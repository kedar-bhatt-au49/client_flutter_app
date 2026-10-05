import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../models/estimate.dart';
import '../../services/estimate_pdf.dart';

/// Full-screen preview of the generated quotation PDF with Share + Download.
class QuotationPreviewScreen extends StatelessWidget {
  final EstimateRecord record;
  final MasterData master;

  const QuotationPreviewScreen(
      {super.key, required this.record, required this.master});

  String get _fileName {
    final no = record.data.estimateNumber.trim().isNotEmpty
        ? record.data.estimateNumber.trim()
        : record.id;
    return 'GlobalSolar2.0_Quotation_$no.pdf';
  }

  Future<void> _share(BuildContext context) async {
    final bytes = await EstimatePdf.generate(record: record, master: master);
    await Printing.sharePdf(bytes: bytes, filename: _fileName);
  }

  Future<void> _download(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await EstimatePdf.generate(record: record, master: master);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsBytes(bytes, flush: true);
      messenger.showSnackBar(
        SnackBar(content: Text('Saved: ${file.path}')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
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
                style: const TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
          ],
        ),
      ),
      body: PdfPreview(
        build: (format) => EstimatePdf.generate(record: record, master: master),
        allowSharing: false,
        allowPrinting: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: _fileName,
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: GSColors.gold500),
        ),
      ),
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
                  onPressed: () => _share(context),
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
                  onPressed: () => _download(context),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GSColors.gold500,
                    foregroundColor: GSColors.navy900,
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
}
