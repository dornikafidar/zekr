import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/quran_fa.dart';
import '../data/quran_passages.dart';
import '../data/recitation_timings.dart';
import '../l10n/fa.dart';
import '../models/zekr.dart';
import '../providers/quran_reading_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/zekr_provider.dart';
import '../services/display_keep.dart';
import '../services/quran_resume.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/synced_ayah_player.dart';
import 'stats_screen.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key, required this.zekrId});

  final String zekrId;

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen>
    with WidgetsBindingObserver {
  bool _celebrating = false;
  bool _autoPlayNext = false;
  Timer? _ticker;
  Timer? _pauseTicker;
  StreamSubscription<AccelerometerEvent>? _shakeSub;
  DateTime? _lastShakeAt;
  bool _shakeBusy = false;
  int _resumeSeekMs = 0;
  bool _resumeReady = false;
  bool _seekConsumed = false;
  DateTime _lastResumeSave = DateTime.fromMillisecondsSinceEpoch(0);
  int _finishGen = 0;
  int _translationPauseLeft = 0;
  /// True while advancing after translation pause (skip re-entering pause).
  bool _advanceFromPause = false;

  bool get _isQuran => widget.zekrId.startsWith('quran_');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isQuran) unawaited(DisplayKeep.setKeepScreenOn(true));
    unawaited(QuranFa.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    }));
    unawaited(_prepareResume());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _shakeSub = accelerometerEventStream().listen(_onAccel);
  }

  Future<void> _prepareResume() async {
    if (!_isQuran) {
      if (mounted) setState(() => _resumeReady = true);
      return;
    }
    final r = await QuranResume.load();
    if (!mounted) return;
    if (r != null && r.zekrId == widget.zekrId) {
      await context.read<ZekrProvider>().restoreQuranPart(
            widget.zekrId,
            r.partIndex,
          );
      _resumeSeekMs = r.positionMs;
    }
    if (mounted) setState(() => _resumeReady = true);
  }

  Future<void> _persistResume({int? positionMs}) async {
    if (!_isQuran || !mounted) return;
    // آیت‌الکرسی / إن یکاد must not replace the surah continue-spot.
    if (!QuranResume.isSurahZekr(widget.zekrId)) return;
    final z = context.read<ZekrProvider>().byId(widget.zekrId);
    if (z == null) return;
    final verseKey = audioVerseKey(
      z.id,
      z.currentPartIndex,
      partTexts: [for (final p in z.parts) p.text],
    );
    String rawTitle;
    try {
      final passages = loadQuranPassages();
      final match = passages.where((p) => p.id == z.id);
      rawTitle = match.isNotEmpty
          ? '${match.first.title} · آیه ${z.currentPartIndex + 1}'
          : (z.note?.trim().isNotEmpty == true
              ? z.note!.trim()
              : 'آیه ${z.currentPartIndex + 1}');
    } catch (_) {
      rawTitle = z.note?.trim().isNotEmpty == true
          ? z.note!.trim()
          : 'آیه ${z.currentPartIndex + 1}';
    }
    final title =
        rawTitle.length > 48 ? '${rawTitle.substring(0, 48)}…' : rawTitle;
    await QuranResume.save(
      zekrId: z.id,
      partIndex: z.currentPartIndex,
      positionMs: positionMs ?? _resumeSeekMs,
      titleFa: title,
      verseKey: verseKey,
    );
  }

  void _onAudioPosition(Duration pos) {
    _resumeSeekMs = pos.inMilliseconds;
    final now = DateTime.now();
    if (now.difference(_lastResumeSave) < const Duration(seconds: 2)) return;
    _lastResumeSave = now;
    unawaited(_persistResume(positionMs: _resumeSeekMs));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_persistResume(positionMs: _resumeSeekMs));
    }
  }

  Future<void> _noteQuranAyah() async {
    if (!hasAudioForZekr(widget.zekrId) &&
        !widget.zekrId.startsWith('quran_')) {
      return;
    }
    await context.read<QuranReadingProvider>().recordAyahs(1);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _finishGen++;
    if (_isQuran) unawaited(DisplayKeep.setKeepScreenOn(false));
    unawaited(_persistResume(positionMs: _resumeSeekMs));
    _ticker?.cancel();
    _pauseTicker?.cancel();
    _shakeSub?.cancel();
    super.dispose();
  }

  Future<void> _afterAyahFinished(Zekr zekr) async {
    final gen = ++_finishGen;
    _seekConsumed = true;
    _resumeSeekMs = 0;
    if (!mounted || waitingOrDone(zekr)) return;
    final pauseSec = context.read<SettingsProvider>().ayahPauseSec;
    if (pauseSec > 0) {
      _pauseTicker?.cancel();
      setState(() => _translationPauseLeft = pauseSec);
      _pauseTicker = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted || gen != _finishGen) {
          t.cancel();
          return;
        }
        if (_translationPauseLeft <= 1) {
          t.cancel();
          setState(() => _translationPauseLeft = 0);
        } else {
          setState(() => _translationPauseLeft--);
        }
      });
      await Future<void>.delayed(Duration(seconds: pauseSec));
      _pauseTicker?.cancel();
      if (!mounted || gen != _finishGen) return;
      // Keep Farsi-only UI until tap rebuilds the next ayah (no Arabic flash).
      _translationPauseLeft = 0;
    }
    if (!mounted || gen != _finishGen) return;
    _autoPlayNext = true;
    _advanceFromPause = true;
    try {
      await _onTap(zekr);
    } finally {
      _advanceFromPause = false;
    }
  }

  bool waitingOrDone(Zekr zekr) =>
      zekr.isWaitingForNextPeriod || zekr.isCompleted;

  void _onAccel(AccelerometerEvent e) {
    // Shake-to-count is for zekr only — never advance Quran ayahs.
    if (_isQuran) return;
    final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    // ~1g idle; a light shake peaks above ~13–14.
    if (mag < 13.5) return;
    final now = DateTime.now();
    if (_lastShakeAt != null &&
        now.difference(_lastShakeAt!) < const Duration(milliseconds: 480)) {
      return;
    }
    _lastShakeAt = now;
    if (_shakeBusy || !mounted) return;
    final zekr = context.read<ZekrProvider>().byId(widget.zekrId);
    if (zekr == null) return;
    _onTap(zekr);
  }

  Future<void> _onTap(Zekr zekr) async {
    if (zekr.isWaitingForNextPeriod) return;
    if (zekr.isCompleted) return; // use «دوباره بگو» button for anytime restart
    if (_shakeBusy) return;

    // Quran circle: wait translation pause, then auto-play next ayah.
    if (_isQuran && !_advanceFromPause) {
      if (_translationPauseLeft > 0) {
        // Skip remaining wait → advance + autoplay now.
        _finishGen++;
        _pauseTicker?.cancel();
        _translationPauseLeft = 0;
        _autoPlayNext = true;
        _advanceFromPause = true;
        try {
          await _commitTap(zekr);
        } finally {
          _advanceFromPause = false;
        }
        return;
      }
      unawaited(_afterAyahFinished(zekr));
      return;
    }

    await _commitTap(zekr);
  }

  Future<void> _commitTap(Zekr zekr) async {
    _finishGen++; // cancel any other pending pause
    if (_translationPauseLeft > 0 && mounted) {
      setState(() => _translationPauseLeft = 0);
    }
    _shakeBusy = true;
    HapticFeedback.lightImpact();
    try {
      final done = await context.read<ZekrProvider>().tap(zekr.id);
      if (zekr.id.startsWith('quran_')) {
        _seekConsumed = true;
        _resumeSeekMs = 0;
        unawaited(_noteQuranAyah());
        unawaited(_persistResume(positionMs: 0));
      }
      if (done && mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _celebrating = true;
          _autoPlayNext = false;
        });
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        if (mounted) setState(() => _celebrating = false);
      }
    } finally {
      _shakeBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final zekr = context.watch<ZekrProvider>().byId(widget.zekrId);

    if (zekr == null || (_isQuran && !_resumeReady)) {
      return Scaffold(
        body: AtmosphereBackground(
          child: Center(
            child: zekr == null
                ? Text(Fa.notFound, style: AppTheme.latin())
                : const CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
      );
    }

    final waiting = zekr.isWaitingForNextPeriod;
    final completed = zekr.isCompleted;
    final showAnytimeCta = completed && zekr.allowAnytime;
    final isQuran = zekr.id.startsWith('quran_');
    // One-tap-per-ayah: ring shows ayah index + overall fill (not 0/1).
    final ayahMode = isQuran && zekr.hasParts;
    final manyAyahs = zekr.hasParts && zekr.parts.length > 4;
    final quranGoal = isQuran ? context.watch<QuranReadingProvider>() : null;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    BackCircleButton(onPressed: () => Navigator.pop(context)),
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
              if (!waiting && !isQuran)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text(
                    Fa.shakeHint,
                    textAlign: TextAlign.center,
                    style: AppTheme.latin(
                      fontSize: 11,
                      color: AppColors.mist,
                    ),
                  ),
                ),
              if (quranGoal != null && quranGoal.enabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                  child: _QuranGoalBanner(goal: quranGoal),
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
                          child: Builder(
                            builder: (context) {
                              // Default offline: سعد الغامدی full Ayat al-Kursi.
                              if (zekr.id == 'quran_kursi') {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SyncedAyahPlayer(
                                      key: const ValueKey('kursi_ghamdi'),
                                      verseKey: 'kursi_ghamdi',
                                      fallbackText: [
                                        for (final p in zekr.parts) p.text,
                                      ].join('\n'),
                                      offlineAsset:
                                          'assets/audio/quran/kursi_ghamdi.mp3',
                                      playLabel: Fa.saadGhamdiKursi,
                                      initialSeekMs: _seekConsumed
                                          ? null
                                          : _resumeSeekMs,
                                      onPositionTick: _onAudioPosition,
                                      onFinished: () {
                                        _seekConsumed = true;
                                        unawaited(
                                          context
                                              .read<QuranReadingProvider>()
                                              .recordAyahs(3),
                                        );
                                      },
                                    ),
                                    _FaTranslation(
                                      verseKey: '2:255',
                                      extraKeys: const ['2:256', '2:257'],
                                    ),
                                  ],
                                );
                              }
                              final verseKey = audioVerseKey(
                                zekr.id,
                                zekr.currentPartIndex,
                                partTexts: [
                                  for (final p in zekr.parts) p.text,
                                ],
                              );
                              if (verseKey != null &&
                                  hasAudioForZekr(zekr.id)) {
                                final chain = _autoPlayNext;
                                final pausing = _translationPauseLeft > 0;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // During translation wait: Farsi only (no Arabic).
                                    if (!pausing)
                                      SyncedAyahPlayer(
                                        key: ValueKey(verseKey),
                                        verseKey: verseKey,
                                        fallbackText: zekr.displayText,
                                        autoPlay: chain,
                                        initialSeekMs: _seekConsumed
                                            ? null
                                            : _resumeSeekMs,
                                        onPositionTick: _onAudioPosition,
                                        onFinished: waiting || completed
                                            ? null
                                            : () => unawaited(
                                                  _afterAyahFinished(zekr),
                                                ),
                                      ),
                                    if (pausing)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          Fa.ayahPauseCountdown(
                                            _translationPauseLeft,
                                          ),
                                          textAlign: TextAlign.center,
                                          style: AppTheme.latin(
                                            fontSize: 13,
                                            weight: FontWeight.w700,
                                            color: AppColors.gold,
                                          ),
                                        ),
                                      ),
                                    _FaTranslation(
                                      verseKey: verseKey,
                                      emphasize: pausing,
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    zekr.displayText,
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    style: AppTheme.arabic(
                                      fontSize: zekr.displayText.length > 120
                                          ? 22
                                          : 28,
                                      color: AppColors.cream,
                                      height: 1.85,
                                    ),
                                  ),
                                  if (verseKey != null)
                                    _FaTranslation(verseKey: verseKey),
                                ],
                              );
                            },
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
                        onTap: waiting || completed
                            ? null
                            : () => _onTap(zekr),
                        child: AnimatedScale(
                          scale: _celebrating ? 1.04 : 1.0,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutBack,
                          child: ProgressRing(
                            progress: ayahMode
                                ? zekr.progress
                                : (zekr.hasParts
                                    ? zekr.partProgress
                                    : zekr.progress),
                            size: isQuran ? 200 : 248,
                            stroke: isQuran ? 12 : 13,
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
                                ] else if (ayahMode) ...[
                                  Text(
                                    '${zekr.currentPartIndex + 1}',
                                    style: AppTheme.latin(
                                      fontSize: 44,
                                      weight: FontWeight.w800,
                                      height: 1,
                                      color: AppColors.cream,
                                    ),
                                  ),
                                  Text(
                                    Fa.ofTarget(zekr.parts.length),
                                    style: AppTheme.latin(
                                      fontSize: 15,
                                      color: AppColors.mist,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      Fa.totalProgress(
                                        zekr.totalCount,
                                        zekr.totalTarget,
                                      ),
                                      style: AppTheme.latin(
                                        fontSize: 13,
                                        weight: FontWeight.w700,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    '${zekr.activeCount}',
                                    style: AppTheme.latin(
                                      fontSize: 52,
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

class _QuranGoalBanner extends StatelessWidget {
  const _QuranGoalBanner({required this.goal});

  final QuranReadingProvider goal;

  @override
  Widget build(BuildContext context) {
    final done = goal.doneToday;
    final accent = done ? AppColors.mint : AppColors.gold;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            done
                ? Fa.quranGoalDoneReading
                : Fa.quranGoalReading(
                    goal.todayCount,
                    goal.target,
                    goal.goal.labelFa,
                  ),
            textAlign: TextAlign.center,
            style: AppTheme.latin(
              fontSize: 12.5,
              weight: FontWeight.w700,
              color: accent,
            ),
          ),
          if (!done) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 4,
                color: AppColors.gold,
                backgroundColor: AppColors.cardBorder,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaTranslation extends StatelessWidget {
  const _FaTranslation({
    required this.verseKey,
    this.extraKeys = const [],
    this.emphasize = false,
  });

  final String verseKey;
  final List<String> extraKeys;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (QuranFa.of(verseKey) != null) QuranFa.of(verseKey)!,
      for (final k in extraKeys)
        if (QuranFa.of(k) != null) QuranFa.of(k)!,
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: emphasize
            ? const EdgeInsets.fromLTRB(12, 10, 12, 10)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: emphasize
              ? AppColors.gold.withValues(alpha: 0.12)
              : Colors.transparent,
          border: emphasize
              ? Border.all(color: AppColors.gold.withValues(alpha: 0.55))
              : null,
        ),
        child: Column(
          children: [
            Text(
              Fa.translationFa,
              style: AppTheme.latin(
                fontSize: 12,
                weight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lines.join('\n\n'),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTheme.latin(
                fontSize: emphasize ? 15 : 14,
                color: emphasize ? AppColors.cream : AppColors.mist,
                height: 1.65,
              ),
            ),
          ],
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
