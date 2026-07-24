import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/zekr.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_edit_zekr_screen.dart';
import 'counter_screen.dart';

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ذکر', style: AppTheme.arabic(fontSize: 36, color: AppColors.gold))
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.15, end: 0),
                    const SizedBox(height: 4),
                    Text('Zekr', style: brandTitle(size: 32))
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 600.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Dein stiller Begleiter für Erinnerung und Ziel.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.mist,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
              Expanded(
                child: provider.loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : provider.items.isEmpty
                        ? _EmptyState(
                            onAdd: () => _openEditor(context),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            itemCount: provider.items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final zekr = provider.items[index];
                              return _ZekrTile(
                                zekr: zekr,
                                index: index,
                                onTap: () => _openCounter(context, zekr.id),
                                onEdit: () =>
                                    _openEditor(context, existing: zekr),
                                onDelete: () =>
                                    _confirmDelete(context, zekr),
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
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
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
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
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

  Future<void> _confirmDelete(BuildContext context, Zekr zekr) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.forest,
        title: Text('Löschen?', style: GoogleFonts.outfit()),
        content: Text(
          '„${zekr.text}" wirklich entfernen?',
          style: GoogleFonts.outfit(color: AppColors.mist),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Löschen',
              style: GoogleFonts.outfit(color: Colors.redAccent),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'بِسْمِ ٱللَّهِ',
              style: AppTheme.arabic(fontSize: 40, color: AppColors.gold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 800.ms),
            const SizedBox(height: 20),
            Text(
              'Noch kein Zekr',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.cream,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Lege dein erstes Zekr an — mit Zielanzahl, Rhythmus und Erinnerung.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: AppColors.mist,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.deepNight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Erstes Zekr anlegen',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ],
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
  });

  final Zekr zekr;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final waiting = zekr.isWaitingForNextPeriod;
    final done = zekr.isCompleted;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ProgressRing(
            progress: zekr.progress,
            size: 64,
            stroke: 5,
            child: Text(
              '${(zekr.progress * 100).round()}%',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.mint,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zekr.text,
                  style: AppTheme.arabic(fontSize: 22, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 6),
                Text(
                  waiting
                      ? 'Fertig · nächstes Mal in ${formatCountdown(zekr.timeUntilNextPeriod)}'
                      : done
                          ? 'Ziel erreicht'
                          : '${zekr.currentCount} / ${zekr.targetCount} · ${zekr.repeatLabel}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: waiting
                        ? AppColors.gold
                        : done
                            ? AppColors.mint
                            : AppColors.mist,
                  ),
                ),
                if (zekr.note != null && zekr.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    zekr.note!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.mist.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.mist),
            color: AppColors.forest,
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Text('Bearbeiten', style: GoogleFonts.outfit()),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Löschen',
                  style: GoogleFonts.outfit(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (80 * index).ms, duration: 450.ms)
        .slideY(begin: 0.08, end: 0, delay: (80 * index).ms);
  }
}
