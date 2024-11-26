import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Create and configure window
        self.window = UIWindow(frame: UIScreen.bounds)
        
        // Create Flutter view controller
        let flutterViewController = FlutterViewController(engine: FlutterEngine(name: "main"))
        
        // Set root view controller
        self.window?.rootViewController = flutterViewController
        
        // Configure UI style
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        
        // Register plugins
        GeneratedPluginRegistrant.register(with: self)
        
        // Make window visible
        self.window?.makeKeyAndVisible()
        
        // Call super after window setup
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle app entering background
    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        // Preserve window state
        self.window?.layer.speed = 0.0
    }
    
    // Handle app becoming active
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        // Restore window state
        self.window?.layer.speed = 1.0
        self.window?.makeKeyAndVisible()
    }
}
