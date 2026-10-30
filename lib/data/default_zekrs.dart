import 'package:uuid/uuid.dart';

import '../models/zekr.dart';

/// Combined default Zekr text (one entry, three lines).
const defaultZekrText =
    'صِرَاطُ عَلِيٍّ مُسْتَقِيمٌ\n'
    'صِرَاطُ مَالِكِ يَوْمِ الدِّينِ\n'
    'اللَّهُمَّ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ';

/// Shown when creating a new Zekr (pre-filled + quick chip).
const exampleZekrText = 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَآلِ مُحَمَّدٍ';

/// One Salam Zekr (two lines).
const defaultSalamText =
    'السَّلَامُ عَلَيْكَ يَا أَبَا عَبْدِ ٱللَّهِ\n'
    'السَّلَامُ عَلَيْكَ وَرَحْمَةُ ٱللَّهِ وَبَرَكَاتُهُ';

/// Tasbihat of Fatimah Zahra (title).
const defaultTasbihZahraTitle = 'تَسْبِيحَاتُ الزَّهْرَاء';

/// Quick-pick core example when creating a Zekr (chip label + fill-ins).
class ZekrExample {
  const ZekrExample({
    required this.labelFa,
    required this.text,
    this.note,
    this.targetCount = 100,
  });

  final String labelFa;
  final String text;
  final String? note;
  final int targetCount;
}

/// Shia presets for «ذکر جدید», each backed by a narration (source in note).
/// Counts follow the narration; where none is narrated, the note says so.
const kZekrExamples = <ZekrExample>[
  ZekrExample(
    labelFa: 'تسبیحات حضرت زهرا',
    text: defaultTasbihZahraTitle,
    note: 'بعد از هر نماز، سپس یک بار لا إله إلا الله · '
        'امام صادق: محبوب‌تر از هزار رکعت نماز (وسائل الشیعه)',
    targetCount: 100,
  ),
  ZekrExample(
    labelFa: 'صلوات با عجّل فرجهم',
    text: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَآلِ مُحَمَّدٍ وَعَجِّلْ فَرَجَهُمْ',
    note: 'جمعه بعد از عصر ۱۰۰ بار · امام صادق؛ '
        'بعد از نماز صبح و ظهر: قائم را درک می‌کند',
    targetCount: 100,
  ),
  ZekrExample(
    labelFa: 'صلوات',
    text: exampleZekrText,
    note: 'هر زمان',
    targetCount: 100,
  ),
  ZekrExample(
    labelFa: 'سلام بر امام حسین',
    text: defaultSalamText,
    note: 'سلام از دور به سیدالشهدا · روزانه',
    targetCount: 3,
  ),
  ZekrExample(
    labelFa: 'هنگام نوشیدن آب',
    text: 'سَلَامُ ٱللَّهِ عَلَى ٱلْحُسَيْنِ وَلَعْنَةُ ٱللَّهِ عَلَىٰ قَاتِلِيهِ',
    note: 'یاد عطش امام حسین · امام صادق (کامل الزیارات، مفتاح الفلاح)',
    targetCount: 1,
  ),
  ZekrExample(
    labelFa: 'دعای فرج',
    text: 'ٱللَّهُمَّ عَجِّلْ لِوَلِيِّكَ ٱلْفَرَج',
    note: 'امام زمان: برای تعجیل فرج بسیار دعا کنید (کمال الدین)',
    targetCount: 100,
  ),
  ZekrExample(
    labelFa: 'دعای غریق',
    text: 'يَا اللَّهُ يَا رَحْمَٰنُ يَا رَحِيمُ يَا مُقَلِّبَ ٱلْقُلُوبِ '
        'ثَبِّتْ قَلْبِي عَلَىٰ دِينِكَ',
    note: 'برای زمان غیبت · امام صادق (کمال الدین) · '
        'دقیقاً همین متن، بدون «والابصار» · تعداد خاصی وارد نشده',
    targetCount: 1,
  ),
  ZekrExample(
    labelFa: 'ذکر یونسیه',
    text: 'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ ٱلظَّالِمِينَ',
    note: 'برای غم و اندوه · انبیاء ۸۷ · امام صادق (خصال) · '
        '۴۰۰ بار در سجده: توصیهٔ آخوند ملاحسینقلی همدانی',
    targetCount: 400,
  ),
  ZekrExample(
    labelFa: 'استغفار بعد از عصر',
    text: 'أَسْتَغْفِرُ ٱللَّهَ وَأَتُوبُ إِلَيْهِ',
    note: '۷۰ بار بعد از نماز عصر · امام صادق: '
        'آمرزش هفتصد گناه (امالی صدوق)',
    targetCount: 70,
  ),
  ZekrExample(
    labelFa: 'حوقله صبح و مغرب',
    text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ لَا حَوْلَ وَلَا قُوَّةَ '
        'إِلَّا بِٱللَّهِ ٱلْعَلِيِّ ٱلْعَظِيمِ',
    note: '۷ بار بعد از نماز صبح و مغرب · امام صادق: '
        'دفع هفتاد نوع بلا (کافی)',
    targetCount: 7,
  ),
];

const tasbihZahraParts = [
  ZekrPart(text: 'ٱللَّهُ أَكْبَرُ', targetCount: 34),
  ZekrPart(text: 'ٱلْحَمْدُ لِلَّهِ', targetCount: 33),
  ZekrPart(text: 'سُبْحَانَ ٱللَّهِ', targetCount: 33),
];

/// Older mistaken single-line defaults (to remove on migration).
const legacyDefaultZekrTexts = [
  'صِرَاطُ عَلِيٍّ مُسْتَقِيمٌ',
  'صِرَاطُ مَالِكِ يَوْمِ الدِّينِ',
  'اللَّهُمَّ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
  'السَّلَامُ عَلَيْكَ يَا أَبَا عَبْدِ ٱللَّهِ',
  'السَّلَامُ عَلَيْكَ وَرَحْمَةُ ٱللَّهِ وَبَرَكَاتُهُ',
];

Zekr _dailyDefault({
  required String id,
  required String text,
  required DateTime at,
  int targetCount = 110,
  String? note,
  List<ZekrPart> parts = const [],
  bool allowAnytime = false,
  bool reminderEnabled = true,
}) {
  final total = parts.isEmpty
      ? targetCount
      : parts.fold<int>(0, (s, p) => s + p.targetCount);
  return Zekr(
    id: id,
    text: text,
    note: note,
    targetCount: total,
    incrementPerTap: 1,
    repeatType: RepeatType.daily,
    intervalDays: 1,
    reminderHour: 8,
    reminderMinute: 0,
    reminderEnabled: reminderEnabled,
    periodStart: at,
    createdAt: at,
    parts: parts,
    partCounts: parts.isEmpty ? const [] : List<int>.filled(parts.length, 0),
    allowAnytime: allowAnytime,
  );
}

/// Built-in Zekr shown on first launch / after migration.
List<Zekr> createDefaultZekrs({DateTime? now, Uuid? uuid}) {
  final at = now ?? DateTime.now();
  final id = uuid ?? const Uuid();

  return [
    _dailyDefault(id: id.v4(), text: defaultZekrText, at: at),
    _dailyDefault(
      id: id.v4(),
      text: defaultSalamText,
      at: at,
      targetCount: 3,
    ),
    _dailyDefault(
      id: id.v4(),
      text: defaultTasbihZahraTitle,
      at: at,
      note: 'بعد از نماز · برنامه روزانه · هر زمان ممکن',
      parts: tasbihZahraParts,
      allowAnytime: true,
    ),
  ];
}
