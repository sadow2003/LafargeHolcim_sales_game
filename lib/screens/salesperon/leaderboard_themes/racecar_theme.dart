import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../main.dart';
import 'leaderboard_theme.dart';

class RaceCarPodium extends LeaderboardPodium {
  const RaceCarPodium({
    super.key,
    required super.top1,
    required super.top2,
    required super.top3,
    required super.phase,
    required super.currentUid,
  });

  static const _carAssets = [
    'assets/images/racecar_gold.svg',
    'assets/images/racecar_silver.svg',
    'assets/images/racecar_bronze.svg',
  ];

  static const _carPositions = [0.74, 0.50, 0.30];

  @override
  Widget build(BuildContext context) {
    final players = [
      _extractPlayer(top1, 1),
      _extractPlayer(top2, 2),
      _extractPlayer(top3, 3),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      const h = 300.0;

      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            // Track + labels
            CustomPaint(
              painter: _RaceTrackPainter(players: players, phase: phase),
              size: Size(w, h),
            ),
            // Car widgets overlaid per lane
            ...players.map((player) {
              final rankIdx = player.rank - 1;
              final lm = _laneMetricsStatic(h, rankIdx);
              final carH = lm.laneH * 2.00;
              // car image is portrait; rotated 90° to face right → effective size swaps
              final carDisplayW = carH;        // original height becomes display width
              final carDisplayH = carH * 0.65; // original width becomes display height
              final cx = w * _carPositions[rankIdx];
              final animX = player.rank == 1 ? sin(phase * 2 * pi) * 4.0 : 0.0;
              final animY = sin(phase * 2 * pi + rankIdx * 1.2) * 1.2;

              return Positioned(
                left: cx + animX - carDisplayW / 2,
                top: lm.centerY + animY - carDisplayH / 2,
                width: carDisplayW,
                height: carDisplayH,
                child: Transform.rotate(
                  angle: pi / 2, // rotate portrait SVG to face right
                  child: SizedBox(
                    width: carDisplayH,  // pre-rotation dimensions
                    height: carDisplayW,
                    child: SvgPicture.asset(
                      _carAssets[rankIdx],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  static _LaneMetrics _laneMetricsStatic(double h, int index) {
    const grassFraction = 0.05;
    const gapFraction = 0.025;
    final totalTrackH = h * (1 - grassFraction * 2) - (2 * h * gapFraction);
    final laneH = totalTrackH / 3;
    final top = h * grassFraction + index * (laneH + h * gapFraction);
    return _LaneMetrics(top: top, laneH: laneH);
  }

  _PlayerData _extractPlayer(QueryDocumentSnapshot? doc, int rank) {
    final data = doc?.data() as Map<String, dynamic>?;
    final firstName = data?['firstName'] ?? '';
    final lastName = data?['lastName'] ?? '';
    final name = '$firstName $lastName'.trim();
    final points = data?['totalPoints'] ?? 0;
    final isMe = doc?.id == currentUid;
    return _PlayerData(
      rank: rank,
      name: name.isNotEmpty ? name : '---',
      points: points,
      isMe: isMe,
    );
  }
}

// ── Player data ──────────────────────────────────────────────────────────────

class _PlayerData {
  final int rank;
  final String name;
  final int points;
  final bool isMe;

  const _PlayerData({
    required this.rank,
    required this.name,
    required this.points,
    required this.isMe,
  });
}

// ── Track painter (background + lane labels) ─────────────────────────────────

class _RaceTrackPainter extends CustomPainter {
  final List<_PlayerData> players;
  final double phase;

  static const _medalColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  static const _carPositions = [0.74, 0.50, 0.30];

  const _RaceTrackPainter({required this.players, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawTrackBackground(canvas, w, h);
    _drawCheckeredZone(canvas, w, h);

    for (final player in players) {
      final rankIdx = player.rank - 1;
      final lm = _laneMetrics(h, rankIdx);
      final carX = w * _carPositions[rankIdx];
      final animX = player.rank == 1 ? sin(phase * 2 * pi) * 4.0 : 0.0;
      final animY = sin(phase * 2 * pi + rankIdx * 1.2) * 1.2;
      final cx = carX + animX;
      final cy = lm.centerY + animY;
      final carH = lm.laneH * 2.00;
      final labelW = carH * 1.5;

      // Name above car
      final displayName = player.name.split(' ').first;
      final namePaint = TextPainter(
        text: TextSpan(
          text: displayName,
          style: TextStyle(
            color: player.isMe ? kSecondaryColor : Colors.white,
            fontSize: lm.laneH * 0.175,
            fontWeight: player.isMe ? FontWeight.bold : FontWeight.w500,
            shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: labelW);
      namePaint.paint(
        canvas,
        Offset(cx - namePaint.width / 2, cy - carH * 0.5 - namePaint.height - 2),
      );

      // Points below car
      final ptsPaint = TextPainter(
        text: TextSpan(
          text: '${player.points} pts',
          style: TextStyle(
            color: _medalColors[rankIdx],
            fontSize: lm.laneH * 0.155,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ptsPaint.paint(
        canvas,
        Offset(cx - ptsPaint.width / 2, cy + carH * 0.58),
      );
    }
  }

  void _drawTrackBackground(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1B5E20),
    );

    for (int i = 0; i < 3; i++) {
      final lm = _laneMetrics(h, i);
      canvas.drawRect(
        Rect.fromLTWH(0, lm.top, w, lm.laneH),
        Paint()..color = const Color(0xFF37474F),
      );

      final edgePaint = Paint()
        ..color = Colors.white38
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(0, lm.top), Offset(w, lm.top), edgePaint);
      canvas.drawLine(Offset(0, lm.bottom), Offset(w, lm.bottom), edgePaint);

      _drawDashedLine(
        canvas,
        Offset(0, lm.centerY),
        Offset(w * 0.88, lm.centerY),
        Paint()
          ..color = Colors.white24
          ..strokeWidth = 1.0,
      );

      final badgeColor = _medalColors[i];
      final badgeR = lm.laneH * 0.28;
      canvas.drawCircle(
        Offset(badgeR + 6, lm.centerY),
        badgeR,
        Paint()..color = badgeColor,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: badgeR * 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(badgeR + 6 - tp.width / 2, lm.centerY - tp.height / 2),
      );
    }
  }


// Draws the checkered finish zone on the right side of the track
  void _drawCheckeredZone(Canvas canvas, double w, double h) {
    final zoneW = w * 0.085;
    final zoneLeft = w - zoneW;
    const squaresPerRow = 3;
    const squaresPerCol = 12;
    final sqW = zoneW / squaresPerRow;
    final trackTop = _laneMetrics(h, 0).top;
    final trackBot = _laneMetrics(h, 2).bottom;
    final sqH = (trackBot - trackTop) / squaresPerCol;

    for (int row = 0; row < squaresPerCol; row++) {
      for (int col = 0; col < squaresPerRow; col++) {
        final isBlack = (row + col) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(zoneLeft + col * sqW, trackTop + row * sqH, sqW, sqH),
          Paint()..color = isBlack ? Colors.black87 : Colors.white,
        );
      }
    }

    canvas.drawLine(
      Offset(zoneLeft, trackTop),
      Offset(zoneLeft, trackBot),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5,
    );
  }


// Calculates lane vertical positions based on total height and lane index
  _LaneMetrics _laneMetrics(double h, int index) {
    const grassFraction = 0.05;
    const gapFraction = 0.025;
    final totalTrackH = h * (1 - grassFraction * 2) - (2 * h * gapFraction);
    final laneH = totalTrackH / 3;
    final top = h * grassFraction + index * (laneH + h * gapFraction);
    return _LaneMetrics(top: top, laneH: laneH);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = sqrt(dx * dx + dy * dy);
    const dashLen = 10.0;
    const total = 18.0;
    final count = (len / total).floor();
    for (int i = 0; i < count; i++) {
      final t1 = i * total / len;
      final t2 = (i * total + dashLen) / len;
      canvas.drawLine(
        Offset(start.dx + dx * t1, start.dy + dy * t1),
        Offset(start.dx + dx * t2, start.dy + dy * t2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RaceTrackPainter old) => old.phase != phase;
}

class _LaneMetrics {
  final double top;
  final double laneH;
  double get bottom => top + laneH;
  double get centerY => top + laneH / 2;

  const _LaneMetrics({required this.top, required this.laneH});
}
