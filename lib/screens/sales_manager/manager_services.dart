import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../broadcast/broadcast_milestones.dart';
import '../../services/notification_service.dart';

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
    // Step 1: Fetch product point value and category.
    final productDoc    = await _db.collection('products').doc(productId).get();
    final productPoints = (productDoc.data()?['productPoints'] ?? 0) as int;
    final productCat    = (productDoc.data()?['category']      ?? '') as String;
    // Step 2: Award points only when the product matches the active event filter
    final pointsAwarded = await _eventPointsAwarded(
      productId:     productId,
      category:      productCat,
      productPoints: productPoints,
      quantity:      quantity,
    );
    // Step 3: Update sale document — mark approved, clear proof image.
    await _db.collection('sales').doc(saleId).update({
      'status':        'approved',
      'pointsAwarded': pointsAwarded,
      'proofImageUrl': FieldValue.delete(),
    });
    // Step 4: Delete the proof image from Storage.
    await deleteProofImage(data['proofImageUrl'] as String?);
    // Step 5: Add points to salesperson (skip if 0 — non-matching product).
    if (pointsAwarded > 0) {
      await _db.collection('users').doc(userId).update({
        'totalPoints': FieldValue.increment(pointsAwarded),
      });
    }
    // Step 6: Increment progress quantity if the product matches the active
    await _incrementProgressIfMatches(
      userId:    userId,
      productId: productId,
      category:  productCat,
      quantity:  quantity,
    );
    // Step 7: Recalculate all ranks.
    await recalculateRanks();
    // Step 8: Check milestone.
    await checkMilestone(
      userId,
      data['userName'] as String? ?? '',
      quantity,
    );
    // Step 9: Notify the salesperson that their claim was approved.
    await NotificationService.sendSaleClaimDecisionNotification(
      userId: userId,
      productName: data['productName'] as String? ?? '',
      quantity: quantity,
      saleId: saleId,
      approved: true,
      pointsAwarded: pointsAwarded,
    );
    return pointsAwarded;
  }
  // ── Event points filter ──────────────────────────────────────────────────────
  // Returns productPoints × quantity if the product matches the active event's
  // category/product filter, or 0 if it does not. Falls back to awarding full
  // points when no event is configured (no filter to enforce).
  static Future<int> _eventPointsAwarded({
    required String productId,
    required String category,
    required int    productPoints,
    required int    quantity,
  }) async {
    final eventDoc  = await _db.collection('settings').doc('salesEvent').get();
    final eventData = eventDoc.data();

    // No event document — no filter, award freely.
    if (eventData == null) return productPoints * quantity;

    final eventCategory = eventData['productCategory'] as String?;
    // Old event without a category filter — award freely.
    if (eventCategory == null || eventCategory.isEmpty) return productPoints * quantity;

    // Category must match.
    if (category != eventCategory) return 0;

    // If a specific product is required, it must also match.
    final eventProductId = eventData['productId'] as String?;
    if (eventProductId != null &&
        eventProductId.isNotEmpty &&
        eventProductId != productId) {
      return 0;
    }

    return productPoints * quantity;
  }

  // ── Progress quantity helper ─────────────────────────────────────────────────
  static Future<void> _incrementProgressIfMatches({
    required String userId,
    required String productId,
    required String category,
    required int    quantity,
  }) async {
    final eventDoc = await _db.collection('settings').doc('salesEvent').get();
    final eventData = eventDoc.data();
    if (eventData == null) return;

    final eventCategory  = eventData['productCategory'] as String?;
    final eventProductId = eventData['productId']       as String?;

    if (eventCategory == null || category != eventCategory) return;
    if (eventProductId != null && eventProductId != productId) return;

    await _db.collection('users').doc(userId).update({
      'progressQuantity': FieldValue.increment(quantity),
    });
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

    final userId = data['userId'] as String?;
    if (userId != null) {
      await NotificationService.sendSaleClaimDecisionNotification(
        userId: userId,
        productName: data['productName'] as String? ?? '',
        quantity: (data['quantity'] ?? 0) as int,
        saleId: saleId,
        approved: false,
      );
    }
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
