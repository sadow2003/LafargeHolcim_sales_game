import 'package:flutter/material.dart';
import '../../../../main.dart';

class AchievementProgressHeader extends StatelessWidget {
  final int unlockedCount;
  final int totalCount;


//Constructor
  const AchievementProgressHeader({
    super.key,
    required this.unlockedCount,
    required this.totalCount,
  });


//_______UI ______
  @override
  Widget build(BuildContext context) {
    final ratio = totalCount == 0 ? 0.0 : unlockedCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryColor, kCyanColor, kSecondaryColor],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         
         
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
             
             
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Progress',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                 
                 
                  Text(
                    '$unlockedCount / $totalCount Unlocked',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
         
         
          const SizedBox(height: 12),
          
          
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            
            
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 10,
            ),
          ),
          
          
          const SizedBox(height: 6),
          
          
          Text(
            '${(ratio * 100).toStringAsFixed(0)}% complete',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
