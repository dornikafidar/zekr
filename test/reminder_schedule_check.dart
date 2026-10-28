import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/models/zekr.dart';
import 'package:zekr/models/zekr_day_stat.dart';
import 'package:zekr/utils/reminder_schedule.dart';

Zekr _zekr({
  required int hour,
  required int minute,
  int currentCount = 0,
  int target = 10,
  DateTime? completedAt,
  List<ZekrDayStat> history = const [],
}) {
  final at = DateTime(2026, 10, 28, 8, 0);
  return Zekr(
    id: 't1',
    text: 'test',
    targetCount: target,
    incrementPerTap: 1,
    repeatType: RepeatType.daily,
    intervalDays: 1,
    reminderHour: hour,
    reminderMinute: minute,
    reminderEnabled: true,
    periodStart: at,
    createdAt: at,
    currentCount: currentCount,
    completedAt: completedAt,
    history: history,
  );
}

void main() {
  test('before completion: reminder stays today if still ahead', () {
    final now = DateTime(2026, 10, 28, 8, 30);
    final z = _zekr(hour: 9, minute: 0, currentCount: 3);
    final next = nextReminderAt(z, now: now);
    expect(next, DateTime(2026, 10, 28, 9, 0));
  });

  test('after completion at 8:30: no reminder at 9 same day', () {
    final now = DateTime(2026, 10, 28, 8, 30);
    final z = _zekr(
      hour: 9,
      minute: 0,
      currentCount: 10,
      completedAt: now,
      history: [
        ZekrDayStat(
          day: dayKey(now),
          count: 10,
          target: 10,
          completed: true,
        ),
      ],
    );
    expect(goalDoneAt(z, now), isTrue);
    final next = nextReminderAt(z, now: now);
    expect(next, DateTime(2026, 10, 29, 9, 0));
  });

  test('after reminder time passed and not done: tomorrow', () {
    final now = DateTime(2026, 10, 28, 10, 0);
    final z = _zekr(hour: 9, minute: 0, currentCount: 2);
    final next = nextReminderAt(z, now: now);
    expect(next, DateTime(2026, 10, 29, 9, 0));
  });
}
