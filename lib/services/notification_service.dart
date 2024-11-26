import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/res_app_icon',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: Color.fromARGB(200, 221, 181, 80),
          ledColor: Colors.white,
        ),
      ],
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'practice_reminders',
          channelName: 'Practice Reminders',
          channelDescription: 'Daily face yoga practice reminders',
          defaultColor: Color(0xFFE99C83),
          ledColor: Color(0xFF465A72),
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: 'achievements',
          channelName: 'Achievements',
          channelDescription: 'Milestone and progress notifications',
          defaultColor: Color(0xFF66D7D1),
          ledColor: Color(0xFF465A72),
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: 'engagement',
          channelName: 'Tips & Updates',
          channelDescription: 'Motivation and new content notifications',
          defaultColor: Color(0xFF748395),
          ledColor: Color(0xFF465A72),
          importance: NotificationImportance.High,
        ),
      ],
    );

    await AwesomeNotifications()
        .isNotificationAllowed()
        .then((isAllowed) async {
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await AwesomeNotifications().cancelSchedule(1);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'practice_reminders',
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
        channelKey: 'engagement',
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
            'Congratulations! Your personalized Face Yoga assessment is ready. Check your inbox for your bespoke report!',
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
        channelKey: 'engagement',
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
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'missed_streak_channel',
      'Missed Streak',
      channelDescription: 'Channel for missed streak notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Missed Streak',
      'You missed a day! Your current streak is now $currentStreak days. Log in to keep your streak going!',
      platformChannelSpecifics,
      payload: 'missed_streak',
    );
  }
}
