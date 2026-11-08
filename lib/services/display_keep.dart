import 'package:flutter/services.dart';

/// Keep the screen awake while reading Quran (native FLAG_KEEP_SCREEN_ON).
class DisplayKeep {
  static const _ch = MethodChannel('zekr/display');

  static Future<void> setKeepScreenOn(bool on) async {
    try {
      await _ch.invokeMethod<void>('setKeepScreenOn', {'on': on});
    } catch (_) {}
  }
}
