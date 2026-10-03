import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Subtle photovoltaic mesh background — thin blue grid lines (like solar cells).
class SolarMeshBackground extends StatelessWidget {
  final Color lineColor;
  final double opacity;
  final Widget? child;

  const SolarMeshBackground({
    super.key,
    this.lineColor = GSColors.blue500,
    this.opacity = 0.05,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MeshPainter(lineColor: lineColor, opacity: opacity),
      child: child,
    );
  }
}

class _MeshPainter extends CustomPainter {
  final Color lineColor;
  final double opacity;

  _MeshPainter({required this.lineColor, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: opacity)
      ..strokeWidth = 1;
    const spacing = 20.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) =>
      old.lineColor != lineColor || old.opacity != opacity;
}

/// Solar rooftop panel silhouette at the base of a gradient sky.
class RooftopSilhouette extends StatelessWidget {
  final Color silhouetteColor;
  final double opacity;
  final double height;

  const RooftopSilhouette({
    super.key,
    this.silhouetteColor = GSColors.navy700,
    this.opacity = 0.25,
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _RooftopPainter(silhouetteColor: silhouetteColor),
        ),
      ),
    );
  }
}

class _RooftopPainter extends CustomPainter {
  final Color silhouetteColor;

  _RooftopPainter({required this.silhouetteColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Rooftop silhouette shape
    final silhouette = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(w * 0.167, h * 0.5)
      ..lineTo(w * 0.36, h * 0.78)
      ..lineTo(w * 0.64, h * 0.4)
      ..lineTo(w * 0.87, h * 0.75)
      ..lineTo(w, h * 0.55)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(silhouette, Paint()..color = silhouetteColor);

    // Panel angle rack lines (dashed)
    final dashPaint = Paint()
      ..color = GSColors.gold500
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    _dashedLine(canvas, Offset(w * 0.026, h * 0.73), Offset(w * 0.154, h * 0.53), dashPaint);
    _dashedLine(canvas, Offset(w * 0.205, h * 0.72), Offset(w * 0.346, h * 0.56), dashPaint);
    final emeraldPaint = Paint()
      ..color = GSColors.green400
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    _dashedLine(canvas, Offset(w * 0.385, h * 0.62), Offset(w * 0.615, h * 0.44), emeraldPaint);
    _dashedLine(canvas, Offset(w * 0.667, h * 0.58), Offset(w * 0.846, h * 0.70), dashPaint);
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    const dash = 3.0;
    const gap = 3.0;
    final dir = (b - a) / total;
    var traveled = 0.0;
    while (traveled < total) {
      final from = a + dir * traveled;
      final to = from + dir * min(dash, total - traveled);
      canvas.drawLine(from, to, paint);
      traveled += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RooftopPainter old) =>
      old.silhouetteColor != silhouetteColor;
}

/// Radiant golden sun logo with two rotating dashed orbital rings + orbiting
/// photon sparks — matches the splash screen design.
class SolarSunLogo extends StatefulWidget {
  final double size;

  const SolarSunLogo({super.key, this.size = 160});

  @override
  State<SolarSunLogo> createState() => _SolarSunLogoState();
}

class _SolarSunLogoState extends State<SolarSunLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
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
    final s = widget.size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = _controller.value * 2 * pi;
        final pulse = 0.5 + 0.5 * sin(_controller.value * 2 * pi);
        return SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating dashed amber ring
              Transform.rotate(
                angle: angle,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GSColors.gold500.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: CustomPaint(painter: _DashCirclePainter(GSColors.gold500)),
                ),
              ),
              // Second rotating dashed emerald ring (reverse)
              Transform.rotate(
                angle: -angle * 1.3,
                child: Container(
                  width: s - 16,
                  height: s - 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GSColors.green400.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: CustomPaint(painter: _DashCirclePainter(GSColors.green400)),
                ),
              ),
              // Orbiting photon sparks
              Transform.rotate(
                angle: angle,
                child: Stack(
                  children: [
                    Positioned(
                      top: -4,
                      left: s / 2 - 5,
                      child: _Spark(size: 10, color: GSColors.gold300),
                    ),
                    Positioned(
                      bottom: -4,
                      left: s / 2 - 4,
                      child: _Spark(size: 8, color: GSColors.green400),
                    ),
                  ],
                ),
              ),
              // Radiant golden sun disc (pulses)
              Transform.scale(
                scale: 1 + pulse * 0.03,
                child: Container(
                  width: s * 0.6,
                  height: s * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFB74D), Color(0xFFFFCA28), Color(0xFFFFE082)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GSColors.gold500.withValues(alpha: 0.45 + pulse * 0.2),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _SunDiscFace(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Spark extends StatelessWidget {
  final double size;
  final Color color;
  const _Spark({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 8)],
      ),
    );
  }
}

class _SunDiscFace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Solar ray geometric flare
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: CustomPaint(painter: _RayFlarePainter()),
            ),
          ),
          // Central sun icon
          const Icon(Icons.wb_sunny_rounded, color: GSColors.navy900, size: 34),
        ],
      ),
    );
  }
}

class _RayFlarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final paint = Paint()..color = Colors.white;
    final path = Path();
    const n = 12;
    for (var i = 0; i < n; i++) {
      final a = (2 * pi / n) * i;
      final inner = r * 0.45;
      final outer = r * 1.1;
      path.moveTo(center.dx + cos(a) * inner, center.dy + sin(a) * inner);
      path.lineTo(center.dx + cos(a) * outer, center.dy + sin(a) * outer);
    }
    for (var i = 0; i < n; i++) {
      final a = (2 * pi / n) * i;
      canvas.drawLine(
        center + Offset(cos(a), sin(a)) * r * 0.4,
        center + Offset(cos(a), sin(a)) * r,
        paint..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Draws dashes along a circle.
class _DashCirclePainter extends CustomPainter {
  final Color color;
  _DashCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dash = 6.0;
    const gap = 8.0;
    var startAngle = 0.0;
    while (startAngle < 2 * pi) {
      final sweep = (dash / radius).clamp(0.0, 2 * pi);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweep, false, paint);
      startAngle += (dash + gap) / radius;
    }
  }

  @override
  bool shouldRepaint(covariant _DashCirclePainter old) => old.color != color;
}

/// Small battery-charge sun indicator pill (bottom of splash).
class BatteryChargeIndicator extends StatefulWidget {
  final bool animate;
  const BatteryChargeIndicator({super.key, this.animate = true});

  @override
  State<BatteryChargeIndicator> createState() => _BatteryChargeIndicatorState();
}

class _BatteryChargeIndicatorState extends State<BatteryChargeIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
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
    final opacity = widget.animate ? 0.7 + 0.3 * _controller.value : 1.0;
    final scale = widget.animate ? 0.97 + 0.06 * _controller.value : 1.0;
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 12),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small pulsing sun icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB74D), Color(0xFFFFCA28)],
                  ),
                  boxShadow: [
                    BoxShadow(color: GSColors.gold500.withValues(alpha: 0.8), blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.wb_sunny_rounded, size: 14, color: GSColors.navy900),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('INITIALIZING SYSTEM',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(width: 6),
                      Text('100%',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: GSColors.gold300)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Segmented charge bar
                  Row(
                    children: [
                      _segment(GSColors.gold500),
                      const SizedBox(width: 2),
                      _segment(GSColors.gold300),
                      const SizedBox(width: 2),
                      _segment(GSColors.green400, animate: true),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segment(Color color, {bool animate = false}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 24,
          height: 6,
          decoration: BoxDecoration(
            color: animate ? color.withValues(alpha: 0.6 + 0.4 * _controller.value) : color,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }
}