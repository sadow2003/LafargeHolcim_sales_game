import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';

// ── Podium slot ──────────────────────────────────────────────────────────────

class PodiumSlot extends StatelessWidget {
  final int rank;
  final QueryDocumentSnapshot? doc;
  final double diameter;
  final double phase;
  final String? currentUid;

  const PodiumSlot({
    required this.rank,
    required this.doc,
    required this.diameter,
    required this.phase,
    required this.currentUid,
  });

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
        //the circle of the animation
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [

            // Glow ring
            Container(
              width: diameter + 10,
              height: diameter + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: medalColor.withValues(alpha: 0.6), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: medalColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),


            // Circle with climbing animation
            ClipOval(
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: ColoredBox(
                  color: const Color(0xFF0E2040),
                  child: CustomPaint(
                    painter: PodiumPainter(
                      phase: phase,
                      stickColor: stickColor,
                      stairColor: medalColor,
                      rank: rank,
                    ),
                  ),
                ),
              ),
            ),


            // Rank badge pinned to bottom-right of the circle
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
                      fontSize: 12),
                ),
              ),
            ),
          ],
        ),


        const SizedBox(height: 6),
        //name of the top three users
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

        //points of the users
        Text(
          '$points pts',
          style: TextStyle(
              color: Colors.white54, fontSize: diameter * 0.075),
        ),
      ],
    );
  }
}


class PodiumPainter extends CustomPainter {
  final double phase;
  final Color stickColor;
  final Color stairColor;
  final int rank;

  const PodiumPainter({
    required this.phase,
    required this.stickColor,
    required this.stairColor,
    required this.rank,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stick = Paint()
      ..color = stickColor//the color of the stickman
      ..strokeWidth = 4.0 //how full is the stickman
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final headFill = Paint()
      ..color = stickColor
      ..style = PaintingStyle.fill;

    _drawPodium(canvas, w, h);

    if (rank == 1) {
      //if the podium is rank one then the stick man wil countinuasly jump up and down
      _drawJumping(canvas, w, h, stick, headFill);
    } else {
      //if it rank 2 or 3 then the stick man will be standing still
      _drawStanding(canvas, w, h, stick, headFill);
    }
  }

  void _drawPodium(Canvas canvas, double w, double h) {
    final podiumH = h * 0.18;//podium height
    final podiumW = w * 0.70;//podium width
    final podiumTop = h - podiumH;
    final left = (w - podiumW) / 2;

    //podium color
    final fill = Paint()
      ..color = stairColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
      //podium border color
    final border = Paint()
      ..color = stairColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;

      //draws a rounded-rectangle podium block on a canvas
    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(left, podiumTop, podiumW, podiumH),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);

    // Rank number on the podium face
    final tp = TextPainter(
      text: TextSpan(
        text: '$rank',
        style: TextStyle(
          color: stairColor,
          fontSize: podiumH * 0.52,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(w / 2 - tp.width / 2, podiumTop + podiumH / 2 - tp.height / 2));
  }

  void _drawJumping(Canvas canvas, double w, double h, Paint stick, Paint headFill) {
    // Stickman bounces up and down, standing on top of the podium
    final podiumTop = h - h * 0.20;//where the stick men is standing
    final jumpOffset = sin(phase * 1* pi).abs() * h * 0.3;//How fast and how high the stickman jumps
    final cx = w * 0.50; //where he is standing(you can get him to be left of the podium ro to the far right)
    final footY = podiumTop - jumpOffset;

    final headR  = w * 0.10;//how big is the stickman head
    final bodyLen = h * 0.17;//how tall is his torso
    final legLen  = h * 0.12;//how long is his legs
    final armLen  = w * 0.12;//how long is his arms

    //reassembaling the stickman
    final bodyBotY = footY - legLen * 0.5;
    final bodyTopY = bodyBotY - bodyLen;
    final headCY   = bodyTopY - headR;

    // draw Head of the stickman
    canvas.drawCircle(Offset(cx, headCY), headR, headFill);
    // draw the Body of the stickman
    canvas.drawLine(Offset(cx, bodyTopY), Offset(cx, bodyBotY), stick);

    // Arms raised during jump
    final armRaise = -(sin(phase * 2 * pi).abs() * 0.6 + 0.3);
    final armY = bodyTopY + bodyLen * 0.25;
    canvas.drawLine(Offset(cx, armY),
        Offset(cx - armLen, armY + armLen * armRaise), stick);
    canvas.drawLine(Offset(cx, armY),
        Offset(cx + armLen, armY + armLen * armRaise), stick);

    // Legs slightly tucked during jump
    final tuck = sin(phase * 2 * pi).abs() * 0.35;
    canvas.drawLine(Offset(cx, bodyBotY),
        Offset(cx - legLen * 0.35, bodyBotY + legLen * (1 - tuck)), stick);
    canvas.drawLine(Offset(cx, bodyBotY),
        Offset(cx + legLen * 0.35, bodyBotY + legLen * (1 - tuck)), stick);

    // Trophy sitting on the podium surface beside the stickman
    final trophyS = w * 0.09;
    final trophyCy = h - h * 0.18 - trophyS * 1.4;
    _drawTrophy(canvas, w * 0.74, trophyCy, trophyS, stairColor);
  }

  void _drawStanding(Canvas canvas, double w, double h, Paint stick, Paint headFill) {
    final cx = w * 0.50;//where is he standing in the podium
    final footY = h - h * 0.18; // stand on top of podium

    final headR  = w * 0.10;//how big is the stickman head
    final bodyLen = h * 0.17;//how tall is his torso
    final legLen  = h * 0.14;//how long is his legs
    final armLen  = w * 0.12;//how long is his arms

    //reasembaling the stickman
    final bodyBotY = footY - legLen;
    final bodyTopY = bodyBotY - bodyLen;
    final headCY   = bodyTopY - headR;

    // Head
    canvas.drawCircle(Offset(cx, headCY), headR, headFill);
    // Body
    canvas.drawLine(Offset(cx, bodyTopY), Offset(cx, bodyBotY), stick);
    // Arms relaxed
    canvas.drawLine(Offset(cx, bodyTopY + bodyLen * 0.2),
        Offset(cx - armLen, bodyTopY + bodyLen * 0.55), stick);
    canvas.drawLine(Offset(cx, bodyTopY + bodyLen * 0.2),
        Offset(cx + armLen, bodyTopY + bodyLen * 0.55), stick);
    // Legs straight
    canvas.drawLine(Offset(cx, bodyBotY), Offset(cx - legLen * 0.28, footY), stick);
    canvas.drawLine(Offset(cx, bodyBotY), Offset(cx + legLen * 0.28, footY), stick);

    // Trophy to the right (upper body level, above podium)
    final trophyS = w * 0.09;
    final trophyCy = h - h * 0.18 - trophyS * 1.4;
    _drawTrophy(canvas, w * 0.74, trophyCy, trophyS, stairColor);
  }

  void _drawTrophy(Canvas canvas, double cx, double cy, double s, Color color) {
    //the border of the trophy
    final outline = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    //the fill of the trophy
    final fill = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Cup body
    final cup = Path()
      ..moveTo(cx - s, cy - s * 0.9)
      ..lineTo(cx - s, cy + s * 0.1)
      ..quadraticBezierTo(cx - s, cy + s * 0.9, cx, cy + s * 0.9)
      ..quadraticBezierTo(cx + s, cy + s * 0.9, cx + s, cy + s * 0.1)
      ..lineTo(cx + s, cy - s * 0.9)
      ..close();
    canvas.drawPath(cup, fill);
    canvas.drawPath(cup, outline);

    // Handles (arcs on each side)
    canvas.drawArc(
        Rect.fromCenter(center: Offset(cx - s, cy), width: s * 1.0, height: s * 0.9),
        pi / 2, pi, false, outline);
    canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + s, cy), width: s * 1.0, height: s * 0.9),
        -pi / 2, pi, false, outline);

    // Stem
    canvas.drawLine(Offset(cx, cy + s * 0.9), Offset(cx, cy + s * 1.4), outline);
    // Base
    canvas.drawLine(
        Offset(cx - s * 0.75, cy + s * 1.4), Offset(cx + s * 0.75, cy + s * 1.4), outline);
  }
  //tells flutter whether to redraw the widget,returns true if any of the values change
  @override
  bool shouldRepaint(PodiumPainter old) =>
      old.phase != phase ||
      old.stickColor != stickColor ||
      old.stairColor != stairColor ||
      old.rank != rank;
}
