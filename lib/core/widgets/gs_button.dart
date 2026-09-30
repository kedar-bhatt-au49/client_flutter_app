import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_text_styles.dart';

/// Branded primary button — gold sun gradient with glow.
class GsButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;

  const GsButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48,
    this.fullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = fullWidth
        ? double.infinity
        : width ?? (icon != null ? null : 160);
    final gradient = backgroundColor == null
        ? GSGradients.sun
        : null;
    final fg = foregroundColor ?? GSColors.ink;

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Row(
            mainAxisSize:
                effectiveWidth == null ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Text(text,
                  style: GSTextStyles.labelLarge.copyWith(
                      color: fg, fontWeight: FontWeight.w700)),
            ],
          );

    final button = SizedBox(
      width: effectiveWidth,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? GSColors.gold500,
          foregroundColor: fg,
          elevation: backgroundColor == null ? 8 : 4,
          shadowColor: backgroundColor == null
              ? GSColors.gold500.withValues(alpha: 0.5)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );

    // Add gold glow decoration when using gradient
    if (backgroundColor == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: GSColors.gold500.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: button,
      );
    }

    return button;
  }
}

/// Secondary / outline button.
class GsOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const GsOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? GSColors.navy900;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, color: c, size: 20) : const SizedBox.shrink(),
      label: Text(text, style: GSTextStyles.labelLarge.copyWith(color: c)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: c.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
