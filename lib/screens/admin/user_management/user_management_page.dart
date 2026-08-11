import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/widgets/_buildDrawer.dart';
import '../../../main.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'user_card.dart';
import 'user_dialog.dart';
import 'user_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  // Filter: 'all' | 'salesperson' | 'sales-manager' | 'market-manager' | 'admin'
  String _roleFilter = 'all';

  // ── Admin-only guard ──────────────────────────────────────────────────────
  // Checked once on init; redirects non-admins to login immediately.
  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _redirectToLogin();
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!mounted) return;

    final role = doc.data()?['role'] ?? '';
    if (role != 'admin') {
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    });
  }
  // ─────────────────────────────────────────────────────────────────────────



  @override
  Widget build(BuildContext context) {
    return Scaffold(



      appBar: GradientAppBar(
        title: 'Manage Users',
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



      body: Column(
        children: [



          // ── Role Filter ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All',            'all'),
                  const SizedBox(width: 8),
                  _filterChip('Salesperson',    'salesperson'),
                  const SizedBox(width: 8),
                  _filterChip('Sales Manager',  'sales-manager'),
                  const SizedBox(width: 8),
                  _filterChip('Market Manager', 'market-manager'),
                  const SizedBox(width: 8),
                  _filterChip('Admin',          'admin'),
                ],
              ),
            ),
          ),



          // ── User List ──────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // No orderBy in the query — we sort client-side to avoid
              // composite index requirements and show new users immediately.
              stream: _roleFilter == 'all'
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .snapshots()
                      //get it base on the role of the user
                  : FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: _roleFilter)
                      .snapshots(),



              builder: (context, snapshot) {
                //shows the loading circle
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                //shows error message
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Sort alphabetically by first name on the client side.
                final docs = [...(snapshot.data?.docs ?? [])]
                  ..sort((a, b) {
                    final aName = (a.data() as Map)['firstName'] as String? ?? '';
                    final bName = (b.data() as Map)['firstName'] as String? ?? '';
                    return aName.toLowerCase().compareTo(bName.toLowerCase());
                  });



                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No users found.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }



                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc  = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return UserCard(
                      uid:      doc.id,
                      data:     data,
                      onEdit:   () => showUserDialog(context,
                          existing: doc, snack: _snack),
                      onDelete: () => _confirmDelete(context, doc.id, data),
                    );
                  },
                );


              },
            ),
          ),
        ],
      ),
      //floating action button for adding users
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showUserDialog(context, existing: null, snack: _snack),
        icon:  const Icon(Icons.person_add_alt_1),
        label: const Text('Add User'),
      ),
    );
  }



  // ── Filter Chip ───────────────────────────────────────────────────────────
  Widget _filterChip(String label, String value) {
    final selected = _roleFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: kPrimaryColor,
      labelStyle: TextStyle(
        color:      selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _roleFilter = value),
    );
  }



  // ── Delete Confirmation ───────────────────────────────────────────────────
  void _confirmDelete(
      BuildContext context, String uid, Map<String, dynamic> data) {
    final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$name"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "The user's data will be permanently deleted. ",
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [


          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),


          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await UserService.deleteUser(
                context: context,
                uid:     uid,
                name:    name,
                snack:   _snack,
              );
            },
            child: const Text('Delete'),
          ),


        ],
      ),
    );
  }



  // ── Helpers ───────────────────────────────────────────────────────────────
  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}
