import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/screens/admin/_buildDrawer_Admin.dart';
import '../../firebase_options.dart';
import '../../main.dart';
import '../../widgets/gradient_app_bar.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  // Filter: 'all' | 'salesperson' | 'admin'
  String _roleFilter = 'all';

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
            child: Row(
              children: [
                _filterChip('All',         'all'),
                const SizedBox(width: 8),
                _filterChip('Salesperson','salesperson'),
                const SizedBox(width: 8),
                _filterChip('Admin',      'admin'),
              ],
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
                //shows the lading circal
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
                    return _UserCard(
                      uid:  doc.id,
                      data: data,
                      onEdit:   () => _showUserDialog(context, existing: doc),
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
        onPressed: () => _showUserDialog(context, existing: null),
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



  // ── Add / Edit Dialog ─────────────────────────────────────────────────────
  void _showUserDialog(BuildContext context, {required QueryDocumentSnapshot? existing}) {
    final isEdit = existing != null;
    final data   = isEdit ? existing.data() as Map<String, dynamic> : {};

    final firstNameCtrl  = TextEditingController(text: data['firstName'] ?? '');
    final lastNameCtrl   = TextEditingController(text: data['lastName']  ?? '');
    final emailCtrl      = TextEditingController(text: data['email']     ?? '');
    final passwordCtrl   = TextEditingController();
    final pointsCtrl     = TextEditingController(
        text: (data['totalPoints'] ?? 0).toString());
    String selectedRole  = data['role'] ?? 'salesperson';
    bool   obscure       = true;

    showDialog(
      context: context,
      //builds the dialog widget itself, providing the dialog's BuildContext
      builder: (ctx) => StatefulBuilder(
        //adds local state management inside the dialog. Without it, calling setState wouldn't rebuild the dialog's contents, only the page behind it
        builder: (ctx, setDialogState) {

          return AlertDialog(
            title: Text(isEdit ? 'Edit User' : 'Add New User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [



                  // First Name
                  TextField(
                    controller: firstNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),




                  // Last Name
                  TextField(
                    controller: lastNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),



                  // Email — read-only when editing
                  TextField(
                    controller: emailCtrl,
                    enabled: !isEdit,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      hintText: 'name@lafargeholcim.com',
                      helperText: isEdit
                          ? 'Email cannot be changed here'
                          : 'Must be a @lafargeholcim.com address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),





                  // Password — only shown when adding
                  if (!isEdit) ...[
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],






                  // Role Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'salesperson', child: Text('Salesperson')),
                      DropdownMenuItem(
                          value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedRole = v ?? 'salesperson'),
                  ),
                  const SizedBox(height: 12),





                  // Total Points — editable by admin (e.g. corrections)
                  TextField(
                    controller: pointsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Total Points',
                      prefixIcon: Icon(Icons.star_outline),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),


            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (isEdit) {
                    await _updateUser(
                      uid:        existing.id,
                      firstName:  firstNameCtrl.text.trim(),
                      lastName:   lastNameCtrl.text.trim(),
                      role:       selectedRole,
                      points:     int.tryParse(pointsCtrl.text.trim()) ?? 0,
                    );
                  } else {
                    await _createUser(
                      context:   context,
                      firstName: firstNameCtrl.text.trim(),
                      lastName:  lastNameCtrl.text.trim(),
                      email:     emailCtrl.text.trim(),
                      password:  passwordCtrl.text.trim(),
                      role:      selectedRole,
                      points:    int.tryParse(pointsCtrl.text.trim()) ?? 0,
                    );
                  }
                },
                child: Text(isEdit ? 'Save' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }




  // ── Create User ───────────────────────────────────────────────────────────
  // Uses a secondary FirebaseApp so the admin stays signed in.
  Future<void> _createUser({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    required int    points,
  }) async {
    if (firstName.isEmpty || lastName.isEmpty ||
        email.isEmpty    || password.isEmpty) {
      _snack(context, 'Please fill in all fields.', Colors.red);
      return;
    }
    if (!email.toLowerCase().endsWith('@lafargeholcim.com')) {
      _snack(context, 'Email must be a @lafargeholcim.com address.', Colors.red);
      return;
    }
    if (password.length < 6) {
      _snack(context, 'Password must be at least 6 characters.', Colors.red);
      return;
    }

    FirebaseApp? secondaryApp;
    try {
      // Initialise a separate Firebase app instance — the admin's session is
      // in the default app; the new user's account is created in this one.
      secondaryApp = await Firebase.initializeApp(
        name:    'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential    = await secondaryAuth.createUserWithEmailAndPassword(
        email:    email,
        password: password,
      );

      final newUid = credential.user!.uid;

      // Sign out the temporary session immediately.
      await secondaryAuth.signOut();

      // Write the Firestore document.
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'firstName':   firstName,
        'lastName':    lastName,
        'email':       email,
        'role':        role,
        'totalPoints': points,
        'rank':        0,
        'createdAt':   FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      _snack(context, 'User "$firstName $lastName" created.', Colors.green);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      _snack(context, _authError(e.code), Colors.red);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Error: $e', Colors.red);
    } finally {
      // Always clean up the secondary app to avoid resource leaks.
      await secondaryApp?.delete();
    }
  }





  // ── Update User ───────────────────────────────────────────────────────────
  Future<void> _updateUser({
    required String uid,
    required String firstName,
    required String lastName,
    required String role,
    required int    points,
  }) async {
    if (firstName.isEmpty || lastName.isEmpty) {
      if (mounted) _snack(context, 'Name cannot be empty.', Colors.red);
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'firstName':   firstName,
        'lastName':    lastName,
        'role':        role,
        'totalPoints': points,
      });

      // If role or points changed, recalculate ranks.
      await _recalculateRanks();

      if (mounted) {
        _snack(context, 'User updated successfully.', Colors.green);
      }
    } catch (e) {
      if (mounted) _snack(context, 'Error updating user: $e', Colors.red);
    }
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
                      'Their Firestore data will be deleted. '
                      'The login account requires a server action to fully remove.',
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
              await _deleteUser(context, uid, name);
            },
            child: const Text('Delete'),
          ),


        ],
      ),
    );
  }




  // ── Delete User ───────────────────────────────────────────────────────────
  Future<void> _deleteUser(
      BuildContext context, String uid, String name) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await _recalculateRanks();
      if (!context.mounted) return;
      _snack(context, '"$name" removed.', Colors.orange);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Error deleting user: $e', Colors.red);
    }
  }





  // ── Recalculate Ranks ─────────────────────────────────────────────────────
  Future<void> _recalculateRanks() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'salesperson')
        .orderBy('totalPoints', descending: true)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < snap.docs.length; i++) {
      batch.update(snap.docs[i].reference, {'rank': i + 1});
    }
    await batch.commit();
  }





  // ── Helpers ───────────────────────────────────────────────────────────────
  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'This email is already registered.';
      case 'invalid-email':        return 'Invalid email address.';
      case 'weak-password':        return 'Password is too weak (min 6 chars).';
      default:                     return 'Auth error: $code';
    }
  }
}





// ── User Card ─────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final String               uid;
  final Map<String, dynamic> data;
  //save the action of the user 
  final VoidCallback         onEdit;
  final VoidCallback         onDelete;

  const _UserCard({
    required this.uid,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final firstName   = data['firstName']   ?? '';
    final lastName    = data['lastName']    ?? '';
    final email       = data['email']       ?? '';
    final role        = data['role']        ?? 'salesperson';
    final totalPoints = data['totalPoints'] ?? 0;
    final rank        = data['rank']        ?? 0;
    final isAdmin     = role == 'admin';




    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      child: ListTile(
        contentPadding:

            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? kSecondaryColor.withValues(alpha: 0.15)
              : kPrimaryColor.withValues(alpha: 0.1),
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAdmin ? kSecondaryColor : kPrimaryColor,
            ),
          ),
        ),



        title: Text(
          '$firstName $lastName'.trim(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),


        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            Text(email, style: const TextStyle(fontSize: 12)),


            const SizedBox(height: 4),


            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? kSecondaryColor.withValues(alpha: 0.15)
                        : kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'Salesperson',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAdmin ? kSecondaryColor : kPrimaryColor,
                    ),
                  ),
                ),

                if (!isAdmin) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 13, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text('$totalPoints pts',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.military_tech,
                          size: 13, color: Colors.blueGrey.shade400),
                      const SizedBox(width: 2),
                      Text(rank == 0 ? '—' : '#$rank',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),


        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [


            IconButton(
              icon: const Icon(Icons.edit_outlined, color: kPrimaryColor),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),


            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
