import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../widgets/_buildDrawer.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'milestone_progress_header.dart';

class MilestoneScreen extends StatelessWidget {
  const MilestoneScreen({super.key});


//__________________________ui______________________________________
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sales')
              .where('userId', isEqualTo: uid)
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, snap) {
            final total = (snap.data?.docs ?? []).fold<int>(
              0,
              (acc, d) =>
                  acc +
                  ((d.data() as Map<String, dynamic>)['quantity'] as num? ?? 0)
                      .toInt(),
            );

            final milestones = generateMilestones(total);

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: milestones.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MilestoneProgressHeader(uid: uid),
                      const SizedBox(height: 24),
                      const Text(
                        'Milestone Badges',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }

                final milestone = milestones[index - 1];
                final reached = total >= milestone;

                return _MilestoneBadge(
                  count: milestone,
                  reached: reached,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MilestoneBadge extends StatelessWidget {
  final int count;
  final bool reached;

  const _MilestoneBadge({required this.count, required this.reached});

  IconData get _icon {
    if (count == 1)    return Icons.star_outline;
    if (count <= 10)   return Icons.local_fire_department_outlined;
    if (count <= 50)   return Icons.bolt_outlined;
    if (count <= 100)  return Icons.military_tech_outlined;
    if (count <= 500)  return Icons.emoji_events_outlined;
    if (count <= 1000) return Icons.workspace_premium_outlined;
    return Icons.diamond_outlined;
  }

  String get _label {
    if (count == 1) return 'First Sale';
    return '$count Products';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: reached
            ? kSecondaryColor.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: reached
              ? kSecondaryColor.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
          width: reached ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            reached ? Icons.check_circle_outline : _icon,
            color: reached ? kSecondaryColor : Colors.white30,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: TextStyle(
                    color: reached ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  reached ? 'Completed!' : 'Sell $count product${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: reached ? kSecondaryColor : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (reached)
            const Icon(Icons.verified, color: Color(0xFF8DC21F), size: 18),
        ],
      ),
    );
  }
}
