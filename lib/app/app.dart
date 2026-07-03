import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/settings/providers/settings_provider.dart';
import 'root_shell.dart';

class QuranMemoApp extends ConsumerWidget {
  const QuranMemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding = ref.watch(
      settingsControllerProvider.select(
        (s) => s.hasCompletedOnboarding ?? false,
      ),
    );
    final language = ref.watch(
      settingsControllerProvider.select(
        (settings) => AppLanguage.fromCode(settings.appLanguageCode),
      ),
    );

    return MaterialApp(
      title: 'Hifz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: language.locale,
      supportedLocales: AppLanguage.values.map((language) => language.locale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: hasCompletedOnboarding
          ? const RootShell()
          : const OnboardingScreen(),
    );
  }
}
