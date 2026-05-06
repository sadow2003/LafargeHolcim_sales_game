import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../widgets/_buildDrawer.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'milestone_progress_header.dart';

class MilestoneScreen extends StatelessWidget {
  const MilestoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Milestones'),
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E2040), Color(0xFF1A3A6B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MilestoneProgressHeader(uid: uid),
            const SizedBox(height: 24),
            _MilestoneBadgeList(),
          ],
        ),
      ),
    );
  }
}

class _MilestoneBadgeList extends StatelessWidget {
  static const _milestones = [
    {'count': 1,     'label': 'First Sale',      'icon': Icons.star_outline},
    {'count': 10,    'label': '10 Products',      'icon': Icons.local_fire_department_outlined},
    {'count': 100,   'label': '100 Products',     'icon': Icons.bolt_outlined},
    {'count': 1000,  'label': '1 000 Products',   'icon': Icons.military_tech_outlined},
    {'count': 10000, 'label': '10 000 Products',  'icon': Icons.emoji_events_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestone Badges',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._milestones.map((m) {
          final icon = m['icon'] as IconData;
          final label = m['label'] as String;
          final count = m['count'] as int;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, color: kSecondaryColor, size: 28),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text('Sell $count product${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
