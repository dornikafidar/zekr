import '../models/zekr.dart';
import 'quran_surahs_data.dart';

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

const _faTitles = <int, String>{
  1: 'فاتحه',
  91: 'شمس',
  93: 'ضحی',
  94: 'شرح',
  95: 'تین',
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

const _extras = <QuranPassage>[
  QuranPassage(
    id: 'quran_kursi',
    title: 'آیة‌الکرسی',
    ref: 'بقره ۲:۲۵۵–۲۵۷',
    ayahs: [
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

/// Sync loader — data is compiled into the app (no asset race).
List<QuranPassage> loadQuranPassages() {
  if (_cached != null) return _cached!;
  final fromData = <QuranPassage>[
    for (final m in quranSurahsRaw)
      if (((m['ayahs']! as List).length) < 16)
        QuranPassage(
          id: m['id']! as String,
          title: 'سوره ${_faTitles[m['number']! as int] ?? m['name_en']}',
          ref:
              '${_faTitles[m['number']! as int] ?? m['name_en']} · ${m['number']}',
          ayahs: (m['ayahs']! as List).cast<String>(),
        ),
  ];
  // Extras also only if short (<16 ayahs).
  _cached = [
    ..._extras.where((p) => p.ayahs.length < 16),
    ...fromData,
  ];
  return _cached!;
}

Future<List<QuranPassage>> loadQuranPassagesAsync() async =>
    loadQuranPassages();

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
