import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _fontScaleKey = 'font_scale';

  double _fontScale = 1.0;

  double get fontScale => _fontScale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value.clamp(0.85, 1.6);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, _fontScale);
    notifyListeners();
  }
}
