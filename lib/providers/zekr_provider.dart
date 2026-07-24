import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/default_zekrs.dart';
import '../models/zekr.dart';
import '../models/zekr_stats.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class ZekrProvider extends ChangeNotifier {
  ZekrProvider({
    StorageService? storage,
    NotificationService? notifications,
  })  : _storage = storage ?? StorageService(),
        _notifications = notifications ?? NotificationService.instance;

  final StorageService _storage;
  final NotificationService _notifications;
  final _uuid = const Uuid();

  List<Zekr> _items = [];
  bool _loading = true;

  List<Zekr> get items => List.unmodifiable(_items);
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    _items = await _storage.loadAll();
    await _seedDefaultsIfNeeded();
    await _refreshPeriods();
    await _notifications.syncAll(_items);
    _loading = false;
    notifyListeners();
  }

  Future<void> _seedDefaultsIfNeeded() async {
    if (await _storage.hasSeededDefaults()) return;

    // Replace the three wrongly split defaults with one combined Zekr.
    final legacyRemoved = _items
        .where((e) => !legacyDefaultZekrTexts.contains(e.text))
        .toList();
    final hadLegacy = legacyRemoved.length != _items.length;
    _items = legacyRemoved;

    final defaults = createDefaultZekrs(uuid: _uuid);
    final existingTexts = _items.map((e) => e.text).toSet();
    final missing =
        defaults.where((d) => !existingTexts.contains(d.text)).toList();

    if (missing.isNotEmpty || hadLegacy) {
      _items = [...missing, ..._items];
      await _persist();
    }
    await _storage.markDefaultsSeeded();
  }

  /// Reset counters when a new period has begun after completion.
  Future<void> _refreshPeriods() async {
    var changed = false;
    final now = DateTime.now();
    _items = _items.map((z) {
      if (z.isCompleted && !now.isBefore(z.nextPeriodStart)) {
        changed = true;
        return z.copyWith(
          currentCount: 0,
          periodStart: now,
          clearCompletedAt: true,
        );
      }
      return z;
    }).toList();
    if (changed) await _persist();
  }

  Future<void> refreshIfNeeded() async {
    await _refreshPeriods();
    notifyListeners();
  }

  Zekr? byId(String id) {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add({
    required String text,
    String? note,
    required int targetCount,
    int incrementPerTap = 1,
    RepeatType repeatType = RepeatType.daily,
    int intervalDays = 1,
    int reminderHour = 8,
    int reminderMinute = 0,
    bool reminderEnabled = true,
  }) async {
    final now = DateTime.now();
    final zekr = Zekr(
      id: _uuid.v4(),
      text: text.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      targetCount: targetCount,
      incrementPerTap: incrementPerTap,
      repeatType: repeatType,
      intervalDays: intervalDays,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      reminderEnabled: reminderEnabled,
      periodStart: now,
      createdAt: now,
    );
    _items = [zekr, ..._items];
    await _persist();
    await _notifications.scheduleFor(zekr);
    notifyListeners();
  }

  Future<void> update(Zekr updated) async {
    _items = _items.map((e) => e.id == updated.id ? updated : e).toList();
    await _persist();
    await _notifications.scheduleFor(updated);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _items = _items.where((e) => e.id != id).toList();
    await _persist();
    await _notifications.cancelFor(id);
    notifyListeners();
  }

  /// Returns true if this tap completed the goal.
  Future<bool> tap(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return false;
    var z = _items[index];
    if (z.isWaitingForNextPeriod) return false;
    if (z.isCompleted) return false;

    final next = (z.currentCount + z.incrementPerTap).clamp(0, z.targetCount);
    final applied = next - z.currentCount;
    if (applied <= 0) return false;
    final justCompleted = next >= z.targetCount;
    z = z.copyWith(
      currentCount: next,
      completedAt: justCompleted ? DateTime.now() : z.completedAt,
      history: applyHistoryDelta(
        z.history,
        delta: applied,
        target: z.targetCount,
        markCompleted: justCompleted,
      ),
    );
    _items = [..._items]..[index] = z;
    await _persist();
    if (justCompleted) {
      await _notifications.scheduleFor(z);
    }
    notifyListeners();
    return justCompleted;
  }

  Future<void> undoTap(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    var z = _items[index];
    if (z.isWaitingForNextPeriod) return;
    final next = (z.currentCount - z.incrementPerTap).clamp(0, z.targetCount);
    final applied = z.currentCount - next;
    if (applied <= 0) return;
    z = z.copyWith(
      currentCount: next,
      clearCompletedAt: next < z.targetCount,
      history: applyHistoryDelta(
        z.history,
        delta: -applied,
        target: z.targetCount,
        markCompleted: false,
        clearCompleted: next < z.targetCount,
      ),
    );
    _items = [..._items]..[index] = z;
    await _persist();
    await _notifications.scheduleFor(z);
    notifyListeners();
  }

  Future<void> resetCount(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final z = _items[index].copyWith(
      currentCount: 0,
      clearCompletedAt: true,
      periodStart: DateTime.now(),
    );
    _items = [..._items]..[index] = z;
    await _persist();
    await _notifications.scheduleFor(z);
    notifyListeners();
  }

  String exportBackupJson() => _storage.encodeBackup(_items);

  /// Replaces all local Zekr with the imported backup.
  Future<int> importBackupJson(String raw) async {
    final imported = _storage.decodeBackup(raw);
    for (final old in _items) {
      await _notifications.cancelFor(old.id);
    }
    _items = imported;
    await _persist();
    await _notifications.syncAll(_items);
    notifyListeners();
    return _items.length;
  }

  Future<void> _persist() => _storage.saveAll(_items);
}
