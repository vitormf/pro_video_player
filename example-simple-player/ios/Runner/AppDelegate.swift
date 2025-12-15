import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var fileChannel: FlutterMethodChannel?
    private var pendingFile: String?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Set up method channel for file handling
        if let controller = window?.rootViewController as? FlutterViewController {
            fileChannel = FlutterMethodChannel(
                name: "simple_player/file",
                binaryMessenger: controller.binaryMessenger
            )

            fileChannel?.setMethodCallHandler { [weak self] call, result in
                if call.method == "getInitialFile" {
                    result(self?.pendingFile)
                    self?.pendingFile = nil
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Handle files opened from other apps (Files app, Share sheet, etc.)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        let urlString = url.absoluteString

        if fileChannel != nil {
            // App is running - send directly to Flutter
            fileChannel?.invokeMethod("openFile", arguments: urlString)
        } else {
            // App not fully started - save for later
            pendingFile = urlString
        }

        return true
    }
}
