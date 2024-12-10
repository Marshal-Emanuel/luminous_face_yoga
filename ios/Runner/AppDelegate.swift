import UIKit
import Flutter
import awesome_notifications
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register plugins first
        GeneratedPluginRegistrant.register(with: self)
        
        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Check current permission status and request if needed
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Current notification settings: \(settings)")
            
            if settings.authorizationStatus == .notDetermined {
                // Request notification permissions only if not determined yet
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                ) { granted, error in
                    if granted {
                        print("Notification permission granted")
                    } else if let error = error {
                        print("Notification permission error: \(error)")
                    } else {
                        print("Notification permission denied")
                    }
                }
            }
        }
        
        // Initialize the root view controller immediately
        if let flutterViewController = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "app_state",
                binaryMessenger: flutterViewController.binaryMessenger
            )
            channel.setMethodCallHandler { (call, result) in
                if call.method == "getInitialRoute" {
                    result("loading")
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle notifications when app is in foreground
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("Received notification in foreground: \(notification.request.identifier)")
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("Notification tapped: \(response.notification.request.identifier)")
        completionHandler()
    }
}
