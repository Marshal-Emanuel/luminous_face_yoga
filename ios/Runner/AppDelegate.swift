import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  var window: UIWindow?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    if #available(iOS 13.0, *) {
      window?.overrideUserInterfaceStyle = .light
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
