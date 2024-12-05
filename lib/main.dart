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
  Future<void>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeWithLogs();
  }

  Future<void> _initializeWithLogs() async {
    try {
      print('Starting app initialization...');
      
      if (Platform.isIOS) {
        print('iOS specific initialization...');
        // Critical iOS setup first
        await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        await InAppWebViewController.setWebContentsDebuggingEnabled(true);
        print('iOS orientation and webview debug set');
        
        // Get preferences
        final prefs = await SharedPreferences.getInstance();
        print('SharedPreferences initialized');

        // Check if first time
        final bool firstLaunch = !(prefs.getBool('notification_permission_asked') ?? false);
        print('First launch check: $firstLaunch');

        if (firstLaunch) {
          // Initialize notifications without scheduling
          print('Initializing notifications for iOS...');
          final bool allowed = await NotificationService.initNotifications();
          await prefs.setBool('notification_permission_asked', true);
          print('iOS Permission result: $allowed');

          // Only schedule if allowed
          if (allowed) {
            print('Setting up iOS notifications...');
            await Future.wait([
              NotificationService.scheduleDailyReminder(
                hour: prefs.getInt('notification_hour') ?? 9,
                minute: prefs.getInt('notification_minute') ?? 0,
              ),
              NotificationService.scheduleEveningTip(),
            ]);
            print('iOS notifications scheduled');
          }
        }

        // Continue with non-notification initialization
        print('Loading remaining settings...');
        await Future.wait([
          NotificationSettings.loadSettings(prefs),
          ProgressService.updateStreakOnAppLaunch(),
          ProgressService.scheduleMidnightCheck(),
        ]);
        print('iOS initialization complete');
      } else {
        // Android flow remains unchanged
        // ... your existing Android code ...
      }
    } catch (e, stack) {
      print('iOS Initialization error: $e');
      print('Stack trace: $stack');
      throw e; // Re-throw to show in UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingScreen();
          } else if (snapshot.hasError) {
            print('Error in initialization: ${snapshot.error}');
            return Scaffold(
              body: Center(child: Text('Error during initialization')),
            );
          }
          return WebviewScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => SafeArea(child: WebviewScreen()),
        '/settings': (context) => SafeArea(child: NotificationSettings()),
        '/progress': (context) => SafeArea(child: ProgressScreen()),
      },
    );
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
