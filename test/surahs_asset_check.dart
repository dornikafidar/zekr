import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/data/quran_passages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('surahs.json has all 114 and juz 2 includes Baqarah', () async {
    final raw = await rootBundle.loadString('assets/quran/surahs.json');
    final list = jsonDecode(raw) as List<dynamic>;
    expect(list.length, 114);
    final nums = {
      for (final e in list) (e as Map)['number'] as int,
    };
    expect(nums.contains(2), isTrue);
    expect(kJuzSurahNumbers[2], contains(2));
    expect(kJuzSurahNumbers[30]!.length, greaterThan(30));
  });
}
