import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final players = [
      _extractPlayer(top1, 1),
      _extractPlayer(top2, 2),
      _extractPlayer(top3, 3),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        width: constraints.maxWidth,
        height: 210,
        child: CustomPaint(
          //the painter responsible for drawing everything
          painter: _RaceTrackPainter(players: players, phase: phase),
          size: Size(constraints.maxWidth, 210),
        ),
      );
    });
  }
  //extract the salesperson info from firestore
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

class _RaceTrackPainter extends CustomPainter {
  final List<_PlayerData> players;
  final double phase;

  static const _medalColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  // the positions of all the three cars on the track, as a fraction(RANK 1 in front, rank 2 in the middle, rank 3 in the back)
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
      final laneMetrics = _laneMetrics(h, rankIdx);
      final carX = w * _carPositions[rankIdx];

      // Rank 1 car gently bobs forward/back
      final animX = player.rank == 1 ? sin(phase * 2 * pi) * 4.0 : 0.0;
      // All cars have a subtle lateral wobble on the track
      final animY = sin(phase * 2 * pi + rankIdx * 1.2) * 1.2;

      _drawCar(
        canvas,
        carX + animX,
        laneMetrics.centerY + animY,
        laneMetrics.laneH * 0.72,
        _medalColors[rankIdx],
        player,
        laneMetrics.laneH,
      );
    }
  }

  // ── Track background ────────────────────────────────────────────────────────

  void _drawTrackBackground(Canvas canvas, double w, double h) {
    // Grass background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1B5E20),
    );

    // Asphalt track lanes
    for (int i = 0; i < 3; i++) {
      final lm = _laneMetrics(h, i);
      canvas.drawRect(
        Rect.fromLTWH(0, lm.top, w, lm.laneH),
        Paint()..color = const Color(0xFF37474F),
      );

      // Lane edge lines
      final edgePaint = Paint()
        ..color = Colors.white38
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(0, lm.top), Offset(w, lm.top), edgePaint);
      canvas.drawLine(Offset(0, lm.bottom), Offset(w, lm.bottom), edgePaint);

      // Dashed center line
      _drawDashedLine(
        canvas,
        Offset(0, lm.centerY),
        Offset(w * 0.88, lm.centerY),
        Paint()
          ..color = Colors.white24
          ..strokeWidth = 1.0,
      );

      // Rank badge on the left edge
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

  // ── Checkered finish zone ───────────────────────────────────────────────────

  void _drawCheckeredZone(Canvas canvas, double w, double h) {
    final zoneW = w * 0.085; // the width of the checkered zone
    final zoneLeft = w - zoneW; // the left limit of the checkered zone
    const squaresPerRow = 3; //how many squares in rach row
    const squaresPerCol = 12;//how many squares in a collum
    final sqW = zoneW / squaresPerRow;//the width of each square
    final trackTop = _laneMetrics(h, 0).top;//the top limit of the track lanes
    final trackBot = _laneMetrics(h, 2).bottom;//the bottom limit of the track lanes
    final sqH = (trackBot - trackTop) / squaresPerCol;//the height of each square

    for (int row = 0; row < squaresPerCol; row++) {
      for (int col = 0; col < squaresPerRow; col++) {
        final isBlack = (row + col) % 2 == 0;
        //draw each square of the checkered pattern
        canvas.drawRect(
          Rect.fromLTWH(zoneLeft + col * sqW, trackTop + row * sqH, sqW, sqH),
          Paint()..color = isBlack ? Colors.black87 : Colors.white,
        );
      }
    }

    // Vertical separator line between track and checkered zone
    canvas.drawLine(
      Offset(zoneLeft, trackTop),
      Offset(zoneLeft, trackBot),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5,
    );
  }

  // ── Car drawing ─────────────────────────────────────────────────────────────

  void _drawCar(
    Canvas canvas,
    double cx,
    double cy,
    double carH,
    Color color,
    _PlayerData player,
    double laneH,
  ) {
    final carW = carH * 2.0;// cars are twice as long as they are tall
    final bodyH = carH * 0.52;// the main body of the car is about half the total height
    final cabinH = bodyH * 0.50;// the cabin takes up about half of the body height
    final wheelR = bodyH * 0.30;// the wheels are circular and about 30% of the body height in radius

    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + bodyH * 0.52),// the shadow is an oval below the car
        width: carW * 0.85,// the shadow is slightly narrower than the car
        height: bodyH * 0.28,// the shadow is a flattened oval
      ),
      Paint()..color = Colors.black45,
    );

    // Car body
    final bodyPaint = Paint()..color = color;
    final bodyHighlight = Paint()..color = color.withValues(alpha: 0.6);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: carW, height: bodyH),
        const Radius.circular(7),
      ),
      bodyPaint,
    );

    // Cabin / cockpit
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - carW * 0.06, cy - bodyH * 0.38),
          width: carW * 0.46,
          height: cabinH,
        ),
        const Radius.circular(5),
      ),
      bodyHighlight,
    );

    // Windshield glare
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - carW * 0.06, cy - bodyH * 0.38),
          width: carW * 0.38,// slightly smaller than cabin width
          height: cabinH * 0.65,// slightly smaller than cabin height
        ),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Wheels (4 corners)
    final wheelPaint = Paint()..color = const Color(0xFF212121);// dark gray wheels
    final hubPaint = Paint()..color = const Color(0xFF9E9E9E);// lighter gray hubs
    for (final wx in [cx - carW * 0.36, cx + carW * 0.36]) {
      for (final wy in [cy - bodyH * 0.3, cy + bodyH * 0.3]) {
        canvas.drawCircle(Offset(wx, wy), wheelR, wheelPaint);
        canvas.drawCircle(Offset(wx, wy), wheelR * 0.45, hubPaint);
      }
    }

    // Headlights (front = right side as car faces right)
    final lightPaint = Paint()..color = Colors.yellow.withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + carW * 0.50, cy - bodyH * 0.15),
          width: carW * 0.06,
          height: bodyH * 0.2,
        ),
        const Radius.circular(2),
      ),
      lightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + carW * 0.50, cy + bodyH * 0.15),
          width: carW * 0.06,
          height: bodyH * 0.2,
        ),
        const Radius.circular(2),
      ),
      lightPaint,
    );

    // Name label (above lane)
    final displayName = player.name.split(' ').first;
    final namePaint = TextPainter(
      text: TextSpan(
        text: displayName,
        style: TextStyle(
          color: player.isMe ? kSecondaryColor : Colors.white,
          fontSize: laneH * 0.175,
          fontWeight: player.isMe ? FontWeight.bold : FontWeight.w500,
          shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: carW * 1.2);
    namePaint.paint(
      canvas,
      Offset(cx - namePaint.width / 2, cy - bodyH * 0.5 - namePaint.height - 2),
    );

    // Points label (below car)
    final ptsPaint = TextPainter(
      text: TextSpan(
        text: '${player.points} pts',
        style: TextStyle(
          color: color,
          fontSize: laneH * 0.155,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    ptsPaint.paint(
      canvas,
      Offset(cx - ptsPaint.width / 2, cy + bodyH * 0.58),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  _LaneMetrics _laneMetrics(double h, int index) {
    const grassFraction = 0.05;// the vertical space taken by grass on top and bottom of the track
    const gapFraction = 0.025;// the vertical space between lanes
    final totalTrackH = h * (1 - grassFraction * 2) - (2 * h * gapFraction);// the total vertical space taken by the track lanes, after accounting for grass and gaps
    final laneH = totalTrackH / 3;// the vertical space taken by each lane
    final top = h * grassFraction + index * (laneH + h * gapFraction);// the vertical position of the top edge of the lane
    return _LaneMetrics(top: top, laneH: laneH);
  }


  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;// the total length of the line in x and y directions
    final dy = end.dy - start.dy;// the total length of the line in x and y directions
    final len = sqrt(dx * dx + dy * dy);// the total length of the line
    const dashLen = 10.0;// the length of each dash segment
    const total = 18.0;// the total length of a dash + gap segment
    final count = (len / total).floor();// how many dash segments fit into the line
    for (int i = 0; i < count; i++) {
      final t1 = i * total / len;// the position of the start of the dash segment
      final t2 = (i * total + dashLen) / len;// the position of the end of the dash segment
      // draw a line segment 
      canvas.drawLine(
        Offset(start.dx + dx * t1, start.dy + dy * t1),
        Offset(start.dx + dx * t2, start.dy + dy * t2),
        paint,
      );
    }
  }

// We want to repaint every frame during the animation, so we return true here.
  @override
  bool shouldRepaint(_RaceTrackPainter old) => old.phase != phase;
}

// Simple struct to hold lane vertical positions and dimensions
class _LaneMetrics {
  final double top;
  final double laneH;
  double get bottom => top + laneH;
  double get centerY => top + laneH / 2;

  const _LaneMetrics({required this.top, required this.laneH});
}
