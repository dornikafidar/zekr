import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../l10n/fa.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Shared play / pause / ±10s / speed / scrubber for Quran + Ziarat.
class AudioTransportBar extends StatefulWidget {
  const AudioTransportBar({
    super.key,
    required this.player,
    required this.playing,
    required this.enabled,
    required this.onToggle,
    this.playLabel = Fa.play,
    this.retryLabel = Fa.retryAudio,
  });

  final AudioPlayer player;
  final bool playing;
  final bool enabled;
  final VoidCallback onToggle;
  final String playLabel;
  final String retryLabel;

  @override
  State<AudioTransportBar> createState() => _AudioTransportBarState();
}

class _AudioTransportBarState extends State<AudioTransportBar> {
  bool _scrubbing = false;
  double? _scrubMs;

  Future<void> _applySpeed(double speed) async {
    try {
      if ((widget.player.speed - speed).abs() > 0.01) {
        await widget.player.setSpeed(speed);
      }
    } catch (_) {}
  }

  Future<void> _seekBy(int seconds) async {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();
    final dur = widget.player.duration ?? Duration.zero;
    final next = widget.player.position + Duration(seconds: seconds);
    final ms = next.inMilliseconds.clamp(0, dur.inMilliseconds);
    await widget.player.seek(Duration(milliseconds: ms));
  }

  Future<void> _setSpeed(double speed) async {
    HapticFeedback.selectionClick();
    await context.read<SettingsProvider>().setPlaybackSpeed(speed);
    await _applySpeed(speed);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final speed = context.watch<SettingsProvider>().playbackSpeed;
    // Keep player rate in sync with saved setting (Quran + Ziarat).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applySpeed(speed);
    });

    if (!widget.enabled) {
      return FilledButton.tonalIcon(
        onPressed: widget.onToggle,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(
          widget.retryLabel,
          style: AppTheme.latin(weight: FontWeight.w700),
        ),
      );
    }

    return Column(
      children: [
        StreamBuilder<Duration?>(
          stream: widget.player.durationStream,
          builder: (context, durSnap) {
            final dur = durSnap.data ?? widget.player.duration ?? Duration.zero;
            final maxMs =
                dur.inMilliseconds < 1 ? 1.0 : dur.inMilliseconds.toDouble();
            return StreamBuilder<Duration>(
              stream: widget.player.positionStream,
              builder: (context, posSnap) {
                final pos = posSnap.data ?? widget.player.position;
                final live = pos.inMilliseconds.toDouble().clamp(0.0, maxMs);
                final value = _scrubbing ? (_scrubMs ?? live) : live;
                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: AppColors.gold,
                        inactiveTrackColor: AppColors.cardBorder,
                        thumbColor: AppColors.gold,
                      ),
                      child: Slider(
                        min: 0,
                        max: maxMs,
                        value: value,
                        onChangeStart: (_) => setState(() {
                          _scrubbing = true;
                          _scrubMs = value;
                        }),
                        onChanged: (v) => setState(() => _scrubMs = v),
                        onChangeEnd: (v) async {
                          await widget.player
                              .seek(Duration(milliseconds: v.round()));
                          if (mounted) {
                            setState(() {
                              _scrubbing = false;
                              _scrubMs = null;
                            });
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Text(
                            _fmt(Duration(milliseconds: value.round())),
                            style: AppTheme.latin(
                              fontSize: 11,
                              color: AppColors.mist,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _fmt(dur),
                            style: AppTheme.latin(
                              fontSize: 11,
                              color: AppColors.mist,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: Fa.seekBack10,
              onPressed: () => _seekBy(-10),
              icon: const Icon(Icons.replay_10_rounded),
              color: AppColors.cream,
            ),
            const SizedBox(width: 4),
            FilledButton.tonalIcon(
              onPressed: widget.onToggle,
              icon: Icon(
                widget.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(
                widget.playing ? Fa.pause : widget.playLabel,
                style: AppTheme.latin(weight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: Fa.seekForward10,
              onPressed: () => _seekBy(10),
              icon: const Icon(Icons.forward_10_rounded),
              color: AppColors.cream,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in SettingsProvider.playbackSpeeds)
              ChoiceChip(
                label: Text(
                  '$s×',
                  style: AppTheme.latin(
                    fontSize: 12,
                    weight: FontWeight.w700,
                  ),
                ),
                selected: (s - speed).abs() < 0.01,
                onSelected: (_) => _setSpeed(s),
                selectedColor: AppColors.gold.withValues(alpha: 0.28),
                backgroundColor: AppColors.cardElevated,
                side: BorderSide(
                  color: (s - speed).abs() < 0.01
                      ? AppColors.gold
                      : AppColors.cardBorder,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
      ],
    );
  }
}
