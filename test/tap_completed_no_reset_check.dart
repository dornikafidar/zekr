import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/data/default_zekrs.dart';
import 'package:zekr/models/zekr.dart';

void main() {
  test('completed tasbih stays completed (circle must not auto-reset)', () {
    final at = DateTime(2026, 1, 1, 8);
    final z = Zekr(
      id: 'tasbih_zahra',
      text: defaultTasbihZahraTitle,
      targetCount: 100,
      incrementPerTap: 1,
      repeatType: RepeatType.daily,
      intervalDays: 1,
      reminderHour: 8,
      reminderMinute: 0,
      reminderEnabled: true,
      periodStart: at,
      createdAt: at,
      parts: tasbihZahraParts,
      partCounts: const [34, 33, 33],
      currentCount: 33,
      completedAt: at,
      allowAnytime: true,
    );
    expect(z.isCompleted, isTrue);
    expect(z.allowAnytime, isTrue);
    // Restart only via startAnytimeRound — not via tap when completed.
  });
}
