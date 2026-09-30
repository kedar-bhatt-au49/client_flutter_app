import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../shared/main_shell.dart';

/// Splash screen — shows sun animation while checking auth state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final auth = context.read<AuthProvider>();
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    if (!auth.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // Try biometric unlock if enabled
    final unlocked = await auth.tryBiometricUnlock();
    if (!mounted) return;

    if (unlocked) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GSGradients.sky),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.jpg'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Global Solar 2.0',
                  style: GSTextStyles.displayMedium.copyWith(color: GSColors.white, fontSize: 28)),
              const SizedBox(height: 8),
              Text('Client Management System',
                  style: GSTextStyles.bodyMedium.copyWith(
                      color: GSColors.white.withValues(alpha: 0.8))),
            ],
          ),
        ),
      ),
    );
  }
}
