import 'dart:async';

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
      // Create a completer to track initialization progress
      final completer = Completer<void>();
      
      if (Platform.isIOS) {
        // Show initialization progress in UI
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Starting iOS initialization...'))
          );
        }

        try {
          await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          await InAppWebViewController.setWebContentsDebuggingEnabled(true);
          
          final prefs = await SharedPreferences.getInstance();
          final bool firstLaunch = !(prefs.getBool('notification_permission_asked') ?? false);

          if (firstLaunch) {
            // Show permission request status
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Requesting notification permissions...'))
              );
            }
            
            final bool allowed = await NotificationService.initNotifications();
            await prefs.setBool('notification_permission_asked', true);

            if (allowed && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Setting up notifications...'))
              );
              
              await NotificationService.scheduleDailyReminder(
                hour: prefs.getInt('notification_hour') ?? 9,
                minute: prefs.getInt('notification_minute') ?? 0,
              );
              await NotificationService.scheduleEveningTip();
            }
          }

          await Future.wait([
            NotificationSettings.loadSettings(prefs),
            ProgressService.updateStreakOnAppLaunch(),
            ProgressService.scheduleMidnightCheck(),
          ]);

          completer.complete();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}'))
            );
          }
          completer.completeError(e);
        }
      }
      
      return completer.future;
    } catch (e) {
      throw e; // Rethrow to be caught by FutureBuilder
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
