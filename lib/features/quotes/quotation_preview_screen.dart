import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:printing/printing.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../models/estimate.dart';
import '../../services/estimate_pdf.dart';
import '../../services/quotation_html.dart';

/// Full-screen quotation preview.
///
/// Renders the **exact 7-page Stitch HTML** in a WebView (with the form data
/// injected), and exports the very same HTML to PDF via `Printing.convertHtml`
/// when the user taps Share or Download.
class QuotationPreviewScreen extends StatefulWidget {
  final EstimateRecord record;
  final MasterData master;

  const QuotationPreviewScreen(
      {super.key, required this.record, required this.master});

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

  Future<void> _init() async {
    try {
      final html = await QuotationHtml.build(
        record: widget.record,
        master: widget.master,
      );
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFEAF4FF));
      await controller.loadHtmlString(html);
      if (!mounted) return;
      setState(() {
        _html = html;
        _controller = controller;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  /// HTML → PDF (exact Stitch design). Falls back to the native 7-page
  /// generator if the platform HTML converter is unavailable or times out,
  /// so Share / Download always produce a file.
  Future<Uint8List> _convert(String html) async {
    try {
      return await Printing.convertHtml(html: html, format: PdfPageFormat.a4)
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      return EstimatePdf.generate(
          record: widget.record, master: widget.master);
    }
  }

  Future<void> _share() async {
    final html = _html;
    if (html == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await _convert(html);
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
    final html = _html;
    if (html == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await _convert(html);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsBytes(bytes, flush: true);
      messenger.showSnackBar(SnackBar(content: Text('Saved: ${file.path}')));
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
          child: Row(
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
