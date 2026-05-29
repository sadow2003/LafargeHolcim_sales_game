import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';

/// Transparent congratulation overlay shown on top of the rankings screen
/// when an event has ended and there are winners.
/// Fades out when the user taps anywhere on it.
class CongratulationOverlay extends StatefulWidget {
  /// Live leaderboard docs (used before results are saved). Pass null when
  /// using [resultWinners] instead.
  final List<QueryDocumentSnapshot>? winners;

  /// Pre-saved winner maps from `lastEventResult` (preferred after auto-close).
  final List<Map<String, dynamic>>? resultWinners;

  /// Prize amounts for 1st / 2nd / 3rd place (null entries = no prize).
  final List<double?>? rewards;

  /// Called after the fade-out animation completes so the parent can remove
  /// the overlay from the tree entirely.
  final VoidCallback? onDismissed;

  /// Headline text (defaults to event-mode text).
  final String title;

  /// Subtitle text shown beneath the headline.
  final String subtitle;

  /// Which field on the user doc to read as the "score" (defaults to totalPoints).
  final String pointsField;

  /// Unit label appended after the score value (defaults to 'pts').
  final String pointsLabel;

  const CongratulationOverlay({
    super.key,
    this.winners,
    this.resultWinners,
    this.rewards,
    this.onDismissed,
    this.title = 'Event Over!',
    this.subtitle = 'Congratulations to our winners',
    this.pointsField = 'totalPoints',
    this.pointsLabel = 'pts',
  });

  @override
  State<CongratulationOverlay> createState() => _CongratulationOverlayState();
}

class _CongratulationOverlayState extends State<CongratulationOverlay>
    with SingleTickerProviderStateMixin {
  // Drives the fade-in / fade-out animation of the overlay.
  late AnimationController _controller;

  // Opacity value (0.0 → 1.0) derived from _controller with an easeIn curve.
  late Animation<double> _opacity;

  // Prevents _dismiss() from triggering the reverse animation more than once.
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onDismissed?.call();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    // Always dispose AnimationControllers to free ticker resources.
    _controller.dispose();
    super.dispose();
  }

  // Called when the user taps anywhere on the overlay.
  // Plays the fade-out animation; AnimatedBuilder collapses the widget to
  // SizedBox.shrink() once opacity reaches 0 so it no longer intercepts taps.
  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _controller.reverse();
  }

  // ____________________________UI______________________
  @override
  Widget build(BuildContext context) {
    final hasWinners = (widget.winners?.isNotEmpty ?? false) ||
        (widget.resultWinners?.isNotEmpty ?? false);
    if (!hasWinners) return const SizedBox.shrink();

    // Rebuilds every frame as _opacity changes so the fade runs smoothly.
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        // Once the fade-out completes, collapse to nothing so the overlay is
        // fully removed from the hit-test tree.
        if (_opacity.value == 0 && _dismissed) return const SizedBox.shrink();
        return Opacity(
          opacity: _opacity.value,
          child: child,
        );
      },

      // child is built once and reused across AnimatedBuilder rebuilds for
      // performance — only the Opacity wrapper is rebuilt each frame.
      child: GestureDetector(
        onTap: _dismiss,

        // Full-screen dark scrim that sits on top of the rankings screen.
        child: Container(
          color: Colors.black.withValues(alpha: 0.72),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

              // Large trophy emoji as a visual focal point.
              Text(
                AppEmojis.trophy,
                style: const TextStyle(fontSize: 64),
              ),

              const SizedBox(height: 12),
              // Primary headline in gold to match the trophy theme.
              Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 4),
              // Subtitle shown beneath the headline.
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 32),
              // Expand the winner tiles list inline using the spread operator.
              ..._buildWinnerTiles(),
              const SizedBox(height: 40),
              // Hint so the user knows how to close the overlay.
              const Text(
                'Tap anywhere to continue',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
              ),       // Column
            ),         // SafeArea
          ),           // SingleChildScrollView
        ),             // Container
      ),               //r GestureDetecto
    );
  }

  // Builds up to 3 ranked winner tiles from either saved results or live docs.
  List<Widget> _buildWinnerTiles() {
    final medals = AppEmojis.medals;
    const borderColors = [
      Color(0xFFFFD700),
      Color(0xFFC0C0C0),
      Color(0xFFCD7F32),
    ];
    final tiles = <Widget>[];

    // Build a unified list of name/points maps from whichever source is available.
    final List<Map<String, dynamic>> entries;
    if (widget.resultWinners != null && widget.resultWinners!.isNotEmpty) {
      entries = widget.resultWinners!.take(3).map((w) => {
        'name':   (w['userName'] as String?) ?? 'Unknown',
        'points': null, // saved results don't store points
        'rank':   w['rank'] as int? ?? 0,
        'rewardAmount': w['rewardAmount'],
      }).toList();
    } else {
      entries = (widget.winners ?? []).take(3).map((doc) {
        final data  = doc.data() as Map<String, dynamic>;
        final first = (data['firstName'] as String?) ?? '';
        final last  = (data['lastName']  as String?) ?? '';
        final name  = '$first $last'.trim().isNotEmpty
            ? '$first $last'.trim()
            : (data['email'] as String?) ?? 'Unknown';
        return {
          'name':   name,
          'points': (data[widget.pointsField] as num?)?.toInt(),
          'rank':   0,
          'rewardAmount': null,
        };
      }).toList();
    }

    for (int i = 0; i < entries.length; i++) {
      final entry  = entries[i];
      final name   = entry['name'] as String;
      final points = entry['points'] as int?;

      // Prize: from resultWinners rewardAmount, or from rewards list.
      final double? prize = (entry['rewardAmount'] as num?)?.toDouble()
          ?? (widget.rewards != null && i < widget.rewards!.length
              ? widget.rewards![i]
              : null);
      final prizeText = (prize != null && prize > 0)
          ? '${prize % 1 == 0 ? prize.toInt() : prize} MAD'
          : null;

      tiles.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColors[i], width: 1.4),
          ),
          child: Row(
            children: [
              Text(medals[i], style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (prizeText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        prizeText,
                        style: TextStyle(
                          color:      borderColors[i],
                          fontSize:   13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (points != null)
                Text(
                  '$points ${widget.pointsLabel}',
                  style: const TextStyle(
                    color:      Colors.white60,
                    fontSize:   13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return tiles;
  }
}
