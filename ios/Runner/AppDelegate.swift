import UIKit
import Flutter
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // ✅ Correct: use registrar ONLY
    if let registrar = self.registrar(forPlugin: "com.biblebookapp.move_to_back") {
      let channel = FlutterMethodChannel(
        name: "com.biblebookapp/move_to_back",
        binaryMessenger: registrar.messenger()
      )

      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard call.method == "moveTaskToBack" else {
          result(FlutterMethodNotImplemented)
          return
        }

        if UIApplication.shared.responds(to: NSSelectorFromString("suspend")) {
          DispatchQueue.main.async {
            UIApplication.shared.perform(NSSelectorFromString("suspend"))
          }
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // Daily Streak Live Activity (iOS 16.1+) — additive only, no other logic changes
    if let registrar = self.registrar(forPlugin: "com.biblebookapp.live_activity") {
      let liveChannel = FlutterMethodChannel(
        name: "com.biblebookapp/live_activity",
        binaryMessenger: registrar.messenger()
      )
      liveChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "startOrUpdate":
          let args = call.arguments as? [String: Any]
          let streakDays = args?["streakDays"] as? Int ?? 0
          let stepsCompleted = args?["stepsCompleted"] as? Int ?? 0
          StreakLiveActivityManager.startOrUpdate(
            streakDays: streakDays,
            stepsCompleted: stepsCompleted
          )
          result(nil)
        case "end":
          StreakLiveActivityManager.end()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return result
  }
}
