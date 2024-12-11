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
    // Get screen size
    final size = MediaQuery.of(context).size;
    // Calculate responsive sizes with larger factors
    final cardPadding = size.width * 0.04;  // Increased from 0.03
    final iconSize = size.width * 0.1;      // Increased from 0.08
    final titleSize = size.width * 0.045;   // Increased from 0.04
    final descSize = size.width * 0.04;     // Increased from 0.035
    final backgroundIconSize = iconSize * 1.8; // Increased multiplier from 1.5

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
            blurRadius: 4,  // Increased from 2
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,  // Increased from 4
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(size.width * 0.05), // Increased from 0.04
      ),
      child: Stack(
        children: [
          // Background icon
          Positioned(
            top: -cardPadding/2,
            right: -cardPadding/2,
            child: Icon(
              achievement.icon,
              size: backgroundIconSize,
              color: achievement.primaryColor.withOpacity(0.1),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  achievement.icon,
                  size: iconSize,
                  color: achievement.accentColor,
                ),
                SizedBox(height: cardPadding * 0.75),
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF18314F),
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: cardPadding * 0.5),
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF748395),
                    fontSize: descSize,
                  ),
                ),
              ],
            ),
          ),
          // Lock overlay
          if (!achievement.isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(size.width * 0.05),
                ),
                child: Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: iconSize * 0.8, // Increased from 0.75
                ),
              ),
            ),
        ],
      ),
    );
  }
}