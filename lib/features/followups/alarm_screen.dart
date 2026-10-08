import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/notification_service.dart';

/// Full-screen alarm shown when a follow-up is due.
/// Rings (loops) + vibrates until the user taps Stop.
class AlarmScreen extends StatefulWidget {
  final String title;
  final String body;

  const AlarmScreen({super.key, required this.title, required this.body});

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

  Future<void> _stop() async {
    if (_stopped) return;
    _stopped = true;
    _vibeTimer?.cancel();
    try {
      await _player.stop();
    } catch (_) {}
    await NotificationService.instance.cancelAll();
    if (mounted) Navigator.of(context).maybePop();
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
      child: Scaffold(
        backgroundColor: const Color(0xFF071440),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.alarm, size: 80, color: Color(0xFFF9B417)),
                const SizedBox(height: 24),
                Text(widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 12),
                Text(widget.body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, color: Colors.white70)),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop_circle, size: 24),
                    label: const Text('Stop',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9B417),
                      foregroundColor: const Color(0xFF071440),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
