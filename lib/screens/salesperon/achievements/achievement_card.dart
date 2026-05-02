import 'package:flutter/material.dart';
import '../../../../main.dart';

class AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final String? iconName;
  final int pointsReward;
  final bool unlocked;

//Constructor
  const AchievementCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconName,
    required this.pointsReward,
    required this.unlocked,
  });


//icons
  static IconData iconFor(String? name) => switch (name) {
    'login'   => Icons.login,
    'star'    => Icons.star,
    'trophy'  => Icons.emoji_events,
    'fire'    => Icons.local_fire_department,
    'rocket'  => Icons.rocket_launch,
    'target'  => Icons.gps_fixed,
    'diamond' => Icons.diamond,
    _         => Icons.military_tech,
  };


//_______UI ______
  @override
  Widget build(BuildContext context) {
   
   // Card design inspired by popular achievement displays in games, with a modern twist
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: unlocked ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      
      // If unlocked, show a vibrant border and shadow; if locked, keep it subdued
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: unlocked
              ? Border.all(color: kSecondaryColor.withValues(alpha: 0.6), width: 1.5)
              : null,
        ),
        
        
        child: Padding(
          padding: const EdgeInsets.all(14),
          
          
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? kSecondaryColor.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                ),
                
                child: Icon(
                  iconFor(iconName),
                  size: 30,
                  color: unlocked ? kSecondaryColor : Colors.grey.shade400,
                ),
              ),
              
              
              const SizedBox(width: 14),
              
              
              Expanded(
                
                
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                 
                  children: [
                    Row(
                      children: [
                       
                       
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: unlocked ? kPrimaryColor : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        
                        
                        if (unlocked)
                          const Icon(Icons.check_circle, color: kSecondaryColor, size: 20)
                        else
                          Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 18),
                      ],
                    ),
                    
                    
                    if (description.isNotEmpty) ...[
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        description,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        
                        const SizedBox(width: 4),
                        
                        
                        Text(
                          '+$pointsReward pts',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        
                        if (unlocked)
                         
                         
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kSecondaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kSecondaryColor.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'Earned',
                              style: TextStyle(
                                fontSize: 11,
                                color: kSecondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          
                          
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Locked',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
