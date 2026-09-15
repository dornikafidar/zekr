import 'zekr.dart';
import 'zekr_day_stat.dart';

enum StatsRange { week, month, year, all }

class StatsBucket {
  final String label;
  final String shortLabel;
  final int count;
  final int completedGoals;
  final int daysActive;
  final DateTime start;
  final DateTime end;

  const StatsBucket({
    required this.label,
    required this.shortLabel,
    required this.count,
    required this.completedGoals,
    required this.daysActive,
    required this.start,
    required this.end,
  });

  double get progressVsTarget {
    // informational only when single-day with target known elsewhere
    return 0;
  }
}

class ZekrStats {
  final List<StatsBucket> buckets;
  final int totalCount;
  final int completedGoals;
  final int activeDays;
  final int bestDayCount;
  final String? bestDayLabel;
  final double averagePerBucket;
  final int currentStreak;

  const ZekrStats({
    required this.buckets,
    required this.totalCount,
    required this.completedGoals,
    required this.activeDays,
    required this.bestDayCount,
    required this.bestDayLabel,
    required this.averagePerBucket,
    required this.currentStreak,
  });
}

class ZekrBreakdownRow {
  final String id;
  final String text;
  final int count;
  final int completedGoals;

  const ZekrBreakdownRow({
    required this.id,
    required this.text,
    required this.count,
    required this.completedGoals,
  });
}

class OverallStats {
  final ZekrStats stats;
  final List<ZekrBreakdownRow> perZekr;
  final int zekrCount;
  final int lifetimeTotal;
  final int lifetimeGoals;

  const OverallStats({
    required this.stats,
    required this.perZekr,
    required this.zekrCount,
    required this.lifetimeTotal,
    required this.lifetimeGoals,
  });
}

Map<String, ZekrDayStat> mergeHistories(Iterable<Zekr> items) {
  final merged = <String, ZekrDayStat>{};
  for (final z in items) {
    for (final h in z.history) {
      final cur = merged[h.day];
      if (cur == null) {
        merged[h.day] = h;
      } else {
        merged[h.day] = cur.copyWith(
          count: cur.count + h.count,
          target: cur.target + h.target,
          completed: cur.completed || h.completed,
        );
      }
    }
  }
  return merged;
}

ZekrStats buildStatsFromHistory(
  Map<String, ZekrDayStat> history, {
  required StatsRange range,
  DateTime? anchor,
  DateTime? createdFallback,
}) {
  final now = dateOnly(anchor ?? DateTime.now());

  late final List<StatsBucket> buckets;
  switch (range) {
    case StatsRange.week:
      buckets = _weekBuckets(now, history);
    case StatsRange.month:
      buckets = _monthBuckets(now, history);
    case StatsRange.year:
      buckets = _yearBuckets(now, history);
    case StatsRange.all:
      buckets = _allBucketsFromHistory(
        history,
        now,
        createdFallback: createdFallback ?? now,
      );
  }

  final total = buckets.fold<int>(0, (s, b) => s + b.count);
  final completed = buckets.fold<int>(0, (s, b) => s + b.completedGoals);
  final active = buckets.fold<int>(0, (s, b) => s + b.daysActive);

  ZekrDayStat? best;
  for (final e in history.values) {
    if (best == null || e.count > best.count) best = e;
  }

  final avg = buckets.isEmpty ? 0.0 : total / buckets.length;

  return ZekrStats(
    buckets: buckets,
    totalCount: total,
    completedGoals: completed,
    activeDays: active,
    bestDayCount: best?.count ?? 0,
    bestDayLabel: best?.day,
    averagePerBucket: avg,
    currentStreak: _streak(history, now),
  );
}

ZekrStats buildStats(
  Zekr zekr, {
  required StatsRange range,
  DateTime? anchor,
}) {
  final history = Map<String, ZekrDayStat>.fromEntries(
    zekr.history.map((e) => MapEntry(e.day, e)),
  );
  return buildStatsFromHistory(
    history,
    range: range,
    anchor: anchor,
    createdFallback: zekr.createdAt,
  );
}

OverallStats buildOverallStats(
  List<Zekr> items, {
  required StatsRange range,
  DateTime? anchor,
}) {
  final now = dateOnly(anchor ?? DateTime.now());
  final merged = mergeHistories(items);
  final stats = buildStatsFromHistory(
    merged,
    range: range,
    anchor: now,
    createdFallback: items.isEmpty
        ? now
        : items
            .map((e) => e.createdAt)
            .reduce((a, b) => a.isBefore(b) ? a : b),
  );

  final perZekr = items.map((z) {
    final s = buildStats(z, range: range, anchor: now);
    return ZekrBreakdownRow(
      id: z.id,
      text: z.text,
      count: s.totalCount,
      completedGoals: s.completedGoals,
    );
  }).toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  final lifetimeTotal =
      items.fold<int>(0, (s, z) => s + z.lifetimeCount);
  final lifetimeGoals =
      items.fold<int>(0, (s, z) => s + z.lifetimeCompletions);

  return OverallStats(
    stats: stats,
    perZekr: perZekr,
    zekrCount: items.length,
    lifetimeTotal: lifetimeTotal,
    lifetimeGoals: lifetimeGoals,
  );
}

List<StatsBucket> _weekBuckets(
  DateTime now,
  Map<String, ZekrDayStat> history,
) {
  // Monday-start week containing [now]
  final monday = now.subtract(Duration(days: now.weekday - 1));
  const names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  return List.generate(7, (i) {
    final day = monday.add(Duration(days: i));
    final key = dayKey(day);
    final stat = history[key];
    return StatsBucket(
      label: '${names[i]} ${day.day}.${day.month}.',
      shortLabel: names[i],
      count: stat?.count ?? 0,
      completedGoals: (stat?.completed ?? false) ? 1 : 0,
      daysActive: (stat != null && stat.count > 0) ? 1 : 0,
      start: day,
      end: day,
    );
  });
}

List<StatsBucket> _monthBuckets(
  DateTime now,
  Map<String, ZekrDayStat> history,
) {
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  return List.generate(daysInMonth, (i) {
    final day = DateTime(now.year, now.month, i + 1);
    final key = dayKey(day);
    final stat = history[key];
    return StatsBucket(
      label: '${day.day}.${day.month}.',
      shortLabel: '${day.day}',
      count: stat?.count ?? 0,
      completedGoals: (stat?.completed ?? false) ? 1 : 0,
      daysActive: (stat != null && stat.count > 0) ? 1 : 0,
      start: day,
      end: day,
    );
  });
}

List<StatsBucket> _yearBuckets(
  DateTime now,
  Map<String, ZekrDayStat> history,
) {
  const names = [
    'Jan',
    'Feb',
    'Mär',
    'Apr',
    'Mai',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Okt',
    'Nov',
    'Dez',
  ];
  return List.generate(12, (m) {
    final start = DateTime(now.year, m + 1, 1);
    final end = DateTime(now.year, m + 2, 0);
    var count = 0;
    var completed = 0;
    var active = 0;
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final stat = history[dayKey(d)];
      if (stat == null) continue;
      count += stat.count;
      if (stat.completed) completed++;
      if (stat.count > 0) active++;
    }
    return StatsBucket(
      label: '${names[m]} ${now.year}',
      shortLabel: names[m],
      count: count,
      completedGoals: completed,
      daysActive: active,
      start: start,
      end: end,
    );
  });
}

List<StatsBucket> _allBucketsFromHistory(
  Map<String, ZekrDayStat> history,
  DateTime now, {
  required DateTime createdFallback,
}) {
  if (history.isEmpty) {
    return [
      StatsBucket(
        label: 'Bisher',
        shortLabel: 'Σ',
        count: 0,
        completedGoals: 0,
        daysActive: 0,
        start: dateOnly(createdFallback),
        end: now,
      ),
    ];
  }
  final sorted = history.values.toList()
    ..sort((a, b) => a.day.compareTo(b.day));
  final years = <int>{};
  for (final e in sorted) {
    years.add(e.date.year);
  }
  final yearList = years.toList()..sort();
  return yearList.map((y) {
    var count = 0;
    var completed = 0;
    var active = 0;
    for (final e in sorted) {
      if (e.date.year != y) continue;
      count += e.count;
      if (e.completed) completed++;
      if (e.count > 0) active++;
    }
    return StatsBucket(
      label: '$y',
      shortLabel: '$y',
      count: count,
      completedGoals: completed,
      daysActive: active,
      start: DateTime(y, 1, 1),
      end: DateTime(y, 12, 31),
    );
  }).toList();
}

int _streak(Map<String, ZekrDayStat> history, DateTime now) {
  var streak = 0;
  var cursor = now;
  while (true) {
    final stat = history[dayKey(cursor)];
    if (stat == null || stat.count <= 0) break;
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Applies a count delta to today's history entry.
List<ZekrDayStat> applyHistoryDelta(
  List<ZekrDayStat> history, {
  required int delta,
  required int target,
  required bool markCompleted,
  bool clearCompleted = false,
  DateTime? at,
}) {
  if (delta == 0 && !markCompleted && !clearCompleted) return history;
  final key = dayKey(at ?? DateTime.now());
  final list = [...history];
  final idx = list.indexWhere((e) => e.day == key);
  if (idx < 0) {
    if (delta <= 0 && !markCompleted) return history;
    list.add(
      ZekrDayStat(
        day: key,
        count: delta < 0 ? 0 : delta,
        target: target,
        completed: markCompleted,
      ),
    );
  } else {
    final cur = list[idx];
    final nextCount = (cur.count + delta).clamp(0, 1 << 30);
    var completed = cur.completed;
    if (markCompleted) completed = true;
    if (clearCompleted) completed = false;
    if (nextCount == 0) completed = false;
    list[idx] = cur.copyWith(
      count: nextCount,
      target: target,
      completed: completed,
    );
  }
  list.sort((a, b) => a.day.compareTo(b.day));
  return list;
}
