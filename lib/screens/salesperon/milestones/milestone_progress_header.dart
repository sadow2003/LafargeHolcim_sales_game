import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Generates the infinite milestone ladder: 1, 10, then ×10 each step.
/// 1 → 10 → 100 → 1000 → 10000 → 100000 → …
/// Always includes at least 3 milestones beyond [total].
List<int> generateMilestones(int total) {
  final result = <int>[1, 10];
  var m = 100;
  while (result.where((v) => v > total).length < 3) {
    result.add(m);
    m = m * 10;
  }
  return result;
}

class MilestoneProgressHeader extends StatelessWidget {
  final String uid;

  const MilestoneProgressHeader({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
        final next = milestones.firstWhere((m) => m > total);
        final prev = milestones.lastWhere((m) => m <= total, orElse: () => 0);
        final ratio = (total - prev) / (next - prev).clamp(1, double.infinity);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D2200), Color(0xFF1A3D00), Color(0xFF1B3A6B)],
              stops: [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.rocket_launch,
                      color: Color(0xFF8DC21F), size: 28),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Products Sold',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        '$total sold',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Next: $next',
                    style: const TextStyle(
                        color: Color(0xFF8DC21F),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF8DC21F)),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${next - total} more to reach the $next milestone',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
