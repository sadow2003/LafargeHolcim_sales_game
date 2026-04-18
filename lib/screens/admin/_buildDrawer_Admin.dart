import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/main.dart';


class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}




class _AppDrawerState extends State<AppDrawer> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ── Drawer Header ───────────────────────────────────────────────
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              // Loading until all the information is extracted
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const DrawerHeader(
                  //what the backgound of the box color is
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryColor, kCyanColor, kSecondaryColor],
                      stops: [0.0, 0.55, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }

              String userName  = 'User';
              String userEmail = _currentUser?.email ?? '';
              String userRole  = 'salesperson';

              if (snapshot.hasData && snapshot.data!.exists) {
                final data      = snapshot.data!.data() as Map<String, dynamic>;
                final firstName = data['firstName'] ?? '';
                final lastName  = data['lastName']  ?? '';
                userName  = '$firstName $lastName'.trim();
                userRole  = data['role'] ?? 'User';
              }




              return Container(
                decoration: const BoxDecoration(
                  // Gradient mirrors the logo: dark navy → cyan → brand green
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kCyanColor, kSecondaryColor],
                    stops: [0.0, 0.55, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 16,
                  16,
                  16,
                ),
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar circle shows the first letter of the user's name.
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : userEmail.isNotEmpty
                                ? userEmail[0].toUpperCase()
                                : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Full name.
                    Text(
                      userName.isNotEmpty ? userName : userEmail,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Email address in smaller text.
                    Text(
                      userEmail,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Role badge pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: kSecondaryColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: kSecondaryColor.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        userRole[0].toUpperCase() + userRole.substring(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),




          // ── Menu Items ──────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                  // ── Admin menu items ───────────────────────────────────
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _drawerItem(
                        context,
                        icon:  Icons.dashboard_outlined,
                        label: 'Admin Dashboard',
                        route: '/admin/dashboard',
                      ),
                      _drawerItem(
                        context,
                        icon:  Icons.inventory_2_outlined,
                        label: 'Product Management',
                        route: '/admin/products',
                      ),
                      _drawerItem(
                        context,
                        icon:  Icons.fact_check_outlined,
                        label: 'Sale Management',
                        route: '/admin/sales',
                      ),
                      _drawerItem(
                        context,
                        icon:  Icons.people_outline,
                        label: 'User Management',
                        route: '/admin/users',
                      ),
                      const Divider(),
                      _logoutItem(context),
                    ],
                  );
                }
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Single Drawer Item ────────────────────────────────────────────
  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String   label,
    required String   route,
    Color? iconColor,
  }) {
    // Check if this item is currently the active 
    final isActive =
        ModalRoute.of(context)?.settings.name == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? kPrimaryColor : (iconColor ?? Colors.grey.shade700),
      ),
      title: Text(
        label,
        style: TextStyle(
          color:      isActive ? kPrimaryColor : Colors.black87,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      // Navy left border when this is the current page.
      tileColor: isActive
          ? kPrimaryColor.withValues(alpha: 0.06)
          : null,
      onTap: () {
        // Close the drawer first
        Navigator.pop(context);
        // then navigate towards the route chosen
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }

  // ── Helper: Logout Item ───────────────────────────────────────────────────
  Widget _logoutItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title:   const Text('Logout', style: TextStyle(color: Colors.red)),
      //show the confirmation dialogue
      onTap:   () => _showLogoutDialog(context),
    );
  }

  //confirmation of log out
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              // Navigate to login and clear the entire navigation stack.
              Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false,
              );
            },
            child: const Text('Logout',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
