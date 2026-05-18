import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Congratulation_screen.dart';
import 'event_countdown_banner.dart';
import 'leaderboard_list.dart';
import 'podium_section.dart';
import 'ranking_services.dart';

/// Renders the stickman-themed event leaderboard body.
///
/// How the event point system works:
///   - A manager sets a date range (start → end) and top-3 cash prizes.
///   - Salespersons earn [totalPoints] by submitting sales approved by a manager.
///   - The leaderboard ranks everyone by [totalPoints] in real time.
///   - When the event ends the top-3 win cash rewards and all points reset to 0.
class EventLeaderboardBody extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final String? currentUid;
  final Map<String, dynamic>? eventData;
  final Map<String, dynamic>? resultData;
  final List<double?>? rewards;
  final AnimationController climbController;
  final ScrollController leaderboardScroll;
  final bool hasSeenResult;
  final VoidCallback onMarkResultSeen;

  const EventLeaderboardBody({
    super.key,
    required this.docs,
    required this.currentUid,
    required this.climbController,
    required this.leaderboardScroll,
    required this.hasSeenResult,
    required this.onMarkResultSeen,
    this.eventData,
    this.resultData,
    this.rewards,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final podiumHeight =
          (constraints.maxHeight * 0.35).clamp(160.0, 260.0);

      return Stack(
        children: [
          Column(
            children: [
              PodiumSection(
                selectedTheme: PodiumTheme.stickman,
                climbController: climbController,
                top1: docs.isNotEmpty ? docs[0] : null,
                top2: docs.length > 1 ? docs[1] : null,
                top3: docs.length > 2 ? docs[2] : null,
                currentUid: currentUid,
                podiumHeight: podiumHeight,
              ),
              const EventCountdownBanner(),
              _listHeader(),
              _myRankBanner(),
              Expanded(
                child: LeaderboardWithButtons(
                  leaderboardScroll: leaderboardScroll,
                  docs: docs,
                  currentUid: currentUid,
                  rewards: rewards,
                ),
              ),
            ],
          ),

          if (!hasSeenResult && _shouldShowCongrats())
            Positioned.fill(child: _congratsOverlay()),
        ],
      );
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  bool _shouldShowCongrats() {
    if (resultData == null) return false;
    if (eventData == null) return true;
    final endDate = (eventData!['endDate'] as Timestamp?)?.toDate();
    if (endDate == null) return true;
    return !endDate.isAfter(DateTime.now());
  }

  Widget _congratsOverlay() {
    final savedWinners = (resultData!['winners'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>();

    if (savedWinners != null && savedWinners.isNotEmpty) {
      return CongratulationOverlay(
        winners: null,
        resultWinners: savedWinners,
        rewards: rewards,
        onDismissed: onMarkResultSeen,
      );
    }

    final actualWinners = docs
        .where((d) =>
            (((d.data() as Map<String, dynamic>)['totalPoints'] as num?)
                    ?.toInt() ??
                0) >
            0)
        .take(3)
        .toList();

    if (actualWinners.isEmpty) return const SizedBox.shrink();
    return CongratulationOverlay(
      winners: actualWinners,
      rewards: rewards,
      onDismissed: onMarkResultSeen,
    );
  }

  Widget _listHeader() {
    return Container(
      color: const Color(0xFF122A52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: const Row(
        children: [
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
    );
  }

  Widget _myRankBanner() {
    final myIdx = docs.indexWhere((d) => d.id == currentUid);
    if (myIdx < 0) return const SizedBox.shrink();
    final myRank = myIdx + 1;
    final myPoints =
        ((docs[myIdx].data() as Map<String, dynamic>)['totalPoints'] as num?) ??
            0;
    final top1Points = docs.isNotEmpty
        ? (((docs[0].data() as Map<String, dynamic>)['totalPoints']) as num?) ??
            0
        : 0;
    final message =
        RankingService.buildRankMessage(myRank, myPoints, top1Points);

    return Container(
      width: double.infinity,
      color: const Color(0xFF0D2248),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: myRank == 1 ? const Color(0xFFFFD700) : Colors.white70,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
