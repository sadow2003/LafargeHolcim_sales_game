import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import 'Congratulation_screen.dart';
import 'nav_circle_button.dart';
import 'podium_section.dart';

/// Renders the race-car-themed progress challenge leaderboard.
///
/// How the progress system works:
///   - The active event specifies a [productCategory] (and optionally a
///     specific [productId]) that is tracked for progress.
///   - When a sale of a matching product is approved, the salesperson's
///     [progressQuantity] counter is incremented by the sale quantity.
///   - Each user's progress is displayed as a percentage:
///     progressQuantity / targetQuantity × 100.
///   - A user is "Completed" once progressQuantity ≥ targetQuantity.
///   - The challenge resets (progressQuantity → 0) when a new event starts.
class ProgressLeaderboardBody extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final String? currentUid;
  final AnimationController climbController;

  /// Document data from `settings/salesEvent`. Null while loading or when
  /// no event is active. The progress challenge lives inside the event doc.
  final Map<String, dynamic>? eventData;

  /// True when the goal-reached overlay has already been dismissed this session.
  final bool hasSeenProgressResult;

  /// Called after the overlay fade-out completes so the parent can mark it seen.
  final VoidCallback? onMarkProgressResultSeen;

  const ProgressLeaderboardBody({
    super.key,
    required this.docs,
    required this.currentUid,
    required this.climbController,
    this.eventData,
    this.hasSeenProgressResult = false,
    this.onMarkProgressResultSeen,
  });

  // ── Unit label ─────────────────────────────────────────────────────────────

  static String _unitLabel(String category) =>
      category == 'Concrete' ? 'm³' : 'tonnes';

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final target      = (eventData?['targetQuantity']  as num?)?.toInt() ?? 0;
    final category    = (eventData?['productCategory'] as String?) ?? '';
    final productName = eventData?['productName'] as String?;

    if (eventData == null || target <= 0 || category.isEmpty) {
      return _noChallenge(context);
    }

    // Sort by progressQuantity descending — client-side so no extra index needed.
    final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
      ..sort((a, b) {
        final aq = ((a.data() as Map<String, dynamic>)['progressQuantity']
                as num?)
            ?.toInt() ??
            0;
        final bq = ((b.data() as Map<String, dynamic>)['progressQuantity']
                as num?)
            ?.toInt() ??
            0;
        return bq.compareTo(aq);
      });

    // Split into completers (≥ target) and still going (< target).
    final completers = <QueryDocumentSnapshot>[];
    final inProgress = <QueryDocumentSnapshot>[];
    for (final doc in sortedDocs) {
      final qty =
          ((doc.data() as Map<String, dynamic>)['progressQuantity'] as num?)
              ?.toInt() ??
          0;
      (qty >= target ? completers : inProgress).add(doc);
    }

    return LayoutBuilder(builder: (_, constraints) {
      final podiumHeight =
          (constraints.maxHeight * 0.30).clamp(130.0, 210.0);

      return Stack(
        children: [
          Column(
            children: [
              // ── Race car podium (top 3 by progressQuantity) ─────────────
              PodiumSection(
                selectedTheme:  PodiumTheme.raceCar,
                climbController: climbController,
                top1:           sortedDocs.isNotEmpty ? sortedDocs[0] : null,
                top2:           sortedDocs.length > 1 ? sortedDocs[1] : null,
                top3:           sortedDocs.length > 2 ? sortedDocs[2] : null,
                currentUid:     currentUid,
                podiumHeight:   podiumHeight,
                targetQuantity: target,
              ),

              // ── Challenge header ─────────────────────────────────────────
              _header(category, productName, target,
                  completers.length, sortedDocs.length),
              _myProgressBanner(sortedDocs, target, category),

              // ── Progress list ────────────────────────────────────────────
              Expanded(
                child: Container(
                  color: const Color(0xFF0E2040),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      if (completers.isNotEmpty)
                        _sectionLabel('Completed', completers.length,
                            const Color(0xFF4CAF50)),
                      ...completers.map(
                          (d) => _userRow(d, target, category, completed: true)),
                      if (inProgress.isNotEmpty)
                        _sectionLabel(
                            'In Progress', inProgress.length, Colors.white38),
                      ...inProgress.map(
                          (d) => _userRow(d, target, category, completed: false)),
                    ],
                  ),
                ),
              ),
              _navButtons(context),
            ],
          ),

          // ── Goal-reached overlay (shows once when first completer appears) ─
          if (!hasSeenProgressResult && completers.isNotEmpty)
            Positioned.fill(
              child: CongratulationOverlay(
                winners:    sortedDocs.take(3).toList(),
                rewards:    null,
                title:      'Goal Reached!',
                subtitle:   'Top 3 Progress Leaders',
                pointsField: 'progressQuantity',
                pointsLabel: _unitLabel(category),
                onDismissed: onMarkProgressResultSeen,
              ),
            ),
        ],
      );
    });
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _header(String category, String? productName, int target,
      int done, int total) {
    final filterLabel = productName != null
        ? 'Product: $productName'
        : 'Category: $category';
    return Container(
      color: const Color(0xFF122A52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.category_outlined,
                  color: Color(0xFF64B5F6), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(filterLabel,
                    style: const TextStyle(
                        color: Color(0xFF64B5F6), fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.flag_outlined,
                  color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 6),
              Text(
                'Target: $target ${_unitLabel(category)}',
                style: const TextStyle(
                    color: Color(0xFFFFD700), fontSize: 13),
              ),
              const Spacer(),
              Text('$done / $total completed',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _myProgressBanner(
      List<QueryDocumentSnapshot> sortedDocs, int target, String category) {
    final myIdx = sortedDocs.indexWhere((d) => d.id == currentUid);
    if (myIdx < 0) return const SizedBox.shrink();

    final myQty =
        ((sortedDocs[myIdx].data() as Map<String, dynamic>)['progressQuantity']
                as num?)
            ?.toInt() ??
        0;
    final pct  = (myQty / target).clamp(0.0, 1.0);
    final done = myQty >= target;

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
                done
                    ? 'Completed!'
                    : '$myQty / $target ${_unitLabel(category)}  '
                        '(${(pct * 100).toStringAsFixed(0)}%)',
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
    int target,
    String category, {
    required bool completed,
  }) {
    final data  = doc.data() as Map<String, dynamic>;
    final isMe  = doc.id == currentUid;
    final name  = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
    final qty   = (data['progressQuantity'] as num?)?.toInt() ?? 0;
    final pct   = (qty / target).clamp(0.0, 1.0);
    final pctLabel = '${(pct * 100).toStringAsFixed(0)}%';
    final photoUrl = data['photoUrl'] as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
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
              backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
              onBackgroundImageError: hasPhoto ? (_, _) {} : null,
              //show initials only when no profile photo is available
              child: hasPhoto
                  ? null
                  : Text(initials,
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
                  Text('$qty ${_unitLabel(category)}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                Text(
                  pctLabel,
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
                      style: TextStyle(
                          color: Colors.white38, fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    'Set up an event with a product target to enable it.',
                    style:
                        TextStyle(color: Colors.white24, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
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
            icon:  Icons.storefront_outlined,
            label: 'Products',
            color: const Color(0xFF2E5FA3),
            onTap: () => Navigator.pushNamed(context, '/products'),
          ),
          NavCircleButton(
            icon:  Icons.person_outline,
            label: 'Profile',
            color: kPrimaryColor,
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          NavCircleButton(
            icon:  Icons.add_chart_outlined,
            label: 'Submit Sale',
            color: const Color(0xFF2E7D32),
            onTap: () => Navigator.pushNamed(context, '/saleclaim'),
          ),
          NavCircleButton(
            icon:  Icons.home_filled,
            label: 'Dashboard',
            color: const Color.fromARGB(255, 100, 240, 81),
            onTap: () => Navigator.pushNamed(context, '/home'),
          ),
        ],
      ),
    );
  }
}
