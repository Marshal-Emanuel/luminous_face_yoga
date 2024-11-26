import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminous_face_yoga/screens/notification_settings.dart';
import 'package:luminous_face_yoga/screens/progress_screen.dart';
import 'package:luminous_face_yoga/services/notification_service.dart';
import 'package:luminous_face_yoga/loading_screen.dart';
import 'package:luminous_face_yoga/webview_screen.dart';
import 'services/progress_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter binding initialized');
    
    if (Platform.isIOS) {
      print('Running on iOS - configuring webview');
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
    
    // Initialize timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Detroit'));

    // Initialize Shared Preferences with error handling
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      print('Shared Preferences initialized successfully.');
    } catch (e) {
      print('Error initializing Shared Preferences: $e');
      // Handle initialization failure if necessary
      return;
    }

    // Load settings from Shared Preferences
    try {
      print('Loading settings from Shared Preferences...');
      await NotificationSettings.loadSettings(prefs);
    } catch (e) {
      print('Error loading settings: $e');
    }

    // Initialize notifications
    try {
      print('Initializing notifications...');
      await NotificationService.initNotifications();
    } catch (e) {
      print('Error initializing notifications: $e');
    }

    // Additional services
    try {
      print('Updating streak on app launch...');
      await ProgressService.updateStreakOnAppLaunch();

      print('Scheduling evening tip...');
      await NotificationService.scheduleEveningTip();

      print('Scheduling midnight check...');
      await ProgressService.scheduleMidnightCheck();
    } catch (e) {
      print('Error during service initialization: $e');
    }

    print('Starting app...');
    runApp(MyApp(prefs: prefs));
  } catch (e, stackTrace) {
    print('Error in main: $e');
    print('Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Building MyApp...');
    return MaterialApp(
      home: SafeArea(child: LoadingScreen()),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      routes: {
        '/home': (context) => SafeArea(child: WebviewScreen()),
        '/settings': (context) => SafeArea(child: NotificationSettings()),
        '/progress': (context) => SafeArea(child: ProgressScreen()),
      },
    );
  }
}
