import 'zekr_day_stat.dart';

enum RepeatType { daily, everyXDays, weekly }

class Zekr {
  final String id;
  final String text;
  final String? note;
  final int targetCount;
  final int currentCount;
  final int incrementPerTap;
  final RepeatType repeatType;
  final int intervalDays;
  final int reminderHour;
  final int reminderMinute;
  final bool reminderEnabled;
  final DateTime periodStart;
  final DateTime? completedAt;
  final DateTime createdAt;
  final List<ZekrDayStat> history;

  const Zekr({
    required this.id,
    required this.text,
    this.note,
    required this.targetCount,
    this.currentCount = 0,
    this.incrementPerTap = 1,
    this.repeatType = RepeatType.daily,
    this.intervalDays = 1,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.reminderEnabled = true,
    required this.periodStart,
    this.completedAt,
    required this.createdAt,
    this.history = const [],
  });

  bool get isCompleted => currentCount >= targetCount;

  double get progress =>
      targetCount == 0 ? 0 : (currentCount / targetCount).clamp(0.0, 1.0);

  int get remaining => (targetCount - currentCount).clamp(0, targetCount);

  int get lifetimeCount =>
      history.fold<int>(0, (sum, e) => sum + e.count);

  int get lifetimeCompletions =>
      history.where((e) => e.completed).length;

  DateTime get nextPeriodStart {
    final base = completedAt ?? periodStart;
    switch (repeatType) {
      case RepeatType.daily:
        return DateTime(base.year, base.month, base.day)
            .add(const Duration(days: 1));
      case RepeatType.everyXDays:
        return DateTime(base.year, base.month, base.day)
            .add(Duration(days: intervalDays));
      case RepeatType.weekly:
        return DateTime(base.year, base.month, base.day)
            .add(const Duration(days: 7));
    }
  }

  bool get isWaitingForNextPeriod {
    if (!isCompleted) return false;
    return DateTime.now().isBefore(nextPeriodStart);
  }

  Duration get timeUntilNextPeriod {
    final diff = nextPeriodStart.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get repeatLabel {
    switch (repeatType) {
      case RepeatType.daily:
        return 'Täglich';
      case RepeatType.everyXDays:
        return intervalDays == 1
            ? 'Täglich'
            : 'Alle $intervalDays Tage';
      case RepeatType.weekly:
        return 'Wöchentlich';
    }
  }

  Zekr copyWith({
    String? id,
    String? text,
    String? note,
    bool clearNote = false,
    int? targetCount,
    int? currentCount,
    int? incrementPerTap,
    RepeatType? repeatType,
    int? intervalDays,
    int? reminderHour,
    int? reminderMinute,
    bool? reminderEnabled,
    DateTime? periodStart,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
    List<ZekrDayStat>? history,
  }) {
    return Zekr(
      id: id ?? this.id,
      text: text ?? this.text,
      note: clearNote ? null : (note ?? this.note),
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      incrementPerTap: incrementPerTap ?? this.incrementPerTap,
      repeatType: repeatType ?? this.repeatType,
      intervalDays: intervalDays ?? this.intervalDays,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      periodStart: periodStart ?? this.periodStart,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'note': note,
        'targetCount': targetCount,
        'currentCount': currentCount,
        'incrementPerTap': incrementPerTap,
        'repeatType': repeatType.name,
        'intervalDays': intervalDays,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'reminderEnabled': reminderEnabled,
        'periodStart': periodStart.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'history': history.map((e) => e.toJson()).toList(),
      };

  factory Zekr.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'];
    final history = <ZekrDayStat>[];
    if (rawHistory is List) {
      for (final e in rawHistory) {
        if (e is Map<String, dynamic>) {
          history.add(ZekrDayStat.fromJson(e));
        } else if (e is Map) {
          history.add(ZekrDayStat.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return Zekr(
      id: json['id'] as String,
      text: json['text'] as String,
      note: json['note'] as String?,
      targetCount: json['targetCount'] as int,
      currentCount: json['currentCount'] as int? ?? 0,
      incrementPerTap: json['incrementPerTap'] as int? ?? 1,
      repeatType: RepeatType.values.firstWhere(
        (e) => e.name == json['repeatType'],
        orElse: () => RepeatType.daily,
      ),
      intervalDays: json['intervalDays'] as int? ?? 1,
      reminderHour: json['reminderHour'] as int? ?? 8,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      periodStart: DateTime.parse(json['periodStart'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      history: history,
    );
  }
}
