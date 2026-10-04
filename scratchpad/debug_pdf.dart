import 'dart:typed_data';
import 'package:global_solar_client_app/models/proposal_data.dart';
import 'package:global_solar_client_app/services/proposal_pdf.dart';

void main() async {
  // Test 1: Default data (useHinglish=false) — subsidy=78000
  final data = SolarProposalData.withDefaults();
  final bytes = await ProposalPdf.generate(data);

  // Check for English labels in raw PDF bytes
  final text = String.fromCharCodes(bytes);

  print('=== Test 1: withDefaults (useHinglish=false) ===');
  print('PDF size: ${bytes.length}');
  print('Starts with %PDF: ${text.startsWith('%PDF')}');

  // These should be present now (after tl() fix)
  print('Contains "System Amount": ${text.contains('System Amount')}');
  print('Contains "Net Cost After Subsidy": ${text.contains('Net Cost')}');
  print('Contains "Government Subsidy": ${text.contains('Government Subsidy')}');
  print('Contains "Net payable": ${text.contains('Net payable')}');

  // Check for Devanagari labels (should NOT be present when useHinglish=false)
  print('Contains "कुल मूल्य": ${text.contains('कुल मूल्य')}');
  print('Contains "अंतिम लागत": ${text.contains('अंतिम लागत')}');
  print('Contains "नेट पेबेबल": ${text.contains('नेट पेबेबल')}');

  // Test 2: Hinglish data (useHinglish=true)
  final dataHinglish = SolarProposalData.withDefaults(useHinglish: true);
  final bytesHinglish = await ProposalPdf.generate(dataHinglish);
  final textHinglish = String.fromCharCodes(bytesHinglish);

  print('\n=== Test 2: withDefaults (useHinglish=true) ===');
  print('Contains "कुल मूल्य": ${textHinglish.contains('कुल मूल्य')}');
  print('Contains "अंतिम लागत": ${textHinglish.contains('अंतिम लागत')}');

  // Check amounts
  final totalBeforeSubsidy = data.grandTotal + data.subsidyAmount;
  print('\n=== Values ===');
  print('grandTotal: ${data.grandTotal}');
  print('subsidyAmount: ${data.subsidyAmount}');
  print('totalBeforeSubsidy: $totalBeforeSubsidy');
  print('amountInWords: ${data.amountInWords}');
}
