import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/quran_passages.dart';
import '../data/recitation_timings.dart';
import '../l10n/fa.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'counter_screen.dart';

/// Dedicated Abdul Basit tilawah menu for all surahs + extras.
class TilawahScreen extends StatefulWidget {
  const TilawahScreen({super.key});

  @override
  State<TilawahScreen> createState() => _TilawahScreenState();
}

class _TilawahScreenState extends State<TilawahScreen> {
  final _search = TextEditingController();
  String _query = '';
  bool _ready = false;
  List<QuranPassage> _all = const [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await ensureQuranDataLoaded();
    if (!mounted) return;
    setState(() {
      _all = loadQuranPassages().where((p) => hasAudioForZekr(p.id)).toList();
      _ready = true;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(QuranPassage passage) async {
    await context.read<ZekrProvider>().ensureQuranPassage(passage);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CounterScreen(zekrId: passage.id)),
    );
  }

  List<QuranPassage> get _filtered {
    final q = _query.trim();
    if (q.isEmpty) return _all;
    return _all.where((p) {
      return p.title.contains(q) ||
          p.ref.contains(q) ||
          p.text.contains(q) ||
          p.id.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.deepNight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }
    final passages = _filtered;
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
                      child: Text(
                        Fa.tilawah,
                        textAlign: TextAlign.center,
                        style: AppTheme.latin(
                          fontSize: 18,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${passages.length}',
                      style: AppTheme.latin(
                        fontSize: 13,
                        color: AppColors.mist,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  Fa.tilawahPageHint,
                  textAlign: TextAlign.center,
                  style: AppTheme.latin(fontSize: 12, color: AppColors.mist),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  style: AppTheme.latin(color: AppColors.cream),
                  cursorColor: AppColors.gold,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardElevated,
                    hintText: Fa.searchQuran,
                    hintStyle: AppTheme.latin(color: AppColors.mist),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: passages.isEmpty
                    ? Center(
                        child: Text(
                          Fa.noSearchResults,
                          style: AppTheme.latin(color: AppColors.mist),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        itemCount: passages.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final p = passages[i];
                          return Material(
                            color: AppColors.cardElevated,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              onTap: () => _open(p),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.headphones_rounded,
                                      color: AppColors.gold,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.title,
                                            style: AppTheme.latin(
                                              fontSize: 16,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            '${p.ref} · ${p.ayahs.length} ${Fa.ayah}',
                                            style: AppTheme.latin(
                                              fontSize: 12,
                                              color: AppColors.mist,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: AppColors.gold,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
