import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/client.dart';
import '../../models/follow_up.dart';
import '../../models/installation.dart';
import '../../models/payment.dart';
import '../../models/quote.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_hub.dart';
import '../installations/installation_screen.dart';
import '../payments/payment_screen.dart';
import '../quotes/quote_builder_screen.dart';
import 'add_edit_client_screen.dart';

/// Client detail — exact design: navy header, profile, quick actions,
/// contact card, pipeline, follow-ups, quote, payments, installation.
class ClientDetailScreen extends StatelessWidget {
  final ClientModel client;

  const ClientDetailScreen({super.key, required this.client});

  Future<void> _openWhatsApp(BuildContext context, String phone, String name) async {
    final message = Uri.encodeComponent(
        'Hello $name, this is Global Solar 2.0 following up on your inquiry.');
    final url = Uri.parse('https://wa.me/91$phone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPhone(BuildContext context, String phone) async {
    final url = Uri.parse('tel:+91$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.isOwner;
    final client = hub.getClient(this.client.id) ?? this.client;

    final followUps = hub.getFollowUpsForClient(client.id);
    final quote = hub.getQuoteForClient(client.id);
    final payment = hub.getPaymentForClient(client.id);
    final installation = hub.getInstallationForClient(client.id);

    return Scaffold(
      backgroundColor: GSColors.sky100,
      body: RefreshIndicator(
        onRefresh: () => hub.init(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Navy header (scrolls with content) ────────────────
            _buildHeader(context, client),
            // ── Profile card, overlapping the header by 28px (Stitch -mt-7) ──
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildProfileCard(context, client),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              child: Column(
                children: [
                  _buildQuickActions(context, client),
                  const SizedBox(height: 14),
                  _buildContactCard(context, client),
                  const SizedBox(height: 14),
                  _buildPipelineCard(context, client),
                  const SizedBox(height: 14),
                  _buildFollowUpsCard(context, followUps),
                  const SizedBox(height: 14),
                  if (quote != null) ...[
                    _buildQuoteCard(context, quote, client),
                    const SizedBox(height: 14),
                  ],
                  if (payment != null) ...[
                    _buildPaymentCard(context, payment),
                    const SizedBox(height: 14),
                  ],
                  if (installation != null) ...[
                    _buildInstallationCard(context, installation),
                    const SizedBox(height: 14),
                  ],
                  // Edit + Delete
                  _buildEditButton(context, client),
                  if (isOwner) ...[
                    const SizedBox(height: 8),
                    _buildDeleteButton(context, hub, client.id),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, ClientModel client) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071440), Color(0xFF0B1F5C), Color(0xFF0B1F5C)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative sun glow
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      GSColors.gold500.withValues(alpha: 0.25),
                      GSColors.gold500.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Top nav row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 48),
              child: Row(
                children: [
                  // Back button (40px circle)
                  _headerIconButton(
                    icon: Icons.arrow_back_rounded,
                    bg: Colors.white.withValues(alpha: 0.1),
                    fg: Colors.white,
                    onTap: () => Navigator.pop(context),
                  ),
                  // Centered title + subtitle
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Client Details',
                                style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3)),
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: GSColors.gold500,
                                boxShadow: [
                                  BoxShadow(color: GSColors.gold500.withValues(alpha: 0.6), blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: Color(0xFFFFD86B)),
                            const SizedBox(width: 4),
                            Text('Kaliyabid, Bhavnagar',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Gold edit button (40px circle)
                  _headerIconButton(
                    icon: Icons.edit_rounded,
                    bg: GSColors.gold500,
                    fg: const Color(0xFF050E26),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => AddEditClientScreen(client: client)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: bg == GSColors.gold500
              ? [BoxShadow(color: GSColors.gold500.withValues(alpha: 0.4), blurRadius: 12)]
              : null,
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }

  // ── Profile card ───────────────────────────────────────────────
  Widget _buildProfileCard(BuildContext context, ClientModel client) {
    final letter = client.name.isNotEmpty ? client.name[0].toUpperCase() : '?';
    final statusColor = _statusColor(client.status);
    final pkg = client.preferredPackage != 'not-sure' ? client.preferredPackage : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xCCE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x14071440), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with status dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF071440), Color(0xFF0B1F5C), Color(0xFF12307F)],
                      ),
                      boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
                    ),
                    child: Center(
                      child: Text(letter,
                          style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(client.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F1B3D))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('ID #GS-2026',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                              ),
                              const SizedBox(width: 5),
                              Text(GSClientStatus.labelOf(client.status).toUpperCase(),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(client.createdAtFormatted,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 3 stat tiles
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                _statTile('PACKAGE', pkg != null ? '$pkg kW' : '—', const Color(0xFFEAF4FF), GSColors.blue500),
                const SizedBox(width: 10),
                _statTile('TYPE', client.propertyType, const Color(0xFFFFF8E1), GSColors.gold500),
                const SizedBox(width: 10),
                _statTile('MONTHLY BILL', '₹${client.monthlyBill.toInt()}', const Color(0xFFECFDF5), GSColors.green600),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color bg, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: accent)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F1B3D))),
          ],
        ),
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, ClientModel client) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'Call Client',
            icon: Icons.call_rounded,
            bg: GSColors.green600,
            onTap: () => _openPhone(context, client.phone),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            label: 'WhatsApp',
            icon: Icons.chat_rounded,
            bg: const Color(0xFF128C7E),
            onTap: () => _openWhatsApp(context, client.phone, client.name),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: bg == GSColors.green600
              ? [BoxShadow(color: GSColors.green600.withValues(alpha: 0.3), blurRadius: 12)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── Contact & property card ───────────────────────────────────
  Widget _buildContactCard(BuildContext context, ClientModel client) {
    return _sectionCard(
      title: 'Contact & Property',
      accent: GSColors.gold500,
      trailing: Text('Verified',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: GSColors.blue500)),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.phone_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: GSColors.blue500,
            label: 'Phone',
            value: client.phone,
            valueStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F1B3D)),
          ),
          _infoRow(
            icon: Icons.location_on_rounded,
            iconBg: const Color(0xFFFFF8E1),
            iconColor: GSColors.gold500,
            label: 'Area',
            value: client.displayArea,
          ),
          _infoRow(
            icon: Icons.home_rounded,
            iconBg: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF7C3AED),
            label: 'Property Type',
            value: client.propertyType,
          ),
          _infoRow(
            icon: Icons.receipt_long_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: GSColors.green600,
            label: 'Monthly Bill',
            value: '₹${client.monthlyBill.toInt()} / mo',
          ),
          _infoRow(
            icon: Icons.wb_sunny_rounded,
            iconBg: const Color(0xFFFFF8E1),
            iconColor: GSColors.gold500,
            label: 'Preferred Package',
            value: client.preferredPackage == 'not-sure'
                ? 'Not sure yet'
                : '${client.preferredPackage} kW',
            valueWidget: client.preferredPackage != 'not-sure'
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${client.preferredPackage} kW',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: GSColors.blue500, fontSize: 13)),
                  )
                : null,
          ),
          _infoRow(
            icon: Icons.group_rounded,
            iconBg: const Color(0xFFF0FDFA),
            iconColor: const Color(0xFF128C7E),
            label: 'Lead Source',
            value: client.source,
            valueWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 5),
                  Text(client.source,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    String? value,
    Widget? valueWidget,
    TextStyle? valueStyle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
          const Spacer(),
          valueWidget ??
              Text(value ?? '',
                  textAlign: TextAlign.right,
                  style: valueStyle ?? const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F1B3D))),
        ],
      ),
    );
  }

  // ── Pipeline card ─────────────────────────────────────────────
  Widget _buildPipelineCard(BuildContext context, ClientModel client) {
    const stages = ['New', 'Contacted', 'Quoted', 'Booked', 'Installed'];
    final current = _pipelineIndex(client.status);
    final isLast = current == stages.length - 1;

    return _sectionCard(
      title: 'Pipeline Status',
      trailing: GestureDetector(
        onTap: () => _changeStatus(context, client),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x99FFE0B2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stage ${current + 1} of ${stages.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309))),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded,
                  size: 16, color: Color(0xFFB45309)),
            ],
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          // 5-step horizontal progress — line passes through center of dots
          SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Background line at the dots' vertical center (top: 12px for 24px dots)
                Positioned(
                  left: 10,
                  right: 10,
                  top: 12,
                  child: Container(height: 4, color: const Color(0xFFE2E8F0)),
                ),
                // Filled gold line up to current step
                Positioned(
                  left: 10,
                  top: 12,
                  width: ((stages.length - 1) == 0 ? 1 : (current / (stages.length - 1))) *
                      (MediaQuery.of(context).size.width - 64),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF9B417), Color(0xFFFFB300)]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Step nodes row (24px dots at center, labels below)
                Row(
                  children: List.generate(stages.length, (i) {
                    final isActive = i <= current;
                    final isCurrent = i == current;
                    return Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? GSColors.gold500 : const Color(0xFFE2E8F0),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                          color: GSColors.gold500.withValues(alpha: 0.4),
                                          blurRadius: 8),
                                    ]
                                  : null,
                            ),
                            child: isActive
                                ? const Icon(Icons.check, size: 13, color: Color(0xFF050E26))
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(stages[i],
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                  color: isActive
                                      ? const Color(0xFF0F1B3D)
                                      : const Color(0xFF94A3B8))),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x99FFE0B2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${stages[current]} • ${isLast ? 'Completed' : 'Awaiting ${stages[current + 1]}'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF78350F)),
                  ),
                ),
                Text('Next: ${isLast ? '—' : stages[current + 1]}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changeStatus(BuildContext context, ClientModel client) {
    final hub = context.read<DataHub>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Update Pipeline Status',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ),
            ...GSClientStatus.all.map((s) => ListTile(
                  leading: Icon(
                    client.status == s
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: client.status == s
                        ? GSColors.gold500
                        : const Color(0xFF94A3B8),
                  ),
                  title: Text(GSClientStatus.labelOf(s)),
                  onTap: () {
                    hub.updateClient(
                        client.copyWith(status: s, updatedAt: DateTime.now()));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Status: ${GSClientStatus.labelOf(s)}')));
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  int _pipelineIndex(String status) {
    switch (status) {
      case GSClientStatus.newLead:
        return 0;
      case GSClientStatus.contacted:
      case GSClientStatus.siteVisit:
        return 1;
      case GSClientStatus.quoted:
        return 2;
      case GSClientStatus.booked:
        return 3;
      case GSClientStatus.installed:
      case GSClientStatus.subsidized:
        return 4;
      default:
        return 0;
    }
  }

  // ── Follow-ups card ───────────────────────────────────────────
  Widget _buildFollowUpsCard(BuildContext context, List<FollowUpModel> followUps) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [BoxShadow(color: Color(0x12071440), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: gold dot + title + badge (right after title), Add button far right
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFFF9B417)),
              ),
              const SizedBox(width: 8),
              const Text('Follow-ups',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F1B3D))),
              const SizedBox(width: 6),
              if (followUps.isNotEmpty)
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF3CD),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Text('${followUps.length}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  children: [
                    Text('+', style: TextStyle(fontSize: 15, color: GSColors.blue500)),
                    Text(' Add Follow-up',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: GSColors.blue500)),
                  ],
                ),
              ),
            ],
          ),
          // Body
          if (followUps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No follow-ups yet',
                  style: TextStyle(fontSize: 13, color: Color(0x990F1B3D))),
            )
          else
            Column(
              children: followUps
                  .take(3)
                  .map((f) => _FollowUpCard(followUp: f))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ── Quote card ────────────────────────────────────────────────
  Widget _buildQuoteCard(BuildContext context, QuoteModel quote, ClientModel client) {
    final pkg = gsPackageById(quote.packageId);
    final accepted = quote.status == 'accepted';

    return _sectionCard(
      title: 'Quotation',
      trailing: Row(
        children: [
          if (accepted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: GSColors.green600),
                  SizedBox(width: 4),
                  Text('Accepted',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: GSColors.green600)),
                ],
              ),
            )
          else
            Text('#QT-${quote.id.substring(0, 4).toUpperCase()}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(width: 4),
          _openChevron(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuoteBuilderScreen(
                  client: client,
                  existing: quote,
                ),
              ),
            ),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0x66EFF6FF)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x99DBEAFE)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text('${pkg?.kw ?? quote.kw} kW • ${pkg?.panels ?? quote.panels} Panels',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F1B3D))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Adani TOPCon',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: GSColors.blue500)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x80E2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Upfront', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      Text('₹${quote.upfront}',
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F1B3D))),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('After Subsidy', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      Text('₹${quote.afterSubsidy}',
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: GSColors.green600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      Text(quote.status.toUpperCase(),
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accepted ? GSColors.green600 : const Color(0xFFFF9800))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Full-width long gold button
            InkWell(
              onTap: () {
                final msg = Uri.encodeComponent(
                  'Hello ${client.name},\nHere is your solar quote:\n'
                  '${pkg?.kw ?? quote.kw} kW • ${pkg?.panels ?? quote.panels} panels\n'
                  'Upfront: ₹${quote.upfront}\nAfter subsidy: ₹${quote.afterSubsidy}\n\n'
                  'Final quote after free site survey.',
                );
                launchUrl(Uri.parse('https://wa.me/91${client.phone}?text=$msg'),
                    mode: LaunchMode.externalApplication);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF9B417), Color(0xFFFFCA28), Color(0xFFFFD86B)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: GSColors.gold500.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFF050E26)),
                    SizedBox(width: 8),
                    Text('View / Share Quotation PDF',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF050E26))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Payment card ──────────────────────────────────────────────
  Widget _buildPaymentCard(BuildContext context, PaymentModel payment) {
    return _sectionCard(
      title: 'Payments',
      trailing: _openChevron(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              clientId: client.id,
              clientName: client.name,
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          _paymentRow(
            label: 'Registration ₹${payment.registrationAmount}',
            paid: payment.registrationPaid,
            date: payment.registrationDateFormatted,
          ),
          _paymentRow(
            label: 'Balance Payment',
            paid: payment.balancePaid,
            date: payment.balanceDateFormatted,
          ),
        ],
      ),
    );
  }

  Widget _paymentRow({required String label, required bool paid, required String date}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: paid ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
            ),
            child: Icon(
              paid ? Icons.check_circle_rounded : Icons.schedule_rounded,
              size: 20,
              color: paid ? GSColors.green600 : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F1B3D))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: paid ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: paid ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
            ),
            child: Text(paid ? 'PAID' : 'PENDING',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: paid ? GSColors.green600 : const Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }

  // ── Installation card ─────────────────────────────────────────
  Widget _buildInstallationCard(BuildContext context, InstallationModel installation) {
    final stages = GSInstallStage.all;
    final currentIdx = installation.currentStageIndex;

    return _sectionCard(
      title: 'Installation',
      trailing: _openChevron(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => InstallationScreen(client: client)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ...List.generate(stages.length, (i) {
            final isComplete = i <= currentIdx;
            final isLast = i == stages.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isComplete ? GSColors.gold500 : const Color(0xFFE2E8F0),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: isComplete
                          ? const Icon(Icons.check, size: 12, color: Color(0xFF050E26))
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 24,
                        color: isComplete ? GSColors.gold500 : const Color(0xFFE2E8F0),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: Text(GSInstallStage.labelOf(stages[i]),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: isComplete ? FontWeight.w700 : FontWeight.w500,
                          color: isComplete ? const Color(0xFF0F1B3D) : const Color(0xFF94A3B8))),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Edit / Delete ─────────────────────────────────────────────
  Widget _buildEditButton(BuildContext context, ClientModel client) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddEditClientScreen(client: client)),
        );
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF9B417), Color(0xFFFFCA28), Color(0xFFFFD86B)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: GSColors.gold500.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, size: 18, color: Color(0xFF050E26)),
            SizedBox(width: 8),
            Text('Edit Client',
                style: TextStyle(
                    fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF050E26))),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, DataHub hub, String clientId) {
    return InkWell(
      onTap: () => _confirmDelete(context, hub, clientId),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GSColors.followupMissed.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, size: 18, color: GSColors.followupMissed),
            const SizedBox(width: 8),
            const Text('Delete Client',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: GSColors.followupMissed)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DataHub hub, String clientId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Client?'),
        content: const Text('This will remove the client and all linked data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              hub.deleteClient(clientId);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Client deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: GSColors.followupMissed)),
          ),
        ],
      ),
    );
  }

  // ── Shared section card ───────────────────────────────────────
  Widget _openChevron({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: GSColors.blue500.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chevron_right_rounded,
            size: 18, color: GSColors.blue500),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    Color accent = GSColors.gold500,
    Widget? trailing,
    Widget? titleBadge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [BoxShadow(color: Color(0x12071440), blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F1B3D))),
              ),
              ?titleBadge,
              ?trailing,
            ],
          ),
          child,
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case GSClientStatus.newLead:
        return const Color(0xFF2196F3);
      case GSClientStatus.contacted:
      case GSClientStatus.siteVisit:
        return const Color(0xFF9C27B0);
      case GSClientStatus.quoted:
        return const Color(0xFFFF9800);
      case GSClientStatus.booked:
        return const Color(0xFFF44336);
      case GSClientStatus.installed:
      case GSClientStatus.subsidized:
        return GSColors.green600;
      default:
        return Colors.grey;
    }
  }
}

/// Follow-up tile inside the detail screen.
class _FollowUpCard extends StatelessWidget {
  final dynamic followUp;

  const _FollowUpCard({required this.followUp});

  @override
  Widget build(BuildContext context) {
    final isOverdue = followUp.isOverdue;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xB3E2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isOverdue ? const Color(0xFFFFE4E6) : const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
                  size: 20,
                  color: isOverdue ? const Color(0xFFE11D48) : const Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text('Follow-up — ${followUp.timeFormatted}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F1B3D))),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isOverdue ? const Color(0xFFFFF1F2) : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(isOverdue ? 'Overdue' : 'Pending',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isOverdue ? const Color(0xFFBE123C) : const Color(0xFFB45309))),
                        ),
                      ],
                    ),
                    if (followUp.note != null && followUp.note!.isNotEmpty)
                      Text(followUp.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x99E2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _chipBtn(
                    label: 'Mark Done',
                    icon: Icons.check_rounded,
                    bg: const Color(0xFFECFDF5),
                    fg: GSColors.green600,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _chipBtn(
                    label: 'Reschedule',
                    icon: Icons.close_rounded,
                    bg: const Color(0xFFF1F5F9),
                    fg: const Color(0xFF64748B),
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipBtn({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}