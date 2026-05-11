import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lafargeholcim_sales_game/main.dart';
import 'package:lafargeholcim_sales_game/widgets/gradient_app_bar.dart';
import 'package:lafargeholcim_sales_game/widgets/_buildDrawer.dart';
import 'coin_balance_banner.dart';
import 'package:lafargeholcim_sales_game/models/store_item.dart';
import 'reward_store_service.dart';
import 'store_item_card.dart';

class RewardStorePage extends StatefulWidget {
  const RewardStorePage({super.key});

  @override
  State<RewardStorePage> createState() => _RewardStorePageState();
}

class _RewardStorePageState extends State<RewardStorePage> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  String _selectedCategory = 'All';

  List<StoreItem> get _filteredItems => _selectedCategory == 'All'
      ? kStoreItems
      : kStoreItems.where((i) => i.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Reward Store'),
      drawer: const AppDrawer(),
      body: StreamBuilder<int>(
        stream: RewardStoreService.coinsStream(_uid ?? ''),
        builder: (context, snapshot) {
          final coins = snapshot.data ?? 0;

          return Column(
            children: [
              CoinBalanceBanner(coins: coins),
              _CategoryFilter(
                selected: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
              ),
              Expanded(
                child: _StoreGrid(
                  items: _filteredItems,
                  userCoins: coins,
                  userId: _uid ?? '',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Category filter chip row ───────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kStoreCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = kStoreCategories[i];
          final isActive = cat == selected;
          return ChoiceChip(
            label: Text(cat),
            selected: isActive,
            onSelected: (_) => onSelected(cat),
            selectedColor: kPrimaryColor,
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
            side: BorderSide(color: isActive ? kPrimaryColor : Colors.grey.shade300),
          );
        },
      ),
    );
  }
}

// ── 2-column grid of store cards ───────────────────────────────────────────

class _StoreGrid extends StatelessWidget {
  const _StoreGrid({
    required this.items,
    required this.userCoins,
    required this.userId,
  });

  final List<StoreItem> items;
  final int userCoins;
  final String userId;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items in this category.', style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => StoreItemCard(
        item: items[i],
        userCoins: userCoins,
        userId: userId,
      ),
    );
  }
}
