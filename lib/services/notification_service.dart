import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/zekr.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
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
    await cancelFor(zekr.id);

    if (!zekr.reminderEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled;

    if (zekr.isWaitingForNextPeriod) {
      final next = zekr.nextPeriodStart;
      scheduled = tz.TZDateTime(
        tz.local,
        next.year,
        next.month,
        next.day,
        zekr.reminderHour,
        zekr.reminderMinute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    } else {
      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        zekr.reminderHour,
        zekr.reminderMinute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }

    final preview = zekr.text.split('\n').first;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'zekr_reminders',
        'Zekr Erinnerungen',
        channelDescription: 'Erinnerungen für deine täglichen Zekr',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          '${zekr.text}\n\nZiel: ${zekr.targetCount}×',
          contentTitle: preview,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final match = zekr.isWaitingForNextPeriod
        ? null
        : _matchComponents(zekr);

    try {
      await _plugin.zonedSchedule(
        _idFor(zekr.id),
        'Zeit für Zekr',
        zekr.text,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: match,
      );
    } catch (e) {
      debugPrint('Notification schedule failed: $e');
      try {
        await _plugin.zonedSchedule(
          _idFor(zekr.id),
          'Zeit für Zekr',
          zekr.text,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: match,
        );
      } catch (e2) {
        debugPrint('Fallback schedule failed: $e2');
      }
    }
  }

  DateTimeComponents? _matchComponents(Zekr zekr) {
    switch (zekr.repeatType) {
      case RepeatType.daily:
        return DateTimeComponents.time;
      case RepeatType.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatType.everyXDays:
        // Exact interval handled by rescheduling after completion/reset.
        return null;
    }
  }

  Future<void> cancelFor(String zekrId) async {
    await _plugin.cancel(_idFor(zekrId));
  }

  Future<void> syncAll(List<Zekr> items) async {
    for (final z in items) {
      await scheduleFor(z);
    }
  }
}
