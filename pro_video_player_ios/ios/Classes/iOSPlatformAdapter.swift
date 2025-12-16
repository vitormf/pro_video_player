import AVFoundation
import AVKit
import Flutter
import UIKit

/// iOS-specific implementation of the PlatformAdapter protocol.
/// Handles iOS-specific functionality like AVAudioSession, UIApplication notifications, etc.
class iOSPlatformAdapter: PlatformAdapter {
    private let registrar: FlutterPluginRegistrar
    private var isFullscreenMode: Bool = false

    var channelPrefix: String {
        return "dev.pro_video_player_ios"
    }

    var backgroundNotificationName: Notification.Name {
        return UIApplication.didEnterBackgroundNotification
    }

    var foregroundNotificationName: Notification.Name {
        return UIApplication.willEnterForegroundNotification
    }

    var isFullscreen: Bool {
        return isFullscreenMode
    }

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }

    func configureAudioSession(allowPip: Bool, allowBackgroundPlayback: Bool, mixWithOthers: Bool) {
        do {
            // Use .playback category when PiP is allowed or background playback is enabled
            // PiP won't work with .ambient category
            let needsPlaybackCategory = allowPip || allowBackgroundPlayback
            let category: AVAudioSession.Category = needsPlaybackCategory ? .playback : .ambient
            let sessionOptions: AVAudioSession.CategoryOptions = mixWithOthers ? .mixWithOthers : []
            try AVAudioSession.sharedInstance().setCategory(category, options: sessionOptions)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Log error but don't crash
            print("[iOSPlatformAdapter] Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    func lookupAssetPath(_ assetPath: String) -> String? {
        let key = registrar.lookupKey(forAsset: assetPath)
        return Bundle.main.path(forResource: key, ofType: nil)
    }

    func enterFullscreen(player: AVPlayer?, playerLayer: AVPlayerLayer?) -> Bool {
        guard !isFullscreenMode else { return true }

        isFullscreenMode = true

        // On iOS, fullscreen is typically handled by the Flutter layer
        // The native side just tracks the state and reports it
        // Actual fullscreen UI transition happens in Flutter

        return true
    }

    func exitFullscreen() {
        guard isFullscreenMode else { return }
        isFullscreenMode = false
    }

    func onPlayerLayerAttached(playerLayer: AVPlayerLayer?) {
        // No additional setup needed on iOS
    }

    func onPlayerViewControllerAttached(_ controller: Any, allowPip: Bool) {
        guard let playerVC = controller as? AVPlayerViewController else { return }

        // When using AVPlayerViewController, PiP is handled by the controller itself
        playerVC.allowsPictureInPicturePlayback = allowPip
    }

    func isPipSupported() -> Bool {
        if #available(iOS 14.0, *) {
            return AVPictureInPictureController.isPictureInPictureSupported()
        }
        return false
    }

    func createPipController(playerLayer: AVPlayerLayer) -> AVPictureInPictureController? {
        if #available(iOS 14.0, *) {
            if AVPictureInPictureController.isPictureInPictureSupported() {
                return AVPictureInPictureController(playerLayer: playerLayer)
            }
        }
        return nil
    }

    func setBackgroundPlayback(_ enabled: Bool) -> Bool {
        do {
            // Reconfigure audio session for background playback
            let category: AVAudioSession.Category = enabled ? .playback : .ambient
            try AVAudioSession.sharedInstance().setCategory(category)
            try AVAudioSession.sharedInstance().setActive(true)
            return true
        } catch {
            print("[iOSPlatformAdapter] Failed to configure audio session for background playback: \(error.localizedDescription)")
            return false
        }
    }

    func isBackgroundPlaybackSupported() -> Bool {
        // Background playback is supported on iOS if:
        // 1. The app has UIBackgroundModes with 'audio' in Info.plist
        // We can check this by looking at the Info.plist
        if let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] {
            return backgroundModes.contains("audio")
        }
        return false
    }
}
