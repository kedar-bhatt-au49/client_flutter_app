/// ---------------------------------------------------------------------------
/// Estimate PDF archive — permanent storage for generated estimate PDFs.
///
/// PDFs are written to the app documents directory (`.../estimates/`) instead
/// of the OS temp directory, so a quotation created weeks ago can still be
/// previewed or shared. The absolute path is stored on the [EstimateRecord]
/// as `pdfPath`.
///
/// Records created before archiving existed have a null `pdfPath`; the archive
/// regenerates the PDF from the persisted estimate data on demand and then
/// saves it permanently.
/// ---------------------------------------------------------------------------
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/estimate.dart';
import 'estimate_pdf.dart';

class EstimateArchive {
  /// `.../app_flutter/estimates`
  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/estimates');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Filename is derived from the estimate number so the file is recognisable
  /// in a file manager, with the record id to guarantee uniqueness.
  static String _fileName(EstimateRecord record) {
    final safe = record.data.estimateNumber
        .replaceAll(RegExp(r'[^A-Za-z0-9\-_]'), '_')
        .trim();
    final label = safe.isEmpty ? 'estimate' : safe;
    return '${label}_${record.id.substring(0, 8)}.pdf';
  }

  /// Render [record] and persist the PDF. Returns the absolute file path.
  static Future<String> archive(EstimateRecord record,
      {MasterData? master}) async {
    master ??= await MasterData.load();
    final bytes =
        await EstimatePdf.generate(record: record, master: master);
    final file = File('${(await _dir()).path}/${_fileName(record)}');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Resolve the PDF for [record], preferring the archived file.
  ///
  /// Falls back to regenerating when no archived file exists yet, then caches
  /// the result so subsequent opens are instant.
  static Future<File> resolve(EstimateRecord record,
      {MasterData? master}) async {
    final existing = record.pdfPath;
    if (existing != null && existing.isNotEmpty) {
      final file = File(existing);
      if (file.existsSync()) return file;
    }
    final path = await archive(record, master: master);
    return File(path);
  }

  /// True when a PDF file is already on disk for this record.
  static bool hasArchivedPdf(EstimateRecord record) {
    final p = record.pdfPath;
    return p != null && p.isNotEmpty && File(p).existsSync();
  }

  /// Delete the archived PDF file. No-op when the record has no file.
  static Future<void> deletePdf(EstimateRecord record) async {
    final p = record.pdfPath;
    if (p == null || p.isEmpty) return;
    final file = File(p);
    if (file.existsSync()) {
      try {
        await file.delete();
      } on FileSystemException {
        // File already gone or locked — nothing actionable.
      }
    }
  }

  /// Copy bytes to a user-chosen location. Used by the "Download" action.
  static Future<File> saveCopy(Uint8List bytes, String fileName) async {
    final downloads = await getDownloadsDirectory();
    if (downloads == null) {
      throw Exception('Downloads directory is not available on this device');
    }
    final file = File('${downloads.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}