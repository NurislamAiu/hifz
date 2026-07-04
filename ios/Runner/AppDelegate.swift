import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appGroupId = "group.com.nurislam.hifz"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let registrar = registrar(forPlugin: "WidgetSyncPlugin") {
      let channel = FlutterMethodChannel(
        name: "hifz/widget_sync",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "savePrayerTimes" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self?.savePrayerTimesForWidget(call.arguments)
        result(nil)
      }
    }
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func savePrayerTimesForWidget(_ arguments: Any?) {
    guard let payload = arguments as? [String: Any],
          let defaults = UserDefaults(suiteName: appGroupId) else {
      return
    }

    defaults.set(payload, forKey: "prayerTimesPayload")
    defaults.set(Date().timeIntervalSince1970, forKey: "prayerTimesUpdatedAt")
    defaults.synchronize()

    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: "HifzReminderWidget")
    }
  }
}
