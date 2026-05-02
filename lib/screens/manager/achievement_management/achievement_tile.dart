import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import 'achievement_icons.dart';

class AchievementTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAward;
  final VoidCallback onRevoke;

// Contructor
  const AchievementTile({
    super.key,
    required this.doc,
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onAward,
    required this.onRevoke,
  });

  //____________UI_________________________
  @override
  Widget build(BuildContext context) {
    final icon = iconFor(data['iconName'] as String?);
    final pts  = (data['pointsReward'] as num?)?.toInt() ?? 0;
    
    
    // Main card container for the achievement tile
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        
        child: Row(
          children: [
            
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kSecondaryColor.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: kSecondaryColor, size: 24),
            ),

            const SizedBox(width: 14),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Achievement title
                  Text(
                    data['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),

                  // Optional description and points reward display
                  if ((data['description'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      data['description'],
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],

                  const SizedBox(height: 4),
                  
                  // Points reward display with star icon
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        '+$pts pts',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                
                // Button to award the achievement to a salesperson
                IconButton(
                  icon: const Icon(Icons.card_giftcard, color: kSecondaryColor),
                  tooltip: 'Award to salesperson',
                  onPressed: onAward,
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  tooltip: 'Revoke from salesperson',
                  onPressed: onRevoke,
                ),
                
                // Edit and delete buttons for the achievement
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: kPrimaryColor),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
