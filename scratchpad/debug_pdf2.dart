import 'dart:io';
import 'dart:typed_data';
import 'package:global_solar_client_app/models/proposal_data.dart';
import 'package:global_solar_client_app/services/proposal_pdf.dart';

void main() async {
  final data = SolarProposalData.withDefaults();
  final bytes = await ProposalPdf.generate(data);

  final file = File('scratchpad/debug_output.pdf');
  await file.writeAsBytes(bytes);
  print('PDF saved: ${file.path} (${bytes.length} bytes)');

  // Search for strings in the raw PDF bytes
  final text = String.fromCharCodes(bytes);
  _search(text, 'कुल मूल्य', 'कुल');
  _search(text, 'System Amount', 'System');
  _search(text, 'Subsidy', 'Subsidy');
  _search(text, 'Net Cost', 'Net Cost');
  _search(text, 'Net payable', 'Net payable');
  _search(text, 'rupee', 'Rs.');
  _search(text, 'BTXET', 'BTXET'); // font marker check
}

void _search(String text, String pattern, String label) {
  final idx = text.indexOf(pattern);
  if (idx >= 0) {
    final start = (idx - 50).clamp(0, text.length - 1);
    final end = (idx + pattern.length + 50).clamp(0, text.length);
    print('[$label] FOUND at offset $idx');
    print('  Context: ...${text.substring(start, end)}...');
  } else {
    print('[$label] NOT FOUND');
  }
}
