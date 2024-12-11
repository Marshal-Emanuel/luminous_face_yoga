import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luminous_face_yoga/services/notification_service.dart';

class NotificationSettings extends StatefulWidget {
  @override
  _NotificationSettingsState createState() => _NotificationSettingsState();

  // Static method to load settings from SharedPreferences
  static Future<void> loadSettings(SharedPreferences prefs) async {
    // This method can be used to set default values or handle them as necessary.
    // You might want to initialize some state variables here if needed.
  }
}

class _NotificationSettingsState extends State<NotificationSettings> {
  late TimeOfDay selectedTime;
  bool dailyReminders = true;
  bool achievementNotifications = true;
  bool tipsNotifications = true;

  @override
  void initState() {
    super.initState();
    selectedTime = TimeOfDay(hour: 9, minute: 0); // Set default time
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTime = TimeOfDay(
        hour: prefs.getInt('notification_hour') ?? 9,
        minute: prefs.getInt('notification_minute') ?? 0,
      );
      dailyReminders = prefs.getBool('daily_reminders') ?? true;
      achievementNotifications =
          prefs.getBool('achievement_notifications') ?? true;
      tipsNotifications = prefs.getBool('tips_notifications') ?? true;
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (await NotificationService.isInitialized()) {
      // Save settings
      await prefs.setInt('notification_hour', selectedTime.hour);
      await prefs.setInt('notification_minute', selectedTime.minute);
      await prefs.setBool('daily_reminders', dailyReminders);
      await prefs.setBool(
          'achievement_notifications', achievementNotifications);
      await prefs.setBool('tips_notifications', tipsNotifications);

      // Cancel existing notifications if reminders are disabled
      if (!dailyReminders) {
        await NotificationService.cancelAllNotifications();
      }

      // Schedule notifications based on new settings
      await NotificationService.scheduleNotifications(prefs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFE99C83),
        elevation: 0,
        title: Text(
          'Notification Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Practice Reminder',
              style: TextStyle(
                color: Color(0xFF18314F),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF6D7CD).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Daily Reminders',
                      style: TextStyle(
                        color: Color(0xFF3C3C3B),
                        fontSize: 16,
                      ),
                    ),
                    value: dailyReminders,
                    activeColor: Color(0xFF66D7D1),
                    onChanged: (bool value) async {
                      setState(() {
                        dailyReminders = value;
                      });
                      await saveSettings();
                    },
                  ),
                  ListTile(
                    title: Text(
                      'Reminder Time',
                      style: TextStyle(
                        color: Color(0xFF3C3C3B),
                        fontSize: 16,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light()
                                  .copyWith(primaryColor: Color(0xFFE99C83)),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                          await saveSettings();
                        }
                      },
                      child: Text(
                        '${selectedTime.format(context)}',
                        style: TextStyle(
                          color: Color(0xFF66D7D1),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Other Notifications',
              style: TextStyle(
                color: Color(0xFF18314F),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF6D7CD).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Achievement Celebrations',
                      style: TextStyle(
                        color: Color(0xFF3C3C3B),
                        fontSize: 16,
                      ),
                    ),
                    value: achievementNotifications,
                    activeColor: Color(0xFF66D7D1),
                    onChanged: (bool value) async {
                      setState(() {
                        achievementNotifications = value;
                      });
                      await saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: Text(
                      'Tips & Motivation',
                      style: TextStyle(
                        color: Color(0xFF3C3C3B),
                        fontSize: 16,
                      ),
                    ),
                    value: tipsNotifications,
                    activeColor: Color(0xFF66D7D1),
                    onChanged: (bool value) async {
                      setState(() {
                        tipsNotifications = value;
                      });
                      await saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
