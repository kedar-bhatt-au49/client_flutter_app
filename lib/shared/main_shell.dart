import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/app_update_dialog.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/clients/client_list_screen.dart';
import '../features/followups/followup_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../providers/data_hub.dart';
import '../services/app_update_service.dart';

/// Main app shell — glassmorphic floating bottom navigation with 5 tabs.
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
  void initState() {
    super.initState();
    // Start Firestore real-time sync now that the user is authenticated.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DataHub>().startSync();
      _checkForUpdateSilently();
    });
  }

  /// Background update check on launch. Any failure is swallowed so a missing
  /// network or GitHub outage can never affect app startup.
  Future<void> _checkForUpdateSilently() async {
    try {
      final version = await AppUpdateService.instance.installedVersion();
      final info = await AppUpdateService.instance
          .checkForUpdate(currentVersionName: version.versionName);
      if (info != null && mounted) {
        await AppUpdateDialogs.showAvailable(context, info);
      }
    } catch (_) {
      // Ignored on purpose — the settings screen has a manual check.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GSColors.sky100,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// Floating glassmorphic bottom navigation bar — exact design.
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unreadFollowUps = context.watch<DataHub>().todayFollowUps.length;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xE6FFFFFF),
        border: Border(top: BorderSide(color: Color(0xCCE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14071440),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                index: 0,
                activeIcon: Icons.wb_sunny_rounded,
                icon: Icons.wb_sunny_outlined,
                label: 'Dashboard',
                active: currentIndex == 0,
              ),
              _navItem(
                index: 1,
                activeIcon: Icons.group_rounded,
                icon: Icons.group_outlined,
                label: 'Clients',
                active: currentIndex == 1,
              ),
              _navItem(
                index: 2,
                activeIcon: Icons.calendar_month_rounded,
                icon: Icons.calendar_month_outlined,
                label: 'Follow-ups',
                active: currentIndex == 2,
                showBadge: unreadFollowUps > 0,
              ),
              _navItem(
                index: 3,
                activeIcon: Icons.bar_chart_rounded,
                icon: Icons.bar_chart_outlined,
                label: 'Reports',
                active: currentIndex == 3,
              ),
              _navItem(
                index: 4,
                activeIcon: Icons.settings_rounded,
                icon: Icons.settings_outlined,
                label: 'Settings',
                active: currentIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData activeIcon,
    required IconData icon,
    required String label,
    required bool active,
    bool showBadge = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: active ? 36 : 32,
                  height: active ? 36 : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: active
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF9B417), Color(0xFFFFCA28), Color(0xFFFFE082)],
                          )
                        : null,
                    color: active ? null : Colors.transparent,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: GSColors.gold500.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    active ? activeIcon : icon,
                    color: active ? GSColors.navy900 : GSColors.ink.withValues(alpha: 0.45),
                    size: active ? 22 : 24,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: GSColors.followupMissed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? GSColors.gold500 : GSColors.ink.withValues(alpha: 0.45),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}