import '../models/zekr.dart';
import '../models/zekr_day_stat.dart';

/// Whether the daily/period goal is already satisfied for [now]'s calendar day.
bool goalDoneAt(Zekr zekr, DateTime now) {
  final today = dayKey(now);
  if (zekr.history.any((h) => h.day == today && h.completed)) return true;
  if (!zekr.isCompleted) return false;
  return now.isBefore(zekr.nextPeriodStart);
}

/// Next local wall-clock time for a one-shot reminder.
/// If today's goal is already done, never returns a time still today.
DateTime nextReminderAt(Zekr zekr, {DateTime? now}) {
  now ??= DateTime.now();
  var day = DateTime(now.year, now.month, now.day);

  if (goalDoneAt(zekr, now)) {
    final next = zekr.nextPeriodStart;
    final nextDay = DateTime(next.year, next.month, next.day);
    day = nextDay.isAfter(day) ? nextDay : day.add(const Duration(days: 1));
  }

  for (var i = 0; i < 400; i++) {
    final candidate = DateTime(
      day.year,
      day.month,
      day.day,
      zekr.reminderHour,
      zekr.reminderMinute,
    );
    if (candidate.isAfter(now) && !_goalDoneOn(zekr, day, now: now)) {
      return candidate;
    }
    day = day.add(const Duration(days: 1));
  }
  // Fallback: tomorrow at reminder time
  final t = DateTime(now.year, now.month, now.day)
      .add(const Duration(days: 1));
  return DateTime(
    t.year,
    t.month,
    t.day,
    zekr.reminderHour,
    zekr.reminderMinute,
  );
}

bool _goalDoneOn(Zekr zekr, DateTime day, {required DateTime now}) {
  final key = dayKey(day);
  if (zekr.history.any((h) => h.day == key && h.completed)) return true;
  final isToday =
      day.year == now.year && day.month == now.month && day.day == now.day;
  if (isToday && goalDoneAt(zekr, now)) return true;
  return false;
}
