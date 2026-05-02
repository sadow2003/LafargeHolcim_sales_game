import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';

class RevokeSheet extends StatefulWidget {
  final String achievementId;
  final String achievementTitle;

//Constructor
  const RevokeSheet({
    super.key,
    required this.achievementId,
    required this.achievementTitle,
  });

  @override
  State<RevokeSheet> createState() => _RevokeSheetState();
}

class _RevokeSheetState extends State<RevokeSheet> {
  final _db = FirebaseFirestore.instance;
  String _search = '';

//Deletes the userachivements
  Future<void> _revoke(String userAchievementDocId, String userName) async {
    await _db.collection('userAchievements').doc(userAchievementDocId).delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Achievement revoked from $userName.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }


//___________UI____________________________________
  @override
  Widget build(BuildContext context) {
    return Container(

      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Main content with padding
      child: Column(
        children: [


          const SizedBox(height: 12),
          
          
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),
          
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                
                Row(
                  children: [
                    
                    const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent, size: 20),

                    
                    const SizedBox(width: 8),
                    
                    Expanded(
                      child: Text(
                        'Revoke: ${widget.achievementTitle}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  'Select a salesperson to remove this achievement from',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                
                const SizedBox(height: 12),
                
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search salesperson…',
                    prefixIcon: Icon(Icons.search),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Fetch only userAchievement docs for THIS achievement
              stream: _db
                  .collection('userAchievements')
                  .where('achievementId', isEqualTo: widget.achievementId)
                  .snapshots(),
              builder: (context, uaSnap) {
                if (uaSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final uaDocs = uaSnap.data?.docs ?? [];

                if (uaDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text(
                          'Nobody has this achievement yet.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                // Collect user IDs that hold this achievement
                final userIds =
                    uaDocs.map((d) => d['userId'] as String).toList();
                // Map userId → userAchievement doc ID for deletion
                final userToDocId = {
                  for (final d in uaDocs) d['userId'] as String: d.id
                };

                return StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('users')
                      .where('role', isEqualTo: 'salesperson')
                      .snapshots(),
                  builder: (context, userSnap) {
                    if (userSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Only show users who currently hold the achievement
                    var holders = (userSnap.data?.docs ?? [])
                        .where((d) => userIds.contains(d.id))
                        .toList();
                    
                    // If there's a search query, filter holders by name
                    if (_search.isNotEmpty) {
                      holders = holders.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final name =
                            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                                .toLowerCase();
                        return name.contains(_search);
                      }).toList();
                    }
                    // If no holders match the search, show a message
                    if (holders.isEmpty) {
                      return Center(
                        child: Text(
                          'No matching salespersons.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    // List of users who have the achievement, with a "Revoke" button for each
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: holders.length,
                      itemBuilder: (context, i) {
                        final data =
                            holders[i].data() as Map<String, dynamic>;
                        final name =
                            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                                .trim();
                        final email    = data['email']    ?? '';
                        final photoUrl = data['photoUrl'] as String?;
                        final initial =
                            name.isNotEmpty ? name[0].toUpperCase() : '?';
                        final uaDocId = userToDocId[holders[i].id]!;

                        // Each ListTile shows the user's name, email, and a "Revoke" button
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                kPrimaryColor.withValues(alpha: 0.15),
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? Text(initial,
                                    style: const TextStyle(
                                        color: kPrimaryColor,
                                        fontWeight: FontWeight.bold))
                                : null,
                          ),
                          title: Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(email,
                              style: const TextStyle(fontSize: 12)),
                          trailing: ElevatedButton(
                            onPressed: () => _revoke(uaDocId, name),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Revoke',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.white)),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
