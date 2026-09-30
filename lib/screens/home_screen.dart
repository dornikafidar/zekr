import 'package:flutter/material.dart';
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0C2A22),
              AppColors.deepNight,
              AppColors.abyss,
            ],
          ),
        ),
        child: SafeArea(
          child: provider.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FeatureCard(
                              icon: Icons.menu_book_rounded,
                              title: Fa.quran,
                              subtitle: Fa.quranHint,
                              accent: AppColors.gold,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const QuranScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FeatureCard(
                              icon: Icons.spa_rounded,
                              title: Fa.situationsShort,
                              subtitle: Fa.situationsHintShort,
                              accent: AppColors.mint,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SituationsScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 350.ms).slideY(
                            begin: 0.04,
                            end: 0,
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                      child: _TodayCard(
                        done: done,
                        open: open,
                        total: items.length,
                        progress: progress,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                      child: Row(
                        children: [
                          Text(
                            Fa.myZekrs,
                            style: AppTheme.latin(
                              fontSize: 14,
                              weight: FontWeight.w700,
                              color: AppColors.mist,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${items.length}',
                            style: AppTheme.latin(
                              fontSize: 13,
                              weight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? _Empty(
                              onAdd: () => _openEditor(context),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(18, 0, 18, 100),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final z = items[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 11),
                                  child: _ZekrCard(
                                    zekr: z,
                                    index: i,
                                    onTap: () => _openCounter(context, z.id),
                                    onEdit: () =>
                                        _openEditor(context, existing: z),
                                    onDelete: () =>
                                        _confirmDelete(context, z),
                                    onStats: () => _openStats(context, z.id),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.deepNight,
        elevation: 0,
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          Fa.newZekr,
          style: AppTheme.latin(
            weight: FontWeight.w700,
            color: AppColors.deepNight,
          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 18, 4),
      child: Row(
        children: [
          _RoundIcon(icon: Icons.settings_rounded, onTap: onSettings),
          _RoundIcon(
            icon: Icons.insights_rounded,
            onTap: onStats,
            color: AppColors.gold,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.ltr,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Zekr',
                    style: AppTheme.latin(
                      fontSize: 26,
                      weight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ذکر',
                    style: AppTheme.arabic(
                      fontSize: 28,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              Text(
                Fa.tagline,
                style: AppTheme.latin(
                  fontSize: 12,
                  color: AppColors.mist,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      color: AppColors.cardElevated,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.16),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.latin(
                  fontSize: 14,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.latin(
                  fontSize: 11,
                  color: AppColors.mist,
                  height: 1.35,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                Fa.todayProgress,
                style: AppTheme.latin(
                  fontSize: 13,
                  weight: FontWeight.w600,
                  color: AppColors.mist,
                ),
              ),
              const Spacer(),
              Text(
                '$done / $total',
                style: AppTheme.latin(
                  fontSize: 16,
                  weight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.cardBorder,
              color: AppColors.softLeaf,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            open == 0 && total > 0
                ? Fa.goalReached
                : '${Fa.open}: $open  ·  ${Fa.done}: $done',
            style: AppTheme.latin(fontSize: 12, color: AppColors.mist),
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
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'بِسْمِ ٱللَّهِ',
                style: AppTheme.arabic(fontSize: 36, color: AppColors.gold),
              ),
              const SizedBox(height: 12),
              Text(
                Fa.noZekrYet,
                style: AppTheme.latin(fontSize: 18, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                Fa.noZekrHint,
                textAlign: TextAlign.center,
                style: AppTheme.latin(
                  fontSize: 13,
                  color: AppColors.mist,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
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

    return Material(
      color: AppColors.cardElevated,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent
                  ? AppColors.gold.withValues(alpha: 0.55)
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: zekr.progress.clamp(0.0, 1.0),
                      strokeWidth: 4.5,
                      backgroundColor: AppColors.cardBorder,
                      color: done ? AppColors.gold : AppColors.mint,
                    ),
                    Text(
                      '${(zekr.progress * 100).round()}٪',
                      style: AppTheme.latin(
                        fontSize: 11,
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
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppTheme.arabic(
                        fontSize: 18,
                        height: 1.4,
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
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
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.mist),
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
    )
        .animate()
        .fadeIn(delay: (40 * index).ms, duration: 320.ms)
        .slideY(begin: 0.04, end: 0, delay: (40 * index).ms);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTheme.latin(
          fontSize: 11,
          weight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
