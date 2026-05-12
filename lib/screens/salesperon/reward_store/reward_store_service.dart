import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lafargeholcim_sales_game/models/store_item.dart';

/// Data returned after a successful redemption — used to generate the PDF receipt.
class RedemptionReceipt {
  final String redemptionId;
  final String userName;
  final String userEmail;
  final StoreItem item;
  final DateTime redeemedAt;

  const RedemptionReceipt({
    required this.redemptionId,
    required this.userName,
    required this.userEmail,
    required this.item,
    required this.redeemedAt,
  });
}

class RewardStoreService {

  //private named constructor.
  RewardStoreService._();

  static final _db = FirebaseFirestore.instance;

  /// Deducts coins, records the redemption, and returns a [RedemptionReceipt]
  /// containing all data needed to generate the PDF.
  static Future<RedemptionReceipt> redeem({
    required String userId,
    required StoreItem item,
  }) async {
    final userRef = _db.collection('users').doc(userId);

    // Fetch user profile for the receipt (name + email)
    final userSnap = await userRef.get();
    final userData = userSnap.data() ?? {};
    final firstName = userData['firstName'] ?? '';
    final lastName  = userData['lastName']  ?? '';
    final userName  = '$firstName $lastName'.trim();
    final userEmail = userData['email'] ?? '';

    late String redemptionId;
    final now = DateTime.now();

    await _db.runTransaction((tx) async {
      final snap         = await tx.get(userRef);
      final currentCoins = (snap.data()?['coins'] ?? 0) as int;

      if (currentCoins < item.coinCost) {
        throw Exception('Insufficient coins');
      }

      tx.update(userRef, {'coins': currentCoins - item.coinCost});

      // Create the redemption document and capture its auto-generated ID
      final redemptionRef = _db.collection('redemptions').doc();
      redemptionId = redemptionRef.id;

      tx.set(redemptionRef, {
        'userId':      userId,
        'userName':    userName,
        'userEmail':   userEmail,
        'itemId':      item.id,
        'itemName':    item.name,
        'coinCost':    item.coinCost,
        'redeemedAt':  FieldValue.serverTimestamp(),
        'status':      'pending',
      });
    });

    return RedemptionReceipt(
      redemptionId: redemptionId,
      userName:     userName,
      userEmail:    userEmail,
      item:         item,
      redeemedAt:   now,
    );
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
