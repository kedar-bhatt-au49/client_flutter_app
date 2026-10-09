import 'package:flutter/material.dart';

import '../features/followups/alarm_screen.dart';

/// Global navigator key so the alarm popup can be shown from anywhere.
final GlobalKey<NavigatorState> gNavKey = GlobalKey<NavigatorState>();

bool _alarmOpen = false;

/// Shows the follow-up alarm popup (won't stack duplicates).
void showFollowUpAlarm({
  required String title,
  required String body,
  String? followUpId,
}) {
  final ctx = gNavKey.currentContext;
  if (ctx == null || _alarmOpen) return;
  _alarmOpen = true;
  showDialog<void>(
    context: ctx,
    barrierDismissible: false,
    builder: (_) =>
        AlarmScreen(title: title, body: body, followUpId: followUpId),
  ).then((_) => _alarmOpen = false);
}
