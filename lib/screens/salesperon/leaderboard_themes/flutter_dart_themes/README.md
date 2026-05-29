# Flutter Dart Themes — Drop-in Replacements

Native Dart/Flutter versions of the new stickman + race car animations. **No HTML, no WebView.** All animations are rendered with `CustomPainter` + `AnimationController` so they integrate natively into your existing app.

## Files

| File                  | Replaces in your project                                                       |
| --------------------- | ------------------------------------------------------------------------------ |
| `PodiumPainter.dart`  | `lib/screens/salesperon/leaderboard_themes/PodiumPainter.dart`                 |
| `stickman_theme.dart` | `lib/screens/salesperon/leaderboard_themes/stickman_theme.dart`                |
| `racecar_theme.dart`  | `lib/screens/salesperon/leaderboard_themes/racecar_theme.dart`                 |

## One required change in `rankings.dart`

Bump the climb controller duration from 700 ms to 1400 ms so the new richer animations have time to breathe:

```dart
_climbController = AnimationController(
  vsync:    this,
  duration: const Duration(milliseconds: 1400),  // was 700
)..repeat();
```

That's the only change outside the three theme files.

## What you get

### Stickman theme
- **Rank 1 — Champion**: deep crouch → explosive jump → arc with knee tuck → landing squash + impact ring. Trophy lifted overhead with subtle wobble. Sparkles around the figure, medal-color aura ring pulsing.
- **Rank 2 — Sprinter**: forward-leaning running pose with full arm/leg opposition, speed lines flicking behind, sweat drop flying off.
- **Rank 3 — Climber**: full-body rise/fall on each pull, alternating arm reaches from overhead to past-hip, dust puffs at feet, climbing rungs to the side.
- **Stage backdrop**: twinkling stars, two soft spotlights sweeping, floor glow, confetti rain over the champion.

### Race car theme
- **Intro animation**: every time the screen opens, cars start at the left starting line and animate (staggered) to their actual rank position.
- **Overtake drift**: when the player who was rank 2 catches the player at rank 1 (or vice versa), the overtaker drifts UP with a nose-up tilt + glow, and the overtaken car drifts DOWN with a backwards tilt.
- **Live animated environment**: sunset horizon strip with sun + drifting clouds + bobbing crowd silhouette; scrolling asphalt grain texture under the cars; lane dashes scroll left to convey forward motion.

## Install

1. **Replace the three files** at `lib/screens/salesperon/leaderboard_themes/` with the ones in this folder.
2. **Update the controller duration** in `rankings.dart` as shown above.
3. Run `flutter pub get` (not strictly required — no new dependencies — but doesn't hurt).
4. Hot-restart.

No data shape changes. Firestore docs flow through the same way they did before.
