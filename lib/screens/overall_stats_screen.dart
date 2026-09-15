import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../models/zekr_day_stat.dart';
import '../models/zekr_stats.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'stats_screen.dart';

class OverallStatsScreen extends StatefulWidget {
  const OverallStatsScreen({super.key});

  @override
  State<OverallStatsScreen> createState() => _OverallStatsScreenState();
}

class _OverallStatsScreenState extends State<OverallStatsScreen> {
  StatsRange _range = StatsRange.week;
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    _anchor = dateOnly(DateTime.now());
  }

  void _shift(int direction) {
    setState(() {
      switch (_range) {
        case StatsRange.week:
          _anchor = _anchor.add(Duration(days: 7 * direction));
        case StatsRange.month:
          _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
        case StatsRange.year:
          _anchor = DateTime(_anchor.year + direction, 1, 1);
        case StatsRange.all:
          break;
      }
    });
  }

  String _periodTitle() {
    switch (_range) {
      case StatsRange.week:
        final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final fmt = DateFormat('d.M.');
        return '${fmt.format(monday)} – ${fmt.format(sunday)}';
      case StatsRange.month:
        const months = [
          'Januar',
          'Februar',
          'März',
          'April',
          'Mai',
          'Juni',
          'Juli',
          'August',
          'September',
          'Oktober',
          'November',
          'Dezember',
        ];
        return '${months[_anchor.month - 1]} ${_anchor.year}';
      case StatsRange.year:
        return '${_anchor.year}';
      case StatsRange.all:
        return 'Gesamt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ZekrProvider>().items;
    final overall =
        buildOverallStats(items, range: _range, anchor: _anchor);
    final stats = overall.stats;
    final canNavigate = _range != StatsRange.all;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.cream,
                    ),
                    Expanded(
                      child: Text(
                        'Gesamtstatistik',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'Übersicht über alle ${overall.zekrCount} Zekr',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.mist,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RangeChips(
                  value: _range,
                  onChanged: (r) => setState(() {
                    _range = r;
                    _anchor = dateOnly(DateTime.now());
                  }),
                ),
              ),
              const SizedBox(height: 8),
              if (canNavigate)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _shift(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                        color: AppColors.mist,
                      ),
                      Expanded(
                        child: Text(
                          _periodTitle(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: AppColors.cream,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shift(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                        color: AppColors.mist,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.55,
                      children: [
                        _StatCard(
                          title: 'Wiederholungen',
                          value: '${stats.totalCount}',
                          hint: 'im Zeitraum',
                        ),
                        _StatCard(
                          title: 'Ziele',
                          value: '${stats.completedGoals}',
                          hint: 'Tage geschafft',
                        ),
                        _StatCard(
                          title: 'Serie',
                          value: '${stats.currentStreak}',
                          hint: 'Tage am Stück',
                        ),
                        _StatCard(
                          title: 'Lifetime',
                          value: '${overall.lifetimeTotal}',
                          hint: '${overall.lifetimeGoals}× Ziel erreicht',
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 20),
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Übersicht',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: _BarChart(buckets: stats.buckets),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 20),
                    _label('PRO ZEKR'),
                    if (overall.perZekr.every((e) => e.count == 0))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Noch kein Verlauf in diesem Zeitraum.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: AppColors.mist),
                        ),
                      )
                    else
                      ...overall.perZekr.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StatsScreen(zekrId: row.id),
                                ),
                              );
                            },
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    row.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    style: AppTheme.arabic(
                                      fontSize: 18,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${row.count}×',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (row.completedGoals > 0)
                                      Text(
                                        '${row.completedGoals} Ziele',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppColors.mint,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.mist,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: AppColors.mist,
        ),
      ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.value, required this.onChanged});

  final StatsRange value;
  final ValueChanged<StatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (StatsRange.week, 'Woche'),
      (StatsRange.month, 'Monat'),
      (StatsRange.year, 'Jahr'),
      (StatsRange.all, 'Gesamt'),
    ];
    return Row(
      children: [
        for (final item in items) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: value == item.$1
                      ? AppColors.gold.withValues(alpha: 0.2)
                      : AppColors.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: value == item.$1
                        ? AppColors.gold
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight:
                        value == item.$1 ? FontWeight.w700 : FontWeight.w500,
                    color: value == item.$1 ? AppColors.gold : AppColors.mist,
                  ),
                ),
              ),
            ),
          ),
          if (item != items.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.hint,
  });

  final String title;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              letterSpacing: 1.1,
              color: AppColors.mist,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
          Text(
            hint,
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.mist),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.buckets});

  final List<StatsBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxVal = buckets.fold<int>(0, (m, b) => math.max(m, b.count));
    final showEvery =
        buckets.length > 14 ? (buckets.length / 7).ceil() : 1;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < buckets.length; i++) ...[
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Tooltip(
                      message: '${buckets[i].count}×',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        height: buckets[i].count <= 0
                            ? 4.0
                            : ((buckets[i].count / (maxVal == 0 ? 1 : maxVal)) *
                                    140.0)
                                .clamp(4, 140),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: buckets[i].completedGoals > 0
                                ? const [AppColors.softLeaf, AppColors.gold]
                                : [
                                    AppColors.emerald,
                                    AppColors.mint.withValues(alpha: 0.85),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (i != buckets.length - 1) const SizedBox(width: 2),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < buckets.length; i++)
              Expanded(
                child: Text(
                  i % showEvery == 0 ? buckets[i].shortLabel : '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppColors.mist,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
