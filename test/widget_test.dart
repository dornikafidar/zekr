import 'package:flutter_test/flutter_test.dart';
import 'package:zekr/main.dart';
import 'package:zekr/providers/zekr_provider.dart';

void main() {
  testWidgets('App starts with home branding', (tester) async {
    final provider = ZekrProvider();
    // Skip full init (prefs/notifications) in unit test environment.
    await tester.pumpWidget(ZekrApp(provider: provider));
    await tester.pump();
    expect(find.text('Zekr'), findsOneWidget);
  });
}
