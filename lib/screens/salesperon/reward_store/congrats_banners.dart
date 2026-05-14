import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';
import 'congrats_tiles.dart';
import 'reward_receipt_pdf.dart';
import 'reward_type_badge.dart';

// ── Hero banner ───────────────────────────────────────────────────────────────

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.currentWin,
    required this.didParticipate,
  });

  final Map<String, dynamic>? currentWin;
  final bool                  didParticipate;

  @override
  Widget build(BuildContext context) {
    final String message;
    if (currentWin != null) {
      message = 'Congratulations — you placed #${currentWin!['rank']}!';
    } else if (didParticipate) {
      message = 'Well done for participating!';
    } else {
      message = 'The event has ended.';
    }

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(AppEmojis.party, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text(
            'Event Over!',
            style: TextStyle(
              color:      Colors.white,
              fontSize:   26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Personal reward card (top 3) ──────────────────────────────────────────────

class PersonalRewardCard extends StatefulWidget {
  const PersonalRewardCard({
    super.key,
    required this.winner,
    required this.userId,
    required this.closedAt,
  });

  final Map<String, dynamic> winner;
  final String               userId;
  final DateTime             closedAt;

  @override
  State<PersonalRewardCard> createState() => _PersonalRewardCardState();
}

class _PersonalRewardCardState extends State<PersonalRewardCard> {
  bool _generating = false;

  Future<void> _downloadReceipt() async {
    setState(() => _generating = true);
    try {
      await RewardReceiptPdf.share(
        userName:     (widget.winner['userName']     as String?) ?? 'Winner',
        rank:          widget.winner['rank']         as int,
        rewardAmount:  ((widget.winner['rewardAmount'] as num?) ?? 0).toDouble(),
        closedAt:      widget.closedAt,
        userId:        widget.userId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Could not generate receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = fmtMoney(widget.winner['rewardAmount']);

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.green.shade50,
        border:       Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Your prize',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:      Colors.green,
                  fontSize:   14,
                ),
              ),
              const Spacer(),
              const MoneyBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Contact your market manager to claim your cash prize.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _generating ? null : _downloadReceipt,
              icon: _generating
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_generating ? 'Generating…' : 'Download Receipt'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Participation badge (rank 4+) ─────────────────────────────────────────────

class ParticipationBadge extends StatelessWidget {
  const ParticipationBadge({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.blue.shade50,
        border:       Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(AppEmojis.medal, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You participated!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:      Colors.blue,
                    fontSize:   14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Great effort, $name. Keep it up for the next event!',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
