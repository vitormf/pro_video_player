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

        // Register traditional MethodChannel (for backward compatibility during migration)
        let channel = FlutterMethodChannel(
            name: PlatformConfig.ios.channelName,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Register Pigeon API
        instance.pigeonHandler = PigeonHostApiHandler(sharedBase: instance.sharedBase, platformBehavior: instance)
        ProVideoPlayerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance.pigeonHandler)

        let factory = VideoPlayerViewFactory(plugin: instance.sharedBase)
        registrar.register(factory, withId: PlatformConfig.ios.viewTypeId)

        // Register AirPlay route picker view factory
        let airPlayFactory = AirPlayRoutePickerViewFactory(messenger: registrar.messenger())
        registrar.register(airPlayFactory, withId: "dev.pro_video_player_ios/airplay_picker")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        sharedBase.handle(call, result: result)
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
