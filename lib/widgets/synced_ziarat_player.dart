import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../data/recitation_timings.dart'
    show
        splitArabicWords,
        approxWordSegments,
        syncDurationForDisplayedWords;
import '../data/ziarat_timings.dart'
    show ZiaratTiming, ZiaratTimings, scaleSegmentsToDuration;
import '../l10n/fa.dart';
import '../theme/app_theme.dart';
import 'audio_transport_bar.dart';

/// Word-synced ziarat playback.
/// Prefers per-reciter stream sync packs, then approx from duration.
class SyncedZiaratPlayer extends StatefulWidget {
  const SyncedZiaratPlayer({
    super.key,
    required this.ziaratId,
    required this.fallbackText,
    this.streamUrl,
    this.audioSourceId,
    this.playLabel = 'پخش همگام',
  });

  final String ziaratId;
  final String fallbackText;
  final String? streamUrl;
  final String? audioSourceId;
  final String playLabel;

  @override
  State<SyncedZiaratPlayer> createState() => _SyncedZiaratPlayerState();
}

class _SyncedZiaratPlayerState extends State<SyncedZiaratPlayer> {
  final _player = AudioPlayer();
  final _scroll = ScrollController();
  final _wordKeys = <GlobalKey>[];
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;
  ZiaratTiming? _timing;
  int _activeWord = -1;
  bool _loading = true;
  bool _audioReady = false;
  bool _playing = false;
  bool _usingStream = false;
  bool _hasRealSync = false;
  String? _error;
  int _gen = 0;

  ZiaratTiming _fromFallbackText() {
    return ZiaratTiming(
      file: '${widget.ziaratId}.mp3',
      words: splitArabicWords(widget.fallbackText),
      segments: const [],
    );
  }

  ZiaratTiming _wordsOnly(ZiaratTiming t) {
    final words = t.words.isNotEmpty
        ? t.words
        : splitArabicWords(widget.fallbackText);
    return ZiaratTiming(file: t.file, words: words, segments: const []);
  }

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

  /// Fit word windows when we only have approx (no ASR pack).
  void _syncSegmentsToDuration(Duration? d) {
    if (!mounted || d == null || _timing == null) return;
    if (_hasRealSync) return; // never stretch real ASR timings
    final raw = d.inMilliseconds;
    if (raw <= 0 || _timing!.words.isEmpty) return;
    final t = _timing!;
    final dur = _usingStream || t.segments.isEmpty
        ? syncDurationForDisplayedWords(raw, t.words.length)
        : raw;

    if (t.segments.isEmpty) {
      final segs = approxWordSegments(t.words, dur);
      if (segs.isEmpty) return;
      setState(() {
        _timing = ZiaratTiming(file: t.file, words: t.words, segments: segs);
      });
      return;
    }

    final scaled = scaleSegmentsToDuration(t.segments, dur);
    if (identical(scaled, t.segments)) return;
    setState(() {
      _timing = ZiaratTiming(file: t.file, words: t.words, segments: scaled);
    });
  }

  Future<void> _wirePlayer() async {
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _stateSub?.cancel();
    final dur = _player.duration;
    if (dur != null) _syncSegmentsToDuration(dur);
    try {
      _posSub = _player
          .createPositionStream(
            steps: 400,
            minPeriod: const Duration(milliseconds: 30),
            maxPeriod: const Duration(milliseconds: 60),
          )
          .listen(_onPosition);
    } catch (_) {
      _posSub = _player.positionStream.listen(_onPosition);
    }
    _durSub = _player.durationStream.listen(_syncSegmentsToDuration);
    _stateSub = _player.playerStateStream.listen((s) {
      if (!mounted) return;
      if (s.playing != _playing) setState(() => _playing = s.playing);
      if (s.processingState == ProcessingState.completed) {
        setState(() {
          _playing = false;
          if (_timing != null && _timing!.words.isNotEmpty) {
            _activeWord = _timing!.words.length - 1;
          }
        });
      }
    });
  }

  void _onPosition(Duration pos) {
    if (!mounted || _timing == null) return;
    // Small lead only for approx sync; real ASR packs are already timed.
    final look = (!_hasRealSync && _usingStream)
        ? pos + const Duration(milliseconds: 220)
        : pos;
    final i = _timing!.wordIndexAt(look);
    if (i != _activeWord) {
      setState(() => _activeWord = i);
      _scrollToActive(i);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SyncedZiaratPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ziaratId != widget.ziaratId ||
        oldWidget.streamUrl != widget.streamUrl ||
        oldWidget.audioSourceId != widget.audioSourceId) {
      _load();
    }
  }

  Future<void> _load() async {
    final gen = ++_gen;
    await _player.stop();
    if (!mounted || gen != _gen) return;
    setState(() {
      _loading = true;
      _audioReady = false;
      _usingStream = false;
      _hasRealSync = false;
      _error = null;
      _activeWord = -1;
      _playing = false;
      _timing = null;
    });

    ZiaratTiming? t;
    try {
      final all = await ZiaratTimings.load();
      t = all.ofId(widget.ziaratId);
    } catch (_) {
      t = null;
    }
    t ??= _fromFallbackText();
    if (t.words.isEmpty) t = _fromFallbackText();

    final fbWords = splitArabicWords(widget.fallbackText);
    if (fbWords.length > t.words.length) {
      t = ZiaratTiming(file: t.file, words: fbWords, segments: const []);
    }

    // Prefer ASR sync pack for this reciter (word↔word).
    final srcId = widget.audioSourceId;
    if (srcId != null && srcId.isNotEmpty) {
      final pack = await ZiaratTimings.loadStreamSync(
        ziaratId: widget.ziaratId,
        sourceId: srcId,
      );
      if (pack != null && pack.words.isNotEmpty) {
        t = pack;
        _hasRealSync = true;
      }
    }

    final preferStream =
        widget.streamUrl != null && widget.streamUrl!.isNotEmpty;

    if (!mounted || gen != _gen) return;
    final timing = t;
    _ensureWordKeys(timing.words.length);
    setState(() {
      _timing = timing;
      _loading = false;
    });

    var loaded = false;

    // Offline first: bundled Ashura reciter, then generic ziarat asset.
    final offlinePaths = <String>[
      if (srcId != null && srcId.isNotEmpty)
        'assets/audio/ziarat/ashura/$srcId.mp3',
      timing.assetPath,
    ];
    for (final path in offlinePaths) {
      try {
        await rootBundle.load(path);
        await _player.setAsset(path);
        if (!mounted || gen != _gen) return;
        setState(() => _timing = timing);
        await _wirePlayer();
        loaded = true;
        setState(() {
          _audioReady = true;
          _usingStream = false;
          _error = null;
        });
        break;
      } catch (_) {
        // try next path / stream
      }
    }

    if (!loaded && preferStream) {
      try {
        await _player
            .setUrl(widget.streamUrl!)
            .timeout(const Duration(seconds: 25));
        if (!mounted || gen != _gen) return;
        _usingStream = true;
        if (!_hasRealSync) {
          final approx = _wordsOnly(timing);
          setState(() => _timing = approx);
          _ensureWordKeys(approx.words.length);
        }
        await _wirePlayer();
        loaded = true;
        setState(() {
          _audioReady = true;
          _error = null;
        });
      } catch (_) {
        loaded = false;
      }
    }

    if (!loaded && mounted && gen == _gen) {
      setState(() {
        _audioReady = false;
        _error = Fa.audioLoadFail;
      });
    }
  }

  Future<void> _toggle() async {
    if (!_audioReady || _timing == null) {
      await _load();
      return;
    }
    if (_player.playing) {
      await _player.pause();
      return;
    }
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      setState(() => _activeWord = -1);
    }
    await _player.play();
  }

  @override
  void dispose() {
    _gen++;
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _scroll.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
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

    final t = _timing;
    final words = t?.words ?? const <String>[];
    _ensureWordKeys(words.length);
    final label = _usingStream
        ? widget.playLabel
        : (widget.streamUrl != null ? Fa.syncedPlay : widget.playLabel);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AudioTransportBar(
          player: _player,
          playing: _playing,
          enabled: _audioReady,
          onToggle: _toggle,
          playLabel: label,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTheme.latin(fontSize: 12, color: AppColors.danger),
          ),
        ],
        const SizedBox(height: 10),
        if (words.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              controller: _scroll,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 5,
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
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: SingleChildScrollView(
              child: Text(
                widget.fallbackText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTheme.arabic(
                  fontSize: 22,
                  height: 1.85,
                  color: AppColors.cream,
                ),
              ),
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
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
          fontSize: active ? 26 : 22,
          height: 1.55,
          color: active
              ? AppColors.gold
              : AppColors.cream.withValues(alpha: dimmed ? 0.4 : 1),
        ),
      ),
    );
  }
}
