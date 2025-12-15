import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var fileChannel: FlutterMethodChannel?
    private var pendingFile: String?
    private var flutterReady = false

    override func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up method channel for file handling
        if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
            fileChannel = FlutterMethodChannel(
                name: "simple_player/file",
                binaryMessenger: controller.engine.binaryMessenger
            )

            fileChannel?.setMethodCallHandler { [weak self] call, result in
                if call.method == "getInitialFile" {
                    // Flutter is ready - mark it and return pending file
                    self?.flutterReady = true
                    result(self?.pendingFile)
                    self?.pendingFile = nil
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // Handle files opened from Finder (double-click or "Open With")
    override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        handleOpenURL(url)
        return true
    }

    // Handle multiple files
    override func application(_ sender: NSApplication, openFiles filenames: [String]) {
        // Only play the first file
        if let filename = filenames.first {
            let url = URL(fileURLWithPath: filename)
            handleOpenURL(url)
        }
        sender.reply(toOpenOrPrint: .success)
    }

    private func handleOpenURL(_ url: URL) {
        let urlString = url.absoluteString

        if flutterReady, let channel = fileChannel {
            // Flutter is ready - send directly
            channel.invokeMethod("openFile", arguments: urlString)
        } else {
            // Flutter not ready yet - save for later retrieval via getInitialFile
            pendingFile = urlString
        }
    }
}
