import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/sun_loader.dart';
import '../../providers/auth_provider.dart';
import '../../shared/main_shell.dart';

/// Login screen — email + password for the 2 pre-created admin accounts.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: GSUsers.founderEmail);
  final _passwordController = TextEditingController(text: GSUsers.appPassword);
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(_emailController.text.trim(), _passwordController.text);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Login failed')),
      );
    }
  }

  Future<void> _handleBiometric() async {
    final auth = context.read<AuthProvider>();
    final available = await auth.canUseBiometrics();

    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometrics not available on this device')),
      );
      return;
    }

    final enabled = auth.biometricsEnabled;
    if (!enabled) {
      await auth.setBiometricsEnabled(true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric unlock enabled. Please login first.')),
      );
      return;
    }

    final success = await auth.tryBiometricUnlock();
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GSGradients.sky),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 12,
                shadowColor: GSColors.shadowMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: GSColors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo / Sun
                      const SunPulseAnimation(size: 80, showPhotons: true),
                      const SizedBox(height: 16),
                      Text('Welcome to Global Solar 2.0',
                          style: GSTextStyles.headlineMedium
                              .copyWith(color: GSColors.navy900)),
                      Text('Client Management App',
                          style: GSTextStyles.bodyMedium
                              .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
                      const SizedBox(height: 8),
                      Text('Authorized admins only',
                          style: GSTextStyles.bodySmall
                              .copyWith(color: GSColors.statusBooked)),
                      const SizedBox(height: 24),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: GSUsers.founderEmail,
                          prefixIcon:
                              const Icon(Icons.email_outlined, color: GSColors.navy700),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: GSTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon:
                              const Icon(Icons.lock_outline, color: GSColors.navy700),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: GSColors.ink.withValues(alpha: 0.5),
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        style: GSTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: 8),

                      // Error message
                      if (auth.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(auth.errorMessage!,
                              style: GSTextStyles.bodySmall
                                  .copyWith(color: GSColors.followupMissed)),
                        ),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: GsButton(
                          text: auth.loading ? 'Signing in...' : 'Sign In',
                          onPressed: auth.loading ? null : _handleLogin,
                          isLoading: auth.loading,
                          height: 52,
                          borderRadius: 16,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Biometric button
                      TextButton.icon(
                        onPressed: auth.loading ? null : _handleBiometric,
                        icon: const Icon(Icons.fingerprint,
                            color: GSColors.navy700, size: 28),
                        label: const Text('Use Biometrics',
                            style: TextStyle(color: GSColors.navy700)),
                      ),
                      const SizedBox(height: 16),

                      // Footer
                      Text('Version 1.0.0',
                          style: GSTextStyles.bodySmall
                              .copyWith(color: GSColors.ink.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
