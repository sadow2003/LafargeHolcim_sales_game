import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../broadcast/broadcast_milestones.dart';

class ManagerService {
  ManagerService._();

  static final _db = FirebaseFirestore.instance;

  // ── One-time cleanup: delete all proof images from approved/rejected sales ──
  // Returns the number of images deleted. Run this once from the admin dashboard
  // to clear the historical images that accumulated before auto-deletion was added.
  static Future<int> cleanupOldProofImages() async {
    final snap = await _db
        .collection('sales')
        .where('status', whereIn: ['approved', 'rejected'])
        .get();

    int deleted = 0;
    for (final doc in snap.docs) {
      final url = (doc.data()['proofImageUrl'] as String?) ?? '';
      if (url.isEmpty) continue;

      await deleteProofImage(url);
      await doc.reference.update({'proofImageUrl': FieldValue.delete()});
      deleted++;
    }
    return deleted;
  }

  // ── Delete proof image from Storage ────────────────────────────────────────
  static Future<void> deleteProofImage(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
    } catch (e) {
      debugPrint('Storage delete skipped: $e');
    }
  }

  // ── Approve Sale ────────────────────────────────────────────────────────────
  // Returns the points awarded so the caller can display them in a snackbar.
  static Future<int> approveSale(
    String saleId,
    Map<String, dynamic> data,
  ) async {
    final userId    = data['userId']    as String?;
    final productId = data['productId'] as String?;
    final quantity  = (data['quantity'] ?? 0) as int;

    if (userId == null || productId == null) {
      throw Exception('Missing userId or productId on sale document.');
    }

    // Step 1: Fetch product point value.
    final productDoc = await _db.collection('products').doc(productId).get();
    final productPoints = (productDoc.data()?['productPoints'] ?? 0) as int;
    final pointsAwarded = productPoints * quantity;

    // Step 2: Update sale document — mark approved, clear proof image.
    await _db.collection('sales').doc(saleId).update({
      'status':        'approved',
      'pointsAwarded': pointsAwarded,
      'proofImageUrl': FieldValue.delete(),
    });

    // Step 3: Delete the proof image from Storage.
    await deleteProofImage(data['proofImageUrl'] as String?);

    // Step 4: Add points to salesperson.
    await _db.collection('users').doc(userId).update({
      'totalPoints': FieldValue.increment(pointsAwarded),
    });

    // Step 5: Recalculate all ranks.
    await recalculateRanks();

    // Step 6: Check milestone.
    await checkMilestone(
      userId,
      data['userName'] as String? ?? '',
      quantity,
    );

    return pointsAwarded;
  }

  // ── Reject Sale ─────────────────────────────────────────────────────────────
  static Future<void> rejectSale(
    String saleId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('sales').doc(saleId).update({
      'status':        'rejected',
      'proofImageUrl': FieldValue.delete(),
    });

    await deleteProofImage(data['proofImageUrl'] as String?);
  }

  // ── Recalculate Ranks ───────────────────────────────────────────────────────
  static Future<void> recalculateRanks() async {
    final usersSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'salesperson')
        .orderBy('totalPoints', descending: true)
        .get();

    final batch = _db.batch();
    for (int i = 0; i < usersSnap.docs.length; i++) {
      batch.update(usersSnap.docs[i].reference, {'rank': i + 1});
    }
    await batch.commit();
  }

  // ── Milestone Check ─────────────────────────────────────────────────────────
  static Future<void> checkMilestone(
    String userId,
    String userName,
    int approvedQty,
  ) async {
    final prevSnap = await _db
        .collection('sales')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .get();

    final newTotal = prevSnap.docs.fold<int>(
      0,
      (acc, d) => acc + ((d.data()['quantity'] as num?)?.toInt() ?? 0),
    );
    final prevTotal = newTotal - approvedQty;

    final milestone = crossedMilestone(prevTotal, newTotal);
    if (milestone == null) return;

    final managerUid  = FirebaseAuth.instance.currentUser?.uid ?? '';
    final managerDoc  = await _db.collection('users').doc(managerUid).get();
    final managerData = managerDoc.data() ?? {};
    final managerName =
        '${managerData['firstName'] ?? ''} ${managerData['lastName'] ?? ''}'
            .trim();

    await _db.collection('broadcasts').add({
      'authorId':        managerUid,
      'authorName':      managerName.isNotEmpty ? managerName : 'System',
      'authorRole':      'sales-manager',
      'type':            'milestone',
      'isMilestone':     true,
      'awardedUserId':   userId,
      'awardedUserName': userName,
      'milestoneCount':  milestone,
      'content':
          '$userName just sold $milestone product${milestone == 1 ? '' : 's'}!',
      'reactions': {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
