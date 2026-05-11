import 'package:flutter/material.dart';

class StoreItem {
  final String id;
  final String name;
  final String description;
  final int coinCost;
  final String category;
  final IconData icon;
  final Color color;

  const StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.coinCost,
    required this.category,
    required this.icon,
    required this.color,
  });
}

const List<String> kStoreCategories = [
  'All',
  'Vouchers',
  'Merchandise',
  'Experiences',
  'Days Off',
];

const List<StoreItem> kStoreItems = [
  StoreItem(
    id: 'voucher_cafe_50',
    name: 'Café Voucher',
    description: '50 DZD coffee voucher redeemable at the office cafeteria.',
    coinCost: 100,
    category: 'Vouchers',
    icon: Icons.local_cafe_outlined,
    color: Color(0xFF6F4E37),
  ),
  StoreItem(
    id: 'voucher_lunch_200',
    name: 'Lunch Voucher',
    description: '200 DZD lunch voucher at the company restaurant.',
    coinCost: 350,
    category: 'Vouchers',
    icon: Icons.restaurant_outlined,
    color: Color(0xFFE65100),
  ),
  StoreItem(
    id: 'merch_tshirt',
    name: 'LafargeHolcim T-Shirt',
    description: 'Official branded polo shirt. Available in S/M/L/XL.',
    coinCost: 500,
    category: 'Merchandise',
    icon: Icons.checkroom_outlined,
    color: Color(0xFF1B3A6B),
  ),
  StoreItem(
    id: 'merch_mug',
    name: 'Branded Mug',
    description: 'Ceramic mug with the LafargeHolcim logo.',
    coinCost: 200,
    category: 'Merchandise',
    icon: Icons.emoji_food_beverage_outlined,
    color: Color(0xFF00AEEF),
  ),
  StoreItem(
    id: 'merch_backpack',
    name: 'Company Backpack',
    description: 'High-quality branded backpack for daily use.',
    coinCost: 1200,
    category: 'Merchandise',
    icon: Icons.backpack_outlined,
    color: Color(0xFF8DC21F),
  ),
  StoreItem(
    id: 'exp_teambuilding',
    name: 'Team-Building Day',
    description: 'Join the next team-building outing (subject to availability).',
    coinCost: 2000,
    category: 'Experiences',
    icon: Icons.groups_outlined,
    color: Color(0xFF7B1FA2),
  ),
  StoreItem(
    id: 'exp_training',
    name: 'Online Course Access',
    description: '3-month access to a professional development platform.',
    coinCost: 1500,
    category: 'Experiences',
    icon: Icons.school_outlined,
    color: Color(0xFF00796B),
  ),
  StoreItem(
    id: 'dayoff_half',
    name: 'Half-Day Off',
    description: 'One approved half-day off — coordinate with your manager.',
    coinCost: 800,
    category: 'Days Off',
    icon: Icons.beach_access_outlined,
    color: Color(0xFFF57C00),
  ),
  StoreItem(
    id: 'dayoff_full',
    name: 'Full Day Off',
    description: 'One approved extra day off — coordinate with your manager.',
    coinCost: 1500,
    category: 'Days Off',
    icon: Icons.wb_sunny_outlined,
    color: Color(0xFFD32F2F),
  ),
];
