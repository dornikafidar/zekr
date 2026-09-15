import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/zekr.dart';

class StorageService {
  static const _key = 'zekr_list';
  static const _seededKey = 'defaults_seeded_v6';

  Future<List<Zekr>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    return decodeBackup(raw);
  }

  Future<void> saveAll(List<Zekr> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, encodeBackup(items));
  }

  Future<bool> hasSeededDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seededKey) ?? false;
  }

  Future<void> markDefaultsSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seededKey, true);
  }

  /// Full local backup payload (versioned, includes history).
  String encodeBackup(List<Zekr> items) {
    return jsonEncode({
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    });
  }

  List<Zekr> decodeBackup(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map((e) => Zekr.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'];
      if (items is List) {
        return items
            .map((e) => Zekr.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw const FormatException('Ungültiges Backup-Format');
  }
}
