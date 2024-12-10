import UIKit
import Flutter
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
        print("[AppDelegate] Received notification in foreground: \(notification.request.identifier)")
        
        // Handle different iOS versions
        if #available(iOS 15.0, *) {
            // iOS 15.0 and later: Use all modern options
            completionHandler([.banner, .badge, .sound, .list])
        } else if #available(iOS 14.0, *) {
            // iOS 14.0 to 14.x: Use banner style
            if #available(iOS 14.2, *) {
                // iOS 14.2+: Include list for better notification center visibility
                completionHandler([.banner, .badge, .sound, .list])
            } else {
                // iOS 14.0-14.1: Basic banner style
                completionHandler([.banner, .badge, .sound])
            }
        } else if #available(iOS 13.0, *) {
            // iOS 13.0 to 13.x: Use alert style
            completionHandler([.alert, .badge, .sound])
        } else {
            // iOS 12.x: Use basic alert style
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    // Handle notification response when app is in background
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("[AppDelegate] Notification tapped: \(response.notification.request.identifier)")
        
        let userInfo = response.notification.request.content.userInfo
        
        // Handle the notification tap based on iOS version
        if #available(iOS 15.0, *) {
            // iOS 15+ specific handling
            NotificationCenter.default.post(
                name: NSNotification.Name("didReceiveNotificationResponse"),
                object: nil,
                userInfo: userInfo
            )
        } else if #available(iOS 13.0, *) {
            // iOS 13-14 specific handling
            NotificationCenter.default.post(
                name: NSNotification.Name("didReceiveNotificationResponse"),
                object: nil,
                userInfo: userInfo
            )
        } else {
            // iOS 12 handling
            NotificationCenter.default.post(
                name: NSNotification.Name("didReceiveNotificationResponse"),
                object: nil,
                userInfo: userInfo
            )
        }
        
        completionHandler()
    }
}
