import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gs_button.dart';
import '../../core/widgets/gs_card.dart';
import '../../providers/data_hub.dart';
import '../../models/follow_up.dart';

/// Follow-up queue — sorted by due date, with Done / Missed / Snooze actions.
class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  String _filter = 'pending'; // pending | done | missed | all

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();

    final items = _getFiltered(hub);

    final todayCount = hub.followUps.where((f) => f.status == 'pending' && f.isOverdue).length;
    final completedToday = hub.followUps.where((f) {
      final d = f.doneAt;
      if (d == null) return false;
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;

    return Scaffold(
      backgroundColor: GSColors.whiteBg,
      appBar: AppBar(title: const Text('Follow-ups')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, hub),
        icon: const Icon(Icons.add),
        label: const Text('Add Follow-up'),
      ),
      body: Column(
        children: [
          // ── Filter tabs ─────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip('Pending', _filter == 'pending',
                    () => setState(() => _filter = 'pending'),
                    color: GSColors.followupPending),
                const SizedBox(width: 8),
                _FilterChip('Overdue', _filter == 'overdue',
                    () => setState(() => _filter = 'overdue'),
                    color: GSColors.followupMissed),
                const SizedBox(width: 8),
                _FilterChip('Done', _filter == 'done',
                    () => setState(() => _filter = 'done'),
                    color: GSColors.green600),
                const SizedBox(width: 8),
                _FilterChip('All', _filter == 'all',
                    () => setState(() => _filter = 'all'),
                    color: GSColors.navy700),
              ],
            ),
          ),

          // Summary
          if (todayCount > 0 || completedToday > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (todayCount > 0)
                    _SummaryBadge('Overdue: $todayCount', GSColors.followupMissed),
                  if (completedToday > 0) ...[
                    const SizedBox(width: 8),
                    _SummaryBadge('Done today: $completedToday', GSColors.green600),
                  ],
                ],
              )),
          const SizedBox(height: 8),

          // ── List ────────────────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    title: 'No follow-ups',
                    message: 'Your follow-up queue is empty. Add one to get started!',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                            launchUrl(Uri.parse('tel:+91$phone'));
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

  void _markDone(BuildContext context, DataHub hub, FollowUpModel f) async {
    await hub.updateFollowUp(
        f.copyWith(status: 'done', doneAt: DateTime.now()));
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

  void _showAddSheet(BuildContext context, DataHub hub) {
    final clients = hub.clients;
    String? selectedClientId = clients.isNotEmpty ? clients.first.id : null;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 30);
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GSColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GSColors.ink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Add Follow-up',
                    style: GSTextStyles.headlineMedium
                        .copyWith(color: GSColors.navy900)),
                const SizedBox(height: 16),
                // Client selector
                DropdownButtonFormField<String>(
                  initialValue: selectedClientId,
                  decoration: const InputDecoration(labelText: 'Client'),
                  items: clients
                      .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name,
                              style: GSTextStyles.bodyMedium)))
                      .toList(),
                  onChanged: (v) => setSheetState(() => selectedClientId = v),
                ),
                const SizedBox(height: 16),
                // Date picker
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon: const Icon(Icons.calendar_today, size: 20),
                    hintText: DateFormat('EEE, dd MMM yyyy').format(selectedDate),
                    hintStyle: GSTextStyles.bodyMedium,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Time picker
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Preferred Time',
                    prefixIcon: const Icon(Icons.access_time, size: 20),
                    hintText: selectedTime.format(context),
                    hintStyle: GSTextStyles.bodyMedium,
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setSheetState(() => selectedTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Note
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      child: GsButton(
                        text: 'Add',
                        onPressed: selectedClientId == null
                            ? null
                            : () async {
                                final id = hub.generateId();
                                final fu = FollowUpModel(
                                  id: id,
                                  clientId: selectedClientId!,
                                  date: selectedDate,
                                  time:
                                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                  status: 'pending',
                                  note: noteController.text.trim().isNotEmpty
                                      ? noteController.text.trim()
                                      : null,
                                  createdAt: DateTime.now(),
                                );
                                await hub.addFollowUp(fu);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Follow-up added')),
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSnoozeSheet(BuildContext context, DataHub hub, FollowUpModel f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GSColors.white,
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
                color: GSColors.ink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Snooze Until',
                style: GSTextStyles.headlineSmall.copyWith(color: GSColors.navy900)),
            const SizedBox(height: 16),
            ChoiceChip(
              label: const Text('Tomorrow'),
              selected: false,
              onSelected: (_) => _snoozeTo(context, hub, f, 1),
              backgroundColor: GSColors.ink.withValues(alpha: 0.1),
              selectedColor: GSColors.gold500.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            ChoiceChip(
              label: const Text('3 days later'),
              selected: false,
              onSelected: (_) => _snoozeTo(context, hub, f, 3),
              backgroundColor: GSColors.ink.withValues(alpha: 0.1),
              selectedColor: GSColors.gold500.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            ChoiceChip(
              label: const Text('1 week later'),
              selected: false,
              onSelected: (_) => _snoozeTo(context, hub, f, 7),
              backgroundColor: GSColors.ink.withValues(alpha: 0.1),
              selectedColor: GSColors.gold500.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            TextButton(
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
              child: const Text('Pick a date'),
            ),
          ],
        ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color color;

  const _FilterChip(this.label, this.selected, this.onSelected, {required this.color});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              color: selected ? GSColors.white : color, fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: color.withValues(alpha: 0.1),
      selectedColor: color,
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SummaryBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: GSTextStyles.bodySmall.copyWith(color: color)),
    );
  }
}

class _FollowUpItem extends StatelessWidget {
  final FollowUpModel followUp;
  final String clientName;
  final String clientPhone;
  final VoidCallback onMarkDone;
  final VoidCallback onMarkMissed;
  final VoidCallback onSnooze;
  final VoidCallback onCall;

  const _FollowUpItem({
    required this.followUp,
    required this.clientName,
    required this.clientPhone,
    required this.onMarkDone,
    required this.onMarkMissed,
    required this.onSnooze,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = followUp.isOverdue;

    return GsCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clientName,
                        style: GSTextStyles.headlineSmall
                            .copyWith(color: GSColors.navy900)),
                    Text(
                      '${followUp.dateFormatted} · ${followUp.timeFormatted}',
                      style: GSTextStyles.bodyMedium.copyWith(
                          color: overdue
                              ? GSColors.followupMissed
                              : GSColors.ink.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              if (overdue)
                const Icon(Icons.warning_amber_rounded,
                    color: GSColors.followupMissed, size: 20),
            ],
          ),
          if (followUp.note != null && followUp.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(followUp.note!,
                  style: GSTextStyles.bodySmall
                      .copyWith(color: GSColors.ink.withValues(alpha: 0.7))),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: followUp.status == 'done' ? null : onMarkDone,
                icon: const Icon(Icons.check_circle,
                    size: 18, color: GSColors.green600),
                label: const Text('Done',
                    style: TextStyle(color: GSColors.green600)),
              ),
              TextButton.icon(
                onPressed: followUp.status == 'missed' ? null : onMarkMissed,
                icon: const Icon(Icons.cancel,
                    size: 18, color: GSColors.followupMissed),
                label: const Text('Missed',
                    style: TextStyle(color: GSColors.followupMissed)),
              ),
              TextButton.icon(
                onPressed: onSnooze,
                icon: const Icon(Icons.snooze,
                    size: 18, color: GSColors.blue500),
                label: const Text('Snooze',
                    style: TextStyle(color: GSColors.blue500)),
              ),
              if (clientPhone.isNotEmpty)
                TextButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone,
                      size: 18, color: GSColors.green600),
                  label: const Text('Call',
                      style: TextStyle(color: GSColors.green600)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
