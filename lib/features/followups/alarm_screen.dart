import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/follow_up.dart';
import '../../providers/data_hub.dart';
import '../../services/notification_service.dart';

/// Popup shown when a follow-up is due. Rings (loops) + vibrates until the
/// user taps Stop or Snooze.
class AlarmScreen extends StatefulWidget {
  final String title;
  final String body;
  final String? followUpId;

  const AlarmScreen({
    super.key,
    required this.title,
    required this.body,
    this.followUpId,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final AudioPlayer _player = AudioPlayer();
  Timer? _vibeTimer;
  bool _stopped = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/alarm.wav'), volume: 1.0);
    } catch (_) {}
    _vibeTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!_stopped) HapticFeedback.vibrate();
    });
  }

  Future<void> _close() async {
    if (_stopped) return;
    _stopped = true;
    _vibeTimer?.cancel();
    try {
      await _player.stop();
    } catch (_) {}
    await NotificationService.instance.cancelAll();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze(int minutes) async {
    final id = widget.followUpId;
    if (id != null) {
      try {
        final hub = context.read<DataHub>();
        FollowUpModel? f;
        for (final x in hub.followUps) {
          if (x.id == id) {
            f = x;
            break;
          }
        }
        if (f != null) {
          final at = DateTime.now().add(Duration(minutes: minutes));
          await hub.updateFollowUp(f.copyWith(
            date: at,
            time: '${at.hour.toString().padLeft(2, '0')}:'
                '${at.minute.toString().padLeft(2, '0')}',
          ));
        }
      } catch (_) {}
    }
    await _close();
  }

  @override
  void dispose() {
    _vibeTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF9B417).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.alarm,
                    size: 34, color: Color(0xFFF9B417)),
              ),
              const SizedBox(height: 16),
              Text(widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF071440))),
              const SizedBox(height: 8),
              Text(widget.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF627193))),
              const SizedBox(height: 18),
              // Snooze options
              Row(
                children: [
                  for (final m in const [5, 10, 15, 30]) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _snooze(m),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0B1F5C),
                          side: const BorderSide(color: Color(0xFFD0E3F8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('${m}m',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (m != 30) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _snooze(60),
                      icon: const Icon(Icons.snooze_rounded, size: 18),
                      label: const Text('Snooze 1 hr',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B1F5C),
                        side: const BorderSide(color: Color(0xFFD0E3F8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _close,
                  icon: const Icon(Icons.stop_circle, size: 20),
                  label: const Text('Stop',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9B417),
                    foregroundColor: const Color(0xFF071440),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
