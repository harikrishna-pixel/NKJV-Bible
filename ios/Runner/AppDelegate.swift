import UIKit
import Flutter
import flutter_local_notifications
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

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

    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerTask(
      withIdentifier: "com.biblebookapp.prayerWallActivity"
    )
    WorkmanagerPlugin.registerTask(
      withIdentifier: "com.biblebookapp.prayerWallActivityOneOff"
    )

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // If launched from streak Live Activity deep link, queue Faith Journey open.
    if let url = launchOptions?[.url] as? URL {
      Self.queueFaithJourneyIfStreakLiveActivity(url: url)
    }

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerAppChannels(messenger: engineBridge.applicationRegistrar.messenger())
  }

  private func registerAppChannels(messenger: FlutterBinaryMessenger) {
    let moveToBack = FlutterMethodChannel(
      name: "com.biblebookapp/move_to_back",
      binaryMessenger: messenger
    )

    moveToBack.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
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

    let streakLive = FlutterMethodChannel(
      name: "com.biblebookapp/streak_live_activity",
      binaryMessenger: messenger
    )
    streakLive.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        let args = call.arguments as? [String: Any]
        if let value = StreakLiveActivityBridge.handle(call: call.method, args: args) {
          result(value)
        } else if call.method == "sync" || call.method == "end" {
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
    }

    let contentLive = FlutterMethodChannel(
      name: "com.biblebookapp/content_live_activity",
      binaryMessenger: messenger
    )
    contentLive.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        let args = call.arguments as? [String: Any]
        if let value = ContentLiveActivityBridge.handle(call: call.method, args: args) {
          result(value)
        } else if call.method.hasPrefix("sync") || call.method.hasPrefix("end") {
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
    }

    let iapMemory = FlutterMethodChannel(
      name: "com.biblebookapp/iap_memory",
      binaryMessenger: messenger
    )
    iapMemory.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        let key = "last_iap_product_id"
        if call.method == "setLastIapProduct" {
          let productId = (call.arguments as? [String: Any])?["productId"] as? String ?? ""
          guard !productId.isEmpty else {
            result(false)
            return
          }
          let data = Data(productId.utf8)
          let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.biblebookapp.iap_memory",
          ]
          SecItemDelete(query as CFDictionary)
          var add = query
          add[kSecValueData as String] = data
          add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
          let status = SecItemAdd(add as CFDictionary, nil)
          result(status == errSecSuccess)
        } else if call.method == "getLastIapProduct" {
          let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.biblebookapp.iap_memory",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
          ]
          var item: CFTypeRef?
          let status = SecItemCopyMatching(query as CFDictionary, &item)
          guard status == errSecSuccess, let data = item as? Data,
                let productId = String(data: data, encoding: .utf8), !productId.isEmpty else {
            result(nil)
            return
          }
          result(productId)
        } else if call.method == "clearLastIapProduct" {
          // QA: remove last-buy memory so buy can be retested after Store history clear.
          let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.biblebookapp.iap_memory",
          ]
          SecItemDelete(query as CFDictionary)
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    Self.queueFaithJourneyIfStreakLiveActivity(url: url)
    return super.application(app, open: url, options: options)
  }

  /// Live Activity tap uses biblebookapp://streak — queue Faith Journey for Home to open.
  private static func queueFaithJourneyIfStreakLiveActivity(url: URL) {
    guard url.scheme?.lowercased() == "biblebookapp",
          url.host?.lowercased() == "streak" else { return }
    // Flutter SharedPreferences on iOS stores keys with the "flutter." prefix.
    UserDefaults.standard.set(
      "open_faith_journey",
      forKey: "flutter.pending_notification_action"
    )
  }
}
