import 'package:flutter/material.dart';

/// Soft flat, pastel-turquoise palette used by the Home tab and the shared
/// nav bar — the rest of the app's screens still run on the dark
/// [AppColors] theme, so widgets using this palette paint their own opaque
/// light background to cover the dark Scaffold behind them.
abstract final class SoftPalette {
  static const Color primary = Color(0xFF159AA6);
  static const Color primaryDark = Color(0xFF0E7A84);
  static const Color light = Color(0xFFBFECEF);
  static const Color background = Color(0xFFEAF8F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF8A9A9D);
  static const Color track = Color(0xFFDFF3F4);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF3FB6BE), light],
    stops: [0.0, 0.55, 1.0],
  );

  static List<BoxShadow> softShadow({
    double opacity = 0.07,
    double y = 10,
    double blur = 22,
  }) => [
    BoxShadow(
      color: Color.fromRGBO(15, 60, 65, opacity),
      offset: Offset(0, y),
      blurRadius: blur,
    ),
  ];
}
