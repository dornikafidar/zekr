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
      note: 'Nach dem Gebet · Plan täglich · jederzeit möglich',
      parts: tasbihZahraParts,
      allowAnytime: true,
    ),
  ];
}
