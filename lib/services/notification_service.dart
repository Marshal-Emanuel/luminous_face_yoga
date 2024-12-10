import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static bool _initialized = false;
  
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

  static Future<bool> requestIOSPermissions() async {
    if (!Platform.isIOS) return true;
    
    try {
      // Request all necessary iOS permissions including critical alerts
      final permissionStatus = await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: 'basic_channel',
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.CriticalAlert,
          NotificationPermission.FullScreenIntent,
        ]
      );
      
      // Store permission status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_permission_granted', permissionStatus);
      
      return permissionStatus;
    } catch (e) {
      print('Error requesting iOS permissions: $e');
      return false;
    }
  }

  static Future<bool> isInitialized() async {
    return _initialized;
  }

  static Future<bool> initializeNotifications() async {
    if (_initialized) return true;
    
    try {
      // For iOS, request permissions first
      if (Platform.isIOS) {
        final isAllowed = await requestIOSPermissions();
        if (!isAllowed) {
          print('iOS notification permissions not granted');
          return false;
        }
      }

      await AwesomeNotifications().cancelAll();
      
      final initialized = await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: Color(0xFF66D7D1),
            ledColor: Color(0xFF465A72),
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
            defaultPrivacy: NotificationPrivacy.Private,
            criticalAlerts: true,
            onlyAlertOnce: false,
          ),
          NotificationChannel(
            channelKey: 'scheduled_channel',
            channelName: 'Scheduled Notifications',
            channelDescription: 'Channel for scheduled reminders and tips',
            defaultColor: Color(0xFF66D7D1),
            ledColor: Color(0xFF465A72),
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
            defaultPrivacy: NotificationPrivacy.Private,
            criticalAlerts: true,
            onlyAlertOnce: false,
          ),
          NotificationChannel(
            channelKey: 'achievements',
            channelName: 'Achievement Notifications',
            channelDescription: 'Channel for achievement notifications',
            defaultColor: Color(0xFF66D7D1),
            ledColor: Color(0xFF465A72),
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
            defaultPrivacy: NotificationPrivacy.Private,
            criticalAlerts: true,
            onlyAlertOnce: false,
          ),
        ],
      );

      if (!initialized) {
        print('Failed to initialize notifications');
        return false;
      }

      _initialized = true;
      return true;
    } catch (e) {
      print('Error initializing notifications: $e');
      return false;
    }
  }

  static Future<void> initializeDefaultSettings(SharedPreferences prefs) async {
    if (!prefs.containsKey('notification_hour')) {
      await prefs.setInt('notification_hour', 9);
    }
    if (!prefs.containsKey('notification_minute')) {
      await prefs.setInt('notification_minute', 0);
    }
    if (!prefs.containsKey('daily_reminders')) {
      await prefs.setBool('daily_reminders', true);
    }
    if (!prefs.containsKey('achievement_notifications')) {
      await prefs.setBool('achievement_notifications', true);
    }
    if (!prefs.containsKey('tips_notifications')) {
      await prefs.setBool('tips_notifications', true);
    }

    if (prefs.getBool('daily_reminders') ?? true) {
      await scheduleDailyReminder(
        hour: prefs.getInt('notification_hour') ?? 9,
        minute: prefs.getInt('notification_minute') ?? 0,
      );
    }
    if (prefs.getBool('tips_notifications') ?? true) {
      await scheduleEveningTip();
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

  static Future<void> sendNotification(String programName, String week, String day) async {
    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
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
        channelKey: 'scheduled_channel',
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
        body: 'Congratulations! Your Face Yoga assessment is ready. Check your inbox for your bespoke report!',
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
        body: 'Discover our membership plans, live classes, and specialized tools',
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

  static Future<void> scheduleNotifications(SharedPreferences prefs) async {
    if (!_initialized) return;

    try {
      if (prefs.getBool('daily_reminders') ?? true) {
        await scheduleDailyReminder(
          hour: prefs.getInt('notification_hour') ?? 9,
          minute: prefs.getInt('notification_minute') ?? 0,
        );
      }

      if (prefs.getBool('tips_notifications') ?? true) {
        await scheduleEveningTip();
      }
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }
}
