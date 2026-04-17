import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '_buildDrawer.dart';
import '../main.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}


class _RankingsPageState extends State<RankingsPage> {
  //get the current user
  final User? _currentUser = FirebaseAuth.instance.currentUser;

//testing variables
  final double stepWidth = 60.0;
  final double stepHeight = 40.0;
  final int pointsPerStep =  5;
  final int totalSteps = 9;

// ____ UI __________________________________________
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      //____Appbar_____________________
      appBar: AppBar(
        title: const Text('Rankings'),
      ),
      //the drawer__________________________________
      drawer: const AppDrawer(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data        = snapshot.data?.data() as Map<String, dynamic>?;
          final String firstName   = data?['firstName']   ?? 'User';
          final String lastName    = data?['lastName']    ?? '';
          final int totalPoints = 20;
          final int rank        = data?['rank']        ?? 0;

          // use ~/ for integer division, clamp to valid range
          int currentStep = (totalPoints ~/ pointsPerStep).clamp(0, totalSteps - 1);
          //the position of the avatar
          double avatarX = currentStep * stepWidth + 10;
          double avatarBottomY = currentStep * stepHeight + stepHeight;

          // Stack needs a fixed size so Positioned works
          double stackHeight = totalSteps * stepHeight ;
          double stackWidth  = totalSteps * stepWidth;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome Banner ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimaryColor, Color(0xFF2E5FA3)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      //_____Gettings______________________
                      const Text(
                        'Welcome To Ranking Page',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),


                      //_____name____________________
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          color: kSecondaryColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),



                      const SizedBox(height: 6),


                      //With there ranks___________________________________________
                      Text(
                        'Your Rank is $rank ',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),

                      //___Total of Points____________________________
                      Text(
                        'With the Total Points of $totalPoints ',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                //Game Part____________________
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(

                    gradient: const LinearGradient(
                      colors: [kPrimaryColor, Color.fromARGB(255, 46, 95, 163)],
                    ),

                    borderRadius: BorderRadius.circular(16),
                  ),

                  // horizontal scroll so the staircase doesn't overflow
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,

                    child: SizedBox(
                      width: stackWidth,
                      height: stackHeight,

                      child: Stack(
                        children: [
                          // Draw each staircase step
                          for (int index = 0; index < totalSteps; index++)

                            Positioned(
                              bottom: index * stepHeight,
                              left: index * stepWidth,
                              

                              child: Container(
                                width: stepWidth,
                                height: stepHeight,
                                decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 75, 180, 233),
                                border: Border.all(color: const Color.fromARGB(179, 248, 232, 6), width: 1),
                                ),
                                //center the text of the stairs
                              alignment: Alignment.center,
                              //telling the level of the stairs
                              child: Text(
                                'Lvl ${index + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),

                          //the avatar of the and it position
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 800),
                            bottom: avatarBottomY,
                            left: avatarX,


                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.amber,
                              child: Icon(Icons.person, color: Colors.white),
                              ),


                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
