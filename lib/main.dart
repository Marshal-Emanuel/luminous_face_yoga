import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminous_face_yoga/screens/notification_settings.dart';
import 'package:luminous_face_yoga/screens/progress_screen.dart';
import 'package:luminous_face_yoga/services/notification_service.dart';
import 'package:luminous_face_yoga/loading_screen.dart';
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
    // Show WebviewScreen immediately
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
      // iOS specific setup
      if (Platform.isIOS) {
        await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        await InAppWebViewController.setWebContentsDebuggingEnabled(true);
      }

      final prefs = await SharedPreferences.getInstance();
      
      // Check if permission was previously asked
      final bool permissionAsked = prefs.getBool('notification_permission_asked') ?? false;
      
      if (!permissionAsked) {
        // First time: Ask for permission
        final bool allowed = await NotificationService.initNotifications();
        await prefs.setBool('notification_permission_asked', true);
        
        if (allowed) {
          // Only schedule if permission granted
          await NotificationService.scheduleDailyReminder(
            hour: prefs.getInt('notification_hour') ?? 9,
            minute: prefs.getInt('notification_minute') ?? 0,
          );
          await NotificationService.scheduleEveningTip();
        }
      }

      // Load other settings
      await NotificationSettings.loadSettings(prefs);
      await ProgressService.updateStreakOnAppLaunch();
      await ProgressService.scheduleMidnightCheck();

    } catch (e) {
      print('Initialization error: $e');
      // Error won't show on screen since UI is already rendered
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
