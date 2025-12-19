import AVFoundation
import AVKit
import Flutter
import UIKit

public class ProVideoPlayerPlugin: NSObject, FlutterPlugin, PlatformPluginBehavior {
    private(set) var sharedBase: SharedPluginBase!
    private var registrar: FlutterPluginRegistrar!

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

        // Register Pigeon API - SharedPluginBase implements ProVideoPlayerHostApi directly
        ProVideoPlayerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance.sharedBase)

        // Register platform views
        let factory = VideoPlayerViewFactory(plugin: instance.sharedBase)
        registrar.register(factory, withId: PlatformConfig.ios.viewTypeId)

        // Register AirPlay route picker view factory
        let airPlayFactory = AirPlayRoutePickerViewFactory(messenger: registrar.messenger())
        registrar.register(airPlayFactory, withId: "dev.pro_video_player.ios/airplay_picker")
    }

    /// Gets a player by ID (for testing purposes)
    func getPlayer(for playerId: Int) -> SharedVideoPlayerWrapper? {
        return sharedBase.getPlayer(for: playerId)
    }

    public func isPipSupported() -> Bool {
        // On iOS, AVPictureInPictureController.isPictureInPictureSupported() is unreliable
        // and often returns false even when PiP is available. We check version instead.
        // PiP requires iOS 14.0+ and UIBackgroundModes with 'audio' in Info.plist.
        let supported: Bool
        if #available(iOS 14.0, *) {
            supported = true
        } else {
            supported = false
        }

        return supported
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
