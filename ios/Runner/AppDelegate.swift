import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var nativeService: TorrentFlowNativeService?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let messenger = engine?.binaryMessenger {
      nativeService = TorrentFlowNativeService(messenger: messenger)
    }

    return result
  }

  override func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    nativeService?.handleBackgroundURLSession(
      identifier: identifier, completionHandler: completionHandler)
  }
}
