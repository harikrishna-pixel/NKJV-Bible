import UIKit
import Flutter
import flutter_local_notifications
import workmanager

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

    // Additive: Prayer Wall background GET poll (Workmanager / BGTaskScheduler).
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerTask(
      withIdentifier: "com.biblebookapp.prayerWallActivity"
    )
    WorkmanagerPlugin.registerTask(
      withIdentifier: "com.biblebookapp.prayerWallActivityOneOff"
    )

    GeneratedPluginRegistrant.register(with: self)

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // If launched from streak Live Activity deep link, queue Faith Journey open.
    if let url = launchOptions?[.url] as? URL {
      Self.queueFaithJourneyIfStreakLiveActivity(url: url)
    }

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

    // Streak Live Activity bridge (UI mirror only; no streak logic).
    let streakLiveMessenger: FlutterBinaryMessenger? = {
      if let controller = self.window?.rootViewController as? FlutterViewController {
        return controller.binaryMessenger
      }
      return self.registrar(forPlugin: "com.biblebookapp.streak_live_activity")?.messenger()
    }()
    if let messenger = streakLiveMessenger {
      let channel = FlutterMethodChannel(
        name: "com.biblebookapp/streak_live_activity",
        binaryMessenger: messenger
      )
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        let args = call.arguments as? [String: Any]
        if let value = StreakLiveActivityBridge.handle(call: call.method, args: args) {
          result(value)
        } else if call.method == "sync" || call.method == "end" {
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // Memory Verse + Continue Reading Live Activities (UI mirrors only).
    let contentLiveMessenger: FlutterBinaryMessenger? = {
      if let controller = self.window?.rootViewController as? FlutterViewController {
        return controller.binaryMessenger
      }
      return self.registrar(forPlugin: "com.biblebookapp.content_live_activity")?.messenger()
    }()
    if let messenger = contentLiveMessenger {
      let channel = FlutterMethodChannel(
        name: "com.biblebookapp/content_live_activity",
        binaryMessenger: messenger
      )
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        let args = call.arguments as? [String: Any]
        if let value = ContentLiveActivityBridge.handle(call: call.method, args: args) {
          result(value)
        } else if call.method.hasPrefix("sync") || call.method.hasPrefix("end") {
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // Additive: last IAP product id in Keychain (survives delete/reinstall).
    let iapMemoryMessenger: FlutterBinaryMessenger? = {
      if let controller = self.window?.rootViewController as? FlutterViewController {
        return controller.binaryMessenger
      }
      return self.registrar(forPlugin: "com.biblebookapp.iap_memory")?.messenger()
    }()
    if let messenger = iapMemoryMessenger {
      let channel = FlutterMethodChannel(
        name: "com.biblebookapp/iap_memory",
        binaryMessenger: messenger
      )
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
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
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return result
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
