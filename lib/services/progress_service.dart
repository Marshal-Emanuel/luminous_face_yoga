import 'dart:async';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement_data.dart';
import 'notification_service.dart';

class ProgressService {
  // Add cooldown tracking
  static DateTime? _lastUpdate;
  static const _updateCooldown = Duration(minutes: 1);
  static bool _updatedOnLaunch = false;

  // Consolidate streak keys
  static const String CURRENT_STREAK_KEY = 'current_streak';
  static const String LAST_ACTIVE_DATE_KEY = 'last_active_date';
  static const String STREAK_DATES_KEY = 'streak_dates';
  static const String MISSED_DATES_KEY = 'missed_dates';
  static const String HIGHEST_STREAK_KEY = 'highest_streak';
  static const String LAST_NOTIFIED_MISSED_KEY = 'last_notified_missed_date';
  
  // Other keys
  static const String _achievementsKey = 'achievements';

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
      // Check cooldown
      if (_lastUpdate != null && 
          DateTime.now().difference(_lastUpdate!) < _updateCooldown) {
        print('Skipping update - cooldown active');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toLocal();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get current data
      final lastActiveDateString = prefs.getString(LAST_ACTIVE_DATE_KEY);
      int currentStreak = prefs.getInt(CURRENT_STREAK_KEY) ?? 0;
      List<String> streakDates = prefs.getStringList(STREAK_DATES_KEY) ?? [];
      List<String> missedDates = prefs.getStringList(MISSED_DATES_KEY) ?? [];
      
      print('Processing streak update...');
      print('Current streak before update: $currentStreak');

      // First time user
      if (lastActiveDateString == null) {
        await prefs.setInt(CURRENT_STREAK_KEY, 0);
        await prefs.setString(LAST_ACTIVE_DATE_KEY, today.toIso8601String());
        print('First time user - streak initialized to: 0');
        return;
      }

      final lastActive = DateTime.parse(lastActiveDateString).toLocal();
      final lastDate = DateTime(lastActive.year, lastActive.month, lastActive.day);
      final difference = today.difference(lastDate).inDays;

      print('Days since last active: $difference');

      if (difference == 0) {
        print('Same day - maintaining streak: $currentStreak');
        return;
      }

      final todayString = today.toIso8601String();

      if (difference == 1) {
        // Next consecutive day
        if (!streakDates.contains(todayString)) {
          currentStreak += 1;
          streakDates.add(todayString);
          
          // Update highest streak if needed
          final highestStreak = prefs.getInt(HIGHEST_STREAK_KEY) ?? 0;
          if (currentStreak > highestStreak) {
            await prefs.setInt(HIGHEST_STREAK_KEY, currentStreak);
          }
          
          // Check and unlock achievements
          await _checkStreakAchievements(currentStreak);
          
          print('New consecutive day - streak increased to: $currentStreak');
        }
      } else {
        // Missed streak
        final lastNotifiedDate = prefs.getString(LAST_NOTIFIED_MISSED_KEY);
        
        // Only notify if we haven't notified for this missed period
        if (lastNotifiedDate != todayString) {
          await NotificationService.sendMissedStreakNotification(currentStreak);
          await prefs.setString(LAST_NOTIFIED_MISSED_KEY, todayString);
        }

        // Decrement streak by 2 (minimum 0)
        currentStreak = (currentStreak - 2).clamp(0, currentStreak);
        
        // Record missed date
        if (!missedDates.contains(todayString)) {
          missedDates.add(todayString);
          streakDates.remove(todayString); // Ensure date isn't in both lists
        }
        
        print('Missed days detected - streak decreased to: $currentStreak');
      }

      // Update storage
      await prefs.setString(LAST_ACTIVE_DATE_KEY, todayString);
      await prefs.setInt(CURRENT_STREAK_KEY, currentStreak);
      await prefs.setStringList(STREAK_DATES_KEY, streakDates);
      await prefs.setStringList(MISSED_DATES_KEY, missedDates);

      _lastUpdate = DateTime.now();
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
    if (_updatedOnLaunch) {
      print('Already updated on launch, skipping...');
      return;
    }
    await updateStreak();
    _updatedOnLaunch = true;
  }

  /// Retrieves the current streak.
  static Future<int> getCurrentStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(CURRENT_STREAK_KEY) ?? 0;
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
    await prefs.remove(CURRENT_STREAK_KEY);
    await prefs.remove(LAST_ACTIVE_DATE_KEY);
    await prefs.remove(STREAK_DATES_KEY);
    await prefs.remove(MISSED_DATES_KEY);
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
      final streakDates = prefs.getStringList(STREAK_DATES_KEY) ?? [];
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
      final missedDates = prefs.getStringList(MISSED_DATES_KEY) ?? [];
      return missedDates.map((dateStr) => DateTime.parse(dateStr)).toList();
    } catch (e) {
      print('Error in getMissedDates: $e');
      return [];
    }
  }

  static Future<void> scheduleMidnightCheck() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'basic_channel',
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

  /// Checks and unlocks streak achievements
  static Future<void> _checkStreakAchievements(int currentStreak) async {
    if (currentStreak >= 7) {
      await unlockAchievement('week_streak');
    }
    if (currentStreak >= 30) {
      await unlockAchievement('month_master');
    }
  }
}
