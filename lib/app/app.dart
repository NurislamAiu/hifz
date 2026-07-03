import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/settings/providers/settings_provider.dart';
import 'root_shell.dart';

class QuranMemoApp extends ConsumerWidget {
  const QuranMemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompletedOnboarding =
        ref.watch(settingsControllerProvider.select((s) => s.hasCompletedOnboarding ?? false));

    return MaterialApp(
      title: 'Hifz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: hasCompletedOnboarding ? const RootShell() : const OnboardingScreen(),
    );
  }
}
