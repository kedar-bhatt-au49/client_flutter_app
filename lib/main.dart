import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/quotes/create_estimate_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/data_hub.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'shared/main_shell.dart';
import 'shared/splash_screen.dart';

late AuthProvider gAuthProvider;
late DataHub gDataHub;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();

  final authService = FirebaseAuthService();
  final databaseService = DatabaseService();
  final notificationService = NotificationService();

  await databaseService.init();
  await databaseService.seedIfNeeded();
  await authService.init();
  await notificationService.init();

  gAuthProvider = AuthProvider(authService);
  gDataHub = DataHub(databaseService, FirestoreService.instance);
  await gAuthProvider.init();
  await gDataHub.init();

  runApp(const GlobalSolarApp());
}

class GlobalSolarApp extends StatelessWidget {
  const GlobalSolarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gAuthProvider),
        ChangeNotifierProvider.value(value: gDataHub),
      ],
      child: MaterialApp(
        title: 'Global Solar 2.0',
        theme: GSTheme.light,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const MainShell(),
          '/create-estimate': (_) => const CreateEstimateScreen(),
        },
      ),
    );
  }
}
