import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_service.dart';

// ── Add / Edit Dialog ─────────────────────────────────────────────────────────
void showUserDialog(
  BuildContext context, {
  required QueryDocumentSnapshot? existing,
  required void Function(String, Color) snack,
}) {
  final isEdit = existing != null;
  final data   = isEdit ? existing.data() as Map<String, dynamic> : {};

  final firstNameCtrl = TextEditingController(text: data['firstName'] ?? '');
  final lastNameCtrl  = TextEditingController(text: data['lastName']  ?? '');
  final emailCtrl     = TextEditingController(text: data['email']     ?? '');
  final passwordCtrl  = TextEditingController();
  final pointsCtrl    = TextEditingController(
      text: (data['totalPoints'] ?? 0).toString());
  String selectedRole = data['role'] ?? 'salesperson';
  bool   obscure      = true;

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
                        value: 'sales-manager', child: Text('Sales Manager')),
                    DropdownMenuItem(
                        value: 'market-manager', child: Text('Market Manager')),
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
                  await UserService.updateUser(
                    context:   context,
                    uid:       existing.id,
                    firstName: firstNameCtrl.text.trim(),
                    lastName:  lastNameCtrl.text.trim(),
                    role:      selectedRole,
                    points:    int.tryParse(pointsCtrl.text.trim()) ?? 0,
                    snack:     snack,
                  );
                } else {
                  await UserService.createUser(
                    context:   context,
                    firstName: firstNameCtrl.text.trim(),
                    lastName:  lastNameCtrl.text.trim(),
                    email:     emailCtrl.text.trim(),
                    password:  passwordCtrl.text.trim(),
                    role:      selectedRole,
                    points:    int.tryParse(pointsCtrl.text.trim()) ?? 0,
                    snack:     snack,
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
