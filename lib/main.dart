import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminous_face_yoga/screens/notification_settings.dart';
import 'package:luminous_face_yoga/screens/progress_screen.dart';
import 'package:luminous_face_yoga/services/notification_service.dart';
import 'package:luminous_face_yoga/loading_screen.dart';
import 'package:luminous_face_yoga/webview_screen.dart';
import 'services/progress_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures plugin services are initialized

  runApp(AppInitializer());
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

    // Start initialization process
    _initializationFuture = initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading screen immediately
          return MaterialApp(
            home: LoadingScreen(),
            debugShowCheckedModeBanner: false,
          );
        } else if (snapshot.hasError) {
          // Handle errors during initialization
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error during initialization')),
            ),
            debugShowCheckedModeBanner: false,
          );
        } else {
          // Initialization complete, show the main app
          return MyApp();
        }
      },
    );
  }
}

Future<void> initializeApp() async {
  try {
    if (Platform.isIOS) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    // Initialize notifications
    await NotificationService.initNotifications();

    // Rest of initialization
    tz.initializeTimeZones();

    // Load settings and schedule notifications
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await Future.wait([
      NotificationSettings.loadSettings(prefs),
      ProgressService.updateStreakOnAppLaunch(),
      NotificationService.scheduleEveningTip(),
      ProgressService.scheduleMidnightCheck(),
    ]);

  } catch (e, stackTrace) {
    print('Error in initialization: $e');
    print('Stack trace: $stackTrace');
    // Rethrow the error to be caught by FutureBuilder
    throw e;
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
