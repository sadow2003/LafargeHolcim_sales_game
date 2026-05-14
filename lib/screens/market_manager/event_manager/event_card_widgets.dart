import 'package:flutter/material.dart';

String _fmtMoney(dynamic raw) {
  final n = ((raw as num?) ?? 0).toDouble();
  if (n == n.truncateToDouble()) return '${n.toInt()} MAD';
  return '$n MAD';
}

class EventStatusBadge extends StatelessWidget {
  const EventStatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class EventRewardSummaryRow extends StatelessWidget {
  const EventRewardSummaryRow({
    super.key,
    required this.rank,
    required this.emoji,
    required this.rawRewards,
  });

  final int                   rank;
  final String                emoji;
  final Map<String, dynamic>  rawRewards;

  @override
  Widget build(BuildContext context) {
    final r      = (rawRewards['$rank'] as Map<String, dynamic>?) ?? {};
    final amount = _fmtMoney(r['amount']);

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
