// lib/models/streak_data.dart
import 'package:flutter/material.dart';

class StreakData {
  final String level;
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;
  final int minDays;

  const StreakData({
    required this.level,
    required this.primaryColor,
    required this.accentColor,
    required this.icon,
    required this.minDays,
  });

  static StreakData getCurrentLevel(int streakDays) {
    return streakLevels.lastWhere(
      (level) => streakDays >= level.minDays,
      orElse: () => streakLevels.first,
    );
  }
}

final streakLevels = [
  StreakData(
    level: 'Beginner',
    primaryColor: Color(0xFFF6D7CD),
    accentColor: Color(0xFFE99C83),
    icon: Icons.star_outline,
    minDays: 0,
  ),
  StreakData(
    level: 'Regular',
    primaryColor: Color(0xFFE9DDCD),
    accentColor: Color(0xFFC7A982),
    icon: Icons.star_half,
    minDays: 7,
  ),
  StreakData(
    level: 'Advanced',
    primaryColor: Color(0xFFC2EFED),
    accentColor: Color(0xFF66D7D1),
    icon: Icons.star,
    minDays: 30,
  ),
  StreakData(
    level: 'Master',
    primaryColor: Color(0xFF748395),
    accentColor: Color(0xFF18314F),
    icon: Icons.workspace_premium,
    minDays: 100,
  ),
];