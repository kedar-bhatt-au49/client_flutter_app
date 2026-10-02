import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:global_solar_client_app/features/quotes/create_estimate_screen.dart';
import 'package:global_solar_client_app/providers/data_hub.dart';
import 'package:global_solar_client_app/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CreateEstimateScreen renders wizard after master data loads',
      (WidgetTester tester) async {
    // DataHub(DatabaseService()) without init() — estimateCount defaults to 0,
    // which is all _loadMaster needs. MasterData.load() uses rootBundle, not Hive.
    final hub = DataHub(DatabaseService());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: hub,
        child: const MaterialApp(
          home: CreateEstimateScreen(),
        ),
      ),
    );

    // Step 1: loading spinner visible, wizard not yet built
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('CREATE ESTIMATE'), findsNothing);

    // Allow MasterData.load() (rootBundle asset) to complete
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Step 2: spinner gone, wizard content visible
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('CREATE ESTIMATE'), findsOneWidget);
    expect(find.text('Lead Details'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
