import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

enum AppThemeMode { dark, light }

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: AppTextStyles.fontFamily,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.accent,
          secondary: AppColors.accentMuted,
          error: AppColors.error,
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        dividerColor: AppColors.divider,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: AppTextStyles.title,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.displayTitle,
          titleLarge: AppTextStyles.title,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.caption,
          labelSmall: AppTextStyles.overline,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.accentSoft,
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.textPrimary : AppColors.textTertiary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.accent : AppColors.textTertiary,
            );
          }),
        ),
        sliderTheme: SliderThemeData(
          trackHeight: 3,
          activeTrackColor: AppColors.textPrimary,
          inactiveTrackColor: AppColors.trackInactive,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: const WidgetStatePropertyAll(AppColors.textPrimary),
          trackColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.trackInactive;
          }),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: AppColors.textPrimary,
          iconColor: AppColors.textSecondary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 0.6,
          space: 0.6,
        ),
      );

  // Placeholder for future light theme support — kept structurally identical
  // so screens built against ColorScheme/TextTheme require no rework.
  static ThemeData get light => dark;
}
