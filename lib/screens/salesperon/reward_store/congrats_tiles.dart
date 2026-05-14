import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';

String fmtMoney(dynamic raw) {
  final n = ((raw as num?) ?? 0).toDouble();
  if (n == n.truncateToDouble()) return '${n.toInt()} MAD';
  return '$n MAD';
}

// ── Winner tile (top 3) ───────────────────────────────────────────────────────

class WinnerTile extends StatelessWidget {
  const WinnerTile({
    super.key,
    required this.winner,
    required this.isMe,
    required this.emojis,
    required this.rankColors,
  });

  final Map<String, dynamic> winner;
  final bool                 isMe;
  final Map<int, String>     emojis;
  final Map<int, Color>      rankColors;

  @override
  Widget build(BuildContext context) {
    final rank   = winner['rank']      as int;
    final name   = (winner['userName'] as String?) ?? 'Participant';
    final amount = fmtMoney(winner['rewardAmount']);
    final color  = rankColors[rank]!;

    return Container(
      decoration: BoxDecoration(
        color: isMe ? Colors.green.shade50 : color.withValues(alpha: 0.07),
        border: Border.all(
          color: isMe ? Colors.green.shade300 : color.withValues(alpha: 0.4),
          width: isMe ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(emojis[rank] ?? '$rank',
            style: const TextStyle(fontSize: 28)),
        title: Row(
          children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (isMe) const YouBadge(),
          ],
        ),
        subtitle: Text(
          amount,
          style: const TextStyle(
            fontSize:   13,
            fontStyle:  FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Participant tile (rank 4+) ────────────────────────────────────────────────

class ParticipantTile extends StatelessWidget {
  const ParticipantTile({
    super.key,
    required this.participant,
    required this.isMe,
  });

  final Map<String, dynamic> participant;
  final bool                 isMe;

  @override
  Widget build(BuildContext context) {
    final rank = participant['rank']      as int;
    final name = (participant['userName'] as String?) ?? 'Participant';

    return Container(
      decoration: BoxDecoration(
        color:        isMe ? Colors.blue.shade50 : Colors.grey.shade50,
        border:       Border.all(
          color: isMe ? Colors.blue.shade300 : Colors.grey.shade300,
          width: isMe ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Text(
            '$rank',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color:      Colors.black54,
              fontSize:   13,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (isMe) const YouBadge(),
          ],
        ),
        subtitle: Text(
          'Participated ${AppEmojis.medal}',
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ),
    );
  }
}

// ── Shared "You" badge ────────────────────────────────────────────────────────

class YouBadge extends StatelessWidget {
  const YouBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:        Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'You',
        style: TextStyle(
          color:      Colors.white,
          fontSize:   11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
