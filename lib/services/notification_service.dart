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

  // Define all channel keys as constants
  static const String DAILY_CHANNEL = 'daily_reminder';
  static const String EVENING_CHANNEL = 'evening_tips';
  static const String ACHIEVEMENT_CHANNEL = 'achievements';
  static const String SCHEDULED_CHANNEL = 'scheduled_channel';
  static const String STREAK_CHANNEL = 'streak_channel';

  // Add new constants
  static const String LAST_PERMISSION_REQUEST_KEY = 'last_permission_request';
  static const String PERMISSION_STATUS_KEY = 'notification_permission_granted';
  static const int PERMISSION_COOLDOWN_DAYS = 10;

  // Add method to check existing permission
  static Future<bool> checkExistingPermission() async {
    if (!Platform.isIOS) return true;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PERMISSION_STATUS_KEY) ?? false;
  }

  // Modify existing requestIOSPermissions
  static Future<bool> requestIOSPermissions() async {
    if (!Platform.isIOS) return true;

    // Check if already permitted
    final existingPermission = await checkExistingPermission();
    if (existingPermission) {
      return true;
    }

    // Check cooldown if previously denied
    final prefs = await SharedPreferences.getInstance();
    final lastRequest = prefs.getInt(LAST_PERMISSION_REQUEST_KEY) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (lastRequest > 0 && 
        now - lastRequest < Duration(days: PERMISSION_COOLDOWN_DAYS).inMilliseconds) {
      return false;
    }

    // Request permissions
    final permissionStatus = 
        await AwesomeNotifications().requestPermissionToSendNotifications();
    
    // Store results
    await prefs.setBool(PERMISSION_STATUS_KEY, permissionStatus);
    await prefs.setInt(LAST_PERMISSION_REQUEST_KEY, now);

    return permissionStatus;
  }

  static Future<void> initNotifications() async {
    final initialized = await AwesomeNotifications().initialize(
      null, // Default icon for notifications
      [
        NotificationChannel(
          channelKey: DAILY_CHANNEL,
          channelName: 'Daily Reminders',
          channelDescription: 'Channel for daily reminders',
          defaultColor: Color(0xFF66D7D1),
          ledColor: Color(0xFF465A72),
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
          defaultRingtoneType: DefaultRingtoneType.Notification,
          criticalAlerts: true,
        ),
        NotificationChannel(
          channelKey: EVENING_CHANNEL,
          channelName: 'Evening Tips',
          channelDescription: 'Channel for evening tips',
          defaultColor: Color(0xFF66D7D1),
          ledColor: Color(0xFF465A72),
          importance: NotificationImportance.Default,
          defaultPrivacy: NotificationPrivacy.Private,
          defaultRingtoneType: DefaultRingtoneType.Notification,
          criticalAlerts: true,
        ),
        NotificationChannel(
          channelKey: ACHIEVEMENT_CHANNEL,
          channelName: 'Achievements',
          channelDescription: 'Channel for achievements',
          defaultColor: Color(0xFF66D7D1),
          ledColor: Color(0xFF465A72),
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: SCHEDULED_CHANNEL,
          channelName: 'Scheduled Notifications',
          channelDescription: 'Channel for scheduled notifications',
          defaultColor: Color(0xFF66D7D1),
          ledColor: Color(0xFF465A72),
          importance: NotificationImportance.Default,
        ),
        NotificationChannel(
          channelKey: STREAK_CHANNEL,
          channelName: 'Streak Notifications',
          channelDescription: 'Channel for streak updates',
          defaultColor: Color(0xFF66D7D1),
          ledColor: Color(0xFF465A72),
          importance: NotificationImportance.High,
        ),
      ],
    );

    if (!initialized) {
      throw Exception('Notifications initialization failed');
    }
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await AwesomeNotifications().cancelSchedule(1);
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: DAILY_CHANNEL,
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

  static Future<void> sendNotification(String programName, String week, String day) async {
    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: DAILY_CHANNEL, // Use standard channel instead of 'basic_channel'
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
        channelKey: EVENING_CHANNEL,
        title: 'Face Yoga Tip',
        body: eveningTips[tipIndex],
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 20,
        minute: 0,
        repeats: true,
      ),
    );
  }

  // Update method to use correct channel
  static Future<void> sendQuizCompletionNotification() async {
    await AwesomeNotifications().cancel(3);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 3,
        channelKey: ACHIEVEMENT_CHANNEL, // Updated from 'achievements'
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

  // Update shop reminder to use proper channel
  static Future<void> scheduleShopReminder() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 4,
        channelKey: SCHEDULED_CHANNEL, // Updated from 'scheduled_channel'
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

  // Update streak notification to use proper channel
  static Future<void> sendMissedStreakNotification(int currentStreak) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: STREAK_CHANNEL, // Updated from 'basic_channel'
        title: 'Missed Streak',
        body: 'You missed a day! Your current streak is now $currentStreak days. Log in to keep your streak going!',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
      ),
    );
  }
}
