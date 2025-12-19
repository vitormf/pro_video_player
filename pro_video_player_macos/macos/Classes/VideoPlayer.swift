import AVFoundation
import AVKit
import FlutterMacOS

/// Minimal macOS VideoPlayer - delegates everything to SharedVideoPlayerWrapper
class VideoPlayer: SharedVideoPlayerWrapper {
    init(playerId: Int, registrar: FlutterPluginRegistrar, source: [String: Any], options: [String: Any]) {
        let platformAdapter = macOSPlatformAdapter(registrar: registrar)

        super.init(
            playerId: playerId,
            registrar: registrar,
            eventChannelName: "dev.pro_video_player.pro_video_player_macos/events/\(playerId)",
            binaryMessenger: registrar.messenger,
            platformAdapter: platformAdapter,
            source: source,
            options: options
        )

        // Set the video player reference for fullscreen handling
        platformAdapter.setVideoPlayer(sharedPlayer)
    }
}
