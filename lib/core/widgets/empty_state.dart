import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'sun_loader.dart';

/// Friendly empty state with sun illustration.
class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;
  final bool showSun;

  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
    this.actionLabel,
    this.showSun = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSun)
              const SunPulseAnimation(size: 100, showPhotons: false)
            else if (icon != null)
              Icon(icon, size: 64, color: GSColors.gold500.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(title,
                textAlign: TextAlign.center,
                style: GSTextStyles.headlineSmall.copyWith(color: GSColors.ink)),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message!,
                    textAlign: TextAlign.center,
                    style: GSTextStyles.bodyMedium
                        .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
              ),
            if (action != null && actionLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: action,
                  icon: Icon(Icons.add, color: GSColors.navy900),
                  label: Text(actionLabel!,
                      style: GSTextStyles.labelLarge.copyWith(color: GSColors.navy900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GSColors.gold500,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
