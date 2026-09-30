import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_text_styles.dart';

/// Branded app bar — navy gradient background with optional gold accent.
class GsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final bool centerTitle;
  final double? toolbarHeight;
  final PreferredSizeWidget? bottom;
  final double elevation;

  const GsAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.centerTitle = false,
    this.toolbarHeight,
    this.bottom,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: GSTextStyles.headlineMedium.copyWith(color: GSColors.white),
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight,
      bottom: bottom,
      elevation: elevation,
      backgroundColor: backgroundColor ?? GSColors.navy900,
      foregroundColor: GSColors.white,
      flexibleSpace: backgroundColor == null
          ? Container(
              decoration: const BoxDecoration(gradient: GSGradients.sky),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight);
}

/// Glass-style bottom navigation bar.
class GsBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GsBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.dashboard_outlined, 'Dashboard'),
    (Icons.group_outlined, 'Clients'),
    (Icons.event_note_outlined, 'Follow-ups'),
    (Icons.bar_chart_outlined, 'Reports'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GSColors.glassWhiteDark,
        border: Border(
          top: BorderSide(color: GSColors.white.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: GSColors.glassWhiteDark,
          selectedItemColor: GSColors.gold500,
          unselectedItemColor: GSColors.ink.withValues(alpha: 0.5),
          selectedLabelStyle: GSTextStyles.labelMedium,
          unselectedLabelStyle: GSTextStyles.labelMedium,
          items: List.generate(_items.length, (i) {
            final (icon, label) = _items[i];
            final selected = i == currentIndex;
            return BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: selected ? GSGradients.sun : null,
                  shape: BoxShape.circle,
                  color: selected
                      ? null
                      : GSColors.ink.withValues(alpha: 0.05),
                ),
                child: Icon(icon,
                    color: selected ? GSColors.navy900 : GSColors.ink.withValues(alpha: 0.5),
                    size: 22),
              ),
              label: label,
            );
          }),
        ),
      ),
    );
  }
}
