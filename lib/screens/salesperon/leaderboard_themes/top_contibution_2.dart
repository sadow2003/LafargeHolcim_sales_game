import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../main.dart';
import 'leaderboard_theme.dart';

// ─── Public podium widget ─────────────────────────────────────────
class TopContributorsPodium extends LeaderboardPodium {
  const TopContributorsPodium({
    super.key,
    required super.top1,
    required super.top2,
    required super.top3,
    required super.phase,
    required super.currentUid,
    required super.podiumHeight,
  });

  @override
  Widget build(BuildContext context){
    return LayoutBuilder(builder:(context,constraints){
      final totalW = constraints.maxWidth;

      final maxD = podiumHeight * 0.44;
      final d1 =(totalW * 0.28).clamp(56.0, maxD);
      final d2 =(totalW * 0.21).clamp(56.0, maxD);
      final d3 =(totalW * 0.19).clamp(56.0, maxD);

      return SizedBox(
        height: podiumHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _BgPainter(phase: phase)),
              ),

              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         _Slot(rank: 2, doc: top2, diameter: d2, phase: phase, currentUid: currentUid),
                        SizedBox(width: totalW * 0.03),
                        _Slot(rank: 1, doc: top1, diameter: d1, phase: phase, currentUid: currentUid),
                        SizedBox(width: totalW * 0.03),
                        _Slot(rank: 3, doc: top3, diameter: d3, phase: phase, currentUid: currentUid),
                    
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
              ))
          ],
        ),
      );
    });
  }
}

class _Slot extends StatelessWidget{
  final int rank;
  final QueryDocumentSnapshot? doc;
  final double diameter;
  final double phase;
  final String? currentUid;

  const _Slot({
    required this.rank,
    required this.doc,
    required this.phase,
    required this.currentUid,
  });

  static Color _medal(int rank) => rank == 1
      ? const Color(0xFFFFD700)
      :rank == 2
        ? const Color(0xFFB0BEC5)
        : const Color(0xFFCD7F32);
  
  static String _initials(String first, String last){
    final f = first.isNotEmpty ? first[0].toUpperCase() :  '';
    final l = last.isNotEmpty  ? last[0].toUpperCase() : '';
    return (f + l).isEmpty ? '?' : f+l;
  }

  @override
  Widget build(BuildContext context){
    final data =doc?.data() as Map<String, dynamic>?;
    final firstName =data?['firstName'] as String? ?? '';
    final lastName = data?['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim().isEmpty
        ? '---'
        : '$firstName $lastName'.trim();
    final points = data?['totalPoints'] ?? 0;
    final photoUrl = data?['photoUrl'] as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final medal =_medal(rank);

    final pulse = (sin(phase * 2 *pi) + 1)/2;

    final ringD = diameter + 8.0;
    final ribbonW = diameter * 0.72;
    final ribbonH    = ribbonW * 0.36;          // matches _RankRibbon aspect ratio
    // stackH includes space for the ribbon peeking below the ring.
    final stackH     = ringD + ribbonH * 0.50;
    final ringOffset = (ringD - diameter) / 2;  

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if(rank == 1)
        _AnimatedCrown(phase: phase, size :diameter *0.40, color : medal)
        else
        SizedBox(height: diameter * 0.40),

        const SizedBox(height: 2),


        SizedBox(
          width: ringD,
          height: stackH,
          child: Stack(
            children: [
              Positioned(
                top: 0,left: 0,right: 0,
                child: SizedBox(
                  height: ringD,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: medal.withValues(alpha: 0.46 + pulse * 0.44),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:        medal.withValues(alpha: 0.20 + pulse * 0.32),
                          blurRadius:   12 + pulse * 8,
                          spreadRadius: 1  + pulse * 2,
                        ),
                      ],
                    ),
                  ),
                ),
                ),
                Positioned(
                  top : ringOffset,
                  left: ringOffset,
                  right: ringOffset,
                  child: SizedBox(
                    height: diameter,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFECEFF1),
                        border:Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                      child: hasPhoto
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              width:  diameter,
                              height: diameter,
                              // fall back to initials silhouette if the URL fails
                              errorBuilder: (_, _, _) => CustomPaint(
                                painter: _AvatarPainter(
                                  initials:   _initials(firstName, lastName),
                                  isMe:       isMe,
                                  medalColor: medal,
                                ),
                              ),
                            )
                          : CustomPaint(
                              painter: _AvatarPainter(
                                initials:   _initials(firstName, lastName),
                                isMe:       isMe,
                                medalColor: medal,
                              ),
                            ),
                    ),
                    ),
                  )
                  ),
                Positioned(
                bottom: 0,
                left:   (ringD - ribbonW) / 2,
                child:  _RankRibbon(rank: rank, color: medal, width: ribbonW),
              ),
            ],
          ),
        )
        const SizedBox(height: 6),
        // Name
        SizedBox(
          width: diameter * 1.15,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:      isMe ? kSecondaryColor : Colors.white,
              fontSize:   diameter * 0.13,
              fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$points pts',
          style: TextStyle(
            color:    Colors.white.withValues(alpha: 0.65),
            fontSize: diameter * 0.105,
          ),
        ),
      ],
    );
  }
}