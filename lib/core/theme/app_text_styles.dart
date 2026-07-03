import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Large, bold typography matching the player-first reference design.
abstract final class AppTextStyles {
  static const String fontFamily = '.SF Pro Display';

  static const TextStyle displayTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 1.1,
  );

  static const String arabicFontFamily = 'NotoNaskhArabic';

  static const TextStyle arabic = TextStyle(
    fontFamily: arabicFontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.9,
  );

  static const String transliterationFontFamily = 'GentiumBookPlus';

  static const TextStyle transliteration = TextStyle(
    fontFamily: transliterationFontFamily,
    fontSize: 16.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
    letterSpacing: 0.1,
  );
}
