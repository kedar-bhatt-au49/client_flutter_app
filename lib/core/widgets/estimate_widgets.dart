/// ---------------------------------------------------------------------------
/// Reusable widgets for the Create Estimate wizard.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ── Shared InputDecoration for professional form fields ───────────────

class GSInputTheme {
  GSInputTheme._();

  static const double fieldBorderRadius = 12.0;

  static InputDecoration fieldDecoration({
    String? hint,
    String? prefixText,
    String? suffixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isDense = true,
    String? errorText,
  }) {
    final hasError = errorText != null;
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldBorderRadius),
      borderSide: BorderSide(
        color: hasError
            ? GSColors.errorRed
            : GSColors.ink.withValues(alpha: 0.2),
        width: 1,
      ),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldBorderRadius),
      borderSide: const BorderSide(color: GSColors.gold500, width: 2),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldBorderRadius),
      borderSide: const BorderSide(color: GSColors.errorRed, width: 2),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle:
          GSTextStyles.bodyMedium.copyWith(color: GSColors.ink.withValues(alpha: 0.4)),
      prefixText: prefixText,
      prefixStyle:
          GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900),
      suffixText: suffixText,
      suffixStyle:
          GSTextStyles.bodyMedium.copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: isDense,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: GSColors.white,
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: focusBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      errorStyle: GSTextStyles.bodySmall.copyWith(color: GSColors.errorRed),
    );
  }
}

// ── Segmented progress bar ─────────────────────────────────────────

class EstimateProgressBar extends StatelessWidget {
  final int stepCount;
  final int currentStep;

  const EstimateProgressBar({
    super.key,
    required this.stepCount,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(stepCount, (i) {
          final completed = i <= currentStep;
          final fill = completed ? GSColors.teal500 : GSColors.pageBg;

          return Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Section header: icon chip + bold title ────────────────────────

class EstimateSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const EstimateSectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Rounded-square icon chip
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GSColors.navy500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: GSColors.navy500),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900),
          ),
        ],
      ),
    );
  }
}

// ── Custom radio group (navy-filled when selected) ──────────────────

class GsRadioGroup extends StatelessWidget {
  final String groupValue;
  final ValueChanged<String?> onChanged;
  final List<RadioOption> options;

  const GsRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length * 2 - 1, (i) {
        if (i.isOdd) return const SizedBox(width: 16);
        final opt = options[i ~/ 2];
        final selected = groupValue == opt.value;
        return _RadioOption(
          opt: opt,
          selected: selected,
          onTap: () => onChanged(opt.value),
        );
      }),
    );
  }
}

class RadioOption {
  final String label;
  final String value;

  RadioOption({required this.label, required this.value});
}

class _RadioOption extends StatelessWidget {
  final RadioOption opt;
  final bool selected;
  final VoidCallback onTap;

  const _RadioOption({
    required this.opt,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? GSColors.navy500 : Colors.transparent,
              border: Border.all(
                color: selected ? GSColors.navy500 : GSColors.ink.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 14, color: GSColors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            opt.label,
            style: GSTextStyles.bodyMedium.copyWith(
              color: selected ? GSColors.navy900 : GSColors.ink.withValues(alpha: 0.7),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── White input card with labeled field ───────────────────────────

class GsInputCard extends StatelessWidget {
  final String label;
  final bool required;
  final Widget input;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Widget? trailing;
  final bool focused;

  const GsInputCard({
    super.key,
    required this.label,
    this.required = false,
    required this.input,
    this.hint,
    this.helperText,
    this.errorText,
    this.padding,
    this.borderRadius = 16,
    this.trailing,
    this.focused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row
            Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: GSTextStyles.labelMedium.copyWith(
                    color: GSColors.navy900,
                    letterSpacing: 0.5,
                  ),
                ),
                if (required) ...[
                  const SizedBox(width: 2),
                  Text(
                    '*',
                    style: GSTextStyles.labelMedium.copyWith(
                      color: GSColors.errorRed,
                    ),
                  ),
                ],
              ],
            ),
            if (helperText != null && errorText == null) ...[
              const SizedBox(height: 6),
              Text(
                helperText!,
                style: GSTextStyles.bodySmall
                    .copyWith(color: GSColors.ink.withValues(alpha: 0.5)),
              ),
            ],
            if (errorText != null) ...[
              const SizedBox(height: 4),
              Text(
                errorText!,
                style: GSTextStyles.bodySmall.copyWith(color: GSColors.errorRed),
              ),
            ],
            const SizedBox(height: 8),
            input,
          ],
        ),
      ),
    );
  }
}

// ── Lead stage tag with colored dot ───────────────────────────────

class LeadStageTag extends StatelessWidget {
  final String label;
  final Color dotColor;
  final bool selected;
  final VoidCallback? onTap;

  const LeadStageTag({
    super.key,
    required this.label,
    required this.dotColor,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? GSColors.teal500.withValues(alpha: 0.12)
              : GSColors.ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? GSColors.teal500
                : GSColors.ink.withValues(alpha: 0.2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GSTextStyles.labelMedium.copyWith(
                color: selected ? GSColors.teal500 : GSColors.ink,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky bottom action bar ──────────────────────────────────────

class ActionBarButtonBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String backText;
  final String nextText;
  final bool nextEnabled;
  final bool nextLoading;

  const ActionBarButtonBar({
    super.key,
    this.onBack,
    this.onNext,
    this.backText = 'Back',
    this.nextText = 'Next',
    this.nextEnabled = true,
    this.nextLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: GSColors.white,
        boxShadow: [
          BoxShadow(
            color: GSColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Secondary (outline) button
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: GSColors.navy900,
                  side: BorderSide(
                      color: GSColors.ink.withValues(alpha: 0.3)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(backText,
                    style: GSTextStyles.labelLarge
                        .copyWith(color: GSColors.navy900)),
              ),
            ),
            const SizedBox(width: 12),
            // Primary (navy-filled) button
            Expanded(
              child: ElevatedButton(
                onPressed: nextEnabled ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GSColors.navy500,
                  foregroundColor: GSColors.white,
                  elevation: nextEnabled ? 4 : 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: nextLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GSColors.white,
                        ),
                      )
                    : Text(nextText,
                        style: GSTextStyles.labelLarge
                            .copyWith(color: GSColors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selector tile: value + chevron inside a bordered box ─────────────
// Used as a tappable dropdown-style field (e.g. Lead Stage).

class GsSelectorTile extends StatelessWidget {
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;
  final bool enabled;
  final bool focused;
  final String? errorText;
  final Widget? leading;

  const GsSelectorTile({
    super.key,
    required this.value,
    required this.valueColor,
    this.onTap,
    this.enabled = true,
    this.focused = false,
    this.errorText,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = errorText != null
        ? GSColors.errorRed
        : (focused
            ? GSColors.gold500
            : GSColors.ink.withValues(alpha: 0.15));
    final borderWidth = errorText != null || focused ? 2.0 : 1.0;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? GSColors.white : GSColors.pageBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                value,
                style: GSTextStyles.bodyMedium.copyWith(color: valueColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: enabled
                  ? GSColors.ink.withValues(alpha: 0.5)
                  : GSColors.ink.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
