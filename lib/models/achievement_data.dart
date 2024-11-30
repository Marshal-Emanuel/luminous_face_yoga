// lib/models/achievement_data.dart

import 'package:flutter/material.dart';

enum AchievementCategory {
  streak,
  quiz,
  practice,
  special,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int requiredCount;
  final AchievementCategory category;
  final int pointsValue;
  final Color primaryColor;
  final Color accentColor;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredCount,
    required this.category,
    required this.pointsValue,
    required this.primaryColor,
    required this.accentColor,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  /// Creates a copy of this Achievement with optional new values.
  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: this.id,
      title: this.title,
      description: this.description,
      icon: this.icon,
      requiredCount: this.requiredCount,
      category: this.category,
      pointsValue: this.pointsValue,
      primaryColor: this.primaryColor,
      accentColor: this.accentColor,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: IconData(json['iconCode'], fontFamily: 'MaterialIcons'),
      requiredCount: json['requiredCount'],
      category: AchievementCategory.values[json['category']],
      pointsValue: json['pointsValue'],
      primaryColor: Color(json['primaryColor']),
      accentColor: Color(json['accentColor']),
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCode': icon.codePoint,
      'requiredCount': requiredCount,
      'category': category.index,
      'pointsValue': pointsValue,
      'primaryColor': primaryColor.value,
      'accentColor': accentColor.value,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
}

final List<Achievement> achievementsList = [
  Achievement(
    id: 'first_login',
    title: 'Welcome!',
    description: 'Started your Face Yoga journey',
    icon: Icons.emoji_emotions,
    requiredCount: 1,
    category: AchievementCategory.special,
    pointsValue: 10,
    primaryColor: Color(0xFFC2EFED),
    accentColor: Color(0xFF66D7D1),
  ),
  Achievement(
    id: 'first_quiz',
    title: 'Self-Aware',
    description: 'Completed Ageing habits quiz',
    icon: Icons.psychology,
    requiredCount: 1,
    category: AchievementCategory.quiz,
    pointsValue: 25,
    primaryColor: Color(0xFFC2EFED),
    accentColor: Color(0xFF66D7D1),
  ),
  Achievement(
    id: 'week_streak',
    title: 'Weekly Warrior',
    description: '7 days consistent practice',
    icon: Icons.calendar_today,
    requiredCount: 7,
    category: AchievementCategory.streak,
    pointsValue: 50,
    primaryColor: Color(0xFFC2EFED),
    accentColor: Color(0xFF66D7D1),
  ),
  Achievement(
    id: 'month_master',
    title: 'Dedication Master',
    description: '30 days of transformation',
    icon: Icons.workspace_premium,
    requiredCount: 30,
    category: AchievementCategory.streak,
    pointsValue: 100,
    primaryColor: Color(0xFFC2EFED),
    accentColor: Color(0xFF66D7D1),
  ),
  // To add more achievments, following same pattern
];
