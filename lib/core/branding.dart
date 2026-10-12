import 'package:flutter/material.dart';

import 'app_flavor.dart';

export 'app_flavor.dart';

/// Central brand strings. Demo builds carry no Global Solar identity.
const String kBrandName = kDemoMode ? 'Solar Client App' : 'Global Solar 2.0';
const String kBrandShort = kDemoMode ? 'Solar Client' : 'Global Solar';
const String kBrandTagline =
    kDemoMode ? 'CLIENT MANAGEMENT SYSTEM' : 'CLIENT MANAGEMENT SYSTEM';
const String kBrandSubtitle =
    kDemoMode ? 'Client Management System' : 'Client Management System';
const String kBrandFooter = kDemoMode
    ? 'Solar Client App • Client Management Suite'
    : 'Global Solar 2.0 • Bhavnagar & Talaja EPC Division';
const String kBrandRegion =
    kDemoMode ? 'Solar EPC Operations' : 'Bhavnagar & Talaja EPC Operations';

/// The in-app logo. Demo builds show a neutral mark — never the Global Solar
/// logo.
class BrandLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;

  const BrandLogo({super.key, this.size = 56, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (!kDemoMode) {
      return Image.asset('assets/images/logo.jpg',
          width: size, height: size, fit: fit);
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5BD8), Color(0xFF4CC46A)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.solar_power_rounded,
          color: Colors.white, size: size * 0.52),
    );
  }
}
