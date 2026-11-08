import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../data/recitation_timings.dart';
import '../l10n/fa.dart';
import '../providers/settings_provider.dart';
import '../services/app_audio.dart';
import '../services/ghamdi_audio_cache.dart';
import '../theme/app_theme.dart';
import 'audio_transport_bar.dart';

/// Quran ayah playback (default: سعد الغامدی) with word highlight.
class SyncedAyahPlayer extends StatefulWidget {
  const SyncedAyahPlayer({
    super.key,
    required this.verseKey,
    this.fallbackText,
    this.onFinished,
    this.autoPlay = false,
    this.offlineAsset,
    this.playLabel,
    this.initialSeekMs,
    this.onPositionTick,
  });

  /// Timing key, e.g. `1:1`, `bismillah`, `2:255`.
  final String verseKey;
  final String? fallbackText;
  final VoidCallback? onFinished;
  final bool autoPlay;

  /// Prefer this bundled file (offline) over CDN / network.
  final String? offlineAsset;
  final String? playLabel;

  /// Resume within this ayah (ms).
  final int? initialSeekMs;

  /// Fired ~every position update (for persisting resume).
  final ValueChanged<Duration>? onPositionTick;

  @override
  State<SyncedAyahPlayer> createState() => _SyncedAyahPlayerState();
}

class _SyncedAyahPlayerState extends State<SyncedAyahPlayer> {
  // Shared: just_audio_background allows only one AudioPlayer.
  AudioPlayer get _player => AppAudio.player;
  final _scroll = ScrollController();
  final _wordKeys = <GlobalKey>[];
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;
  AyahTiming? _timing;
  int _activeWord = -1;
  bool _loading = true;
  bool _missing = false;
  bool _playing = false;
  bool _finishFired = false;
  int _loadGen = 0;
  /// First stable media duration — some devices inflate duration after replay.
  int? _syncDurMs;

  MediaItem _mediaTag() => MediaItem(
        id: widget.verseKey,
        title: widget.playLabel ?? Fa.saadGhamdi,
        album: 'قرآن',
      );

  void _ensureWordKeys(int n) {
    while (_wordKeys.length < n) {
      _wordKeys.add(GlobalKey());
    }
    if (_wordKeys.length > n) {
      _wordKeys.removeRange(n, _wordKeys.length);
    }
  }

  void _scrollToActive(int i) {
    if (i < 0 || i >= _wordKeys.length) return;
    final ctx = _wordKeys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.35,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SyncedAyahPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verseKey != widget.verseKey ||
        oldWidget.offlineAsset != widget.offlineAsset) {
      _finishFired = false;
      _load();
    }
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _trySetUrl(String url) async {
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url), tag: _mediaTag()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _trySetFile(String path) async {
    try {
      await _player.setAudioSource(
        AudioSource.file(path, tag: _mediaTag()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _trySetAsset(String path) async {
    try {
      await _player.setAudioSource(
        AudioSource.asset(path, tag: _mediaTag()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  int _stableDurationMs(int reportedMs) {
    if (reportedMs <= 0) return reportedMs;
    final locked = _syncDurMs;
    // ponytail: inflated duration after 2nd play → half-speed highlight; lock first good value
    if (locked != null && locked > 500 && reportedMs > locked * 1.45) {
      return locked;
    }
    if (locked == null ||
        reportedMs < locked ||
        (reportedMs - locked).abs() > 200) {
      _syncDurMs = reportedMs;
    }
    return _syncDurMs!;
  }

  void _resyncWordsToDuration(Duration? d) {
    if (!mounted || d == null || _timing == null) return;
    if (_timing!.words.isEmpty) return;
    final ms = _stableDurationMs(d.inMilliseconds);
    if (ms <= 0) return;
    final next = withResyncedApproxSegments(_timing!, ms);
    final oldEnd =
        _timing!.segments.isEmpty ? -1 : _timing!.segments.last[2];
    if (oldEnd == ms &&
        _timing!.segments.length == next.segments.length) {
      return;
    }
    setState(() => _timing = next);
  }

  Future<void> _applySavedSpeed() async {
    if (!mounted) return;
    try {
      final speed = context.read<SettingsProvider>().playbackSpeed;
      if ((_player.speed - speed).abs() > 0.01) {
        await _player.setSpeed(speed);
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    final gen = ++_loadGen;
    _syncDurMs = null;
    await _player.stop();
    if (!mounted || gen != _loadGen) return;
    setState(() {
      _loading = true;
      _missing = false;
      _activeWord = -1;
      _playing = false;
    });
    final offline = widget.offlineAsset;
    final all = offline == null ? await RecitationTimings.load() : null;
    if (!mounted || gen != _loadGen) return;
    AyahTiming? t;
    if (offline != null) {
      t = AyahTiming(
        words: splitArabicWords(widget.fallbackText ?? ''),
        segments: const [],
      );
    } else {
      t = await all!.resolve(widget.verseKey);
      if (!mounted || gen != _loadGen) return;
      if (t == null) {
        setState(() {
          _timing = null;
          _missing = true;
          _loading = false;
        });
        return;
      }
      // Words only from pack/API; segments rebuilt from Ghamdi duration below.
      t = withWordsFromText(t, widget.fallbackText);
      t = AyahTiming(
        file: t.file,
        networkUrl: t.networkUrl,
        words: t.words,
        segments: const [],
      );
    }
    try {
      var loaded = false;
      // 1) Explicit bundled override (e.g. kursi_ghamdi).
      if (offline != null && await _assetExists(offline)) {
        loaded = await _trySetAsset(offline);
      }
      // 2) Ghamdi disk cache.
      if (!loaded && widget.verseKey != 'kursi_ghamdi') {
        final cached =
            await GhamdiAudioCache.instance.localPath(widget.verseKey);
        if (cached != null) loaded = await _trySetFile(cached);
      }
      // 3) Download Ghamdi into cache (then offline).
      if (!loaded && widget.verseKey != 'kursi_ghamdi') {
        final path =
            await GhamdiAudioCache.instance.ensureCached(widget.verseKey);
        if (path != null) loaded = await _trySetFile(path);
      }
      // 4) Stream CDN (Ghamdi first).
      if (!loaded && all != null) {
        final urls = <String>[
          if (t.networkUrl != null) t.networkUrl!,
          ...all.networkUrlsFor(widget.verseKey),
        ];
        final seen = <String>{};
        for (final url in urls) {
          if (!seen.add(url)) continue;
          if (await _trySetUrl(url)) {
            loaded = true;
            unawaited(
              GhamdiAudioCache.instance.ensureCached(widget.verseKey),
            );
            break;
          }
        }
      }
      if (!mounted || gen != _loadGen) return;
      if (!loaded) throw StateError('no audio source');

      final dur = _player.duration;
      if (dur != null && dur.inMilliseconds > 0) {
        t = withResyncedApproxSegments(
          t,
          _stableDurationMs(dur.inMilliseconds),
        );
      }

      await _posSub?.cancel();
      await _durSub?.cancel();
      await _stateSub?.cancel();
      try {
        _posSub = _player
            .createPositionStream(
              steps: 200,
              minPeriod: const Duration(milliseconds: 40),
              maxPeriod: const Duration(milliseconds: 80),
            )
            .listen(_onPosition);
      } catch (_) {
        _posSub = _player.positionStream.listen(_onPosition);
      }
      _durSub = _player.durationStream.listen(_resyncWordsToDuration);
      _stateSub = _player.playerStateStream.listen((s) {
        if (!mounted || gen != _loadGen) return;
        final playing = s.playing;
        if (playing != _playing) setState(() => _playing = playing);
        if (s.processingState == ProcessingState.completed) {
          setState(() {
            _playing = false;
            if (_timing != null && _timing!.words.isNotEmpty) {
              _activeWord = _timing!.words.length - 1;
            }
          });
          if (!_finishFired) {
            _finishFired = true;
            widget.onFinished?.call();
          }
        }
      });
      if (!mounted || gen != _loadGen) return;
      await _applySavedSpeed();
      final seekMs = widget.initialSeekMs;
      if (seekMs != null && seekMs > 400) {
        final d = _player.duration;
        final maxMs = d?.inMilliseconds ?? seekMs + 1;
        final clamped = seekMs.clamp(0, (maxMs - 200).clamp(0, maxMs));
        await _player.seek(Duration(milliseconds: clamped));
      }
      if (!mounted || gen != _loadGen) return;
      setState(() {
        _timing = t;
        _loading = false;
        _missing = false;
      });
      if (widget.autoPlay) {
        _finishFired = false;
        unawaited(_player.play());
      }
    } catch (_) {
      if (mounted && gen == _loadGen) {
        setState(() {
          _missing = true;
          _loading = false;
          _timing = t;
        });
      }
    }
  }

  void _onPosition(Duration pos) {
    if (!mounted || _timing == null) return;
    widget.onPositionTick?.call(pos);
    // Don't let a bogus long duration keep highlighting after audio ended.
    final dur = _syncDurMs ?? _player.duration?.inMilliseconds;
    final capped = (dur != null && pos.inMilliseconds > dur)
        ? Duration(milliseconds: dur)
        : pos;
    final i = _timing!.wordIndexAt(capped);
    if (i != _activeWord) {
      setState(() => _activeWord = i);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToActive(i);
      });
    }
  }

  Future<void> _toggle() async {
    if (_missing) {
      await _load();
      return;
    }
    if (_timing == null) return;
    if (_player.playing) {
      await _player.pause();
      return;
    }
    _finishFired = false;
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      setState(() => _activeWord = -1);
    }
    await _applySavedSpeed();
    await _player.play();
  }

  @override
  void dispose() {
    try {
      widget.onPositionTick?.call(_player.position);
    } catch (_) {}
    _loadGen++;
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _scroll.dispose();
    // Shared player — pause when leaving this ayah UI; never dispose.
    unawaited(_player.pause());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          ),
        ),
      );
    }

    final fallback = widget.fallbackText ?? '';
    final t = _timing;
    final words = t != null && t.words.isNotEmpty
        ? t.words
        : splitArabicWords(fallback);

    if (_missing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AudioTransportBar(
            player: _player,
            playing: false,
            enabled: false,
            onToggle: _toggle,
            playLabel: widget.playLabel ?? Fa.saadGhamdi,
          ),
          if (fallback.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              fallback,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTheme.arabic(
                fontSize: fallback.length > 120 ? 22 : 28,
                color: AppColors.cream,
                height: 1.85,
              ),
            ),
          ],
        ],
      );
    }

    if (t == null) {
      if (fallback.isEmpty) return const SizedBox.shrink();
      return Text(
        fallback,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: AppTheme.arabic(
          fontSize: fallback.length > 120 ? 22 : 28,
          color: AppColors.cream,
          height: 1.85,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AudioTransportBar(
          player: _player,
          playing: _playing,
          enabled: true,
          onToggle: _toggle,
          playLabel: widget.playLabel ?? Fa.saadGhamdi,
        ),
        const SizedBox(height: 12),
        if (words.isNotEmpty) ...[
          Builder(
            builder: (_) {
              _ensureWordKeys(words.length);
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 8,
                    textDirection: TextDirection.rtl,
                    children: [
                      for (var i = 0; i < words.length; i++)
                        KeyedSubtree(
                          key: _wordKeys[i],
                          child: _WordChip(
                            text: words[i],
                            active: i == _activeWord,
                            dimmed: _playing && i != _activeWord,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ] else if (fallback.isNotEmpty)
          Text(
            fallback,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTheme.arabic(
              fontSize: fallback.length > 120 ? 22 : 28,
              color: AppColors.cream,
              height: 1.85,
            ),
          ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.text,
    required this.active,
    required this.dimmed,
  });

  final String text;
  final bool active;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? AppColors.gold.withValues(alpha: 0.28)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: active
            ? Border.all(color: AppColors.gold, width: 1.4)
            : Border.all(color: Colors.transparent),
      ),
      child: Text(
        text,
        style: AppTheme.arabic(
          fontSize: active ? 30 : 27,
          height: 1.65,
          color: active
              ? AppColors.gold
              : AppColors.cream.withValues(alpha: dimmed ? 0.4 : 1),
        ),
      ),
    );
  }
}
