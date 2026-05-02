import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'broadcast_card.dart';

class BroadcastFeed extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String? currentUid;
  final String currentUserRole;
  // Constructor
  const BroadcastFeed({
    super.key,
    required this.stream,
    required this.currentUid,
    required this.currentUserRole,
  });

// ____UI BUILDING___
  @override
  Widget build(BuildContext context) {
    // Listen to the broadcasts collection and build the feed
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_outlined, size: 64, color: Colors.white24),
                SizedBox(height: 14),
                Text(
                  'No broadcasts yet.\nBe the first to share!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 16),
                ),
              ],
            ),
          );
        }
        // Build a list of BroadcastCards from the documents
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return BroadcastCard(
              docId: docs[i].id,
              data: data,
              currentUid: currentUid,
              currentUserRole: currentUserRole,
              playConfetti: i == 0,
            );
          },
        );
      },
    );
  }
}
