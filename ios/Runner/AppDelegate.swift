import Flutter
import UIKit
import UserNotifications
import awesome_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set notification delegate first
        UNUserNotificationCenter.current().delegate = self
        
        // Create and configure window
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create Flutter engine
        let flutterEngine = FlutterEngine(name: "main")
        flutterEngine.run()
        
        // Create Flutter view controller
        let flutterViewController = FlutterViewController(
            engine: flutterEngine,
            nibName: nil,
            bundle: nil
        )
        
        // Set root view controller
        self.window?.rootViewController = flutterViewController
        
        // Configure UI style
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        
        // Setup notification delegate
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        // Initialize Awesome Notifications
        AwesomeNotifications().initialize(
            nil,
            channels: nil,
            debug: true
        )
        
        // Register plugins after notification initialization
        GeneratedPluginRegistrant.register(with: self)
        
        // Request notification permissions
        AwesomeNotifications().requestPermissionToSendNotifications()
        
        // Make window visible
        self.window?.makeKeyAndVisible()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Add notification handling method
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
    
    // Keep existing lifecycle methods
    override func applicationWillResignActive(_ application: UIApplication) {
        super.applicationWillResignActive(application)
        window?.resignFirstResponder()
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        window?.makeKeyAndVisible()
    }
}
