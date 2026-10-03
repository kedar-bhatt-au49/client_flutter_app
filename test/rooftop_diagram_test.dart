import 'package:flutter_test/flutter_test.dart';
import 'package:global_solar_client_app/models/proposal_data.dart';
import 'package:global_solar_client_app/services/proposal_pdf.dart';

void main() {
  test('Page 2 rooftop diagram generates without errors', () async {
    final data = SolarProposalData.withDefaults();
    final bytes = await ProposalPdf.generate(data);
    expect(bytes, isNotEmpty);
    print('SUCCESS: PDF generated, ${bytes.length} bytes');
  });
}
