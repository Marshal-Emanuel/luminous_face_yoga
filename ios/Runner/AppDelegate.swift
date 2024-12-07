import Flutter
import UIKit
import UserNotifications

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
        
        // Only set delegate, don't request permissions
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            // Don't request permissions here - let Flutter handle it
        }
        
        // Register plugins
        GeneratedPluginRegistrant.register(with: flutterEngine)
        
        // Make window visible
        self.window?.makeKeyAndVisible()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.alert, .badge, .sound])
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        super.applicationWillResignActive(application)
        window?.resignFirstResponder()
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        window?.makeKeyAndVisible()
    }
}
