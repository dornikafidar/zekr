import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/main.dart';
import 'package:zekr/providers/settings_provider.dart';
import 'package:zekr/providers/zekr_provider.dart';

void main() {
  testWidgets('App starts with home branding', (tester) async {
    final zekrProvider = ZekrProvider();
    final settingsProvider = SettingsProvider();
    await tester.pumpWidget(ZekrApp(
      zekrProvider: zekrProvider,
      settingsProvider: settingsProvider,
    ));
    await tester.pump();
    expect(find.text('Zekr'), findsOneWidget);
    expect(find.text('ذکر'), findsOneWidget);
  });
}
