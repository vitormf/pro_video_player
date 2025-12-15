import AVFoundation
import AVKit
import Foundation

#if os(iOS)
    import Flutter
    import UIKit
#elseif os(macOS)
    import FlutterMacOS
#endif

/// Configuration for platform-specific plugin behavior
public struct PlatformConfig {
    let channelName: String
    let viewTypeId: String
    let supportsPipActions: Bool

    public init(
        channelName: String,
        viewTypeId: String,
        supportsPipActions: Bool
    ) {
        self.channelName = channelName
        self.viewTypeId = viewTypeId
        self.supportsPipActions = supportsPipActions
    }

    public static let ios = PlatformConfig(
        channelName: "com.example.pro_video_player_ios/methods",
        viewTypeId: "com.example.pro_video_player_ios/video_view",
        supportsPipActions: true
    )

    public static let macOS = PlatformConfig(
        channelName: "com.example.pro_video_player_macos/methods",
        viewTypeId: "com.example.pro_video_player_macos/video_view",
        supportsPipActions: false
    )
}

/// Protocol for platform-specific differences in plugin behavior
public protocol PlatformPluginBehavior {
    /// Returns whether PiP is supported on this platform
    func isPipSupported() -> Bool

    /// Returns whether background playback is supported on this platform
    func isBackgroundPlaybackSupported() -> Bool

    /// Handles platform-specific PiP actions (iOS only)
    func handleSetPipActions(
        call: FlutterMethodCall, player: SharedVideoPlayerWrapper, result: @escaping FlutterResult)

    /// Creates a platform-specific video player instance
    func createVideoPlayer(playerId: Int, source: [String: Any], options: [String: Any])
        -> SharedVideoPlayerWrapper
}

/// Shared base implementation for iOS and macOS video player plugins.
///
/// This class contains all the common method channel handling logic to eliminate
/// code duplication between iOS and macOS implementations.
open class SharedPluginBase: NSObject {
    private var players: [Int: SharedVideoPlayerWrapper] = [:]
    private var nextPlayerId: Int = 0
    private let registrar: Any
    private let platformBehavior: PlatformPluginBehavior
    private let config: PlatformConfig

    public init(registrar: Any, platformBehavior: PlatformPluginBehavior, config: PlatformConfig) {
        self.registrar = registrar
        self.platformBehavior = platformBehavior
        self.config = config
        super.init()
    }

    public func getPlayer(for playerId: Int) -> SharedVideoPlayerWrapper? {
        return players[playerId]
    }

    /// Main method call handler - routes method calls to appropriate handlers
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Handle verbose logging control
        if call.method == "setVerboseLogging" {
            handleSetVerboseLogging(call: call, result: result)
            return
        }

        verboseLog("Method called: \(call.method)", tag: "Plugin")

        switch call.method {
        case "create":
            handleCreate(call: call, result: result)
        case "dispose":
            handleDispose(call: call, result: result)
        case "play":
            handlePlay(call: call, result: result)
        case "pause":
            handlePause(call: call, result: result)
        case "stop":
            handleStop(call: call, result: result)
        case "seekTo":
            handleSeekTo(call: call, result: result)
        case "setPlaybackSpeed":
            handleSetPlaybackSpeed(call: call, result: result)
        case "setVolume":
            handleSetVolume(call: call, result: result)
        case "setLooping":
            handleSetLooping(call: call, result: result)
        case "setScalingMode":
            handleSetScalingMode(call: call, result: result)
        case "setSubtitleTrack":
            handleSetSubtitleTrack(call: call, result: result)
        case "setSubtitleRenderMode":
            handleSetSubtitleRenderMode(call: call, result: result)
        case "setAudioTrack":
            handleSetAudioTrack(call: call, result: result)
        case "addExternalSubtitle":
            handleAddExternalSubtitle(call: call, result: result)
        case "removeExternalSubtitle":
            handleRemoveExternalSubtitle(call: call, result: result)
        case "getExternalSubtitles":
            handleGetExternalSubtitles(call: call, result: result)
        case "getPosition":
            handleGetPosition(call: call, result: result)
        case "getDuration":
            handleGetDuration(call: call, result: result)
        case "enterPip":
            handleEnterPip(call: call, result: result)
        case "exitPip":
            handleExitPip(call: call, result: result)
        case "isPipSupported":
            handleIsPipSupported(result: result)
        case "setPipActions":
            handleSetPipActionsWrapper(call: call, result: result)
        case "enterFullscreen":
            handleEnterFullscreen(call: call, result: result)
        case "exitFullscreen":
            handleExitFullscreen(call: call, result: result)
        case "setMediaMetadata":
            handleSetMediaMetadata(call: call, result: result)
        case "getVideoQualities":
            handleGetVideoQualities(call: call, result: result)
        case "setVideoQuality":
            handleSetVideoQuality(call: call, result: result)
        case "getCurrentVideoQuality":
            handleGetCurrentVideoQuality(call: call, result: result)
        case "isQualitySelectionSupported":
            handleIsQualitySelectionSupported(call: call, result: result)
        case "setBackgroundPlayback":
            handleSetBackgroundPlayback(call: call, result: result)
        case "isBackgroundPlaybackSupported":
            handleIsBackgroundPlaybackSupportedWrapper(result: result)
        case "getPlatformCapabilities":
            handleGetPlatformCapabilities(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    private func handleGetPlatformCapabilities(result: @escaping FlutterResult) {
        verboseLog("Getting platform capabilities", tag: "Plugin")

        // Determine platform name from config
        #if os(iOS)
            let platformName = "iOS"
            let supportsScreenBrightness = true
        #elseif os(macOS)
            let platformName = "macOS"
            let supportsScreenBrightness = false
        #else
            let platformName = "Unknown"
            let supportsScreenBrightness = false
        #endif

        let capabilities: [String: Any] = [
            "supportsPictureInPicture": true,  // iOS/macOS support PiP via AVPictureInPictureController
            "supportsFullscreen": true,  // iOS/macOS support fullscreen
            "supportsBackgroundPlayback": platformBehavior.isBackgroundPlaybackSupported(),  // Depends on configuration
            "supportsCasting": true,  // iOS/macOS support AirPlay
            "supportsAirPlay": true,  // Built-in AirPlay support
            "supportsChromecast": false,  // Chromecast SDK not integrated
            "supportsRemotePlayback": false,  // Remote Playback API is Web-only
            "supportsQualitySelection": true,  // Supports quality selection for HLS streams
            "supportsPlaybackSpeedControl": true,  // AVPlayer supports playback speed
            "supportsSubtitles": true,  // Supports subtitles via AVMediaSelectionGroup
            "supportsExternalSubtitles": true,  // Supports external subtitle loading
            "supportsAudioTrackSelection": true,  // Supports audio track selection
            "supportsChapters": true,  // Supports chapters via AVTimedMetadataGroup
            "supportsVideoMetadataExtraction": true,  // Supports metadata via AVAssetTrack
            "supportsNetworkMonitoring": true,  // Has NWPathMonitor for network monitoring
            "supportsBandwidthEstimation": true,  // Provides bandwidth via AVPlayerItemAccessLog
            "supportsAdaptiveBitrate": true,  // Supports ABR (maxBitrate only)
            "supportsHLS": true,  // AVPlayer has native HLS support
            "supportsDASH": false,  // AVPlayer does not support DASH
            "supportsDeviceVolumeControl": true,  // Supports volume control
            "supportsScreenBrightnessControl": supportsScreenBrightness,  // iOS only
            "platformName": platformName,
            "nativePlayerType": "AVPlayer",
            "additionalInfo": [
                "osVersion": ProcessInfo.processInfo.operatingSystemVersionString,
                "pipSupported": platformBehavior.isPipSupported(),
                "backgroundPlaybackSupported": platformBehavior.isBackgroundPlaybackSupported(),
            ],
        ]

        result(capabilities)
    }

    private func handleSetVerboseLogging(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? [String: Any],
            let enabled = args["enabled"] as? Bool
        {
            setVideoPlayerVerboseLogging(enabled)
            verboseLog("Verbose logging \(enabled ? "enabled" : "disabled")", tag: "Plugin")
            result(nil)
        } else {
            result(
                FlutterError(
                    code: "INVALID_ARGS", message: "Invalid arguments for setVerboseLogging",
                    details: nil))
        }
    }

    /// Creates a platform-specific video player by delegating to platformBehavior
    private func createVideoPlayer(playerId: Int, source: [String: Any], options: [String: Any])
        -> SharedVideoPlayerWrapper
    {
        return platformBehavior.createVideoPlayer(
            playerId: playerId, source: source, options: options)
    }

    private func handleCreate(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let sourceData = args["source"] as? [String: Any],
            let optionsData = args["options"] as? [String: Any]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let playerId = nextPlayerId
        nextPlayerId += 1

        let player = createVideoPlayer(playerId: playerId, source: sourceData, options: optionsData)

        players[playerId] = player
        result(playerId)
    }

    private func handleDispose(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        players[playerId]?.dispose()
        players.removeValue(forKey: playerId)
        result(nil)
    }

    private func handlePlay(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        player.play()
        result(nil)
    }

    private func handlePause(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        player.pause()
        result(nil)
    }

    private func handleStop(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        player.stop()
        result(nil)
    }

    private func handleSeekTo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let position = args["position"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        guard position >= 0 else {
            result(
                FlutterError(
                    code: "INVALID_ARGS", message: "Position must be non-negative", details: nil))
            return
        }

        player.seekTo(milliseconds: position)
        result(nil)
    }

    private func handleSetPlaybackSpeed(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let speed = args["speed"] as? Double,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        guard speed > 0.0 && speed <= 10.0 else {
            result(
                FlutterError(
                    code: "INVALID_ARGS",
                    message: "Playback speed must be between 0.0 (exclusive) and 10.0", details: nil
                ))
            return
        }

        player.setPlaybackSpeed(Float(speed))
        result(nil)
    }

    private func handleSetVolume(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let volume = args["volume"] as? Double,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        guard volume >= 0.0 && volume <= 1.0 else {
            result(
                FlutterError(
                    code: "INVALID_ARGS", message: "Volume must be between 0.0 and 1.0",
                    details: nil))
            return
        }

        player.setVolume(Float(volume))
        result(nil)
    }

    private func handleSetLooping(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let looping = args["looping"] as? Bool,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        player.setLooping(looping)
        result(nil)
    }

    private func handleSetScalingMode(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let scalingMode = args["scalingMode"] as? String,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let validModes: Set<String> = ["fit", "fill", "fitWidth", "fitHeight"]
        guard validModes.contains(scalingMode) else {
            result(
                FlutterError(
                    code: "INVALID_ARGS",
                    message: "Invalid scaling mode. Must be one of: fit, fill, fitWidth, fitHeight",
                    details: nil))
            return
        }

        player.setScalingMode(scalingMode)
        result(nil)
    }

    private func handleSetSubtitleTrack(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let track = args["track"] as? [String: Any]
        player.setSubtitleTrack(track)
        result(nil)
    }

    private func handleSetAudioTrack(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let track = args["track"] as? [String: Any]
        player.setAudioTrack(track)
        result(nil)
    }

    private func handleSetSubtitleRenderMode(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let renderMode = args["renderMode"] as? String
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        verboseLog("setSubtitleRenderMode() called for player \(playerId), mode: \(renderMode)", tag: "Plugin")

        // TODO: Implement subtitle render mode switching for iOS/macOS
        // For now, log and return success to maintain compatibility
        result(nil)
    }

    private func handleAddExternalSubtitle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let sourceType = args["sourceType"] as? String,
            let path = args["path"] as? String
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let format = args["format"] as? String
        let label = args["label"] as? String
        let language = args["language"] as? String
        let isDefault = args["isDefault"] as? Bool ?? false
        let webvttContent = args["webvttContent"] as? String

        verboseLog(
            "addExternalSubtitle() called for player \(playerId): sourceType=\(sourceType), path=\(path), format=\(format ?? "nil"), webvttContent=\(webvttContent != nil ? "\(webvttContent!.count) chars" : "nil")",
            tag: "Plugin"
        )

        // TODO: Implement external subtitle loading for iOS/macOS using AVPlayerItemLegibleOutput
        // For now, return null to indicate not yet implemented
        // The Dart layer will handle this gracefully by using Flutter rendering mode
        result(nil)
    }

    private func handleRemoveExternalSubtitle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let trackId = args["trackId"] as? String
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        verboseLog("removeExternalSubtitle() called for player \(playerId), trackId: \(trackId)", tag: "Plugin")

        // TODO: Implement external subtitle removal for iOS/macOS
        // For now, return false to indicate not yet implemented
        result(false)
    }

    private func handleGetExternalSubtitles(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        verboseLog("getExternalSubtitles() called for player \(playerId)", tag: "Plugin")

        // TODO: Implement external subtitle listing for iOS/macOS
        // For now, return empty array to indicate not yet implemented
        result([])
    }

    private func handleGetPosition(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        result(player.getPosition())
    }

    private func handleGetDuration(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        result(player.getDuration())
    }

    private func handleEnterPip(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        let success = player.enterPip()
        result(success)
    }

    private func handleExitPip(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        player.exitPip()
        result(nil)
    }

    private func handleIsPipSupported(result: @escaping FlutterResult) {
        result(platformBehavior.isPipSupported())
    }

    private func handleSetPipActionsWrapper(
        call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        platformBehavior.handleSetPipActions(call: call, player: player, result: result)
    }

    private func handleEnterFullscreen(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        let success = player.enterFullscreen()
        result(success)
    }

    private func handleExitFullscreen(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        player.exitFullscreen()
        result(nil)
    }

    private func handleSetMediaMetadata(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        let metadata = args["metadata"] as? [String: Any] ?? [:]
        player.setMediaMetadata(metadata)
        result(nil)
    }

    private func handleGetVideoQualities(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        result(player.getVideoQualities())
    }

    private func handleSetVideoQuality(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        let track = args["track"] as? [String: Any]
        result(player.setVideoQuality(track))
    }

    private func handleGetCurrentVideoQuality(
        call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        result(player.getCurrentVideoQuality())
    }

    private func handleIsQualitySelectionSupported(
        call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        result(player.isQualitySelectionSupported())
    }

    private func handleSetBackgroundPlayback(
        call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let enabled = args["enabled"] as? Bool,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        result(player.setBackgroundPlayback(enabled))
    }

    private func handleIsBackgroundPlaybackSupportedWrapper(result: @escaping FlutterResult) {
        result(platformBehavior.isBackgroundPlaybackSupported())
    }
}
