import 'package:flutter/material.dart';
import 'leaderboard_theme.dart';
import 'podiumPainter.dart';

//inherits from the abstract file leaderboard podium for the general structure of the leaderboard theme
class StickmanPodium extends LeaderboardPodium {
  const StickmanPodium({
    super.key,
    required super.top1,
    required super.top2,
    required super.top3,
    required super.phase,
    required super.currentUid,
    required super.podiumHeight,
  });

//build the ui of the stickman podium
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        // Reserve space for text labels + spacing below each circle
        final maxD = podiumHeight *0.73 ;
        final d1 = (totalW * 0.34).clamp(0.0, maxD);
        final d2 = (totalW * 0.26).clamp(0.0, maxD * 0.80);
        final d3 = (totalW * 0.24).clamp(0.0, maxD * 0.75);
        //the podium rows from left to right 2,1,3
        return SizedBox(
          height: podiumHeight,
          child: OverflowBox(
            maxHeight: podiumHeight,
            alignment: Alignment.center,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PodiumSlot(rank: 2, doc: top2, diameter: d2, phase: phase, currentUid: currentUid),
                SizedBox(width: totalW * 0.02),
                PodiumSlot(rank: 1, doc: top1, diameter: d1, phase: phase, currentUid: currentUid),
                SizedBox(width: totalW * 0.02),
                PodiumSlot(rank: 3, doc: top3, diameter: d3, phase: phase, currentUid: currentUid),
              ],
            ),
          ),
        );
      }),
    );
  }
}


