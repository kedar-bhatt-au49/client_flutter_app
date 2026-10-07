import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_hub.dart';
import '../auth/login_screen.dart';

/// Settings — exact design: navy header, profile, app settings, security,
/// notifications, support, about, sign out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _gold = Color(0xFFF9B417);
  static const _goldLight = Color(0xFFFFCA40);
  static const _goldDark = Color(0xFFC98A1B);
  static const _navy = Color(0xFF071440);
  static const _navyDeep = Color(0xFF0B1F5C);
  static const _sky = Color(0xFFEAF4FF);
  static const _skyCard = Color(0xFFF0F7FF);
  static const _skyBorder = Color(0xFFD8E9FE);
  static const _slate = Color(0xFF627193);
  static const _dark = Color(0xFF0A1A44);
  static const _green = Color(0xFF1E7A43);
  static const _greenLight = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);

  bool _notificationsEnabled = true;
  bool _dailyReminder = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _changePassword(AuthProvider auth) async {
    final ctrl = TextEditingController();
    final newPass = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change password'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
              labelText: 'New password', hintText: 'At least 6 characters'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (newPass == null || newPass.isEmpty || !mounted) return;
    final ok = await auth.changePassword(newPass);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Password updated'
          : (auth.errorMessage ?? 'Could not update password')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: _sky,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _gold))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileCard(user),
                        const SizedBox(height: 14),
                        _buildAppSettings(),
                        const SizedBox(height: 14),
                        _buildSecurity(auth),
                        const SizedBox(height: 14),
                        _buildNotifications(),
                        const SizedBox(height: 14),
                        _buildSupport(),
                        const SizedBox(height: 14),
                        _buildAbout(),
                        const SizedBox(height: 14),
                        _buildSignOut(auth),
                        const SizedBox(height: 16),
                        _buildFooter(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_navy, Color(0xFF091B4E), _navyDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Settings',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.4)),
                        SizedBox(width: 8),
                        _PulseDot(),
                      ],
                    ),
                    const Text('Global Solar 2.0',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xCCD0E6FF))),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showAboutDialog(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_gold, _goldDark, _goldLight],
                    ),
                    boxShadow: [
                      BoxShadow(color: _gold.withValues(alpha: 0.4), blurRadius: 12),
                    ],
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile card ───────────────────────────────────────────────
  Widget _buildProfileCard(dynamic user) {
    final name = user?.displayName ?? 'Global Solar Admin';
    final role = user?.displayRole ?? 'Founder • Owner';
    final email = user?.email ?? GSUsers.founderEmail;
    final isOwner = user?.role == 'owner';

    return _card(
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_goldDark, _gold, Color(0xFFFFE28A)],
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_navyDeep, _navy],
                    ),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: _goldLight, size: 28),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _greenLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _gold),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(role,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _slate)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _slate)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8EE),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Icon(isOwner ? Icons.verified_user_rounded : Icons.badge_rounded,
                    size: 13, color: _green),
                const SizedBox(width: 4),
                Text(isOwner ? 'OWNER' : 'CO-FOUNDER',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: _green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── App settings ───────────────────────────────────────────────
  Widget _buildAppSettings() {
    return _sectionCard(
      icon: Icons.settings_rounded,
      title: 'App Settings',
      trailing: 'EPC Suite',
      children: [
        _infoRow(Icons.access_time_rounded, const Color(0xFF2563EB),
            'Working Hours', GSWorkingHours.en),
        _infoRow(Icons.bolt_rounded, const Color(0xFFD97706),
            'Default Package', '3.69 kW',
            valueHighlight: true),
        _infoRow(Icons.calendar_today_rounded, _green,
            'Prices Last Updated', GSTax.pricesLastUpdated),
      ],
    );
  }

  // ── Security ───────────────────────────────────────────────────
  Widget _buildSecurity(AuthProvider auth) {
    return _sectionCard(
      icon: Icons.shield_rounded,
      title: 'Security',
      trailingWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: _greenLight),
            ),
            const SizedBox(width: 5),
            const Text('Active',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _green)),
          ],
        ),
      ),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_reset_rounded,
              color: Color(0xFF2563EB)),
          title: const Text('Change Password',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1B3D))),
          subtitle: const Text('Update your account password',
              style: TextStyle(fontSize: 12, color: Color(0xFF627193))),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF627193)),
          onTap: () => _changePassword(auth),
        ),
      ],
    );
  }

  // ── Notifications ──────────────────────────────────────────────
  Widget _buildNotifications() {
    return _sectionCard(
      icon: Icons.notifications_rounded,
      title: 'Notifications',
      children: [
        _toggleRow(
          label: 'Follow-up Reminders',
          subtitle: 'Get reminders for due follow-ups',
          value: _notificationsEnabled,
          onChanged: (v) => setState(() => _notificationsEnabled = v),
        ),
        _toggleRow(
          label: 'Daily Summary',
          subtitle: 'Daily reminder for pending items',
          value: _dailyReminder,
          onChanged: (v) => setState(() => _dailyReminder = v),
        ),
      ],
    );
  }

  // ── Support ────────────────────────────────────────────────────
  Widget _buildSupport() {
    return _sectionCard(
      icon: Icons.headset_mic_rounded,
      title: 'Support',
      children: [
        _actionRow(
          icon: Icons.chat_rounded,
          bg: _greenLight,
          label: 'WhatsApp Support',
          onTap: () {
            final msg = Uri.encodeComponent('Hello Global Solar 2.0 team,');
            launchUrl(
                Uri.parse('https://wa.me/${GSUsers.whatsappNumber}?text=$msg'));
          },
        ),
        _actionRow(
          icon: Icons.call_rounded,
          bg: _green,
          label: 'Call Support',
          onTap: () => launchUrl(Uri.parse('tel:+91${GSUsers.founderPhone}')),
        ),
        _actionRow(
          icon: Icons.mail_rounded,
          bg: _navyDeep,
          label: 'Email Support',
          onTap: () => launchUrl(Uri.parse('mailto:${GSUsers.founderEmail}')),
        ),
      ],
    );
  }

  // ── About ──────────────────────────────────────────────────────
  Widget _buildAbout() {
    return _sectionCard(
      icon: Icons.info_rounded,
      title: 'About',
      children: [
        _simpleInfoRow('Company', 'Global Solar 2.0'),
        _addressRow('Address',
            'Shop No. 4A, Sukhsagar Complex, Bhavnagar, Gujarat 364002'),
        _dotInfoRow('Panel Brand', const Color(0xFF3B82F6), 'Adani TOPCon (G2G)'),
        _dotInfoRow('Inverter Brand', const Color(0xFFF59E0B), 'Polycab'),
      ],
    );
  }

  // ── Sign out ───────────────────────────────────────────────────
  Widget _buildSignOut(AuthProvider auth) {
    return InkWell(
      onTap: () async {
        final navigator = Navigator.of(context);
        context.read<DataHub>().stopSync();
        await auth.signOut();
        if (!mounted) return;
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xCCFECACA)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F0B1F5C), blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 18, color: _red),
            SizedBox(width: 8),
            Text('Sign Out',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _red)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text('Global Solar 2.0 v1.0.0',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: _slate)),
        const SizedBox(height: 4),
        Text(
          'Designed & Developed for Mr. Jayrajsinh S. Umat & Mr. Gopalsinh J. Parmar',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 10, color: _slate.withValues(alpha: 0.7), height: 1.4),
        ),
      ],
    );
  }

  // ── Building blocks ────────────────────────────────────────────
  Widget _sectionCard({
    required IconData icon,
    required String title,
    String? trailing,
    Widget? trailingWidget,
    required List<Widget> children,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconTile(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
              ),
              if (trailingWidget != null)
                trailingWidget
              else if (trailing != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x99E2E8F0)),
                  ),
                  child: Text(trailing,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _slate)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, Color iconColor, String label, String value,
      {bool valueHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _skyCard,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _slate)),
          ),
          Container(
            padding: valueHighlight
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                : EdgeInsets.zero,
            decoration: valueHighlight
                ? BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x99FDE68A)),
                  )
                : null,
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueHighlight
                        ? const Color(0xFF78350F)
                        : _dark)),
          ),
        ],
      ),
    );
  }

  Widget _simpleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _slate)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
        ],
      ),
    );
  }

  Widget _addressRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: _slate)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _skyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x99DBEAFE)),
            ),
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, color: _dark, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _dotInfoRow(String label, Color dotColor, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _slate)),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
        ],
      ),
    );
  }

  Widget _toggleRow({
    IconData? icon,
    Color? iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _skyCard,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Icon(icon, size: 17, color: iconColor ?? _slate),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: _slate)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _goldSwitch(value, onChanged),
        ],
      ),
    );
  }

  Widget _goldSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(colors: [_gold, _goldDark])
              : null,
          color: value ? null : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color bg,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _dark)),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _skyBorder.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F0B1F5C), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  Widget _iconTile(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _sky,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 17, color: _navyDeep),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('About',
            style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                color: _navy)),
        content: const Text(
          'Global Solar 2.0 — Client Management Suite\n\n'
          'Designed & Developed for Mr. Jayrajsinh S. Umat & Mr. Gopalsinh J. Parmar.',
          style: TextStyle(fontSize: 13, height: 1.5, color: _slate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: _goldDark)),
          ),
        ],
      ),
    );
  }
}

/// Pulsing gold dot.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1400), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF9B417),
          boxShadow: [BoxShadow(color: Color(0xFFF9B417), blurRadius: 8)],
        ),
      ),
    );
  }
}