import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/main.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';

String _fmtMoney(dynamic raw) {
  final n = ((raw as num?) ?? 0).toDouble();
  if (n == n.truncateToDouble()) return '${n.toInt()} MAD';
  return '$n MAD';
}

class ActiveEventRewardsView extends StatefulWidget {
  const ActiveEventRewardsView({
    super.key,
    required this.end,
    required this.rawRewards,
  });

  final DateTime             end;
  final Map<String, dynamic> rawRewards;

  @override
  State<ActiveEventRewardsView> createState() => _ActiveEventRewardsViewState();
}

class _ActiveEventRewardsViewState extends State<ActiveEventRewardsView> {
  late Timer _timer;
  Duration   _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) { _updateRemaining(); }
    });
  }

  //update every secound to sumulate a timer
  void _updateRemaining() {
    final diff = widget.end.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String get _countdownText {
    final d = _remaining;
    if (d.inDays > 0) {
      return '${d.inDays}d ${_pad(d.inHours.remainder(24))}h ${_pad(d.inMinutes.remainder(60))}m';
    }
    return '${_pad(d.inHours)}:${_pad(d.inMinutes.remainder(60))}:${_pad(d.inSeconds.remainder(60))}';
  }

  bool get _isUrgent => _remaining.inHours < 24 && _remaining > Duration.zero;


//__________________UI______________________________
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _CountdownBanner(
            text:     _remaining == Duration.zero ? 'Closing…' : _countdownText,
            isUrgent: _isUrgent,
          ),
          const SizedBox(height: 28),
          const Align(
            alignment: Alignment.centerLeft,
            
            //text 'Cash Prizes up for grabs'
            child: Text(
              'Cash Prizes up for grabs',
              style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.bold,
                color:      kPrimaryColor,
              ),
            ),
          ),

          //text 'Finish in the top 3 to win.'
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Finish in the top 3 to win.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),

          //the reward prize of the 1 rank
          const SizedBox(height: 16),
          RewardPrizeCard(rank: 1, emoji: AppEmojis.gold, rawRewards: widget.rawRewards,
              accentColor: const Color(0xFFFFD700)),

          //the reward prize for the secound rank
          const SizedBox(height: 12),
          RewardPrizeCard(rank: 2, emoji: AppEmojis.silver, rawRewards: widget.rawRewards,
              accentColor: const Color(0xFFC0C0C0)),

          //the reward prize for the third rank
          const SizedBox(height: 12),
          RewardPrizeCard(rank: 3, emoji: AppEmojis.bronze, rawRewards: widget.rawRewards,
              accentColor: const Color(0xFFCD7F32)),
        ],
      ),
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  //constructor
  const _CountdownBanner({required this.text, required this.isUrgent});

  final String text;
  final bool   isUrgent;

  //___________________ui_____________________________
  @override
  Widget build(BuildContext context) {
    //thr countainer for the count down 
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        //the container changesd color depending on the time left in the event
        gradient: LinearGradient(
          colors: isUrgent
              ? [Colors.orange.shade700, Colors.red.shade600]
              : [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),

      //the text 'event ends in'
      child: Column(
        children: [
          const Text(
            'Event ends in',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),

          //the count down text
          Text(
            text,
            style: const TextStyle(
              color:         Colors.white,
              fontSize:      32,
              fontWeight:    FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class RewardPrizeCard extends StatelessWidget {
  const RewardPrizeCard({
    super.key,
    required this.rank,
    required this.emoji,
    required this.rawRewards,
    required this.accentColor,
  });

  final int                   rank;
  final String                emoji;
  final Map<String, dynamic>  rawRewards;
  final Color                 accentColor;


//__________________ui________________
  @override
  Widget build(BuildContext context) {
    final r      = (rawRewards['$rank'] as Map<String, dynamic>?) ?? {};
    final amount = _fmtMoney(r['amount']);

    // the container that holds the rewards
    return Container(
      decoration: BoxDecoration(
        color:        accentColor.withValues(alpha: 0.08),
        border:       Border.all(color: accentColor.withValues(alpha: 0.45), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),

      //the list of the reward cards
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Text(emoji, style: const TextStyle(fontSize: 32)),
        title: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize:   20,
          ),
        ),

        //subtitles
        subtitle: const Text(
          'Cash prize',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ),
    );
  }
}
