import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../leaderboard_themes/stickman_theme.dart';
import '../leaderboard_themes/racecar_theme.dart';

enum PodiumTheme { stickman, raceCar }

// ── Podium section (theme toggle + animated podium) ──────────────────────────

class PodiumSection extends StatelessWidget {
  final PodiumTheme selectedTheme;
  final ValueChanged<PodiumTheme> onThemeChanged;
  final AnimationController climbController;
  final QueryDocumentSnapshot? top1;
  final QueryDocumentSnapshot? top2;
  final QueryDocumentSnapshot? top3;
  final String? currentUid;
  final double podiumHeight;

  const PodiumSection({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
    required this.climbController,
    required this.top1,
    required this.top2,
    required this.top3,
    required this.currentUid,
    required this.podiumHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   const Color(0xFF1A3A6B),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: Column(
        children: [

          // Theme toggle buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ThemeToggleButton(
                icon:     Icons.directions_run,
                label:    'Stickman',
                selected: selectedTheme == PodiumTheme.stickman,
                onTap:    () => onThemeChanged(PodiumTheme.stickman),
              ),
              const SizedBox(width: 8),
              ThemeToggleButton(
                icon:     Icons.directions_car,
                label:    'Race Car',
                selected: selectedTheme == PodiumTheme.raceCar,
                onTap:    () => onThemeChanged(PodiumTheme.raceCar),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Animated podium — switches between themes, clipped to podiumHeight
          SizedBox(
            height: podiumHeight,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: climbController,
                builder: (context, _) {
                  if (selectedTheme == PodiumTheme.raceCar) {
                    return RaceCarPodium(
                      top1:        top1,
                      top2:        top2,
                      top3:        top3,
                      phase:       climbController.value,
                      currentUid:  currentUid,
                      podiumHeight: podiumHeight,
                    );
                  }
                  return StickmanPodium(
                    top1:        top1,
                    top2:        top2,
                    top3:        top3,
                    phase:       climbController.value,
                    currentUid:  currentUid,
                    podiumHeight: podiumHeight,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Theme toggle pill button ─────────────────────────────────────────────────

class ThemeToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ThemeToggleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? kSecondaryColor.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kSecondaryColor : Colors.white24,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: selected ? kSecondaryColor : Colors.white54),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize:   11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color:      selected ? kSecondaryColor : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
