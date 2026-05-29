// stickman_theme.dart
// ─────────────────────────────────────────────────────────────────
// Event-tab leaderboard theme. Renders the top-3 podium with the
// new animated stickmen (champion / sprinter / climber) on a
// theatrical stage backdrop (stars, spotlights, confetti).
//
// Drop in at lib/screens/salesperon/leaderboard_themes/stickman_theme.dart
// ─────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import '../leaderboard_theme.dart';
import 'PodiumPainter.dart';

class StickmanPodium extends LeaderboardPodium {
  const StickmanPodium({
    super.key,
    required super.top1,
    required super.top2,
    required super.top3,
    required super.phase,
    required super.currentUid,
    required super.podiumHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        final maxD = podiumHeight * 0.62;
        final d1 = (totalW * 0.34).clamp(0.0, maxD);
        final d2 = (totalW * 0.26).clamp(0.0, maxD * 0.80);
        final d3 = (totalW * 0.24).clamp(0.0, maxD * 0.75);

        return SizedBox(
          height: podiumHeight,
          child: Stack(
            children: [
              // Animated theatrical backdrop covering the podium box.
              Positioned.fill(
                child: CustomPaint(
                  painter: _StageBgPainter(phase: phase),
                ),
              ),

              // Three podium slots arranged 2-1-3.
              OverflowBox(
                maxHeight: podiumHeight,
                alignment: Alignment.center,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PodiumSlot(rank: 2, doc: top2, diameter: d2, phase: phase, currentUid: currentUid),
                    SizedBox(width: totalW * 0.02),
                    PodiumSlot(rank: 1, doc: top1, diameter: d1, phase: phase, currentUid: currentUid),
                    SizedBox(width: totalW * 0.02),
                    PodiumSlot(rank: 3, doc: top3, diameter: d3, phase: phase, currentUid: currentUid),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// _StageBgPainter — twinkling stars, two soft spotlight beams
// sweeping the stage, confetti rain over the champion (center).
// ─────────────────────────────────────────────────────────────────
class _StageBgPainter extends CustomPainter {
  final double phase;
  _StageBgPainter({required this.phase});

  static const _stars = [
    Offset(0.08, 0.22),
    Offset(0.18, 0.12),
    Offset(0.30, 0.28),
    Offset(0.46, 0.18),
    Offset(0.56, 0.08),
    Offset(0.68, 0.24),
    Offset(0.82, 0.14),
    Offset(0.92, 0.30),
    Offset(0.12, 0.60),
    Offset(0.26, 0.70),
    Offset(0.40, 0.55),
    Offset(0.58, 0.65),
    Offset(0.74, 0.58),
    Offset(0.88, 0.70),
    Offset(0.06, 0.40),
    Offset(0.96, 0.48),
  ];

  static const _confettiColors = [
    Color(0xFFFFD700),
    Color(0xFF8DC21F),
    Color(0xFF00AEEF),
    Color(0xFFFFFFFF),
    Color(0xFFFF7043),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawGlow(canvas, w, h);
    _drawSpotlights(canvas, w, h);
    _drawStars(canvas, w, h);
    _drawConfetti(canvas, w, h);
  }

  // Floor glow + center halo
  void _drawGlow(Canvas canvas, double w, double h) {
    final base = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1),
        radius: 0.6,
        colors: [
          const Color(0xFF8DC21F).withValues(alpha: 0.22),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), base);

    final halo = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 0.55,
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.08),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), halo);
  }

  // Two sweeping spotlight beams
  void _drawSpotlights(Canvas canvas, double w, double h) {
    final beam = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFFF0B4).withValues(alpha: 0.0),
          const Color(0xFFFFF0B4).withValues(alpha: 0.18),
          const Color(0xFFFFF0B4).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(-w * 0.05, 0, w * 0.1, h * 1.4));

    final leftAngle = -0.31 + 0.52 * (sin(phase * pi) + 1) / 2; // -18° → +12°
    final rightAngle = 0.31 - 0.52 * (sin(phase * pi + 1.4) + 1) / 2;

    for (final tilt in [
      [-0.28, leftAngle],
      [0.28, rightAngle],
    ]) {
      canvas.save();
      final cx = w * (0.5 + tilt[0]);
      final cy = h;
      canvas.translate(cx, cy);
      canvas.rotate(tilt[1]);
      canvas.translate(-w * 0.05, -h * 1.4);
      canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.1, h * 1.4), beam);
      canvas.restore();
    }
  }

  // Twinkling stars
  void _drawStars(Canvas canvas, double w, double h) {
    final paint = Paint();
    for (int i = 0; i < _stars.length; i++) {
      final p = _stars[i];
      final t = (phase + i * 0.27) % 1.0;
      final pulse = (sin(t * 2 * pi) + 1) / 2; // 0..1
      final opacity = 0.15 + pulse * 0.85;
      final scale = 0.6 + pulse * 0.6;
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(p.dx * w, p.dy * h), 1.0 * scale, paint);
    }
  }

  // Confetti falling — concentrated around the center (over rank 1)
  void _drawConfetti(Canvas canvas, double w, double h) {
    for (int i = 0; i < 18; i++) {
      // X position biased toward center via a sin-based scatter
      final cxBase = 0.5 + sin(i * 12.9898) * 0.30;
      final fallDur = 2.6 + (i * 0.41) % 1.4; // arbitrary duration each
      final lifecycle = ((phase * 2 + i * 0.32) % fallDur) / fallDur; // 0..1

      if (lifecycle < 0.05 || lifecycle > 0.95) continue;
      final y = h * (lifecycle * 1.15 - 0.05);
      final x = w * cxBase;
      final color = _confettiColors[i % _confettiColors.length];
      final rot = (i * 47.0 + phase * 720) * pi / 180;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      final fill = Paint()..color = color.withValues(alpha: 0.92);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 5, height: 8),
          const Radius.circular(1),
        ),
        fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StageBgPainter old) => old.phase != phase;
}
