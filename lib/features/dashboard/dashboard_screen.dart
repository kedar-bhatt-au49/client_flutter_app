import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/gs_card.dart';
import '../../core/widgets/sun_loader.dart';
import '../../features/quotes/quotation_form_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_hub.dart';

/// Home / Dashboard — stats cards, today's follow-ups, pipeline snapshot.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    // Data is live from Hive; just trigger a reload
    final hub = context.read<DataHub>();
    await hub.init();
  }

  Future<void> _openWhatsApp(BuildContext context, String phone, String name) async {
    final message = Uri.encodeComponent(
        'Hello $name, this is Global Solar 2.0. Following up on your solar inquiry.');
    final url = Uri.parse('https://wa.me/91$phone?text=$message');
    final messenger = ScaffoldMessenger.of(context);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      messenger
          .showSnackBar(const SnackBar(content: Text('WhatsApp not available')));
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
    final auth = context.watch<AuthProvider>();
    final dataHub = context.watch<DataHub>();

    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: CustomScrollView(
          slivers: [
            // ── App bar ───────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: GSColors.navy900,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Good ${DateTime.now().hour < 12 ? "Morning" : "Afternoon"}, ${auth.currentUser?.name.split(' ').first ?? 'Admin'}',
                  style: GSTextStyles.headlineMedium.copyWith(color: GSColors.white),
                ),
                centerTitle: false,
                background: Container(
                  decoration: const BoxDecoration(gradient: GSGradients.sky),
                  child: Stack(
                    children: [
                      const Align(
                        alignment: Alignment(0.8, 0.2),
                        child: SunPulseAnimation(size: 120, showPhotons: true),
                      ),
                      Align(
                        alignment: Alignment(-0.8, -0.5),
                        child: Container(
                          width: 80,
                          height: 80,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: GSColors.white),
                  onPressed: () => _refresh(context),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Today — ${DateTime.now()}',
                    style: GSTextStyles.bodySmall
                        .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
              ),
            ),

            // ── Stats cards ───────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildStatsCards(context, dataHub),
            ),

            // ── Quick actions: Create Quotation ─────────────────────
            SliverToBoxAdapter(
              child: _buildQuickActions(context),
            ),

            // ── Pipeline snapshot ─────────────────────────────────
            SliverToBoxAdapter(
              child: _buildPipeline(context, dataHub),
            ),

            // ── Today's follow-ups ────────────────────────────────
            SliverToBoxAdapter(
              child: _buildTodayFollowUps(context, dataHub),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, DataHub dataHub) {
    final stats = dataHub.getDashboardStats();
    final items = [
      (Icons.leaderboard_rounded, 'New Leads', '${stats.newLeads}',
          GSColors.statusNew, stats.newLeads > 0),
      (Icons.event_note_rounded, "Today's FUs", '${stats.todayFollowUps}',
          GSColors.followupPending, stats.todayFollowUps > 0),
      (Icons.receipt_long_rounded, 'Pending Quotes', '${stats.pendingQuotes}',
          GSColors.blue500, stats.pendingQuotes > 0),
      (Icons.solar_power, 'Installed', '${stats.installed}',
          GSColors.statusInstalled, stats.installed > 0),
      (Icons.payments_rounded, 'Revenue', '₹${(stats.totalRevenue).formatWithComma()}',
          GSColors.green600, stats.totalRevenue > 0),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final crossCount = isWide ? 5 : (constraints.maxWidth > 400 ? 3 : 2);
          final spacing = 12.0;
          final cardWidth =
              (constraints.maxWidth - (spacing * (crossCount - 1))) / crossCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final (icon, label, value, color, hasData) = item;
              return SizedBox(
                width: cardWidth,
                child: _StatCard(
                  icon: icon,
                  label: label,
                  value: value,
                  color: color,
                  hasData: hasData,
                  animate: i < 5,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GsCard(
            padding: const EdgeInsets.all(16),
            goldAccent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GSColors.gold500.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: GSColors.navy900,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quotation',
                      style: GSTextStyles.headlineSmall
                          .copyWith(color: GSColors.navy900),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Generate and share a solar quotation for a new client.',
                  style: GSTextStyles.bodySmall
                      .copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 12),
                GsButton(
                  text: 'Create Quotation',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QuotationFormScreen(),
                      ),
                    );
                  },
                  icon: Icons.receipt_long,
                  fullWidth: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GsCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GSColors.teal500.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.calculate,
                        color: GSColors.navy900,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Estimate',
                      style: GSTextStyles.headlineSmall
                          .copyWith(color: GSColors.navy900),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Build a detailed solar estimate with our price calculator.',
                  style: GSTextStyles.bodySmall
                      .copyWith(color: GSColors.ink.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 12),
                GsButton(
                  text: 'Create Estimate',
                  onPressed: () {
                    Navigator.of(context).pushNamed('/create-estimate');
                  },
                  icon: Icons.calculate,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeline(BuildContext context, DataHub dataHub) {
    final pipeline = dataHub.pipelineEntries;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GsCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pipeline Snapshot',
                style: GSTextStyles.headlineSmall
                    .copyWith(color: GSColors.navy900)),
            const SizedBox(height: 12),
            ...pipeline.asMap().entries.map((entry) {
              final i = entry.key;
              final label = entry.value.key;
              final count = entry.value.value;
              final isActive = count > 0;
              final isLast = i == pipeline.length - 1;
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? GSColors.gold500
                              : GSColors.ink.withValues(alpha: 0.2),
                          border: Border.all(
                              color: isActive
                                  ? GSColors.navy900
                                  : GSColors.ink.withValues(alpha: 0.1),
                              width: 2),
                        ),
                        child: isActive
                            ? const Icon(Icons.check,
                                size: 16, color: GSColors.navy900)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(label,
                            style: GSTextStyles.bodyMedium.copyWith(
                                color: isActive
                                    ? GSColors.navy900
                                    : GSColors.ink.withValues(alpha: 0.5))),
                      ),
                      Text('$count',
                          style: GSTextStyles.bodyLargeSemiBold
                              .copyWith(color: GSColors.navy900)),
                    ],
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      width: 2,
                      height: 16,
                      color: GSColors.ink.withValues(alpha: 0.1),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayFollowUps(BuildContext context, DataHub dataHub) {
    final today = dataHub.todayFollowUps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Follow-ups",
                  style: GSTextStyles.headlineSmall
                      .copyWith(color: GSColors.navy900)),
              if (today.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Navigate to full follow-ups screen
                  },
                  child: Text('See all (${today.length})',
                      style: GSTextStyles.bodySmall
                          .copyWith(color: GSColors.blue500)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (today.isEmpty)
            GsCard(
              padding: const EdgeInsets.all(24),
              child: const EmptyState(
                title: 'No follow-ups today',
                message: 'All caught up! New follow-ups will appear here.',
                icon: Icons.check_circle_outline,
                showSun: false,
              ),
            )
          else
            ...today.map((f) => _FollowUpTile(
                  followUp: f,
                  onCall: () => _openPhone(context, _getPhoneForClient(context, f.clientId)),
                  onWhatsApp: () {
                    final client = dataHub.getClient(f.clientId);
                    if (client != null) {
                      _openWhatsApp(context, client.phone, client.name);
                    }
                  },
                )),
        ],
      ),
    );
  }

  String _getPhoneForClient(BuildContext context, String clientId) {
    final client = context.read<DataHub>().getClient(clientId);
    return client?.phone ?? '0000000000';
  }
}

/// Individual stat card with animated counter.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool hasData;
  final bool animate;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.hasData,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    return GsCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (hasData)
                const Icon(Icons.trending_up, size: 16, color: GSColors.green600),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GSTextStyles.headlineSmall.copyWith(
                  color: GSColors.navy900, fontWeight: FontWeight.w700)),
          Text(label,
              style: GSTextStyles.bodySmall
                  .copyWith(color: GSColors.ink.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

/// Follow-up item in the today's list.
class _FollowUpTile extends StatelessWidget {
  final dynamic followUp;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _FollowUpTile({
    required this.followUp,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final clientName = followUp.clientId; // Will be resolved by provider
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GsCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Time indicator
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: followUp.isOverdue
                    ? GSColors.followupMissed.withValues(alpha: 0.15)
                    : GSColors.gold500.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                followUp.isOverdue
                    ? Icons.warning_rounded
                    : Icons.access_time_rounded,
                color: followUp.isOverdue
                    ? GSColors.followupMissed
                    : GSColors.gold500,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Follow-up — ${followUp.timeFormatted}',
                      style: GSTextStyles.bodyMediumSemiBold
                          .copyWith(color: GSColors.navy900)),
                  Text(clientName,
                      style: GSTextStyles.bodyMedium
                          .copyWith(color: GSColors.ink.withValues(alpha: 0.7))),
                ],
              ),
            ),

            // Quick actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone, color: GSColors.green600, size: 20),
                  onPressed: onCall,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: GSColors.green600, size: 20),
                  onPressed: onWhatsApp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
