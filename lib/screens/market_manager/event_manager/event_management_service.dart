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

  /// Saves (or overwrites) the active event.
  ///
  /// In addition to the date range and top-3 cash prizes, the event now
  /// embeds the progress challenge parameters:
  ///   - [productCategory]: required — only sales of this category count
  ///     toward the progress leaderboard.
  ///   - [productId] / [productName]: optional — when set, only sales of
  ///     that specific product count (ignores other products in the category).
  ///   - [targetQuantity]: the unit goal each salesperson races toward.
  ///
  /// Saving a new event also resets every salesperson's [progressQuantity]
  /// counter to 0 so the new challenge starts from a clean slate.
  static Future<void> saveEvent(
    DateTimeRange      range,
    List<MoneyReward>  rewards, {
    required String productCategory,
    String?         productId,
    String?         productName,
    required int    targetQuantity,
  }) async {
    assert(rewards.length == 3);
    final uid   = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = _db.batch();

    // Reset every salesperson's progress counter for the fresh event.
    final usersSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'salesperson')
        .get();
    for (final doc in usersSnap.docs) {
      batch.update(doc.reference, {'progressQuantity': 0});
    }

    // Build the event payload.
    final payload = <String, dynamic>{
      'startDate':       Timestamp.fromDate(range.start),
      'endDate':         Timestamp.fromDate(range.end),
      'createdBy':       uid,
      'updatedAt':       FieldValue.serverTimestamp(),
      'productCategory': productCategory,
      'targetQuantity':  targetQuantity,
      'rewards': {
        '1': rewards[0].toMap(),
        '2': rewards[1].toMap(),
        '3': rewards[2].toMap(),
      },
    };
    if (productId   != null) payload['productId']   = productId;
    if (productName != null) payload['productName'] = productName;

    batch.set(_db.collection('settings').doc('salesEvent'), payload);
    await batch.commit();

    await _postEventBroadcast(
      'New Sales Event Started!\n'
      '${_filterLabel(productCategory, productName)} — Target: '
      '$targetQuantity ${_unitLabel(productCategory)}.\n'
      'Ends ${_fmtDateTime(range.end)}.',
      phase:       'started',
      category:    productCategory,
      productName: productName,
    );
  }

  /// Closes the event: saves winners + all participants, deletes the event doc,
  /// and resets both [totalPoints] and [progressQuantity] for all salespersons.
  /// Idempotent — returns immediately if the event doc no longer exists.
  static Future<void> deleteEvent(DateTime start, DateTime end) async {
    final eventSnap  = await _db.collection('settings').doc('salesEvent').get();
    if (!eventSnap.exists) return;           // already closed by another client
    final eventData  = eventSnap.data() ?? {};
    final rawRewards = (eventData['rewards'] as Map<String, dynamic>?) ?? {};

    final allRanked = await _resolveAllParticipants();
    await _saveLastEventResult(allRanked, rawRewards);
    await _db.collection('settings').doc('salesEvent').delete();
    await _resetAllSalespersonPoints();

    final category    = eventData['productCategory'] as String? ?? '';
    final productName = eventData['productName']      as String?;
    await _postEventBroadcast(
      'Sales Event Ended!\n'
      '${_filterLabel(category, productName)} — the sales window is now '
      'closed. Check the Rewards screen for the results!',
      phase:       'ended',
      category:    category,
      productName: productName,
    );
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
      'closedAt':     FieldValue.serverTimestamp(),
      'winners':      winners,
      'participants': participants,
    });
  }

  // ── Broadcast helpers ─────────────────────────────────────────────────────

  // Describes the progress filter: the specific product if one was chosen,
  // otherwise just the category.
  static String _filterLabel(String category, String? productName) =>
      (productName != null && productName.isNotEmpty)
          ? 'Product: $productName'
          : 'Category: $category';

  static String _unitLabel(String category) =>
      category == 'Concrete' ? 'm³' : 'tonnes';

  static String _fmtDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  // Posts a system broadcast authored by the current market manager.
  //
  // [phase] and [category]/[productName] are stored alongside the free-text
  // [content] so the broadcast UI can style start vs. end events differently
  // and highlight the product/category the event is about, without having
  // to parse it back out of the message text.
  static Future<void> _postEventBroadcast(
    String content, {
    required String phase,
    required String category,
    String? productName,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userDoc  = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};
    final authorName =
        '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();

    await _db.collection('broadcasts').add({
      'authorId':        uid,
      'authorName':      authorName.isNotEmpty ? authorName : 'System',
      'authorRole':      'market-manager',
      'type':            'event',
      'content':         content,
      'eventPhase':      phase,
      'eventCategory':   category,
      if (productName != null && productName.isNotEmpty)
        'eventProductName': productName,
      'reactions':       {},
      'createdAt':       FieldValue.serverTimestamp(),
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
        batch.update(doc.reference, {
          'totalPoints':    0,
          'progressQuantity': 0,
        });
      }
      await batch.commit();
    }
  }
}
