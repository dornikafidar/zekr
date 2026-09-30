import '../l10n/fa.dart';
import '../models/zekr.dart';

/// Four situational dhikrs from Imam al-Sadiq (a.s.).
class SituationDhikr {
  const SituationDhikr({
    required this.id,
    required this.title,
    required this.hint,
    required this.text,
    required this.icon,
  });

  final String id;
  final String title;
  final String hint;
  final String text;
  final String icon; // material icon name key used in UI
}

const situationFearId = 'sit_fear';
const situationGriefId = 'sit_grief';
const situationPlotId = 'sit_plot';
const situationDunyaId = 'sit_dunya';

const situationDhikrs = [
  SituationDhikr(
    id: situationFearId,
    title: Fa.sitFear,
    hint: Fa.sitFearHint,
    text: 'حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ',
    icon: 'shield',
  ),
  SituationDhikr(
    id: situationGriefId,
    title: Fa.sitGrief,
    hint: Fa.sitGriefHint,
    text: 'لَا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ ٱلظَّالِمِينَ',
    icon: 'heart',
  ),
  SituationDhikr(
    id: situationPlotId,
    title: Fa.sitPlot,
    hint: Fa.sitPlotHint,
    text: 'وَأُفَوِّضُ أَمْرِي إِلَى ٱللَّهِ إِنَّ ٱللَّهَ بَصِيرٌ بِٱلْعِبَادِ',
    icon: 'visibility',
  ),
  SituationDhikr(
    id: situationDunyaId,
    title: Fa.sitDunya,
    hint: Fa.sitDunyaHint,
    text: 'مَا شَاءَ ٱللَّهُ لَا قُوَّةَ إِلَّا بِٱللَّهِ',
    icon: 'spa',
  ),
];

List<Zekr> createSituationZekrs({DateTime? now}) {
  final at = now ?? DateTime.now();
  return [
    for (final s in situationDhikrs)
      Zekr(
        id: s.id,
        text: s.text,
        note: s.title,
        targetCount: 1,
        incrementPerTap: 1,
        repeatType: RepeatType.daily,
        intervalDays: 1,
        reminderHour: 8,
        reminderMinute: 0,
        reminderEnabled: false,
        periodStart: at,
        createdAt: at,
        allowAnytime: true,
      ),
  ];
}
