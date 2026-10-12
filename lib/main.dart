import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/alarm_launcher.dart';
import 'core/app_flavor.dart';
import 'core/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/demo/demo_lock_screen.dart';
import 'features/quotes/create_estimate_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/data_hub.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'services/database_service.dart';
import 'services/demo_seed.dart';
import 'services/license_service.dart';
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

  // Demo builds use anonymous auth so the client never sees a login screen.
  if (kDemoMode) {
    try {
      if (fb.FirebaseAuth.instance.currentUser == null) {
        await fb.FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
    }
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

  // Notification taps / Stop action.
  NotificationService.instance.onAction = (actionId, payload) {
    if (actionId == 'stop') {
      gNavKey.currentState?.popUntil((r) => r.isFirst);
    } else {
      showFollowUpAlarm(
          title: 'Follow-up due', body: 'You have a follow-up due now.');
    }
  };

  // Demo license gate + sample data.
  var license = LicenseStatus.licensedForever;
  if (kDemoMode) {
    try {
      license = await LicenseService.instance
          .check()
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('license check failed: $e');
    }
    if (license.licensed) {
      DemoSeed.seedIfNeeded().catchError((_) {});
    }
  }

  runApp(GlobalSolarApp(license: license));

  // Non-critical — never blocks startup.
  notificationService.init().catchError((_) {});
}

class GlobalSolarApp extends StatelessWidget {
  final LicenseStatus license;
  const GlobalSolarApp({super.key, required this.license});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gAuthProvider),
        ChangeNotifierProvider.value(value: gDataHub),
      ],
      child: MaterialApp(
        title: kDemoMode ? kDemoAppName : 'Global Solar 2.0',
        theme: GSTheme.light,
        navigatorKey: gNavKey,
        home: license.licensed
            ? const SplashScreen()
            : DemoLockScreen(
                status: license,
                onRetry: () => LicenseService.instance.check(),
              ),
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
