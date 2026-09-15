import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/default_zekrs.dart';
import '../models/zekr.dart';
import '../models/zekr_day_stat.dart';
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
    await _reconcileHistory();
    await _refreshPeriods();
    await _notifications.syncAll(_items);
    _loading = false;
    notifyListeners();
  }

  Future<void> _seedDefaultsIfNeeded() async {
    if (await _storage.hasSeededDefaults()) return;

    // Replace wrongly split defaults with combined Zekr entries.
    final legacyRemoved = _items
        .where((e) => !legacyDefaultZekrTexts.contains(e.text))
        .toList();
    final hadLegacy = legacyRemoved.length != _items.length;
    _items = legacyRemoved;

    // Ensure Salam default is 3× daily if already present.
    var retargeted = false;
    _items = _items.map((z) {
      if (z.text == defaultSalamText &&
          (z.targetCount != 3 || z.repeatType != RepeatType.daily)) {
        retargeted = true;
        return z.copyWith(
          targetCount: 3,
          repeatType: RepeatType.daily,
          intervalDays: 1,
        );
      }
      return z;
    }).toList();

    final defaults = createDefaultZekrs(uuid: _uuid);
    final existingTexts = _items.map((e) => e.text).toSet();
    final missing =
        defaults.where((d) => !existingTexts.contains(d.text)).toList();

    if (missing.isNotEmpty || hadLegacy || retargeted) {
      _items = [...missing, ..._items];
      await _persist();
    }
    await _storage.markDefaultsSeeded();
  }

  /// Backfill history when currentCount is ahead (e.g. counted before
  /// history feature existed, or after an upgrade mid-session).
  Future<void> _reconcileHistory() async {
    var changed = false;
    _items = _items.map((z) {
      var history = [...z.history];
      var localChanged = false;

      // Fix completed days that were under-counted vs their target.
      for (var i = 0; i < history.length; i++) {
        final h = history[i];
        if (h.completed && h.target > 0 && h.count < h.target) {
          history[i] = h.copyWith(count: h.target);
          localChanged = true;
        }
      }

      if (z.currentCount > 0 || z.isCompleted) {
        final day = z.completedAt != null
            ? dayKey(z.completedAt!)
            : dayKey(DateTime.now());
        final idx = history.indexWhere((h) => h.day == day);
        final existing = idx >= 0 ? history[idx].count : 0;
        final desired = z.currentCount > 0
            ? z.currentCount
            : z.targetCount;
        final shouldComplete = z.isCompleted || desired >= z.targetCount;

        if (existing < desired ||
            (shouldComplete && (idx < 0 || !history[idx].completed))) {
          localChanged = true;
          if (idx < 0) {
            history.add(
              ZekrDayStat(
                day: day,
                count: desired,
                target: z.targetCount,
                completed: shouldComplete,
              ),
            );
          } else {
            final cur = history[idx];
            history[idx] = cur.copyWith(
              count: desired > cur.count ? desired : cur.count,
              target: z.targetCount,
              completed: shouldComplete || cur.completed,
            );
          }
        }
      }

      if (!localChanged) return z;
      changed = true;
      history.sort((a, b) => a.day.compareTo(b.day));
      return z.copyWith(history: history);
    }).toList();

    if (changed) await _persist();
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
          partCounts:
              z.hasParts ? List<int>.filled(z.parts.length, 0) : const [],
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

  /// Returns true if this tap completed the full goal (all parts).
  Future<bool> tap(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return false;
    var z = _items[index];
    if (z.isWaitingForNextPeriod) return false;

    // Anytime: if already complete, start a fresh round first.
    if (z.isCompleted && z.allowAnytime) {
      z = z.copyWith(
        currentCount: 0,
        partCounts: z.hasParts ? List<int>.filled(z.parts.length, 0) : const [],
        clearCompletedAt: true,
        periodStart: DateTime.now(),
      );
    }
    if (z.isCompleted) return false;

    late final int applied;
    late final int nextTotal;
    late final List<int> nextPartCounts;
    late final int nextCurrent;

    if (z.hasParts) {
      final counts = [...z.effectivePartCounts];
      final partIdx = z.currentPartIndex;
      final part = z.parts[partIdx];
      final before = counts[partIdx];
      final after = (before + z.incrementPerTap).clamp(0, part.targetCount);
      applied = after - before;
      if (applied <= 0) return false;
      counts[partIdx] = after;
      nextPartCounts = counts;
      nextTotal = counts.fold<int>(0, (s, c) => s + c);
      nextCurrent = after;
    } else {
      nextCurrent =
          (z.currentCount + z.incrementPerTap).clamp(0, z.targetCount);
      applied = nextCurrent - z.currentCount;
      if (applied <= 0) return false;
      nextTotal = nextCurrent;
      nextPartCounts = const [];
    }

    final justCompleted = z.hasParts
        ? () {
            for (var i = 0; i < z.parts.length; i++) {
              if (nextPartCounts[i] < z.parts[i].targetCount) return false;
            }
            return true;
          }()
        : nextCurrent >= z.targetCount;

    final syncedHistory = applyHistoryDelta(
      z.history,
      delta: applied,
      target: z.totalTarget,
      markCompleted: justCompleted,
    );
    final day = dayKey(DateTime.now());
    final hIdx = syncedHistory.indexWhere((h) => h.day == day);
    var history = syncedHistory;
    if (hIdx >= 0 && syncedHistory[hIdx].count < nextTotal) {
      history = [...syncedHistory];
      history[hIdx] = history[hIdx].copyWith(
        count: nextTotal > history[hIdx].count ? nextTotal : history[hIdx].count,
        // For multi-round anytime, keep counting up; don't force count = nextTotal only
        completed: justCompleted || history[hIdx].completed,
      );
      // Better: always add delta, already done in applyHistoryDelta.
      // Fix undercount only when history lags behind this period's total.
      if (history[hIdx].count < nextTotal && !z.allowAnytime) {
        history[hIdx] = history[hIdx].copyWith(count: nextTotal);
      }
    }

    z = z.copyWith(
      currentCount: nextCurrent,
      partCounts: nextPartCounts,
      completedAt: justCompleted ? DateTime.now() : z.completedAt,
      history: history,
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

    late final int applied;
    late final int nextCurrent;
    late final List<int> nextPartCounts;

    if (z.hasParts) {
      final counts = [...z.effectivePartCounts];
      var partIdx = z.currentPartIndex;
      // If current part is empty but not first, step back.
      if (counts[partIdx] == 0 && partIdx > 0) {
        partIdx -= 1;
      }
      if (counts[partIdx] == 0) return;
      final before = counts[partIdx];
      final after =
          (before - z.incrementPerTap).clamp(0, z.parts[partIdx].targetCount);
      applied = before - after;
      if (applied <= 0) return;
      counts[partIdx] = after;
      nextPartCounts = counts;
      nextCurrent = after;
    } else {
      nextCurrent =
          (z.currentCount - z.incrementPerTap).clamp(0, z.targetCount);
      applied = z.currentCount - nextCurrent;
      if (applied <= 0) return;
      nextPartCounts = const [];
    }

    final stillComplete = z.hasParts
        ? () {
            for (var i = 0; i < z.parts.length; i++) {
              if (nextPartCounts[i] < z.parts[i].targetCount) return false;
            }
            return true;
          }()
        : nextCurrent >= z.targetCount;

    z = z.copyWith(
      currentCount: nextCurrent,
      partCounts: nextPartCounts,
      clearCompletedAt: !stillComplete,
      history: applyHistoryDelta(
        z.history,
        delta: -applied,
        target: z.totalTarget,
        markCompleted: false,
        clearCompleted: !stillComplete,
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
      partCounts: _items[index].hasParts
          ? List<int>.filled(_items[index].parts.length, 0)
          : const [],
      clearCompletedAt: true,
      periodStart: DateTime.now(),
    );
    _items = [..._items]..[index] = z;
    await _persist();
    await _notifications.scheduleFor(z);
    notifyListeners();
  }

  /// Start another round immediately (for allowAnytime zekrs).
  Future<void> startAnytimeRound(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final z = _items[index];
    if (!z.allowAnytime) return;
    final reset = z.copyWith(
      currentCount: 0,
      partCounts: z.hasParts ? List<int>.filled(z.parts.length, 0) : const [],
      clearCompletedAt: true,
      periodStart: DateTime.now(),
    );
    _items = [..._items]..[index] = reset;
    await _persist();
    await _notifications.scheduleFor(reset);
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
