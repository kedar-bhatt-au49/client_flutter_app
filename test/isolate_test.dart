import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_solar_client_app/services/proposal_pdf.dart';
import 'package:global_solar_client_app/models/proposal_data.dart';

void main() {
  test('Isolate: verify financial summary text in original _fsRow version', () async {
    final data = SolarProposalData.withDefaults();
    final bytes = await ProposalPdf.generate(data);

    File('test_output/debug.pdf').createSync(recursive: true);
    File('test_output/debug.pdf').writeAsBytesSync(bytes);

    final text = _decompressPdf(bytes);
    File('test_output/decompressed.txt').writeAsStringSync(text);

    // Search for individual words from financial summary (PDF splits text across TJ operators)
    final terms = [
      'Financial', 'Summary', 'System', 'Amount', 'Net', 'Cost',
      'Subsidy', 'Payment', 'Mode', 'Inclusive', 'GST',
      '2,58,460', '78,000', '1,80,460', 'Rs.',
    ];

    for (final term in terms) {
      var count = 0;
      var idx = text.indexOf(term);
      while (idx >= 0) {
        count++;
        idx = text.indexOf(term, idx + 1);
      }
      if (count > 0) {
        print('FOUND: "$term" ($count occurrences)');
        // Print context
        if (count <= 3 && idx > 0) {
          // re-find first occurrence
          idx = text.indexOf(term);
          final start = (idx - 50).clamp(0, text.length - 1);
          final end = (idx + term.length + 50).clamp(0, text.length);
          print('  Context: ...${text.substring(start, end)}...');
        }
      } else {
        print('NOT FOUND: "$term"');
      }
    }

    // Count total TJ operators
    final tjCount = RegExp(r'\[(.*?)\]TJ').allMatches(text).length;
    print('\nTotal TJ operators: $tjCount');
    print('Decompressed length: ${text.length}');
  });
}

String _decompressPdf(List<int> bytes) {
  final s = String.fromCharCodes(bytes);
  final allDecoded = StringBuffer();
  final streamRegex = RegExp(r'stream\r?\n', multiLine: false);
  final matches = streamRegex.allMatches(s);

  for (final match in matches) {
    final start = match.end;
    final endMatch = RegExp(r'\r?\nendstream').firstMatch(s.substring(start));
    if (endMatch == null) continue;

    final dictStart = s.lastIndexOf('<<', match.start);
    final dictEnd = match.start;
    final dict = s.substring(dictStart, dictEnd);
    if (!dict.contains('FlateDecode')) continue;

    final rawData = s.substring(start, start + endMatch.start);

    try {
      final compressed = rawData.codeUnits;
      final decompressed = ZLibDecoder().convert(compressed);
      allDecoded.write(utf8.decode(decompressed));
      allDecoded.write('\n');
    } catch (e) {
      try {
        final altRaw = s.substring(start - 1, start + endMatch.start - 1);
        final compressed = altRaw.codeUnits;
        final decompressed = ZLibDecoder().convert(compressed);
        allDecoded.write(utf8.decode(decompressed));
        allDecoded.write('\n');
      } catch (e2) {
        // skip
      }
    }
  }

  return allDecoded.toString();
}
