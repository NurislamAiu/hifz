import 'dart:ui';

import 'package:flutter/material.dart';

/// A frosted-glass surface (iOS "Liquid Glass" style): a blurred backdrop,
/// a subtle tint, and a thin light-catching border on top.
///
/// Keep usage to a handful of floating/static chrome elements (nav bars,
/// pill badges, modal sheets) — [BackdropFilter] is a real GPU cost per
/// instance, so it shouldn't be applied to individual list items.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blurSigma = 24,
    this.tintColor,
    this.tintOpacity = 0.35,
    this.borderOpacity = 0.14,
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final double tintOpacity;
  final double borderOpacity;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tint = tintColor ?? Colors.white;
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: borderOpacity)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint.withValues(alpha: tintOpacity * 0.5),
                Colors.black.withValues(alpha: 0.28),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
