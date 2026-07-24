class ZekrDayStat {
  final String day; // yyyy-MM-dd
  final int count;
  final int target;
  final bool completed;

  const ZekrDayStat({
    required this.day,
    this.count = 0,
    this.target = 0,
    this.completed = false,
  });

  DateTime get date {
    final p = day.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  ZekrDayStat copyWith({
    String? day,
    int? count,
    int? target,
    bool? completed,
  }) {
    return ZekrDayStat(
      day: day ?? this.day,
      count: count ?? this.count,
      target: target ?? this.target,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'count': count,
        'target': target,
        'completed': completed,
      };

  factory ZekrDayStat.fromJson(Map<String, dynamic> json) => ZekrDayStat(
        day: json['day'] as String,
        count: json['count'] as int? ?? 0,
        target: json['target'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}

String dayKey(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
