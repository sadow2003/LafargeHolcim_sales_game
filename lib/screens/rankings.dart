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


      appBar: GradientAppBar(title: 'Rankings'),


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
                child: LayoutBuilder(builder: (context, constraints) {
                  
                  // Total available width → divide into 3 slots with gutters
                  final totalW = constraints.maxWidth;
                  
                  // #1 gets 40 %, #2 and #3 get 28 % each; 4 % gutters (×2)
                  final d1 = totalW * 0.36;
                  final d2 = totalW * 0.27;
                  final d3 = totalW * 0.25;

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
              width: diameter + 6,
              height: diameter + 6,
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
                    painter: _ClimbingPainter(
                      phase: phase,
                      stickColor: stickColor,
                      stairColor: medalColor,
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

// ── Endless-stair climbing painter ──────────────────────────────────────────
//
// Stairs scroll DOWNWARD as phase 0→1, creating the illusion of climbing up.
// The stickman is fixed in the canvas center; only its limbs animate.

class _ClimbingPainter extends CustomPainter {//a Flutter class that lets you draw custom graphics directly on screen.
  final double phase;       // 0.0 → 1.0 continuous
  final Color stickColor;
  final Color stairColor;


  const _ClimbingPainter({
    required this.phase,
    required this.stickColor,
    required this.stairColor,
  });


  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;//Shorthand variable for the total available width
    final h = size.height;//Shorthand variable for the total available height


    // ── Stairs ─────────────────────────────────────────────────────────
    // Side-view staircase going up-right.
    // Each "step" occupies stepW horizontally and stepH vertically.
    
    final stepW = w * 0.40;//Each step is 40% of the total canvas width
    final stepH = h * 0.22;//Each step is 22% of the total canvas height
    final treadThick = stepH * 0.30; // The horizontal plank (the part you walk on) = 30% of the step height Called "tread" — the flat top surface of a stair step
    final riserW     = stepW * 0.15; // The vertical face of the step = 15% of the step width Called "riser" — the vertical part connecting two treads

    //draws shapes filled with a semi-transparent version of stairColor — giving the podium steps a translucent colored fill effect, like frosted glass
    final fillPaint = Paint()
      ..color = stairColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    
    final linePaint = Paint()
      ..color = stairColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square;



    // scroll offset: stairs move down by one stepH per cycle
    final scroll = phase * stepH;



    // Anchor the staircase so that the stickman's foot level (~70 % of h)
    // always sits on a tread. Step index 2 (from the bottom of the view)
    // provides that tread.
    const anchorStep = 2;


    // At scroll=0 step anchorStep's tread top = stickFootY - treadThick/2
    final stickFootY = h * 0.68;
    final anchorTreadTop = stickFootY - treadThick * 0.5;


    for (int i = -2; i < 7; i++) {
      // tread top-left corner
      final left = w / 2 - stepW / 2 + (i - anchorStep) * stepW;
      final top  = anchorTreadTop - (i - anchorStep) * stepH + scroll;


      // Tread
      canvas.drawRect(Rect.fromLTWH(left, top, stepW, treadThick), fillPaint);
      canvas.drawRect(Rect.fromLTWH(left, top, stepW, treadThick), linePaint);


      // Riser (left-side vertical face)
      canvas.drawRect(
          Rect.fromLTWH(left, top + treadThick, riserW, stepH - treadThick),
          fillPaint);
      canvas.drawRect(
          Rect.fromLTWH(left, top + treadThick, riserW, stepH - treadThick),
          linePaint);
    }



    // ── Stickman (fixed position, only limbs move) ──────────────────────
    final cx = w * 0.50;
    final footY = stickFootY;

    final headR   = w * 0.10;
    final bodyLen = h * 0.18;
    final legLen  = h * 0.14;
    final armLen  = w * 0.14;

    final bodyBotY  = footY - legLen * 0.4;
    final bodyTopY  = bodyBotY - bodyLen;
    final headCY    = bodyTopY - headR;

    final stick = Paint()
      ..color = stickColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final headFill = Paint()
      ..color = stickColor
      ..style = PaintingStyle.fill;



    // Head (filled circle)
    canvas.drawCircle(Offset(cx, headCY), headR, headFill);



    // Body
    canvas.drawLine(Offset(cx, bodyTopY), Offset(cx, bodyBotY), stick);



    // Arms swing counter to legs
    final armSwing = sin(phase * 2 * pi) * 0.55;
    final armY = bodyTopY + bodyLen * 0.30;
    canvas.drawLine(
      Offset(cx, armY),
      Offset(cx - armLen * cos(armSwing), armY + armLen * sin(armSwing + 0.5)),
      stick,
    );
    canvas.drawLine(
      Offset(cx, armY),
      Offset(cx + armLen * cos(armSwing), armY + armLen * sin(-armSwing + 0.5)),
      stick,
    );


    // Legs alternate: left and right half-cycle apart
    final legPhase = phase * 2 * pi;


    void drawLeg(double angle) {
      final kx = cx + legLen * sin(angle);
      // Raise the lifted foot slightly
      final ky = footY - legLen * (1 - cos(angle)).abs() * 0.45;
      canvas.drawLine(Offset(cx, bodyBotY), Offset(kx, ky), stick);
    }


    drawLeg(sin(legPhase) * 0.55);
    drawLeg(sin(legPhase + pi) * 0.55);
  }

//going through the phases 0 to 1 
  @override
  bool shouldRepaint(_ClimbingPainter old) =>
      old.phase != phase ||
      old.stickColor != stickColor ||
      old.stairColor != stairColor;
}
