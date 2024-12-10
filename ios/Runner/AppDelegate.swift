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
        
        // Check current permission status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification permission status: \(settings.authorizationStatus.rawValue)")
        }
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Notification permission error: \(error)")
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
        // Handle notification tap
        print("Notification tapped: \(response.notification.request.identifier)")
        completionHandler()
    }
}
