import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Sun pulse + photon drift — used for splash and loading states.
class SunPulseAnimation extends StatefulWidget {
  final double size;
  final bool showPhotons;
  final Color? sunColor;

  const SunPulseAnimation({
    super.key,
    this.size = 120,
    this.showPhotons = true,
    this.sunColor,
  });

  @override
  State<SunPulseAnimation> createState() => _SunPulseAnimationState();
}

class _SunPulseAnimationState extends State<SunPulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.sunColor ?? GSColors.gold500;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SunPainter(
              pulse: _controller.value,
              sunColor: color,
              showPhotons: widget.showPhotons,
            ),
          );
        },
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  final double pulse;
  final Color sunColor;
  final bool showPhotons;

  _SunPainter({
    required this.pulse,
    required this.sunColor,
    required this.showPhotons,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;

    // Glow layers — 3 concentric circles that pulse
    for (var i = 3; i >= 1; i--) {
      final alpha = (0.15 / i) * (1 - pulse * 0.3);
      final radius = maxRadius * (0.5 + i * 0.15 + pulse * 0.1);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = sunColor.withValues(alpha: alpha)
          ..isAntiAlias = true,
      );
    }

    // Core sun circle
    final coreRadius = maxRadius * (0.38 + pulse * 0.04);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..color = sunColor
        ..isAntiAlias = true,
    );

    // Sun rays — 12 rays rotating
    final rayCount = 12;
    final rayLength = maxRadius * (0.6 + pulse * 0.1);
    final rayWidth = maxRadius * 0.06;
    final baseAngle = pulse * 2 * pi;
    for (var i = 0; i < rayCount; i++) {
      final angle = baseAngle + (2 * pi / rayCount) * i;
      final path = Path()
        ..moveTo(
          center.dx + cos(angle) * coreRadius,
          center.dy + sin(angle) * coreRadius,
        )
        ..lineTo(
          center.dx + cos(angle) * (coreRadius + rayLength),
          center.dy + sin(angle) * (coreRadius + rayLength),
        )
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center.dx + cos(angle) * coreRadius - rayWidth / 2,
            center.dy + sin(angle) * coreRadius - rayWidth / 2,
            rayWidth,
            rayLength,
          ),
          Radius.circular(rayWidth / 2),
        ));
      canvas.drawPath(
        path,
        Paint()
          ..color = sunColor
          ..isAntiAlias = true
          ..strokeCap = StrokeCap.round,
      );
    }

    // Photons drifting outward
    if (showPhotons) {
      final photonCount = 8;
      for (var i = 0; i < photonCount; i++) {
        final angle = baseAngle + (2 * pi / photonCount) * i;
        final distance = maxRadius * (0.8 + pulse * 0.4);
        final photonRadius = maxRadius * 0.04;
        final alpha = 0.6 + sin(pulse * pi + i) * 0.4;
        canvas.drawCircle(
          Offset(
            center.dx + cos(angle) * distance,
            center.dy + sin(angle) * distance,
          ),
          photonRadius,
          Paint()
            ..color = sunColor.withValues(alpha: alpha)
            ..isAntiAlias = true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SunPainter old) =>
      old.pulse != pulse || old.showPhotons != showPhotons;
}

/// Simple sun loader — used for inline loading states.
class SunLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const SunLoader({super.key, this.size = 36, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SunPulseAnimation(size: size, showPhotons: false, sunColor: color),
    );
  }
}
