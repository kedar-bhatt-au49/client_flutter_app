import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_solar_client_app/models/proposal_data.dart';
import 'package:global_solar_client_app/services/proposal_pdf.dart';

void main() {
  test('Page 2 design photo generates without errors', () async {
    // Use withDefaults which provides internally-consistent quotation data.
    // Asset images will fall back to empty Uint8List (placeholders) in tests,
    // but the 7-panel design photo image path is handled gracefully.
    final data = SolarProposalData.withDefaults();
    final bytes = await ProposalPdf.generate(data);

    expect(bytes, isNotEmpty);
    expect(bytes, isA<Uint8List>());
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });

  test('Grid formula produces 3x3 for 9 panels', () {
    const count = 9;
    final rows = math.max(1, (math.sqrt(count * 0.6)).ceil());
    final cols = math.max(1, (count / rows).ceil());
    expect(rows, 3);
    expect(cols, 3);
  });

  test('Grid formula produces 2x3 for 6 panels', () {
    const count = 6;
    final rows = math.max(1, (math.sqrt(count * 0.6)).ceil());
    final cols = math.max(1, (count / rows).ceil());
    expect(rows, 2);
    expect(cols, 3);
  });

  test('Grid formula produces 3x3 for 7 panels', () {
    const count = 7;
    final rows = math.max(1, (math.sqrt(count * 0.6)).ceil());
    final cols = math.max(1, (count / rows).ceil());
    expect(rows, 3);
    expect(cols, 3);
  });
}
