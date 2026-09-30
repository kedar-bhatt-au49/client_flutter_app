import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Solar-cell grid pattern — drawn as a canvas decoration or divider.
class SolarGridDivider extends StatelessWidget {
  final double height;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const SolarGridDivider({
    super.key,
    this.height = 1,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height == 1 ? 2 : height,
      decoration: BoxDecoration(
        color: color ?? GSColors.gold500.withValues(alpha: 0.3),
      ),
    );
  }
}

/// Solar grid pattern painted on canvas — use as a background decoration.
class SolarGridPainter extends CustomPainter {
  final Color color;
  final double cellSize;

  SolarGridPainter({this.color = GSColors.gold500, this.cellSize = 20});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.08);

    // Diagonal grid pattern
    for (double x = 0; x < size.width + size.height; x += cellSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SolarGridPainter old) =>
      old.color != color || old.cellSize != cellSize;
}

/// Diagonal light ray pattern.
class LightRayPainter extends CustomPainter {
  final Color color;

  LightRayPainter({this.color = GSColors.gold500});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1.5;

    for (var i = 0; i < 6; i++) {
      final x = (size.width / 6) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.width / 12, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LightRayPainter old) =>
      old.color != color;
}
