import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../l10n/fa.dart';
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
          child: Center(child: Text(Fa.notFound, style: AppTheme.latin())),
        ),
      );
    }

    final waiting = zekr.isWaitingForNextPeriod;
    final completed = zekr.isCompleted;
    final showAnytimeCta = completed && zekr.allowAnytime;
    final isQuran = zekr.id.startsWith('quran_');
    final manyAyahs = zekr.hasParts && zekr.parts.length > 4;

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
                      tooltip: Fa.history,
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
                      tooltip: Fa.reset,
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                  child: Column(
                    children: [
                      if (isQuran || zekr.hasParts) ...[
                        Text(
                          zekr.text,
                          textAlign: TextAlign.center,
                          style: AppTheme.latin(
                            fontSize: 18,
                            weight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                        if (zekr.note != null && zekr.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            zekr.note!,
                            textAlign: TextAlign.center,
                            style: AppTheme.latin(
                              fontSize: 12,
                              color: AppColors.mist,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                      if (zekr.hasParts && !manyAyahs) ...[
                        _PartStepper(zekr: zekr),
                        const SizedBox(height: 14),
                      ],
                      if (manyAyahs) ...[
                        StatusPill(
                          label: Fa.ayahOf(
                            zekr.currentPartIndex + 1,
                            zekr.parts.length,
                          ),
                          color: AppColors.gold,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (!isQuran && !zekr.hasParts) ...[
                        Text(
                          zekr.displayText,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: AppTheme.arabic(
                            fontSize:
                                zekr.displayText.contains('\n') ? 26 : 34,
                            color: AppColors.cream,
                            height: 1.7,
                          ),
                        )
                            .animate(
                              key: ValueKey(
                                '${zekr.id}-${zekr.currentPartIndex}',
                              ),
                            )
                            .fadeIn(duration: 300.ms),
                        if (zekr.note != null && zekr.note!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            zekr.note!,
                            textAlign: TextAlign.center,
                            style: AppTheme.latin(
                              fontSize: 14,
                              color: AppColors.mist,
                            ),
                          ),
                        ],
                      ],
                      if (zekr.hasParts || isQuran)
                        GlassCard(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                          child: Text(
                            zekr.displayText,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: AppTheme.arabic(
                              fontSize: zekr.displayText.length > 120 ? 22 : 28,
                              color: AppColors.cream,
                              height: 1.85,
                            ),
                          ),
                        )
                            .animate(
                              key: ValueKey(
                                '${zekr.id}-a${zekr.currentPartIndex}',
                              ),
                            )
                            .fadeIn(duration: 280.ms),
                      const SizedBox(height: 22),
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
                            size: isQuran ? 200 : 248,
                            stroke: isQuran ? 11 : 13,
                            glow: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (waiting) ...[
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.gold,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    Fa.achieved,
                                    style: AppTheme.latin(
                                      fontSize: 16,
                                      weight: FontWeight.w600,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  Text(
                                    Fa.againAt(
                                      formatNextPeriodLabel(
                                        zekr.nextPeriodStart,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                    style: AppTheme.latin(
                                      fontSize: 12,
                                      color: AppColors.mist,
                                    ),
                                  ),
                                  Text(
                                    formatCountdown(zekr.timeUntilNextPeriod),
                                    style: AppTheme.latin(
                                      fontSize: 20,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ] else if (completed) ...[
                                  Text(
                                    '✓',
                                    style: AppTheme.latin(
                                      fontSize: 40,
                                      color: AppColors.mint,
                                    ),
                                  ),
                                  Text(
                                    Fa.goalReached,
                                    style: AppTheme.latin(
                                      fontSize: 16,
                                      color: AppColors.mint,
                                    ),
                                  ),
                                  if (zekr.allowAnytime)
                                    Text(
                                      Fa.tapForNewRound,
                                      style: AppTheme.latin(
                                        fontSize: 12,
                                        color: AppColors.mist,
                                      ),
                                    ),
                                ] else ...[
                                  Text(
                                    '${zekr.activeCount}',
                                    style: AppTheme.latin(
                                      fontSize: isQuran ? 42 : 52,
                                      weight: FontWeight.w700,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    Fa.ofTarget(zekr.activeTarget),
                                    style: AppTheme.latin(
                                      fontSize: 14,
                                      color: AppColors.mist,
                                    ),
                                  ),
                                  if (zekr.hasParts)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        Fa.totalProgress(
                                          zekr.totalCount,
                                          zekr.totalTarget,
                                        ),
                                        style: AppTheme.latin(
                                          fontSize: 12,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!waiting && !completed)
                        Text(
                          zekr.hasParts
                              ? (isQuran
                                  ? Fa.ayahOf(
                                      zekr.currentPartIndex + 1,
                                      zekr.parts.length,
                                    )
                                  : Fa.partTap(
                                      zekr.currentPartIndex,
                                      zekr.parts.length,
                                    ))
                              : Fa.tapCircle,
                          style: AppTheme.latin(
                            fontSize: 13,
                            color: AppColors.mist.withValues(alpha: 0.85),
                          ),
                        ),
                      if (showAnytimeCta)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: FilledButton.icon(
                            onPressed: () async {
                              await context
                                  .read<ZekrProvider>()
                                  .startAnytimeRound(zekr.id);
                            },
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text(Fa.sayAgain),
                          ),
                        ),
                      if (_celebrating)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'بارك الله فيك',
                            style: AppTheme.arabic(
                              fontSize: 26,
                              color: AppColors.gold,
                            ),
                          ).animate().fadeIn().scale(),
                        ),
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: i == zekr.currentPartIndex && !zekr.isCompleted
                    ? AppColors.gold.withValues(alpha: 0.18)
                    : AppColors.card.withValues(alpha: 0.55),
                border: Border.all(
                  color: counts[i] >= zekr.parts[i].targetCount
                      ? AppColors.mint
                      : i == zekr.currentPartIndex
                          ? AppColors.gold
                          : AppColors.cardBorder,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${i + 1}',
                    style: AppTheme.latin(
                      fontSize: 11,
                      color: AppColors.mist,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${counts[i]}/${zekr.parts[i].targetCount}',
                    style: AppTheme.latin(fontSize: 10, color: AppColors.mist),
                  ),
                ],
              ),
            ),
          ),
          if (i != zekr.parts.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}
