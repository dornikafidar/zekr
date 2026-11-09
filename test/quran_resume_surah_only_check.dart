import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/data/quran_passages.dart';
import 'package:zekr/services/quran_resume.dart';

void main() {
  test('resume only tracks full surahs, not kursi/inyakad', () {
    expect(QuranResume.isSurahZekr('quran_s2'), isTrue);
    expect(QuranResume.isSurahZekr('quran_s114'), isTrue);
    expect(QuranResume.isSurahZekr('quran_kursi'), isFalse);
    expect(QuranResume.isSurahZekr('quran_inyakad'), isFalse);
  });

  test('juzForResume falls back to first juz containing surah', () {
    expect(
      juzForResume(zekrId: 'quran_s1', verseKey: null),
      1,
    );
    expect(
      juzForResume(zekrId: 'quran_s112', verseKey: null),
      30,
    );
  });
}
