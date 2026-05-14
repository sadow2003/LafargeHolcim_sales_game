import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../widgets/_buildDrawer.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'Congrationlation_screen.dart';
import 'event_countdown_banner.dart';
import 'leaderboard_list.dart';
import 'podium_section.dart';

class RankingsPage2 extends StatefulWidget {
  const RankingsPage2({super.key});

  @override
  State<RankingsPage2> createState() => _RankingsPage2State();
}

class _RankingsPage2State extends State<RankingsPage2>
    with SingleTickerProviderStateMixin{
      final User? _currentUser = FirebaseAuth.instance.currentUser;

      late AnimationController _climbController;

      final ScrollController _leaderboardScroll =ScrollController();

      PodiumTheme _selectedTheme= PodiumTheme.stickman;

      bool _eventEnded =false;
      Timer? _endTimer;
      StreamSubscription<DocumentSnapshot>? _eventSub;

      @override
      void initState(){
        super.initState();
        _climbController =AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
          )..repeat();

      _eventSub = FirebaseFirestore.instance
            .collection('settings')
            .doc('salesEvent')
            .snapshots()
            .listen((snap){
              final data = snap.data();
              final endDate = (data?['endDate']as Timestamp?)?.toDate();

              _endTimer?.cancel();
              _endTimer=null;

              if(endDate ==null){
                if(_eventEnded && mounted) setState(()=>_eventEnded =false);
                return;
              }
              final remaning = endDate.difference(DateTime.now());
              if(remaning.isNegative){
                if(!_eventEnded && mounted) setState(()=> _eventEnded =true);
              }else{
                if(_eventEnded && mounted) setState(()=>_eventEnded =false);
                _endTimer =Timer(remaning,(){
                  if (mounted) setState(()=>_eventEnded=true);
                });
              }
            });
      }

      @override 

      void dispose(){
        _endTimer?.cancel();
        _eventSub?.cancel();
        _climbController.dispose();
        _leaderboardScroll.dispose();
        super.dispose();
      }

      void _scrollToCurrentUser(List<QueryDocumentSnapshot> docs){
        final idx =docs.indexWhere((d)=>d.id == _currentUser?.uid);
        if(idx < 0) return;
        WidgetsBinding.instance.addPostFrameCallback((_){
          if(!_leaderboardScroll.hasClients)return;
          final target = idx *72.0;
          final maxExt = _leaderboardScroll.position.maxScrollExtent;
          _leaderboardScroll.animateTo(
            target.clamp(0.0, maxExt),
            duration: const Duration(milliseconds: 700), 
            curve: Curves.easeIn,
            );
        });
      }

      @override
      Widget build(BuildContext context){
        return Scaffold(
          appBar: GradientAppBar(title:'Leaderboard'),

          drawer: const AppDrawer(),

          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('settings')
                .doc('salesEvent')
                .snapshots(),
            builder: (context,eventSnap){
              final eventData = eventSnap.data?.data() as Map<String, dynamic>?;
              final rawRewards =eventData?['rewards'] as Map<String,dynamic>?;
              final List<double?>? rewards = rawRewards == null
                  ? null
                  :[
                    ((rawRewards['1']as Map<String,dynamic>?)?['amount']as num?)?.toDouble(),
                    ((rawRewards['2']as Map<String,dynamic>?)?['amount']as num?)?.toDouble(),
                    ((rawRewards['3']as Map<String,dynamic>?)?['amount']as num?)?.toDouble(),
                  ];
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role',isEqualTo:'salesperson')
                    .orderBy('totalPoints', descending: true)
                    .snapshots(), 
                builder: (context,snapshot){
                  if(snapshot.connectionState == ConnectionState.waiting){
                    return const Center(child: CircularProgressIndicator());
                  }
                  if(snapshot.hasError){
                    return Center(child: Text('Error${snapshot.error}'));

                  }
                   final docs = snapshot.data?.docs ?? [];
                   _scrollToCurrentUser(docs);

                   final top1 = docs.isNotEmpty? docs[0] : null;
                   final top2 = docs.isNotEmpty? docs[1] : null;
                   final top3 = docs.isNotEmpty? docs[2] : null;


                   return LayoutBuilder(builder: (_,constraints){
                    final podiumHeight=
                        (constraints.maxHeight * 0.35).clamp(160.0, 260.0);
                    return Stack(
                      children: [
                        Column(
                          children: [
                            PodiumSection(
                              selectedTheme: _selectedTheme, 
                              onThemeChanged: (t)=>setState(()=>_selectedTheme), 
                              climbController: _climbController, 
                              top1: top1, 
                              top2: top2, 
                              top3: top3, 
                              currentUid: _currentUser?.uid, 
                              podiumHeight: podiumHeight
                              ),

                            const EventCountdownBanner(),

                            Container(
                              color: const Color(0xFF122A52),
                              padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                              child: const Row(
                                children: [
                                  Text('#',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  )),
                                  SizedBox(width:16),
                                  Expanded(
                                child: Text('Player',
                                    style: TextStyle(
                                        color:      Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize:   13)),
                                    ),
                                   Text('Points',
                                      style: TextStyle(
                                          color:      Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize:   13)),

                                ],
                                ),
                            ),

                            Builder(builder:(context){
                              final myIdx = docs.indexWhere((d)=>d.id == _currentUser?.uid);
                              if(myIdx < 0)return const SizedBox.shrink();
                              final myRank =myIdx +1;
                              final myPoints = (docs[myIdx].data() as Map<String,dynamic>)['totalPoints']?? 0;
                              final top1Points =top1 != null
                                  ?((top1.data()as Map<String,dynamic>)['totalPoints']?? 0)
                                  :0;
                              final diff =(top1Points as  num) -(myPoints as num);

                              String message;
                              switch(myRank){
                                case 1:  message = 'Congratulation!!!, You are ranked #1 ';
                                case 2:  message = 'You are ranked #2 ,you are so close only $diff pts left';
                                case 3:  message = 'You are ranked #3, keep going only $diff pts to go';
                                default: message = 'You are ranked #$myRank — only $diff pts for rank 1';
                              }

                              return Container(
                                width: double.infinity,
                                color: const Color(0xFF0D2248),
                                padding:const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
                                child: Text(message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: myRank ==1
                                      ?const Color(0xFFFFD700)
                                      : Colors.white70,
                                  fontSize:  12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                ),
                              );
                            }),

                            Expanded(
                              child: LeaderboardWithButtons(
                                leaderboardScroll: _leaderboardScroll, 
                                docs: docs, 
                                currentUid: _currentUser?.uid,
                                rewards: rewards,
                                ),
                            ),
                          ],
                        ),

                        if(_eventEnded)
                        Builder(builder: (_){
                          final actualWinners =docs
                              .where((d){
                                final pts =((d.data()as Map<String,dynamic>)['totalPoints']as num?)?.toInt() ?? 0;
                                return pts > 0;
                              })
                              .take(3)
                              .toList();
                          if (actualWinners.isEmpty)return const SizedBox.shrink();
                          return Positioned .fill(
                            child: CongratulationOverlay(
                              winners: actualWinners,
                              rewards: rewards,
                              onDismissed: ()=>setState(()=>_eventEnded = false),
                              ),
                            );
                        }),
                      ],
                    );
                   });
                }
                );
            },
            ),
          );
      }
    }