import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../screens/market_manager/event_manager/event_management_service.dart';

class RankingService {
  // ── Streams ─────────────────────────────────────────────────────────────────

  static Stream<DocumentSnapshot> get resultStream =>
      EventManagementService.lastResultStream();

  static Stream<DocumentSnapshot> get eventStream =>
      FirebaseFirestore.instance
          .collection('settings')
          .doc('salesEvent')
          .snapshots();

  static Stream<QuerySnapshot> get usersStream =>
      FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'salesperson')
          .orderBy('totalPoints', descending: true)
          .limit(10)
          .snapshots();

  static Stream<DocumentSnapshot> get progressChallengeStream =>
      FirebaseFirestore.instance
          .collection('settings')
          .doc('progressChallenge')
          .snapshots();

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns a stable key for a lastEventResult document, used to track
  /// which overlays the user has already dismissed this session.
  static String? resultKey(Map<String, dynamic>? data) {
    final ts = data?['closedAt'];
    if (ts is Timestamp) return ts.microsecondsSinceEpoch.toString();
    return null;
  }

  /// Extracts the top-3 reward amounts from an active event document.
  /// Returns null when no event is active.
  static List<double?>? extractRewards(Map<String, dynamic>? eventData) {
    final rawRewards = eventData?['rewards'] as Map<String, dynamic>?;
    if (rawRewards == null) return null;
    return [
      ((rawRewards['1'] as Map<String, dynamic>?)?['amount'] as num?)?.toDouble(),
      ((rawRewards['2'] as Map<String, dynamic>?)?['amount'] as num?)?.toDouble(),
      ((rawRewards['3'] as Map<String, dynamic>?)?['amount'] as num?)?.toDouble(),
    ];
  }

  /// Builds the motivational rank message shown in the current-user banner.
  static String buildRankMessage(int rank, num myPoints, num top1Points) {
    final diff = top1Points - myPoints;
    switch (rank) {
      case 1:  return 'Congratulation!!!, You are ranked #1 ';
      case 2:  return 'You are ranked #2 ,you are so close only $diff pts left';
      case 3:  return 'You are ranked #3, keep going only $diff pts to go';
      default: return 'You are ranked #$rank — only $diff pts for rank 1';
    }
  }

  /// Animates the leaderboard scroll so the current user's row is visible.
  static void scrollToCurrentUser({
    required String? uid,
    required List<QueryDocumentSnapshot> docs,
    required ScrollController controller,
  }) {
    final idx = docs.indexWhere((d) => d.id == uid);
    if (idx < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) return;
      final target = idx * 72.0;
      final maxExt = controller.position.maxScrollExtent;
      controller.animateTo(
        target.clamp(0.0, maxExt),
        duration: const Duration(milliseconds: 700),
        curve:    Curves.easeOut,
      );
    });
  }

  /// Watches the salesEvent doc and fires [onEnded] / [onActive] at the exact
  /// moment the endDate passes — no per-second polling.
  /// Cancel the returned subscription in dispose().
  static StreamSubscription<DocumentSnapshot> listenEventEnd({
    required void Function() onEnded,
    required void Function() onActive,
  }) {
    Timer? endTimer;
    return eventStream.listen((snap) {
      final data    = snap.data() as Map<String, dynamic>?;
      final endDate = (data?['endDate'] as Timestamp?)?.toDate();

      endTimer?.cancel();
      endTimer = null;

      if (endDate == null) { onActive(); return; }

      final remaining = endDate.difference(DateTime.now());
      if (remaining.isNegative) {
        onEnded();
      } else {
        onActive();
        endTimer = Timer(remaining, onEnded);
      }
    });
  }
}
