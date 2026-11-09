import 'package:shared_preferences/shared_preferences.dart';

/// Last Quran listening spot — survives leaving the screen or closing the app.
/// Only full surahs (`quran_s*`). Ayat al-Kursi / إن یکاد never overwrite this.
class QuranResume {
  const QuranResume({
    required this.zekrId,
    required this.partIndex,
    required this.positionMs,
    required this.titleFa,
    this.verseKey,
  });

  final String zekrId;
  final int partIndex;
  final int positionMs;
  final String titleFa;
  final String? verseKey;

  static const _kId = 'quran_resume_zekr';
  static const _kPart = 'quran_resume_part';
  static const _kPos = 'quran_resume_pos_ms';
  static const _kTitle = 'quran_resume_title';
  static const _kVerse = 'quran_resume_verse';

  static bool isSurahZekr(String zekrId) => zekrId.startsWith('quran_s');

  static Future<QuranResume?> load() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString(_kId);
    if (id == null || id.isEmpty) return null;
    // Drop stale extras if an older build saved them.
    if (!isSurahZekr(id)) {
      await clear();
      return null;
    }
    return QuranResume(
      zekrId: id,
      partIndex: p.getInt(_kPart) ?? 0,
      positionMs: p.getInt(_kPos) ?? 0,
      titleFa: p.getString(_kTitle) ?? id,
      verseKey: p.getString(_kVerse),
    );
  }

  static Future<void> save({
    required String zekrId,
    required int partIndex,
    required int positionMs,
    required String titleFa,
    String? verseKey,
  }) async {
    // Never replace surah resume with آیت‌الکرسی / إن یکاد.
    if (!isSurahZekr(zekrId)) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kId, zekrId);
    await p.setInt(_kPart, partIndex);
    await p.setInt(_kPos, positionMs < 0 ? 0 : positionMs);
    await p.setString(_kTitle, titleFa);
    if (verseKey != null) {
      await p.setString(_kVerse, verseKey);
    } else {
      await p.remove(_kVerse);
    }
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kId);
    await p.remove(_kPart);
    await p.remove(_kPos);
    await p.remove(_kTitle);
    await p.remove(_kVerse);
  }
}
