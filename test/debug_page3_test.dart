import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_solar_client_app/models/proposal_data.dart';
import 'package:global_solar_client_app/services/proposal_pdf.dart';

void main() {
  test('Debug: check what renders on page 3', () async {
    final data = SolarProposalData.withDefaults();
    final bytes = await ProposalPdf.generate(data);

    final text = String.fromCharCodes(bytes);
    final lines = text.split('\n');
    final buffer = StringBuffer();
    bool inStream = false;
    StringBuffer? currentStream;

    for (final line in lines) {
      if (line.contains('FlateDecode')) {
        inStream = true;
        currentStream = StringBuffer();
      } else if (inStream && line.contains('endstream')) {
        final raw = currentStream.toString();
        final rawBytes = raw.codeUnits;
        try {
          final decompressed = ZLibDecoder().convert(rawBytes);
          final decoded = String.fromCharCodes(decompressed);
          buffer.writeln(decoded);
          buffer.writeln('---END STREAM---');
        } catch (e) {
          buffer.writeln('---DECOMPRESS ERROR: $e---');
        }
        inStream = false;
        currentStream = null;
      } else if (inStream && currentStream != null) {
        currentStream.write(line);
        currentStream.writeCharCode(0x0A);
      }
    }

    final allDecoded = buffer.toString();

    void search(String pattern, String label) {
      final idx = allDecoded.indexOf(pattern);
      if (idx >= 0) {
        final start = (idx - 30).clamp(0, allDecoded.length - 1);
        final end = (idx + pattern.length + 50).clamp(0, allDecoded.length);
        print('FOUND: "$label" at $idx');
        print('  Context: ${allDecoded.substring(start, end)}');
      } else {
        print('NOT FOUND: "$label"');
      }
    }

    // Line items table
    search('Solar PV Module', 'Line item: Solar PV Module');
    search('Solar Inverter', 'Line item: Solar Inverter');
    search('Electrical ACDB', 'Line item: Electrical ACDB');
    search('Earthing', 'Line item: Earthing/GI Wire');
    search('Discount', 'Line item: Discount');
    search('GST', 'Line item: GST');
    search('Meter', 'Line item: Meter');
    search('Commissioning', 'Line item: Commissioning');

    // Financial summary
    search('Financial', 'Financial Summary caption');
    search('Sub ', 'Sub Total label');
    search('1,52,800', 'Sub Total amount');
    search('Tax', 'Tax label');
    search('27,660', 'Tax amount');
    search('Total', 'Total label');
    search('1,80,460', 'Grand Total amount');

    // Bottom section
    search('Rupee', 'Amount in words');
    search('Notes', 'Notes label');
    search('Bank', 'Bank details');
    search('AUTHORIZED', 'Signature label');
    search('Accepted Payment', 'Payment modes');
    search('Scan the UPI', 'UPI text');

    // Count TJ operators per "page" (delimited by ---END STREAM---)
    final streams = allDecoded.split('---END STREAM---');
    print('\nTotal streams: ${streams.length}');

    // Print each text stream to debug what's actually on each page
    for (int i = 0; i < streams.length; i++) {
      final stream = streams[i];
      final tjCount = 'TJ'.allMatches(stream).length;
      final tfCount = 'Tf'.allMatches(stream).length;
      print('Stream $i: $tjCount text objects, $tfCount font switches, ${stream.length} chars');
    }

    // Print the full content of stream 4 (page 3 — Quotation)
    if (streams.length > 4) {
      print('\n=== PAGE 3 (Stream 4) CONTENT ===');
      print(streams[4]);
    }

    // Check how many line items are in the data
    print('\nNumber of line items: ${data.lineItems.length}');
    for (int i = 0; i < data.lineItems.length; i++) {
      print('  Item $i: ${data.lineItems[i].description} (rate=${data.lineItems[i].rate}, qty=${data.lineItems[i].qty})');
    }
  });
}
