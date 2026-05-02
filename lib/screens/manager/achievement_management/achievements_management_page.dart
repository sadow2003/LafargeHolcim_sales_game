import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../widgets/_buildDrawer.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'achievement_form.dart';
import 'achievement_tile.dart';
import 'award_sheet.dart';
import 'revoke_sheet.dart';

class AchievementsManagementPage extends StatelessWidget {
  const AchievementsManagementPage({super.key});

  @override
  
  //________________UI_________________________
  Widget build(BuildContext context) {
    return Scaffold(
      
      // Custom gradient app bar with title
      appBar: GradientAppBar(title: 'Achievements'),
      
      // Navigation drawer for manager options
      drawer: const AppDrawer(),
      
      // Floating action button to add new achievements
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null, null),
        backgroundColor: kSecondaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Achievement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      // Body with real-time list of achievements from Firestore
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('achievements')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          
          // Display a message when there are no achievements
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  // Icon and message indicating no achievements exist
                  Icon(Icons.emoji_events_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No achievements yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          
          
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              
              // Map the achievement's icon name to an actual IconData using the helper function
              return AchievementTile(
                doc:      doc,
                data:     data,
                onEdit:   () => _showForm(context, doc.id, data),
                onDelete: () => _confirmDelete(context, doc.id, data['title'] ?? ''),
                onAward:  () => _showAwardSheet(context, doc.id, data['title'] ?? ''),
                onRevoke: () => _showRevokeSheet(context, doc.id, data['title'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to show the achievement form for creating or editing an achievement
  void _showForm(BuildContext context, String? id, Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AchievementForm(id: id, existing: existing),
    );
  }

  void _showRevokeSheet(BuildContext context, String achievementId, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RevokeSheet(
        achievementId:    achievementId,
        achievementTitle: title,
      ),
    );
  }

// Helper method to show the award sheet for awarding an achievement to a salesperson
  void _showAwardSheet(BuildContext context, String achievementId, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AwardSheet(
        achievementId:    achievementId,
        achievementTitle: title,
      ),
    );
  }


// Confirmation dialog for deleting an achievement with options to cancel or confirm deletion
  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Achievement'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('achievements')
                  .doc(id)
                  .delete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
