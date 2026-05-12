import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Coins awarded per finishing rank inside an event
const _coinRules = {1: 500, 2: 300, 3: 200};
const _participationCoins = 100; // any participant outside top 3

class EventManagementService {
  EventManagementService._();

  static final _db = FirebaseFirestore.instance;

  static Stream<DocumentSnapshot> eventStream()=>
    _db.collection('settings').doc('salesEvent').snapshots();

  static Future<void> saveEvent(DateTimeRange range)async{
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await _db.collection('settings').doc('salesEvent').set({
      'startDate': Timestamp.fromDate(range.start),
      'endDate':   Timestamp.fromDate(range.end),
      'createdBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, int>> deleteEvent(DateTime start, DateTime end) async {
    final awards = await distributeCoins(start, end);
    await _db.collection('settings').doc('salesEvent').delete();
    await _resetAllSalespersonPoints();
    return awards;
  }
  static Future<Map<String, int>> distributeCoins(
      DateTime start, DateTime end) async {

    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    // 1. Fetch all approved sales inside the event window
    final salesSnap = await _db
        .collection('sales')
        .where('status',    isEqualTo:            'approved')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo:    Timestamp.fromDate(endOfDay))
        .get();

    // 2. Sum pointsAwarded per user (participation gate: pts must be > 0)
    final pointsByUser = <String, int>{};
    for (final doc in salesSnap.docs) {
      final data = doc.data();
      final uid  = data['userId']        as String? ?? '';
      final pts  = (data['pointsAwarded'] as num?  ?? 0).toInt();
      if (uid.isNotEmpty && pts > 0) {
        pointsByUser[uid] = (pointsByUser[uid] ?? 0) + pts;
      }
    }

    if (pointsByUser.isEmpty) return {}; // nobody participated

    // 3. Rank participants highest → lowest event points
    final ranked = pointsByUser.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 4. Assign coins — rank position starts at 1
    final coinAwards = <String, int>{};
    for (var i = 0; i < ranked.length; i++) {
      final rank = i + 1;
      coinAwards[ranked[i].key] = _coinRules[rank] ?? _participationCoins;
    }

    // 5. Batch-write coin increments to each user
    final batch = _db.batch();
    for (final entry in coinAwards.entries) {
      batch.update(
        _db.collection('users').doc(entry.key),
        {'coins': FieldValue.increment(entry.value)},
      );
    }
    await batch.commit();

    return coinAwards; // returned so the UI can show a summary
  }

  static Future<void> _resetAllSalespersonPoints() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'salesperson')
        .get();

    // Firestore batch limit is 500 — chunk if needed
    const chunkSize = 500;
    for (var i = 0; i < snap.docs.length; i += chunkSize) {
      final batch = _db.batch();
      final chunk = snap.docs.skip(i).take(chunkSize);
      for (final doc in chunk) {
        batch.update(doc.reference, {'totalPoints': 0});
      }
      await batch.commit();
    }
  }
}
