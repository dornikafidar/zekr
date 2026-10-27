import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ziarat_places.dart';
import '../l10n/fa.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/synced_ziarat_player.dart';

class ZiaratDetailScreen extends StatefulWidget {
  const ZiaratDetailScreen({super.key, required this.place});

  final ZiaratPlace place;

  @override
  State<ZiaratDetailScreen> createState() => _ZiaratDetailScreenState();
}

class _ZiaratDetailScreenState extends State<ZiaratDetailScreen> {
  late ZiaratItem _current;
  int _audioIndex = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.place.ziarat.first;
    _audioIndex = _defaultAudioIndex(_current);
  }

  int _defaultAudioIndex(ZiaratItem z) {
    final sources = z.resolvedAudioSources;
    final i = sources.indexWhere((s) => s.labelFa.contains('ارضی'));
    return i >= 0 ? i : 0;
  }

  void _selectZiarat(ZiaratItem z) {
    HapticFeedback.selectionClick();
    setState(() {
      _current = z;
      _audioIndex = _defaultAudioIndex(z);
    });
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final sources = _current.resolvedAudioSources;
    final selected = sources.isEmpty
        ? null
        : sources[_audioIndex.clamp(0, sources.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    BackCircleButton(onPressed: () => Navigator.pop(context)),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            place.nameFa,
                            textAlign: TextAlign.center,
                            style: AppTheme.latin(
                              fontSize: 18,
                              weight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            place.cityFa,
                            style: AppTheme.latin(
                              fontSize: 12,
                              color: AppColors.mist,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  children: [
                    Text(
                      place.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.latin(
                        fontSize: 13,
                        color: AppColors.mist,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      Fa.ziaratList,
                      style: AppTheme.latin(
                        fontSize: 13,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final z in place.ziarat)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: z.id == _current.id
                              ? AppColors.gold.withValues(alpha: 0.12)
                              : AppColors.cardElevated,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _selectZiarat(z),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: z.id == _current.id
                                      ? AppColors.gold
                                      : AppColors.cardBorder,
                                  width: z.id == _current.id ? 1.6 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.headphones_rounded,
                                    color: z.id == _current.id
                                        ? AppColors.gold
                                        : AppColors.mist,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      z.titleFa,
                                      style: AppTheme.latin(
                                        fontSize: 15,
                                        weight: FontWeight.w700,
                                        color: z.id == _current.id
                                            ? AppColors.cream
                                            : AppColors.mist,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.mint.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      Fa.hasAudio,
                                      style: AppTheme.latin(
                                        fontSize: 11,
                                        weight: FontWeight.w700,
                                        color: AppColors.mint,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (sources.length > 1) ...[
                      const SizedBox(height: 8),
                      Text(
                        Fa.selectAudio,
                        style: AppTheme.latin(
                          fontSize: 13,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        textDirection: TextDirection.rtl,
                        children: [
                          for (var i = 0; i < sources.length; i++)
                            ChoiceChip(
                              label: Text(
                                sources[i].labelFa,
                                style: AppTheme.latin(
                                  fontSize: 12,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              selected: i == _audioIndex,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _audioIndex = i);
                              },
                              selectedColor:
                                  AppColors.gold.withValues(alpha: 0.28),
                              backgroundColor: AppColors.cardElevated,
                              side: BorderSide(
                                color: i == _audioIndex
                                    ? AppColors.gold
                                    : AppColors.cardBorder,
                              ),
                              labelStyle: TextStyle(
                                color: i == _audioIndex
                                    ? AppColors.cream
                                    : AppColors.mist,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'صد مرتبهٔ لعن و سلام در متن یک‌بار آمده — هنگام قرائت تکرار کنید.',
                        textAlign: TextAlign.center,
                        style: AppTheme.latin(
                          fontSize: 11,
                          color: AppColors.mist,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Sticky player: progress / ±10s / play always visible.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: SyncedZiaratPlayer(
                    key: ValueKey(
                      '${_current.id}|${selected?.id ?? ''}|${selected?.url ?? ''}',
                    ),
                    ziaratId: _current.id,
                    fallbackText: _current.arabicPreview,
                    streamUrl: selected?.url,
                    audioSourceId: selected?.id,
                    playLabel: selected?.labelFa ?? Fa.syncedPlay,
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
