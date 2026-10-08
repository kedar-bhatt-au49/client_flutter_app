import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Lightweight notification service — schedules follow-up reminders.
class NotificationService {
  static final NotificationService instance = NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'followup_channel';
  static const _channelName = 'Follow-up Reminders';
  static const _channelDesc = 'Daily follow-up reminder notifications';

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(initSettings);
    tz.initializeTimeZones();
    // Android 13+ runtime permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleFollowUpReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF071440),
      colorized: true,
      icon: 'ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    final platformDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'followup:$id',
    );
  }

  Future<void> cancelFollowUp(int id) async {
    await _plugin.cancel(id);
  }

  int _alertId = 5000;

  /// Shows an immediate alert (used for live sync changes).
  Future<void> showAlert(String title, String body) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_launcher',
    );
    await _plugin.show(
      _alertId++,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: 'alert',
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> showDailyReminder() async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_launcher',
    );
    final platformDetails = NotificationDetails(android: androidDetails);
    await _plugin.show(
      999,
      'Global Solar 2.0',
      'You have pending follow-ups. Open the app to review.',
      platformDetails,
    );
  }
}
