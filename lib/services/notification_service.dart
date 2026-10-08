import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules follow-up reminder notifications (local, on-device).
class NotificationService {
  static final NotificationService instance = NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // v3 → forces the channel to be (re)created with the alarm sound + vibration.
  static const _channelId = 'followup_reminders_v3';
  static const _channelName = 'Follow-up Reminders';
  static const _channelDesc = 'Follow-up reminder notifications';

  // The device's alarm ringtone (long, loud) → alarm-like behaviour.
  static const _alarmSound = 'content://settings/system/alarm_alert';

  static final Int64List _vibration =
      Int64List.fromList([0, 1000, 500, 1500, 500, 1500]);

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(initSettings);

    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {}

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        sound: const UriAndroidNotificationSound(_alarmSound),
        enableVibration: true,
        vibrationPattern: _vibration,
      ),
    );
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: const UriAndroidNotificationSound(_alarmSound),
          enableVibration: true,
          vibrationPattern: _vibration,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> scheduleFollowUpReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (!tzDate.isAfter(tz.TZDateTime.now(tz.local))) return;

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id,
          title,
          body,
          tzDate,
          _details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'followup:$id',
        );

    try {
      await schedule(AndroidScheduleMode.alarmClock);
    } catch (_) {
      try {
        await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      } catch (_) {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
  }

  Future<void> cancelFollowUp(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<bool> canScheduleExact() async {
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await impl?.canScheduleExactNotifications() ?? true;
  }

  Future<void> requestExact() async {
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestExactAlarmsPermission();
  }

  int _alertId = 5000;

  /// Immediate alarm-style alert (used for live sync / in-app due checks).
  Future<void> showAlert(String title, String body) async {
    await _plugin.show(_alertId++, title, body, _details, payload: 'alert');
  }
}
