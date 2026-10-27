import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/data/recitation_timings.dart';

void main() {
  test('splitArabicWords keeps ayah tokens', () {
    const t =
        'يَسْأَلُونَكَ عَنِ ٱلْأَنفَالِ ۖ قُلِ ٱلْأَنفَالُ لِلَّهِ وَٱلرَّسُولِ';
    final w = splitArabicWords(t);
    expect(w.length, greaterThanOrEqualTo(5));
    expect(w.first, contains('يَسْأَلُونَكَ'));
  });

  test('approxWordSegments cover full duration', () {
    final words = splitArabicWords('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');
    final segs = approxWordSegments(words, 4000);
    expect(segs.length, words.length);
    expect(segs.first[1], 0);
    expect(segs.last[2], 4000);
    for (var i = 0; i < segs.length; i++) {
      expect(segs[i][0], i);
      expect(segs[i][2], greaterThan(segs[i][1]));
    }
  });

  test('syncDurationForDisplayedWords compresses 100x-padded audio', () {
    // 20 min file / 600 shown words → would be ~2s/word without cap.
    final capped = syncDurationForDisplayedWords(20 * 60 * 1000, 600);
    expect(capped, lessThan(20 * 60 * 1000));
    expect(capped, 600 * 360);
    expect(syncDurationForDisplayedWords(600 * 400, 600), 600 * 400);
  });
}
