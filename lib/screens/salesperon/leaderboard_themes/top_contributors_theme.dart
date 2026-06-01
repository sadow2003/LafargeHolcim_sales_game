// top_contributors_theme.dart
// ─────────────────────────────────────────────────────────────────
// Transit-inspired "Top Contributors" leaderboard theme.
// Circular avatars with initials, animated crown for 1st place,
// and medal-coloured rank ribbons on a deep-blue particle background.
// ─────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import 'leaderboard_theme.dart';

// ─── Public podium widget ─────────────────────────────────────────
class TopContributorsPodium extends LeaderboardPodium {
  const TopContributorsPodium({
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
    return LayoutBuilder(builder: (context, constraints) {
      final totalW = constraints.maxWidth;
      // Smaller cap so crown + circle + name + points all fit in podiumHeight.
      final maxD  = podiumHeight * 0.44;
      final d1 = (totalW * 0.28).clamp(56.0, maxD);
      final d2 = (totalW * 0.21).clamp(44.0, maxD * 0.82);
      final d3 = (totalW * 0.19).clamp(40.0, maxD * 0.76);

      return SizedBox(
        height: podiumHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _BgPainter(phase: phase)),
            ),
            // Row order: 2nd – 1st – 3rd  (standard podium layout)
            // Positioned.fill + Column(end) prevents overflow when content
            // is taller than the available space.
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Slot(rank: 2, doc: top2, diameter: d2, phase: phase, currentUid: currentUid),
                      SizedBox(width: totalW * 0.03),
                      _Slot(rank: 1, doc: top1, diameter: d1, phase: phase, currentUid: currentUid),
                      SizedBox(width: totalW * 0.03),
                      _Slot(rank: 3, doc: top3, diameter: d3, phase: phase, currentUid: currentUid),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── One podium slot ──────────────────────────────────────────────
class _Slot extends StatelessWidget {
  final int rank;
  final QueryDocumentSnapshot? doc;
  final double diameter;
  final double phase;
  final String? currentUid;

  const _Slot({
    required this.rank,
    required this.doc,
    required this.diameter,
    required this.phase,
    required this.currentUid,
  });

  static Color _medal(int rank) => rank == 1
      ? const Color(0xFFFFD700)
      : rank == 2
          ? const Color(0xFFB0BEC5)
          : const Color(0xFFCD7F32);

  static String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty  ? last[0].toUpperCase()  : '';
    return (f + l).isEmpty ? '?' : f + l;
  }

  @override
  Widget build(BuildContext context) {
    final data      = doc?.data() as Map<String, dynamic>?;
    final firstName = data?['firstName'] as String? ?? '';
    final lastName  = data?['lastName']  as String? ?? '';
    final name      = '$firstName $lastName'.trim().isEmpty
        ? '---'
        : '$firstName $lastName'.trim();
    final points   = data?['totalPoints'] ?? 0;
    final photoUrl = data?['photoUrl']   as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final isMe     = doc?.id == currentUid;
    final medal  = _medal(rank);

    final pulse      = (sin(phase * 2 * pi) + 1) / 2;

    // Layout constants — derived from diameter so everything scales together.
    final ringD      = diameter + 8.0;          // ring is 4 px wider on each side
    final ribbonW    = diameter * 0.72;
    final ribbonH    = ribbonW * 0.36;          // matches _RankRibbon aspect ratio
    // stackH includes space for the ribbon peeking below the ring.
    final stackH     = ringD + ribbonH * 0.50;
    final ringOffset = (ringD - diameter) / 2;  // = 4 px

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for 1st — same-height spacer keeps 2nd & 3rd bottom-aligned
        if (rank == 1)
          _AnimatedCrown(phase: phase, size: diameter * 0.40, color: medal)
        else
          SizedBox(height: diameter * 0.40),

        const SizedBox(height: 2),

        // Avatar with pulsing ring and rank ribbon.
        // Explicit SizedBox height = ring + ribbon-peek — no negative offsets.
        SizedBox(
          width:  ringD,
          height: stackH,
          child: Stack(
            children: [
              // Pulsing ring (fills the top ringD × ringD area)
              Positioned(
                top: 0, left: 0, right: 0,
                child: SizedBox(
                  height: ringD,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: medal.withValues(alpha: 0.46 + pulse * 0.44),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:        medal.withValues(alpha: 0.20 + pulse * 0.32),
                          blurRadius:   12 + pulse * 8,
                          spreadRadius: 1  + pulse * 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Avatar circle, centred inside the ring
              Positioned(
                top:   ringOffset,
                left:  ringOffset,
                right: ringOffset,
                child: SizedBox(
                  height: diameter,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFECEFF1),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              width:  diameter,
                              height: diameter,
                              // fall back to initials silhouette if the URL fails
                              errorBuilder: (_, _, _) => CustomPaint(
                                painter: _AvatarPainter(
                                  initials:   _initials(firstName, lastName),
                                  isMe:       isMe,
                                  medalColor: medal,
                                ),
                              ),
                            )
                          : CustomPaint(
                              painter: _AvatarPainter(
                                initials:   _initials(firstName, lastName),
                                isMe:       isMe,
                                medalColor: medal,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // Ribbon at very bottom — peeks below the ring with no negative offset
              Positioned(
                bottom: 0,
                left:   (ringD - ribbonW) / 2,
                child:  _RankRibbon(rank: rank, color: medal, width: ribbonW),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Name
        SizedBox(
          width: diameter * 1.15,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:      isMe ? kSecondaryColor : Colors.white,
              fontSize:   diameter * 0.13,
              fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$points pts',
          style: TextStyle(
            color:    Colors.white.withValues(alpha: 0.65),
            fontSize: diameter * 0.105,
          ),
        ),
      ],
    );
  }
}

// ─── Animated crown (rank 1 only) ────────────────────────────────
class _AnimatedCrown extends StatelessWidget {
  final double phase;
  final double size;
  final Color  color;

  const _AnimatedCrown({required this.phase, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final bobY = sin(phase * 2 * pi) * size * 0.07;
    return Transform.translate(
      offset: Offset(0, bobY),
      child: SizedBox(
        width:  size,
        height: size,
        child:  CustomPaint(painter: _CrownPainter(color: color)),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;
  const _CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shadow = Paint()
      ..color = color.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final crown = Path()
      ..moveTo(w * 0.05, h * 0.92)
      ..lineTo(w * 0.10, h * 0.40)
      ..lineTo(w * 0.30, h * 0.65)
      ..lineTo(w * 0.50, h * 0.08)
      ..lineTo(w * 0.70, h * 0.65)
      ..lineTo(w * 0.90, h * 0.40)
      ..lineTo(w * 0.95, h * 0.92)
      ..close();

    canvas.drawPath(crown, shadow);
    canvas.drawPath(crown, fill);

    // White dots on tips
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.90);
    canvas.drawCircle(Offset(w * 0.50, h * 0.10), w * 0.065, dot);
    canvas.drawCircle(Offset(w * 0.10, h * 0.40), w * 0.050, dot);
    canvas.drawCircle(Offset(w * 0.90, h * 0.40), w * 0.050, dot);

    // Green gem at top
    final gem = Paint()..color = const Color(0xFF43A047);
    canvas.drawCircle(Offset(w * 0.50, h * 0.10), w * 0.042, gem);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) => old.color != color;
}

// ─── Avatar painter ───────────────────────────────────────────────
// Draws a person silhouette with initials layered on top.
class _AvatarPainter extends CustomPainter {
  final String initials;
  final bool   isMe;
  final Color  medalColor;

  const _AvatarPainter({
    required this.initials,
    required this.isMe,
    required this.medalColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft white-to-light-grey background
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 0.8,
        colors: const [Colors.white, Color(0xFFDDE3EA)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bg);

    final silhouette = Paint()
      ..color = (isMe ? medalColor : const Color(0xFF78909C)).withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(Offset(w * 0.50, h * 0.34), w * 0.19, silhouette);

    // Shoulders (upper-body arc)
    final bodyPath = Path()
      ..addArc(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.92), width: w * 0.72, height: h * 0.62),
        pi, pi,
      );
    canvas.drawPath(bodyPath, silhouette);

    // Initials text centred on the head circle
    final tp = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color:      Colors.white,
          fontSize:   w * 0.24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, h * 0.28 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) =>
      old.initials != initials || old.isMe != isMe || old.medalColor != medalColor;
}

// ─── Rank ribbon badge ────────────────────────────────────────────
class _RankRibbon extends StatelessWidget {
  final int    rank;
  final Color  color;
  final double width;

  const _RankRibbon({required this.rank, required this.color, required this.width});

  String get _label => rank == 1 ? '1st' : rank == 2 ? '2nd' : '3rd';

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size:    Size(width, width * 0.36),
      painter: _RibbonPainter(color: color, label: _label),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  final Color  color;
  final String label;
  const _RibbonPainter({required this.color, required this.label});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = h * 0.38;

    // Drop shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(1, 2, w, h), Radius.circular(r)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Pill fill
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(r)),
      Paint()..color = color,
    );

    // Rank text
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color:       Colors.white,
          fontSize:    h * 0.60,
          fontWeight:  FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, h / 2 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) =>
      old.color != color || old.label != label;
}

// ─── Background: deep blue + floating orbs + twinkling particles ──
class _BgPainter extends CustomPainter {
  final double phase;
  _BgPainter({required this.phase});

  static const _dots = [
    Offset(0.08, 0.13), Offset(0.22, 0.07), Offset(0.39, 0.19),
    Offset(0.58, 0.11), Offset(0.74, 0.24), Offset(0.91, 0.09),
    Offset(0.14, 0.52), Offset(0.84, 0.44), Offset(0.50, 0.05),
    Offset(0.31, 0.38), Offset(0.69, 0.36), Offset(0.05, 0.30),
    Offset(0.96, 0.60), Offset(0.45, 0.72), Offset(0.77, 0.68),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Main gradient
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [Color(0xFF1A3A6B), Color(0xFF0D2245)],
        ).createShader(rect),
    );

    // Soft centre glow
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.40),
      w * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(w * 0.50, h * 0.40), radius: w * 0.55)),
    );

    // Twinkling dots
    final dotPaint = Paint();
    for (int i = 0; i < _dots.length; i++) {
      final t = (phase + i * 0.17) % 1.0;
      final pulse = (sin(t * 2 * pi) + 1) / 2;
      dotPaint.color = Colors.white.withValues(alpha: 0.10 + pulse * 0.50);
      canvas.drawCircle(
        Offset(_dots[i].dx * w, _dots[i].dy * h),
        0.9 + pulse * 0.9,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => old.phase != phase;
}
