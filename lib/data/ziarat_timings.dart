import 'dart:convert';

import 'package:flutter/services.dart';

class ZiaratTiming {
  const ZiaratTiming({
    required this.words,
    required this.segments,
    required this.file,
  });

  final List<String> words;

  /// Each: [wordIndex, startMs, endMs]
  final List<List<int>> segments;
  final String file;

  String get assetPath => 'assets/audio/ziarat/$file';

  int wordIndexAt(Duration position) {
    final ms = position.inMilliseconds;
    if (segments.isEmpty) return -1;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s.length < 3) continue;
      final start = s[1];
      final end = s[2];
      final last = i == segments.length - 1;
      if (ms >= start && (last ? ms <= end + 120 : ms < end)) {
        return s[0].clamp(0, words.length - 1);
      }
    }
    if (ms >= segments.first[1]) {
      var best = segments.first[0];
      for (final s in segments) {
        if (s.length < 3) continue;
        if (ms >= s[1]) best = s[0];
      }
      return best.clamp(0, words.isEmpty ? 0 : words.length - 1);
    }
    return -1;
  }
}

/// Stretch/shrink word windows so the last end matches [durationMs].
List<List<int>> scaleSegmentsToDuration(
  List<List<int>> segments,
  int durationMs,
) {
  if (segments.isEmpty || durationMs <= 0) return segments;
  final end = segments.last[2];
  if (end <= 0) return segments;
  final ratio = durationMs / end;
  if ((ratio - 1.0).abs() < 0.04) return segments;
  final scaled = [
    for (final s in segments)
      [s[0], (s[1] * ratio).round(), (s[2] * ratio).round()],
  ];
  scaled.last[2] = durationMs;
  return scaled;
}

class ZiaratTimings {
  ZiaratTimings._(this._items);

  final Map<String, ZiaratTiming> _items;
  static ZiaratTimings? _cached;

  static Future<ZiaratTimings> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/audio/ziarat/timings.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final map = json['items'] as Map<String, dynamic>;
    final items = <String, ZiaratTiming>{};
    for (final e in map.entries) {
      final m = e.value as Map<String, dynamic>;
      items[e.key] = ZiaratTiming(
        file: m['file'] as String,
        words: (m['words'] as List).cast<String>(),
        segments: [
          for (final s in (m['segments'] as List))
            (s as List).map((x) => (x as num).toInt()).toList(),
        ],
      );
    }
    return _cached = ZiaratTimings._(items);
  }

  ZiaratTiming? ofId(String ziaratId) => _items[ziaratId];

  /// Word sync for a streamed reciter: assets/audio/ziarat/sync/{ziaratId}/{sourceId}.json
  static Future<ZiaratTiming?> loadStreamSync({
    required String ziaratId,
    required String sourceId,
  }) async {
    final path = 'assets/audio/ziarat/sync/$ziaratId/$sourceId.json';
    try {
      final raw = await rootBundle.loadString(path);
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final segs = [
        for (final s in (m['segments'] as List))
          (s as List).map((x) => (x as num).toInt()).toList(),
      ];
      // Need real timestamps — reject empty/placeholder packs.
      if (segs.isEmpty || segs.where((s) => s.length >= 3 && s[1] >= 0).length < 8) {
        return null;
      }
      return ZiaratTiming(
        file: '$ziaratId.mp3',
        words: (m['words'] as List).cast<String>(),
        segments: segs,
      );
    } catch (_) {
      return null;
    }
  }
}
