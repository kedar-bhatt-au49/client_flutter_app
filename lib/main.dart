import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
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

  // Firebase must never block the app from starting.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase.initializeApp failed: $e');
  }
  await Hive.initFlutter();

  // Supabase Storage (payment documents / installation photos).
  try {
    await Supabase.initialize(
        url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
    final sb = Supabase.instance.client;
    if (sb.auth.currentSession == null) {
      try {
        await sb.auth.signInAnonymously();
      } catch (_) {}
    }
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  final authService = FirebaseAuthService();
  final databaseService = DatabaseService();
  final notificationService = NotificationService.instance;

  await databaseService.init();
  await databaseService.seedIfNeeded();

  gAuthProvider = AuthProvider(authService);
  gDataHub = DataHub(databaseService, FirestoreService.instance);

  // Every step is guarded by a timeout + try/catch so startup can never hang
  // (e.g. offline first run on a new phone).
  try {
    await gAuthProvider.init().timeout(const Duration(seconds: 6));
  } catch (e) {
    debugPrint('authProvider.init failed: $e');
  }
  try {
    await gDataHub.init().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('dataHub.init failed: $e');
  }

  runApp(const GlobalSolarApp());

  // Non-critical — never blocks startup.
  notificationService.init().catchError((_) {});
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
