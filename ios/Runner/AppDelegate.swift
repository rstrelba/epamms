import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    let clipboardChannel = FlutterMethodChannel(
      name: "com.mysterioussanta/clipboard",
      binaryMessenger: controller.binaryMessenger
    )
    
    clipboardChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "copyImage" {
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments are invalid", details: nil))
          return
        }
        
        var imageData: Data?
        if let typedData = args["image"] as? FlutterStandardTypedData {
          imageData = typedData.data
        } else if let bytes = args["image"] as? [UInt8] {
          imageData = Data(bytes)
        }
        
        guard let data = imageData else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Image data is invalid", details: nil))
          return
        }
        
        let success = self.copyImageToClipboard(imageData: data)
        if success {
          result(true)
        } else {
          result(FlutterError(code: "COPY_FAILED", message: "Failed to copy image to clipboard", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func copyImageToClipboard(imageData: Data) -> Bool {
    guard let image = UIImage(data: imageData) else {
      return false
    }
    
    UIPasteboard.general.image = image
    return true
  }
}
