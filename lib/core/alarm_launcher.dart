import 'package:flutter/material.dart';

import '../features/followups/alarm_screen.dart';

/// Global navigator key so the alarm can be pushed from anywhere.
final GlobalKey<NavigatorState> gNavKey = GlobalKey<NavigatorState>();

bool _alarmOpen = false;

/// Pushes the full-screen alarm (won't stack duplicates).
void showFollowUpAlarm({required String title, required String body}) {
  final nav = gNavKey.currentState;
  if (nav == null || _alarmOpen) return;
  _alarmOpen = true;
  nav
      .push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AlarmScreen(title: title, body: body),
      ))
      .then((_) => _alarmOpen = false);
}
