import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '_buildDrawer.dart';
import '../widgets/gradient_app_bar.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}




class _HomePageState extends State<HomePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Dashboard'),
      drawer: const AppDrawer(), // Side menu — defined in _buildDrawer.dart



      // ── Body ─────────────────────────────────────────────────────────────
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .snapshots(), // .snapshots() = live stream, not a one-time read
        builder: (context, snapshot) {
          // While waiting for Firestore, show a loading spinner.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }


          // If something went wrong, show the error message.
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }



          // Extract the user data from the Firestore document.
          final data        = snapshot.data?.data() as Map<String, dynamic>?;
          final firstName   = data?['firstName']   ?? 'User';
          final totalPoints = data?['totalPoints'] ?? data?['points'] ?? 0;
          final rank        = data?['rank']        ?? 0;



          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome Banner ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    // Gradient mirrors the logo: dark navy → cyan → brand green
                    gradient: const LinearGradient(
                      colors: [kPrimaryColor, kCyanColor, kSecondaryColor],
                      stops: [0.0, 0.55, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        firstName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Keep selling to climb the leaderboard!',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),




                // ── Performance Stats ───────────────────────────────────────
                const Text(
                  'Your Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),





                // Two stat cards side by side.
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        icon: Icons.star,
                        iconColor: kSecondaryColor,
                        label: 'Total Points',
                        value: totalPoints.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        icon: Icons.military_tech,
                        iconColor: Colors.amber,
                        label: 'Current Rank',
                        value: rank == 0 ? '—' : '#$rank',
                      ),
                    ),
                  ],
                ),




                const SizedBox(height: 12),

                // Full-width card counting the user's sales by status.
                _SalesCountCard(userId: _currentUser.uid),
                const SizedBox(height: 24),

                // ── Quick Actions ───────────────────────────────────────────
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _quickActionButton(
                        context,
                        icon: Icons.add_shopping_cart,
                        label: 'Submit Sale',
                        route: '/saleclaim',
                        color: kSecondaryColor,
                      ),
                    ),




                    const SizedBox(width: 12),



                    Expanded(
                      child: _quickActionButton(
                        context,
                        icon: Icons.leaderboard,
                        label: 'Leaderboard',
                        route: '/rankings',
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),



                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _quickActionButton(
                        context,
                        icon: Icons.inventory_2_outlined,
                        label: 'Products',
                        route: '/products',
                        color: const Color(0xFF2E7D32),
                      ),
                    ),




                    const SizedBox(width: 12),




                    Expanded(
                      child: _quickActionButton(
                        context,
                        icon: Icons.person_outline,
                        label: 'My Profile',
                        route: '/profile',
                        color: const Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }






  // ── Helper Widgets ────────────────────────────────────────────────────────
  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }





  // Colored button with an icon + label that navigates to a route.
  Widget _quickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, route),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}


// ── Sales Count Card ──────────────────────────────────────────────────────────

class _SalesCountCard extends StatelessWidget {
  final String userId;
  const _SalesCountCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sales')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        int total    = 0;
        int pending  = 0;
        int approved = 0;
        int rejected = 0;

        // Count each document's status.
        if (snapshot.hasData) {
          total    = snapshot.data!.docs.length;
          pending  = snapshot.data!.docs
              .where((d) => (d.data() as Map)['status'] == 'pending')
              .length;
          approved = snapshot.data!.docs
              .where((d) => (d.data() as Map)['status'] == 'approved')
              .length;
          rejected=snapshot.data!.docs
              .where((d)=>(d.data() as Map)['status']=='rejected')
              .length;
        }




        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _countItem('Total', total, const Color.from(alpha: 1, red: 0.376, green: 0.49, blue: 0.545)),
                const SizedBox(
                    height: 30, child: VerticalDivider(thickness: 1)),
                _countItem('Pending', pending, kSecondaryColor),
                const SizedBox(
                    height: 30, child: VerticalDivider(thickness: 1)),
                _countItem('Approved', approved, Colors.green),
                const SizedBox(
                    height: 30, child: VerticalDivider(thickness: 1)),
                _countItem('Rejected', rejected, Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  // Small column: big number on top, tiny label below.
  Widget _countItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

