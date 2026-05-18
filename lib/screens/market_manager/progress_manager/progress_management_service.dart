import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing the single `settings/progressChallenge` document.
///
/// Firestore shape:
/// ```json
/// {
///   "isActive":     true,
///   "targetPoints": 1000,
///   "title":        "Q2 Challenge",
///   "createdAt":    Timestamp,
///   "createdBy":    "uid"
/// }
/// ```
class ProgressChallengeService {
  ProgressChallengeService._();

  static final _db  = FirebaseFirestore.instance;
  static final _ref = _db.collection('settings').doc('progressChallenge');

  // ── Stream ────────────────────────────────────────────────────────────────

  static Stream<DocumentSnapshot> stream() => _ref.snapshots();

  // ── Write operations ──────────────────────────────────────────────────────

  /// Creates or fully replaces the progress challenge and activates it.
  static Future<void> save({
    required String title,
    required int    targetPoints,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await _ref.set({
      'isActive':     true,
      'targetPoints': targetPoints,
      'title':        title,
      'createdAt':    FieldValue.serverTimestamp(),
      'createdBy':    uid,
    });
  }

  /// Flips the `isActive` flag without touching anything else.
  static Future<void> setActive(bool active) =>
      _ref.update({'isActive': active});

  /// Permanently removes the progress challenge from Firestore.
  static Future<void> delete() => _ref.delete();
}
