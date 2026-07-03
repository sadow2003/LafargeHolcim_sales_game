import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../leaderboard_themes/racecar_theme.dart';
import '../leaderboard_themes/top_contributors_theme.dart';

enum PodiumTheme { raceCar, topContributors }

// ── Podium section (animated podium only, theme is fixed per system) ─────────

class PodiumSection extends StatelessWidget {
  final PodiumTheme selectedTheme;
  final AnimationController climbController;
  final QueryDocumentSnapshot? top1;
  final QueryDocumentSnapshot? top2;
  final QueryDocumentSnapshot? top3;
  final String? currentUid;
  final double podiumHeight;
  /// Only used by the race-car theme to position cars by progress %.
  final int targetQuantity;

  const PodiumSection({
    super.key,
    required this.selectedTheme,
    required this.climbController,
    required this.top1,
    required this.top2,
    required this.top3,
    required this.currentUid,
    required this.podiumHeight,
    this.targetQuantity = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   const Color(0xFF1A3A6B),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: SizedBox(
        height: podiumHeight,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: climbController,
            builder: (context, _) {
              if (selectedTheme == PodiumTheme.raceCar) {
                return RaceCarPodium(
                  top1:           top1,
                  top2:           top2,
                  top3:           top3,
                  phase:          climbController.value,
                  currentUid:     currentUid,
                  podiumHeight:   podiumHeight,
                  targetQuantity: targetQuantity,
                );
              }
              return TopContributorsPodium(
                top1:         top1,
                top2:         top2,
                top3:         top3,
                phase:        climbController.value,
                currentUid:   currentUid,
                podiumHeight: podiumHeight,
              );
            },
          ),
        ),
      ),
    );
  }
}
