import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/zekr.dart';

/// Shared Bismillah for every surah / passage (except Fatiha ayah 1 / Tawbah).
const kBismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

bool startsWithBismillah(String s) {
  final t = s.replaceAll('\uFEFF', '').trimLeft();
  return t.startsWith('بِسْمِ') ||
      t.startsWith('بِّسْمِ') ||
      t.startsWith('بسم');
}

String stripLeadingBismillah(String s) {
  final t = s.replaceAll('\uFEFF', '').trimLeft();
  if (!startsWithBismillah(t)) return t;
  final m = RegExp(r'^ب[ِِّ]*سْمِ\s+\S+\s+\S+\s+\S+\s*').firstMatch(t);
  if (m == null) return t;
  return t.substring(m.end).trimLeft();
}

List<String> withLeadingBismillah(List<String> ayahs, {required int surah}) {
  if (ayahs.isEmpty) return [kBismillah];
  // Fatiha: first ayah IS Bismillah. Tawbah: no Bismillah.
  if (surah == 1 || surah == 9) return ayahs;
  final rest = <String>[
    stripLeadingBismillah(ayahs.first),
    ...ayahs.skip(1),
  ].where((a) => a.trim().isNotEmpty).toList();
  return [kBismillah, ...rest];
}

class QuranPassage {
  const QuranPassage({
    required this.id,
    required this.title,
    required this.ref,
    required this.ayahs,
    this.number,
    this.juz,
  });

  final String id;
  final String title;
  final String ref;
  final List<String> ayahs;
  final int? number;
  final int? juz;

  String get text => ayahs.join('\n');

  List<ZekrPart> get parts => [
        for (final a in ayahs) ZekrPart(text: a, targetCount: 1),
      ];
}

class JuzInfo {
  const JuzInfo({required this.juz, required this.surahNumbers});

  final int juz;
  final List<int> surahNumbers;
}

/// Canonical surah membership per juz (a surah may appear in several juz).
const kJuzSurahNumbers = <int, List<int>>{
  1: [1, 2],
  2: [2],
  3: [2, 3],
  4: [3, 4],
  5: [4],
  6: [4, 5],
  7: [5, 6],
  8: [6, 7],
  9: [7, 8],
  10: [8, 9],
  11: [9, 10, 11],
  12: [11, 12],
  13: [12, 13, 14],
  14: [15, 16],
  15: [17, 18],
  16: [18, 19, 20],
  17: [21, 22],
  18: [23, 24, 25],
  19: [25, 26, 27],
  20: [27, 28, 29],
  21: [29, 30, 31, 32, 33],
  22: [33, 34, 35, 36],
  23: [36, 37, 38, 39],
  24: [39, 40, 41],
  25: [41, 42, 43, 44, 45],
  26: [46, 47, 48, 49, 50, 51],
  27: [51, 52, 53, 54, 55, 56, 57],
  28: [58, 59, 60, 61, 62, 63, 64, 65, 66],
  29: [67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77],
  30: [
    78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96,
    97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112,
    113, 114,
  ],
};

List<QuranPassage> get _extras => [
      QuranPassage(
        id: 'quran_kursi',
        title: 'آیة‌الکرسی',
        ref: 'بقره ۲:۲۵۵–۲۵۷',
        number: 2,
        juz: 3,
        ayahs: withLeadingBismillah(
          const [
            'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ ۚ '
                'لَا تَأْخُذُهُۥ سِنَةٌۭ وَلَا نَوْمٌۭ ۚ '
                'لَّهُۥ مَا فِى ٱلسَّمَٰوَٰتِ وَمَا فِى ٱلْأَرْضِ ۗ '
                'مَن ذَا ٱلَّذِى يَشْفَعُ عِندَهُۥٓ إِلَّا بِإِذْنِهِۦ ۚ '
                'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ '
                'وَلَا يُحِيطُونَ بِشَىْءٍۢ مِّنْ عِلْمِهِۦٓ إِلَّا بِمَا شَآءَ ۚ '
                'وَسِعَ كُرْسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلْأَرْضَ ۖ '
                'وَلَا يَـُٔودُهُۥ حِفْظُهُمَا ۚ وَهُوَ ٱلْعَلِىُّ ٱلْعَظِيمُ',
            'لَآ إِكْرَاهَ فِى ٱلدِّينِ ۖ قَد تَّبَيَّنَ ٱلرُّشْدُ مِنَ ٱلْغَىِّ ۚ '
                'فَمَن يَكْفُرْ بِٱلطَّٰغُوتِ وَيُؤْمِنۢ بِٱللَّهِ '
                'فَقَدِ ٱسْتَمْسَكَ بِٱلْعُرْوَةِ ٱلْوُثْقَىٰ لَا ٱنفِصَامَ لَهَا ۗ '
                'وَٱللَّهُ سَمِيعٌ عَلِيمٌ',
            'ٱللَّهُ وَلِىُّ ٱلَّذِينَ ءَامَنُوا۟ يُخْرِجُهُم مِّنَ ٱلظُّلُمَٰتِ إِلَى ٱلنُّورِ ۖ '
                'وَٱلَّذِينَ كَفَرُوٓا۟ أَوْلِيَآؤُهُمُ ٱلطَّٰغُوتُ '
                'يُخْرِجُونَهُم مِّنَ ٱلنُّورِ إِلَى ٱلظُّلُمَٰتِ ۗ '
                'أُو۟لَٰٓئِكَ أَصْحَٰبُ ٱلنَّارِ ۖ هُمْ فِيهَا خَٰلِدُونَ',
          ],
          surah: 2,
        ),
      ),
      QuranPassage(
        id: 'quran_inyakad',
        title: 'و إن یکاد',
        ref: 'قلم ۶۸:۵۱–۵۲',
        number: 68,
        juz: 29,
        ayahs: withLeadingBismillah(
          const [
            'وَإِن يَكَادُ ٱلَّذِينَ كَفَرُوا۟ لَيُزْلِقُونَكَ بِأَبْصَٰرِهِمْ '
                'لَمَّا سَمِعُوا۟ ٱلذِّكْرَ وَيَقُولُونَ إِنَّهُۥ لَمَجْنُونٌ',
            'وَمَا هُوَ إِلَّا ذِكْرٌ لِّلْعَٰلَمِينَ',
          ],
          surah: 68,
        ),
      ),
    ];

List<QuranPassage>? _cached;
List<JuzInfo>? _juzCached;
bool _loading = false;

Future<void> ensureQuranDataLoaded() async {
  if (_cached != null) return;
  if (_loading) {
    while (_loading) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    return;
  }
  _loading = true;
  try {
    final raw = await rootBundle.loadString('assets/quran/surahs.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final fromData = <QuranPassage>[
      for (final item in list)
        () {
          final m = Map<String, dynamic>.from(item as Map);
          final n = (m['number'] as num).toInt();
          final name = (m['name_fa'] as String?)?.isNotEmpty == true
              ? m['name_fa'] as String
              : '${m['name_en']}';
          final ayahs = (m['ayahs'] as List).map((e) => '$e').toList();
          return QuranPassage(
            id: '${m['id']}',
            title: 'سوره $name',
            ref: '$name · $n',
            number: n,
            juz: (m['juz'] as num?)?.toInt(),
            ayahs: withLeadingBismillah(ayahs, surah: n),
          );
        }(),
    ];

    final byJuz = <int, Set<int>>{};
    try {
      final juzRaw = await rootBundle.loadString('assets/quran/juz.json');
      final juzList = jsonDecode(juzRaw) as List<dynamic>;
      for (final item in juzList) {
        if (item is! Map) continue;
        final juzNum = (item['juz'] as num?)?.toInt();
        if (juzNum == null || juzNum < 1 || juzNum > 30) continue;
        final mapping = item['verse_mapping'];
        if (mapping is! Map) continue;
        final set = byJuz.putIfAbsent(juzNum, () => <int>{});
        for (final k in mapping.keys) {
          final s = int.tryParse('$k');
          if (s != null && s > 0) set.add(s);
        }
      }
    } catch (_) {
      // Fall through — fill from surah.juz below.
    }
    // Merge surah.juz + static map so mid-juz surahs (e.g. 4 in juz 5) always show.
    for (final p in fromData) {
      if (p.juz == null || p.number == null) continue;
      byJuz.putIfAbsent(p.juz!, () => <int>{}).add(p.number!);
    }
    for (final e in kJuzSurahNumbers.entries) {
      byJuz.putIfAbsent(e.key, () => <int>{}).addAll(e.value);
    }
    _juzCached = [
      for (var i = 1; i <= 30; i++)
        JuzInfo(
          juz: i,
          surahNumbers: (byJuz[i]?.toList() ?? <int>[])..sort(),
        ),
    ];

    _cached = [..._extras, ...fromData];
  } finally {
    _loading = false;
  }
}

/// Prefer [ensureQuranDataLoaded] first; returns empty until loaded.
List<QuranPassage> loadQuranPassages() =>
    List.unmodifiable(_cached ?? const []);

List<JuzInfo> loadJuzInfos() => List.unmodifiable(_juzCached ?? const []);

Future<List<QuranPassage>> loadQuranPassagesAsync() async {
  await ensureQuranDataLoaded();
  return loadQuranPassages();
}

List<Zekr> zekrsFromPassages(List<QuranPassage> passages, {DateTime? now}) {
  final at = now ?? DateTime.now();
  return [
    for (final p in passages)
      Zekr(
        id: p.id,
        text: p.title,
        note: p.ref,
        targetCount: p.ayahs.length,
        incrementPerTap: 1,
        repeatType: RepeatType.daily,
        intervalDays: 1,
        reminderHour: 8,
        reminderMinute: 0,
        reminderEnabled: false,
        periodStart: at,
        createdAt: at,
        parts: p.parts,
        partCounts: List<int>.filled(p.ayahs.length, 0),
        allowAnytime: true,
      ),
  ];
}
