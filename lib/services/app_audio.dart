import 'package:just_audio/just_audio.dart';

/// Single shared player — required by just_audio_background.
class AppAudio {
  AppAudio._();
  static final player = AudioPlayer();
}
