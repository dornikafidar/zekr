// ponytail: one assert-based check for word timing lookup.
import '../lib/data/recitation_timings.dart';

void main() {
  const t = AyahTiming(
    file: 'x.mp3',
    words: ['a', 'b', 'c'],
    segments: [
      [0, 100, 200],
      [1, 200, 350],
      [2, 350, 500],
    ],
  );
  assert(t.wordIndexAt(const Duration(milliseconds: 50)) == -1);
  assert(t.wordIndexAt(const Duration(milliseconds: 150)) == 0);
  assert(t.wordIndexAt(const Duration(milliseconds: 250)) == 1);
  assert(t.wordIndexAt(const Duration(milliseconds: 400)) == 2);
  assert(t.wordIndexAt(const Duration(milliseconds: 600)) == 2);
  // ignore: avoid_print
  print('recitation_timings_check ok');
}
