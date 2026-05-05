import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import 'broadcast_constants.dart';
import 'broadcast_milestones.dart';
import 'broadcast_edit_sheet.dart';


class BroadcastCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String? currentUid;
  final String currentUserRole;
  final bool playConfetti;

//the constructor
  const BroadcastCard({
    super.key,
    required this.docId,
    required this.data,
    required this.currentUid,
    required this.currentUserRole,
    this.playConfetti = false,
  });
//the time ago feature
  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

//delete post function
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

          // cancel and delete buttons
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),

          // delete button with red accent
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    // if user confirmed deletion, delete the document from Firestore
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('broadcasts')
          .doc(docId)
          .delete();
    }
  }

//edit post function
  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditBroadcastSheet(
        docId: docId,
        initialContent: data['content'] as String? ?? '',
        initialType: data['type'] as String? ?? 'general',
      ),
    );
  }

//toggle reaction function
  Future<void> _toggleReaction(String emoji) async {
    if (currentUid == null) return;
    final ref =
        FirebaseFirestore.instance.collection('broadcasts').doc(docId);
    final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
    final users = List<String>.from(reactions[emoji] ?? []);
    if (users.contains(currentUid)) {
      users.remove(currentUid);
    } else {
      users.add(currentUid!);
    }
    reactions[emoji] = users;
    await ref.update({'reactions': reactions});
  }

//build method that constructs the UI
  @override
  Widget build(BuildContext context) {
    
    
    
    // Milestone posts get a special card with confetti
    if (data['isMilestone'] == true) {
      return MilestoneBroadcastCard(
        docId:           docId,
        data:            data,
        currentUid:      currentUid,
        currentUserRole: currentUserRole,
        playConfetti:    playConfetti,
      );
    }

    final type = (data['type'] as String? ?? 'general').toLowerCase();
    
    final typeColor =
        broadcastTypeColors[type] ?? const Color(0xFFB0B0B0);
    
    final typeIcon =
        broadcastTypeIcons[type] ?? Icons.campaign_outlined;
    
    final authorName = data['authorName'] as String? ?? 'Unknown';
    final content = data['content'] as String? ?? '';
    final points = data['pointsAtTime'];
    final rank = data['rankAtTime'];
    final ts = data['createdAt'] as Timestamp?;
    final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
    final isOwn = data['authorId'] == currentUid;
    final canDelete = isOwn ||
        currentUserRole == 'admin' ||
        currentUserRole == 'manager';
        // Generate initials for avatar
    final initials = authorName.isNotEmpty
        ? authorName
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

        // Build the card UI
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isOwn
            ? kPrimaryColor.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwn
              ? kSecondaryColor.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
          width: isOwn ? 1.2 : 1,
        ),
      ),
      
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
           
            // ── Author row ──────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      isOwn ? kSecondaryColor : const Color(0xFF2E5FA3),
                  child: Text(
                    initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),



                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isOwn ? '$authorName (You)' : authorName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    isOwn ? kSecondaryColor : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (data['authorRole'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data['authorRole'] as String,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        _timeAgo(ts),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),



                // ── action menu ──────────────────────────────────────
                if (canDelete)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: Colors.white54, size: 20),
                    color: const Color(0xFF1A3A6B),
                    onSelected: (value) {
                      if (value == 'edit') _showEditSheet(context);
                      if (value == 'delete') _deletePost(context);
                    },
                    itemBuilder: (_) => [
                      if (isOwn)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined,
                                color: Colors.white70, size: 18),
                            SizedBox(width: 10),
                            Text('Edit',
                                style: TextStyle(color: Colors.white)),
                          ]),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 18),
                          SizedBox(width: 10),
                          Text('Delete',
                              style: TextStyle(color: Colors.redAccent)),
                        ]),
                      ),
                    ],
                  ),
                const SizedBox(width: 4),
                
                
                // ── type badge ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: typeColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, color: typeColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        type[0].toUpperCase() + type.substring(1),
                        style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Content ─────────────────────────────────────────────
            Text(
              content,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, height: 1.4),
            ),

            // ── Stats row ───────────────────────────────────────────
            if (points != null || rank != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (rank != null)
                    BroadcastStatChip(
                      icon: Icons.leaderboard_outlined,
                      label: 'Rank #$rank',
                      color: rank == 1
                          ? const Color(0xFFFFD700)
                          : Colors.white54,
                    ),
                  if (rank != null && points != null)
                    const SizedBox(width: 8),
                  if (points != null)
                    BroadcastStatChip(
                      icon: Icons.star_outline,
                      label: '$points pts',
                      color: Colors.white54,
                    ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),

            
            // ── Reactions ────────────────────────────────────────────
            Row(
              children: broadcastReactionEmojis.map((emoji) {
                final users =
                    List<String>.from(reactions[emoji] ?? []);
                
                final reacted = users.contains(currentUid);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _toggleReaction(emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: reacted
                            ? kSecondaryColor.withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: reacted
                              ? kSecondaryColor.withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji,
                              style: const TextStyle(fontSize: 14)),
                          if (users.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${users.length}',
                              style: TextStyle(
                                color: reacted
                                    ? kSecondaryColor
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
    );
  }
}

// ── Stat chip ────────────────────────────────────────────────────────────────

class BroadcastStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const BroadcastStatChip(
      {super.key, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
