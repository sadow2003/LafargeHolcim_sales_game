import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import 'nav_circle_button.dart';
import 'podium_section.dart';

/// Renders the race-car-themed progress challenge leaderboard.
///
/// How the progress point system works:
///   - A manager sets a target number of points — there is no end date.
///   - Every approved sale adds to a salesperson's [totalPoints].
///   - Once a salesperson's points reach or exceed the target they are
///     marked "Completed". Everyone else shows as "In Progress".
///   - The challenge stays open until the manager deactivates it.
///
/// Firestore shape for `settings/progressChallenge`:
/// ```json
/// {
///   "isActive":     true,
///   "targetPoints": 1000,
///   "title":        "Q2 Challenge"
/// }
/// ```
class ProgressLeaderboardBody extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final String? currentUid;
  final AnimationController climbController;

  /// Document data from `settings/progressChallenge`. Null while loading.
  final Map<String, dynamic>? challengeData;

  const ProgressLeaderboardBody({
    super.key,
    required this.docs,
    required this.currentUid,
    required this.climbController,
    this.challengeData,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = challengeData?['isActive'] == true;
    final target = (challengeData?['targetPoints'] as num?)?.toInt() ?? 0;
    final title = (challengeData?['title'] as String?) ?? 'Progress Challenge';

    if (!isActive || target <= 0) return _noChallenge(context);

    // Split into completers (>= target) and still going (< target).
    // [docs] is already sorted by totalPoints desc from Firestore, so the order
    // within each group is correct automatically.
    final completers = <QueryDocumentSnapshot>[];
    final inProgress = <QueryDocumentSnapshot>[];
    for (final doc in docs) {
      final pts =
          ((doc.data() as Map<String, dynamic>)['totalPoints'] as num?)
              ?.toInt() ??
          0;
      (pts >= target ? completers : inProgress).add(doc);
    }

    return LayoutBuilder(builder: (_, constraints) {
      final podiumHeight =
          (constraints.maxHeight * 0.30).clamp(130.0, 210.0);

      return Column(
        children: [
          // ── Race car podium (top 3 by points) ─────────────────────────────
          PodiumSection(
            selectedTheme: PodiumTheme.raceCar,
            climbController: climbController,
            top1: docs.isNotEmpty ? docs[0] : null,
            top2: docs.length > 1 ? docs[1] : null,
            top3: docs.length > 2 ? docs[2] : null,
            currentUid: currentUid,
            podiumHeight: podiumHeight,
          ),

          // ── Challenge header ───────────────────────────────────────────────
          _header(title, target, completers.length, docs.length),
          _myProgressBanner(target),

          // ── Progress list ──────────────────────────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFF0E2040),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  if (completers.isNotEmpty)
                    _sectionLabel('Completed', completers.length,
                        const Color(0xFF4CAF50)),
                  ...completers.map((d) => _userRow(d, target, completed: true)),
                  if (inProgress.isNotEmpty)
                    _sectionLabel(
                        'In Progress', inProgress.length, Colors.white38),
                  ...inProgress
                      .map((d) => _userRow(d, target, completed: false)),
                ],
              ),
            ),
          ),
          _navButtons(context),
        ],
      );
    });
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _header(String title, int target, int done, int total) {
    return Container(
      color: const Color(0xFF122A52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.flag_outlined,
                  color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 6),
              Text('Target: $target pts',
                  style: const TextStyle(
                      color: Color(0xFFFFD700), fontSize: 13)),
              const Spacer(),
              Text('$done / $total completed',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _myProgressBanner(int target) {
    final myIdx = docs.indexWhere((d) => d.id == currentUid);
    if (myIdx < 0) return const SizedBox.shrink();

    final myPts =
        ((docs[myIdx].data() as Map<String, dynamic>)['totalPoints'] as num?)
            ?.toInt() ??
        0;
    final pct = (myPts / target).clamp(0.0, 1.0);
    final done = myPts >= target;

    return Container(
      color: const Color(0xFF0D2248),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Your progress',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text(
                done ? 'Completed!' : '$myPts / $target pts',
                style: TextStyle(
                  color: done ? const Color(0xFF4CAF50) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                done ? const Color(0xFF4CAF50) : kSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Text(
            '$label ($count)',
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _userRow(
    QueryDocumentSnapshot doc,
    int target, {
    required bool completed,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = doc.id == currentUid;
    final name =
        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
    final pts = (data['totalPoints'] as num?)?.toInt() ?? 0;
    final pct = (pts / target).clamp(0.0, 1.0);
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFF1B4D2E)
            : isMe
                ? kPrimaryColor.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(color: kSecondaryColor, width: 1.5)
            : completed
                ? Border.all(color: const Color(0xFF4CAF50), width: 1)
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  isMe ? kSecondaryColor : const Color(0xFF2E5FA3),
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMe ? '$name (You)' : name,
                    style: TextStyle(
                      color: isMe ? kSecondaryColor : Colors.white,
                      fontWeight:
                          isMe ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completed
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2E5FA3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (completed)
                  const Text('Done!',
                      style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                          fontSize: 12))
                else
                  Text('$pts pts',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: completed
                        ? const Color(0xFF4CAF50)
                        : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noChallenge(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFF0E2040),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, color: Colors.white24, size: 64),
                  SizedBox(height: 16),
                  Text('No active progress challenge',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('A manager can set a target to start one.',
                      style:
                          TextStyle(color: Colors.white24, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
        _navButtons(context),
      ],
    );
  }

  Widget _navButtons(BuildContext context) {
    return Container(
      color: const Color(0xFF0E2040),
      padding: EdgeInsets.fromLTRB(
          24, 14, 24, 14 + MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          NavCircleButton(
            icon: Icons.storefront_outlined,
            label: 'Products',
            color: const Color(0xFF2E5FA3),
            onTap: () => Navigator.pushNamed(context, '/products'),
          ),
          NavCircleButton(
            icon: Icons.person_outline,
            label: 'Profile',
            color: kPrimaryColor,
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          NavCircleButton(
            icon: Icons.add_chart_outlined,
            label: 'Submit Sale',
            color: const Color(0xFF2E7D32),
            onTap: () => Navigator.pushNamed(context, '/saleclaim'),
          ),
          NavCircleButton(
            icon: Icons.home_filled,
            label: 'Dashboard',
            color: const Color.fromARGB(255, 100, 240, 81),
            onTap: () => Navigator.pushNamed(context, '/home'),
          ),
        ],
      ),
    );
  }
}
