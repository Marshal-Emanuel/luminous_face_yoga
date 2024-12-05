import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminous_face_yoga/screens/notification_settings.dart';
import 'package:luminous_face_yoga/screens/progress_screen.dart';
import 'package:luminous_face_yoga/services/notification_service.dart';

import 'package:luminous_face_yoga/webview_screen.dart';
import 'services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(AppInitializer()); // Run app immediately
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Start async initialization after UI renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAsync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WebviewScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => SafeArea(child: WebviewScreen()),
        '/settings': (context) => SafeArea(child: NotificationSettings()),
        '/progress': (context) => SafeArea(child: ProgressScreen()),
      },
    );
  }

  Future<void> _initializeAsync() async {
    try {
      if (Platform.isIOS) {
        await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        await InAppWebViewController.setWebContentsDebuggingEnabled(true);
      }

      final prefs = await SharedPreferences.getInstance();
      final bool firstLaunch = !(prefs.getBool('notification_permission_asked') ?? false);

      if (firstLaunch) {
        final bool allowed = await NotificationService.initNotifications();
        await prefs.setBool('notification_permission_asked', true);

        if (allowed) {
          await NotificationService.cancelAllNotifications();
          await Future.wait([
            NotificationService.scheduleEveningTip(),
            NotificationService.scheduleDailyReminder(
              hour: prefs.getInt('notification_hour') ?? 9,
              minute: prefs.getInt('notification_minute') ?? 0,
            ),
          ]);
        }
      }

      // Load other settings in background
      Future.wait([
        NotificationSettings.loadSettings(prefs),
        ProgressService.updateStreakOnAppLaunch(),
        ProgressService.scheduleMidnightCheck(),
      ]);

    } catch (e) {
      print('Non-critical initialization error: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  // Removed unnecessary 'prefs' parameter since it's not used in build

  // Navigator key (if needed)
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    print('Building MyApp...');
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: SafeArea(child: WebviewScreen()),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
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
