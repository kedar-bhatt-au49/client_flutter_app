import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/solar_visuals.dart';
import '../providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../shared/main_shell.dart';

/// Splash screen — exact "Sunrise over the rooftop" design:
/// sky gradient + PV mesh + rooftop silhouette + sun logo + battery charge.
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
            stops: [0.0, 0.32, 0.68, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // PV mesh overlay
            const Positioned.fill(child: SolarMeshBackground(opacity: 0.06)),
            // Drifting photons
            const Positioned.fill(child: _PhotonField()),
            // Rooftop silhouette at base
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: const RooftopSilhouette(height: 96),
            ),
            // SafeArea content
            SafeArea(
              child: Column(
                children: [
                  // Centered brand block
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Official Global Solar logo in a gold ring
                          Container(
                            width: 152,
                            height: 152,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFD54F),
                                  Color(0xFFFFE082),
                                  Color(0xFFFFB300),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: GSColors.gold500.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Brand identity
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                const TextSpan(text: 'Global Solar '),
                                TextSpan(
                                  text: '2.0',
                                  style: TextStyle(
                                    foreground: Paint()
                                      ..shader = const LinearGradient(
                                        colors: [Color(0xFFFFD54F), Color(0xFFFFE082), Color(0xFF4CC46A)],
                                      ).createShader(Rect.fromLTWH(0, 0, 100, 30)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('CLIENT MANAGEMENT SYSTEM',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                                color: Colors.white.withValues(alpha: 0.85),
                              )),
                          const SizedBox(height: 16),
                          // Gold→green energy conduit line
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle, color: Color(0xFFFFB300)),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 144,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFFFB300),
                                    Color(0xFFFFE082),
                                    Color(0xFF4CC46A),
                                  ]),
                                  boxShadow: [
                                    BoxShadow(
                                        color: GSColors.gold500.withValues(alpha: 0.7),
                                        blurRadius: 8),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle, color: Color(0xFF4CC46A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // EPC operations badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle, color: Color(0xFF4CC46A)),
                                ),
                                const SizedBox(width: 6),
                                Text('Bhavnagar & Talaja EPC Operations',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.9))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom battery charge indicator
                  Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Column(
                      children: [
                        const BatteryChargeIndicator(),
                        const SizedBox(height: 12),
                        Text('Secure Cloud Synchronized',
                            style: GSTextStyles.bodySmall.copyWith(
                                color: GSColors.navy900.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drifting gold/emerald photon particles in the splash background.
class _PhotonField extends StatelessWidget {
  const _PhotonField();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _Photon(top: 236, left: 86, color: GSColors.gold300, size: 6, delay: 0.2),
        _Photon(top: 287, right: 94, color: GSColors.gold300, size: 8, delay: 1.1),
        _Photon(top: 355, left: 187, color: GSColors.green400, size: 4, delay: 1.8),
        _Photon(top: 186, right: 148, color: GSColors.gold500, size: 6, delay: 2.4),
        _Photon(top: 405, left: 62, color: GSColors.gold300, size: 8, delay: 0.7),
      ],
    );
  }
}

class _Photon extends StatefulWidget {
  final double top;
  final double? left;
  final double? right;
  final Color color;
  final double size;
  final double delay;

  const _Photon({
    required this.top,
    this.left,
    this.right,
    required this.color,
    required this.size,
    required this.delay,
  });

  @override
  State<_Photon> createState() => _PhotonState();
}

class _PhotonState extends State<_Photon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      right: widget.right,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = (_controller.value + widget.delay) % 1.0;
          final opacity = t < 0.5 ? 0.2 + 0.7 * (t / 0.5) : 1.0 - 0.9 * ((t - 0.5) / 0.5);
          final offset = t * 32.0;
          return Transform.translate(
            offset: Offset(0, offset),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(color: widget.color, blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}