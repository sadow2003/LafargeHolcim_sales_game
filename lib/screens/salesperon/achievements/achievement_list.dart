import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'achievement_card.dart';
import 'achievement_progress_header.dart';
import 'milestone_progress_header.dart';

class AchievementList extends StatelessWidget {
  final List<QueryDocumentSnapshot> achievements;
  final Set<String> unlockedIds;
  final int totalCount;
  final int unlockedCount;
  final String uid;


//Constructor
  const AchievementList({
    super.key,
    required this.achievements,
    required this.unlockedIds,
    required this.totalCount,
    required this.unlockedCount,
    required this.uid,
  });


//_______UI ______
  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Nothing here yet',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          ],
        ),
      );
    }


    return CustomScrollView(
      slivers: [
        
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AchievementProgressHeader(
              unlockedCount: unlockedCount,
              totalCount:    totalCount,
            ),
          ),
        ),
        
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: MilestoneProgressHeader(uid: uid),
          ),
        ),
        
        
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final doc      = achievements[i];
                final data     = doc.data() as Map<String, dynamic>;
                final unlocked = unlockedIds.contains(doc.id);

                return AchievementCard(
                  title:        data['title']       ?? 'Achievement',
                  description:  data['description'] ?? '',
                  iconName:     data['iconName']    as String?,
                  pointsReward: (data['pointsReward'] as num?)?.toInt() ?? 0,
                  unlocked:     unlocked,
                );
              },
              childCount: achievements.length,
            ),
          ),
        ),
        
        
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}
