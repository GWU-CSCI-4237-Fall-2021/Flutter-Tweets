import UIKit
import Flutter
import Firebase
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyD6D1ea9d0hpYai3Cei9jJl35Wc66js8_Q")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    override init() {
        FirebaseApp.configure()
    }
}
