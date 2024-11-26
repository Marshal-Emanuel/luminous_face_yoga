import 'package:flutter/material.dart';
import '../models/achievement_data.dart';

class AchievementUnlockedDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockedDialog({Key? key, required this.achievement})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           
            Text(
              '🎉',
              style: TextStyle(
                fontSize: 60,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Achievement Unlocked!',
              style: TextStyle(
                color: const Color(0xFF18314F), 
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: TextStyle(
                color: const Color(0xFF18314F), 
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF6F6F6E), 
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66D7D1), 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Awesome!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}