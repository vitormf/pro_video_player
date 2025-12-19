import AVFoundation
import AVKit
import FlutterMacOS
import Foundation

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
            config: .macOS
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
            config: .macOS
        )

        // Register Pigeon API - SharedPluginBase implements ProVideoPlayerHostApi directly
        ProVideoPlayerHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance.sharedBase)

        // Register platform views
        let factory = VideoPlayerViewFactory(plugin: instance.sharedBase)
        registrar.register(factory, withId: PlatformConfig.macOS.viewTypeId)

        // Register AirPlay route picker view factory
        let airPlayFactory = AirPlayRoutePickerViewFactory(messenger: registrar.messenger)
        registrar.register(airPlayFactory, withId: "dev.pro_video_player.macos/airplay_picker")
    }

    /// Gets a player by ID (for testing purposes)
    func getPlayer(for playerId: Int) -> SharedVideoPlayerWrapper? {
        return sharedBase.getPlayer(for: playerId)
    }

    public func isPipSupported() -> Bool {
        // On macOS, AVPictureInPictureController.isPictureInPictureSupported() is unreliable
        // and often returns false even when PiP is available. We check version instead.
        // PiP requires macOS 10.15+ and the com.apple.security.device.audio-video entitlement.
        let supported: Bool
        if #available(macOS 10.15, *) {
            supported = true
        } else {
            supported = false
        }

        return supported
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
