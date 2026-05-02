import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';

class AwardSheet extends StatefulWidget {
  final String achievementId;
  final String achievementTitle;

// Constructor for the AwardSheet, requiring the achievement ID and title to display in the sheet
  const AwardSheet({
    super.key,
    required this.achievementId,
    required this.achievementTitle,
  });

  @override
  State<AwardSheet> createState() => _AwardSheetState();
}

// State class for the AwardSheet, managing the search functionality and awarding logic
class _AwardSheetState extends State<AwardSheet> {
  final _db = FirebaseFirestore.instance;
  String _search = '';

  // Method to award the achievement to a selected salesperson
  Future<void> _award(String userId, String userName) async {
    final existing = await _db
        .collection('userAchievements')
        .where('userId', isEqualTo: userId)
        .where('achievementId', isEqualTo: widget.achievementId)
        .get();

    // Check if the user already has the achievement and show a message if so
    if (existing.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName already has this achievement.')),
        );
      }
      return;
    }

    await _db.collection('userAchievements').add({
      'userId':        userId,
      'achievementId': widget.achievementId,
      'unlockedAt':    FieldValue.serverTimestamp(),
      'awardedBy':     'manager',
    });

    // Fetch achievement icon to include in the broadcast
    final achDoc = await _db.collection('achievements').doc(widget.achievementId).get();
    final iconName = (achDoc.data()?['iconName'] as String?) ?? 'trophy';

    // Fetch manager name for the broadcast author
    final managerUid  = FirebaseAuth.instance.currentUser?.uid ?? '';
    final managerDoc  = await _db.collection('users').doc(managerUid).get();
    final managerData = managerDoc.data() ?? {};
    final managerName = '${managerData['firstName'] ?? ''} ${managerData['lastName'] ?? ''}'.trim();

    await _db.collection('broadcasts').add({
      'authorId':         managerUid,
      'authorName':       managerName.isNotEmpty ? managerName : 'Manager',
      'authorRole':       'manager',
      'type':             'achievement',
      'isAchievementAward': true,
      'awardedUserId':    userId,
      'awardedUserName':  userName,
      'achievementTitle': widget.achievementTitle,
      'achievementIcon':  iconName,
      'content': 'Congratulations $userName for getting the "${widget.achievementTitle}" achievement! 🎉',
      'reactions':        {},
      'createdAt':        FieldValue.serverTimestamp(),
    });

    // Show a confirmation message that the achievement has been awarded
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Achievement awarded to $userName!'),
          backgroundColor: kSecondaryColor,
        ),
      );
    }
  }


  //_________ui____________
  @override
  Widget build(BuildContext context) {
    
    // Main container for the award sheet with a fixed height and rounded top corners
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      
      // Column layout for the content of the award sheet
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
                
                Text(
                  'Award: ${widget.achievementTitle}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  'Select a salesperson to receive this achievement',
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
              stream: _db
                  .collection('users')
                  .where('role', isEqualTo: 'salesperson')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snap.data?.docs ?? [];
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name =
                        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                            .toLowerCase();
                    return name.contains(_search);
                  }).toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No salespersons found',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }
                
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data     = docs[i].data() as Map<String, dynamic>;
                    final name     = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                    final email    = data['email']    ?? '';
                    final photoUrl = data['photoUrl'] as String?;
                    final initial  = name.isNotEmpty ? name[0].toUpperCase() : '?';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPrimaryColor.withValues(alpha: 0.15),
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(initial,
                                style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      
                      subtitle: Text(email,
                          style: const TextStyle(fontSize: 12)),
                      
                      trailing: ElevatedButton(
                        onPressed: () => _award(docs[i].id, name),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSecondaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        
                        child: const Text('Award',
                            style: TextStyle(fontSize: 13, color: Colors.white)),
                      ),
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
