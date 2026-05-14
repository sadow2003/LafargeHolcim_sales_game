import 'package:flutter/material.dart';
import 'package:lafargeholcim_sales_game/main.dart';
import 'package:lafargeholcim_sales_game/utils/app_emojis.dart';
import 'congrats_banners.dart';
import 'congrats_tiles.dart';

class CongratsView extends StatelessWidget {
  const CongratsView({
    super.key,
    required this.winners,
    required this.participants,
    required this.currentUid,
    required this.closedAt,
  });

  final List<dynamic> winners;
  final List<dynamic> participants;
  final String        currentUid;
  final DateTime      closedAt;

  static final _emojis = {1: AppEmojis.gold, 2: AppEmojis.silver, 3: AppEmojis.bronze};
  static const _colors = {
    1: Color(0xFFFFD700),
    2: Color(0xFFC0C0C0),
    3: Color(0xFFCD7F32),
  };

  @override
  Widget build(BuildContext context) {
    final winnerList      = winners.cast<Map<String, dynamic>>();
    final participantList = participants.cast<Map<String, dynamic>>();

    final currentWin = winnerList
        .where((w) => w['userId'] == currentUid)
        .firstOrNull;

    final currentParticipant = participantList
        .where((p) => p['userId'] == currentUid)
        .firstOrNull;

    final didParticipate = currentWin != null || currentParticipant != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          HeroBanner(
            currentWin:     currentWin,
            didParticipate: didParticipate,
          ),

          if (currentWin != null) ...[
            const SizedBox(height: 20),
            PersonalRewardCard(
              winner:   currentWin,
              userId:   currentUid,
              closedAt: closedAt,
            ),
          ],

          if (currentParticipant != null) ...[//
            const SizedBox(height: 20),
            ParticipationBadge(
              name: (currentParticipant['userName'] as String?) ?? '',
            ),
          ],

          const SizedBox(height: 28),

          if (winnerList.isNotEmpty) ...[//
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Top 3 Winners',
                style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.bold,
                  color:      kPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            //
            ...winnerList.map((w) => Padding(//
              padding: const EdgeInsets.only(bottom: 10),
              child: WinnerTile(
                winner:     w,
                isMe:       w['userId'] == currentUid,
                emojis:     _emojis,
                rankColors: _colors,
              ),
            )),
          ],

          //
          if (participantList.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Other Participants',
                style: TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.bold,
                  color:      Colors.black87,
                ),
              ),
            ),

            //
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Great effort from everyone who took part!',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),

            //
            const SizedBox(height: 12),
            ...participantList//
                .where((p) => p['userId'] != currentUid)
                .map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ParticipantTile(participant: p, isMe: false),
                )),
          ],
        ],
      ),
    );
  }
}
