import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../firebase_options.dart';

class UserService {

  // ── Create User ───────────────────────────────────────────────────────────
  // Uses a secondary FirebaseApp so the admin stays signed in.
  static Future<void> createUser({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    required int    points,
    required void Function(String, Color) snack,
  }) async {
    if (firstName.isEmpty || lastName.isEmpty ||
        email.isEmpty    || password.isEmpty) {
      snack('Please fill in all fields.', Colors.red);
      return;
    }
    if (!email.toLowerCase().endsWith('@lafargeholcim.com')) {
      snack('Email must be a @lafargeholcim.com address.', Colors.red);
      return;
    }
    if (password.length < 8) {
      snack('Password must be at least 8 characters.', Colors.red);
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      snack('Password must contain a lowercase letter.', Colors.red);
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      snack('Password must contain an uppercase letter.', Colors.red);
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      snack('Password must contain a number.', Colors.red);
      return;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;`~/]').hasMatch(password)) {
      snack('Password must contain a special character.', Colors.red);
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
      snack('User "$firstName $lastName" created.', Colors.green);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      snack(authError(e.code), Colors.red);
    } catch (e) {
      if (!context.mounted) return;
      snack('Error: $e', Colors.red);
    } finally {
      // Always clean up the secondary app to avoid resource leaks.
      await secondaryApp?.delete();
    }
  }



  // ── Update User ───────────────────────────────────────────────────────────
  static Future<void> updateUser({
    required BuildContext context,
    required String uid,
    required String firstName,
    required String lastName,
    required String role,
    required int    points,
    required void Function(String, Color) snack,
  }) async {
    if (firstName.isEmpty || lastName.isEmpty) {
      snack('Name cannot be empty.', Colors.red);
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
      await recalculateRanks();

      snack('User updated successfully.', Colors.green);
    } catch (e) {
      snack('Error updating user: $e', Colors.red);
    }
  }



  // ── Delete User ───────────────────────────────────────────────────────────
  static Future<void> deleteUser({
    required BuildContext context,
    required String uid,
    required String name,
    required void Function(String, Color) snack,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await recalculateRanks();
      if (!context.mounted) return;
      snack('"$name" removed.', Colors.orange);
    } catch (e) {
      if (!context.mounted) return;
      snack('Error deleting user: $e', Colors.red);
    }
  }



  // ── Recalculate Ranks ─────────────────────────────────────────────────────
  static Future<void> recalculateRanks() async {
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
  static String authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'This email is already registered.';
      case 'invalid-email':        return 'Invalid email address.';
      case 'weak-password':        return 'Password is too weak (min 8 chars, upper, lower, number, special).';
      default:                     return 'Auth error: $code';
    }
  }
}
