import AVFoundation
import AVKit
import Foundation

#if os(iOS)
    import Flutter
    import MediaPlayer
    import UIKit
#elseif os(macOS)
    import FlutterMacOS
    import IOKit.ps
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
open class SharedPluginBase: NSObject, FlutterStreamHandler {
    private var players: [Int: SharedVideoPlayerWrapper] = [:]
    private var nextPlayerId: Int = 0
    private let registrar: Any
    private let platformBehavior: PlatformPluginBehavior
    private let config: PlatformConfig

    // Battery updates stream
    private var batteryEventSink: FlutterEventSink?
    private var batteryEventChannel: FlutterEventChannel?

    #if os(iOS)
        /// Cached MPVolumeView for setting system volume without showing system HUD.
        /// The view must be added to the view hierarchy to work correctly.
        private lazy var volumeView: MPVolumeView = {
            let view = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
            view.alpha = 0.01  // Nearly invisible but still functional
            return view
        }()
    #endif

    public init(registrar: Any, platformBehavior: PlatformPluginBehavior, config: PlatformConfig) {
        self.registrar = registrar
        self.platformBehavior = platformBehavior
        self.config = config
        super.init()

        // Set up battery event channel
        setupBatteryEventChannel()
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
        case "getDeviceVolume":
            handleGetDeviceVolume(result: result)
        case "setDeviceVolume":
            handleSetDeviceVolume(call: call, result: result)
        case "getScreenBrightness":
            handleGetScreenBrightness(result: result)
        case "setScreenBrightness":
            handleSetScreenBrightness(call: call, result: result)
        case "getBatteryInfo":
            handleGetBatteryInfo(result: result)
        case "setLooping":
            handleSetLooping(call: call, result: result)
        case "setScalingMode":
            handleSetScalingMode(call: call, result: result)
        case "setSubtitleTrack":
            handleSetSubtitleTrack(call: call, result: result)
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
        case "getVideoMetadata":
            handleGetVideoMetadata(call: call, result: result)
        case "setControlsMode":
            handleSetControlsMode(call: call, result: result)
        case "isCastingSupported":
            handleIsCastingSupported(result: result)
        case "getAvailableCastDevices":
            handleGetAvailableCastDevices(call: call, result: result)
        case "startCasting":
            handleStartCasting(call: call, result: result)
        case "stopCasting":
            handleStopCasting(call: call, result: result)
        case "getCastState":
            handleGetCastState(call: call, result: result)
        case "getCurrentCastDevice":
            handleGetCurrentCastDevice(call: call, result: result)
        case "setWindowFullscreen":
            handleSetWindowFullscreen(call: call, result: result)
        case "getPlatformCapabilities":
            handleGetPlatformCapabilities(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    private func handleGetPlatformCapabilities(result: @escaping FlutterResult) {
        verboseLog("Getting platform capabilities", tag: "Plugin")

        let capabilities: [String: Any] = [
            "supportsPictureInPicture": true,  // iOS always supports PiP via AVPictureInPictureController
            "supportsFullscreen": true,  // iOS supports fullscreen via UIWindowScene
            "supportsBackgroundPlayback": platformBehavior.isBackgroundPlaybackSupported(),  // Depends on Info.plist configuration
            "supportsCasting": true,  // iOS supports AirPlay
            "supportsAirPlay": true,  // iOS has built-in AirPlay support
            "supportsChromecast": false,  // Chromecast SDK not integrated (future enhancement)
            "supportsRemotePlayback": false,  // Remote Playback API is Web-only
            "supportsQualitySelection": true,  // iOS supports quality selection for HLS streams
            "supportsPlaybackSpeedControl": true,  // AVPlayer supports playback speed
            "supportsSubtitles": true,  // iOS supports subtitles via AVMediaSelectionGroup
            "supportsExternalSubtitles": true,  // iOS supports external subtitle loading
            "supportsAudioTrackSelection": true,  // iOS supports audio track selection
            "supportsChapters": true,  // iOS supports chapters via AVTimedMetadataGroup
            "supportsVideoMetadataExtraction": true,  // iOS supports metadata via AVAssetTrack
            "supportsNetworkMonitoring": true,  // iOS has NWPathMonitor for network monitoring
            "supportsBandwidthEstimation": true,  // iOS provides bandwidth via AVPlayerItemAccessLog
            "supportsAdaptiveBitrate": true,  // iOS supports ABR (maxBitrate only)
            "supportsHLS": true,  // AVPlayer has native HLS support
            "supportsDASH": false,  // AVPlayer does not support DASH
            "supportsDeviceVolumeControl": true,  // iOS supports volume control via AVAudioSession
            "supportsScreenBrightnessControl": true,  // iOS supports brightness via UIScreen
            "platformName": "iOS",
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

    private func handleGetDeviceVolume(result: @escaping FlutterResult) {
        #if os(iOS)
            let volume = AVAudioSession.sharedInstance().outputVolume
            result(Double(volume))
        #elseif os(macOS)
            // macOS doesn't have a simple API to get system volume
            // Return 1.0 as a fallback (full volume)
            result(1.0)
        #endif
    }

    private func handleSetDeviceVolume(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let volume = args["volume"] as? Double
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

        #if os(iOS)
            // iOS: Use MPVolumeView to set system volume without showing system HUD
            // The volumeView must be in the view hierarchy for this to work
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    result(nil)
                    return
                }

                // Ensure the volume view is in the view hierarchy
                if self.volumeView.superview == nil {
                    if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                        window.addSubview(self.volumeView)
                    }
                }

                // Find and use the slider to set volume
                if let slider = self.volumeView.subviews.first(where: { $0 is UISlider })
                    as? UISlider
                {
                    slider.value = Float(volume)
                }
                result(nil)
            }
            return
        #elseif os(macOS)
            // macOS: Use AppleScript to set system volume (0-100 scale)
            let volumePercent = Int(volume * 100)
            let script = "set volume output volume \(volumePercent)"
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                if let error = error {
                    result(
                        FlutterError(
                            code: "VOLUME_ERROR", message: "Failed to set volume: \(error)",
                            details: nil))
                } else {
                    result(nil)
                }
            } else {
                result(
                    FlutterError(
                        code: "VOLUME_ERROR", message: "Failed to create AppleScript", details: nil)
                )
            }
        #endif
    }

    private func handleGetScreenBrightness(result: @escaping FlutterResult) {
        #if os(iOS)
            let brightness = UIScreen.main.brightness
            result(Double(brightness))
        #elseif os(macOS)
            // macOS doesn't have a simple API to get screen brightness
            result(1.0)
        #endif
    }

    private func handleSetScreenBrightness(call: FlutterMethodCall, result: @escaping FlutterResult)
    {
        guard let args = call.arguments as? [String: Any],
            let brightness = args["brightness"] as? Double
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        guard brightness >= 0.0 && brightness <= 1.0 else {
            result(
                FlutterError(
                    code: "INVALID_ARGS", message: "Brightness must be between 0.0 and 1.0",
                    details: nil))
            return
        }

        #if os(iOS)
            UIScreen.main.brightness = CGFloat(brightness)
            result(nil)
        #elseif os(macOS)
            // macOS brightness control requires private APIs or external tools
            // For now, just return success as a no-op
            _ = brightness  // Suppress unused variable warning
            result(nil)
        #endif
    }

    private func handleGetBatteryInfo(result: @escaping FlutterResult) {
        #if os(iOS)
            // Enable battery monitoring
            UIDevice.current.isBatteryMonitoringEnabled = true

            let batteryLevel = UIDevice.current.batteryLevel
            // batteryLevel returns -1.0 if battery state is unknown
            if batteryLevel < 0 {
                result(nil)
                return
            }

            let batteryState = UIDevice.current.batteryState
            let isCharging = batteryState == .charging || batteryState == .full
            let percentage = Int(batteryLevel * 100)

            let batteryInfo: [String: Any] = [
                "percentage": percentage,
                "isCharging": isCharging
            ]
            result(batteryInfo)
        #elseif os(macOS)
            // Use IOKit to get battery info on macOS
            let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
            let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

            guard let source = sources.first else {
                // No battery (desktop Mac)
                result(nil)
                return
            }

            guard let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] else {
                result(nil)
                return
            }

            // Get current capacity and max capacity to calculate percentage
            if let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int,
               let maxCapacity = description[kIOPSMaxCapacityKey] as? Int,
               maxCapacity > 0 {
                let percentage = (currentCapacity * 100) / maxCapacity
                let isCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false

                let batteryInfo: [String: Any] = [
                    "percentage": percentage,
                    "isCharging": isCharging
                ]
                result(batteryInfo)
            } else {
                result(nil)
            }
        #endif
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

        let validModes: Set<String> = ["fit", "fill", "stretch", "fitWidth", "fitHeight"]
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

    // MARK: - External Subtitles

    private func handleAddExternalSubtitle(call: FlutterMethodCall, result: @escaping FlutterResult)
    {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let sourceType = args["sourceType"] as? String,
            let path = args["path"] as? String,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let format = args["format"] as? String
        let label = args["label"] as? String
        let language = args["language"] as? String
        let isDefault = args["isDefault"] as? Bool ?? false

        player.addExternalSubtitle(
            sourceType: sourceType,
            path: path,
            format: format,
            label: label,
            language: language,
            isDefault: isDefault
        ) { track in
            result(track)
        }
    }

    private func handleRemoveExternalSubtitle(
        call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let trackId = args["trackId"] as? String,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let success = player.removeExternalSubtitle(trackId: trackId)
        result(success)
    }

    private func handleGetExternalSubtitles(
        call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        result(player.getExternalSubtitles())
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

    private func handleGetVideoMetadata(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        result(player.getVideoMetadata())
    }

    private func handleSetControlsMode(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let controlsModeString = args["controlsMode"] as? String
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let controlsMode: ControlsMode =
            switch controlsModeString {
            case "native": .native
            case "flutter": .custom  // Flutter controls are handled as custom on native side
            default: .none
            }

        VideoPlayerViewRegistry.shared.setControlsMode(for: playerId, mode: controlsMode)
        result(nil)
    }

    // MARK: - Casting Methods

    private func handleIsCastingSupported(result: @escaping FlutterResult) {
        // AirPlay is always supported on iOS/macOS
        result(true)
    }

    private func handleGetAvailableCastDevices(
        call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        result(player.getAvailableCastDevices())
    }

    private func handleStartCasting(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        // Device is optional - on iOS/macOS AirPlay selection is done via system UI
        let device = args["device"] as? [String: Any] ?? [:]
        result(player.startCasting(device: device))
    }

    private func handleStopCasting(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        player.stopCasting()
        result(nil)
    }

    private func handleGetCastState(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        result(player.getCastState())
    }

    private func handleGetCurrentCastDevice(
        call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
        guard let args = call.arguments as? [String: Any],
            let playerId = args["playerId"] as? Int,
            let player = players[playerId]
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid player ID", details: nil))
            return
        }

        result(player.getCurrentCastDevice())
    }

    private func handleSetWindowFullscreen(call: FlutterMethodCall, result: @escaping FlutterResult)
    {
        guard let args = call.arguments as? [String: Any],
            let fullscreen = args["fullscreen"] as? Bool
        else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        // Return immediately to avoid blocking Flutter
        result(nil)

        #if os(macOS)
            // Perform window fullscreen toggle asynchronously after a brief delay
            // This prevents conflicts with Flutter's navigation animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard let window = NSApplication.shared.mainWindow else {
                    return
                }

                let isCurrentlyFullscreen = window.styleMask.contains(.fullScreen)

                // Only toggle if the desired state differs from current state
                if fullscreen != isCurrentlyFullscreen {
                    window.toggleFullScreen(nil)
                }
            }
        #endif
    }

    // MARK: - Battery Event Channel

    private func setupBatteryEventChannel() {
        #if os(iOS)
            let messenger = (registrar as! FlutterPluginRegistrar).messenger()
            batteryEventChannel = FlutterEventChannel(
                name: "com.example.pro_video_player_ios/batteryUpdates",
                binaryMessenger: messenger
            )
        #elseif os(macOS)
            let messenger = (registrar as! FlutterPluginRegistrar).messenger
            batteryEventChannel = FlutterEventChannel(
                name: "com.example.pro_video_player_macos/batteryUpdates",
                binaryMessenger: messenger
            )
        #endif
        batteryEventChannel?.setStreamHandler(self)
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        batteryEventSink = events

        #if os(iOS)
            // Enable battery monitoring
            UIDevice.current.isBatteryMonitoringEnabled = true

            // Register for battery notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(batteryLevelDidChange),
                name: UIDevice.batteryLevelDidChangeNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(batteryStateDidChange),
                name: UIDevice.batteryStateDidChangeNotification,
                object: nil
            )

            // Send initial battery state
            sendBatteryUpdate()
        #elseif os(macOS)
            // macOS: We could set up a timer to poll battery state periodically
            // For now, just send initial state
            sendBatteryUpdate()
        #endif

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        #if os(iOS)
            // Remove observers
            NotificationCenter.default.removeObserver(self, name: UIDevice.batteryLevelDidChangeNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIDevice.batteryStateDidChangeNotification, object: nil)
        #endif

        batteryEventSink = nil
        return nil
    }

    #if os(iOS)
        @objc private func batteryLevelDidChange() {
            sendBatteryUpdate()
        }

        @objc private func batteryStateDidChange() {
            sendBatteryUpdate()
        }
    #endif

    private func sendBatteryUpdate() {
        guard let eventSink = batteryEventSink else { return }

        #if os(iOS)
            let batteryLevel = UIDevice.current.batteryLevel
            if batteryLevel < 0 {
                // Battery state unknown - don't send update
                return
            }

            let batteryState = UIDevice.current.batteryState
            let isCharging = batteryState == .charging || batteryState == .full
            let percentage = Int(batteryLevel * 100)

            let batteryInfo: [String: Any] = [
                "percentage": percentage,
                "isCharging": isCharging
            ]
            eventSink(batteryInfo)
        #elseif os(macOS)
            let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
            let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

            guard let source = sources.first,
                  let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any],
                  let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int,
                  let maxCapacity = description[kIOPSMaxCapacityKey] as? Int,
                  maxCapacity > 0 else {
                // No battery or invalid data
                return
            }

            let percentage = (currentCapacity * 100) / maxCapacity
            let isCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false

            let batteryInfo: [String: Any] = [
                "percentage": percentage,
                "isCharging": isCharging
            ]
            eventSink(batteryInfo)
        #endif
    }
}
