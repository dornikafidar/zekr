import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/quran_passages.dart';
import '../l10n/fa.dart';
import '../providers/zekr_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'counter_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late Future<List<QuranPassage>> _future;

  @override
  void initState() {
    super.initState();
    _future = loadQuranPassages();
  }

  Future<void> _open(QuranPassage passage) async {
    final provider = context.read<ZekrProvider>();
    if (provider.byId(passage.id) == null) {
      await provider.init();
    }
    if (!mounted) return;
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CounterScreen(zekrId: passage.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        Fa.quran,
                        textAlign: TextAlign.center,
                        style: AppTheme.latin(
                          fontSize: 18,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Text(
                  Fa.quranPageHint,
                  textAlign: TextAlign.center,
                  style: AppTheme.latin(fontSize: 13, color: AppColors.mist),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<QuranPassage>>(
                  future: _future,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      );
                    }
                    final passages = snap.data!;
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      itemCount: passages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = passages[i];
                        final z =
                            context.watch<ZekrProvider>().byId(p.id);
                        final progress = z?.progress ?? 0.0;
                        return GlassCard(
                          accent: i < 3,
                          onTap: () => _open(p),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Row(
                            children: [
                              ProgressRing(
                                progress: progress,
                                size: 46,
                                stroke: 4,
                                child: Text(
                                  '${p.ayahs.length}',
                                  style: AppTheme.latin(
                                    fontSize: 11,
                                    weight: FontWeight.w700,
                                    color: AppColors.mint,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.title,
                                      style: AppTheme.latin(
                                        fontSize: 15,
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
                                    const SizedBox(height: 6),
                                    Text(
                                      p.ayahs.first,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textDirection: TextDirection.rtl,
                                      style: AppTheme.arabic(
                                        fontSize: 15,
                                        color: AppColors.cream,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              StatusPill(
                                label: Fa.sayNow,
                                color: AppColors.mint,
                              ),
                            ],
                          ),
                        );
                      },
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
