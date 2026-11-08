import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'providers/quran_reading_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/zekr_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.zekr.zekr.audio',
    androidNotificationChannelName: 'تلاوت قرآن',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
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
  final quranReading = QuranReadingProvider();
  await Future.wait([
    zekrProvider.init(),
    settingsProvider.init(),
    quranReading.init(),
  ]);
  runApp(ZekrApp(
    zekrProvider: zekrProvider,
    settingsProvider: settingsProvider,
    quranReading: quranReading,
  ));
}

class ZekrApp extends StatelessWidget {
  const ZekrApp({
    super.key,
    required this.zekrProvider,
    required this.settingsProvider,
    required this.quranReading,
  });

  final ZekrProvider zekrProvider;
  final SettingsProvider settingsProvider;
  final QuranReadingProvider quranReading;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: zekrProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: quranReading),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'ذکر',
            debugShowCheckedModeBanner: false,
            locale: const Locale('fa'),
            supportedLocales: const [
              Locale('fa'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.dark,
            // Force RTL for the whole tree (Farsi-first app).
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(settings.fontScale),
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
