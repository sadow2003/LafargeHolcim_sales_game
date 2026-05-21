import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'event_reward.dart';

class EventManagementService {
  EventManagementService._();

  static final _db = FirebaseFirestore.instance;

  // ── Streams ───────────────────────────────────────────────────────────────

  static Stream<DocumentSnapshot> eventStream() =>
      _db.collection('settings').doc('salesEvent').snapshots();

  static Stream<DocumentSnapshot> lastResultStream() =>
      _db.collection('settings').doc('lastEventResult').snapshots();
  

  static Future<void> saveEvent(
    DateTimeRange range,
    List<MoneyReward> rewards,{
      required String productCatregory,
      String? productId,
      String? productName,
      required int targetQuantity,
    }) async {
      assert(rewards.length == 3);
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final batch =_db.batch();

      final usersSnap = await _db
          .collection('users')
          .where('role',isEqualTo: 'salesperson')
          .get();
      for (final doc in usersSnap.docs){
        batch.update(doc.reference, {'progressQuantity':0});
      }

      final payload = <String,dynamic>{
        'startDate': Timestamp.fromDate(range.start),
        'endDate': Timestamp.fromDate(range.end),
        'createdBy':uid ,
        'updatedAt': FieldValue.serverTimestamp(),
        'productCategory': productCatregory,
        'targetQuantity':targetQuantity,
        'rewards':{
          '1':rewards[0].toMap(),
          '2':rewards[1].toMap(),
          '3' :rewards[2].toMap(),
        },
      };

      if (productId != null) payload['productId'] =productId;
      if (productName != null) payload ['productName'] =productName;

      batch.set(_db.collection('settings').doc('salesEvent'),payload);
      await batch.commit();
    }
    static Future<void> deleteEvent(DateTime start, DateTime end) async {
    final eventSnap  = await _db.collection('settings').doc('salesEvent').get();
    if (!eventSnap.exists) return;           // already closed by another client
    final eventData  = eventSnap.data() ?? {};
    final rawRewards = (eventData['rewards'] as Map<String, dynamic>?) ?? {};

    final allRanked = await _resolveAllParticipants();
    await _saveLastEventResult(allRanked, rawRewards);
    await _db.collection('settings').doc('salesEvent').delete();
    await _resetAllSalespersonPoints();
  }
   static Future<List<Map<String, dynamic>>> _resolveAllParticipants() async {
    final usersSnap = await _db
        .collection('users')
        .where('role',        isEqualTo:    'salesperson')
        .where('totalPoints', isGreaterThan: 0)
        .orderBy('totalPoints', descending: true)
        .get();

    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < usersSnap.docs.length; i++) {
      final d     = usersSnap.docs[i].data();
      final uid   = usersSnap.docs[i].id;
      final first = (d['firstName'] as String?) ?? '';
      final last  = (d['lastName']  as String?) ?? '';
      String userName = '$first $last'.trim();
      if (userName.isEmpty) userName = (d['email'] as String?) ?? 'Participant';
      result.add({'rank': i + 1, 'userId': uid, 'userName': userName});
    }
    return result;
  }
   static Future<void> _saveLastEventResult(
    List<Map<String, dynamic>> allRanked,
    Map<String, dynamic> rawRewards,
  ) async {
    final winners      = <Map<String, dynamic>>[];
    final participants = <Map<String, dynamic>>[];

    for (final entry in allRanked) {
      final rank = entry['rank'] as int;
      if (rank <= 3) {
        final rewardRaw = (rawRewards['$rank'] as Map<String, dynamic>?) ?? {};
        winners.add({
          ...entry,
          'rewardAmount': ((rewardRaw['amount'] as num?) ?? 0).toDouble(),
        });
      } else {
        participants.add(entry);
      }
    }

    await _db.collection('settings').doc('lastEventResult').set({
      'closedAt':     FieldValue.serverTimestamp(),
      'winners':      winners,
      'participants': participants,
    });
  }
  static Future<void> _resetAllSalespersonPoints() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'salesperson')
        .get();

    const chunkSize = 500;
    for (var i = 0; i < snap.docs.length; i += chunkSize) {
      final batch = _db.batch();
      final chunk = snap.docs.skip(i).take(chunkSize);
      for (final doc in chunk) {
        batch.update(doc.reference, {
          'totalPoints': 0,
          'progressQuantity': 0,
        });
      }
      await batch.commit();
    }
  }
}