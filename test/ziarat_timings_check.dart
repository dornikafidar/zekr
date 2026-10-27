import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/data/ziarat_timings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scaleSegmentsToDuration fixes stretched TTS clock', () {
    final scaled = scaleSegmentsToDuration(
      [
        [0, 0, 2000],
        [1, 2000, 4400],
      ],
      2200,
    );
    expect(scaled.last[2], 2200);
    expect(scaled.first[2], 1000);
  });

  test('every ziarat has audio + word timings', () async {
    final raw = await rootBundle.loadString('assets/audio/ziarat/timings.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final items = json['items'] as Map<String, dynamic>;
    const ids = [
      'ashura',
      'warith',
      'aminullah',
      'imam_reza',
      'kazemayn_z',
      'masumeh',
      'shahcheragh',
      'alaeddin',
    ];
    for (final id in ids) {
      expect(items.containsKey(id), isTrue, reason: id);
      final m = items[id] as Map<String, dynamic>;
      final words = m['words'] as List;
      final segs = m['segments'] as List;
      expect(words, isNotEmpty, reason: id);
      expect(segs.length, words.length, reason: id);
      await rootBundle.load('assets/audio/ziarat/${m['file']}');
    }
  });
}
