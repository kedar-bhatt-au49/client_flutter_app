import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:html_to_pdf/html_to_pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../models/estimate.dart';
import '../../providers/data_hub.dart';
import '../../services/estimate_pdf.dart';
import '../../services/quotation_archive_service.dart';
import '../../services/quotation_html.dart';
import 'quotation_history_screen.dart';

/// When set, the preview screen automatically triggers the matching action
/// (share or download) immediately after the PDF has been generated and
/// archived.  Used by the history screen's quick-action buttons.
enum PreviewAutoAction { share, download }

/// Full-screen quotation preview.
///
/// Renders the **exact 7-page Stitch HTML** in a WebView (with the form data
/// injected), and exports the very same HTML to PDF via `Printing.convertHtml`
/// when the user taps Share or Download.
class QuotationPreviewScreen extends StatefulWidget {
  final EstimateRecord record;
  final MasterData master;
  final PreviewAutoAction? autoAction;

  const QuotationPreviewScreen(
      {super.key,
      required this.record,
      required this.master,
      this.autoAction});

  @override
  State<QuotationPreviewScreen> createState() => _QuotationPreviewScreenState();
}

class _QuotationPreviewScreenState extends State<QuotationPreviewScreen> {
  WebViewController? _controller;
  String? _html;
  String? _error;
  bool _busy = false;

  String get _fileName {
    final no = widget.record.data.estimateNumber.trim().isNotEmpty
        ? widget.record.data.estimateNumber.trim()
        : widget.record.id;
    return 'GlobalSolar2.0_Quotation_$no.pdf';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Scales the A4 sheets (794px wide) to fit the phone width on screen.
  /// Runs only in the preview WebView; the export path stays at full A4 size.
  static const _fitJs = r'''
    (function () {
      function fit() {
        var w = 794;
        var s = (document.documentElement.clientWidth || window.innerWidth) / w;
        document.body.style.width = w + 'px';
        document.body.style.zoom = s;
      }
      fit();
      window.addEventListener('resize', fit);
      setTimeout(fit, 300);
      setTimeout(fit, 1200);
    })();
  ''';

  Future<void> _applyFit(WebViewController c) async {
    try {
      await c.runJavaScript(_fitJs);
    } catch (_) {}
  }

  Future<void> _init() async {
    try {
      final html = await QuotationHtml.build(
        record: widget.record,
        master: widget.master,
        language: widget.record.data.language,
      );
      final controller = WebViewController();
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFEAF4FF))
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) => _applyFit(controller),
        ));
      await controller.loadHtmlString(html);
      if (!mounted) return;
      setState(() {
        _html = html;
        _controller = controller;
      });
      // Auto-archive a permanent PDF copy in the background so the
      // quotation history always has a downloadable artifact. Skip this
      // when an auto-action is queued — _share/_download will generate it.
      final action = widget.autoAction;
      if (action == null &&
          !await QuotationArchiveService.hasPdf(widget.record)) {
        _generateAndArchive();
      }
      // If launched with an auto-action (share / download), trigger it
      // once the PDF is ready.
      if (action != null) {
        _runAutoAction(action);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  void _runAutoAction(PreviewAutoAction action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (action == PreviewAutoAction.share) {
        _share();
      } else {
        _download();
      }
    });
  }

  /// Generates the 7-page HTML → PDF, archives it to permanent storage,
  /// records the path on the estimate record, and returns the PDF bytes.
  ///
  /// Falls back to the native [EstimatePdf.generate] (pw-based 7-page PDF)
  /// if the HTML-to-PDF conversion fails, so Share / Download always produce
  /// a real file that is permanently archived (never the OS temp directory).
  Future<Uint8List> _generateAndArchive() async {
    final html = _html;
    if (html == null) {
      throw Exception('No HTML content to convert');
    }

    final archivePath = await QuotationArchiveService.archivePath(widget.record);
    final archiveFile = File(archivePath);

    Uint8List bytes;
    try {
      // HTML → PDF conversion, writing to the permanent archive directory.
      final tmpDir = (await QuotationArchiveService.archiveDirectory).path;
      final tmpName = 'gs_quote_${DateTime.now().millisecondsSinceEpoch}';
      final tmpFile = await HtmlToPdf.convertFromHtmlContent(
        htmlContent: html,
        printPdfConfiguration: PrintPdfConfiguration(
          targetDirectory: tmpDir,
          targetName: tmpName,
          printSize: PrintSize.A4,
          printOrientation: PrintOrientation.Portrait,
        ),
      ).timeout(const Duration(seconds: 60));
      bytes = await tmpFile.readAsBytes();
      // Remove the intermediate conversion file (the real archive copy
      // lives at [archivePath]).
      try {
        await tmpFile.delete();
      } catch (_) {}
    } on TimeoutException {
      rethrow;
    } catch (_) {
      // Fallback: native 7-page pw-based PDF generator.
      bytes = await EstimatePdf.generate(
          record: widget.record, master: widget.master);
    }

    // Persist to permanent archive.
    await archiveFile.writeAsBytes(bytes, flush: true);

    // Record the archived path on the estimate so the history screen
    // can find it later.
    if (mounted) {
      unawaited(
        context.read<DataHub>().updateEstimatePdfPath(widget.record.id, archivePath),
      );
    }

    return bytes;
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await _generateAndArchive();
      await Printing.sharePdf(bytes: bytes, filename: _fileName);
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('PDF generation timed out. Please try again.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await _generateAndArchive();
      final path =
          await QuotationArchiveService.archivePath(widget.record);
      messenger.showSnackBar(
          SnackBar(content: Text('PDF saved to: $path')));
    } on TimeoutException {
      messenger.showSnackBar(const SnackBar(
          content: Text('PDF generation timed out. Please try again.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GSColors.pageBg,
      appBar: AppBar(
        backgroundColor: GSColors.navy900,
        foregroundColor: GSColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to form',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quotation Preview',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
             Text(_fileName,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 20),
            tooltip: 'Quotation History',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const QuotationHistoryScreen()));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: GSColors.white,
            border: Border(top: BorderSide(color: GSColors.sky100)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_html == null || _busy) ? null : _share,
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GSColors.navy700,
                        side: const BorderSide(color: GSColors.navy700),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_html == null || _busy) ? null : _download,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: GSColors.navy900),
                            )
                          : const Icon(Icons.download_rounded, size: 18),
                      label: Text(_busy ? 'Generating…' : 'Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GSColors.gold500,
                        foregroundColor: GSColors.navy900,
                        disabledBackgroundColor:
                            GSColors.gold500.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).popUntil((r) => r.isFirst),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Done'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GSColors.green600,
                    side: const BorderSide(color: GSColors.green600),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 44, color: GSColors.statusNew),
              const SizedBox(height: 12),
              Text('Could not build the quotation.\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GSColors.ink)),
            ],
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return const Center(
          child: CircularProgressIndicator(color: GSColors.gold500));
    }
    return WebViewWidget(controller: controller);
  }
}
