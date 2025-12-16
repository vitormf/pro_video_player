import AVFoundation
import AVKit
import Foundation

// MARK: - Platform Adapter Protocol

/// Protocol defining platform-specific functionality that differs between iOS and macOS.
/// Implementations provide the platform-specific behavior while sharing common AVPlayer logic.
public protocol PlatformAdapter: AnyObject {
    /// The event channel name prefix for this platform (e.g., "dev.pro_video_player_ios")
    var channelPrefix: String { get }

    /// Configure audio session for the platform.
    /// - Parameters:
    ///   - allowPip: Whether PiP is allowed
    ///   - allowBackgroundPlayback: Whether background playback is allowed
    ///   - mixWithOthers: Whether to mix audio with other apps
    func configureAudioSession(allowPip: Bool, allowBackgroundPlayback: Bool, mixWithOthers: Bool)

    /// Look up an asset path for the platform's Flutter registrar.
    /// - Parameter assetPath: The asset path from Flutter
    /// - Returns: The resolved file path, or nil if not found
    func lookupAssetPath(_ assetPath: String) -> String?

    /// Get the background notification name for auto-PiP and wake lock management.
    /// iOS uses `UIApplication.didEnterBackgroundNotification`, macOS uses `NSApplication.didResignActiveNotification`
    var backgroundNotificationName: Notification.Name { get }

    /// Get the foreground notification name for wake lock management.
    /// iOS uses `UIApplication.willEnterForegroundNotification`, macOS uses `NSApplication.didBecomeActiveNotification`
    var foregroundNotificationName: Notification.Name { get }

    /// Enter fullscreen mode.
    /// - Parameter player: The AVPlayer instance
    /// - Returns: True if fullscreen was entered successfully
    func enterFullscreen(player: AVPlayer?, playerLayer: AVPlayerLayer?) -> Bool

    /// Exit fullscreen mode.
    func exitFullscreen()

    /// Whether the platform is currently in fullscreen mode.
    var isFullscreen: Bool { get }

    /// Called when the player layer is attached to a view hierarchy.
    /// Platform-specific setup can be done here (e.g., PiP controller on macOS).
    func onPlayerLayerAttached(playerLayer: AVPlayerLayer?)

    /// Called when an AVPlayerViewController/AVPlayerView is attached.
    /// - Parameters:
    ///   - controller: The view controller (AVPlayerViewController on iOS, AVPlayerView on macOS)
    ///   - allowPip: Whether PiP is allowed for this player
    func onPlayerViewControllerAttached(_ controller: Any, allowPip: Bool)

    /// Check PiP availability with platform-specific version requirements.
    /// - Returns: True if PiP is supported on this platform version
    func isPipSupported() -> Bool

    /// Create an AVPictureInPictureController if supported.
    /// - Parameter playerLayer: The player layer to use for PiP
    /// - Returns: The PiP controller, or nil if not supported
    func createPipController(playerLayer: AVPlayerLayer) -> AVPictureInPictureController?

    /// Set background playback enabled state at runtime.
    /// - Parameter enabled: Whether to enable or disable background playback
    /// - Returns: True if background playback was successfully configured
    func setBackgroundPlayback(_ enabled: Bool) -> Bool

    /// Check if background playback is supported on this platform.
    /// - Returns: True if background playback is supported
    func isBackgroundPlaybackSupported() -> Bool
}
