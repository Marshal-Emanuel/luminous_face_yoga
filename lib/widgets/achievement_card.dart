import 'package:flutter/material.dart';
import '../models/achievement_data.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({
    Key? key,
    required this.achievement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            achievement.primaryColor.withOpacity(0.3),
            achievement.accentColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: achievement.accentColor.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Icon(
              achievement.icon,
              size: 60,
              color: achievement.primaryColor.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  achievement.icon,
                  size: 40,
                  color: achievement.accentColor,
                ),
                const SizedBox(height: 12),
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF18314F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF748395),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!achievement.isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}