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
    // Like Android, we would also normally store this key in a .gitignore'd file
    GMSServices.provideAPIKey(ApiKeys.googleMapsKey)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    override init() {
        FirebaseApp.configure()
    }
}
