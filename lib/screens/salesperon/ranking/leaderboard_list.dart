import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import 'nav_circle_button.dart';

// ── Leaderboard + bottom nav buttons ────────────────────────────────────────

class LeaderboardWithButtons extends StatelessWidget {
  final ScrollController leaderboardScroll;
  final List<QueryDocumentSnapshot> docs;
  final String? currentUid;
  // Prize amounts for ranks 1–3; null means no active event
  final List<double?>? rewards;

  const LeaderboardWithButtons({
    super.key,
    required this.leaderboardScroll,
    required this.docs,
    required this.currentUid,
    this.rewards,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFF0E2040),
            child: ListView.builder(
              controller: leaderboardScroll,
              itemCount: docs.length,
              itemExtent: 72,

              //for evry user in the document we create this card for the leaderboard
              itemBuilder: (context, i) {
                final doc  = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                final isMe = doc.id == currentUid;
                final name =
                    '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                        .trim();
                final points   = data['totalPoints'] ?? 0;
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

                final rankColor = i == 0
                    ? const Color(0xFFFFD700)
                    : i == 1
                        ? const Color(0xFFC0C0C0)
                        : i == 2
                            ? const Color(0xFFCD7F32)
                            : Colors.white54;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                  //container of thge user in leaderboard
                  decoration: BoxDecoration(
                    color: isMe
                        ? kPrimaryColor.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isMe
                        ? Border.all(color: kSecondaryColor, width: 1.5)
                        : null,
                  ),

                  //one user of the leader
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        //___rank dispayed
                        SizedBox(
                          width: 30,
                          child: Text(
                            '#${i + 1}',
                            style: TextStyle(
                              color:      rankColor,
                              fontWeight: FontWeight.bold,
                              fontSize:   14,
                            ),
                          ),
                        ),

                        //circle avatar of the user
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius:          18,
                          backgroundColor: isMe
                              ? kSecondaryColor
                              : const Color(0xFF2E5FA3),
                          backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                          onBackgroundImageError: hasPhoto ? (_, _) {} : null,
                          //show initials only when no profile photo is available
                          child: hasPhoto
                              ? null
                              : Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize:   12,
                                    color:      Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),

                    //name of the user
                    title: Text(
                      isMe ? '$name (You)' : name,
                      style: TextStyle(
                        color:      isMe ? kSecondaryColor : Colors.white,
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),

                    //points of the user, plus prize badge for top 3 when an event is active
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$points pts',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Bottom circular nav buttons ───────────────────────────────
        Container(
          color: const Color(0xFF0E2040),

          //the system's safe-area inset — so the buttons lift exactly enough to clear the navigation bar on any Android device, with no hard-coded pixel value
          padding: EdgeInsets.fromLTRB(
            24, 14, 24, 14 + MediaQuery.of(context).padding.bottom),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              //products button
              NavCircleButton(
                icon:  Icons.storefront_outlined,
                label: 'Products',
                color: const Color(0xFF2E5FA3),
                onTap: () => Navigator.pushNamed(context, '/products'),
              ),

              //Profile Button
              NavCircleButton(
                icon:  Icons.person_outline,
                label: 'Profile',
                color: kPrimaryColor,
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),

              //Submite Sales Button
              NavCircleButton(
                icon:  Icons.add_chart_outlined,
                label: 'Submit Sale',
                color: const Color(0xFF2E7D32),
                onTap: () => Navigator.pushNamed(context, '/saleclaim'),
              ),

              //Dashboard Button
              NavCircleButton(
                icon:  Icons.home_filled,
                label: 'Dashboard',
                color: const Color.fromARGB(255, 100, 240, 81),
                onTap: () => Navigator.pushNamed(context, '/home'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
