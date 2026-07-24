import 'package:uuid/uuid.dart';

import '../models/zekr.dart';

/// Combined default Zekr text (one entry, three lines).
const defaultZekrText =
    'صِرَاطُ عَلِيٍّ مُسْتَقِيمٌ\n'
    'صِرَاطُ مَالِكِ يَوْمِ الدِّينِ\n'
    'اللَّهُمَّ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ';

/// Older mistaken single-line defaults (to remove on migration).
const legacyDefaultZekrTexts = [
  'صِرَاطُ عَلِيٍّ مُسْتَقِيمٌ',
  'صِرَاطُ مَالِكِ يَوْمِ الدِّينِ',
  'اللَّهُمَّ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
];

/// Built-in Zekr shown on first launch / after migration.
List<Zekr> createDefaultZekrs({DateTime? now, Uuid? uuid}) {
  final at = now ?? DateTime.now();
  final id = uuid ?? const Uuid();

  return [
    Zekr(
      id: id.v4(),
      text: defaultZekrText,
      targetCount: 110,
      incrementPerTap: 1,
      repeatType: RepeatType.daily,
      intervalDays: 1,
      reminderHour: 8,
      reminderMinute: 0,
      reminderEnabled: true,
      periodStart: at,
      createdAt: at,
    ),
  ];
}
