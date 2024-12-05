import Flutter
import UIKit
import UserNotifications
import awesome_notifications_ios // Changed import

@main
@objc class AppDelegate: FlutterAppDelegate { // Removed redundant UNUserNotificationCenterDelegate
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set notification delegate first
        UNUserNotificationCenter.current().delegate = self
        
        // Register plugins first
        GeneratedPluginRegistrant.register(with: self)
        
        // Configure UI style
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Added override keyword
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // Added override keyword
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
