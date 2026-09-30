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
  final _search = TextEditingController();
  String _query = '';
  late final List<QuranPassage> _all;

  @override
  void initState() {
    super.initState();
    _all = loadQuranPassages();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '${passages.length}',
                        style: AppTheme.latin(
                          fontSize: 13,
                          color: AppColors.mist,
                        ),
                      ),
                    ),
                  ],
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
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.mist,
                            ),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
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
                          final z =
                              context.watch<ZekrProvider>().byId(p.id);
                          final progress = z?.progress ?? 0.0;
                          return _QuranTile(
                            passage: p,
                            progress: progress,
                            onTap: () => _open(p),
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

class _QuranTile extends StatelessWidget {
  const _QuranTile({
    required this.passage,
    required this.progress,
    required this.onTap,
  });

  final QuranPassage passage;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF12332B),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF255447)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 3,
                      color: AppColors.gold,
                      backgroundColor: AppColors.cardBorder,
                    ),
                    Text(
                      '${passage.ayahs.length}',
                      style: AppTheme.latin(
                        fontSize: 11,
                        weight: FontWeight.w700,
                        color: AppColors.mint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passage.title,
                      style: AppTheme.latin(
                        fontSize: 16,
                        weight: FontWeight.w700,
                        color: AppColors.cream,
                      ),
                    ),
                    Text(
                      '${passage.ref} · ${passage.ayahs.length} ${Fa.ayah}',
                      style: AppTheme.latin(
                        fontSize: 12,
                        color: AppColors.mist,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      passage.ayahs.first,
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
            ],
          ),
        ),
      ),
    );
  }
}
