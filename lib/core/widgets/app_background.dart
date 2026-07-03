import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'aurora_background.dart';

/// The standard screen backdrop used everywhere: the app's dark gradient
/// plus the subtle animated aurora glow, so every screen shares the same
/// "alive" background rather than just the surahs/home screen.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.gradient,
    this.borderRadius,
  });

  final Widget child;
  final Gradient? gradient;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.backgroundGradient,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Stack(
          children: [
            const Positioned.fill(child: AuroraBackground()),
            child,
          ],
        ),
      ),
    );
  }
}
