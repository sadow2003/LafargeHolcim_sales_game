import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '_buildDrawer.dart';
import '../main.dart';
import '../widgets/gradient_app_bar.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage>
    with SingleTickerProviderStateMixin {// Flutter mixin that provides a single Ticker — the engine that drives animations.
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  //drives an animation (controls start, stop, repeat, value over time)
  late AnimationController _climbController;
  final ScrollController _leaderboardScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _climbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _climbController.dispose();
    _leaderboardScroll.dispose();
    super.dispose();
  }

  void _scrollToCurrentUser(List<QueryDocumentSnapshot> docs) {
    final idx = docs.indexWhere((d) => d.id == _currentUser?.uid);
    if (idx < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_leaderboardScroll.hasClients) return;
      final target = idx * 72.0;
      final maxExt = _leaderboardScroll.position.maxScrollExtent;
      _leaderboardScroll.animateTo(
        target.clamp(0.0, maxExt),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      appBar: GradientAppBar(
        title: 'Rankings',
        ),


      drawer: const AppDrawer(),


      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'salesperson')
            .orderBy('totalPoints', descending: true)
            .snapshots(),


        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          _scrollToCurrentUser(docs);

          final top1 = docs.isNotEmpty ? docs[0] : null;
          final top2 = docs.length > 1 ? docs[1] : null;
          final top3 = docs.length > 2 ? docs[2] : null;

          return Column(
            children: [


              // ── Podium section ──────────────────────────────────────
              Container(


                color: const Color(0xFF1A3A6B),
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),

                // LayoutBuilder so we can size circles relative to screen width

                child: ClipRect(
                child: LayoutBuilder(builder: (context, constraints) {
                  
                  // Total available width → divide into 3 slots with gutters
                  final totalW = constraints.maxWidth;
                  
                  // #1 gets 40 %, #2 and #3 get 28 % each; 4 % gutters (×2)
                  final d1 = totalW * 0.34;
                  final d2 = totalW * 0.26;
                  final d3 = totalW * 0.24;

                  return AnimatedBuilder(
                    animation: _climbController,
                    builder: (context, _) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          
                          
                          _PodiumSlot(
                            rank: 2,
                            doc: top2,
                            diameter: d2,
                            phase: _climbController.value,
                            currentUid: _currentUser?.uid,
                          ),
                          SizedBox(width: totalW * 0.02),
                          
                          
                          
                          _PodiumSlot(
                            rank: 1,
                            doc: top1,
                            diameter: d1,
                            phase: _climbController.value,
                            currentUid: _currentUser?.uid,
                          ),
                          SizedBox(width: totalW * 0.02),
                          
                          
                          _PodiumSlot(
                            rank: 3,
                            doc: top3,
                            diameter: d3,
                            phase: _climbController.value,
                            currentUid: _currentUser?.uid,
                          ),
                        ],
                      );
                    },
                  );
                }),
                ),
              ),


              // ── Leaderboard header ──────────────────────────────────
              Container(
                color: const Color(0xFF122A52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: const [
                    Text('#',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text('Player',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                    Text('Points',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),

              // ── Current user rank banner ───────────────────────────
              Builder(builder: (context) {
                final myIdx = docs.indexWhere((d) => d.id == _currentUser?.uid);
                if (myIdx < 0) return const SizedBox.shrink();
                final myRank = myIdx + 1;
                final myPoints = (docs[myIdx].data() as Map<String, dynamic>)['totalPoints'] ?? 0;
                final top1Points = top1 != null
                    ? ((top1.data() as Map<String, dynamic>)['totalPoints'] ?? 0)
                    : 0;
                final diff = (top1Points as num) - (myPoints as num);

                String message;
                switch(myRank){
                  case(1):message = 'Congratulation!!!, You are ranked #1 ';
                  case(2):message = 'You are ranked #2 ,you are so close only $diff pts left';
                  case(3):message = 'You are ranked #3, keep going only $diff pts to go';
                  default: message = 'You are ranked #$myRank — only $diff pts for rank 1';
                }
                

                return Container(
                  width: double.infinity,
                  color: const Color(0xFF0D2248),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: myRank == 1
                          ? const Color(0xFFFFD700)
                          : Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),

              // ── Scrollable leaderboard ──────────────────────────────
              Expanded(
                // NOTE: wrapped below — leaderboard + bottom buttons share this Expanded
                child: _LeaderboardWithButtons(
                  leaderboardScroll: _leaderboardScroll,
                  docs: docs,
                  currentUid: _currentUser?.uid,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Leaderboard + bottom nav buttons ────────────────────────────────────────

class _LeaderboardWithButtons extends StatelessWidget {
  final ScrollController leaderboardScroll;
  final List<QueryDocumentSnapshot> docs;
  final String? currentUid;

  const _LeaderboardWithButtons({
    required this.leaderboardScroll,
    required this.docs,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFF0E2040),
            child: ListView.builder(
              controller: leaderboardScroll,
              itemCount: docs.length,
              itemExtent: 72,


              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                final isMe = doc.id == currentUid;
                final name =
                    '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                        .trim();
                final points = data['totalPoints'] ?? 0;
                final initials = name.isNotEmpty
                    ? name
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase()
                    : '?';

                final rankColor = i == 0
                    ? const Color(0xFFFFD700)
                    : i == 1
                        ? const Color(0xFFC0C0C0)
                        : i == 2
                            ? const Color(0xFFCD7F32)
                            : Colors.white54;



                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),

                  //container of the leaderboard   
                  decoration: BoxDecoration(
                    color: isMe
                        ? kPrimaryColor.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isMe
                        ? Border.all(color: kSecondaryColor, width: 1.5)
                        : null,
                  ),

                  //one user of the leader
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        //___rank dispayed 
                        SizedBox(
                          width: 30,
                          child: Text(
                            '#${i + 1}',
                            style: TextStyle(
                              color: rankColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        //circle avatar of the user
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isMe
                              ? kSecondaryColor
                              : const Color(0xFF2E5FA3),
                              //the initial lettre of the username
                          child: Text(
                            initials,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    //name of the user
                    title: Text(
                      isMe ? '$name (You)' : name,
                      style: TextStyle(
                        color: isMe ? kSecondaryColor : Colors.white,
                        fontWeight:
                            isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),


                    //points of the user
                    trailing: Text(
                      '$points pts',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Bottom circular nav buttons ───────────────────────────────
        Container(
          color: const Color(0xFF0E2040),

          //the system's safe-area inset — so the buttons lift exactly enough to clear the navigation bar on any Android device, with no hard-coded pixel value
          padding: EdgeInsets.fromLTRB(24, 14, 24, 14 + MediaQuery.of(context).padding.bottom),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

            children: [

              //products button
              _NavCircleButton(
                icon: Icons.storefront_outlined,
                label: 'Products',
                color: const Color(0xFF2E5FA3),
                onTap: () => Navigator.pushNamed(context, '/products'),
              ),

              //Profile Button
              _NavCircleButton(
                icon: Icons.person_outline,
                label: 'Profile',
                color: kPrimaryColor,
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),

              //Submite Sales Button
              _NavCircleButton(
                icon: Icons.add_chart_outlined,
                label: 'Submit Sale',
                color: const Color(0xFF2E7D32),
                onTap: () => Navigator.pushNamed(context, '/saleclaim'),
              ),

              //Dashboard Button
              _NavCircleButton(
                icon: Icons.home_filled,
                label: 'Dashboard',
                color: const Color.fromARGB(255, 100, 240, 81),
                onTap: () => Navigator.pushNamed(context, '/home'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Circular nav button ──────────────────────────────────────────────────────

class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavCircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Container(
            width: 64,
            height: 64,

            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [

                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),

              ],

            ),

            child: Icon(icon, color: Colors.white, size: 28),

          ),
          const SizedBox(height: 6),

          Text(
            label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11),
          ),

        ],
      ),
    );
  }
}

// ── Podium slot ──────────────────────────────────────────────────────────────

class _PodiumSlot extends StatelessWidget {
  final int rank;
  final QueryDocumentSnapshot? doc;
  final double diameter;
  final double phase;
  final String? currentUid;

  const _PodiumSlot({
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
                    painter: _PodiumPainter(
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
        //name of the user
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

class _PodiumPainter extends CustomPainter {
  final double phase;
  final Color stickColor;
  final Color stairColor;
  final int rank;

  const _PodiumPainter({
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
      _drawJumping(canvas, w, h, stick, headFill);
    } else {
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
  //tells flutter whether to redraw the widget,retrun true if any of the values change
  @override
  bool shouldRepaint(_PodiumPainter old) =>
      old.phase != phase ||
      old.stickColor != stickColor ||
      old.stairColor != stairColor ||
      old.rank != rank;
}
