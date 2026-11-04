import 'dart:convert';

import 'package:flutter/services.dart';

/// Offline Farsi ayah translations (IslamHouse / assets/quran/fa.json).
class QuranFa {
  QuranFa._();
  static Map<String, String>? _map;

  static Future<void> ensureLoaded() async {
    if (_map != null) return;
    final raw = await rootBundle.loadString('assets/quran/fa.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _map = {
      for (final e in decoded.entries) e.key: e.value as String,
    };
  }

  /// [verseKey] like `2:255` or `bismillah` → `1:1`.
  static String? of(String verseKey) {
    final m = _map;
    if (m == null) return null;
    if (verseKey == 'bismillah') return m['1:1'];
    return m[verseKey];
  }
}
