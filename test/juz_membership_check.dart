import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/data/quran_passages.dart';

void main() {
  test('every juz 1..30 has at least one surah', () {
    for (var j = 1; j <= 30; j++) {
      final nums = kJuzSurahNumbers[j] ?? const <int>[];
      expect(nums, isNotEmpty, reason: 'juz $j empty');
    }
    expect(kJuzSurahNumbers[5], contains(4));
    expect(kJuzSurahNumbers[2], contains(2));
  });
}
