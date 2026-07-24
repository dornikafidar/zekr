import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/zekr.dart';

class StorageService {
  static const _key = 'zekr_list';

  Future<List<Zekr>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Zekr.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<Zekr> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
