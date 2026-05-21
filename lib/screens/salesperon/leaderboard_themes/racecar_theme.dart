import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../main.dart';
import 'leaderboard_theme.dart';

// ── Lane geometry (shared by widget + painter) ───────────────────────────────

_LaneMetrics _laneAt(double h, int index) {
  const grassFraction = 0.05;
  const gapFraction   = 0.025;
  final totalTrackH   = h * (1 - grassFraction * 2) - (2 * h * gapFraction);
  final laneH = totalTrackH / 3;
  final top   = h * grassFraction + index * (laneH + h * gapFraction);
  return _LaneMetrics(top: top, laneH: laneH);
}

// ── Podium widget ────────────────────────────────────────────────────────────

class RaceCarPodium extends LeaderboardPodium {
  /// Target quantity for the progress challenge – used to compute car positions.
  final int targetQuantity;

  const RaceCarPodium({
    super.key,
    required super.top1,
    required super.top2,
    required super.top3,
    required super.phase,
    required super.currentUid,
    required super.podiumHeight,
    this.targetQuantity = 0,
  });

  static const _carAssets = [
    'assets/images/racecar_gold.svg',
    'assets/images/racecar_silver.svg',
    'assets/images/racecar_bronze.svg',
  ];

  static const _medalColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  @override
  Widget build(BuildContext context) {
    final players = [
      _player(top1, 1),
      _player(top2, 2),
      _player(top3, 3),
    ];

    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final h = podiumHeight;

      return SizedBox(
        width:  w,
        height: h,
        child: Stack(
          children: [
            // ── Static track background ──────────────────────────────────
            CustomPaint(
              painter: const _TrackPainter(),
              size: Size(w, h),
            ),

            // ── One animated car overlay per rank lane ───────────────────
            ...players.map((player) {
              final rankIdx  = player.rank - 1;
              final lm       = _laneAt(h, rankIdx);
              final carH     = lm.laneH * 2.0;
              final carW     = carH;         // displayed width after SVG rotation
              final carDispH = carH * 0.75;  // displayed height after rotation
              final badgeR   = lm.laneH * 0.28;
              final startX   = badgeR * 2 + 20.0; // just past rank badge
              final finishX  = w * 0.915;          // start of checkered zone

              // Wobble offsets (driven by outer phase animation)
              final animY = sin(phase * 2 * pi + rankIdx * 1.2) * 1.2;
              final animX = rankIdx == 0 ? sin(phase * 2 * pi) * 4.0 : 0.0;

              return TweenAnimationBuilder<double>(
                // Key by user ID so Flutter preserves animation state across rank changes
                key:      ValueKey('racecar_${player.uid}'),
                tween:    Tween<double>(begin: 0.0, end: player.progressPct),
                duration: const Duration(milliseconds: 900),
                curve:    Curves.easeOutCubic,
                builder: (context2, animPct, child) {
                  // X position along the track = progress %
                  final cx = startX + (finishX - startX) * animPct;

                  return SizedBox(
                    width:  w,
                    height: h,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [

                        // ── Car SVG ──────────────────────────────────────
                        Positioned(
                          left:   cx + animX - carW / 2,
                          top:    lm.centerY + animY - carDispH / 2,
                          width:  carW,
                          height: carDispH,
                          child: Transform.rotate(
                            angle: pi / 2, // portrait SVG → faces right
                            child: SizedBox(
                              width:  carDispH,
                              height: carW,
                              child:  SvgPicture.asset(
                                _carAssets[rankIdx],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                        // ── First-name label (top of lane, follows car X) ─
                        Positioned(
                          left:  (cx + animX - 46).clamp(startX - 40, w - 94),
                          top:   lm.top + 2,
                          width: 92,
                          child: Text(
                            player.firstName,
                            textAlign: TextAlign.center,
                            maxLines:  1,
                            overflow:  TextOverflow.ellipsis,
                            style: TextStyle(
                              color: player.isMe
                                  ? kSecondaryColor
                                  : Colors.white,
                              fontSize:   (lm.laneH * 0.30).clamp(9.0, 14.0),
                              fontWeight: player.isMe
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),

                        // ── Progress % label (bottom of lane, follows car X)
                        Positioned(
                          left:  (cx + animX - 28).clamp(startX - 22, w - 58),
                          top:   lm.bottom - (lm.laneH * 0.38).clamp(11.0, 17.0),
                          width: 56,
                          child: Text(
                            '${(animPct * 100).toStringAsFixed(0)}%',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:      _medalColors[rankIdx],
                              fontSize:   (lm.laneH * 0.28).clamp(8.0, 13.0),
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 5),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      );
    });
  }

  _PlayerData _player(QueryDocumentSnapshot? doc, int rank) {
    final data        = doc?.data() as Map<String, dynamic>?;
    final firstName   = (data?['firstName'] as String? ?? '').trim();
    final lastName    = (data?['lastName']  as String? ?? '').trim();
    final progressQty = (data?['progressQuantity'] as num?)?.toInt() ?? 0;
    final isMe        = doc?.id == currentUid;
    final progressPct = targetQuantity > 0
        ? (progressQty / targetQuantity).clamp(0.0, 1.0)
        : 0.0;
    final fullName = '$firstName $lastName'.trim();
    return _PlayerData(
      rank:        rank,
      uid:         doc?.id ?? 'empty_$rank',
      firstName:   firstName.isNotEmpty
          ? firstName
          : (fullName.isNotEmpty ? fullName : '---'),
      progressPct: progressPct,
      isMe:        isMe,
    );
  }
}

// ── Player data ──────────────────────────────────────────────────────────────

class _PlayerData {
  final int    rank;
  final String uid;
  final String firstName;
  final double progressPct; // 0.0 – 1.0
  final bool   isMe;

  const _PlayerData({
    required this.rank,
    required this.uid,
    required this.firstName,
    required this.progressPct,
    required this.isMe,
  });
}

// ── Static track background painter ─────────────────────────────────────────

class _TrackPainter extends CustomPainter {
  const _TrackPainter();

  static const _medalColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grass border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1B5E20),
    );

    for (int i = 0; i < 3; i++) {
      final lm = _laneAt(h, i);

      // Asphalt lane
      canvas.drawRect(
        Rect.fromLTWH(0, lm.top, w, lm.laneH),
        Paint()..color = const Color(0xFF37474F),
      );

      // Lane edge lines
      final edge = Paint()
        ..color       = Colors.white38
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(0, lm.top),    Offset(w, lm.top),    edge);
      canvas.drawLine(Offset(0, lm.bottom), Offset(w, lm.bottom), edge);

      // Centre dashed line (stops before finish zone)
      _dashed(
        canvas,
        Offset(0, lm.centerY),
        Offset(w * 0.88, lm.centerY),
        Paint()
          ..color       = Colors.white24
          ..strokeWidth = 1.0,
      );

      // Rank badge circle
      final badgeColor = _medalColors[i];
      final badgeR     = lm.laneH * 0.28;
      canvas.drawCircle(
        Offset(badgeR + 6, lm.centerY),
        badgeR,
        Paint()..color = badgeColor,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color:      Colors.white,
            fontSize:   badgeR * 1.1,
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

    // Checkered finish zone
    final zoneW    = w * 0.085;
    final zoneLeft = w - zoneW;
    const cols = 3, rows = 12;
    final sqW      = zoneW / cols;
    final trackTop = _laneAt(h, 0).top;
    final trackBot = _laneAt(h, 2).bottom;
    final sqH      = (trackBot - trackTop) / rows;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawRect(
          Rect.fromLTWH(
              zoneLeft + c * sqW, trackTop + r * sqH, sqW, sqH),
          Paint()
            ..color = (r + c) % 2 == 0 ? Colors.black87 : Colors.white,
        );
      }
    }
    canvas.drawLine(
      Offset(zoneLeft, trackTop),
      Offset(zoneLeft, trackBot),
      Paint()
        ..color       = Colors.white70
        ..strokeWidth = 1.5,
    );
  }

  void _dashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx  = end.dx - start.dx;
    final dy  = end.dy - start.dy;
    final len = sqrt(dx * dx + dy * dy);
    const dashLen = 10.0, total = 18.0;
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

  // Track background never changes — repaint only on first draw.
  @override
  bool shouldRepaint(_TrackPainter old) => false;
}

// ── Lane geometry model ──────────────────────────────────────────────────────

class _LaneMetrics {
  final double top;
  final double laneH;
  double get bottom  => top + laneH;
  double get centerY => top + laneH / 2;

  const _LaneMetrics({required this.top, required this.laneH});
}
