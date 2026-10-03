import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../models/follow_up.dart';
import '../../providers/data_hub.dart';
import 'add_follow_up_screen.dart';

/// Follow-ups queue — exact design: navy header, date + filter chips,
/// stat badges, follow-up cards with actions, empty state.
class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  String _filter = 'pending'; // pending | overdue | done | all
  static const _gold = Color(0xFFF9B417);
  static const _goldLight = Color(0xFFFFD86B);
  static const _navy = Color(0xFF0B1F5C);
  static const _navyDark = Color(0xFF071440);
  static const _blue = Color(0xFF1E5BD8);
  static const _sky = Color(0xFFEAF4FF);
  static const _red = Color(0xFFF44336);
  static const _green = Color(0xFF1E8E3E);

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final items = _getFiltered(hub);

    final pendingCount = hub.followUps.where((f) => f.status == 'pending').length;
    final overdueCount = hub.followUps.where((f) => f.status == 'pending' && f.isOverdue).length;
    final doneCount = hub.followUps.where((f) => f.status == 'done').length;

    final completedToday = hub.followUps.where((f) {
      final d = f.doneAt;
      if (d == null) return false;
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;

    return Scaffold(
      backgroundColor: _sky,
      body: Column(
        children: [
          // ── 1. Navy header ─────────────────────────────────────
          _buildHeader(context, hub),
          // ── 2. Date + filter chips + badges ───────────────────
          _buildFilterBar(context, pendingCount, overdueCount, doneCount, completedToday, items.length),
          // ── 3. Queue list ──────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState(hub)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final f = items[i];
                      final client = hub.getClient(f.clientId);
                      return _FollowUpItem(
                        followUp: f,
                        clientName: client?.name ?? 'Unknown client',
                        clientPhone: client?.phone ?? '',
                        onMarkDone: () => _markDone(context, hub, f),
                        onMarkMissed: () => _markMissed(context, hub, f),
                        onSnooze: () => _showSnoozeSheet(context, hub, f),
                        onCall: () {
                          final phone = client?.phone ?? '';
                          if (phone.isNotEmpty) {
                            launchUrl(Uri.parse('tel:+91$phone'),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        onWhatsApp: () {
                          final phone = client?.phone ?? '';
                          final name = client?.name ?? '';
                          if (phone.isNotEmpty) {
                            final msg = Uri.encodeComponent(
                                'Hello $name, this is Global Solar 2.0. Following up on your solar inquiry.');
                            launchUrl(Uri.parse('https://wa.me/91$phone?text=$msg'),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<FollowUpModel> _getFiltered(DataHub hub) {
    var items = hub.followUps;
    if (_filter == 'pending' || _filter == 'overdue') {
      items = items.where((f) => f.status == 'pending').toList();
      if (_filter == 'overdue') {
        items = items.where((f) => f.isOverdue).toList();
      }
    } else if (_filter != 'all') {
      items = items.where((f) => f.status == _filter).toList();
    }
    return items;
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, DataHub hub) {
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              // Logo badge
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_gold, _goldLight],
                  ),
                  boxShadow: [
                    BoxShadow(color: GSColors.gold500.withValues(alpha: 0.45), blurRadius: 12),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF071440),
                  ),
                  child: const Icon(Icons.wb_sunny_rounded,
                      color: GSColors.gold500, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Follow-ups',
                            style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3)),
                        SizedBox(width: 6),
                        _PulseDot(),
                      ],
                    ),
                    Text('Bhavnagar & Talaja Hub',
                        style: TextStyle(fontSize: 12, color: Color(0xCCD6E6FF))),
                  ],
                ),
              ),
              // Add follow-up button
              InkWell(
                onTap: () => _openAddScreen(context, hub),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_gold, Color(0xFFFFCA40)],
                    ),
                    boxShadow: [
                      BoxShadow(color: GSColors.gold500.withValues(alpha: 0.45), blurRadius: 12),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Color(0xFF0F1B3D), size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter bar ─────────────────────────────────────────────────
  Widget _buildFilterBar(
    BuildContext context,
    int pending,
    int overdue,
    int done,
    int doneToday,
    int showing,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: _sky,
        border: Border(bottom: BorderSide(color: Color(0xCCDBEAFE))),
      ),
      child: Column(
        children: [
          // Date row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: _blue),
                    const SizedBox(width: 6),
                    Text('Today — ${DateFormat('d MMM yyyy').format(DateTime.now())}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: _navy)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xCCDBEAFE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('PM Surya Ghar',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF1D4ED8))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Filter chips
          Row(
            children: [
              _filterChip('Pending', pending, _filter == 'pending', _gold,
                  () => setState(() => _filter = 'pending')),
              const SizedBox(width: 8),
              _filterChip('Overdue', overdue, _filter == 'overdue', _red,
                  () => setState(() => _filter = 'overdue')),
              const SizedBox(width: 8),
              _filterChip('Done', done, _filter == 'done', _green,
                  () => setState(() => _filter = 'done')),
              const SizedBox(width: 8),
              _filterChip('All', pending + done, _filter == 'all', _navy,
                  () => setState(() => _filter = 'all')),
            ],
          ),
          const SizedBox(height: 10),
          // Summary badges
          Row(
            children: [
              if (overdue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xE6FEE2E2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _red,
                          boxShadow: [BoxShadow(color: _red.withValues(alpha: 0.6), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Overdue: $overdue',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _red)),
                    ],
                  ),
                ),
              if (overdue > 0 && doneToday > 0) const SizedBox(width: 8),
              if (doneToday > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xE6D1FAE5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_rounded, size: 12, color: _green),
                      const SizedBox(width: 4),
                      Text('Done today: $doneToday',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _green)),
                    ],
                  ),
                ),
              const Spacer(),
              Text('Showing $showing tasks',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int count, bool active, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? color : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: active ? color : color.withValues(alpha: 0.5)),
            boxShadow: active
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : color)),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : color)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────
  Widget _buildEmptyState(DataHub hub) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _blue.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF8E1),
                border: Border.all(color: _gold.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.wb_sunny_rounded, color: _gold, size: 24),
            ),
            const SizedBox(height: 10),
            const Text('Need to Schedule More?',
                style: TextStyle(
                    fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 14, color: _navyDark)),
            const SizedBox(height: 4),
            const Text('Your queue is clear. Add one to get started!',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openAddScreen(context, hub),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(color: GSColors.gold500.withValues(alpha: 0.35), blurRadius: 10),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: Color(0xFF0F1B3D)),
                    SizedBox(width: 4),
                    Text('Add Follow-up',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F1B3D))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────
  void _markDone(BuildContext context, DataHub hub, FollowUpModel f) async {
    await hub.updateFollowUp(f.copyWith(status: 'done', doneAt: DateTime.now()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as done')),
    );
  }

  void _markMissed(BuildContext context, DataHub hub, FollowUpModel f) async {
    await hub.updateFollowUp(f.copyWith(status: 'missed'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as missed')),
    );
  }

  void _openAddScreen(BuildContext context, DataHub hub) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddFollowUpScreen()),
    );
  }

  void _showSnoozeSheet(BuildContext context, DataHub hub, FollowUpModel f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1B3D).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Snooze Until',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 18, color: _navyDark)),
            const SizedBox(height: 16),
            _snoozeChip('Tomorrow', () => _snoozeTo(context, hub, f, 1)),
            const SizedBox(height: 8),
            _snoozeChip('3 days later', () => _snoozeTo(context, hub, f, 3)),
            const SizedBox(height: 8),
            _snoozeChip('1 week later', () => _snoozeTo(context, hub, f, 7)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: f.date.add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && context.mounted) {
                  _snoozeToDate(context, hub, f, picked);
                }
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 16, color: _blue),
              label: const Text('Pick a date', style: TextStyle(color: _blue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _snoozeChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _navyDark)),
      ),
    );
  }

  void _snoozeTo(BuildContext context, DataHub hub, FollowUpModel f, int days) {
    final newDate = DateTime.now().add(Duration(days: days));
    hub.updateFollowUp(f.copyWith(date: newDate, status: 'pending'));
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Snoozed to ${DateFormat("dd MMM").format(newDate)}')));
  }

  void _snoozeToDate(BuildContext context, DataHub hub, FollowUpModel f, DateTime date) {
    hub.updateFollowUp(f.copyWith(date: date, status: 'pending'));
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Snoozed to ${DateFormat("dd MMM").format(date)}')));
  }
}

/// Pulsing gold dot in header.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
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

/// Follow-up card — exact design.
class _FollowUpItem extends StatelessWidget {
  final FollowUpModel followUp;
  final String clientName;
  final String clientPhone;
  final VoidCallback onMarkDone;
  final VoidCallback onMarkMissed;
  final VoidCallback onSnooze;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _FollowUpItem({
    required this.followUp,
    required this.clientName,
    required this.clientPhone,
    required this.onMarkDone,
    required this.onMarkMissed,
    required this.onSnooze,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = followUp.isOverdue;
    final done = followUp.status == 'done';
    final missed = followUp.status == 'missed';

    // Status config
    final statusColor = done
        ? const Color(0xFF1E8E3E)
        : missed
            ? const Color(0xFF9E9E9E)
            : overdue
                ? const Color(0xFFF44336)
                : const Color(0xFFF9B417);
    final statusLabel = done
        ? '✓ Done'
        : missed
            ? 'Missed'
            : overdue
                ? 'Overdue'
                : '• Pending';
    final statusBg = done
        ? const Color(0xFFD1FAE5)
        : missed
            ? const Color(0xFFF1F5F9)
            : overdue
                ? const Color(0xFFF44336)
                : const Color(0xFFFEF3C7);
    final statusText = done
        ? const Color(0xFF166534)
        : missed
            ? const Color(0xFF64748B)
            : overdue
                ? Colors.white
                : const Color(0xFF92400E);
    final statusBorder = done
        ? const Color(0xFFBBF7D0)
        : missed
            ? const Color(0xFFE2E8F0)
            : overdue
                ? const Color(0xFFF44336)
                : const Color(0xFFFDE68A);

    final cardBorder = overdue
        ? const Color(0xFFFECACA)
        : const Color(0xCCFFFFFF);
    final cardBg = overdue
        ? const Color(0x4DFEE2E2)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: overdue ? 2 : 1),
        boxShadow: const [BoxShadow(color: Color(0x12071440), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: overdue
                      ? const Color(0xCCFEE2E2)
                      : done
                          ? const Color(0xFFD1FAE5)
                          : missed
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  done
                      ? Icons.check_circle_rounded
                      : missed
                          ? Icons.cancel_rounded
                          : overdue
                              ? Icons.warning_amber_rounded
                              : Icons.access_time_rounded,
                  size: 20,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(clientName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F1B3D))),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusBorder),
                          ),
                          child: Text(statusLabel,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusText)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Date & time
                    Row(
                      children: [
                        Icon(
                          done ? Icons.event_available_rounded : Icons.calendar_today_rounded,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${followUp.dateFormatted} • ${followUp.timeFormatted}${overdue ? ' (Yesterday)' : ''}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: overdue ? FontWeight.w700 : FontWeight.w600,
                                color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    // Note
                    if (followUp.note != null && followUp.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(followUp.note!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: overdue ? const Color(0xFF475569) : const Color(0xFF64748B))),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Actions row
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: overdue ? const Color(0x99FECACA) : const Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                // Mark Done (green, flex)
                Expanded(
                  child: _actionBtn(
                    label: 'Mark Done',
                    icon: Icons.check_rounded,
                    bg: const Color(0xFFECFDF5),
                    fg: const Color(0xFF1E8E3E),
                    onTap: followUp.status == 'done' ? null : onMarkDone,
                  ),
                ),
                const SizedBox(width: 8),
                // Snooze (blue)
                _actionBtn(
                  label: 'Snooze',
                  icon: Icons.notifications_none_rounded,
                  bg: const Color(0xFFEFF6FF),
                  fg: const Color(0xFF1E5BD8),
                  onTap: onSnooze,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                const SizedBox(width: 8),
                // Call (green circle)
                _iconBtn(
                  icon: Icons.call_rounded,
                  bg: const Color(0xFF22A24A),
                  onTap: clientPhone.isNotEmpty ? onCall : null,
                ),
                const SizedBox(width: 6),
                // WhatsApp (green circle)
                _iconBtn(
                  icon: Icons.chat_rounded,
                  bg: const Color(0xFF25D366),
                  onTap: clientPhone.isNotEmpty ? onWhatsApp : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
    EdgeInsets? padding,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color bg,
    VoidCallback? onTap,
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
          boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.3), blurRadius: 6)],
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}