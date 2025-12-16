import AVFoundation
import AVKit
import FlutterMacOS
import Foundation

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
            config: .macOS
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
            config: .macOS
        )

        // Register traditional MethodChannel (for backward compatibility during migration)
        let channel = FlutterMethodChannel(
            name: PlatformConfig.macOS.channelName,
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Register Pigeon API
        instance.pigeonHandler = PigeonHostApiHandler(sharedBase: instance.sharedBase, platformBehavior: instance)
        ProVideoPlayerHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance.pigeonHandler)

        let factory = VideoPlayerViewFactory(plugin: instance.sharedBase)
        registrar.register(factory, withId: PlatformConfig.macOS.viewTypeId)

        // Register AirPlay route picker view factory
        let airPlayFactory = AirPlayRoutePickerViewFactory(messenger: registrar.messenger)
        registrar.register(airPlayFactory, withId: "dev.pro_video_player_macos/airplay_picker")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        sharedBase.handle(call, result: result)
    }

    /// Gets a player by ID (for testing purposes)
    func getPlayer(for playerId: Int) -> SharedVideoPlayerWrapper? {
        return sharedBase.getPlayer(for: playerId)
    }

    public func isPipSupported() -> Bool {
        if #available(macOS 10.15, *) {
            return AVPictureInPictureController.isPictureInPictureSupported()
        }
        return false
    }

    public func handleSetPipActions(
        call: FlutterMethodCall, player: SharedVideoPlayerWrapper, result: @escaping FlutterResult
    ) {
        result(
            FlutterError(
                code: "NOT_SUPPORTED", message: "PiP actions not supported on macOS", details: nil
            ))
    }

    public func isBackgroundPlaybackSupported() -> Bool {
        return true
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
