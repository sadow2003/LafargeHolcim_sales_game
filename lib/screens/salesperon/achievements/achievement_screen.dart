import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../widgets/_buildDrawer.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'achievement_list.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}



class _AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  final _db  = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  late TabController _tabController;

  static const _tabs = ['All', 'Unlocked', 'Locked'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

//_______UI ______
  @override
  Widget build(BuildContext context) {
    
    
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Achievements',
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          indicatorColor: kSecondaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorWeight: 3,
        ),
      ),
      
      
      drawer: const AppDrawer(),
      
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('achievements').snapshots(),
        
        
        builder: (context, achSnap) {
          if (achSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (achSnap.hasError) {
            return Center(child: Text('Error: ${achSnap.error}'));
          }
          final allAchievements = achSnap.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('userAchievements')
                .where('userId', isEqualTo: _uid)
                .snapshots(),
           
           
           builder: (context, unlockedSnap) {
              final unlockedIds = (unlockedSnap.data?.docs ?? [])
                  .map((d) => d['achievementId'] as String)
                  .toSet();

              
              return TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  final filtered = switch (tab) {
                    'Unlocked' => allAchievements
                        .where((d) => unlockedIds.contains(d.id))
                        .toList(),
                    'Locked' => allAchievements
                        .where((d) => !unlockedIds.contains(d.id))
                        .toList(),
                    _ => allAchievements,
                  };

                  return AchievementList(
                    achievements:  filtered,
                    unlockedIds:   unlockedIds,
                    totalCount:    allAchievements.length,
                    unlockedCount: unlockedIds.length,
                    uid:           _uid,
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
