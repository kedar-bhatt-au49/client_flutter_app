import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_solar_client_app/models/proposal_data.dart';
import 'package:global_solar_client_app/services/proposal_pdf.dart';

void main() {
  test('Debug: page 3 overflow with 15 line items (estimate flow)', () async {
    final defaultData = SolarProposalData.withDefaults();
    final json = defaultData.toJson();

    final manyItems = <ProposalLineItem>[
      ProposalLineItem(
        description: 'Solar Panels',
        specs: ['Adani TOPCon 610Wp (25 Years, 25 Years, 25 Years)'],
        qty: '10', unit: 'Nos.', rate: 146400, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'Inverter', specs: ['Polycab @ 3.6kW'],
        qty: '1', unit: 'Nos.', rate: 36000, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'Structure & Mounting', specs: ['Hot-dip galvanized MS structure'],
        qty: '1', unit: 'set', rate: 12000, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'DC Cable', specs: ['4 sq.mm, 65m'],
        qty: '1', unit: 'set', rate: 3500, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'AC Wire', specs: ['2.5 sq.mm, 80m'],
        qty: '1', unit: 'set', rate: 4500, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'Earthing Wire', specs: ['2.5 sq.mm, 150m'],
        qty: '1', unit: 'set', rate: 3200, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'LA (ALU.) Cable', specs: ['16 sq.mm, 80m'],
        qty: '1', unit: 'set', rate: 6400, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'MC4 Connectors', specs: ['10 pairs'],
        qty: '1', unit: 'set', rate: 2500, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'DCDB / ACDB', specs: ['2P DCDB + 2P ACDB'],
        qty: '1', unit: 'set', rate: 8000, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'Chemical Earthing', specs: ['2 nos'],
        qty: '1', unit: 'set', rate: 3000, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'Cable Ties & Accessories', specs: ['Pack'],
        qty: '1', unit: 'set', rate: 1500, cgstPercent: 6, sgstPercent: 6,
      ),
      ProposalLineItem(
        description: 'Discount (per kW)', specs: [],
        qty: '1', unit: 'set', rate: -5000, cgstPercent: 0, sgstPercent: 0,
      ),
      ProposalLineItem(
        description: 'Tax (GST 12.0%)', specs: [],
        qty: '1', unit: 'set', rate: 27660, cgstPercent: 0, sgstPercent: 0,
      ),
      ProposalLineItem(
        description: 'Insurance', specs: [],
        qty: '1', unit: 'set', rate: 3000, cgstPercent: 0, sgstPercent: 0,
      ),
      ProposalLineItem(
        description: 'PM Surya Ghar Subsidy (Adjustment)',
        specs: ['Government subsidy credit', 'Residential only'],
        qty: '1', unit: 'set', rate: -78000, cgstPercent: 0, sgstPercent: 0,
      ),
    ];

    json['line_items'] = manyItems.map((i) => i.toJson()).toList();
    final sbTotal = manyItems.fold(0, (s, i) => s + i.taxableAmount);
    final cgst = manyItems.fold(0, (s, i) => s + i.cgstAmount);
    final sgst = manyItems.fold(0, (s, i) => s + i.sgstAmount);
    json['sub_total'] = sbTotal;
    json['cgst_total'] = cgst;
    json['sgst_total'] = sgst;
    json['tax_gst'] = cgst + sgst;
    json['grand_total'] = sbTotal + cgst + sgst;

    final data = SolarProposalData.fromJson(json);
    final bytes = await ProposalPdf.generate(data);

    // Decode PDF text streams
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
    final streams = allDecoded.split('---END STREAM---');
    final subTotalStr = ProposalPdf.moneyINR(data.subTotal);
    final grandTotalStr = ProposalPdf.moneyINR(data.grandTotal);

    print('\nTotal streams: ${streams.length}');
    for (int i = 0; i < streams.length; i++) {
      final s = streams[i];
      final tjCount = 'TJ'.allMatches(s).length;
      print('Stream $i: $tjCount text objects, ${s.length} chars');
    }

    print('\n=== Searching all streams ===');
    void searchAll(String pattern, String label) {
      final idx = allDecoded.indexOf(pattern);
      if (idx >= 0) {
        final start = (idx - 30).clamp(0, allDecoded.length - 1);
        final end = (idx + pattern.length + 50).clamp(0, allDecoded.length);
        print('FOUND: "$label" at $idx');
        print('  Context: ${allDecoded.substring(start, end)}');
      } else {
        print('NOT FOUND in ANY stream: "$label"');
      }
    }

    searchAll('Financial', 'Financial Summary caption');
    searchAll(subTotalStr, 'Sub Total amount');
    searchAll(grandTotalStr, 'Grand Total amount');

    print('\n=== Per-page check ===');
    for (int i = 0; i < streams.length; i++) {
      final s = streams[i];
      final hasFinancial = s.contains('Financial');
      final hasSubTotal = s.contains(subTotalStr);
      final hasTotal = s.contains(grandTotalStr);
      if (hasFinancial || hasSubTotal || hasTotal) {
        print('Stream $i has financial info: '
            'financial=$hasFinancial, subTotal=$hasSubTotal, total=$hasTotal');
      }
    }

    // Print page 3 content (stream 4)
    if (streams.length > 4) {
      print('\n=== PAGE 3 (Stream 4) - first 2000 chars ===');
      print(streams[4].substring(0, streams[4].length < 2000 ? streams[4].length : 2000));
    }
  });
}
