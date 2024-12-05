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
    _initializationFuture = _initializeAppWithNotifications();
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
            return Scaffold(
              body: Center(child: Text('Error during initialization')),
            );
          } else {
            return MyApp();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Future<void> _initializeAppWithNotifications() async {
    try {
      print('Starting critical initialization');

      // Critical initializations first
      if (Platform.isIOS) {
        await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp]);
        await InAppWebViewController.setWebContentsDebuggingEnabled(true);
      }

      final prefs = await SharedPreferences.getInstance();

      // Start notification setup in background
      _handleNotifications(prefs);

      // Continue with other initializations
      await Future.wait([
        NotificationSettings.loadSettings(prefs),
        ProgressService.updateStreakOnAppLaunch(),
        ProgressService.scheduleMidnightCheck(),
      ]);
    } catch (error) {
      print('Critical initialization error: $error');
      throw error;
    }
  }

  Future<void> _handleNotifications(SharedPreferences prefs) async {
    try {
      bool notificationsAllowed = await NotificationService.initNotifications();
      if (notificationsAllowed) {
        await NotificationService.cancelAllNotifications();
        await Future.wait([
          NotificationService.scheduleEveningTip(),
          NotificationService.scheduleDailyReminder(
            hour: prefs.getInt('notification_hour') ?? 9,
            minute: prefs.getInt('notification_minute') ?? 0,
          ),
        ]);
      }
    } catch (e) {
      print('Non-critical notification error: $e');
      // Don't throw - let app continue
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
