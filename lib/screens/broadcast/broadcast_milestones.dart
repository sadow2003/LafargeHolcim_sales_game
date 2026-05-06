import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'broadcast_constants.dart';

/// Mirrors the progression screen: 1, 10, 100, 1000, 10000, …
List<int> _broadcastMilestones(int newTotal) {
  final result = <int>[1, 10];
  var m = 100;
  while (m <= newTotal * 10 + 100000) {
    result.add(m);
    m *= 10;
  }
  return result;
}

/// Returns the milestone value crossed, or null if none was crossed.
int? crossedMilestone(int previousTotal, int newTotal) {
  for (final m in _broadcastMilestones(newTotal)) {
    if (previousTotal < m && newTotal >= m) return m;
  }
  return null;
}

class MilestoneBroadcastCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String? currentUid;
  final String currentUserRole;
  final bool playConfetti;

  const MilestoneBroadcastCard({
    super.key,
    required this.docId,
    required this.data,
    required this.currentUid,
    required this.currentUserRole,
    this.playConfetti = false,
  });

  @override
  State<MilestoneBroadcastCard> createState() => _MilestoneBroadcastCardState();
}

class _MilestoneBroadcastCardState extends State<MilestoneBroadcastCard> {
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

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _toggleReaction(String emoji) async {
    if (widget.currentUid == null) return;
    final ref = FirebaseFirestore.instance.collection('broadcasts').doc(widget.docId);
    final reactions = Map<String, dynamic>.from(widget.data['reactions'] ?? {});
    final users = List<String>.from(reactions[emoji] ?? []);
    if (users.contains(widget.currentUid)) {
      users.remove(widget.currentUid);
    } else {
      users.add(widget.currentUid!);
    }
    reactions[emoji] = users;
    await ref.update({'reactions': reactions});
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A3A6B),
        title: const Text('Delete Broadcast', style: TextStyle(color: Colors.white)),
        content: const Text('This broadcast will be permanently removed.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('broadcasts').doc(widget.docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data         = widget.data;
    final userName     = data['awardedUserName'] as String? ?? '';
    final milestone    = (data['milestoneCount'] as num?)?.toInt() ?? 0;
    final ts           = data['createdAt'] as Timestamp?;
    final reactions    = Map<String, dynamic>.from(data['reactions'] ?? {});
    final canDelete    = widget.currentUserRole == 'admin' || widget.currentUserRole == 'sales-manager';
    final initial      = userName.isNotEmpty ? userName[0].toUpperCase() : '🚀';

    const green      = Color(0xFF8DC21F);
    const darkGreen  = Color(0xFF5A8A00);
    const bgGradient = LinearGradient(
      colors: [Color(0xFF0D2200), Color(0xFF1A3D00), Color(0xFF1B3A6B)],
      stops: [0.0, 0.45, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: green.withValues(alpha: 0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: green.withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: green.withValues(alpha: 0.18),
                        border: Border.all(color: green.withValues(alpha: 0.5)),
                      ),
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
                          Text(userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(_timeAgo(ts),
                              style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    // Milestone type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: green.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_outlined, color: green, size: 12),
                          SizedBox(width: 4),
                          Text('Milestone',
                              style: TextStyle(
                                  color: green,
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

                // ── Milestone badge ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: green.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [green, darkGreen]),
                        ),
                        child: const Icon(Icons.rocket_launch, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '🎉 Milestone Reached! 🎉',
                        style: TextStyle(
                          color: green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('just sold a total of',
                          style: TextStyle(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        '$milestone product${milestone == 1 ? '' : 's'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: green,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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
                    final reacted = users.contains(widget.currentUid);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => _toggleReaction(emoji),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: reacted
                                ? green.withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: reacted
                                  ? green.withValues(alpha: 0.55)
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
                                      color: reacted ? green : Colors.white54,
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
        ),

        // ── Confetti ──────────────────────────────────────────────────────
        ConfettiWidget(
          confettiController: _confetti,
          blastDirection: pi / 2,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          gravity: 0.15,
          emissionFrequency: 0.05,
          colors: const [
            Color(0xFF8DC21F),
            Color(0xFFFFD700),
            Color(0xFF00AEEF),
            Colors.white,
            Colors.lightGreenAccent,
          ],
          shouldLoop: false,
        ),
      ],
    );
  }
}
