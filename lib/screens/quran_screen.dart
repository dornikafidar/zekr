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
  bool _ready = false;
  int? _selectedJuz; // null = juz grid or all when searching
  List<QuranPassage> _all = const [];
  List<JuzInfo> _juzs = const [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await ensureQuranDataLoaded();
    if (!mounted) return;
    setState(() {
      _all = loadQuranPassages();
      _juzs = loadJuzInfos();
      _ready = true;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(QuranPassage passage) async {
    final provider = context.read<ZekrProvider>();
    await provider.ensureQuranPassage(passage);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CounterScreen(zekrId: passage.id)),
    );
  }

  List<QuranPassage> get _surahsOnly =>
      _all.where((p) => p.id.startsWith('quran_s')).toList();

  List<QuranPassage> get _extrasOnly => _all
      .where((p) => p.id == 'quran_kursi' || p.id == 'quran_inyakad')
      .toList();

  Set<int> _surahNumsForJuz(int juz) => {
        ...(kJuzSurahNumbers[juz] ?? const <int>[]),
        for (final j in _juzs)
          if (j.juz == juz) ...j.surahNumbers,
      };

  List<QuranPassage> get _filteredSurahs {
    final q = _query.trim();
    var list = _surahsOnly;
    if (_selectedJuz != null) {
      final nums = _surahNumsForJuz(_selectedJuz!);
      list = list.where((p) => p.number != null && nums.contains(p.number)).toList();
    }
    if (q.isEmpty) return list;
    return list.where((p) {
      return p.title.contains(q) ||
          p.ref.contains(q) ||
          '${p.number}'.contains(q) ||
          p.id.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: AppColors.deepNight,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final searching = _query.trim().isNotEmpty;
    final showJuzGrid = _selectedJuz == null && !searching;

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
                      matchTextDirection: true,
                      onPressed: () {
                        if (_selectedJuz != null) {
                          setState(() => _selectedJuz = null);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        _selectedJuz == null
                            ? Fa.quran
                            : Fa.juzN(_selectedJuz!),
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
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Text(
                  Fa.quranPageHint,
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
              if (showJuzGrid) ...[
                if (_extrasOnly.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          Fa.favoritesExtra,
                          style: AppTheme.latin(
                            fontSize: 13,
                            weight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final p in _extrasOnly)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SurahTile(
                              passage: p,
                              onTap: () => _open(p),
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    Fa.juz,
                    style: AppTheme.latin(
                      fontSize: 13,
                      weight: FontWeight.w700,
                      color: AppColors.mist,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: 30,
                    itemBuilder: (context, i) {
                      final n = i + 1;
                      return Material(
                        color: AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _selectedJuz = n),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$n',
                                  style: AppTheme.latin(
                                    fontSize: 26,
                                    weight: FontWeight.w800,
                                    color: AppColors.gold,
                                  ),
                                ),
                                Text(
                                  Fa.juz,
                                  style: AppTheme.latin(
                                    fontSize: 12,
                                    color: AppColors.mist,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final passages = _filteredSurahs;
                      if (passages.isEmpty) {
                        return Center(
                          child: Text(
                            Fa.noSearchResults,
                            style: AppTheme.latin(color: AppColors.mist),
                          ),
                        );
                      }
                      return ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        itemCount: passages.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final p = passages[i];
                          return _SurahTile(
                            passage: p,
                            onTap: () => _open(p),
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

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.passage, required this.onTap});

  final QuranPassage passage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardElevated,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Text(
                  passage.number != null
                      ? '${passage.number}'
                      : '${passage.ayahs.length}',
                  style: AppTheme.latin(
                    fontSize: 13,
                    weight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
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
                      ),
                    ),
                    Text(
                      '${passage.ref} · ${passage.ayahs.length} ${Fa.ayah}'
                      '${passage.juz != null ? ' · ${Fa.juzN(passage.juz!)}' : ''}',
                      style: AppTheme.latin(
                        fontSize: 12,
                        color: AppColors.mist,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.mist,
                size: 15,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
