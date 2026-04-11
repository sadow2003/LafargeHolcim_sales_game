import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


// Home Page with Drawer and Logout Functionality
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}




class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(


      // AppBar with title and styling
      appBar: AppBar(
        title: const Text('Home Page'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),



      // Drawer with user info and logout option
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [





            DrawerHeader(
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
                      FirebaseAuth.instance.currentUser?.email
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          'U',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.teal,
                      ),
                    ),
                  ),



                  SizedBox(height: 10),



                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'anonymous@domain.com',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  //add User first name and last ane here if you want to display it in the drawer header
                  

                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.production_quantity_limits),
              title: const Text('Products'),
              onTap: () {
                // Navigate to Profile Page
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Rankings'),
              onTap: () {
                // Navigate to Profile Page
                Navigator.pop(context);
              },
            ),


            Divider(color: Colors.grey),



            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              onTap: () {
                // Navigate to Profile Page
                Navigator.pushNamed(context, '/profile');
              },
            ),
            
            ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
// Perform logout
              try {
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();
                
                // Navigate to login screen (replace current screen)
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', // or your login screen route
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              }
            },
          ),
          ],
        ),
    ),



// Main content of the Home Page
      body: Center(
        child: Text(
          'Welcome to the Home Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
