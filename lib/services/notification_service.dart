import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/zekr.dart';
import '../utils/reminder_schedule.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    // Schedule via TZDateTime.from(local DateTime) so wall-clock matches the
    // device, regardless of which Location we pin here.
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tehran'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _requestPermissions();
    _ready = true;
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  int _idFor(String zekrId) => zekrId.hashCode & 0x7FFFFFFF;

  Future<void> scheduleFor(Zekr zekr) async {
    if (!_ready) await init();
    // Always clear first so a completed zekr cannot keep an old alarm.
    await cancelFor(zekr.id);

    if (!zekr.reminderEnabled) return;

    final when = nextReminderAt(zekr);
    // Absolute instant from device-local wall clock (avoids TZ name mismatch).
    final scheduled = tz.TZDateTime.from(when, tz.local);
    await _zonedScheduleOnce(zekr, scheduled);
  }

  Future<void> _zonedScheduleOnce(Zekr zekr, tz.TZDateTime scheduled) async {
    final preview = zekr.text.split('\n').first;
    final body = zekr.text.length > 180
        ? '${zekr.text.substring(0, 180)}…'
        : zekr.text;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'zekr_reminders',
        'یادآوری ذکر',
        channelDescription: 'یادآوری برای ذکرهای روزانه',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          '${zekr.text}\n\nهدف: ${zekr.totalTarget}×',
          contentTitle: preview,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        _idFor(zekr.id),
        'وقت ذکر',
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Notification schedule failed: $e');
      try {
        await _plugin.zonedSchedule(
          _idFor(zekr.id),
          'وقت ذکر',
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e2) {
        debugPrint('Fallback schedule failed: $e2');
      }
    }
  }

  Future<void> cancelFor(String zekrId) async {
    await _plugin.cancel(_idFor(zekrId));
  }

  Future<void> cancelMany(Iterable<String> zekrIds) async {
    for (final id in zekrIds) {
      await cancelFor(id);
    }
  }

  Future<void> syncAll(List<Zekr> items) async {
    for (final z in items) {
      await scheduleFor(z);
    }
  }
}
