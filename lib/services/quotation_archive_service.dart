import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/estimate.dart';

/// Manages permanent archival of quotation PDFs so generated documents
/// survive app restarts and are browseable from the history screen.
///
/// PDFs are stored in `<app-documents>/quotations/` with a stable filename
/// derived from the estimate number and client name, so re-saving an
/// existing quotation overwrites the same file (no duplicates).
class QuotationArchiveService {
  QuotationArchiveService._();

  /// Sub-directory under the app documents directory.
  static const _dirName = 'quotations';

  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  /// Returns the permanent directory that holds all archived quotation PDFs.
  static Future<Directory> get archiveDirectory async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Computes the deterministic archive filename for a given estimate record.
  /// Format: `EST-001_ClientName_2026-10-06.pdf`
  static String archiveFileName(EstimateRecord record) {
    final no = record.data.estimateNumber.trim().isNotEmpty
        ? record.data.estimateNumber.trim()
        : 'EST-${record.id.substring(0, 8)}';
    final name = _sanitize(record.data.leadName);
    final date = _dateFmt.format(record.createdAt);
    final safeNo = _sanitize(no);
    return '${safeNo}_${name}_$date.pdf';
  }

  /// Full path where the PDF for [record] should be permanently stored.
  static Future<String> archivePath(EstimateRecord record) async {
    final dir = await archiveDirectory;
    return '${dir.path}/${archiveFileName(record)}';
  }

  /// Returns `true` if an archived PDF already exists for [record].
  static Future<bool> hasPdf(EstimateRecord record) async {
    if (record.pdfPath != null && (record.pdfPath as String).isNotEmpty) {
      return File(record.pdfPath as String).exists();
    }
    final path = await archivePath(record);
    return File(path).exists();
  }

  /// Persists the PDF [bytes] to the permanent archive directory and returns
  /// the file path. Overwrites any older PDF that was stored for this record.
  static Future<String> savePdf(
      EstimateRecord record, List<int> bytes) async {
    final existingPath = await archivePath(record);

    // Clean up an older PDF that may have been stored under a previous
    // filename (e.g. after the client name was edited).
    final previousPath = record.pdfPath;
    if (previousPath != null &&
        previousPath != existingPath &&
        await File(previousPath).exists()) {
      try {
        await File(previousPath).delete();
      } catch (_) {}
    }

    final file = File(existingPath);
    await file.writeAsBytes(bytes, flush: true);
    return existingPath;
  }

  /// Deletes the archived PDF for [record] (and clears the path reference).
  static Future<void> deletePdf(EstimateRecord record) async {
    final paths = <String>{
      if (record.pdfPath != null) record.pdfPath!,
      await archivePath(record),
    };
    for (final p in paths) {
      try {
        if (p.isNotEmpty && await File(p).exists()) {
          await File(p).delete();
        }
      } catch (_) {}
    }
  }

  static String _sanitize(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'\s+'), '_');
    return cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
  }
}
