// Copyright 2025 The Pro Video Player Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

#if os(iOS)
    import Flutter
#elseif os(macOS)
    import FlutterMacOS
#endif

/// Handler class that implements the Pigeon-generated ProVideoPlayerHostApi protocol.
///
/// This class implements all platform methods using type-safe Pigeon-generated APIs,
/// providing bidirectional communication between Dart and native code.
class PigeonHostApiHandler: NSObject, ProVideoPlayerHostApi {
    private weak var sharedBase: SharedPluginBase?
    private let platformBehavior: PlatformPluginBehavior

    init(sharedBase: SharedPluginBase, platformBehavior: PlatformPluginBehavior) {
        self.sharedBase = sharedBase
        self.platformBehavior = platformBehavior
        super.init()
    }

    // MARK: - Core Playback Methods

    func create(
        source: VideoSourceMessage,
        options: VideoPlayerOptionsMessage,
        completion: @escaping (Result<Int64, Error>) -> Void
    ) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        // Convert Pigeon messages to dictionary format expected by SharedPluginBase
        let sourceDict = convertVideoSourceToDict(source)
        let optionsDict = convertPlayerOptionsToDict(options)

        // Create a fake FlutterMethodCall to delegate to existing implementation
        let args: [String: Any] = [
            "source": sourceDict,
            "options": optionsDict
        ]
        let call = FlutterMethodCall(methodName: "create", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let playerId = result as? Int {
                completion(.success(Int64(playerId)))
            } else {
                completion(.failure(PigeonError(code: "INVALID_RESULT", message: "Invalid result from create", details: nil)))
            }
        }
    }

    func dispose(playerId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "dispose", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    func play(playerId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        delegateVoidMethod(methodName: "play", playerId: playerId, completion: completion)
    }

    func pause(playerId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        delegateVoidMethod(methodName: "pause", playerId: playerId, completion: completion)
    }

    func stop(playerId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        delegateVoidMethod(methodName: "stop", playerId: playerId, completion: completion)
    }

    func seekTo(playerId: Int64, positionMs: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let args: [String: Any] = ["playerId": Int(playerId), "position": Int(positionMs)]
        let call = FlutterMethodCall(methodName: "seekTo", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    func setPlaybackSpeed(playerId: Int64, speed: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let args: [String: Any] = ["playerId": Int(playerId), "speed": speed]
        let call = FlutterMethodCall(methodName: "setPlaybackSpeed", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    func setVolume(playerId: Int64, volume: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let args: [String: Any] = ["playerId": Int(playerId), "volume": volume]
        let call = FlutterMethodCall(methodName: "setVolume", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    func getPosition(playerId: Int64, completion: @escaping (Result<Int64, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getPosition", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let position = result as? Int {
                completion(.success(Int64(position)))
            } else {
                completion(.failure(PigeonError(code: "INVALID_RESULT", message: "Invalid position result", details: nil)))
            }
        }
    }

    func getDuration(playerId: Int64, completion: @escaping (Result<Int64, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getDuration", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let duration = result as? Int {
                completion(.success(Int64(duration)))
            } else {
                completion(.failure(PigeonError(code: "INVALID_RESULT", message: "Invalid duration result", details: nil)))
            }
        }
    }

    func getPlatformCapabilities(completion: @escaping (Result<PlatformCapabilitiesMessage, Error>) -> Void) {
        #if os(iOS)
        let platformName = "iOS"
        #elseif os(macOS)
        let platformName = "macOS"
        #else
        let platformName = "Unknown"
        #endif

        let capabilities = PlatformCapabilitiesMessage(
            supportsPictureInPicture: platformBehavior.isPipSupported(),
            supportsFullscreen: true,
            supportsBackgroundPlayback: platformBehavior.isBackgroundPlaybackSupported(),
            supportsCasting: true,
            supportsAirPlay: true,
            supportsChromecast: false,
            supportsRemotePlayback: true,
            supportsQualitySelection: true,
            supportsPlaybackSpeedControl: true,
            supportsSubtitles: true,
            supportsExternalSubtitles: true,
            supportsAudioTrackSelection: true,
            supportsChapters: true,
            supportsVideoMetadataExtraction: true,
            supportsNetworkMonitoring: true,
            supportsBandwidthEstimation: true,
            supportsAdaptiveBitrate: true,
            supportsHLS: true,
            supportsDASH: false,
            supportsDeviceVolumeControl: true,
            supportsScreenBrightnessControl: true,
            platformName: platformName,
            nativePlayerType: "AVPlayer",
            additionalInfo: nil
        )
        completion(.success(capabilities))
    }

    func setVerboseLogging(enabled: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        VerboseLogger.shared.setEnabled(enabled)
        completion(.success(()))
    }

    // MARK: - Device Controls

    func getDeviceVolume(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getDeviceVolume", arguments: nil)
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let volume = result as? Double {
                completion(.success(volume))
            } else {
                completion(.failure(PigeonError(code: "INVALID_RESULT", message: "Invalid volume result", details: nil)))
            }
        }
    }

    func setDeviceVolume(volume: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "setDeviceVolume", arguments: ["volume": volume])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    func getScreenBrightness(completion: @escaping (Result<Double, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getScreenBrightness", arguments: nil)
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let brightness = result as? Double {
                completion(.success(brightness))
            } else {
                completion(.failure(PigeonError(code: "INVALID_RESULT", message: "Invalid brightness result", details: nil)))
            }
        }
    }

    func setScreenBrightness(brightness: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "setScreenBrightness", arguments: ["brightness": brightness])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    func getBatteryInfo(completion: @escaping (Result<BatteryInfoMessage?, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getBatteryInfo", arguments: nil)
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let batteryDict = result as? [String: Any] {
                let level = batteryDict["level"] as? Double ?? 0.0
                let percentage = Int64(level * 100)
                let isCharging = batteryDict["isCharging"] as? Bool ?? false
                let batteryInfo = BatteryInfoMessage(percentage: percentage, isCharging: isCharging)
                completion(.success(batteryInfo))
            } else {
                completion(.success(nil))
            }
        }
    }

    // MARK: - Player Configuration

    func setLooping(playerId: Int64, looping: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let args: [String: Any] = ["playerId": Int(playerId), "looping": looping]
        let call = FlutterMethodCall(methodName: "setLooping", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    func setScalingMode(playerId: Int64, mode: VideoScalingModeEnum, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let modeString = convertScalingModeToString(mode)
        let args: [String: Any] = ["playerId": Int(playerId), "scalingMode": modeString]
        let call = FlutterMethodCall(methodName: "setScalingMode", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    func setControlsMode(playerId: Int64, mode: ControlsModeEnum, completion: @escaping (Result<Void, Error>) -> Void) {
        // Controls mode is handled on the Dart side, no native implementation needed
        completion(.success(()))
    }

    // MARK: - Subtitle Management

    func setSubtitleTrack(playerId: Int64, track: SubtitleTrackMessage?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        var args: [String: Any] = ["playerId": Int(playerId)]
        if let track = track {
            args["track"] = [
                "id": track.id,
                "label": track.label as Any,
                "language": track.language as Any,
                "isDefault": track.isDefault as Any
            ]
        }

        let call = FlutterMethodCall(methodName: "setSubtitleTrack", arguments: args)
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    func setSubtitleRenderMode(playerId: Int64, mode: SubtitleRenderModeEnum, completion: @escaping (Result<Void, Error>) -> Void) {
        // Subtitle render mode is primarily handled on Dart side
        completion(.success(()))
    }

    func addExternalSubtitle(playerId: Int64, source: SubtitleSourceMessage, completion: @escaping (Result<ExternalSubtitleTrackMessage?, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        // Convert VideoSourceType enum to string
        let sourceTypeString: String
        switch source.type {
        case .network:
            sourceTypeString = "network"
        case .file:
            sourceTypeString = "file"
        case .asset:
            sourceTypeString = "asset"
        }

        // Convert optional format to string
        let formatString: String?
        if let format = source.format {
            formatString = convertSubtitleFormatToString(format)
        } else {
            formatString = nil
        }

        let args: [String: Any] = [
            "playerId": Int(playerId),
            "source": [
                "sourceType": sourceTypeString,
                "path": source.path,
                "format": formatString as Any,
                "label": source.label as Any,
                "language": source.language as Any,
                "isDefault": source.isDefault
            ]
        ]

        let call = FlutterMethodCall(methodName: "addExternalSubtitle", arguments: args)
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let trackDict = result as? [String: Any] {
                let track = ExternalSubtitleTrackMessage(
                    id: trackDict["id"] as? String ?? "",
                    label: trackDict["label"] as? String ?? "",
                    language: trackDict["language"] as? String,
                    isDefault: trackDict["isDefault"] as? Bool ?? false,
                    path: trackDict["path"] as? String ?? "",
                    sourceType: trackDict["sourceType"] as? String ?? "",
                    format: self.convertStringToSubtitleFormat(trackDict["format"] as? String ?? "vtt")
                )
                completion(.success(track))
            } else {
                completion(.success(nil))
            }
        }
    }

    func removeExternalSubtitle(playerId: Int64, trackId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let args: [String: Any] = ["playerId": Int(playerId), "trackId": trackId]
        let call = FlutterMethodCall(methodName: "removeExternalSubtitle", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let success = result as? Bool {
                completion(.success(success))
            } else {
                completion(.success(false))
            }
        }
    }

    func getExternalSubtitles(playerId: Int64, completion: @escaping (Result<[ExternalSubtitleTrackMessage?], Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getExternalSubtitles", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let tracksArray = result as? [[String: Any]] {
                let tracks = tracksArray.map { trackDict -> ExternalSubtitleTrackMessage in
                    ExternalSubtitleTrackMessage(
                        id: trackDict["id"] as? String ?? "",
                        label: trackDict["label"] as? String ?? "",
                        language: trackDict["language"] as? String,
                        isDefault: trackDict["isDefault"] as? Bool ?? false,
                        path: trackDict["path"] as? String ?? "",
                        sourceType: trackDict["sourceType"] as? String ?? "",
                        format: self.convertStringToSubtitleFormat(trackDict["format"] as? String ?? "vtt")
                    )
                }
                completion(.success(tracks))
            } else {
                completion(.success([]))
            }
        }
    }

    // MARK: - Audio Management

    func setAudioTrack(playerId: Int64, track: AudioTrackMessage?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        var args: [String: Any] = ["playerId": Int(playerId)]
        if let track = track {
            args["track"] = [
                "id": track.id,
                "label": track.label as Any,
                "language": track.language as Any,
                "isDefault": track.isDefault as Any
            ]
        }

        let call = FlutterMethodCall(methodName: "setAudioTrack", arguments: args)
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Picture-in-Picture

    func enterPip(playerId: Int64, options: PipOptionsMessage, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        var args: [String: Any] = ["playerId": Int(playerId)]
        if let aspectRatio = options.aspectRatio {
            args["aspectRatio"] = aspectRatio
        }
        args["autoEnterOnBackground"] = options.autoEnterOnBackground

        let call = FlutterMethodCall(methodName: "enterPip", arguments: args)
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let success = result as? Bool {
                completion(.success(success))
            } else {
                completion(.success(false))
            }
        }
    }

    func exitPip(playerId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        delegateVoidMethod(methodName: "exitPip", playerId: playerId, completion: completion)
    }

    func isPipSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
        let supported = platformBehavior.isPipSupported()
        verboseLog("Pigeon isPipSupported called, returning: \(supported)", tag: "PigeonHandler")
        completion(.success(supported))
    }

    func setPipActions(playerId: Int64, actions: [PipActionMessage?], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let actionsArray = actions.compactMap { action -> [String: Any]? in
            guard let action = action else { return nil }
            var dict: [String: Any] = ["type": convertPipActionTypeToString(action.type)]
            if let skipIntervalMs = action.skipIntervalMs {
                dict["skipIntervalMs"] = skipIntervalMs
            }
            return dict
        }

        let args: [String: Any] = ["playerId": Int(playerId), "actions": actionsArray]
        let call = FlutterMethodCall(methodName: "setPipActions", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Fullscreen

    func enterFullscreen(playerId: Int64, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "enterFullscreen", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let success = result as? Bool {
                completion(.success(success))
            } else {
                completion(.success(false))
            }
        }
    }

    func exitFullscreen(playerId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        delegateVoidMethod(methodName: "exitFullscreen", playerId: playerId, completion: completion)
    }

    func setWindowFullscreen(fullscreen: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "setWindowFullscreen", arguments: ["fullscreen": fullscreen])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Background Playback

    func setBackgroundPlayback(playerId: Int64, enabled: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let args: [String: Any] = ["playerId": Int(playerId), "enabled": enabled]
        let call = FlutterMethodCall(methodName: "setBackgroundPlayback", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let success = result as? Bool {
                completion(.success(success))
            } else {
                completion(.success(false))
            }
        }
    }

    func isBackgroundPlaybackSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(platformBehavior.isBackgroundPlaybackSupported()))
    }

    // MARK: - Quality Selection

    func getVideoQualities(playerId: Int64, completion: @escaping (Result<[VideoQualityTrackMessage?], Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getVideoQualities", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let qualitiesArray = result as? [[String: Any]] {
                let qualities = qualitiesArray.map { qualityDict -> VideoQualityTrackMessage in
                    VideoQualityTrackMessage(
                        id: qualityDict["id"] as? String ?? "",
                        label: qualityDict["label"] as? String,
                        bitrate: qualityDict["bitrate"] as? Int64,
                        width: qualityDict["width"] as? Int64,
                        height: qualityDict["height"] as? Int64,
                        codec: qualityDict["codec"] as? String,
                        isDefault: qualityDict["isDefault"] as? Bool
                    )
                }
                completion(.success(qualities))
            } else {
                completion(.success([]))
            }
        }
    }

    func setVideoQuality(playerId: Int64, track: VideoQualityTrackMessage, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        var trackDict: [String: Any] = [
            "id": track.id
        ]
        if let bitrate = track.bitrate {
            trackDict["bitrate"] = Int(bitrate)
        }
        if let width = track.width {
            trackDict["width"] = Int(width)
        }
        if let height = track.height {
            trackDict["height"] = Int(height)
        }
        if let label = track.label {
            trackDict["label"] = label
        }
        if let codec = track.codec {
            trackDict["codec"] = codec
        }
        if let isDefault = track.isDefault {
            trackDict["isDefault"] = isDefault
        }

        let args: [String: Any] = ["playerId": Int(playerId), "track": trackDict]
        let call = FlutterMethodCall(methodName: "setVideoQuality", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let success = result as? Bool {
                completion(.success(success))
            } else {
                completion(.success(false))
            }
        }
    }

    func getCurrentVideoQuality(playerId: Int64, completion: @escaping (Result<VideoQualityTrackMessage, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getCurrentVideoQuality", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let qualityDict = result as? [String: Any] {
                let quality = VideoQualityTrackMessage(
                    id: qualityDict["id"] as? String ?? "",
                    label: qualityDict["label"] as? String,
                    bitrate: qualityDict["bitrate"] as? Int64,
                    width: qualityDict["width"] as? Int64,
                    height: qualityDict["height"] as? Int64,
                    codec: qualityDict["codec"] as? String,
                    isDefault: qualityDict["isDefault"] as? Bool
                )
                completion(.success(quality))
            } else {
                completion(.failure(PigeonError(code: "NOT_FOUND", message: "Current quality not found", details: nil)))
            }
        }
    }

    func isQualitySelectionSupported(playerId: Int64, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "isQualitySelectionSupported", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let supported = result as? Bool {
                completion(.success(supported))
            } else {
                completion(.success(false))
            }
        }
    }

    // MARK: - Video Metadata

    func getVideoMetadata(playerId: Int64, completion: @escaping (Result<VideoMetadataMessage?, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getVideoMetadata", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let metadataDict = result as? [String: Any] {
                let metadata = VideoMetadataMessage(
                    duration: metadataDict["duration"] as? Int64,
                    width: metadataDict["width"] as? Int64,
                    height: metadataDict["height"] as? Int64,
                    videoCodec: metadataDict["videoCodec"] as? String,
                    audioCodec: metadataDict["audioCodec"] as? String,
                    bitrate: metadataDict["bitrate"] as? Int64,
                    frameRate: metadataDict["frameRate"] as? Double
                )
                completion(.success(metadata))
            } else {
                completion(.success(nil))
            }
        }
    }

    func setMediaMetadata(playerId: Int64, metadata: MediaMetadataMessage, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        var metadataDict: [String: Any] = [:]
        if let title = metadata.title {
            metadataDict["title"] = title
        }
        if let artist = metadata.artist {
            metadataDict["artist"] = artist
        }
        if let album = metadata.album {
            metadataDict["album"] = album
        }
        if let artworkUrl = metadata.artworkUrl {
            metadataDict["artworkUrl"] = artworkUrl
        }

        let args: [String: Any] = ["playerId": Int(playerId), "metadata": metadataDict]
        let call = FlutterMethodCall(methodName: "setMediaMetadata", arguments: args)

        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Casting

    func isCastingSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
        // AirPlay is always supported on iOS/macOS
        completion(.success(true))
    }

    func getAvailableCastDevices(playerId: Int64, completion: @escaping (Result<[CastDeviceMessage?], Error>) -> Void) {
        // AirPlay device discovery is handled by the system, not exposed programmatically
        completion(.success([]))
    }

    func startCasting(playerId: Int64, device: CastDeviceMessage?, completion: @escaping (Result<Bool, Error>) -> Void) {
        // AirPlay casting is initiated through the route picker UI, not programmatically
        completion(.success(false))
    }

    func stopCasting(playerId: Int64, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "stopCasting", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let success = result as? Bool {
                completion(.success(success))
            } else {
                completion(.success(false))
            }
        }
    }

    func getCastState(playerId: Int64, completion: @escaping (Result<CastStateEnum, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getCastState", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let stateString = result as? String {
                let state = self.convertStringToCastState(stateString)
                completion(.success(state))
            } else {
                completion(.success(.notConnected))
            }
        }
    }

    func getCurrentCastDevice(playerId: Int64, completion: @escaping (Result<CastDeviceMessage?, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: "getCurrentCastDevice", arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else if let deviceDict = result as? [String: Any] {
                let device = CastDeviceMessage(
                    id: deviceDict["id"] as? String ?? "",
                    name: deviceDict["name"] as? String ?? "",
                    type: self.convertStringToCastDeviceType(deviceDict["type"] as? String ?? "unknown")
                )
                completion(.success(device))
            } else {
                completion(.success(nil))
            }
        }
    }

    // MARK: - Helper Methods

    /// Helper method to delegate simple void methods with only playerId
    private func delegateVoidMethod(methodName: String, playerId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sharedBase = sharedBase else {
            completion(.failure(PigeonError(code: "NO_PLUGIN", message: "Plugin not initialized", details: nil)))
            return
        }

        let call = FlutterMethodCall(methodName: methodName, arguments: ["playerId": Int(playerId)])
        sharedBase.handle(call) { result in
            if let error = result as? FlutterError {
                completion(.failure(PigeonError(code: error.code, message: error.message, details: error.details)))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Conversion Methods

    private func convertVideoSourceToDict(_ source: VideoSourceMessage) -> [String: Any] {
        var dict: [String: Any] = [:]

        switch source.type {
        case .network:
            dict["type"] = "network"
            if let url = source.url {
                dict["url"] = url
            }
            if let headers = source.headers {
                dict["headers"] = headers.compactMapValues { $0 }
            }
        case .file:
            dict["type"] = "file"
            if let path = source.path {
                dict["path"] = path
            }
        case .asset:
            dict["type"] = "asset"
            if let assetPath = source.assetPath {
                dict["assetPath"] = assetPath
            }
        }

        return dict
    }

    private func convertPlayerOptionsToDict(_ options: VideoPlayerOptionsMessage) -> [String: Any] {
        return [
            "autoPlay": options.autoPlay,
            "looping": options.looping,
            "volume": options.volume,
            "playbackSpeed": options.playbackSpeed,
            "allowBackgroundPlayback": options.allowBackgroundPlayback,
            "mixWithOthers": options.mixWithOthers,
            "allowPip": options.allowPip,
            "autoEnterPipOnBackground": options.autoEnterPipOnBackground
        ]
    }

    private func convertScalingModeToString(_ mode: VideoScalingModeEnum) -> String {
        switch mode {
        case .fit:
            return "fit"
        case .fill:
            return "fill"
        case .stretch:
            return "stretch"
        }
    }

    private func convertSubtitleFormatToString(_ format: SubtitleFormatEnum) -> String {
        switch format {
        case .srt:
            return "srt"
        case .vtt:
            return "vtt"
        case .ssa:
            return "ssa"
        case .ass:
            return "ass"
        case .ttml:
            return "ttml"
        }
    }

    private func convertStringToSubtitleFormat(_ string: String) -> SubtitleFormatEnum {
        switch string.lowercased() {
        case "srt":
            return .srt
        case "vtt":
            return .vtt
        case "ssa":
            return .ssa
        case "ass":
            return .ass
        case "ttml":
            return .ttml
        default:
            return .vtt
        }
    }

    private func convertPipActionTypeToString(_ type: PipActionTypeEnum) -> String {
        switch type {
        case .playPause:
            return "playPause"
        case .skipPrevious:
            return "skipPrevious"
        case .skipNext:
            return "skipNext"
        case .skipBackward:
            return "skipBackward"
        case .skipForward:
            return "skipForward"
        }
    }

    private func convertStringToCastState(_ string: String) -> CastStateEnum {
        switch string.lowercased() {
        case "connected":
            return .connected
        case "connecting":
            return .connecting
        case "disconnecting":
            return .disconnecting
        default:
            return .notConnected
        }
    }

    private func convertStringToCastDeviceType(_ string: String) -> CastDeviceTypeEnum {
        switch string.lowercased() {
        case "airplay":
            return .airPlay
        case "chromecast":
            return .chromecast
        case "webremoteplayback":
            return .webRemotePlayback
        default:
            return .unknown
        }
    }
}
