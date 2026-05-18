import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../widgets/_buildDrawer.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'event_point_system.dart';
import 'progress_point_system.dart';
import 'ranking_services.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage>
    with TickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late AnimationController _climbController;
  late TabController _tabController;
  final ScrollController _leaderboardScroll = ScrollController();

  bool _eventEnded = false;

  // Static so it survives navigation — prevents the overlay re-appearing when
  // the user leaves and returns to the leaderboard.
  static final Set<String> _seenResultKeys = {};

  StreamSubscription<DocumentSnapshot>? _eventSub;

  // Hoisted to fields so Flutter never restarts them mid-build.
  final Stream<DocumentSnapshot> _resultStream = RankingService.resultStream;
  final Stream<DocumentSnapshot> _eventStream  = RankingService.eventStream;
  final Stream<QuerySnapshot>    _usersStream  = RankingService.usersStream;
  final Stream<DocumentSnapshot> _progressStream =
      RankingService.progressChallengeStream;

  @override
  void initState() {
    super.initState();
    _climbController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    )..repeat();

    _tabController = TabController(length: 2, vsync: this);

    _eventSub = RankingService.listenEventEnd(
      onEnded:  () { if (!_eventEnded && mounted) setState(() => _eventEnded = true);  },
      onActive: () { if (_eventEnded  && mounted) setState(() => _eventEnded = false); },
    );
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _climbController.dispose();
    _tabController.dispose();
    _leaderboardScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Leaderboard'),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // ── Tab bar ──────────────────────────────────────────────────────
          Container(
            color: const Color(0xFF122A52),
            child: TabBar(
              controller: _tabController,
              indicatorColor: kSecondaryColor,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(
                  icon: Icon(Icons.emoji_events_outlined, size: 18),
                  text: 'Event',
                ),
                Tab(
                  icon: Icon(Icons.flag_outlined, size: 18),
                  text: 'Progress',
                ),
              ],
            ),
          ),

          // ── Tab bodies ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _resultStream,
              builder: (context, resultSnap) {
                final resultData =
                    resultSnap.data?.data() as Map<String, dynamic>?;

                return StreamBuilder<DocumentSnapshot>(
                  stream: _eventStream,
                  builder: (context, eventSnap) {
                    final eventData =
                        eventSnap.data?.data() as Map<String, dynamic>?;
                    final rewards = RankingService.extractRewards(eventData);

                    return StreamBuilder<QuerySnapshot>(
                      stream: _usersStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        final docs = snapshot.data?.docs ?? [];
                        RankingService.scrollToCurrentUser(
                          uid:        _currentUser?.uid,
                          docs:       docs,
                          controller: _leaderboardScroll,
                        );

                        return StreamBuilder<DocumentSnapshot>(
                          stream: _progressStream,
                          builder: (context, progressSnap) {
                            final challengeData = progressSnap.data?.data()
                                as Map<String, dynamic>?;

                            final resultKey =
                                RankingService.resultKey(resultData);
                            final hasSeenResult = resultKey != null &&
                                _seenResultKeys.contains(resultKey);

                            return TabBarView(
                              controller: _tabController,
                              children: [
                                // ── Event: stickman leaderboard ───────────
                                EventLeaderboardBody(
                                  docs:             docs,
                                  currentUid:       _currentUser?.uid,
                                  eventData:        eventData,
                                  resultData:       resultData,
                                  rewards:          rewards,
                                  climbController:  _climbController,
                                  leaderboardScroll: _leaderboardScroll,
                                  hasSeenResult:    hasSeenResult,
                                  onMarkResultSeen: () {
                                    if (resultKey != null) {
                                      setState(() =>
                                          _seenResultKeys.add(resultKey));
                                    }
                                  },
                                ),

                                // ── Progress: race car leaderboard ────────
                                ProgressLeaderboardBody(
                                  docs:           docs,
                                  currentUid:     _currentUser?.uid,
                                  climbController: _climbController,
                                  challengeData:  challengeData,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
