import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'broadcast_constants.dart';

class AchievementBroadcastCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String? currentUid;
  final String currentUserRole;
  final bool playConfetti;

//Constructor
  const AchievementBroadcastCard({
    super.key,
    required this.docId,
    required this.data,
    required this.currentUid,
    required this.currentUserRole,
    this.playConfetti = false,
  });

  @override
  State<AchievementBroadcastCard> createState() =>
      _AchievementBroadcastCardState();
}



class _AchievementBroadcastCardState extends State<AchievementBroadcastCard> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.playConfetti) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }


// Mapping of icon names to IconData for display
  static const _iconMap = <String, IconData>{
    'trophy':  Icons.emoji_events,
    'star':    Icons.star,
    'medal':   Icons.military_tech,
    'fire':    Icons.local_fire_department,
    'rocket':  Icons.rocket_launch,
    'target':  Icons.gps_fixed,
    'diamond': Icons.diamond,
    'login':   Icons.login,
  };


// Helper function to format timestamps into "time ago" strings
  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }


// Toggles the user's reaction (emoji) on the broadcast post
  Future<void> _toggleReaction(String emoji) async {
    if (widget.currentUid == null) return;
    final ref = FirebaseFirestore.instance
        .collection('broadcasts')
        .doc(widget.docId);
    final reactions =
        Map<String, dynamic>.from(widget.data['reactions'] ?? {});
    final users = List<String>.from(reactions[emoji] ?? []);
    if (users.contains(widget.currentUid)) {
      users.remove(widget.currentUid);
    } else {
      users.add(widget.currentUid!);
    }
    reactions[emoji] = users;
    await ref.update({'reactions': reactions});
  }


// Deletes the broadcast post after confirming with the user 
  Future<void> _deletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
       
        backgroundColor: const Color(0xFF1A3A6B),
        
        title: const Text('Delete Broadcast',
            style: TextStyle(color: Colors.white)),
        
        content: const Text('This broadcast will be permanently removed.',
            style: TextStyle(color: Colors.white70)),
       
        actions: [
          
          // Cancel button to dismiss the dialog without deleting
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),

          // Delete button to confirm deletion of the broadcast
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('broadcasts')
          .doc(widget.docId)
          .delete();
    }
  }


//_________UI___________________________
  @override
  Widget build(BuildContext context) {
    final data              = widget.data;
    final awardedName       = data['awardedUserName']  as String? ?? '';
    final achievementTitle  = data['achievementTitle'] as String? ?? '';
    final iconName          = data['achievementIcon']  as String? ?? 'trophy';
    final icon              = _iconMap[iconName] ?? Icons.military_tech;
    final ts                = data['createdAt'] as Timestamp?;
    final reactions         = Map<String, dynamic>.from(data['reactions'] ?? {});
    final canDelete         = widget.currentUserRole == 'admin' ||
                              widget.currentUserRole == 'manager';

    // Initials for the awarded user
    final initial = awardedName.isNotEmpty ? awardedName[0].toUpperCase() : '🏆';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // ── Card ───────────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1A00), Color(0xFF3D2800), Color(0xFF1B3A6B)],
              stops: [0.0, 0.45, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),


            borderRadius: BorderRadius.circular(16),
            
            
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.55),
              width: 1.5,
            ),


            boxShadow: [
              
              
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          
          
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Header row ──────────────────────────────────────────
                Row(
                  children: [
                    // Trophy badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                        border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                      ),
                      
                      // Icon representing the achievement type 
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    
                    
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // Awarded user's name with styling
                          Text(
                            awardedName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          
                          // Timestamp formatted as "time ago"
                          Text(
                            _timeAgo(ts),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    // Achievement type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          
                          // Icon representing the achievement type
                          Icon(Icons.emoji_events_outlined,
                              color: Color(0xFFFFD700), size: 12),
                          
                          
                          SizedBox(width: 4),
                          
                          // Label for the achievement type
                          Text(
                            'Achievement',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Delete button for amanagers, shown as a popup menu
                    if (canDelete) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Colors.white54, size: 20),
                        color: const Color(0xFF1A3A6B),
                        onSelected: (v) {
                          if (v == 'delete') _deletePost(context);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 18),
                              SizedBox(width: 10),
                              Text('Delete',
                                  style:
                                      TextStyle(color: Colors.redAccent)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),



                const SizedBox(height: 16),



                // ── Achievement badge ───────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  ),
                  
                  child: Column(
                    children: [
                      
                      // Icon representing the achievement type
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                          ),
                        ),
                        
                        
                        child: Icon(icon, color: Colors.white, size: 32),
                      ),
                      
                      
                      const SizedBox(height: 12),
                      
                      // Congratulatory message and achievement title
                      const Text(
                        '🎉 Congratulations! 🎉',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      
                      const SizedBox(height: 6),
                      
                      
                      Text(
                        awardedName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      
                      const SizedBox(height: 4),
                     
                     // Achievement title with special styling
                      const Text(
                        'has earned the achievement',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 13),
                      ),
                     
                     
                      const SizedBox(height: 8),
                      
                      // Achievement title with special styling
                      Text(
                        '"$achievementTitle"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),



                // ── Reactions ───────────────────────────────────────────
                Row(
                  children: broadcastReactionEmojis.map((emoji) {
                   
                   
                    final users =
                        List<String>.from(reactions[emoji] ?? []);
                    
                    
                    final reacted = users.contains(widget.currentUid);
                    
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      
                      // Reaction button with emoji and count, styled based on whether the user has reacted
                      child: GestureDetector(
                        onTap: () => _toggleReaction(emoji),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: reacted
                                ? const Color(0xFFFFD700)
                                    .withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: reacted
                                  ? const Color(0xFFFFD700)
                                      .withValues(alpha: 0.55)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          
                          // Display the emoji and the count of reactions, with special styling if the user has reacted
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji,
                                  style: const TextStyle(fontSize: 14)),
                              if (users.isNotEmpty) ...[
                                
                                const SizedBox(width: 4),
                                
                                // Count of reactions for this emoji, styled based on whether the user has reacted
                                Text(
                                  '${users.length}',
                                  style: TextStyle(
                                    color: reacted
                                        ? const Color(0xFFFFD700)
                                        : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),




        // ── Confetti ────────────────────────────────────────────────────
        ConfettiWidget(
          confettiController: _confetti,
          blastDirection: pi / 2,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          gravity: 0.15,
          emissionFrequency: 0.05,
          colors: const [
            Color(0xFFFFD700),
            Color(0xFF8DC21F),
            Color(0xFF00AEEF),
            Colors.white,
            Colors.orangeAccent,
          ],
          shouldLoop: false,
        ),
      ],
    );
  }
}
