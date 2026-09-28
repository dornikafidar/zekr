import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/zekr.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'stats_screen.dart';

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
    if (zekr.isWaitingForNextPeriod) return;
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
            child: Text('Nicht gefunden', style: AppTheme.latin()),
          ),
        ),
      );
    }

    final waiting = zekr.isWaitingForNextPeriod;
    final completed = zekr.isCompleted;
    final showAnytimeCta = completed && zekr.allowAnytime;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    StatusPill(label: zekr.repeatLabel, color: AppColors.mist),
                    IconCircleButton(
                      tooltip: 'Verlauf',
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.gold,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StatsScreen(zekrId: zekr.id),
                          ),
                        );
                      },
                    ),
                    IconCircleButton(
                      tooltip: 'Einen zurück',
                      icon: Icons.undo_rounded,
                      color: AppColors.mist,
                      onPressed: waiting || zekr.totalCount == 0
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              context.read<ZekrProvider>().undoTap(zekr.id);
                            },
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
                      if (zekr.hasParts) ...[
                        Text(
                          zekr.text,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: AppTheme.arabic(
                            fontSize: 22,
                            color: AppColors.gold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PartStepper(zekr: zekr),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        zekr.displayText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTheme.arabic(
                          fontSize: zekr.displayText.contains('\n') ? 26 : 36,
                          color: AppColors.cream,
                          height: 1.7,
                        ),
                      )
                          .animate(
                            key: ValueKey(
                              '${zekr.id}-${zekr.currentPartIndex}-${zekr.displayText}',
                            ),
                          )
                          .fadeIn(duration: 350.ms),
                      if (zekr.note != null && zekr.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          zekr.note!,
                          textAlign: TextAlign.center,
                          style: AppTheme.latin(
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
                            progress: zekr.hasParts
                                ? zekr.partProgress
                                : zekr.progress,
                            size: 268,
                            stroke: 13,
                            glow: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (waiting) ...[
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.gold,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Geschafft',
                                    style: AppTheme.latin(
                                      fontSize: 18,
                                      weight: FontWeight.w600,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Wieder ab ${formatNextPeriodLabel(zekr.nextPeriodStart)}',
                                    textAlign: TextAlign.center,
                                    style: AppTheme.latin(
                                      fontSize: 13,
                                      color: AppColors.mist,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatCountdown(zekr.timeUntilNextPeriod),
                                    style: AppTheme.latin(
                                      fontSize: 22,
                                      weight: FontWeight.w700,
                                      color: AppColors.cream,
                                    ),
                                  ),
                                ] else if (completed) ...[
                                  Text(
                                    '✓',
                                    style: AppTheme.latin(
                                      fontSize: 48,
                                      color: AppColors.mint,
                                    ),
                                  ),
                                  Text(
                                    'Ziel erreicht',
                                    style: AppTheme.latin(
                                      fontSize: 18,
                                      color: AppColors.mint,
                                    ),
                                  ),
                                  if (zekr.allowAnytime) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tippe für eine neue Runde',
                                      style: AppTheme.latin(
                                        fontSize: 12,
                                        color: AppColors.mist,
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  Text(
                                    '${zekr.activeCount}',
                                    style: AppTheme.latin(
                                      fontSize: 56,
                                      weight: FontWeight.w700,
                                      color: AppColors.cream,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'von ${zekr.activeTarget}',
                                    style: AppTheme.latin(
                                      fontSize: 16,
                                      color: AppColors.mist,
                                    ),
                                  ),
                                  if (zekr.hasParts) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Gesamt ${zekr.totalCount}/${zekr.totalTarget}',
                                      style: AppTheme.latin(
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
                      if (!waiting && !completed)
                        Text(
                          zekr.hasParts
                              ? 'Teil ${zekr.currentPartIndex + 1}/${zekr.parts.length} · tippe'
                              : 'Tippe auf den Kreis',
                          style: AppTheme.latin(
                            fontSize: 14,
                            color: AppColors.mist.withValues(alpha: 0.8),
                            letterSpacing: 0.4,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(begin: 0.45, end: 1, duration: 1400.ms),
                      if (showAnytimeCta)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: FilledButton.icon(
                            onPressed: () async {
                              await context
                                  .read<ZekrProvider>()
                                  .startAnytimeRound(zekr.id);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.deepNight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.replay_rounded),
                            label: Text(
                              'Jetzt nochmal sagen',
                              style: AppTheme.latin(
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
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
                      TextButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.forest,
                              title: Text('Zähler zurücksetzen?',
                                  style: AppTheme.latin()),
                              content: Text(
                                'Der Fortschritt dieser Runde wird gelöscht.',
                                style: AppTheme.latin(color: AppColors.mist),
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
                          style: AppTheme.latin(
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

class _PartStepper extends StatelessWidget {
  const _PartStepper({required this.zekr});

  final Zekr zekr;

  @override
  Widget build(BuildContext context) {
    final counts = zekr.effectivePartCounts;
    return Row(
      children: [
        for (var i = 0; i < zekr.parts.length; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: i == zekr.currentPartIndex && !zekr.isCompleted
                      ? [
                          AppColors.gold.withValues(alpha: 0.22),
                          AppColors.card.withValues(alpha: 0.7),
                        ]
                      : [
                          AppColors.cardElevated.withValues(alpha: 0.85),
                          AppColors.card.withValues(alpha: 0.55),
                        ],
                ),
                border: Border.all(
                  color: counts[i] >= zekr.parts[i].targetCount
                      ? AppColors.mint
                      : i == zekr.currentPartIndex
                          ? AppColors.gold
                          : AppColors.cardBorder.withValues(alpha: 0.7),
                  width: i == zekr.currentPartIndex ? 1.3 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    zekr.parts[i].text,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.arabic(
                      fontSize: 13,
                      color: counts[i] >= zekr.parts[i].targetCount
                          ? AppColors.mint
                          : AppColors.cream,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${counts[i]}/${zekr.parts[i].targetCount}',
                    style: AppTheme.latin(
                      fontSize: 11,
                      color: AppColors.mist,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i != zekr.parts.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
