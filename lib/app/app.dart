import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_strings.dart';
import '../core/platform_info.dart';
import '../core/theme/app_theme.dart';
import '../features/desktop/presentation/mac_desktop_shell.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/settings/providers/settings_provider.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import 'root_shell.dart';

class QuranMemoApp extends ConsumerWidget {
  const QuranMemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      home: const _SplashGate(),
    );
  }
}

/// Shows the animated [SplashScreen] on launch, then cross-fades into the real
/// entry point once the intro has played.
class _SplashGate extends ConsumerStatefulWidget {
  const _SplashGate();

  @override
  ConsumerState<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<_SplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  Widget _destination() {
    if (isMacDesktop) return const MacDesktopShell();
    final hasCompletedOnboarding = ref.watch(
      settingsControllerProvider.select(
        (s) => s.hasCompletedOnboarding ?? false,
      ),
    );
    return hasCompletedOnboarding
        ? const RootShell()
        : const OnboardingScreen();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _ready
          ? _destination()
          : const SplashScreen(key: ValueKey('splash')),
    );
  }
}
