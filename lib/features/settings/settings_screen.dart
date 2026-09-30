import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/gs_card.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/sun_loader.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';

/// Settings — app config, biometrics, notifications, about, sign out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminder = false;
  bool _biometricsEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final auth = context.read<AuthProvider>();
    _biometricsEnabled = auth.biometricsEnabled;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: SunLoader())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── User info ─────────────────────────────────────
                  if (user != null) _buildUserInfo(user),
                  const SizedBox(height: 16),

                  // ── App Settings ────────────────────────────────────
                  _buildSection('App Settings', [
                    _buildInfoRow(Icons.schedule, 'Working Hours',
                        GSWorkingHours.en),
                    _buildInfoRow(Icons.label, 'Default Package',
                        GSWorkingHours.en.contains("3.69") ? "3.69 kW" : "3.69"),
                    _buildInfoRow(Icons.update, 'Prices Last Updated',
                        GSTax.pricesLastUpdated),
                  ]),
                  const SizedBox(height: 16),

                  // ── Security ───────────────────────────────────────
                  _buildSection('Security', [
                    _buildToggleRow(
                      Icons.fingerprint,
                      'Biometric Unlock',
                      'Use fingerprint to open the app',
                      _biometricsEnabled,
                      (v) async {
                        setState(() => _biometricsEnabled = v ?? false);
                        final messenger = ScaffoldMessenger.of(context);
                        await auth.setBiometricsEnabled(v ?? false);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text((v ?? false)
                                  ? 'Biometric unlock enabled'
                                  : 'Biometric unlock disabled')),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // ── Notifications ────────────────────────────────────
                  _buildSection('Notifications', [
                    _buildToggleRow(
                      Icons.notifications,
                      'Follow-up Reminders',
                      'Get reminders for due follow-ups',
                      _notificationsEnabled,
                      (v) => setState(() => _notificationsEnabled = v ?? false),
                    ),
                    _buildToggleRow(
                      Icons.alarm,
                      'Daily Summary',
                      'Daily reminder for pending items',
                      _dailyReminder,
                      (v) => setState(() => _dailyReminder = v ?? false),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // ── Support ────────────────────────────────────────
                  _buildSection('Support', [
                    _buildActionRow(
                      Icons.chat_bubble_outline, 'WhatsApp Support', GSColors.green600,
                      () {
                        final msg = Uri.encodeComponent(
                            'Hello Global Solar 2.0 team,');
                        launchUrl(Uri.parse(
                            'https://wa.me/${GSUsers.whatsappNumber}?text=$msg'));
                      }),
                    _buildActionRow(
                      Icons.phone, 'Call Support', GSColors.green600,
                      () {
                        launchUrl(
                            Uri.parse('tel:+91${GSUsers.founderPhone}'));
                      }),
                    _buildActionRow(
                      Icons.email, 'Email Support', GSColors.navy700,
                      () {
                        launchUrl(Uri.parse(
                            'mailto:${GSUsers.founderEmail}'));
                      }),
                  ]),
                  const SizedBox(height: 16),

                  // ── About ───────────────────────────────────────────
                  _buildSection('About', [
                    _buildInfoRow(Icons.business, 'Company',
                        'Global Solar 2.0'),
                    _buildInfoRow(Icons.location_on, 'Address',
                        'Shop No. 4A, Sukhsagar Complex,\nBhavnagar, Gujarat 364002'),
                    _buildInfoRow(Icons.bolt, 'Panel Brand',
                        'Adani TOPCon (G2G)'),
                    _buildInfoRow(Icons.bolt, 'Inverter Brand', 'Polycab'),
                  ]),
                  const SizedBox(height: 24),

                  // ── Sign out ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: GsOutlinedButton(
                      text: 'Sign Out',
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await auth.signOut();
                        if (!mounted) return;
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      icon: Icons.logout,
                      color: GSColors.followupMissed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Global Solar 2.0 v1.0.0\nDesigned & Developed for\nMr. Jayrajsinh S. Umat & Mr. Gopalsinh J. Parmar',
                      textAlign: TextAlign.center,
                      style: GSTextStyles.bodySmall
                          .copyWith(color: GSColors.ink.withValues(alpha: 0.4))),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return GsCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style: GSTextStyles.headlineSmall
                    .copyWith(color: GSColors.navy900)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: GSColors.navy700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                style: GSTextStyles.bodyMedium.copyWith(color: GSColors.ink)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    IconData icon,
    String label,
    String subtitle,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: GSColors.navy700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GSTextStyles.bodyMediumSemiBold
                        .copyWith(color: GSColors.navy900)),
                Text(subtitle,
                    style: GSTextStyles.bodySmall
                        .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
              ],
            )),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: GSColors.gold500,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: GSTextStyles.bodyMedium.copyWith(color: GSColors.navy900)),
      onTap: onTap,
    );
  }

  Widget _buildUserInfo(dynamic user) {
    return GsCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: GSGradients.sun,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 30, color: GSColors.navy900),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName,
                    style: GSTextStyles.headlineMedium
                        .copyWith(color: GSColors.navy900)),
                Text(user.displayRole,
                    style: GSTextStyles.bodyMedium
                        .copyWith(color: GSColors.ink.withValues(alpha: 0.7))),
                Text(user.email,
                    style: GSTextStyles.bodySmall
                        .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
              ],
            ),
          ),
          GSStatusChip(status: user.role == 'owner' ? 'installed' : 'booked'),
        ],
      ),
    );
  }
}
