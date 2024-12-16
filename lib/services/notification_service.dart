import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:device_info_plus/device_info_plus.dart';
import '../models/achievement_data.dart';

const String _titleStyle = '<font face="Avenir-Medium" size="18">%s</font>';
const String _bodyStyle = '<font face="Avenir-Light" size="16">%s</font>';

class NotificationService {
  static bool _initialized = false;

  // Add channel constants
  static const String STREAK_CHANNEL = 'streak_notifications';
  static const String ACHIEVEMENT_CHANNEL = 'achievement_notifications';
  static const String BASIC_CHANNEL = 'basic_channel';
  static const String SCHEDULED_CHANNEL = 'scheduled_channel';

  static final List<String> eveningTips = [
    "Eat protein at every meal",
    "Try doing your face yoga and skincare routine early evening before you are too tired",
    "Try Castor oil if you have thirsty skin",
    "Do a few cheek lifts daily",
    "Feeling stressed? Do square breathing, breath in for 4, hold for 4, out for 4 and hold for 4",
    "Make sure you study the muscle diagram to help you isolate your facial muscles",
    "Check out our bad habits blog",
    "Affirmation – say it 3 times (and mean it)– I feel fabulous",
    "Take a trip to the Relaxation hub",
    "Use a mirror when practising face yoga to check positioning",
    "Always use clean hands for face yoga!",
    "Have you checked out the latest live class on catch up?",
    "Don't forget to register for your live classes!",
    "Feel puffy in the mornings? Do some lymphatic drainage techniques",
    "Struggling to fit face yoga in? Do a technique while waiting at the traffic lights!",
    "Have you uploaded your progress pictures lately?",
    "Make sure you get 8 hours of sleep at night",
    "Always wear SPF 50, even on the cloudy days!",
    "Never go to sleep in your makeup!",
    "Affirmation – say it 3 times (and mean it)– I radiate joy and happiness",
    "Quick mouth toning practise to do now: Run tongue around inside of lip line firmly, 3 times in each direction",
    "Eat plenty of foods rich in Vit C for the anti-oxidants and to synthesise collagen",
    "Drink plenty of water every day!",
    "Limit processed sugar to avoid glycation (sugar face)",
    "Affirmation – say it 3 times (and mean it)– I am calm and serene",
    "Struggling to fit face yoga in? Do a technique while boiling the kettle!",
    "Quick neck practise to do now: Look up, jut out lower lip, hold for 10 seconds"
  ];

  static Future<bool> requestIOSPermissions() async {
    if (!Platform.isIOS) return true;

    try {
      // Request basic permissions
      final permissionStatus = await AwesomeNotifications()
          .requestPermissionToSendNotifications(
              channelKey: 'basic_channel',
              permissions: [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Badge,
            NotificationPermission.Vibration,
          ]);

      print('iOS permission request result: $permissionStatus');

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
    if (_initialized) {
      print('Notifications already initialized');
      return true;
    }
    
    try {
      print('Starting notification initialization...');
      
      // Initialize channels first
      final initialized = await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: BASIC_CHANNEL,
            channelName: 'Basic Notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: const Color(0xFF66D7D1),
            ledColor: const Color(0xFF465A72),
            importance: NotificationImportance.Max,
            playSound: true,
            enableVibration: true,
            defaultPrivacy: NotificationPrivacy.Public,
          ),
          NotificationChannel(
            channelKey: STREAK_CHANNEL,
            channelName: 'Streak Notifications',
            channelDescription: 'Notifications about your practice streak',
            defaultColor: const Color(0xFF66D7D1),
            ledColor: const Color(0xFF465A72),
            importance: NotificationImportance.Max,
            playSound: true,
            enableVibration: true,
            defaultPrivacy: NotificationPrivacy.Public,
          ),
          NotificationChannel(
            channelKey: ACHIEVEMENT_CHANNEL,
            channelName: 'Achievement Notifications',
            channelDescription: 'Notifications about unlocked achievements',
            defaultColor: const Color(0xFFE99C83),
            ledColor: const Color(0xFF465A72),
            importance: NotificationImportance.Max,
            playSound: true,
            enableVibration: true,
            defaultPrivacy: NotificationPrivacy.Public,
          ),
          NotificationChannel(
            channelKey: SCHEDULED_CHANNEL,
            channelName: 'Scheduled Notifications',
            channelDescription: 'Channel for scheduled reminders and tips',
            defaultColor: const Color(0xFF66D7D1),
            ledColor: const Color(0xFF465A72),
            importance: NotificationImportance.Max,
            playSound: true,
            enableVibration: true,
            defaultPrivacy: NotificationPrivacy.Public,
          ),
        ],
      );

      if (!initialized) {
        print('Failed to initialize notification channels');
        return false;
      }

      // Explicitly request permissions right after channel initialization
      final permissionGranted = await AwesomeNotifications().requestPermissionToSendNotifications();
      
      if (!permissionGranted) {
        print('Notification permissions denied');
        return false;
      }

      _initialized = true;
      print('Notification initialization completed successfully');

      // Send immediate test notification to verify
      await sendTestNotification();

      return true;
    } catch (e) {
      print('Error during notification initialization: $e');
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
    try {
      await AwesomeNotifications().cancel(1);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: SCHEDULED_CHANNEL,
          title: _titleStyle.replaceAll('%s', 'Time for Face Yoga'),
          body: _bodyStyle.replaceAll(
              '%s', 'Ready for your daily facial exercises?'),
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
        ),
        schedule: NotificationCalendar(
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
    } catch (e) {
      print('Error scheduling daily reminder: $e');
    }
  }

  static Future<void> sendNotification(
      String programName, String week, String day) async {
    int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: BASIC_CHANNEL,
        title: _titleStyle.replaceAll('%s', 'Program Progress'),
        body: _bodyStyle.replaceAll(
            '%s', 'For program $programName, you reached $week - $day'),
      ),
    );
  }

  static Future<void> scheduleEveningTip() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 2,
          channelKey: SCHEDULED_CHANNEL,
          title: _titleStyle.replaceAll('%s', 'Face Yoga Tip'),
          body: _bodyStyle.replaceAll('%s', eveningTips[DateTime.now().day % eveningTips.length]),
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
        ),
        schedule: NotificationCalendar(
          hour: 20,
          minute: 0,
          second: 0,
          repeats: true,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
    } catch (e) {
      print('Error scheduling evening tip: $e');
    }
  }

  static Future<void> sendQuizCompletionNotification() async {
    await AwesomeNotifications().cancel(3);
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 3,
        channelKey: ACHIEVEMENT_CHANNEL,
        title: _titleStyle.replaceAll('%s', 'Achievement Unlocked'),
        body: _bodyStyle.replaceAll('%s',
            'Your Face Yoga assessment is ready. Check your inbox for your bespoke report!'),
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
        channelKey: SCHEDULED_CHANNEL,
        title: _titleStyle.replaceAll('%s', 'Enhance Your Face Yoga Journey'),
        body: _bodyStyle.replaceAll('%s',
            'Discover our membership plans, live classes, and specialized tools'),
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

  static Future<void> sendMissedStreakNotification(int previousStreak,
      {int daysMissed = 1}) async {
    try {
      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      String title = _titleStyle.replaceAll('%s', 'Streak Interrupted');
      String body = _bodyStyle.replaceAll('%s',
          'You missed yesterday! Your streak was $previousStreak days. Come back today to rebuild your streak!');

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: STREAK_CHANNEL, // Use streak-specific channel
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        schedule: NotificationCalendar(
          hour: 9,
          minute: 0,
          second: 0,
          millisecond: 0,
          repeats: false,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );

      print('Missed streak notification scheduled: $daysMissed days missed');
    } catch (e) {
      print('Error sending missed streak notification: $e');
    }
  }

  static Future<void> scheduleNotifications(SharedPreferences prefs) async {
    if (!_initialized) {
      print('Cannot schedule notifications - not initialized');
      return;
    }

    try {
      print('Starting to schedule notifications...');
      if (prefs.getBool('daily_reminders') ?? true) {
        final hour = prefs.getInt('notification_hour') ?? 9;
        final minute = prefs.getInt('notification_minute') ?? 0;
        print('Scheduling daily reminder for $hour:$minute');
        await scheduleDailyReminder(
          hour: hour,
          minute: minute,
        );
      } else {
        print('Daily reminders are disabled');
      }

      if (prefs.getBool('tips_notifications') ?? true) {
        print('Scheduling evening tip');
        await scheduleEveningTip();
      } else {
        print('Tips notifications are disabled');
      }
      print('All notifications scheduled successfully');
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  static Future<bool> sendTestNotification() async {
    try {
      print('Sending test notification...');
      final now = DateTime.now();
      final testTime = now.add(Duration(seconds: 5));

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 999,
          channelKey: BASIC_CHANNEL,
          title: _titleStyle.replaceAll('%s', 'Test Notification'),
          body: _bodyStyle.replaceAll(
              '%s', 'If you see this, notifications are working!'),
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
        ),
        schedule: NotificationCalendar(
          year: testTime.year,
          month: testTime.month,
          day: testTime.day,
          hour: testTime.hour,
          minute: testTime.minute,
          second: testTime.second,
          millisecond: 0,
          repeats: false,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
      print('Test notification scheduled for: ${testTime.toString()}');
      return true;
    } catch (e) {
      print('Error sending test notification: $e');
      return false;
    }
  }

  static Future<void> sendWelcomeBackNotification() async {
    try {
      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: BASIC_CHANNEL,
          title: _titleStyle.replaceAll('%s', 'Welcome Back'),
          body: _bodyStyle.replaceAll(
              '%s', 'Ready to work out those face muscles?'),
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
      );
    } catch (e) {
      print('Error sending welcome back notification: $e');
    }
  }

  static Future<void> sendAchievementNotification(String achievementId) async {
    try {
      final achievement = achievementsList.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => throw Exception('Achievement not found: $achievementId'),
      );

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: ACHIEVEMENT_CHANNEL,
          title: _titleStyle.replaceAll('%s', 'Achievement Unlocked!'),
          body: _bodyStyle.replaceAll(
              '%s', '${achievement.title} - ${achievement.description}'),
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          displayOnBackground: true,
          wakeUpScreen: true,
        ),
      );
    } catch (e) {
      print('Error sending achievement notification: $e');
    }
  }

  static Future<void> scheduleMidnightCheck() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: BASIC_CHANNEL,
        title: _titleStyle.replaceAll('%s', 'New Day Begins!'),
        body: _bodyStyle.replaceAll('%s', 'Time to maintain your face yoga streak. Your facial muscles await their daily workout!'),
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
}
