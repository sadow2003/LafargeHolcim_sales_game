import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/models/store_item.dart';

class RewardStoreService {
  RewardStoreService._();

  static final _db = FirebaseFirestore.instance;

  /// Deducts [item.coinCost] from the user's coin balance and records the
  /// redemption as a pending request in the `redemptions` collection.
  static Future<void> redeem({
    required String userId,
    required StoreItem item,
  }) async {
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final currentCoins = (snap.data()?['coins'] ?? 0) as int;

      if (currentCoins < item.coinCost) {
        throw Exception('Insufficient coins');
      }

      tx.update(userRef, {'coins': currentCoins - item.coinCost});

      tx.set(_db.collection('redemptions').doc(), {
        'userId': userId,
        'itemId': item.id,
        'itemName': item.name,
        'coinCost': item.coinCost,
        'redeemedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    });
  }

  /// Live stream of the current user's coin balance.
  static Stream<int> coinsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) => (snap.data()?['coins'] ?? 0) as int);
  }
}
