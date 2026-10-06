import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/solar_visuals.dart';
import '../../providers/auth_provider.dart';
import '../../shared/main_shell.dart';

/// Login screen — exact "Sunrise over the rooftop" design:
/// sky gradient + PV mesh + glass card with email/password + gold sign-in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _keepSignedIn = true;

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071440), // navy-900
              Color(0xFF0B1F5C), // navy-700
              Color(0xFF1E5BD8), // blue-500
              Color(0xFFEAF4FF), // sky-100
            ],
            stops: [0.0, 0.30, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // PV mesh overlay
            const Positioned.fill(child: SolarMeshBackground(opacity: 0.04)),
            // SafeArea content
            SafeArea(
              child: Column(
                children: [
                  // Top brand header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage('assets/images/logo.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Global Solar 2.0',
                                style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Centered glass card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Center(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. Gold sun logo badge
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFFFB74D), Color(0xFFFFE082)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: GSColors.gold500.withValues(alpha: 0.5),
                                          blurRadius: 14,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.wb_sunny_rounded,
                                        color: GSColors.navy900, size: 26),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // 2. Headline
                                const Text(
                                  'Welcome to Global Solar 2.0',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: GSColors.navy900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                // 3. Subtitle
                                Text(
                                  'Client Management App',
                                  textAlign: TextAlign.center,
                                  style: GSTextStyles.bodySmall.copyWith(
                                      color: GSColors.ink.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 12),
                                // 4. Authorized admins pill
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB300).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.shield_rounded,
                                            size: 14, color: Color(0xFFFF8F00)),
                                        const SizedBox(width: 6),
                                        Text('Authorized admins only',
                                            style: GSTextStyles.bodySmall.copyWith(
                                                color: const Color(0xFFFF8F00),
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // 5. Email field
                                _fieldLabel('Email Address'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: _fieldDecoration(
                                    icon: Icons.email_outlined,
                                    hint: 'Enter your email',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: _fieldTextStyle(),
                                ),
                                const SizedBox(height: 14),
                                // 6. Password field
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _fieldLabel('Password'),
                                    TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 24),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Forgot?',
                                          style: TextStyle(
                                              fontSize: 11, color: GSColors.blue500)),
                                    ),
                                  ],
                                ),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: _fieldDecoration(
                                    icon: Icons.lock_outline,
                                    hint: 'Enter administrative password',
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: GSColors.ink.withValues(alpha: 0.5),
                                        size: 18,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  style: _fieldTextStyle(),
                                ),
                                // Remember me & encrypted row
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () => setState(
                                            () => _keepSignedIn = !_keepSignedIn),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _keepSignedIn
                                                  ? Icons.check_box
                                                  : Icons.check_box_outline_blank,
                                              size: 18,
                                              color: _keepSignedIn
                                                  ? GSColors.blue500
                                                  : GSColors.ink.withValues(alpha: 0.4),
                                            ),
                                            const SizedBox(width: 6),
                                            Text('Keep signed in',
                                                style: GSTextStyles.bodySmall.copyWith(
                                                    color: GSColors.ink.withValues(alpha: 0.7),
                                                    fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle,
                                              size: 13, color: GSColors.green600),
                                          const SizedBox(width: 4),
                                          Text('256-bit Encrypted',
                                              style: GSTextStyles.bodySmall.copyWith(
                                                  color: GSColors.green600,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // 7. Sign In button
                                _signInButton(auth),
                                const SizedBox(height: 12),
                                // 8. Biometrics button
                                _biometricButton(auth),
                                // 9. Version footer
                                Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Divider(
                                      color: GSColors.ink.withValues(alpha: 0.08),
                                      height: 1),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Version 1.0.0  •  Internal EPC Ops',
                                  textAlign: TextAlign.center,
                                  style: GSTextStyles.bodySmall.copyWith(
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom security badge
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text('Global Solar 2.0  •  Bhavnagar & Talaja EPC Division',
                        style: GSTextStyles.bodySmall.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: GSColors.ink.withValues(alpha: 0.8))),
    );
  }

  InputDecoration _fieldDecoration({
    required IconData icon,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: GSColors.ink.withValues(alpha: 0.35)),
      prefixIcon: Icon(icon, color: GSColors.blue500.withValues(alpha: 0.7), size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: GSColors.sky100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: GSColors.blue500.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GSColors.blue500, width: 1.2),
      ),
    );
  }

  TextStyle _fieldTextStyle() {
    return TextStyle(fontSize: 13, color: GSColors.ink, fontWeight: FontWeight.w500);
  }

  Widget _signInButton(AuthProvider auth) {
    final disabled = auth.loading;
    return GestureDetector(
      onTap: disabled ? null : _handleLogin,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF9B417), Color(0xFFFFC83B), Color(0xFFFFD86B)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE0B2).withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: GSColors.gold500.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: auth.loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: GSColors.navy900))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sign In',
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.3,
                            color: GSColors.navy900)),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: GSColors.navy900),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _biometricButton(AuthProvider auth) {
    return GestureDetector(
      onTap: auth.loading ? null : _handleBiometric,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade100.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 18, color: GSColors.blue500),
            const SizedBox(width: 8),
            Text('Use Biometrics (Face ID / Fingerprint)',
                style: GSTextStyles.bodySmall.copyWith(
                    color: GSColors.navy900, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}