import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../l10n/fa.dart';
import '../models/zekr.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
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
    final doneToday =
        items.where((z) => z.isDailyGoalDone || z.isCompleted).length;
    final open = items.length - doneToday;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: provider.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _Header()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ShortcutCard(
                                icon: Icons.menu_book_rounded,
                                title: Fa.quran,
                                subtitle: Fa.quranHint,
                                color: AppColors.gold,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const QuranScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ShortcutCard(
                                icon: Icons.spa_rounded,
                                title: Fa.situationsShort,
                                subtitle: Fa.situationsHintShort,
                                color: AppColors.mint,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SituationsScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 80.ms).slideY(
                              begin: 0.05,
                              end: 0,
                            ),
                      ),
                    ),
                    if (items.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: _TodayBar(
                            done: doneToday,
                            open: open,
                            total: items.length,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
                        child: Text(
                          Fa.myZekrs,
                          style: AppTheme.latin(
                            fontSize: 13,
                            weight: FontWeight.w700,
                            color: AppColors.mist,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(onAdd: () => _openEditor(context)),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                          child: Column(
                            children: [
                              for (var index = 0; index < items.length; index++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == items.length - 1 ? 0 : 10,
                                  ),
                                  child: _ZekrTile(
                                    zekr: items[index],
                                    index: index,
                                    onTap: () =>
                                        _openCounter(context, items[index].id),
                                    onEdit: () => _openEditor(
                                      context,
                                      existing: items[index],
                                    ),
                                    onDelete: () => _confirmDelete(
                                      context,
                                      items[index],
                                    ),
                                    onStats: () =>
                                        _openStats(context, items[index].id),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => CounterScreen(zekrId: id),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
    if (context.mounted) {
      context.read<ZekrProvider>().refreshIfNeeded();
    }
  }

  Future<void> _openEditor(BuildContext context, {Zekr? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditZekrScreen(existing: existing),
      ),
    );
  }

  Future<void> _openStats(BuildContext context, String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StatsScreen(zekrId: id)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Zekr zekr) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Fa.deleteQ, style: AppTheme.latin(weight: FontWeight.w700)),
        content: Text(
          Fa.deleteConfirm,
          style: AppTheme.latin(color: AppColors.mist, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text(Fa.cancel, style: AppTheme.latin(color: AppColors.mist)),
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 20, 4),
      child: Row(
        children: [
          IconCircleButton(
            tooltip: Fa.settings,
            icon: Icons.settings_rounded,
            color: AppColors.mist,
            filled: true,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconCircleButton(
            tooltip: Fa.overallStats,
            icon: Icons.insights_rounded,
            color: AppColors.gold,
            filled: true,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OverallStatsScreen()),
              );
            },
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: [
                  Text('Zekr', style: brandTitle(size: 28)),
                  const SizedBox(width: 10),
                  Text(
                    'ذکر',
                    style: AppTheme.arabic(fontSize: 28, color: AppColors.gold),
                  ),
                ],
              ),
              const SizedBox(height: 2),
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
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      accent: true,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.latin(fontSize: 14, weight: FontWeight.w700),
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
    );
  }
}

class _TodayBar extends StatelessWidget {
  const _TodayBar({
    required this.done,
    required this.open,
    required this.total,
  });

  final int done;
  final int open;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = total == 0 ? 0.0 : done / total;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                  fontSize: 14,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: p.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.cardBorder.withValues(alpha: 0.45),
              color: AppColors.softLeaf,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            open == 0 ? Fa.goalReached : '${Fa.open}: $open',
            style: AppTheme.latin(fontSize: 11, color: AppColors.mist),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 120.ms);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          accent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'بِسْمِ ٱللَّهِ',
                style: AppTheme.arabic(fontSize: 40, color: AppColors.gold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                Fa.noZekrYet,
                style: AppTheme.latin(fontSize: 20, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                Fa.noZekrHint,
                textAlign: TextAlign.center,
                style: AppTheme.latin(
                  fontSize: 13,
                  color: AppColors.mist,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text(Fa.createFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZekrTile extends StatelessWidget {
  const _ZekrTile({
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
    final waiting = zekr.isWaitingForNextPeriod;
    final done = zekr.isCompleted || zekr.isDailyGoalDone;
    final statusColor = waiting || done
        ? (waiting ? AppColors.gold : AppColors.mint)
        : AppColors.mist;
    final statusLabel = waiting
        ? Fa.finished
        : done
            ? Fa.goalReached
            : zekr.repeatLabel;

    return GlassCard(
      onTap: onTap,
      accent: done || waiting,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          ProgressRing(
            progress: zekr.progress,
            size: 58,
            stroke: 5,
            glow: done,
            child: Text(
              '${(zekr.progress * 100).round()}٪',
              style: AppTheme.latin(
                fontSize: 10,
                weight: FontWeight.w700,
                color: done ? AppColors.gold : AppColors.mint,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  zekr.text,
                  style: AppTheme.arabic(fontSize: 18, height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    StatusPill(label: statusLabel, color: statusColor),
                    if (!waiting)
                      StatusPill(
                        label: '${zekr.totalCount}/${zekr.totalTarget}',
                        color: AppColors.softLeaf,
                      ),
                  ],
                ),
                if (waiting) ...[
                  const SizedBox(height: 6),
                  Text(
                    Fa.againAt(formatNextPeriodLabel(zekr.nextPeriodStart)),
                    textAlign: TextAlign.right,
                    style: AppTheme.latin(
                      fontSize: 11,
                      color: AppColors.gold.withValues(alpha: 0.9),
                    ),
                  ),
                ],
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
    );
  }
}
