import 'zekr_day_stat.dart';

enum RepeatType { daily, everyXDays, weekly }

class ZekrPart {
  final String text;
  final int targetCount;

  const ZekrPart({
    required this.text,
    required this.targetCount,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'targetCount': targetCount,
      };

  factory ZekrPart.fromJson(Map<String, dynamic> json) => ZekrPart(
        text: json['text'] as String,
        targetCount: json['targetCount'] as int,
      );
}

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
  final List<ZekrPart> parts;
  final List<int> partCounts;
  /// Daily plan/reminder, but can start another round anytime.
  final bool allowAnytime;

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
    this.parts = const [],
    this.partCounts = const [],
    this.allowAnytime = false,
  });

  bool get hasParts => parts.isNotEmpty;

  List<int> get effectivePartCounts {
    if (!hasParts) return const [];
    if (partCounts.length == parts.length) return partCounts;
    return List<int>.filled(parts.length, 0);
  }

  int get currentPartIndex {
    if (!hasParts) return 0;
    final counts = effectivePartCounts;
    for (var i = 0; i < parts.length; i++) {
      if (counts[i] < parts[i].targetCount) return i;
    }
    return parts.length - 1;
  }

  ZekrPart? get currentPart =>
      hasParts ? parts[currentPartIndex] : null;

  String get displayText =>
      hasParts ? parts[currentPartIndex].text : text;

  int get activeTarget =>
      hasParts ? parts[currentPartIndex].targetCount : targetCount;

  int get activeCount =>
      hasParts ? effectivePartCounts[currentPartIndex] : currentCount;

  int get totalTarget => hasParts
      ? parts.fold<int>(0, (s, p) => s + p.targetCount)
      : targetCount;

  int get totalCount => hasParts
      ? effectivePartCounts.fold<int>(0, (s, c) => s + c)
      : currentCount;

  bool get isCompleted {
    if (hasParts) {
      final counts = effectivePartCounts;
      for (var i = 0; i < parts.length; i++) {
        if (counts[i] < parts[i].targetCount) return false;
      }
      return true;
    }
    return currentCount >= targetCount;
  }

  double get progress {
    final t = totalTarget;
    if (t == 0) return 0;
    return (totalCount / t).clamp(0.0, 1.0);
  }

  double get partProgress {
    final t = activeTarget;
    if (t == 0) return 0;
    return (activeCount / t).clamp(0.0, 1.0);
  }

  int get remaining => (totalTarget - totalCount).clamp(0, totalTarget);

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
    if (allowAnytime) return false;
    return DateTime.now().isBefore(nextPeriodStart);
  }

  /// Official daily goal done, but anytime rounds are still allowed.
  bool get isDailyGoalDone {
    if (!isCompleted) return false;
    return DateTime.now().isBefore(nextPeriodStart);
  }

  Duration get timeUntilNextPeriod {
    final diff = nextPeriodStart.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get repeatLabel {
    final base = switch (repeatType) {
      RepeatType.daily => 'Täglich',
      RepeatType.everyXDays =>
        intervalDays == 1 ? 'Täglich' : 'Alle $intervalDays Tage',
      RepeatType.weekly => 'Wöchentlich',
    };
    if (allowAnytime) return '$base · jederzeit';
    return base;
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
    List<ZekrPart>? parts,
    List<int>? partCounts,
    bool? allowAnytime,
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
      parts: parts ?? this.parts,
      partCounts: partCounts ?? this.partCounts,
      allowAnytime: allowAnytime ?? this.allowAnytime,
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
        'parts': parts.map((e) => e.toJson()).toList(),
        'partCounts': effectivePartCounts,
        'allowAnytime': allowAnytime,
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

    final rawParts = json['parts'];
    final parts = <ZekrPart>[];
    if (rawParts is List) {
      for (final e in rawParts) {
        if (e is Map<String, dynamic>) {
          parts.add(ZekrPart.fromJson(e));
        } else if (e is Map) {
          parts.add(ZekrPart.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final rawCounts = json['partCounts'];
    final partCounts = <int>[];
    if (rawCounts is List) {
      for (final e in rawCounts) {
        if (e is int) {
          partCounts.add(e);
        } else if (e is num) {
          partCounts.add(e.toInt());
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
      parts: parts,
      partCounts: partCounts,
      allowAnytime: json['allowAnytime'] as bool? ?? false,
    );
  }
}
