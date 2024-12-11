import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Move delegate setup to very beginning, before plugin registration
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        // Then register plugins
        GeneratedPluginRegistrant.register(with: self)
        
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
        // Always call completionHandler to prevent hanging
        DispatchQueue.main.async {
            if #available(iOS 14.0, *) {
                completionHandler([.banner, .list, .sound, .badge])
            } else {
                completionHandler([.alert, .sound, .badge])
            }
        }
    }
    
    // Handle notification response when app is in background
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle on main thread to prevent UI freezes
        DispatchQueue.main.async {
            let userInfo = response.notification.request.content.userInfo
            NotificationCenter.default.post(
                name: NSNotification.Name("didReceiveNotificationResponse"),
                object: nil,
                userInfo: userInfo
            )
            completionHandler()
        }
    }
}
