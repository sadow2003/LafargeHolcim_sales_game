import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../widgets/_buildDrawer.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'event_countdown_banner.dart';
import 'leaderboard_list.dart';
import 'podium_section.dart';

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
  //controls the scrolling leaderboard
  final ScrollController _leaderboardScroll = ScrollController();
  // which podium theme is currently displayed
  PodiumTheme _selectedTheme = PodiumTheme.stickman;

  @override
  void initState() {
    super.initState();
    _climbController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _climbController.dispose();
    _leaderboardScroll.dispose();
    super.dispose();
  }

  //function that lets the user go staight to the the current user
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
        curve:    Curves.easeOut,
      );
    });
  }

  //___________________UI___________________________________
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: GradientAppBar(title: 'Leaderboard'),

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
          //extract the top three users on the list
          final top1 = docs.isNotEmpty  ? docs[0] : null;
          final top2 = docs.length > 1  ? docs[1] : null;
          final top3 = docs.length > 2  ? docs[2] : null;

          return LayoutBuilder(builder: (_, constraints) {
            // Clamp podium height so it never overflows on small screens
            final podiumHeight =
                (constraints.maxHeight * 0.35).clamp(160.0, 260.0);

            return Column(
              children: [

                // ── Podium section ──────────────────────────────────────
                PodiumSection(
                  selectedTheme:   _selectedTheme,
                  onThemeChanged:  (t) => setState(() => _selectedTheme = t),
                  climbController: _climbController,
                  top1:            top1,
                  top2:            top2,
                  top3:            top3,
                  currentUid:      _currentUser?.uid,
                  podiumHeight:    podiumHeight,
                ),

                // ── Event countdown banner ──────────────────────────────
                const EventCountdownBanner(),

                // ── Leaderboard header ──────────────────────────────────
                Container(
                  color:   const Color(0xFF122A52),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: const Row(
                    children: [
                      Text('#',
                          style: TextStyle(
                              color:      Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize:   13)),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Player',
                            style: TextStyle(
                                color:      Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize:   13)),
                      ),
                      Text('Points',
                          style: TextStyle(
                              color:      Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize:   13)),
                    ],
                  ),
                ),

                // ── Current user rank banner ───────────────────────────
                Builder(builder: (context) {
                  final myIdx = docs.indexWhere((d) => d.id == _currentUser?.uid);
                  if (myIdx < 0) return const SizedBox.shrink();
                  final myRank   = myIdx + 1;
                  final myPoints = (docs[myIdx].data() as Map<String, dynamic>)['totalPoints'] ?? 0;
                  final top1Points = top1 != null
                      ? ((top1.data() as Map<String, dynamic>)['totalPoints'] ?? 0)
                      : 0;
                  final diff = (top1Points as num) - (myPoints as num);

                  String message;
                  switch (myRank) {
                    case 1:  message = 'Congratulation!!!, You are ranked #1 ';
                    case 2:  message = 'You are ranked #2 ,you are so close only $diff pts left';
                    case 3:  message = 'You are ranked #3, keep going only $diff pts to go';
                    default: message = 'You are ranked #$myRank — only $diff pts for rank 1';
                  }

                  return Container(
                    width:   double.infinity,
                    color:   const Color(0xFF0D2248),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: myRank == 1
                            ? const Color(0xFFFFD700)
                            : Colors.white70,
                        fontSize:   12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),

                // ── Scrollable leaderboard ──────────────────────────────
                Expanded(
                  // NOTE: wrapped below — leaderboard + bottom buttons share this Expanded
                  child: LeaderboardWithButtons(
                    leaderboardScroll: _leaderboardScroll,
                    docs:              docs,
                    currentUid:        _currentUser?.uid,
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }
}
