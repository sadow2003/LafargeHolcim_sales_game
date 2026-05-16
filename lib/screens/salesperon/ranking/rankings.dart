import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../widgets/_buildDrawer.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'Congratulation_screen.dart';
import 'event_countdown_banner.dart';
import 'leaderboard_list.dart';
import 'podium_section.dart';
import 'ranking_services.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage>
    with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late AnimationController _climbController;
  final ScrollController _leaderboardScroll = ScrollController();
  PodiumTheme _selectedTheme = PodiumTheme.stickman;

  bool _eventEnded = false;

  // Static so it survives navigation — prevents the overlay re-appearing when
  // the user leaves and returns to the leaderboard.
  static final Set<String> _seenResultKeys = {};

  Timer?                              _endTimer;
  StreamSubscription<DocumentSnapshot>? _eventSub;

  // Hoisted to fields so Flutter never restarts them mid-build.
  final Stream<DocumentSnapshot> _resultStream = RankingService.resultStream;
  final Stream<DocumentSnapshot> _eventStream  = RankingService.eventStream;
  final Stream<QuerySnapshot>    _usersStream  = RankingService.usersStream;

  @override
  void initState() {
    super.initState();
    _climbController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    )..repeat();

    _eventSub = RankingService.listenEventEnd(
      onEnded:  () { if (!_eventEnded && mounted) setState(() => _eventEnded = true);  },
      onActive: () { if (_eventEnded  && mounted) setState(() => _eventEnded = false); },
    );
  }

  @override
  void dispose() {
    _endTimer?.cancel();
    _eventSub?.cancel();
    _climbController.dispose();
    _leaderboardScroll.dispose();
    super.dispose();
  }

  //___________________UI___________________________________
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: GradientAppBar(title: 'Leaderboard'),

      drawer: const AppDrawer(),

      body: StreamBuilder<DocumentSnapshot>(
        stream: _resultStream,
        builder: (context, resultSnap) {
          final resultData = resultSnap.data?.data() as Map<String, dynamic>?;

          return StreamBuilder<DocumentSnapshot>(
            stream: _eventStream,
            builder: (context, eventSnap) {
              final eventData = eventSnap.data?.data() as Map<String, dynamic>?;
              final rewards   = RankingService.extractRewards(eventData);

              return StreamBuilder<QuerySnapshot>(
                stream: _usersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  RankingService.scrollToCurrentUser(
                    uid:        _currentUser?.uid,
                    docs:       docs,
                    controller: _leaderboardScroll,
                  );

                  final top1 = docs.isNotEmpty ? docs[0] : null;
                  final top2 = docs.length > 1  ? docs[1] : null;
                  final top3 = docs.length > 2  ? docs[2] : null;

                  return LayoutBuilder(builder: (_, constraints) {
                    final podiumHeight =
                        (constraints.maxHeight * 0.35).clamp(160.0, 260.0);

                    return Stack(
                      children: [
                        Column(
                          children: [

                            // ── Podium ──────────────────────────────────────────
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

                            // ── Event countdown banner ───────────────────────────
                            const EventCountdownBanner(),

                            // ── Leaderboard header ───────────────────────────────
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

                            // ── Current user rank banner ─────────────────────────
                            Builder(builder: (context) {
                              final myIdx = docs.indexWhere((d) => d.id == _currentUser?.uid);
                              if (myIdx < 0) return const SizedBox.shrink();
                              final myRank     = myIdx + 1;
                              final myPoints   = ((docs[myIdx].data() as Map<String, dynamic>)['totalPoints'] as num?) ?? 0;
                              final top1Points = top1 != null
                                  ? (((top1.data() as Map<String, dynamic>)['totalPoints']) as num?) ?? 0
                                  : 0;
                              final message = RankingService.buildRankMessage(myRank, myPoints, top1Points);

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

                            // ── Scrollable leaderboard ───────────────────────────
                            Expanded(
                              child: LeaderboardWithButtons(
                                leaderboardScroll: _leaderboardScroll,
                                docs:              docs,
                                currentUid:        _currentUser?.uid,
                                rewards:           rewards,
                              ),
                            ),
                          ],
                        ),

                        // ── Congratulation overlay ───────────────────────────────
                        if (resultData != null &&
                            !_seenResultKeys.contains(RankingService.resultKey(resultData)) &&
                            !(eventData != null &&
                                (eventData['endDate'] as Timestamp?)
                                    ?.toDate()
                                    .isAfter(DateTime.now()) == true))
                          Builder(builder: (_) {
                            final key = RankingService.resultKey(resultData);
                            void markSeen() {
                              if (key != null) setState(() => _seenResultKeys.add(key));
                            }

                            final savedWinners =
                                (resultData['winners'] as List<dynamic>?)
                                    ?.cast<Map<String, dynamic>>();

                            if (savedWinners != null && savedWinners.isNotEmpty) {
                              return Positioned.fill(
                                child: CongratulationOverlay(
                                  winners:       null,
                                  resultWinners: savedWinners,
                                  rewards:       rewards,
                                  onDismissed:   markSeen,
                                ),
                              );
                            }

                            final actualWinners = docs
                                .where((d) {
                                  final pts = ((d.data() as Map<String, dynamic>)['totalPoints'] as num?)?.toInt() ?? 0;
                                  return pts > 0;
                                })
                                .take(3)
                                .toList();
                            if (actualWinners.isEmpty) return const SizedBox.shrink();
                            return Positioned.fill(
                              child: CongratulationOverlay(
                                winners:     actualWinners,
                                rewards:     rewards,
                                onDismissed: markSeen,
                              ),
                            );
                          }),
                      ],
                    );
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
