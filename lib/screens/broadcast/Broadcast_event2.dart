import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'broadcast_constants.dart';

class EventBroadcastCard2 extends StatelessWidget{
  final String docId;
  final Map<String, dynamic> data;
  final String? currentUid;
  final String currentUserRole;

  const EventBroadcastCard2({
    super.key,
    required this.docId,
    required this.data,
    required this.currentUid,
    required this.currentUserRole,
  });

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff =DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _toggleReaction(String emoji) async {
    if (currentUid == null) return;
    final ref = FirebaseFirestore.instance.collection('broadcasts').doc(docId);
    final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
    final users = List<String>.from(reactions[emoji] ?? []);
    if(users.contains(currentUid)){
      users.remove(currentUid);
    } else {
      users.add(currentUid!);
    }
    reactions[emoji] = users;
    await ref.update({'reactions':reactions});
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A3A6B),
        title: const Text('Declare Broadcast',style:TextStyle(color:Colors.white)),
        content: const Text('this broadcast will be permanently removed.',
            style: TextStyle(color:Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',style:TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('broadcasts').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authorName =  data['authorName'] as String? ?? 'System';
    final content    =  (data['content'] as String? ?? '').trim();
    final ts         =  data['createdAt'] as Timestamp?;
    final reactions   = Map<String, dynamic>.from(data['reactions'] ?? {});
    final isOwn       = data['authorId'] == currentUid;
    final canDelete   = isOwn ||
        currentUserRole == 'admin' ||
        currentUserRole == 'sales-manager';
    final category   = data['eventCategory']   as String?;
    final productName = data['eventProductName'] as String?;
    final phase      = data['eventPhase']      as String?;

    final lines = content.split('\n');
    final headline = lines.first;
    var   body     = lines.skip(1).join('\n').trim();

    final chipLabel = (productName!= null && productName.isNotEmpty)
        ? 'Product: $productName'
        : (category != null && category.isNotEmpty ? 'Category: $category' : null);
    if (chipLabel != null) {
      body = body.replaceFirst(
        RegExp(r'^(Category|Product):.*?—\s*'),
        '',
      );
    }

    final isEnded = phase != null ? phase == 'ended' :headline.contains('');

    final accent     = isEnded ? const Color(0xFFE53935) : const Color(0xFF29B6F6);
    final darkAccent = isEnded ? const Color(0xFF8E1511) : const Color(0xFF0277BD);
    final bgGradient = LinearGradient(
      colors: isEnded
          ? [const Color(0xFF2B0503), const Color(0xFF521010), const Color(0xFF1B3A6B)]
          : [const Color(0xFF03142B), const Color(0xFF0B2A52), const Color(0xFF1B3A6B)],
      stops: const [0.0, 0.45, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children:[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.18),
                    border: Border.all(color: accent.withValues(alpha:0.5)),
                  ),
                  child: Icon(
                    isEnded ? Icons.flag_outlined : Icons.campaign_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(_timeAgo(ts),
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  ),
                  Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available_outlined, color: accent, size: 12),
                      const SizedBox(width: 4),
                      Text(isEnded ? 'Event Ended' : 'Event',
                          style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                    color: const Color(0xFF1A3A6B),
                    onSelected: (v) {
                      if (v == 'delete') _deletePost(context);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // ── Event banner ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [accent, darkAccent]),
                    ),
                    child: Icon(
                      isEnded ? Icons.emoji_events_outlined : Icons.rocket_launch,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (chipLabel != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            productName != null && productName.isNotEmpty
                                ? Icons.inventory_2_outlined
                                : Icons.category_outlined,
                            color: accent,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            chipLabel,
                            style: TextStyle(
                              color: accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),

            // ── Reactions ────────────────────────────────────────────
            Row(
              children: broadcastReactionEmojis.map((emoji) {
                final users = List<String>.from(reactions[emoji] ?? []);
                final reacted = users.contains(currentUid);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _toggleReaction(emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: reacted
                            ? accent.withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: reacted
                              ? accent.withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 14)),
                          if (users.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text('${users.length}',
                                style: TextStyle(
                                  color: reacted ? accent : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                )),
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
