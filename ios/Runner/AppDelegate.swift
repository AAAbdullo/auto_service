import Flutter
import UIKit
import YandexMapsMobile

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set the API key BEFORE registering plugins so the Flutter plugin
    // can safely call YMKMapKit.sharedInstance() on the main thread.
    // Do NOT call sharedInstance() here — that triggers premature SDK thread
    // initialization before Dart workers are ready, causing EXC_BAD_ACCESS.
    YMKMapKit.setApiKey("21ce4ce6-0677-46c6-9f24-d669e0d8f2ef")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
