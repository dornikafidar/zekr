import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/data/quran_passages.dart';
import 'package:zekr/data/recitation_timings.dart';

void main() {
  test('kursi / inyakad map Bismillah then ayah keys', () {
    final kursi = withLeadingBismillah(const [
      'ٱللَّهُ لَآ إِلَٰهَ',
      'لَآ إِكْرَاهَ',
      'ٱللَّهُ وَلِىُّ',
    ], surah: 2);
    expect(audioVerseKey('quran_kursi', 0, partTexts: kursi), 'bismillah');
    expect(audioVerseKey('quran_kursi', 1, partTexts: kursi), '2:255');
    expect(audioVerseKey('quran_kursi', 2, partTexts: kursi), '2:256');
    expect(audioVerseKey('quran_kursi', 3, partTexts: kursi), '2:257');

    final inyakad = withLeadingBismillah(const [
      'وَإِن يَكَادُ',
      'وَمَا هُوَ',
    ], surah: 68);
    expect(audioVerseKey('quran_inyakad', 0, partTexts: inyakad), 'bismillah');
    expect(audioVerseKey('quran_inyakad', 1, partTexts: inyakad), '68:51');
    expect(audioVerseKey('quran_inyakad', 2, partTexts: inyakad), '68:52');
  });

  test('surah with leading Bismillah uses partIndex as ayah', () {
    final parts = [kBismillah, 'قُلْ هُوَ', 'ٱللَّهُ ٱلصَّمَدُ'];
    expect(audioVerseKey('quran_s112', 0, partTexts: parts), 'bismillah');
    expect(audioVerseKey('quran_s112', 1, partTexts: parts), '112:1');
    expect(audioVerseKey('quran_s112', 2, partTexts: parts), '112:2');
  });
}
