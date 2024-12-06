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

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures plugin services are initialized

  runApp(AppInitializer());
}

class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  Future<SharedPreferences>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
  }

  Future<SharedPreferences> _initialize() async {
    try {
      if (Platform.isIOS) {
        try {
          await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        } catch (e) {
          print('Error setting orientation: $e');
        }
        
        try {
          await InAppWebViewController.setWebContentsDebuggingEnabled(true);
        } catch (e) {
          print('Error setting web debug: $e');
        }
      }
      
      try {
        return await SharedPreferences.getInstance();
      } catch (e) {
        print('Error getting SharedPreferences: $e');
        throw e; // Re-throw to trigger error UI
      }
    } catch (e) {
      print('Critical initialization error: $e');
      throw e; // Show error screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<SharedPreferences>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingScreen();
          } else if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Initialization Error',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return NotificationInitializer(prefs: snapshot.data!);
          }
        },
      ),
    );
  }
}

class NotificationInitializer extends StatefulWidget {
  final SharedPreferences prefs;
  
  const NotificationInitializer({Key? key, required this.prefs}) : super(key: key);
  
  @override
  _NotificationInitializerState createState() => _NotificationInitializerState();
}

class _NotificationInitializerState extends State<NotificationInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Request permissions first
      final notificationsAllowed = await NotificationService.requestIOSPermissions();
      await widget.prefs.setBool('notifications_enabled', notificationsAllowed);

      if (notificationsAllowed) {
        // Initialize channels
        await NotificationService.initNotifications();
        
        // Schedule notifications one by one
        await NotificationService.scheduleEveningTip();
        await NotificationService.scheduleDailyReminder(
          hour: widget.prefs.getInt('notification_hour') ?? 9,
          minute: widget.prefs.getInt('notification_minute') ?? 0,
        );

        // Initialize other services sequentially
        await NotificationSettings.loadSettings(widget.prefs);
        await ProgressService.updateStreakOnAppLaunch();
        await ProgressService.scheduleMidnightCheck();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      }
    } catch (e) {
      print('Error during notification initialization: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingScreen(); // Keep loading screen visible during initialization
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
