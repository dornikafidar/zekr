import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class AyahTiming {
  const AyahTiming({
    required this.words,
    required this.segments,
    this.file,
    this.networkUrl,
  });

  final String? file;
  final String? networkUrl;
  final List<String> words;

  /// Each: [wordIndex, startMs, endMs]
  final List<List<int>> segments;

  String? get assetPath =>
      file == null ? null : 'assets/audio/abdulbaset/$file';

  bool get hasLocalAsset => file != null;

  int wordIndexAt(Duration position) {
    final ms = position.inMilliseconds;
    if (segments.isEmpty) return -1;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s.length < 3) continue;
      final start = s[1];
      final end = s[2];
      final last = i == segments.length - 1;
      if (ms >= start && (last ? ms <= end + 80 : ms < end)) {
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

class RecitationTimings {
  RecitationTimings._(this._ayahs);

  final Map<String, AyahTiming> _ayahs;
  static RecitationTimings? _cached;
  static final Map<String, AyahTiming> _remoteCache = {};

  static const _cdn =
      'https://everyayah.com/data/Abdul_Basit_Murattal_64kbps';
  static const _cdnAlt =
      'https://verses.quran.com/AbdulBaset/Murattal/mp3';
  static const _api = 'https://api.quran.com/api/v4';

  static Future<RecitationTimings> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString(
      'assets/audio/abdulbaset/timings.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final ayahs = <String, AyahTiming>{};
    final map = json['ayahs'] as Map<String, dynamic>;
    for (final e in map.entries) {
      final m = e.value as Map<String, dynamic>;
      ayahs[e.key] = AyahTiming(
        file: m['file'] as String?,
        words: (m['words'] as List).cast<String>(),
        segments: [
          for (final s in (m['segments'] as List))
            (s as List).map((e) => (e as num).toInt()).toList(),
        ],
      );
    }
    return _cached = RecitationTimings._(ayahs);
  }

  AyahTiming? ofKey(String verseKey) => _ayahs[verseKey];

  /// everyayah SSSAAA.mp3
  String _cdnFile(String verseKey) {
    if (verseKey == 'bismillah') return '$_cdn/001001.mp3';
    final code = _verseCode(verseKey);
    return '$_cdn/$code.mp3';
  }

  /// Same SSSAAA.mp3 layout on verses.quran.com mirror.
  String _cdnAltFile(String verseKey) {
    if (verseKey == 'bismillah') return '$_cdnAlt/001001.mp3';
    return '$_cdnAlt/${_verseCode(verseKey)}.mp3';
  }

  static String _verseCode(String verseKey) {
    final parts = verseKey.split(':');
    final surah = int.parse(parts[0]);
    final ayah = int.parse(parts[1]);
    return '${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}';
  }

  AyahTiming _streamOnly(String verseKey) {
    return AyahTiming(
      file: null,
      networkUrl: _cdnFile(verseKey),
      words: const [],
      segments: const [],
    );
  }

  List<String> networkUrlsFor(String verseKey) => [
        _cdnFile(verseKey),
        _cdnAltFile(verseKey),
      ];

  /// Local pack if present, otherwise fetch timings + stream URL.
  /// Never returns null for a valid `s:a` / `bismillah` key — CDN always.
  Future<AyahTiming?> resolve(String verseKey) async {
    final local = _ayahs[verseKey];
    if (local != null) {
      return AyahTiming(
        file: local.file,
        networkUrl: local.networkUrl ?? _cdnFile(verseKey),
        words: local.words,
        segments: local.segments,
      );
    }
    if (_remoteCache.containsKey(verseKey)) return _remoteCache[verseKey];
    if (verseKey == 'bismillah') {
      final b = _ayahs['bismillah'] ?? _ayahs['1:1'];
      if (b != null) {
        return AyahTiming(
          file: b.file,
          networkUrl: _cdnFile('bismillah'),
          words: b.words,
          segments: b.segments,
        );
      }
      return _streamOnly('1:1');
    }
    final parts = verseKey.split(':');
    if (parts.length != 2) return null;
    if (int.tryParse(parts[0]) == null || int.tryParse(parts[1]) == null) {
      return null;
    }

    try {
      final uri = Uri.parse(
        '$_api/verses/by_key/$verseKey?audio=2&words=true&word_fields=text_uthmani',
      );
      final client = HttpClient();
      try {
        final req = await client.getUrl(uri);
        req.headers.set(HttpHeaders.userAgentHeader, 'ZekrApp/1.0');
        final res = await req.close().timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) {
          return _streamOnly(verseKey);
        }
        final body = await res.transform(utf8.decoder).join();
        final verse =
            (jsonDecode(body) as Map<String, dynamic>)['verse']
                as Map<String, dynamic>;
        final words = [
          for (final w in (verse['words'] as List))
            if ((w as Map)['char_type_name'] == 'word' &&
                w['text_uthmani'] != null)
              w['text_uthmani'] as String,
        ];
        final segs = <List<int>>[];
        for (final s in (verse['audio'] as Map?)?['segments'] as List? ?? []) {
          final list = (s as List).map((e) => (e as num).toInt()).toList();
          if (list.length >= 4) {
            segs.add([list[1] - 1, list[2], list[3]]);
          } else if (list.length == 3) {
            segs.add(list);
          }
        }
        final t = AyahTiming(
          file: null,
          networkUrl: _cdnFile(verseKey),
          words: words,
          segments: segs,
        );
        _remoteCache[verseKey] = t;
        return t;
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      // ponytail: API/CDN sync optional — stream URL alone is enough to play
      return _streamOnly(verseKey);
    }
  }
}

int? surahNumberFromZekrId(String id) {
  final m = RegExp(r'^quran_s(\d+)$').firstMatch(id);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

bool _part0IsBismillah(List<String>? partTexts) {
  if (partTexts == null || partTexts.isEmpty) return true;
  final t = partTexts.first.replaceAll('\uFEFF', '').trimLeft();
  return t.startsWith('بِسْمِ') ||
      t.startsWith('بِّسْمِ') ||
      t.startsWith('بسم');
}

/// [partTexts] = current zekr part strings (to detect leading Bismillah).
String? audioVerseKey(
  String zekrId,
  int partIndex, {
  List<String>? partTexts,
}) {
  final withBis = _part0IsBismillah(partTexts);
  switch (zekrId) {
    case 'quran_kursi':
      final keys = withBis
          ? const ['bismillah', '2:255', '2:256', '2:257']
          : const ['2:255', '2:256', '2:257'];
      return partIndex < keys.length ? keys[partIndex] : null;
    case 'quran_inyakad':
      final keys = withBis
          ? const ['bismillah', '68:51', '68:52']
          : const ['68:51', '68:52'];
      return partIndex < keys.length ? keys[partIndex] : null;
  }
  final s = surahNumberFromZekrId(zekrId);
  if (s == null) return null;
  if (s == 1) return '1:${partIndex + 1}';
  if (s == 9) return '9:${partIndex + 1}';
  if (withBis) {
    if (partIndex == 0) return 'bismillah';
    return '$s:$partIndex';
  }
  return '$s:${partIndex + 1}';
}

bool hasAudioForZekr(String zekrId) =>
    zekrId == 'quran_kursi' ||
    zekrId == 'quran_inyakad' ||
    surahNumberFromZekrId(zekrId) != null;

/// Split ayah / passage text into display words (RTL Arabic).
List<String> splitArabicWords(String text) {
  return [
    for (final p in text.split(RegExp(r'\s+')))
      if (p.trim().isNotEmpty) p.trim(),
  ];
}

/// Cap sync length when the file is much longer than the shown text
/// (e.g. زیارت عاشورا audio with ۱۰۰× loops, UI text once).
/// ponytail: heuristic pace — upgrade: real word timings per qari.
int syncDurationForDisplayedWords(int audioMs, int wordCount) {
  if (wordCount <= 0 || audioMs <= 0) return audioMs;
  const maxMsPerWord = 520;
  const targetMsPerWord = 360;
  if (audioMs / wordCount <= maxMsPerWord) return audioMs;
  return (wordCount * targetMsPerWord).round().clamp(1, audioMs);
}

/// Char-weighted word windows over [durationMs].
/// ponytail: approximate sync when API segments missing — upgrade: full murattal timings pack.
List<List<int>> approxWordSegments(List<String> words, int durationMs) {
  if (words.isEmpty || durationMs <= 0) return const [];
  // Letter weight without harakat — closer to spoken length than raw UTF-16.
  final weights = [
    for (final w in words)
      () {
        final n = w.runes.where((r) {
          // Arabic combining marks / tatweel
          return !(r == 0x0640 || (r >= 0x064B && r <= 0x065F) || r == 0x0670);
        }).length;
        return n <= 0 ? 1 : n;
      }(),
  ];
  final total = weights.fold<int>(0, (a, b) => a + b);
  var t = 0;
  final segs = <List<int>>[];
  for (var i = 0; i < words.length; i++) {
    final span =
        (durationMs * weights[i] / total).round().clamp(90, durationMs);
    final end =
        i == words.length - 1 ? durationMs : (t + span).clamp(0, durationMs);
    segs.add([i, t, end < t + 60 ? t + 60 : end]);
    t = segs.last[2];
  }
  if (segs.isNotEmpty) segs.last[2] = durationMs;
  return segs;
}

AyahTiming withWordsFromText(AyahTiming t, String? text) {
  if (t.words.isNotEmpty || text == null || text.trim().isEmpty) return t;
  return AyahTiming(
    file: t.file,
    networkUrl: t.networkUrl,
    words: splitArabicWords(text),
    segments: t.segments,
  );
}

AyahTiming withApproxSegments(AyahTiming t, int durationMs) {
  if (t.segments.isNotEmpty || t.words.isEmpty || durationMs <= 0) return t;
  return AyahTiming(
    file: t.file,
    networkUrl: t.networkUrl,
    words: t.words,
    segments: approxWordSegments(t.words, durationMs),
  );
}
