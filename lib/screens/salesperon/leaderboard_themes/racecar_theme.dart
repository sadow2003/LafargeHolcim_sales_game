import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../main.dart';
import 'leaderboard_theme.dart';

class RaceCarPodium extends LeaderboardPodium {
  /// Optional — used to scale "progress %" from points if you want
  /// progress-based positioning instead of fixed rank lanes. Set 0 to
  /// fall back to fixed rank lane spacing (original behaviour).
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
    return _RaceTrack(
      top1: top1,
      top2: top2,
      top3: top3,
      currentUid: currentUid,
      phase: phase,
      podiumHeight: podiumHeight,
      targetQuantity: targetQuantity,
      carAssets: _carAssets,
      medalColors: _medalColors,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stateful track — handles intro + overtake animations.
// ─────────────────────────────────────────────────────────────────
class _RaceTrack extends StatefulWidget {
  final QueryDocumentSnapshot? top1;
  final QueryDocumentSnapshot? top2;
  final QueryDocumentSnapshot? top3;
  final String? currentUid;
  final double phase;
  final double podiumHeight;
  final int targetQuantity;
  final List<String> carAssets;
  final List<Color> medalColors;

  const _RaceTrack({
    required this.top1,
    required this.top2,
    required this.top3,
    required this.currentUid,
    required this.phase,
    required this.podiumHeight,
    required this.targetQuantity,
    required this.carAssets,
    required this.medalColors,
  });

  @override
  State<_RaceTrack> createState() => _RaceTrackState();
}

class _RaceTrackState extends State<_RaceTrack> with TickerProviderStateMixin {
  late final AnimationController _intro;

  // pid -> previous rank (for detecting overtakes)
  final Map<String, int> _prevRank = {};
  // pid -> drift state (-1 down, 0 none, 1 up) + start time
  final Map<String, _DriftState> _drift = {};

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _maybeTriggerDrifts(List<_PlayerSlot> slots) {
    for (final s in slots) {
      final prev = _prevRank[s.pid];
      if (prev != null && prev != s.rank) {
        _drift[s.pid] = _DriftState(
          direction: s.rank < prev ? 1 : -1,
          start: DateTime.now(),
        );
      }
      _prevRank[s.pid] = s.rank;
    }
    // Clean up old drifts (>1s)
    _drift.removeWhere((_, d) => DateTime.now().difference(d.start).inMilliseconds > 1000);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = widget.podiumHeight;

      final slots = <_PlayerSlot>[];
      for (final entry in [
        (widget.top1, 1),
        (widget.top2, 2),
        (widget.top3, 3),
      ]) {
        final doc = entry.$1;
        if (doc == null) continue;
        final data = doc.data() as Map<String, dynamic>;
        final pts = (data['progressQuantity'] as num?)?.toInt() ?? 0;
        final firstName = (data['firstName'] ?? '') as String;
        final lastName = (data['lastName'] ?? '') as String;
        final name = '$firstName $lastName'.trim();
        slots.add(_PlayerSlot(
          pid: doc.id,
          rank: entry.$2,
          name: name.isEmpty ? '---' : name,
          points: pts,
          isMe: doc.id == widget.currentUid,
        ));
      }

      _maybeTriggerDrifts(slots);

      return AnimatedBuilder(
        animation: _intro,
        builder: (context, _) {
          return Stack(
            children: [
              // Horizon strip + animated track background
              CustomPaint(
                painter: _RaceBackgroundPainter(
                  phase: widget.phase,
                  laneCount: slots.length,
                ),
                size: Size(w, h),
              ),

              // Cars overlaid as positioned children so their motion is
              // smooth between rank lanes (overtake = `top` transition).
              ...slots.map((slot) {
                return _RaceCar(
                  slot: slot,
                  trackWidth: w,
                  trackHeight: h,
                  laneCount: slots.length,
                  intro: _intro.value,
                  ambientPhase: widget.phase,
                  drift: _drift[slot.pid],
                  carAsset: widget.carAssets[(slot.rank - 1)
                      .clamp(0, widget.carAssets.length - 1)],
                  medalColor: widget.medalColors[(slot.rank - 1)
                      .clamp(0, widget.medalColors.length - 1)],
                  target: widget.targetQuantity,
                );
              }),
            ],
          );
        },
      );
    });
  }
}

class _PlayerSlot {
  final String pid;
  final int rank;
  final String name;
  final int points;
  final bool isMe;
  _PlayerSlot({
    required this.pid,
    required this.rank,
    required this.name,
    required this.points,
    required this.isMe,
  });
}

class _DriftState {
  final int direction; // 1 = up (overtake), -1 = down
  final DateTime start;
  _DriftState({required this.direction, required this.start});
}

// ─────────────────────────────────────────────────────────────────
// Individual car widget.
// ─────────────────────────────────────────────────────────────────
class _RaceCar extends StatelessWidget {
  final _PlayerSlot slot;
  final double trackWidth;
  final double trackHeight;
  final int laneCount;
  final double intro;
  final double ambientPhase;
  final _DriftState? drift;
  final String carAsset;
  final Color medalColor;
  final int target;

  const _RaceCar({
    required this.slot,
    required this.trackWidth,
    required this.trackHeight,
    required this.laneCount,
    required this.intro,
    required this.ambientPhase,
    required this.drift,
    required this.carAsset,
    required this.medalColor,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final lm = _laneMetrics(trackHeight, slot.rank - 1, laneCount);

    double targetXPct;
    if (target > 0) {
      final pct = (slot.points / target).clamp(0.0, 1.0);
      targetXPct = 0.06 + pct * 0.82;
    } else {
      const fixed = [0.74, 0.50, 0.30];
      targetXPct = fixed[(slot.rank - 1).clamp(0, 2)];
    }

    final introDelay = (slot.rank - 1) * 0.15;
    final introT = ((intro - introDelay) / (1 - introDelay)).clamp(0.0, 1.0);
    final introCurve = Curves.easeOutCubic.transform(introT);
    final xPct = 0.06 + (targetXPct - 0.06) * introCurve;

    double tilt = 0;
    double yShift = 0;
    double scaleK = 1;
    bool glow = false;
    bool trail = false;
    if (drift != null) {
      final elapsed = DateTime.now().difference(drift!.start).inMilliseconds;
      final k = (elapsed / 900).clamp(0.0, 1.0);
      final wave = sin(k * pi);
      if (drift!.direction > 0) {
        tilt = -0.16 * wave;
        yShift = -3 * wave;
        scaleK = 1 + 0.08 * wave;
        glow = wave > 0.15;
      } else {
        tilt = 0.14 * wave;
        yShift = 2.5 * wave;
        scaleK = 1 - 0.04 * wave;
      }
      trail = wave > 0.2;
    }

    final bob = sin(ambientPhase * 2 * pi + slot.rank * 1.2) * 1.2;
    final ambientShake = slot.rank == 1 ? sin(ambientPhase * 2 * pi) * 3.0 : 0.0;

    final carH = lm.laneH * 0.80;
    final carDisplayW = carH;
    final carDisplayH = carH * 0.75;
    final cx = trackWidth * xPct + ambientShake;

    return Positioned(
      left: cx - carDisplayW / 2,
      top: lm.centerY + bob + yShift - carDisplayH / 2,
      width: carDisplayW,
      height: carDisplayH,
      child: Transform.scale(
        scale: scaleK,
        child: Transform.rotate(
          angle: pi / 2 + tilt,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -carDisplayW * 0.4,
                top: -16,
                width: carDisplayW * 1.8,
                child: _CarLabel(
                  text: slot.isMe ? 'You' : slot.name.split(' ').first,
                  isMe: slot.isMe,
                ),
              ),
              Positioned(
                left: -carDisplayW * 0.4,
                bottom: -14,
                width: carDisplayW * 1.8,
                child: _CarPts(text: '${slot.points} pts', color: medalColor),
              ),

              if (trail)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _TrailPainter(
                      direction: drift!.direction,
                      progress: (DateTime.now().difference(drift!.start).inMilliseconds / 900).clamp(0.0, 1.0),
                    )),
                  ),
                ),

              SizedBox(
                width: carDisplayH,
                height: carDisplayW,
                child: glow
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: kSecondaryColor.withValues(alpha: 0.55),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(carAsset, fit: BoxFit.contain),
                      )
                    : SvgPicture.asset(carAsset, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _LaneMetrics _laneMetrics(double h, int index, int total) {
    const grassFraction = 0.05;
    const gapFraction = 0.025;
    final totalTrackH = h * (1 - grassFraction * 2) - ((total - 1) * h * gapFraction);
    final laneH = totalTrackH / total;
    final top = h * grassFraction + index * (laneH + h * gapFraction);
    return _LaneMetrics(top: top, laneH: laneH);
  }
}

class _CarLabel extends StatelessWidget {
  final String text;
  final bool isMe;
  const _CarLabel({required this.text, required this.isMe});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isMe ? kSecondaryColor : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
  }
}

class _CarPts extends StatelessWidget {
  final String text;
  final Color color;
  const _CarPts({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
  }
}

class _LaneMetrics {
  final double top;
  final double laneH;
  double get bottom => top + laneH;
  double get centerY => top + laneH / 2;
  const _LaneMetrics({required this.top, required this.laneH});
}

// ─────────────────────────────────────────────────────────────────
// _RaceBackgroundPainter — horizon strip + lanes + scrolling dashes
// + checkered finish + waving flag.
// ─────────────────────────────────────────────────────────────────
class _RaceBackgroundPainter extends CustomPainter {
  final double phase;
  final int laneCount;
  _RaceBackgroundPainter({required this.phase, required this.laneCount});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawHorizon(canvas, w, h);
    _drawLanes(canvas, w, h);
    _drawCheckeredZone(canvas, w, h);
    _drawFlag(canvas, w, h);
  }

  void _drawHorizon(Canvas canvas, double w, double h) {
    final horizonH = h * 0.10;
    final rect = Rect.fromLTWH(0, 0, w, horizonH);
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFB27A), Color(0xFFF7A26F), Color(0xFF2A6FA3)],
        stops: [0.0, 0.35, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    final scroll = (phase * 0.6 * w) % (w * 1.1);
    for (int i = -1; i < 3; i++) {
      final cx = (i * w * 0.4) + (w * 0.15) - scroll;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, horizonH * 0.45),
            width: 22, height: 6),
        cloudPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 12, horizonH * 0.35),
            width: 18, height: 5),
        cloudPaint..color = Colors.white.withValues(alpha: 0.45),
      );
    }

    final sunCenter = Offset(w * 0.78, horizonH * 0.75);
    final sun = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFF2A8), Color(0xFFFFB74A)],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 7));
    canvas.drawCircle(sunCenter, 7, sun);
    canvas.drawCircle(
      sunCenter,
      11,
      Paint()..color = const Color(0xFFFFB74A).withValues(alpha: 0.2),
    );

    final crowdPaint = Paint()..color = Colors.black.withValues(alpha: 0.78);
    final bob = sin(phase * 4 * pi) * 0.5;
    for (double x = 0; x < w; x += 3) {
      final heightVar = ((sin(x * 0.7) + 1) / 2) * 3 + 2 + bob;
      canvas.drawRect(
        Rect.fromLTWH(x, horizonH - heightVar, 2, heightVar),
        crowdPaint,
      );
    }
  }

  void _drawLanes(Canvas canvas, double w, double h) {
    final horizonH = h * 0.10;
    final trackTop = horizonH;
    final trackH = h - horizonH;

    canvas.drawRect(
      Rect.fromLTWH(0, trackTop, w, trackH),
      Paint()..color = const Color(0xFF1B5E20),
    );

    for (int i = 0; i < laneCount; i++) {
      final lm = _laneMetrics(h, i, laneCount, horizonH);
      canvas.drawRect(
        Rect.fromLTWH(0, lm.top, w, lm.laneH),
        Paint()..color = const Color(0xFF37474F),
      );

      final edge = Paint()
        ..color = Colors.white38
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(0, lm.top), Offset(w, lm.top), edge);
      canvas.drawLine(Offset(0, lm.bottom), Offset(w, lm.bottom), edge);

      _drawScrollingDashes(canvas, lm.centerY, w);

      final badgeR = lm.laneH * 0.28;
      final medalColors = [
        const Color(0xFFFFD700),
        const Color(0xFFC0C0C0),
        const Color(0xFFCD7F32),
      ];
      final badgeColor = medalColors[i.clamp(0, medalColors.length - 1)];
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
      tp.paint(canvas,
          Offset(badgeR + 6 - tp.width / 2, lm.centerY - tp.height / 2));
    }
  }

  void _drawScrollingDashes(Canvas canvas, double y, double w) {
    const dashLen = 10.0;
    const gap = 8.0;
    const stride = dashLen + gap;
    final offset = (phase * stride) % stride;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..strokeWidth = 1.0;

    double x = -offset;
    while (x < w * 0.92) {
      canvas.drawLine(Offset(x, y), Offset(x + dashLen, y), paint);
      x += stride;
    }
  }

  void _drawCheckeredZone(Canvas canvas, double w, double h) {
    final horizonH = h * 0.10;
    final zoneW = w * 0.085;
    final zoneLeft = w - zoneW;
    const squaresPerRow = 3;
    const squaresPerCol = 12;
    final sqW = zoneW / squaresPerRow;
    final trackTop = _laneMetrics(h, 0, laneCount, horizonH).top;
    final trackBot = _laneMetrics(h, laneCount - 1, laneCount, horizonH).bottom;
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

  void _drawFlag(Canvas canvas, double w, double h) {
    final horizonH = h * 0.10;
    final poleX = w - 2;
    final poleTop = horizonH * 0.45;
    final poleBot = h * 0.95;

    final pole = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(poleX, poleTop), Offset(poleX, poleBot), pole);

    final flagW = w * 0.07;
    final flagH = horizonH * 0.5;
    final skew = sin(phase * 4 * pi) * 0.2;

    canvas.save();
    canvas.translate(poleX, poleTop);
    canvas.transform(Matrix4(
      1.0, 0.0, 0.0, 0.0,
      skew, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0,
    ).storage);

    const cellCountX = 4;
    const cellCountY = 3;
    final cellW = flagW / cellCountX;
    final cellH = flagH / cellCountY;
    for (int r = 0; r < cellCountY; r++) {
      for (int c = 0; c < cellCountX; c++) {
        final dark = (r + c) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(-flagW + c * cellW, r * cellH, cellW, cellH),
          Paint()..color = dark ? Colors.black : Colors.white,
        );
      }
    }
    canvas.restore();
  }

  _LaneMetrics _laneMetrics(double h, int index, int total, double horizonH) {
    final trackH = h - horizonH;
    const grassFraction = 0.05;
    const gapFraction = 0.025;
    final totalTrackH = trackH * (1 - grassFraction * 2) -
        ((total - 1) * trackH * gapFraction);
    final laneH = totalTrackH / total;
    final top = horizonH + trackH * grassFraction +
        index * (laneH + trackH * gapFraction);
    return _LaneMetrics(top: top, laneH: laneH);
  }

  @override
  bool shouldRepaint(covariant _RaceBackgroundPainter old) =>
      old.phase != phase || old.laneCount != laneCount;
}

// ─── Drift smoke streak painter ──────────────────────────────────
class _TrailPainter extends CustomPainter {
  final int direction;
  final double progress;

  _TrailPainter({required this.direction, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fade = sin(progress * pi);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * fade)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    canvas.drawLine(Offset(0, h * 0.35), Offset(w * 0.5, h * 0.35), paint);
    canvas.drawLine(Offset(0, h * 0.65), Offset(w * 0.55, h * 0.65), paint);
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.direction != direction || old.progress != progress;
}
