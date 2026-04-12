import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late final User? currentUser;
  late final FirebaseFirestore firestore;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    firestore = FirebaseFirestore.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header with User Info
          FutureBuilder<DocumentSnapshot>(
            future: firestore.collection('users').doc(currentUser!.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              }

              String userName = 'User';
              String userEmail = currentUser?.email ?? 'Unknown';

              if (snapshot.hasData && snapshot.data!.exists) {
                final userData =
                    snapshot.data!.data() as Map<String, dynamic>;
                final firstName = userData['firstName'] ?? '';
                final lastName = userData['lastName'] ?? '';
                userName = '$firstName $lastName'.trim();
              }

              return DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.teal,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : userEmail[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userName.isNotEmpty ? userName : userEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Home Menu Item
          ListTile(
            leading: const Icon(Icons.home, color: Colors.teal),
            title: const Text('Home'),
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
          ),

          // Profile Menu Item
          ListTile(
            leading: const Icon(Icons.person, color: Colors.teal),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),

// Products Menu Item
           ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.teal),
            title: const Text('Products'),
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
          ),


// Ranking Menu Item
           ListTile(
            leading: const Icon(Icons.star, color: Colors.teal),
            title: const Text('Ranking'),
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
          ),

          const Divider(),




          // Logout Menu Item
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            textColor: Colors.red,
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }




  // Logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                // Close the dialog
                Navigator.pop(context);
                // Close the drawer
                Navigator.pop(context);
                // Navigate to login and clear all previous routes
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}