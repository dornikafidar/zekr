import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../data/recitation_timings.dart';
import '../l10n/fa.dart';
import '../theme/app_theme.dart';
import 'audio_transport_bar.dart';

/// Abdul Basit playback with word-by-word highlight for any ayah.
class SyncedAyahPlayer extends StatefulWidget {
  const SyncedAyahPlayer({
    super.key,
    required this.verseKey,
    this.fallbackText,
    this.onFinished,
    this.autoPlay = false,
  });

  /// Timing key, e.g. `1:1`, `bismillah`, `2:255`.
  final String verseKey;
  final String? fallbackText;
  final VoidCallback? onFinished;
  final bool autoPlay;

  @override
  State<SyncedAyahPlayer> createState() => _SyncedAyahPlayerState();
}

class _SyncedAyahPlayerState extends State<SyncedAyahPlayer> {
  final _player = AudioPlayer();
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SyncedAyahPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verseKey != widget.verseKey) {
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
      await _player.setUrl(url);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _ensureApproxFromDuration(Duration? d) {
    if (!mounted || d == null || _timing == null) return;
    if (_timing!.segments.isNotEmpty || _timing!.words.isEmpty) return;
    final next = withApproxSegments(_timing!, d.inMilliseconds);
    if (identical(next, _timing) || next.segments.isEmpty) return;
    setState(() => _timing = next);
  }

  Future<void> _load() async {
    final gen = ++_loadGen;
    await _player.stop();
    if (!mounted || gen != _loadGen) return;
    setState(() {
      _loading = true;
      _missing = false;
      _activeWord = -1;
      _playing = false;
    });
    final all = await RecitationTimings.load();
    if (!mounted || gen != _loadGen) return;
    var t = await all.resolve(widget.verseKey);
    if (!mounted || gen != _loadGen) return;
    if (t == null) {
      setState(() {
        _timing = null;
        _missing = true;
        _loading = false;
      });
      return;
    }
    // Always have words for the whole mushaf (API, local, or split ayah text).
    t = withWordsFromText(t, widget.fallbackText);
    try {
      var loaded = false;
      if (t.hasLocalAsset && t.assetPath != null) {
        if (await _assetExists(t.assetPath!)) {
          try {
            await _player.setAsset(t.assetPath!);
            loaded = true;
          } catch (_) {
            // Fall through to network.
          }
        }
      }
      if (!loaded) {
        final urls = <String>[
          if (t.networkUrl != null) t.networkUrl!,
          ...all.networkUrlsFor(widget.verseKey),
        ];
        final seen = <String>{};
        for (final url in urls) {
          if (!seen.add(url)) continue;
          if (await _trySetUrl(url)) {
            loaded = true;
            break;
          }
        }
      }
      if (!mounted || gen != _loadGen) return;
      if (!loaded) throw StateError('no audio source');

      // If duration already known (common for setAsset), fill approx segments now.
      final dur = _player.duration;
      if (dur != null) t = withApproxSegments(t, dur.inMilliseconds);

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
      _durSub = _player.durationStream.listen(_ensureApproxFromDuration);
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
      setState(() {
        _timing = t;
        _loading = false;
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
        });
      }
    }
  }

  void _onPosition(Duration pos) {
    if (!mounted || _timing == null) return;
    final i = _timing!.wordIndexAt(pos);
    if (i != _activeWord) setState(() => _activeWord = i);
  }

  Future<void> _toggle() async {
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
    await _player.play();
  }

  @override
  void dispose() {
    _loadGen++;
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
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
    if (_missing || _timing == null) {
      final text = widget.fallbackText ?? '';
      if (text.isEmpty) return const SizedBox.shrink();
      return Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: AppTheme.arabic(
          fontSize: text.length > 120 ? 22 : 28,
          color: AppColors.cream,
          height: 1.85,
        ),
      );
    }

    final t = _timing!;
    final fallback = widget.fallbackText ?? '';
    final words = t.words.isNotEmpty ? t.words : splitArabicWords(fallback);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AudioTransportBar(
          player: _player,
          playing: _playing,
          enabled: true,
          onToggle: _toggle,
          playLabel: Fa.abdulbaset,
        ),
        const SizedBox(height: 12),
        if (words.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 8,
                textDirection: TextDirection.rtl,
                children: [
                  for (var i = 0; i < words.length; i++)
                    _WordChip(
                      text: words[i],
                      active: i == _activeWord,
                      dimmed: _playing && i != _activeWord,
                    ),
                ],
              ),
            ),
          )
        else if (fallback.isNotEmpty)
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
