import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

//abstract file that serves as a contract for different leaderboard podium UI themes
abstract class LeaderboardPodium extends StatelessWidget {
  final QueryDocumentSnapshot? top1;
  final QueryDocumentSnapshot? top2;
  final QueryDocumentSnapshot? top3;
  final double phase;
  final String? currentUid;

  const LeaderboardPodium({
    super.key,
    required this.top1,
    required this.top2,
    required this.top3,
    required this.phase,
    required this.currentUid,
  });
}
