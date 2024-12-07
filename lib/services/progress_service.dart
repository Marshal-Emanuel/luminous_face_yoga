import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../models/achievement_data.dart';
import 'notification_service.dart';

class ProgressService {
  static const String _achievementsKey = 'achievements';
  static const String _streakKey = 'current_streak';
  static const String _lastActiveDateKey = 'last_active_date';
  static const String _streakDatesKey = 'streak_dates';
  static const String _missedDatesKey = 'missed_dates';

  /// Unlocks an achievement by its [achievementId].
  static Future<void> unlockAchievement(String achievementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(_achievementsKey);
      final achievements = achievementsJson != null
          ? Map<String, dynamic>.from(json.decode(achievementsJson))
          : {};
      achievements[achievementId] = {
        'isUnlocked': true,
        'unlockedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_achievementsKey, json.encode(achievements));
      print('Achievement $achievementId unlocked successfully.');
    } catch (e) {
      print('Error in unlockAchievement: $e');
    }
  }

 static Future<Map<String, String>?> getLastProgressForProgram(String programName) async {
  final prefs = await SharedPreferences.getInstance();
  final progressJson = prefs.getString('user_progress');
  if (progressJson != null) {
    final progressData = Map<String, dynamic>.from(json.decode(progressJson));
    if (progressData.containsKey(programName)) {
      final programProgress = Map<String, dynamic>.from(progressData[programName]);
      final week = programProgress['week']?.toString() ?? '';
      final day = programProgress['day']?.toString() ?? '';
      return {
        'week': week,
        'day': day,
      };
    }
  }
  return null; // No progress found for this program
}

  /// changelog.:  Unlocks the quiz achievement without affecting the streak.
  static Future<void> unlockQuizAchievement() async {
    await unlockAchievement('first_quiz');
  }

  

  /// Updates the current streak based on the last active date.
  static Future<void> updateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActiveDateString = prefs.getString(_lastActiveDateKey);
      final now = DateTime.now().toLocal();

      // Get today's date at start of day
      final today = DateTime(now.year, now.month, now.day);

      int currentStreak = prefs.getInt(_streakKey) ?? 0;
      List<String> streakDates = prefs.getStringList(_streakDatesKey) ?? [];
      List<String> missedDates = prefs.getStringList(_missedDatesKey) ?? [];

      print('Processing streak update...');
      print('Current streak before update: $currentStreak');

      if (lastActiveDateString != null) {
        final lastActive = DateTime.parse(lastActiveDateString).toUtc();
        // Get last active date at start of day
        final lastDate =
            DateTime(lastActive.year, lastActive.month, lastActive.day);

        // Calculate actual calendar day difference
        final difference = today.difference(lastDate).inDays;
        print('Calendar day difference: $difference');

        if (difference == 0) {
          // Same calendar day - no streak update needed
          print(
              'Same calendar day - maintaining current streak: $currentStreak');
          return;
        } else if (difference == 1) {
          // Next calendar day - only increment if not already counted
          if (!streakDates.contains(today.toIso8601String())) {
            currentStreak += 1;
            streakDates.add(today.toIso8601String());
            print('New consecutive day - streak increased to: $currentStreak');
          }
        } else {
          // More than one day missed
          currentStreak = (currentStreak - 2).clamp(0, currentStreak);
          if (!missedDates.contains(today.toIso8601String())) {
            missedDates.add(today.toIso8601String());
          }
          print('Missed days detected - streak decreased to: $currentStreak');
          await NotificationService.sendMissedStreakNotification(currentStreak);
        }
      } else {
        // First time user
        currentStreak = 1;
        streakDates.add(today.toIso8601String());
        print('First time user - streak initialized to: 1');
      }

      // Update storage with new values
      await prefs.setString(_lastActiveDateKey, today.toIso8601String());
      await prefs.setInt(_streakKey, currentStreak);
      await prefs.setStringList(_streakDatesKey, streakDates);
      await prefs.setStringList(_missedDatesKey, missedDates);

      print('Streak update completed. Final streak: $currentStreak');
    } catch (e) {
      print('Error in updateStreak: $e');
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isConsecutiveDay(DateTime date1, DateTime date2) {
    final nextDay = DateTime(date1.year, date1.month, date1.day + 1);
    return isSameDay(date2, nextDay);
  }

  /// Updates streak on app launch
  static Future<void> updateStreakOnAppLaunch() async {
    await updateStreak();
  }

  /// Retrieves the current streak.
  static Future<int> getCurrentStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_streakKey) ?? 0;
    } catch (e) {
      print('Error in getCurrentStreak: $e');
      return 0;
    }
  }

  /// Retrieves the list of unlocked achievements.
  static Future<List<Achievement>> getUnlockedAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(_achievementsKey);
      final achievementsData = achievementsJson != null
          ? Map<String, dynamic>.from(json.decode(achievementsJson))
          : {};

      final unlockedAchievements = achievementsList.where((achievement) {
        return achievementsData.containsKey(achievement.id) &&
            achievementsData[achievement.id]['isUnlocked'] == true;
      }).toList();

      return unlockedAchievements;
    } catch (e) {
      print('Error in getUnlockedAchievements: $e');
      return [];
    }
  }

  /// Optional: Method to reset streak (useful for testing)
  static Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_streakKey);
    await prefs.remove(_lastActiveDateKey);
    await prefs.remove(_streakDatesKey);
    await prefs.remove(_missedDatesKey);
    print('Streak has been reset.');
  }

  /// Retrieves all achievements.
  static Future<List<Achievement>> getAllAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = prefs.getString(_achievementsKey);
    final achievementsData = achievementsJson != null
        ? Map<String, dynamic>.from(json.decode(achievementsJson))
        : {};

    // Map through all achievements to include their unlock status
    final allAchievements = achievementsList.map((achievement) {
      final isUnlocked =
          achievementsData[achievement.id]?['isUnlocked'] ?? false;
      final unlockedAtString = achievementsData[achievement.id]?['unlockedAt'];
      final unlockedAt =
          unlockedAtString != null ? DateTime.parse(unlockedAtString) : null;

      return achievement.copyWith(
        isUnlocked: isUnlocked,
        unlockedAt: unlockedAt,
      );
    }).toList();

    return allAchievements;
  }

  /// Retrieves the dates when the user maintained their streak.
  static Future<List<DateTime>> getStreakDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakDates = prefs.getStringList(_streakDatesKey) ?? [];
      print('Retrieved streak dates: $streakDates');
      return streakDates.map((dateStr) => DateTime.parse(dateStr)).toList();
    } catch (e) {
      print('Error in getStreakDates: $e');
      return [];
    }
  }

  /// Retrieves the dates when the user missed their streak.
  static Future<List<DateTime>> getMissedDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final missedDates = prefs.getStringList(_missedDatesKey) ?? [];
      print('Retrieved missed dates: $missedDates');
      return missedDates.map((dateStr) => DateTime.parse(dateStr)).toList();
    } catch (e) {
      print('Error in getMissedDates: $e');
      return [];
    }
  }

  static Future<void> scheduleMidnightCheck() async {
    // Cancel any existing scheduled notifications with the same ID
    await AwesomeNotifications().cancelSchedule(0);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0, // Unique notification ID
        channelKey: NotificationService.STREAK_CHANNEL, // Use appropriate channel key
        title: 'Welcome Back!',
        body: 'Check your progress and keep glowing.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 0,
        minute: 0,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  static Future<void> saveProgress(String programName, String week, String day) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('user_progress');
    final progressData = progressJson != null
        ? Map<String, dynamic>.from(json.decode(progressJson))
        : {};

    // Update the progress for the specific program
    progressData[programName] = {
      'week': week,
      'day': day,
    };

    // Save the updated progress data
    await prefs.setString('user_progress', json.encode(progressData));
  }
}
