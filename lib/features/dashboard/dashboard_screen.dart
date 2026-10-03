import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/solar_visuals.dart';
import '../../features/followups/add_follow_up_screen.dart';
import '../../features/installations/installation_screen.dart';
import '../../features/payments/payment_screen.dart';
import '../../features/quotes/quote_builder_screen.dart';
import '../../models/client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_hub.dart';

/// Dashboard — exact design: navy header + stats + quotation + pipeline + FUs.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
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
      backgroundColor: GSColors.sky100,
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: CustomScrollView(
          slivers: [
            // ── Navy header ─────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context, auth)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildDateRow(dataHub),
                  const SizedBox(height: 12),
                  _buildStatsCards(context, dataHub),
                  const SizedBox(height: 12),
                  _buildQuickActions(context, dataHub),
                  const SizedBox(height: 12),
                  _buildQuotationCard(context, dataHub),
                  const SizedBox(height: 12),
                  _buildPipeline(context, dataHub),
                  const SizedBox(height: 12),
                  _buildTodayFollowUps(context, dataHub),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    final firstName = auth.currentUser?.name.split(' ').first ?? 'Admin';
    final role = auth.currentUser?.role == 'owner' ? 'Founder' : 'Co-Founder';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071440), Color(0xFF0B1F5C)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  // Logo badge
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF9B417), Color(0xFFFFCA28), Color(0xFFFFE082)],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Color(0x40F9B417), blurRadius: 12, spreadRadius: 1),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF050E26),
                      ),
                      child: const Icon(Icons.solar_power_rounded,
                          color: GSColors.gold500, size: 26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$greeting, $firstName',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            )),
                        Text('$role • Global Solar 2.0',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: Colors.white.withValues(alpha: 0.75),
                            )),
                      ],
                    ),
                  ),
                  // Refresh
                  _roundIconButton(
                    icon: Icons.refresh_rounded,
                    bg: Colors.white.withValues(alpha: 0.1),
                    fg: Colors.white,
                    onTap: () => _refresh(context),
                  ),
                  const SizedBox(width: 8),
                  // Notification bell with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _roundIconButton(
                        icon: Icons.notifications_rounded,
                        bg: GSColors.gold500.withValues(alpha: 0.2),
                        fg: GSColors.gold500,
                        onTap: () {},
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: GSColors.followupMissed,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF071440), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Solar panel silhouette edge
              const RooftopSilhouette(silhouetteColor: GSColors.blue500, opacity: 0.15, height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: fg, size: 19),
      ),
    );
  }

  // ── Date row ───────────────────────────────────────────────────
  Widget _buildDateRow(DataHub dataHub) {
    final today = DateFormat('d MMM yyyy').format(DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: GSColors.blue500),
            const SizedBox(width: 6),
            Text('Today — $today',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: GSColors.ink.withValues(alpha: 0.6))),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: GSColors.blue500.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            children: [
              Icon(Icons.location_on_rounded, size: 13, color: GSColors.blue500),
              SizedBox(width: 4),
              Text('Bhavnagar & Talaja',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GSColors.blue500)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats cards ────────────────────────────────────────────────
  Widget _buildStatsCards(BuildContext context, DataHub dataHub) {
    final stats = dataHub.getDashboardStats();
    final items = [
      (Icons.person_add_rounded, 'New Leads', '${stats.newLeads}', GSColors.blue500, '+18%', _StatStyle.solid),
      (Icons.schedule_rounded, "Today's FUs", '${stats.todayFollowUps}', GSColors.gold500, 'Action req', _StatStyle.gold),
      (Icons.request_quote_rounded, 'Pending Quotes', '${stats.pendingQuotes}', GSColors.blue500, 'Active', _StatStyle.solid),
      (Icons.verified_rounded, 'Installed Plants', '${stats.installed}', GSColors.green600, 'Total', _StatStyle.green),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(item: items[0])),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(item: items[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(item: items[2])),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(item: items[3])),
          ],
        ),
        const SizedBox(height: 12),
        // Revenue full-width card
        _RevenueCard(revenue: stats.totalRevenue),
      ],
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, DataHub dataHub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Quick Actions',
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1B3D))),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFF9B417)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _quickActionTile(
                label: 'Add Follow-up',
                icon: Icons.event_available_rounded,
                color: GSColors.blue500,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddFollowUpScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionTile(
                label: 'Payments',
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF059669),
                onTap: () => _pickClient(context, dataHub, (client) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                          clientId: client.id, clientName: client.name)));
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionTile(
                label: 'Installation',
                icon: Icons.construction_rounded,
                color: const Color(0xFF7C3AED),
                onTap: () => _pickClient(context, dataHub, (client) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => InstallationScreen(client: client)));
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: const [BoxShadow(color: Color(0x0A071440), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F1B3D))),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet to pick a client before opening client-scoped screens.
  void _pickClient(
      BuildContext context, DataHub dataHub, ValueChanged<ClientModel> onPicked) {
    final clients = dataHub.clients;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No clients yet. Add a client first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text('Select Client',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F1B3D))),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text('Choose a client to open this screen for',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: clients.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = clients[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        backgroundColor:
                            GSColors.blue500.withValues(alpha: 0.12),
                        child: Text(c.name.isNotEmpty
                            ? c.name.substring(0, 1).toUpperCase()
                            : '?'),
                      ),
                      title: Text(c.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F1B3D))),
                      subtitle: Text('${c.area} • ${c.phone}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8)),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onPicked(c);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quotation card ─────────────────────────────────────────────
  Widget _buildQuotationCard(BuildContext context, DataHub dataHub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GSColors.gold500.withValues(alpha: 0.4), width: 2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0x66FFF8E1)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x0A071440), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF9B417), Color(0xFFFFCA28)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [BoxShadow(color: Color(0x4DF9B417), blurRadius: 10)],
                ),
                child: const Icon(Icons.description_rounded,
                    color: Color(0xFF050E26), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Quotation',
                          style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F1B3D))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('QUICK TOOL',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFFB45309))),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Generate and share a solar quotation for a new client.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          // Gold button
          InkWell(
            onTap: () {
              _pickClient(context, dataHub, (client) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => QuoteBuilderScreen(client: client)),
                );
              });
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF9B417), Color(0xFFFFB300), Color(0xFFFFC83B)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: GSColors.gold500.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Create Quotation',
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF050E26))),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF050E26)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pipeline ───────────────────────────────────────────────────
  Widget _buildPipeline(BuildContext context, DataHub dataHub) {
    final pipeline = dataHub.pipelineEntries;
    final totalActive = pipeline.fold<int>(0, (sum, e) => sum + e.value);

    final stageColors = <String, Color>{
      'New Lead': GSColors.blue500,
      'Contacted': const Color(0xFF9C27B0),
      'Site Visit': const Color(0xFF9C27B0),
      'Quoted': GSColors.gold500,
      'Booked': const Color(0xFFF44336),
      'Installed': GSColors.green600,
      'Subsidized': GSColors.green600,
      'Lost': Colors.grey,
    };

    // Filter to the meaningful funnel stages (skip empty trailing)
    final funnel = <(String, int)>[];
    for (final e in pipeline) {
      funnel.add((e.key, e.value));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xCCE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0A071440), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pipeline Snapshot',
                        style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F1B3D))),
                    SizedBox(height: 2),
                    Text('Conversion funnel & status',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GSColors.blue500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Active Deals ($totalActive)',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: GSColors.blue500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...funnel.asMap().entries.map((entry) {
            final i = entry.key;
            final (label, count) = entry.value;
            final isLast = i == funnel.length - 1;
            final color = stageColors[label] ?? Colors.grey;
            return Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6),
                          ],
                        ),
                        child: isLast
                            ? const Icon(Icons.check, size: 10, color: Colors.white)
                            : null,
                      ),
                      if (!isLast)
                        Container(width: 2, height: 20, color: const Color(0xFFE2E8F0)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: GSColors.ink.withValues(alpha: 0.75))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F1B3D))),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Today's follow-ups ─────────────────────────────────────────
  Widget _buildTodayFollowUps(BuildContext context, DataHub dataHub) {
    final today = dataHub.todayFollowUps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Today's Follow-ups",
                style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1B3D))),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFF9B417)),
            ),
            const Spacer(),
            if (today.isNotEmpty)
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('See all (${today.length})',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: GSColors.blue500)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (today.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xCCE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 32, color: GSColors.green600),
                SizedBox(height: 8),
                Text('All caught up!',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F1B3D))),
                SizedBox(height: 2),
                Text('New follow-ups will appear here.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          )
        else
          ...today.map((f) {
            final client = dataHub.getClient(f.clientId);
            return _FollowUpTile(
              followUp: f,
              client: client,
              onCall: () {
                final phone = client?.phone ?? '0000000000';
                _openPhone(context, phone);
              },
              onWhatsApp: () {
                if (client != null) {
                  _openWhatsApp(context, client.phone, client.name);
                }
              },
            );
          }),
      ],
    );
  }
}

enum _StatStyle { solid, gold, green }

class _StatCard extends StatelessWidget {
  final (IconData, String, String, Color, String, _StatStyle) item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final (icon, label, value, color, badge, style) = item;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: style == _StatStyle.gold
                ? const Color(0x99FFE082)
                : const Color(0xB3E2E8F0)),
        gradient: style == _StatStyle.gold
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33FFF8E1), Colors.white])
            : null,
        boxShadow: const [BoxShadow(color: Color(0x0A071440), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F1B3D))),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final int revenue;
  const _RevenueCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xB3E2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0A071440), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GSColors.green400.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.currency_rupee_rounded,
                color: GSColors.green600, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Revenue (${DateFormat('MMM').format(DateTime.now())})',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                Text('₹${revenue.toString()}',
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F1B3D))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.trending_up, size: 15, color: GSColors.green600),
                SizedBox(width: 4),
                Text('+24%',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: GSColors.green600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Follow-up tile — exact design.
class _FollowUpTile extends StatelessWidget {
  final dynamic followUp;
  final dynamic client;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _FollowUpTile({
    required this.followUp,
    required this.client,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = followUp.isOverdue;
    final name = client?.name ?? followUp.clientId;
    final area = client?.area ?? '';
    final pkg = client?.preferredPackage ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isOverdue
                ? const Color(0xB3FECACA)
                : const Color(0xCCE2E8F0)),
        gradient: isOverdue
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x20FEE2E2), Colors.white])
            : null,
        boxShadow: const [BoxShadow(color: Color(0x0A071440), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOverdue
                  ? const Color(0xFFFFE4E6)
                  : const Color(0xFFFFF3CD),
            ),
            child: Icon(
              isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
              color: isOverdue ? const Color(0xFFE11D48) : const Color(0xFFB45309),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Follow-up — ${followUp.timeFormatted}',
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F1B3D))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? const Color(0xFFFFF1F2)
                            : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: isOverdue
                                ? const Color(0xFFFECACA)
                                : const Color(0xFFFFE0B2)),
                      ),
                      child: Text(isOverdue ? 'Overdue' : 'Pending',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isOverdue
                                  ? const Color(0xFFBE123C)
                                  : const Color(0xFFB45309))),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: name,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569))),
                      if (area.isNotEmpty)
                        TextSpan(
                          text: '  ($area${pkg.isNotEmpty ? ', $pkg kW' : ''})',
                          style: TextStyle(
                              fontSize: 12, color: GSColors.ink.withValues(alpha: 0.4)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Call + WhatsApp
          Row(
            children: [
              _actionCircle(
                icon: Icons.call_rounded,
                bg: GSColors.green400.withValues(alpha: 0.15),
                fg: GSColors.green600,
                onTap: onCall,
              ),
              const SizedBox(width: 6),
              _actionCircle(
                icon: Icons.chat_rounded,
                bg: GSColors.green600,
                fg: Colors.white,
                onTap: onWhatsApp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCircle({
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          boxShadow: bg == GSColors.green600
              ? [BoxShadow(color: GSColors.green600.withValues(alpha: 0.3), blurRadius: 6)]
              : null,
        ),
        child: Icon(icon, color: fg, size: 17),
      ),
    );
  }
}