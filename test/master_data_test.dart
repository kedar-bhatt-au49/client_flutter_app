import 'package:flutter_test/flutter_test.dart';
import 'package:global_solar_client_app/models/estimate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MasterData.load parses all assets without throwing (regression)', () async {
    final master = await MasterData.load();

    expect(master.estimateNumberPrefix, 'EST');
    expect(master.defaultCurrency, 'INR');

    // BosItems — qty must be int, not String (the bug was qty as String)
    expect(master.bosItems, isNotEmpty);
    for (final bos in master.bosItems) {
      expect(bos.qty, greaterThan(0));
      expect(bos.rate, greaterThan(0));
    }

    // Sanity-check the totals are computed correctly
    expect(master.bosItems.first.total, equals(65 * 12));

    expect(master.panels, isNotEmpty);
    expect(master.inverters, isNotEmpty);
    expect(master.structurePipes, isNotEmpty);
    expect(master.gstProfiles, isNotEmpty);
    expect(master.leadStages, isNotEmpty);
    expect(master.currencies, isNotEmpty);
  });
}
