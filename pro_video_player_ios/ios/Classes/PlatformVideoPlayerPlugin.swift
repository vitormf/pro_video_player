import AVFoundation
import AVKit
import Flutter
import UIKit

public class ProVideoPlayerPlugin: NSObject, FlutterPlugin, PlatformPluginBehavior {
    private(set) var sharedBase: SharedPluginBase!
    private var registrar: FlutterPluginRegistrar!
    private var pigeonHandler: PigeonHostApiHandler?

    /// Test-friendly initializer that creates a plugin instance with a custom registrar
    /// - Parameter registrar: The Flutter plugin registrar to use
    init(registrar: FlutterPluginRegistrar) {
        super.init()
        self.registrar = registrar
        self.sharedBase = SharedPluginBase(
            registrar: registrar,
            platformBehavior: self,
            config: .ios
        )
        self.pigeonHandler = PigeonHostApiHandler(sharedBase: self.sharedBase, platformBehavior: self)
    }

    override init() {
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ProVideoPlayerPlugin()
        instance.registrar = registrar
        instance.sharedBase = SharedPluginBase(
            registrar: registrar,
            platformBehavior: instance,
            config: .ios
        )

        // Register Pigeon API for all method calls
        instance.pigeonHandler = PigeonHostApiHandler(sharedBase: instance.sharedBase, platformBehavior: instance)
        ProVideoPlayerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance.pigeonHandler)

        // Register platform views
        let factory = VideoPlayerViewFactory(plugin: instance.sharedBase)
        registrar.register(factory, withId: PlatformConfig.ios.viewTypeId)

        // Register AirPlay route picker view factory
        let airPlayFactory = AirPlayRoutePickerViewFactory(messenger: registrar.messenger())
        registrar.register(airPlayFactory, withId: "dev.pro_video_player.ios/airplay_picker")
    }

    // Note: This handle() method is no longer used since we migrated to Pigeon.
    // It's kept only because tests might still reference it.
    // All method calls now go through PigeonHostApiHandler instead.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // No-op: All calls should go through Pigeon API now
        result(FlutterMethodNotImplemented)
    }

    /// Gets a player by ID (for testing purposes)
    func getPlayer(for playerId: Int) -> SharedVideoPlayerWrapper? {
        return sharedBase.getPlayer(for: playerId)
    }

    public func isPipSupported() -> Bool {
        if #available(iOS 14.0, *) {
            return AVPictureInPictureController.isPictureInPictureSupported()
        }
        return false
    }

    public func handleSetPipActions(
        call: FlutterMethodCall, player: SharedVideoPlayerWrapper, result: @escaping FlutterResult
    ) {
        let args = call.arguments as? [String: Any]
        let actions = args?["actions"] as? [[String: Any]]
        player.setPipActions(actions)
        result(nil)
    }

    public func isBackgroundPlaybackSupported() -> Bool {
        if let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] {
            return backgroundModes.contains("audio")
        }
        return false
    }

    public func createVideoPlayer(playerId: Int, source: [String: Any], options: [String: Any])
        -> SharedVideoPlayerWrapper
    {
        return VideoPlayer(
            playerId: playerId,
            registrar: registrar,
            source: source,
            options: options
        )
    }
}
