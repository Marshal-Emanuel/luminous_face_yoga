import Flutter
import UIKit
import UserNotifications
import awesome_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
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
        
        // Request notification authorization
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .criticalAlert]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { _, _ in }
            )
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        // Register plugins
        GeneratedPluginRegistrant.register(with: flutterEngine)
        
        // Make window visible
        self.window?.makeKeyAndVisible()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle notifications when app is in foreground
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([[.banner, .badge, .sound]])
        } else {
            completionHandler([[.alert, .badge, .sound]])
        }
    }
    
    // Handle notification response when user taps notification
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            SwiftAwesomeNotificationsPlugin.instance.handleNotificationActionReceived(jsonString: jsonString)
        }
        completionHandler()
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        super.applicationWillResignActive(application)
        window?.resignFirstResponder()
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        window?.makeKeyAndVisible()
        
        // Reset badge count when app becomes active
        application.applicationIconBadgeNumber = 0
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        // Perform any background tasks cleanup here
    }
}
