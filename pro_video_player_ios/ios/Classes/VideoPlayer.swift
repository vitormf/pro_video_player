import AVFoundation
import AVKit
import Flutter

/// Minimal iOS VideoPlayer - delegates everything to SharedVideoPlayerWrapper
class VideoPlayer: SharedVideoPlayerWrapper {
    init(
        playerId: Int, registrar: FlutterPluginRegistrar, source: [String: Any],
        options: [String: Any]
    ) {
        let platformAdapter = iOSPlatformAdapter(registrar: registrar)

        super.init(
            playerId: playerId,
            registrar: registrar,
            eventChannelName: "dev.pro_video_player_ios/events/\(playerId)",
            binaryMessenger: registrar.messenger(),
            platformAdapter: platformAdapter,
            source: source,
            options: options
        )
    }
}
