import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class _Blob {
  final Color color;
  final double size;
  final Alignment base;
  final double ampX;
  final double ampY;
  final double freqX;
  final double freqY;
  final double phase;

  const _Blob({
    required this.color,
    required this.size,
    required this.base,
    required this.ampX,
    required this.ampY,
    required this.freqX,
    required this.freqY,
    required this.phase,
  });
}

final _blobs = [
  _Blob(
    color: AppColors.accent,
    size: 320,
    base: const Alignment(-0.9, -1.0),
    ampX: 0.30,
    ampY: 0.24,
    freqX: 1,
    freqY: 1,
    phase: 0,
  ),
  _Blob(
    color: const Color(0xFF6B5CE0),
    size: 280,
    base: const Alignment(1.0, -0.4),
    ampX: 0.24,
    ampY: 0.30,
    freqX: 1,
    freqY: 2,
    phase: math.pi / 2,
  ),
  _Blob(
    color: AppColors.accentMuted,
    size: 360,
    base: const Alignment(-0.5, 1.1),
    ampX: 0.20,
    ampY: 0.26,
    freqX: 1,
    freqY: 1,
    phase: math.pi * 1.5,
  ),
];

/// A soft, continuously-drifting blurred glow behind screen content — the
/// same "living gradient" language Apple Music / Yandex Music use on their
/// now-playing surfaces. Blobs move on gentle Lissajous paths (sums of sines,
/// not simple back-and-forth) and the whole layer is blurred once via
/// [ImageFiltered] so it reads as a smooth melting glow rather than distinct
/// circles — a single blur pass per frame, not a per-pixel backdrop sample,
/// so it stays cheap enough to animate continuously.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 38),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * math.pi;
              return Stack(
                children: [
                  for (final blob in _blobs)
                    Align(
                      alignment: Alignment(
                        (blob.base.x +
                                blob.ampX *
                                    math.sin(t * blob.freqX + blob.phase))
                            .clamp(-1.6, 1.6),
                        (blob.base.y +
                                blob.ampY *
                                    math.cos(t * blob.freqY + blob.phase))
                            .clamp(-1.6, 1.6),
                      ),
                      child: Container(
                        width: blob.size,
                        height: blob.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: blob.color.withValues(alpha: 0.32),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
