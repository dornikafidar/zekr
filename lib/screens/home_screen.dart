import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../l10n/fa.dart';
import '../models/zekr.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import 'add_edit_zekr_screen.dart';
import 'counter_screen.dart';
import 'overall_stats_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';
import 'situations_screen.dart';
import 'stats_screen.dart';
import 'direction_compass_screen.dart';
import 'ziarat_places_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ZekrProvider>().refreshIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ZekrProvider>();
    final items = provider.homeItems;
    final done =
        items.where((z) => z.isDailyGoalDone || z.isCompleted).length;
    final open = items.length - done;
    final progress = items.isEmpty ? 0.0 : done / items.length;

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      // endFloat = bottom-left in RTL (thumb-friendly).
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.deepNight,
          elevation: 2,
          highlightElevation: 4,
          onPressed: () {
            HapticFeedback.selectionClick();
            _openEditor(context);
          },
          icon: const Icon(Icons.add_rounded, size: 26),
          label: Text(
            Fa.newZekr,
            style: AppTheme.latin(
              weight: FontWeight.w800,
              color: AppColors.deepNight,
              fontSize: 15,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              delay: 200.ms,
              curve: Curves.easeOutBack,
            ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E342A),
              AppColors.deepNight,
              AppColors.abyss,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Soft gold atmosphere (no blur — GPU-safe).
            Positioned(
              top: -80,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.14),
                        AppColors.gold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: -60,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.mint.withValues(alpha: 0.08),
                        AppColors.mint.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: provider.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _Header(
                            onSettings: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                            onStats: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OverallStatsScreen(),
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                _HeroNavCard(
                                  icon: Icons.menu_book_rounded,
                                  title: Fa.quran,
                                  subtitle: Fa.quranHint,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const QuranScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MiniNavCard(
                                        icon: Icons.mosque_rounded,
                                        title: Fa.ziaratPlacesShort,
                                        subtitle: Fa.ziaratPlacesHint,
                                        accent: AppColors.gold,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ZiaratPlacesScreen(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _MiniNavCard(
                                        icon: Icons.spa_rounded,
                                        title: Fa.situationsShort,
                                        subtitle: Fa.situationsHintShort,
                                        accent: AppColors.mint,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SituationsScreen(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _HeroNavCard(
                                  icon: Icons.explore_rounded,
                                  title: Fa.directionCompassShort,
                                  subtitle: Fa.directionHint,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const DirectionCompassScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                .animate()
                                .fadeIn(duration: 380.ms)
                                .slideY(begin: 0.05, end: 0),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                          sliver: SliverToBoxAdapter(
                            child: _TodayCard(
                              done: done,
                              open: open,
                              total: items.length,
                              progress: progress,
                            )
                                .animate()
                                .fadeIn(delay: 80.ms, duration: 380.ms)
                                .slideY(begin: 0.04, end: 0, delay: 80.ms),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  Fa.myZekrs,
                                  style: AppTheme.latin(
                                    fontSize: 16,
                                    weight: FontWeight.w800,
                                    color: AppColors.cream,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.gold
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    '${items.length}',
                                    style: AppTheme.latin(
                                      fontSize: 13,
                                      weight: FontWeight.w800,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (items.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _Empty(onAdd: () => _openEditor(context)),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                            sliver: SliverList.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final z = items[i];
                                return _ZekrCard(
                                  zekr: z,
                                  index: i,
                                  onTap: () => _openCounter(context, z.id),
                                  onEdit: () =>
                                      _openEditor(context, existing: z),
                                  onDelete: () => _confirmDelete(context, z),
                                  onStats: () => _openStats(context, z.id),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCounter(BuildContext context, String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CounterScreen(zekrId: id)),
    );
    if (context.mounted) context.read<ZekrProvider>().refreshIfNeeded();
  }

  Future<void> _openEditor(BuildContext context, {Zekr? existing}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditZekrScreen(existing: existing)),
    );
  }

  Future<void> _openStats(BuildContext context, String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatsScreen(zekrId: id)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Zekr zekr) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forest,
        title: Text(
          Fa.deleteQ,
          style: AppTheme.latin(weight: FontWeight.w700),
        ),
        content: Text(
          Fa.deleteConfirm,
          style: AppTheme.latin(color: AppColors.mist),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(Fa.cancel, style: AppTheme.latin(color: AppColors.mist)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              Fa.delete,
              style: AppTheme.latin(
                color: AppColors.danger,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ZekrProvider>().delete(zekr.id);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings, required this.onStats});

  final VoidCallback onSettings;
  final VoidCallback onStats;

  @override
  Widget build(BuildContext context) {
    // RTL: brand at start (right), actions at end (left).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ذکر',
                  style: AppTheme.arabic(
                    fontSize: 36,
                    color: AppColors.gold,
                  ),
                ),
                Text(
                  Fa.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.latin(
                    fontSize: 12.5,
                    color: AppColors.mist,
                    weight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RoundIcon(
            icon: Icons.insights_rounded,
            onTap: onStats,
            color: AppColors.gold,
          ),
          const SizedBox(width: 8),
          _RoundIcon(icon: Icons.settings_outlined, onTap: onSettings),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: -0.06, end: 0);
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.onTap,
    this.color = AppColors.mist,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardElevated.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.cardBorder.withValues(alpha: 0.7),
            ),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}

class _HeroNavCard extends StatelessWidget {
  const _HeroNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.gold.withValues(alpha: 0.22),
                AppColors.cardElevated,
                const Color(0xFF0F2C25),
              ],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Row(
              children: [
                // Start (right in RTL): icon + titles
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: AppColors.gold.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(icon, color: AppColors.gold, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.latin(
                          fontSize: 16.5,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.latin(
                          fontSize: 12,
                          color: AppColors.mist,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                // Trailing (left in RTL): enter deeper — keep « (IconData would flip).
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.gold.withValues(alpha: 0.85),
                  size: 15,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniNavCard extends StatelessWidget {
  const _MiniNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 118,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: accent.withValues(alpha: 0.16),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: AppTheme.latin(
                  fontSize: 14.5,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: AppTheme.latin(
                  fontSize: 11,
                  color: AppColors.mist,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.done,
    required this.open,
    required this.total,
    required this.progress,
  });

  final int done;
  final int open;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    final complete = total > 0 && open == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: complete
              ? AppColors.gold.withValues(alpha: 0.5)
              : AppColors.cardBorder,
        ),
      ),
      // RTL: copy first (right), ring last (left).
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  Fa.todayProgress,
                  textAlign: TextAlign.start,
                  style: AppTheme.latin(
                    fontSize: 13,
                    weight: FontWeight.w700,
                    color: AppColors.mist,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0 ? '۰' : '$done ${Fa.of} $total',
                  textAlign: TextAlign.start,
                  style: AppTheme.latin(
                    fontSize: 22,
                    weight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : p,
                    minHeight: 9,
                    backgroundColor: const Color(0xFF1A3F35),
                    color: complete ? AppColors.gold : AppColors.softLeaf,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  complete
                      ? Fa.goalReached
                      : '${Fa.open}: $open  ·  ${Fa.done}: $done',
                  textAlign: TextAlign.start,
                  style: AppTheme.latin(
                    fontSize: 12,
                    color: AppColors.mist,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : p,
                    strokeWidth: 6,
                    backgroundColor:
                        AppColors.cardBorder.withValues(alpha: 0.9),
                    color: complete ? AppColors.gold : AppColors.mint,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  total == 0 ? '—' : '${(p * 100).round()}٪',
                  style: AppTheme.latin(
                    fontSize: 13,
                    weight: FontWeight.w800,
                    color: AppColors.cream,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'بِسْمِ ٱللَّهِ',
                style: AppTheme.arabic(fontSize: 38, color: AppColors.gold),
              ),
              const SizedBox(height: 14),
              Text(
                Fa.noZekrYet,
                style: AppTheme.latin(fontSize: 19, weight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                Fa.noZekrHint,
                textAlign: TextAlign.center,
                style: AppTheme.latin(
                  fontSize: 13.5,
                  color: AppColors.mist,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text(Fa.createFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZekrCard extends StatelessWidget {
  const _ZekrCard({
    required this.zekr,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStats,
  });

  final Zekr zekr;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStats;

  @override
  Widget build(BuildContext context) {
    final done = zekr.isCompleted || zekr.isDailyGoalDone;
    final waiting = zekr.isWaitingForNextPeriod;
    final accent = done || waiting;
    final p = zekr.progress.clamp(0.0, 1.0);

    return Material(
      color: AppColors.cardElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent
                  ? AppColors.gold.withValues(alpha: 0.6)
                  : AppColors.cardBorder,
              width: accent ? 1.3 : 1,
            ),
            gradient: accent
                ? LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      AppColors.gold.withValues(alpha: 0.1),
                      AppColors.cardElevated,
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Start (right): progress
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: p,
                          strokeWidth: 5,
                          backgroundColor: const Color(0xFF1A3F35),
                          color: done ? AppColors.gold : AppColors.mint,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '${(p * 100).round()}٪',
                        style: AppTheme.latin(
                          fontSize: 11.5,
                          weight: FontWeight.w800,
                          color: AppColors.cream,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        zekr.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: AppTheme.arabic(
                          fontSize: 19,
                          height: 1.45,
                          color: AppColors.cream,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Chip(
                            label: waiting
                                ? Fa.finished
                                : done
                                    ? Fa.goalReached
                                    : zekr.repeatLabel,
                            color: waiting || done
                                ? AppColors.gold
                                : AppColors.mist,
                          ),
                          if (!waiting)
                            _Chip(
                              label: '${zekr.totalCount}/${zekr.totalTarget}',
                              color: AppColors.softLeaf,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.mist,
                  ),
                  color: AppColors.forest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (v) {
                    if (v == 'stats') onStats();
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'stats',
                      child: Text(Fa.history, style: AppTheme.latin()),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(Fa.edit, style: AppTheme.latin()),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        Fa.delete,
                        style: AppTheme.latin(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (50 * index).ms, duration: 340.ms)
        .slideY(begin: 0.05, end: 0, delay: (50 * index).ms);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTheme.latin(
          fontSize: 11.5,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
