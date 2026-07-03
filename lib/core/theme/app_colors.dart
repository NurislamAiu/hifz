import 'package:flutter/material.dart';

/// Dark minimalist palette inspired by Apple Music / Spotify players.
abstract final class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0E1A);
  static const Color backgroundGradientTop = Color(0xFF141B33);
  static const Color surface = Color(0xFF121627);
  static const Color surfaceElevated = Color(0xFF1B2138);
  static const Color surfaceCard = Color(0xFF161B2E);

  // Accent
  static const Color accent = Color(0xFF5B7FFF);
  static const Color accentMuted = Color(0xFF3A4A85);
  static const Color accentSoft = Color(0x335B7FFF);

  // Text
  static const Color textPrimary = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFF8B93A7);
  static const Color textTertiary = Color(0xFF5C6478);

  // Utility
  static const Color divider = Color(0xFF232A42);
  static const Color success = Color(0xFF4CD97B);
  static const Color warning = Color(0xFFE8B94D);
  static const Color error = Color(0xFFE8604D);
  static const Color trackInactive = Color(0xFF262C42);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [background, backgroundGradientTop],
  );

  static LinearGradient playerGradient({Color? accentColor}) => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          background,
          Color.alphaBlend((accentColor ?? accent).withValues(alpha: 0.22), backgroundGradientTop),
        ],
      );
}
