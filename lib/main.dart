import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'providers/zekr_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.deepNight,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await NotificationService.instance.init();
  final zekrProvider = ZekrProvider();
  final settingsProvider = SettingsProvider();
  await Future.wait([
    zekrProvider.init(),
    settingsProvider.init(),
  ]);
  runApp(ZekrApp(
    zekrProvider: zekrProvider,
    settingsProvider: settingsProvider,
  ));
}

class ZekrApp extends StatelessWidget {
  const ZekrApp({
    super.key,
    required this.zekrProvider,
    required this.settingsProvider,
  });

  final ZekrProvider zekrProvider;
  final SettingsProvider settingsProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: zekrProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Zekr',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
