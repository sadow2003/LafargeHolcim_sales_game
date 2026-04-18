import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../widgets/gradient_app_bar.dart';
import '_buildDrawer_Admin.dart';


class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      appBar: GradientAppBar(
        title: 'Admin Dashboard',
        // The back arrow is hidden — admins should use the Logout button in the drawer.
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),



      //Drawer of admin
      drawer: const AppDrawer(),



      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Banner ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimaryColor, Color(0xFF2E5FA3)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),


              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),


                  Text(
                    'Manage products, users, and sales claims.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Live Stats ──────────────────────────────────────────────
            
            
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Row of 3 stat cards (Users / Pending / Total Sales).
            Row(
              children: [


                Expanded(child: _StatCard(
                  label: 'Users',
                  icon:  Icons.people,
                  color: kPrimaryColor,
                  // Count users with role = salesperson
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'salesperson')
                      .snapshots(),
                )),


                const SizedBox(width: 10),



                Expanded(child: _StatCard(
                  label: 'Pending',
                  icon:  Icons.hourglass_top,
                  color: kSecondaryColor,
                  stream: FirebaseFirestore.instance
                      .collection('sales')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                )),


                const SizedBox(width: 10),



                Expanded(child: _StatCard(
                  label: 'All Sales',
                  icon:  Icons.receipt_long,
                  color: Colors.green,
                  stream: FirebaseFirestore.instance
                      .collection('sales')
                      .snapshots(),
                )),
              ],
            ),
            const SizedBox(height: 28),

            // ── Navigation Tiles ────────────────────────────────────────
            const Text(
              'Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Manage Products tile.
            _NavTile(
              icon:     Icons.inventory_2_outlined,
              title:    'Manage Products',
              subtitle: 'Add, edit, or remove products from the catalog',
              color:    kPrimaryColor,
              onTap:    () => Navigator.pushNamed(context, '/admin/products'),
            ),
            const SizedBox(height: 12),

            // Approve Sales tile.
            _NavTile(
              icon:     Icons.fact_check_outlined,
              title:    'Manage Sales',
              subtitle: 'Manage the sales of salespeople',
              color:    Colors.green.shade700,
              onTap:    () => Navigator.pushNamed(context, '/admin/sales'),
            ),
            const SizedBox(height: 12),

            // Manage Users tile.
            _NavTile(
              icon:     Icons.people_outline,
              title:    'Manage Users',
              subtitle: 'Add, edit, or remove user accounts',
              color:    Colors.deepPurple,
              onTap:    () => Navigator.pushNamed(context, '/admin/users'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
// Listens to a Firestore collection stream and shows the document count.
class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.stream,
  });
//______Ui_______________________________________________________
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Navigation Tile ───────────────────────────────────────────────────────────
// A tappable card that navigates to another admin screen.
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Color    color;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title:    Text(title,    style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
