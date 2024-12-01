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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications before running app
  await NotificationService.initNotifications();
  
  if (Platform.isIOS) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  runApp(MaterialApp(
    home: LoadingScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

Future<void> initializeApp() async {
      try {
        WidgetsFlutterBinding.ensureInitialized();
    
        if (Platform.isIOS) {
          await InAppWebViewController.setWebContentsDebuggingEnabled(true);
          await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        }

        // Initialize timezones
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('America/Detroit'));

        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Initialize notifications first to ensure proper permission handling
        await NotificationService.initNotifications();

        // Initialize remaining services
        await Future.wait([
          NotificationSettings.loadSettings(prefs),
          ProgressService.updateStreakOnAppLaunch(),
          NotificationService.scheduleEveningTip(),
          ProgressService.scheduleMidnightCheck(),
        ]);

    // Replace loading screen with main app
    runApp(MyApp(prefs: prefs));
  } catch (e, stackTrace) {
    print('Error in initialization: $e');
    print('Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  MyApp({Key? key, required this.prefs}) : super(key: key);

  // Added navigator key
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    print('Building MyApp...');
    return MaterialApp(
      navigatorKey: navigatorKey, // Set the navigator key
      home: SafeArea(child: LoadingScreen()),
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
