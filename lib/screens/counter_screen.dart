import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/zekr.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key, required this.zekrId});

  final String zekrId;

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  bool _celebrating = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _onTap(Zekr zekr) async {
    if (zekr.isWaitingForNextPeriod || zekr.isCompleted) return;
    HapticFeedback.lightImpact();
    final done = await context.read<ZekrProvider>().tap(zekr.id);
    if (done && mounted) {
      HapticFeedback.mediumImpact();
      setState(() => _celebrating = true);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (mounted) setState(() => _celebrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zekr = context.watch<ZekrProvider>().byId(widget.zekrId);

    if (zekr == null) {
      return Scaffold(
        body: AtmosphereBackground(
          child: Center(
            child: Text('Nicht gefunden', style: GoogleFonts.outfit()),
          ),
        ),
      );
    }

    final waiting = zekr.isWaitingForNextPeriod;

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
                    const Spacer(),
                    Text(
                      zekr.repeatLabel,
                      style: GoogleFonts.outfit(
                        color: AppColors.mist,
                        fontSize: 13,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Einen zurück',
                      onPressed: waiting || zekr.currentCount == 0
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              context.read<ZekrProvider>().undoTap(zekr.id);
                            },
                      icon: const Icon(Icons.undo_rounded),
                      color: AppColors.mist,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),
                      Text(
                        zekr.text,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTheme.arabic(
                          fontSize: zekr.text.contains('\n') ? 26 : 36,
                          color: AppColors.cream,
                          height: 1.7,
                        ),
                      ).animate().fadeIn(duration: 500.ms),
                      if (zekr.note != null && zekr.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          zekr.note!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.mist,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const Spacer(flex: 1),
                      GestureDetector(
                        onTap: () => _onTap(zekr),
                        child: AnimatedScale(
                          scale: _celebrating ? 1.04 : 1.0,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutBack,
                          child: ProgressRing(
                            progress: zekr.progress,
                            size: 260,
                            stroke: 12,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (waiting) ...[
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.gold,
                                    size: 42,
                                  ).animate().scale(),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Geschafft',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Nächstes Mal in',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: AppColors.mist,
                                    ),
                                  ),
                                  Text(
                                    formatCountdown(zekr.timeUntilNextPeriod),
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.cream,
                                    ),
                                  ),
                                ] else if (zekr.isCompleted) ...[
                                  Text(
                                    '✓',
                                    style: GoogleFonts.outfit(
                                      fontSize: 48,
                                      color: AppColors.mint,
                                    ),
                                  ),
                                  Text(
                                    'Ziel erreicht',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      color: AppColors.mint,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    '${zekr.currentCount}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.cream,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'von ${zekr.targetCount}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      color: AppColors.mist,
                                    ),
                                  ),
                                  if (zekr.incrementPerTap > 1) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '+${zekr.incrementPerTap} pro Tipp',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (!waiting && !zekr.isCompleted)
                        Text(
                          'Tippe auf den Kreis',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.mist.withValues(alpha: 0.8),
                            letterSpacing: 0.4,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(begin: 0.45, end: 1, duration: 1400.ms),
                      if (_celebrating)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'بارك الله فيك',
                            style: AppTheme.arabic(
                              fontSize: 28,
                              color: AppColors.gold,
                            ),
                          ).animate().fadeIn().scale(),
                        ),
                      const Spacer(flex: 2),
                      if (!waiting)
                        TextButton(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.forest,
                                title: Text('Zähler zurücksetzen?',
                                    style: GoogleFonts.outfit()),
                                content: Text(
                                  'Der Fortschritt dieser Periode wird gelöscht.',
                                  style: GoogleFonts.outfit(
                                      color: AppColors.mist),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Abbrechen'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Zurücksetzen'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              await context
                                  .read<ZekrProvider>()
                                  .resetCount(zekr.id);
                            }
                          },
                          child: Text(
                            'Zähler zurücksetzen',
                            style: GoogleFonts.outfit(
                              color: AppColors.mist.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
