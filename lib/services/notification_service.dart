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

  
    static Future<bool> requestIOSPermissions() async {
      if (!Platform.isIOS) return true;
    
      final permissionStatus = await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: 'basic_channel',
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Provisional,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.CriticalAlert,
        ]
      );
    
      // Store permission status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_permission_granted', permissionStatus);
    
      return permissionStatus;
    }

    static Future<void> initNotifications() async {
      // Initialize first
      final initialized = await AwesomeNotifications().initialize(
        Platform.isIOS 
          ? 'resource://Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x'
          : 'resource://mipmap/notification_icon',
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: Color.fromARGB(200, 221, 181, 80),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
            soundSource: Platform.isIOS ? 'resource://raw/res_notification' : 'resource://raw/notification',
            criticalAlerts: true,
          ),
          NotificationChannel(
            channelKey: 'scheduled_channel',
            channelName: 'Scheduled notifications',
            channelDescription: 'Scheduled notifications channel',
            defaultColor: Color(0xFF66D7D1),
            ledColor: Color(0xFF465A72),
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
            criticalAlerts: true,
            onlyAlertOnce: false,
          ),
        ],
      );

      if (!initialized) {
        throw Exception('Failed to initialize notifications');
      }

      // Request permissions for iOS
      if (Platform.isIOS) {
        final permissionGranted = await requestIOSPermissions();
        if (!permissionGranted) {
          print('iOS notification permissions not granted');
        }
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
        displayOnForeground: true,
        displayOnBackground: true,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
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
