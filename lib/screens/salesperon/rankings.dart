import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/_buildDrawer.dart';
import '../../main.dart';
import '../../widgets/gradient_app_bar.dart';
import 'leaderboard_themes/stickman_theme.dart';
import 'leaderboard_themes/racecar_theme.dart';

enum _PodiumTheme { stickman, raceCar }

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage>
    with SingleTickerProviderStateMixin {// Flutter mixin that provides a single Ticker — the engine that drives animations.
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  //drives an animation (controls start, stop, repeat, value over time)
  late AnimationController _climbController;
  //controls the scrolling leaderboard
  final ScrollController _leaderboardScroll = ScrollController();
  // which podium theme is currently displayed
  _PodiumTheme _selectedTheme = _PodiumTheme.stickman;
  @override
  void initState() {
    super.initState();
    _climbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _climbController.dispose();
    _leaderboardScroll.dispose();
    super.dispose();
  }

  //function that lets the user go staight to the the current user
  void _scrollToCurrentUser(List<QueryDocumentSnapshot> docs) {
    final idx = docs.indexWhere((d) => d.id == _currentUser?.uid);
    if (idx < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_leaderboardScroll.hasClients) return;
      final target = idx * 72.0;
      final maxExt = _leaderboardScroll.position.maxScrollExtent;
      _leaderboardScroll.animateTo(
        target.clamp(0.0, maxExt),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
      );
    });
  }

  //___________________UI___________________________________
  @override
  Widget build(BuildContext context) {
    return Scaffold(


      appBar: GradientAppBar(
        title: 'Leaderboard',
        ),


      drawer: const AppDrawer(),


      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'salesperson')
            .orderBy('totalPoints', descending: true)
            .snapshots(),


        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          _scrollToCurrentUser(docs);
          //extract the top three users on the list
          final top1 = docs.isNotEmpty ? docs[0] : null;
          final top2 = docs.length > 1 ? docs[1] : null;
          final top3 = docs.length > 2 ? docs[2] : null;

          return Column(
            children: [


              // ── Podium section ──────────────────────────────────────
              Container(
                color: const Color(0xFF1A3A6B),
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                child: Column(
                  children: [

                    // Theme toggle buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ThemeToggleButton(
                          icon: Icons.directions_run,
                          label: 'Stickman',
                          selected: _selectedTheme == _PodiumTheme.stickman,
                          onTap: () => setState(() => _selectedTheme = _PodiumTheme.stickman),
                        ),
                        const SizedBox(width: 8),
                        _ThemeToggleButton(
                          icon: Icons.directions_car,
                          label: 'Race Car',
                          selected: _selectedTheme == _PodiumTheme.raceCar,
                          onTap: () => setState(() => _selectedTheme = _PodiumTheme.raceCar),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Animated podium — switches between themes
                    AnimatedBuilder(
                      animation: _climbController,
                      builder: (context, _) {
                        if (_selectedTheme == _PodiumTheme.raceCar) {
                          return RaceCarPodium(
                            top1: top1,
                            top2: top2,
                            top3: top3,
                            phase: _climbController.value,
                            currentUid: _currentUser?.uid,
                          );
                        }
                        return StickmanPodium(
                          top1: top1,
                          top2: top2,
                          top3: top3,
                          phase: _climbController.value,
                          currentUid: _currentUser?.uid,
                        );
                      },
                    ),
                  ],
                ),
              ),


              // ── Leaderboard header ──────────────────────────────────
              Container(
                color: const Color(0xFF122A52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: const [
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
              ),

              // ── Current user rank banner ───────────────────────────
              Builder(builder: (context) {
                final myIdx = docs.indexWhere((d) => d.id == _currentUser?.uid);
                if (myIdx < 0) return const SizedBox.shrink();
                final myRank = myIdx + 1;
                final myPoints = (docs[myIdx].data() as Map<String, dynamic>)['totalPoints'] ?? 0;
                final top1Points = top1 != null
                    ? ((top1.data() as Map<String, dynamic>)['totalPoints'] ?? 0)
                    : 0;
                final diff = (top1Points as num) - (myPoints as num);

                String message;
                switch(myRank){
                  case(1):message = 'Congratulation!!!, You are ranked #1 ';
                  case(2):message = 'You are ranked #2 ,you are so close only $diff pts left';
                  case(3):message = 'You are ranked #3, keep going only $diff pts to go';
                  default: message = 'You are ranked #$myRank — only $diff pts for rank 1';
                }
                

                return Container(
                  width: double.infinity,
                  color: const Color(0xFF0D2248),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: myRank == 1
                          ? const Color(0xFFFFD700)
                          : Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),

              // ── Scrollable leaderboard ──────────────────────────────
              Expanded(
                // NOTE: wrapped below — leaderboard + bottom buttons share this Expanded
                child: _LeaderboardWithButtons(
                  leaderboardScroll: _leaderboardScroll,
                  docs: docs,
                  currentUid: _currentUser?.uid,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Leaderboard + bottom nav buttons ────────────────────────────────────────

class _LeaderboardWithButtons extends StatelessWidget {
  final ScrollController leaderboardScroll;
  final List<QueryDocumentSnapshot> docs;
  final String? currentUid;

  const _LeaderboardWithButtons({
    required this.leaderboardScroll,
    required this.docs,
    required this.currentUid,
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
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                final isMe = doc.id == currentUid;
                final name =
                    '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                        .trim();
                final points = data['totalPoints'] ?? 0;
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
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),

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
                              color: rankColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        //circle avatar of the user
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isMe
                              ? kSecondaryColor
                              : const Color(0xFF2E5FA3),
                              //the initial lettre of the username
                          child: Text(
                            initials,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    //name of the user
                    title: Text(
                      isMe ? '$name (You)' : name,
                      style: TextStyle(
                        color: isMe ? kSecondaryColor : Colors.white,
                        fontWeight:
                            isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),


                    //points of the user
                    trailing: Text(
                      '$points pts',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
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
          padding: EdgeInsets.fromLTRB(24, 14, 24, 14 + MediaQuery.of(context).padding.bottom),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

            children: [

              //products button
              _NavCircleButton(
                icon: Icons.storefront_outlined,
                label: 'Products',
                color: const Color(0xFF2E5FA3),
                onTap: () => Navigator.pushNamed(context, '/products'),
              ),

              //Profile Button
              _NavCircleButton(
                icon: Icons.person_outline,
                label: 'Profile',
                color: kPrimaryColor,
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),

              //Submite Sales Button
              _NavCircleButton(
                icon: Icons.add_chart_outlined,
                label: 'Submit Sale',
                color: const Color(0xFF2E7D32),
                onTap: () => Navigator.pushNamed(context, '/saleclaim'),
              ),

              //Dashboard Button
              _NavCircleButton(
                icon: Icons.home_filled,
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

// ── Theme toggle pill button ─────────────────────────────────────────────────

class _ThemeToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeToggleButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            Icon(icon, size: 14, color: selected ? kSecondaryColor : Colors.white54),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? kSecondaryColor : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Circular nav button ──────────────────────────────────────────────────────

class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavCircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Container(
            width: 64,
            height: 64,

            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [

                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),

              ],

            ),

            child: Icon(icon, color: Colors.white, size: 28),

          ),
          const SizedBox(height: 6),

          Text(
            label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11),
          ),

        ],
      ),
    );
  }
}
