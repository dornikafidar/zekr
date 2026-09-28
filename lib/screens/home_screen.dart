import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/zekr.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_edit_zekr_screen.dart';
import 'counter_screen.dart';
import 'overall_stats_screen.dart';
import 'settings_screen.dart';
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
    final items = provider.items;
    final doneToday =
        items.where((z) => z.isDailyGoalDone || z.isCompleted).length;
    final open = items.length - doneToday;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Zekr', style: brandTitle(size: 32))
                                  .animate()
                                  .fadeIn(duration: 450.ms)
                                  .slideX(begin: -0.04, end: 0),
                              const SizedBox(width: 12),
                              Text(
                                'ذکر',
                                style: AppTheme.arabic(
                                  fontSize: 30,
                                  color: AppColors.gold,
                                ),
                                textDirection: TextDirection.rtl,
                              )
                                  .animate()
                                  .fadeIn(delay: 80.ms, duration: 450.ms),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ruhig zählen. Sanft erinnern.',
                            style: AppTheme.latin(
                              fontSize: 13,
                              color: AppColors.mist,
                              weight: FontWeight.w400,
                            ),
                          ).animate().fadeIn(delay: 140.ms),
                        ],
                      ),
                    ),
                    IconCircleButton(
                      tooltip: 'Gesamtstatistik',
                      icon: Icons.insights_rounded,
                      color: AppColors.gold,
                      filled: true,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OverallStatsScreen(),
                          ),
                        );
                      },
                    ),
                    IconCircleButton(
                      tooltip: 'Einstellungen',
                      icon: Icons.settings_rounded,
                      color: AppColors.mist,
                      filled: true,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (!provider.loading && items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Offen',
                          value: '$open',
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          label: 'Geschafft',
                          value: '$doneToday',
                          color: AppColors.mint,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          label: 'Gesamt',
                          value: '${items.length}',
                          color: AppColors.softLeaf,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.06, end: 0),
                ),
              Expanded(
                child: provider.loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : items.isEmpty
                        ? _EmptyState(onAdd: () => _openEditor(context))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final zekr = items[index];
                              return _ZekrTile(
                                zekr: zekr,
                                index: index,
                                onTap: () => _openCounter(context, zekr.id),
                                onEdit: () =>
                                    _openEditor(context, existing: zekr),
                                onDelete: () => _confirmDelete(context, zekr),
                                onStats: () => _openStats(context, zekr.id),
                              );
                            },
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
          'Neues Zekr',
          style: AppTheme.latin(
              weight: FontWeight.w700, color: AppColors.deepNight),
        ),
      ).animate().fadeIn(delay: 280.ms).scale(begin: const Offset(0.92, 0.92)),
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
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
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
        title: Text('Löschen?', style: AppTheme.latin(weight: FontWeight.w700)),
        content: Text(
          'Dieses Zekr wirklich entfernen?',
          style: AppTheme.latin(color: AppColors.mist, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Abbrechen', style: AppTheme.latin(color: AppColors.mist)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Löschen',
              style: AppTheme.latin(
                  color: AppColors.danger, weight: FontWeight.w700),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.latin(
              fontSize: 10,
              weight: FontWeight.w600,
              color: AppColors.mist,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.latin(
              fontSize: 22,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          accent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'بِسْمِ ٱللَّهِ',
                style: AppTheme.arabic(fontSize: 42, color: AppColors.gold),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 700.ms),
              const SizedBox(height: 18),
              Text(
                'Noch kein Zekr',
                style: AppTheme.latin(
                  fontSize: 22,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lege dein erstes Zekr an — mit Ziel, Rhythmus und Erinnerung.',
                textAlign: TextAlign.center,
                style: AppTheme.latin(
                  fontSize: 14,
                  color: AppColors.mist,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Erstes Zekr anlegen'),
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
        ? 'Fertig'
        : done
            ? 'Ziel erreicht'
            : zekr.repeatLabel;

    return GlassCard(
      onTap: onTap,
      accent: done || waiting,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Row(
        children: [
          ProgressRing(
            progress: zekr.progress,
            size: 68,
            stroke: 5.5,
            glow: done,
            child: Text(
              '${(zekr.progress * 100).round()}%',
              style: AppTheme.latin(
                fontSize: 11,
                weight: FontWeight.w700,
                color: done ? AppColors.gold : AppColors.mint,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  zekr.text,
                  style: AppTheme.arabic(fontSize: 20, height: 1.45),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    StatusPill(label: statusLabel, color: statusColor),
                    if (!waiting)
                      StatusPill(
                        label: '${zekr.totalCount}/${zekr.totalTarget}',
                        color: AppColors.softLeaf,
                      ),
                    if (zekr.hasParts)
                      StatusPill(
                        label: '${zekr.parts.length} Teile',
                        color: AppColors.gold,
                      ),
                  ],
                ),
                if (waiting) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Wieder ab ${formatNextPeriodLabel(zekr.nextPeriodStart)}',
                    textAlign: TextAlign.right,
                    style: AppTheme.latin(
                      fontSize: 12,
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
                child: Text('Verlauf', style: AppTheme.latin()),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Text('Bearbeiten', style: AppTheme.latin()),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Löschen',
                  style: AppTheme.latin(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (70 * index).ms, duration: 420.ms)
        .slideY(begin: 0.07, end: 0, delay: (70 * index).ms);
  }
}
