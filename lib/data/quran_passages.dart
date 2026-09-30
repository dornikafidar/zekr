import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/zekr.dart';

class QuranPassage {
  const QuranPassage({
    required this.id,
    required this.title,
    required this.ref,
    required this.ayahs,
  });

  final String id;
  final String title;
  final String ref;
  final List<String> ayahs;

  String get text => ayahs.join('\n');

  List<ZekrPart> get parts => [
        for (final a in ayahs) ZekrPart(text: a, targetCount: 1),
      ];
}

/// Popular Persian titles for included surahs.
const _faTitles = <int, String>{
  1: 'فاتحه',
  32: 'سجده',
  36: 'یس',
  55: 'الرحمن',
  56: 'واقعه',
  67: 'ملک',
  78: 'نبأ',
  79: 'نازعات',
  80: 'عبس',
  81: 'تکویر',
  82: 'انفطار',
  83: 'مطففین',
  84: 'انشقاق',
  85: 'بروج',
  86: 'طارق',
  87: 'أعلی',
  88: 'غاشیه',
  89: 'فجر',
  90: 'بلد',
  91: 'شمس',
  92: 'لیل',
  93: 'ضحی',
  94: 'شرح',
  95: 'تین',
  96: 'علق',
  97: 'قدر',
  98: 'بینه',
  99: 'زلزله',
  100: 'عادیات',
  101: 'قارعه',
  102: 'تکاثر',
  103: 'عصر',
  104: 'همزه',
  105: 'فیل',
  106: 'قریش',
  107: 'ماعون',
  108: 'کوثر',
  109: 'کافرون',
  110: 'نصر',
  111: 'مسد',
  112: 'إخلاص',
  113: 'فلق',
  114: 'ناس',
};

/// Extra short passages (not full surahs).
const _extras = <QuranPassage>[
  QuranPassage(
    id: 'quran_kursi',
    title: 'آیة‌الکرسی',
    ref: 'بقره ۲:۲۵۵',
    ayahs: [
      'ٱللَّهُ لَا إِلَٰهَ إِلَّا هُوَ ٱلْحَيُّ ٱلْقَيُّومُ ۚ '
          'لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
          'لَّهُ مَا فِي ٱلسَّمَٰوَٰتِ وَمَا فِي ٱلْأَرْضِ ۗ '
          'مَن ذَا ٱلَّذِي يَشْفَعُ عِندَهُۥ إِلَّا بِإِذْنِهِۦ ۚ '
          'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ '
          'وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِۦ إِلَّا بِمَا شَآءَ ۚ '
          'وَسِعَ كُرْسِيُّهُ ٱلسَّمَٰوَٰتِ وَٱلْأَرْضَ ۖ '
          'وَلَا يَـُٔودُهُۥ حِفْظُهُمَا ۚ '
          'وَهُوَ ٱلْعَلِيُّ ٱلْعَظِيمُ',
    ],
  ),
  QuranPassage(
    id: 'quran_inyakad',
    title: 'و إن یکاد',
    ref: 'قلم ۶۸:۵۱–۵۲',
    ayahs: [
      'وَإِن يَكَادُ ٱلَّذِينَ كَفَرُوا۟ لَيُزْلِقُونَكَ بِأَبْصَٰرِهِمْ '
          'لَمَّا سَمِعُوا۟ ٱلذِّكْرَ وَيَقُولُونَ إِنَّهُۥ لَمَجْنُونٌ',
      'وَمَا هُوَ إِلَّا ذِكْرٌ لِّلْعَٰلَمِينَ',
    ],
  ),
];

List<QuranPassage>? _cached;

Future<List<QuranPassage>> loadQuranPassages() async {
  if (_cached != null) return _cached!;
  final raw = await rootBundle.loadString('assets/quran/surahs.json');
  final list = jsonDecode(raw) as List<dynamic>;
  final fromFile = <QuranPassage>[
    for (final e in list)
      () {
        final m = e as Map<String, dynamic>;
        final n = m['number'] as int;
        final ayahs = (m['ayahs'] as List).cast<String>();
        final title = _faTitles[n] ?? (m['name_en'] as String);
        return QuranPassage(
          id: m['id'] as String,
          title: 'سوره $title',
          ref: '$title · $n',
          ayahs: ayahs,
        );
      }(),
  ];
  // Extras first (Kursi, Inyakad), then surahs. Prefer file versions of
  // overlapping short surahs over old hardcoded ones.
  _cached = [..._extras, ...fromFile];
  return _cached!;
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
