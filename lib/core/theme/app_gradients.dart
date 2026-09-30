import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Gradient definitions — "Sunrise over the rooftop".
abstract class GSGradients {
  /// Sky gradient: navy-900 → blue-500 → sky-100
  static const LinearGradient sky = LinearGradient(
    colors: [GSColors.navy900, GSColors.blue500, GSColors.sky100],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Sun (CTA) gradient: gold-300 → gold-500
  static const LinearGradient sun = LinearGradient(
    colors: [GSColors.gold300, GSColors.gold500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Energy (success) gradient: green-400 → gold-300
  static const LinearGradient energy = LinearGradient(
    colors: [GSColors.green400, GSColors.gold300],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Navy to transparent (for overlays)
  static const LinearGradient navyToTransparent = LinearGradient(
    colors: [GSColors.navy900, Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
