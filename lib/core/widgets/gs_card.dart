import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';

/// Branded card with optional gold accent and glassmorphism support.
class GsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool glass;
  final bool goldAccent;
  final bool elevated;
  final VoidCallback? onTap;
  final Border? border;

  const GsCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.width,
    this.height,
    this.borderRadius = 20,
    this.glass = false,
    this.goldAccent = false,
    this.elevated = true,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = glass
        ? GSColors.glassWhiteDark
        : (color ?? GSColors.white);

    Widget cardChild = child;
    if (padding != null) {
      cardChild = Padding(padding: padding!, child: child);
    }

    final decoration = BoxDecoration(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ??
          (goldAccent
              ? Border.all(color: GSColors.gold500.withValues(alpha: 0.3), width: 2)
              : null),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: GSColors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : [],
      gradient: goldAccent && !glass
          ? GSGradients.sun
          : null,
    );

    final container = Container(
      width: width,
      height: height,
      decoration: decoration,
      child: cardChild,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

/// Thin gold accent card used for compact stat displays.
class GsStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const GsStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GsCard(
      goldAccent: false,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? GSColors.navy700).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? GSColors.navy700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: GSColors.ink.withValues(alpha: 0.7))),
                Text(value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: GSColors.navy900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
