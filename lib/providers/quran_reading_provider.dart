import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

enum QuranDailyGoal {
  ayah10(10, '۱۰ آیه'),
  ayah20(20, '۲۰ آیه'),
  halfHizb(40, 'نیم حزب'), // ~½ hizb ≈ 40 ayahs (approx)
  hizb(80, 'یک حزب'),
  juz(200, 'یک جزء'); // ~1 juz ≈ 200 ayahs average

  const QuranDailyGoal(this.ayahTarget, this.labelFa);
  final int ayahTarget;
  final String labelFa;
}

/// Daily Quran reading goal + progress + reminder.
class QuranReadingProvider extends ChangeNotifier {
  static const _kEnabled = 'quran_goal_enabled';
  static const _kGoal = 'quran_goal_type';
  static const _kHour = 'quran_goal_hour';
  static const _kMinute = 'quran_goal_minute';
  static const _kCount = 'quran_goal_count';
  static const _kDay = 'quran_goal_day'; // yyyy-MM-dd

  bool enabled = false;
  QuranDailyGoal goal = QuranDailyGoal.ayah10;
  int hour = 8;
  int minute = 0;
  int todayCount = 0;
  String _dayKey = '';

  int get target => goal.ayahTarget;
  bool get doneToday => todayCount >= target;
  double get progress => target <= 0 ? 0 : (todayCount / target).clamp(0.0, 1.0);

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool(_kEnabled) ?? false;
    final g = p.getString(_kGoal);
    goal = QuranDailyGoal.values.firstWhere(
      (e) => e.name == g,
      orElse: () => QuranDailyGoal.ayah10,
    );
    hour = p.getInt(_kHour) ?? 8;
    minute = p.getInt(_kMinute) ?? 0;
    _rollDay(p);
    notifyListeners();
    await _resyncReminder();
  }

  String _todayKey([DateTime? now]) {
    final n = now ?? DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  void _rollDay(SharedPreferences p) {
    final today = _todayKey();
    final stored = p.getString(_kDay) ?? '';
    if (stored != today) {
      _dayKey = today;
      todayCount = 0;
      p.setString(_kDay, today);
      p.setInt(_kCount, 0);
    } else {
      _dayKey = today;
      todayCount = p.getInt(_kCount) ?? 0;
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, enabled);
    await p.setString(_kGoal, goal.name);
    await p.setInt(_kHour, hour);
    await p.setInt(_kMinute, minute);
    await p.setString(_kDay, _dayKey);
    await p.setInt(_kCount, todayCount);
  }

  Future<void> setEnabled(bool v) async {
    enabled = v;
    await _save();
    await _resyncReminder();
    notifyListeners();
  }

  Future<void> setGoal(QuranDailyGoal g) async {
    goal = g;
    await _save();
    await _resyncReminder();
    notifyListeners();
  }

  Future<void> setTime(int h, int m) async {
    hour = h;
    minute = m;
    await _save();
    await _resyncReminder();
    notifyListeners();
  }

  /// Call when user finishes listening/reading one ayah.
  Future<void> recordAyahs(int n) async {
    if (n <= 0) return;
    final p = await SharedPreferences.getInstance();
    _rollDay(p);
    final wasDone = doneToday;
    todayCount += n;
    await _save();
    if (!wasDone && doneToday) {
      await NotificationService.instance.cancelQuranGoal();
    }
    notifyListeners();
  }

  Future<void> _resyncReminder() async {
    if (!enabled) {
      await NotificationService.instance.cancelQuranGoal();
      return;
    }
    final p = await SharedPreferences.getInstance();
    _rollDay(p);
    if (doneToday) {
      await NotificationService.instance.cancelQuranGoal();
      // Schedule tomorrow.
      await NotificationService.instance.scheduleQuranGoal(
        hour: hour,
        minute: minute,
        title: 'وقت تلاوت قرآن',
        body: 'هدف امروز: ${goal.labelFa}',
        skipToday: true,
      );
      return;
    }
    await NotificationService.instance.scheduleQuranGoal(
      hour: hour,
      minute: minute,
      title: 'وقت تلاوت قرآن',
      body: 'هدف امروز: ${goal.labelFa} · پیشرفت $todayCount/$target',
      skipToday: false,
    );
  }
}
