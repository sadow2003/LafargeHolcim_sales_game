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

  late final Future<DocumentSnapshot> _userFuture = FirebaseFirestore.instance
      .collection('users')
      .doc(_currentUser?.uid)
      .get();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String userName  = '';
          String userEmail = _currentUser?.email ?? '';
          String userRole  = 'salesperson';
          String? photoUrl;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data      = snapshot.data!.data() as Map<String, dynamic>;
            final firstName = data['firstName'] ?? '';
            final lastName  = data['lastName']  ?? '';
            userName  = '$firstName $lastName'.trim();
            userRole  = data['role'] ?? 'salesperson';
            photoUrl  = data['photoUrl'];
          }

          return Column(
            children: [
              _buildHeader(context, userName, userEmail, userRole, photoUrl),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ..._menuItems(context, userRole),
                    const Divider(),
                    _logoutItem(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, String userEmail,
      String userRole, String? photoUrl) {
    final displayName = userName.isNotEmpty ? userName : userEmail;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      decoration: const BoxDecoration(
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
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            userEmail,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: kSecondaryColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSecondaryColor.withValues(alpha: 0.6)),
            ),
            child: Text(
              userRole.isNotEmpty
                  ? userRole[0].toUpperCase() + userRole.substring(1)
                  : '',
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
  }

  List<Widget> _menuItems(BuildContext context, String role) {
    switch (role) {
      case 'admin':
        return [
          _drawerItem(context,
              icon: Icons.dashboard_outlined,
              label: 'Admin Dashboard',
              route: '/admin/dashboard'),
          _drawerItem(context,
              icon: Icons.inventory_2_outlined,
              label: 'Product Management',
              route: '/admin/products'),
          _drawerItem(context,
              icon: Icons.fact_check_outlined,
              label: 'Sale Management',
              route: '/admin/sales'),
          _drawerItem(context,
              icon: Icons.people_outline,
              label: 'User Management',
              route: '/admin/users'),
          _drawerItem(context,
              icon: Icons.tv_outlined,
              label: 'Broadcast',
              route: '/broadcast'),
        ];
      case 'manager':
        return [
          _drawerItem(context,
              icon: Icons.dashboard_outlined,
              label: 'Manager Dashboard',
              route: '/manager/dashboard'),
          _drawerItem(context,
              icon: Icons.inventory_2_outlined,
              label: 'Product Management',
              route: '/manager/products'),
          _drawerItem(context,
              icon: Icons.fact_check_outlined,
              label: 'Sale Management',
              route: '/manager/sales'),
          _drawerItem(context,
              icon: Icons.tv_outlined,
              label: 'Broadcast',
              route: '/broadcast'),
        ];
      default: // salesperson
        return [
          _drawerItem(context,
              icon: Icons.home_outlined,
              label: 'Dashboard',
              route: '/home'),
          _drawerItem(context,
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              route: '/products'),
          _drawerItem(context,
              icon: Icons.leaderboard_outlined,
              label: 'Leaderboard',
              route: '/rankings'),
          _drawerItem(context,
              icon: Icons.person_outline,
              label: 'My Profile',
              route: '/profile'),
          _drawerItem(context,
              icon: Icons.add_shopping_cart,
              label: 'Submit Sale',
              route: '/saleclaim',
              iconColor: kSecondaryColor),
          _drawerItem(context,
              icon: Icons.tv_outlined,
              label: 'Broadcast',
              route: '/broadcast'),
        ];
    }
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    Color? iconColor,
  }) {
    final isActive = ModalRoute.of(context)?.settings.name == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? kPrimaryColor : (iconColor ?? Colors.grey.shade700),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? kPrimaryColor : Colors.black87,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? kPrimaryColor.withValues(alpha: 0.06) : null,
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }

  Widget _logoutItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Logout', style: TextStyle(color: Colors.red)),
      onTap: () => _showLogoutDialog(context),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
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
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            child:
                const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
