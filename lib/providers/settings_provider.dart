import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _fontScaleKey = 'font_scale';
  static const _playbackSpeedKey = 'playback_speed';
  static const _ayahPauseSecKey = 'ayah_pause_sec';

  static const playbackSpeeds = <double>[0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  /// Max seconds to keep Farsi translation after an ayah (slider 0–60).
  static const ayahPauseMaxSec = 60;

  double _fontScale = 1.0;
  double _playbackSpeed = 1.0;
  int _ayahPauseSec = 3;

  double get fontScale => _fontScale;
  double get playbackSpeed => _playbackSpeed;
  int get ayahPauseSec => _ayahPauseSec;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    final s = prefs.getDouble(_playbackSpeedKey) ?? 1.0;
    _playbackSpeed = playbackSpeeds.contains(s) ? s : 1.0;
    _ayahPauseSec =
        (prefs.getInt(_ayahPauseSecKey) ?? 3).clamp(0, ayahPauseMaxSec);
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value.clamp(0.85, 1.6);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, _fontScale);
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double value) async {
    final nearest = playbackSpeeds.reduce(
      (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
    );
    if (nearest == _playbackSpeed) return;
    _playbackSpeed = nearest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_playbackSpeedKey, _playbackSpeed);
    notifyListeners();
  }

  Future<void> setAyahPauseSec(int value) async {
    final next = value.clamp(0, ayahPauseMaxSec);
    if (next == _ayahPauseSec) return;
    _ayahPauseSec = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ayahPauseSecKey, _ayahPauseSec);
    notifyListeners();
  }
}
