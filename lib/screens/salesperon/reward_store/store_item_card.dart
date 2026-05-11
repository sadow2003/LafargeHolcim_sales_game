import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/main.dart';
import 'package:lafargeholcim_sales_game/models/store_item.dart';
import 'reward_store_service.dart';

class StoreItemCard extends StatelessWidget {
  const StoreItemCard({
    super.key,
    required this.item,
    required this.userCoins,
    required this.userId,
  });

  final StoreItem item;
  final int userCoins;
  final String userId;

  bool get _canAfford => userCoins >= item.coinCost;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ItemIconHeader(item: item, canAfford: _canAfford),
          Expanded(child: _ItemInfo(item: item, canAfford: _canAfford, onRedeem: () => _confirmRedeem(context))),
        ],
      ),
    );
  }

  void _confirmRedeem(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(item.icon, color: item.color, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${item.coinCost} coins will be deducted',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processRedemption(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRedemption(BuildContext context) async {
    try {
      await RewardStoreService.redeem(userId: userId, item: item);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('${item.name} redeemed! Check with HR/admin.')),
              ],
            ),
            backgroundColor: kSecondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Redemption failed. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

// ── Icon header section of the card ───────────────────────────────────────

class _ItemIconHeader extends StatelessWidget {
  const _ItemIconHeader({required this.item, required this.canAfford});

  final StoreItem item;
  final bool canAfford;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      color: item.color.withValues(alpha: 0.12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(item.icon, size: 44, color: item.color),
          if (!canAfford)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Need more',
                  style: TextStyle(fontSize: 9, color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Text / action section of the card ─────────────────────────────────────

class _ItemInfo extends StatelessWidget {
  const _ItemInfo({
    required this.item,
    required this.canAfford,
    required this.onRedeem,
  });

  final StoreItem item;
  final bool canAfford;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              item.description,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
              const SizedBox(width: 3),
              Text(
                '${item.coinCost}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              const Spacer(),
              GestureDetector(
                onTap: canAfford ? onRedeem : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: canAfford ? kPrimaryColor : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Redeem',
                    style: TextStyle(
                      fontSize: 11,
                      color: canAfford ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
