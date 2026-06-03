
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';

enum StickmanMode { champion, sprinter, climber }

class PodiumSlot extends StatelessWidget {
  final int rank;
  final QueryDocumentSnapshot? doc;
  final double diameter;
  final double phase; // 0..1 from external climbController
  final String? currentUid;

  const PodiumSlot({
    super.key,
    required this.rank,
    required this.doc,
    required this.diameter,
    required this.phase,
    required this.currentUid,
  });

  StickmanMode get _mode {
    switch (rank) {
      case 1:
        return StickmanMode.champion;
      case 2:
        return StickmanMode.sprinter;
      default:
        return StickmanMode.climber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc?.data() as Map<String, dynamic>?;
    final firstName = data?['firstName'] ?? '';
    final lastName = data?['lastName'] ?? '';
    final name = '$firstName $lastName'.trim().isNotEmpty
        ? '$firstName $lastName'.trim()
        : '---';
    final points = data?['totalPoints'] ?? 0;
    final isMe = doc?.id == currentUid;

    final medalColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);

    final stickColor = isMe ? kSecondaryColor : Colors.white;
    final badgeSize = diameter * 0.22;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Pulsing glow ring (medal color)
            _PulseRing(
              size: diameter + 10,
              color: medalColor,
              phase: phase,
            ),

            // Circle with animated character
            ClipOval(
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: CustomPaint(
                  painter: StickmanScenePainter(
                    phase: phase,
                    stickColor: stickColor,
                    medalColor: medalColor,
                    rank: rank,
                    mode: _mode,
                  ),
                ),
              ),
            ),

            // Rank badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: medalColor,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),
        SizedBox(
          width: diameter,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isMe ? kSecondaryColor : Colors.white,
              fontSize: diameter * 0.09,
              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$points pts',
          style: TextStyle(color: Colors.white54, fontSize: diameter * 0.075),
        ),
      ],
    );
  }
}

// ─── Pulsing border ring ─────────────────────────────────────────
class _PulseRing extends StatelessWidget {
  final double size;
  final Color color;
  final double phase;
  const _PulseRing({required this.size, required this.color, required this.phase});

  @override
  Widget build(BuildContext context) {
    final pulse = (sin(phase * 2 * pi) + 1) / 2; // 0..1
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.6 + pulse * 0.3), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3 + pulse * 0.4),
            blurRadius: 12 + pulse * 6,
            spreadRadius: 1 + pulse * 2,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// StickmanScenePainter — paints background, podium, character, FX
// All animations are derived from `phase` (0..1 looping).
// ─────────────────────────────────────────────────────────────────
class StickmanScenePainter extends CustomPainter {
  final double phase;
  final Color stickColor;
  final Color medalColor;
  final int rank;
  final StickmanMode mode;

  const StickmanScenePainter({
    required this.phase,
    required this.stickColor,
    required this.medalColor,
    required this.rank,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawBackground(canvas, w, h);
    _drawAura(canvas, w, h);
    if (mode == StickmanMode.champion) _drawSparkles(canvas, w, h);
    _drawPodium(canvas, w, h);

    final stick = Paint()
      ..color = stickColor
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final headFill = Paint()
      ..color = stickColor
      ..style = PaintingStyle.fill;

    switch (mode) {
      case StickmanMode.champion:
        _drawChampion(canvas, w, h, stick, headFill);
        _drawImpactRing(canvas, w, h);
        break;
      case StickmanMode.sprinter:
        _drawSprinterFx(canvas, w, h);
        _drawSprinter(canvas, w, h, stick, headFill);
        _drawSideTrophy(canvas, w, h);
        break;
      case StickmanMode.climber:
        _drawClimberRungs(canvas, w, h);
        _drawClimberDust(canvas, w, h);
        _drawClimber(canvas, w, h, stick, headFill);
        _drawSideTrophy(canvas, w, h);
        break;
    }
  }

  // ── Background ──────────────────────────────────────────────────
  void _drawBackground(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.1),
        radius: 0.85,
        colors: const [Color(0xFF1B3A6B), Color(0xFF0A1A36)],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Tiny stars
    final star = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(w * 0.14, h * 0.18), w * 0.008, star);
    canvas.drawCircle(Offset(w * 0.78, h * 0.12), w * 0.007, star);
    canvas.drawCircle(Offset(w * 0.88, h * 0.34), w * 0.006, star);
    canvas.drawCircle(Offset(w * 0.06, h * 0.50), w * 0.008, star);
  }

  // ── Aura behind the character (pulses with the animation) ──────
  void _drawAura(Canvas canvas, double w, double h) {
    double t;
    switch (mode) {
      case StickmanMode.champion:
        t = sin(phase * pi).abs();
        break;
      case StickmanMode.sprinter:
        t = (sin(phase * 6 * pi) + 1) / 2;
        break;
      case StickmanMode.climber:
        t = (sin(phase * pi) + 1) / 2;
        break;
    }
    final rect = Rect.fromCircle(center: Offset(w * 0.5, h * 0.68), radius: w * 0.32);
    final p = Paint()
      ..shader = RadialGradient(
        colors: [
          medalColor.withValues(alpha: 0.18 + t * 0.22),
          medalColor.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.68),
      w * (0.22 + t * 0.10),
      p,
    );
  }

  // ── Champion sparkles ──────────────────────────────────────────
  void _drawSparkles(Canvas canvas, double w, double h) {
    const positions = [
      Offset(0.24, 0.32),
      Offset(0.76, 0.28),
      Offset(0.18, 0.54),
      Offset(0.82, 0.56),
      Offset(0.50, 0.18),
      Offset(0.36, 0.42),
      Offset(0.64, 0.44),
    ];
    final fill = Paint()..color = medalColor;
    for (int i = 0; i < positions.length; i++) {
      final t = (phase + i * 0.13) % 1.0;
      double scale, opacity;
      if (t < 0.4) {
        final k = t / 0.4;
        scale = 0.3 + k * 0.9;
        opacity = k;
      } else if (t < 0.75) {
        final k = (t - 0.4) / 0.35;
        scale = 1.2 - k * 0.5;
        opacity = 1 - k * 0.6;
      } else {
        scale = 0;
        opacity = 0;
      }
      if (opacity <= 0) continue;
      final p = positions[i];
      final cx = p.dx * w;
      final cy = p.dy * h;
      final r = w * 0.018 * scale;
      fill.color = medalColor.withValues(alpha: opacity);
      final path = Path()
        ..moveTo(cx, cy - r * 2.4)
        ..lineTo(cx + r * 0.6, cy - r * 0.6)
        ..lineTo(cx + r * 2.4, cy)
        ..lineTo(cx + r * 0.6, cy + r * 0.6)
        ..lineTo(cx, cy + r * 2.4)
        ..lineTo(cx - r * 0.6, cy + r * 0.6)
        ..lineTo(cx - r * 2.4, cy)
        ..lineTo(cx - r * 0.6, cy - r * 0.6)
        ..close();
      canvas.drawPath(path, fill);
    }
  }

  // ── Podium block ───────────────────────────────────────────────
  void _drawPodium(Canvas canvas, double w, double h) {
    final podiumH = h * 0.16;
    final podiumW = w * 0.66;
    final podiumTop = h - podiumH;
    final left = (w - podiumW) / 2;

    final fill = Paint()..color = medalColor.withValues(alpha: 0.35);
    final border = Paint()
      ..color = medalColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(left, podiumTop, podiumW, podiumH),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);

    final tp = TextPainter(
      text: TextSpan(
        text: '$rank',
        style: TextStyle(
          color: medalColor,
          fontSize: podiumH * 0.52,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(w / 2 - tp.width / 2, podiumTop + podiumH / 2 - tp.height / 2),
    );
  }

  // ── Champion ────────────────────────────────────────────────────
  void _drawChampion(Canvas canvas, double w, double h, Paint stick, Paint headFill) {
    final podiumTop = h * 0.84;
    final cx = w * 0.5;

    double jumpY;
    double squashY = 1.0;
    if (phase < 0.18) {
      final k = phase / 0.18;
      jumpY = 0;
      squashY = 1.0 - k * 0.18;
    } else if (phase < 0.5) {
      final k = (phase - 0.18) / 0.32;
      jumpY = -Curves.easeOutCubic.transform(k) * h * 0.32;
      squashY = 0.82 + k * 0.26;
    } else if (phase < 0.88) {
      final k = (phase - 0.5) / 0.38;
      jumpY = -h * 0.32 * (1 - Curves.easeInCubic.transform(k));
      squashY = 1.08 - k * 0.20;
    } else {
      final k = (phase - 0.88) / 0.12;
      jumpY = 0;
      squashY = 0.88 + k * 0.12;
    }

    final footY = podiumTop + jumpY;
    final headR = w * 0.10;
    final bodyLen = h * 0.16 * squashY;
    final legLen = h * 0.10;
    final armLen = w * 0.14;

    final bodyBotY = footY - legLen * 0.5;
    final bodyTopY = bodyBotY - bodyLen;
    final headCY = bodyTopY - headR;

    canvas.drawCircle(Offset(cx, headCY), headR, headFill);
    canvas.drawLine(Offset(cx, bodyTopY), Offset(cx, bodyBotY), stick);

    final wobble = sin(phase * 2 * pi) * 0.18;
    final handLx = cx - armLen * 0.4;
    final handRx = cx + armLen * 0.4;
    final handY = bodyTopY - armLen * (0.9 + wobble.abs() * 0.1);
    canvas.drawLine(Offset(cx, bodyTopY + bodyLen * 0.15), Offset(handLx, handY), stick);
    canvas.drawLine(Offset(cx, bodyTopY + bodyLen * 0.15), Offset(handRx, handY), stick);

    final apex = phase < 0.5
        ? (phase - 0.18).clamp(0, 0.32) / 0.32
        : (1 - (phase - 0.5) / 0.5);
    final tuck = (apex.clamp(0, 1).toDouble()) * 0.55;
    canvas.drawLine(
      Offset(cx, bodyBotY),
      Offset(cx - legLen * 0.4, bodyBotY + legLen * (1 - tuck)),
      stick,
    );
    canvas.drawLine(
      Offset(cx, bodyBotY),
      Offset(cx + legLen * 0.4, bodyBotY + legLen * (1 - tuck)),
      stick,
    );

    final trophyCx = cx;
    final trophyCy = handY - armLen * 0.2;
    final trophyAngle = sin(phase * 2 * pi) * 0.18;
    canvas.save();
    canvas.translate(trophyCx, trophyCy);
    canvas.rotate(trophyAngle);
    _drawHeroTrophy(canvas, w * 0.10, medalColor);
    canvas.restore();
  }

  // ── Champion impact ring on the podium at landing ──────────────
  void _drawImpactRing(Canvas canvas, double w, double h) {
    if (phase < 0.85) return;
    final k = (phase - 0.85) / 0.15;
    final paint = Paint()
      ..color = medalColor.withValues(alpha: 0.9 * (1 - k))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rx = w * (0.18 + k * 0.28);
    final ry = h * (0.025 + k * 0.025);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.84), width: rx * 2, height: ry * 2),
      paint,
    );
  }

  // ── Sprinter ────────────────────────────────────────────────────
  void _drawSprinter(Canvas canvas, double w, double h, Paint stick, Paint headFill) {
    final cx = w * 0.50;
    final footY = h * 0.82;

    final t = sin(phase * 4 * pi);

    canvas.save();
    canvas.translate(cx, footY);
    canvas.rotate(-0.14);
    canvas.translate(-cx, -footY);

    final bob = sin(phase * 8 * pi).abs() * h * 0.015;
    final fy = footY - bob;

    final headR = w * 0.10;
    final bodyLen = h * 0.16;
    final legLen = h * 0.12;
    final armLen = w * 0.13;

    final bodyBotY = fy - legLen * 0.4;
    final bodyTopY = bodyBotY - bodyLen;
    final headCY = bodyTopY - headR;

    canvas.drawCircle(Offset(cx, headCY), headR, headFill);
    canvas.drawLine(Offset(cx, bodyTopY), Offset(cx, bodyBotY), stick);

    final armSwing = t;
    final shoulderY = bodyTopY + bodyLen * 0.15;
    canvas.drawLine(
      Offset(cx, shoulderY),
      Offset(cx + armLen * armSwing * 0.7,
          shoulderY + armLen * (0.8 - armSwing.abs() * 0.5)),
      stick,
    );
    canvas.drawLine(
      Offset(cx, shoulderY),
      Offset(cx - armLen * armSwing * 0.7,
          shoulderY + armLen * (0.8 + armSwing.abs() * 0.5)),
      stick,
    );

    final legSwing = -t;
    canvas.drawLine(
      Offset(cx, bodyBotY),
      Offset(cx + legLen * legSwing * 0.7,
          bodyBotY + legLen * (0.85 - legSwing.abs() * 0.4)),
      stick,
    );
    canvas.drawLine(
      Offset(cx, bodyBotY),
      Offset(cx - legLen * legSwing * 0.7,
          bodyBotY + legLen * (0.85 + legSwing.abs() * 0.4)),
      stick,
    );

    canvas.restore();
  }

  void _drawSprinterFx(Canvas canvas, double w, double h) {
    for (int i = 0; i < 3; i++) {
      final t = (phase * 4 + i * 0.33) % 1.0;
      double opacity;
      double xOff;
      if (t < 0.4) {
        final k = t / 0.4;
        opacity = k;
        xOff = w * 0.12 * (1 - k);
      } else {
        final k = (t - 0.4) / 0.6;
        opacity = 1 - k;
        xOff = -w * 0.18 * k;
      }
      final p = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.55)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final y = h * (0.62 + i * 0.08);
      canvas.drawLine(Offset(w * 0.10 + xOff, y), Offset(w * 0.22 + xOff, y), p);
    }

    final st = phase % 1.0;
    if (st > 0.15 && st < 0.9) {
      final k = (st - 0.15) / 0.75;
      final opacity = k < 0.85 ? 1.0 : (1.0 - (k - 0.85) / 0.15);
      final paint = Paint()..color = const Color(0xFF7EC8F4).withValues(alpha: opacity);
      final outline = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.9)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke;
      final cx = w * (0.58 + k * 0.10);
      final cy = h * (0.46 + k * 0.30);
      final dr = w * 0.022;
      final path = Path()
        ..moveTo(cx, cy - dr)
        ..quadraticBezierTo(cx - dr * 0.6, cy + dr * 0.4, cx, cy + dr * 0.7)
        ..quadraticBezierTo(cx + dr * 0.6, cy + dr * 0.4, cx, cy - dr)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawPath(path, outline);
    }
  }

  // ── Climber ─────────────────────────────────────────────────────
  void _drawClimber(Canvas canvas, double w, double h, Paint stick, Paint headFill) {
    final pull = sin(phase * 2 * pi);
    final rise = -pull.clamp(-1.0, 1.0) * h * 0.05;
    final stretch = 1.0 + pull * 0.04;

    final cx = w * 0.50;
    final footY = h * 0.82 + rise;
    final headR = w * 0.10;
    final bodyLen = h * 0.16 * stretch;
    final legLen = h * 0.12;
    final armLen = w * 0.13;

    final bodyBotY = footY - legLen * 0.4;
    final bodyTopY = bodyBotY - bodyLen;
    final headCY = bodyTopY - headR;

    canvas.drawCircle(Offset(cx, headCY), headR, headFill);
    canvas.drawLine(Offset(cx, bodyTopY), Offset(cx, bodyBotY), stick);

    final aL = cos(phase * 2 * pi);
    final aR = -aL;
    final shoulderY = bodyTopY + bodyLen * 0.15;
    final reachL = aL > 0 ? -aL : -aL * 0.7;
    final reachR = aR > 0 ? -aR : -aR * 0.7;
    canvas.drawLine(
      Offset(cx, shoulderY),
      Offset(cx - armLen * 0.4, shoulderY + armLen * reachL),
      stick,
    );
    canvas.drawLine(
      Offset(cx, shoulderY),
      Offset(cx + armLen * 0.4, shoulderY + armLen * reachR),
      stick,
    );

    final lL = -cos(phase * 2 * pi);
    final lR = -lL;
    canvas.drawLine(
      Offset(cx, bodyBotY),
      Offset(cx - legLen * 0.35, bodyBotY + legLen * (0.85 + lL * 0.25)),
      stick,
    );
    canvas.drawLine(
      Offset(cx, bodyBotY),
      Offset(cx + legLen * 0.35, bodyBotY + legLen * (0.85 + lR * 0.25)),
      stick,
    );
  }

  void _drawClimberRungs(Canvas canvas, double w, double h) {
    final p = Paint()
      ..color = medalColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.68, h * 0.38), Offset(w * 0.82, h * 0.38), p);
    canvas.drawLine(Offset(w * 0.68, h * 0.54), Offset(w * 0.82, h * 0.54), p);
    canvas.drawLine(Offset(w * 0.68, h * 0.70), Offset(w * 0.82, h * 0.70), p);
  }

  void _drawClimberDust(Canvas canvas, double w, double h) {
    final t = (phase * 1.0) % 1.0;
    if (t < 0.25 || t > 0.95) return;
    final k = (t - 0.25) / 0.70;
    final opacity = (k < 0.5 ? k * 2 : (1 - (k - 0.5) * 2)).clamp(0.0, 1.0);
    final scale = 0.6 + k * 0.8;
    final p = Paint()..color = Colors.white.withValues(alpha: 0.35 * opacity);
    canvas.drawCircle(Offset(w * 0.55, h * 0.83), w * 0.025 * scale, p);
    canvas.drawCircle(Offset(w * 0.58, h * 0.84), w * 0.018 * scale, p);
    canvas.drawCircle(Offset(w * 0.52, h * 0.84), w * 0.015 * scale, p);
  }

  // ── Side trophy (sprinter + climber) ───────────────────────────
  void _drawSideTrophy(Canvas canvas, double w, double h) {
    final s = w * 0.07;
    _drawTrophyAt(canvas, w * 0.84, h * 0.62, s, medalColor);
  }

  void _drawTrophyAt(Canvas canvas, double cx, double cy, double s, Color color) {
    final outline = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final cup = Path()
      ..moveTo(cx - s, cy - s * 0.9)
      ..lineTo(cx - s, cy + s * 0.1)
      ..quadraticBezierTo(cx - s, cy + s * 0.9, cx, cy + s * 0.9)
      ..quadraticBezierTo(cx + s, cy + s * 0.9, cx + s, cy + s * 0.1)
      ..lineTo(cx + s, cy - s * 0.9)
      ..close();
    canvas.drawPath(cup, fill);
    canvas.drawPath(cup, outline);

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - s, cy), width: s * 1.0, height: s * 0.9),
      pi / 2, pi, false, outline,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + s, cy), width: s * 1.0, height: s * 0.9),
      -pi / 2, pi, false, outline,
    );
    canvas.drawLine(Offset(cx, cy + s * 0.9), Offset(cx, cy + s * 1.4), outline);
    canvas.drawLine(
      Offset(cx - s * 0.75, cy + s * 1.4),
      Offset(cx + s * 0.75, cy + s * 1.4),
      outline,
    );
  }

  void _drawHeroTrophy(Canvas canvas, double s, Color color) {
    final outline = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final cup = Path()
      ..moveTo(-s, -s * 0.8)
      ..lineTo(-s, s * 0.2)
      ..quadraticBezierTo(-s, s * 1.0, 0, s * 1.0)
      ..quadraticBezierTo(s, s * 1.0, s, s * 0.2)
      ..lineTo(s, -s * 0.8)
      ..close();
    canvas.drawPath(cup, fill);
    canvas.drawPath(cup, outline);

    canvas.drawArc(Rect.fromCenter(center: Offset(-s, 0), width: s, height: s), pi / 2, pi, false, outline);
    canvas.drawArc(Rect.fromCenter(center: Offset(s, 0),  width: s, height: s), -pi / 2, pi, false, outline);
    canvas.drawLine(Offset(0, s * 1.0), Offset(0, s * 1.5), outline);
    canvas.drawLine(Offset(-s * 0.8, s * 1.5), Offset(s * 0.8, s * 1.5), outline);
  }

  @override
  bool shouldRepaint(covariant StickmanScenePainter old) =>
      old.phase != phase ||
      old.stickColor != stickColor ||
      old.medalColor != medalColor ||
      old.rank != rank ||
      old.mode != mode;
}
