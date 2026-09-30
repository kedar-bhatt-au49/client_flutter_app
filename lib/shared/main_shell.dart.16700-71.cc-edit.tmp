import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/widgets/gs_button.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/clients/client_list_screen.dart';
import '../features/followups/followup_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../providers/data_hub.dart';

/// Main app shell — bottom navigation with 5 tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  static const _pages = [
    DashboardScreen(),
    ClientListScreen(),
    FollowUpScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _BuildBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget? _buildFab() {
    // FAB appears on Clients tab and Follow-ups tab
    if (_currentIndex == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: GsButton(
          text: '',
          onPressed: () {
            // Navigate to add client
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Client screen')),
              );
            }
          },
          icon: Icons.add,
          width: 56,
          height: 56,
          borderRadius: 28,
          backgroundColor: GSColors.gold500,
          foregroundColor: GSColors.navy900,
        ),
      );
    }
    return null;
  }
}

class _BuildBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BuildBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.dashboard_outlined, 'Dashboard'),
    (Icons.group_outlined, 'Clients'),
    (Icons.event_note_outlined, 'Follow-ups'),
    (Icons.bar_chart_outlined, 'Reports'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadFollowUps = context.watch<DataHub>().todayFollowUps.length;

    return Container(
      decoration: BoxDecoration(
        color: GSColors.glassWhiteDark,
        border: Border(
          top: BorderSide(
              color: GSColors.white.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: GSColors.glassWhiteDark,
          selectedItemColor: GSColors.gold500,
          unselectedItemColor: GSColors.ink.withValues(alpha: 0.4),
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: List.generate(_items.length, (i) {
            final (icon, label) = _items[i];
            final selected = i == currentIndex;
            final showBadge = i == 2 && unreadFollowUps > 0;

            return BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: selected ? GSGradients.sun : null,
                      shape: BoxShape.circle,
                      color: selected
                          ? null
                          : GSColors.ink.withValues(alpha: 0.05),
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? GSColors.navy900
                          : GSColors.ink.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: GSColors.followupPending,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: label,
            );
          }),
        ),
      ),
    );
  }
}
