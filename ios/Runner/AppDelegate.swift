import Flutter
import UIKit
import UserNotifications
import awesome_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set delegate first
        UNUserNotificationCenter.current().delegate = self
        
        // Initialize Awesome Notifications
        AwesomeNotifications().initialize(
            nil,
            channels: nil,
            debug: true
        )
        
        // Register plugins after initialization
        GeneratedPluginRegistrant.register(with: self)
        
        // Request permissions last
        AwesomeNotifications().requestPermissionToSendNotifications()
        
        // Configure UI style
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Notification will present method
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // Notification did receive method
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle the notification response here
        completionHandler()
    }
}
