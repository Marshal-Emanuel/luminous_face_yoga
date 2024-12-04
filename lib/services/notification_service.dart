import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final List<String> eveningTips = [
    "Take time to massage your facial pressure points tonight",
    "Practice mindful breathing during your face yoga routine",
    "Remember to relax your jaw throughout the day",
    "Keep your facial muscles relaxed while working",
    "Incorporate neck exercises into your routine",
    "Practice good posture to prevent neck strain",
    "Stay hydrated for optimal skin elasticity",
    "Try facial muscle resistance exercises tonight",
    "Focus on symmetrical facial exercises",
    "Practice tongue positioning exercises",
    "Remember to exercise your eye muscles today",
    "Try cheek lifting exercises before bed",
    "Practice forehead smoothing techniques",
    "Work on your smile muscles tonight",
    "Do some gentle face muscle stretches",
    "Practice face yoga breathing techniques",
    "Focus on lymphatic drainage exercises",
    "Try face yoga exercises for better sleep",
    "Work on your facial muscle tone tonight",
    "Practice face yoga for stress relief"
  ];

  static const String _permissionKey = 'notification_permission_status';
  static const String _lastPromptDateKey = 'last_permission_prompt_date';
  
  // Add this method to check permission state
  static Future<bool> shouldRequestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionStatus = prefs.getString(_permissionKey);
    final lastPromptDate = prefs.getString(_lastPromptDateKey);

    // If never asked before
    if (permissionStatus == null) return true;

    // If previously denied, only ask again after 30 days
    if (permissionStatus == 'denied' && lastPromptDate != null) {
      final lastPrompt = DateTime.parse(lastPromptDate);
      final daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;
      return daysSinceLastPrompt >= 30;
    }

    return false;
  }

  static Future<bool> requestIOSPermissions() async {
    if (!Platform.isIOS) return true;
    
    final shouldPrompt = await shouldRequestPermission();
    if (!shouldPrompt) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_permissionKey) == 'granted';
    }

    final permissionStatus = await AwesomeNotifications().requestPermissionToSendNotifications();
    
    // Store permission state and prompt date
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_permissionKey, permissionStatus ? 'granted' : 'denied');
    await prefs.setString(_lastPromptDateKey, DateTime.now().toIso8601String());

    return permissionStatus;
  }

  // Add initialization tracking
  static bool _isInitialized = false;

  // Modify initNotifications to handle both initialization and permissions
  static Future<bool> initNotifications() async {
    // Prevent multiple initialization
    if (_isInitialized) return true;
    
    try {
      final initialized = await AwesomeNotifications().initialize(
        null,
        [
          // Keep existing channel configurations
          NotificationChannel(
            channelKey: 'scheduled_channel',
            channelName: 'Scheduled Notifications',
            channelDescription: 'Channel for scheduled reminders and tips',
            defaultColor: Color(0xFF66D7D1),
            ledColor: Color(0xFF465A72),
            importance: NotificationImportance.High,
            defaultPrivacy: NotificationPrivacy.Private,
            defaultRingtoneType: DefaultRingtoneType.Notification,
            onlyAlertOnce: false,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: Color(0xFF66D7D1),
            ledColor: Color(0xFF465A72),
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
            // Add iOS specific settings
            defaultPrivacy: NotificationPrivacy.Private,
            defaultRingtoneType: DefaultRingtoneType.Notification,
          ),
          NotificationChannel(
            channelKey: 'achievements',
            channelName: 'Achievement Notifications',
            channelDescription: 'Channel for achievement notifications',
            defaultColor: Color(0xFF66D7D1),
            ledColor: Color(0xFF465A72),
            importance: NotificationImportance.Default,
            playSound: true,
            enableVibration: true,
            // Add iOS specific settings
            defaultPrivacy: NotificationPrivacy.Private,
            defaultRingtoneType: DefaultRingtoneType.Notification,
          ),
          // Add any other channels you are using
        ],
      );

      if (!initialized) {
        throw Exception('Notifications initialization failed');
      }

      // Handle permissions in the same method
      if (Platform.isIOS) {
        final permissionStatus = await _handleIOSPermissions();
        _isInitialized = permissionStatus;
        return permissionStatus;
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Notification initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Make this private since it's now handled internally
  static Future<bool> _handleIOSPermissions() async {
    final shouldPrompt = await shouldRequestPermission();
    if (!shouldPrompt) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_permissionKey) == 'granted';
    }

    final permissionStatus = await AwesomeNotifications()
        .requestPermissionToSendNotifications();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_permissionKey, 
        permissionStatus ? 'granted' : 'denied');
    await prefs.setString(_lastPromptDateKey, 
        DateTime.now().toIso8601String());

    return permissionStatus;
  }

  static Future<void> scheduleDailyReminder({
  required int hour,
  required int minute,
}) async {
  await AwesomeNotifications().cancelSchedule(1);
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 1,
      channelKey: 'scheduled_channel',
      title: 'Time for Face Yoga!',
      body: 'Ready for your daily facial exercises?',
      notificationLayout: NotificationLayout.Default,
    ),
    schedule: NotificationCalendar(
      hour: hour,
      minute: minute,
      second: 0,
      millisecond: 0,
      repeats: true,
      allowWhileIdle: true,
    ),
  );
}

static Future<void> sendNotification(
    String programName, String week, String day) async {
  int notificationId =
      DateTime.now().millisecondsSinceEpoch.remainder(100000);

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: notificationId,
      channelKey: 'basic_channel',
      title: 'Program Progress',
      body: 'For program $programName, you reached $week - $day',
    ),
  );
}

static Future<void> scheduleEveningTip() async {
  final tipIndex = DateTime.now().day % eveningTips.length;
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 2,
      channelKey: 'scheduled_channel',  // Changed from 'engagement'
      title: 'Face Yoga Tip',
      body: eveningTips[tipIndex],
      notificationLayout: NotificationLayout.Default,
    ),
    schedule: NotificationCalendar(
      hour: 20,
      minute: 0,
      repeats: false,
    ),
  );
}

static Future<void> sendQuizCompletionNotification() async {
  await AwesomeNotifications().cancel(3);

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 3,
      channelKey: 'achievements',
      title: '🎉 Achievement Unlocked!',
      body:
          'Congratulations! Your  Face Yoga assessment is ready. Check your inbox for your bespoke report!',
      notificationLayout: NotificationLayout.Default,
      displayOnForeground: true,
      displayOnBackground: true,
      wakeUpScreen: true,
    ),
  );
}

static Future<void> scheduleShopReminder() async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 4,
      channelKey: 'scheduled_channel',
      title: 'Enhance Your Face Yoga Journey',
      body:
          'Discover our membership plans, live classes, and specialized tools',
      notificationLayout: NotificationLayout.Default,
      payload: {'url': 'https://www.luminousfaceyoga.com/shop/'},
    ),
    schedule: NotificationCalendar(
      weekday: DateTime.now().weekday,
      hour: 14,
      minute: 0,
      repeats: true,
    ),
  );
}

static Future<void> cancelAllNotifications() async {
  await AwesomeNotifications().cancelAll();
}

static Future<void> sendMissedStreakNotification(int currentStreak) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'basic_channel',
      title: 'Missed Streak',
      body: 'You missed a day! Your current streak is now $currentStreak days. Log in to keep your streak going!',
      notificationLayout: NotificationLayout.Default,
      category: NotificationCategory.Reminder,
    ),
  );
}
}
