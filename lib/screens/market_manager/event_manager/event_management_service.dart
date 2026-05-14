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

  // ── Event CRUD ────────────────────────────────────────────────────────────

  /// Saves (or overwrites) the active event with date range and top-3 cash prizes.
  static Future<void> saveEvent(
    DateTimeRange range,
    List<MoneyReward> rewards,
  ) async {
    assert(rewards.length == 3);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await _db.collection('settings').doc('salesEvent').set({
      'startDate': Timestamp.fromDate(range.start),
      'endDate':   Timestamp.fromDate(range.end),
      'createdBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'rewards': {
        '1': rewards[0].toMap(),
        '2': rewards[1].toMap(),
        '3': rewards[2].toMap(),
      },
    });
  }

  /// Closes the event: saves winners + all participants, deletes the event doc, resets points.
  static Future<void> deleteEvent(DateTime start, DateTime end) async {
    final eventSnap  = await _db.collection('settings').doc('salesEvent').get();
    final eventData  = eventSnap.data() ?? {};
    final rawRewards = (eventData['rewards'] as Map<String, dynamic>?) ?? {};

    final allRanked = await _resolveAllParticipants();
    await _saveLastEventResult(allRanked, rawRewards);
    await _db.collection('settings').doc('salesEvent').delete();
    await _resetAllSalespersonPoints();
  }

  // ── Rank ALL participants by their current totalPoints ───────────────────
  // Uses users.totalPoints directly (same source as the leaderboard) so the
  // stored winners always match what salespersons saw during the event.

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

  // ── Save results: top-3 get cash prizes, rest are participants ────────────

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
      'closedAt':    FieldValue.serverTimestamp(),
      'winners':     winners,
      'participants': participants,
    });
  }

  // ── Points reset ──────────────────────────────────────────────────────────

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
        batch.update(doc.reference, {'totalPoints': 0});
      }
      await batch.commit();
    }
  }
}
