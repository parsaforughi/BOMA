import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.boma.app/clipboard",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "copyImage":
          guard
            let args = call.arguments as? [String: Any],
            let typedData = args["bytes"] as? FlutterStandardTypedData
          else {
            result(FlutterError(code: "NO_BYTES", message: "No image bytes provided", details: nil))
            return
          }
          guard let image = UIImage(data: typedData.data) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Could not decode PNG", details: nil))
            return
          }
          UIPasteboard.general.image = image
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
