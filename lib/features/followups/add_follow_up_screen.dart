import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/follow_up.dart';
import '../../providers/data_hub.dart';

/// Create / Edit Follow-up screen — exact design: navy header + form card.
class AddFollowUpScreen extends StatefulWidget {
  final String? preselectedClientId;
  final FollowUpModel? existing; // non-null = edit mode

  const AddFollowUpScreen({super.key, this.preselectedClientId, this.existing});

  @override
  State<AddFollowUpScreen> createState() => _AddFollowUpScreenState();
}

class _AddFollowUpScreenState extends State<AddFollowUpScreen> {
  static const _gold = Color(0xFFF9B417);
  static const _goldLight = Color(0xFFFFD86B);
  static const _navyDark = Color(0xFF071440);
  static const _blue = Color(0xFF1E5BD8);
  static const _sky = Color(0xFFEAF4FF);
  static const _muted = Color(0xFF627193);

  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  String? _selectedClientId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _selectedClientId = e.clientId;
      _selectedDate = e.date;
      final parts = e.time.split(':');
      _selectedTime = TimeOfDay(
        hour: parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 10) : 10,
        minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      );
      _noteController.text = e.note ?? '';
    } else {
      _selectedClientId = widget.preselectedClientId;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) return;

    setState(() => _loading = true);
    final hub = context.read<DataHub>();
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final note = _noteController.text.trim();

    if (widget.existing != null) {
      await hub.updateFollowUp(widget.existing!.copyWith(
        date: _selectedDate,
        time: timeStr,
        note: note,
      ));
    } else {
      final fu = FollowUpModel(
        id: hub.generateId(),
        clientId: _selectedClientId!,
        date: _selectedDate,
        time: timeStr,
        status: 'pending',
        note: note.isNotEmpty ? note : null,
        createdAt: DateTime.now(),
      );
      await hub.addFollowUp(fu);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              widget.existing != null ? 'Follow-up updated' : 'Follow-up added')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<DataHub>();
    final clients = hub.clients;
    if (_selectedClientId == null && clients.isNotEmpty) {
      _selectedClientId = clients.first.id;
    }

    return Scaffold(
      backgroundColor: _sky,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Navy header ─────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF071440), Color(0xFF0B1F5C)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      const Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Create Follow-up',
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
                      ),
                      const SizedBox(width: 40), // symmetry
                    ],
                  ),
                ),
              ),
            ),
            // ── Form body ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A0B1F5C), blurRadius: 32, offset: Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section header
                      Container(
                        padding: const EdgeInsets.only(bottom: 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFEAF4FF))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _sky,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.event_note_rounded,
                                  size: 16, color: _blue),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Follow-up Details',
                                  style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF0F1B3D))),
                            ),
                            const Text('Step 1 of 1',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w500, color: _muted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Client
                      _label('Client', required: true),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedClientId,
                        isExpanded: true,
                        isDense: true,
                        decoration: _fieldDeco(Icons.person_rounded, _blue),
                        items: clients
                            .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedClientId = v),
                        validator: (_) =>
                            _selectedClientId == null ? 'Select a client' : null,
                      ),
                      const SizedBox(height: 16),

                      // Due date
                      _label('Due Date', required: true),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 30)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(
                            color: _sky,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 20, color: _blue),
                              const SizedBox(width: 10),
                              Text(
                                  DateFormat('EEE, dd MMM yyyy')
                                      .format(_selectedDate),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F1B3D))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time
                      _label('Preferred Time', required: true),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (picked != null) {
                            setState(() => _selectedTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(
                            color: _sky,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 20, color: _gold),
                              const SizedBox(width: 10),
                              Text(_selectedTime.format(context),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F1B3D))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Note
                      Row(
                        children: [
                          _label('Note'),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _sky,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('Optional',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: _muted)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: _sky,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          children: [
                            const Positioned(
                              left: 14,
                              top: 14,
                              child: Icon(Icons.edit_note_rounded,
                                  size: 20, color: _muted),
                            ),
                            TextFormField(
                              controller: _noteController,
                              maxLines: 4,
                              minLines: 4,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0F1B3D),
                                  height: 1.4),
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                hintText:
                                    'Any note about this follow-up (e.g. call after 5pm, document pending)...',
                                hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: _muted.withValues(alpha: 0.7),
                                    height: 1.4),
                                contentPadding:
                                    const EdgeInsets.fromLTRB(44, 14, 16, 14),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Bottom save bar ─────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                border: const Border(top: BorderSide(color: Color(0xFFEAF4FF))),
                boxShadow: const [
                  BoxShadow(color: Color(0x10071440), blurRadius: 20, offset: Offset(0, -8)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _loading ? null : _save,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_gold, _goldLight, Color(0xFFD9980B)]),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: _goldLight.withValues(alpha: 0.6)),
                          boxShadow: [
                            BoxShadow(
                                color: GSColors.gold500.withValues(alpha: 0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: _navyDark))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 22, color: _navyDark),
                                    SizedBox(width: 8),
                                    Text('Save Follow-up',
                                        style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: _navyDark)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 128,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _navyDark.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
              text: text.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _muted)),
          if (required)
            const TextSpan(
                text: ' *', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 11)),
        ],
      ),
    );
  }

  InputDecoration _fieldDeco(IconData icon, Color iconColor) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: iconColor),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      filled: true,
      fillColor: _sky,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _blue, width: 1.2),
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