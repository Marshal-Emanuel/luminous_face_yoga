import 'dart:ui';

class StreakLevel {
  final String name;
  final int requiredDays;
  final Color primaryColor;
  final Color secondaryColor;
  final String icon;
  final int pointMultiplier;

  const StreakLevel({
    required this.name,
    required this.requiredDays,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.pointMultiplier,
  });
}

final streakLevels = [
  StreakLevel(
    name: 'Bronze',
    requiredDays: 7,
    primaryColor: Color(0xFFC7A982),
    secondaryColor: Color(0xFFE9DDCD),
    icon: '🥉',
    pointMultiplier: 1,
  ),
  StreakLevel(
    name: 'Silver',
    requiredDays: 30,
    primaryColor: Color(0xFF748395),
    secondaryColor: Color(0xFFF6D7CD),
    icon: '🥈',
    pointMultiplier: 2,
  ),
  StreakLevel(
    name: 'Gold',
    requiredDays: 100,
    primaryColor: Color(0xFFE99C83),
    secondaryColor: Color(0xFFC2EFED),
    icon: '🥇',
    pointMultiplier: 3,
  ),
];