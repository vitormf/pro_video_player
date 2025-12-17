import AVFoundation
import AVKit
import AppKit
import FlutterMacOS

/// macOS-specific implementation of the PlatformAdapter protocol.
/// Handles macOS-specific functionality like NSApplication notifications, fullscreen windows, etc.
class macOSPlatformAdapter: PlatformAdapter {
    private let registrar: FlutterPluginRegistrar
    private var isFullscreenMode: Bool = false
    private var fullscreenWindow: FullscreenWindow?
    private var fullscreenPlayerView: AVPlayerView?
    private weak var videoPlayer: SharedVideoPlayer?

    var channelPrefix: String {
        return "dev.pro_video_player_macos"
    }

    var backgroundNotificationName: Notification.Name {
        return NSApplication.didResignActiveNotification
    }

    var foregroundNotificationName: Notification.Name {
        return NSApplication.didBecomeActiveNotification
    }

    var isFullscreen: Bool {
        return isFullscreenMode
    }

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }

    /// Sets the video player reference for fullscreen exit handling.
    func setVideoPlayer(_ player: SharedVideoPlayer?) {
        self.videoPlayer = player
    }

    func configureAudioSession(allowPip: Bool, allowBackgroundPlayback: Bool, mixWithOthers: Bool) {
        // macOS doesn't have AVAudioSession like iOS
        // Audio configuration is handled differently on macOS
        // No action needed here
    }

    func lookupAssetPath(_ assetPath: String) -> String? {
        let key = registrar.lookupKey(forAsset: assetPath)
        return Bundle.main.path(forResource: key, ofType: nil)
    }

    func enterFullscreen(player: AVPlayer?, playerLayer: AVPlayerLayer?) -> Bool {
        guard !isFullscreenMode else { return true }
        guard let player = player else { return false }

        // Get the main screen
        guard let screen = NSScreen.main else {
            return false
        }

        // Create a fullscreen window
        let fullscreenRect = screen.frame
        let window = FullscreenWindow(
            contentRect: fullscreenRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.backgroundColor = .black
        window.collectionBehavior = [.fullScreenPrimary, .managed]
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // Set the exit handler for ESC key
        window.exitFullscreenHandler = { [weak self] in
            self?.exitFullscreen()
            self?.videoPlayer?.sendEvent(["type": "fullscreenStateChanged", "isFullscreen": false])
        }

        // Create AVPlayerView for fullscreen playback
        let playerView = AVPlayerView(frame: fullscreenRect)
        playerView.player = player
        playerView.controlsStyle = .floating
        playerView.showsFullScreenToggleButton = false
        playerView.autoresizingMask = [.width, .height]

        window.contentView = playerView

        // Store references
        fullscreenWindow = window
        fullscreenPlayerView = playerView

        // Show the window first
        window.makeKeyAndOrderFront(nil)

        // Observe fullscreen exit notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidExitFullScreen(_:)),
            name: NSWindow.didExitFullScreenNotification,
            object: window
        )

        // Enter native macOS fullscreen mode (hides menu bar and dock)
        window.toggleFullScreen(nil)
        isFullscreenMode = true

        return true
    }

    @objc private func windowDidExitFullScreen(_ notification: Notification) {
        // User exited fullscreen via macOS controls (green button)
        guard let window = notification.object as? NSWindow, window === fullscreenWindow else { return }
        exitFullscreen()
        videoPlayer?.sendEvent(["type": "fullscreenStateChanged", "isFullscreen": false])
    }

    func exitFullscreen() {
        guard isFullscreenMode else { return }

        isFullscreenMode = false

        // Remove observer
        if let window = fullscreenWindow {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didExitFullScreenNotification, object: window)

            // Exit native fullscreen if still in fullscreen mode
            if window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }

            window.orderOut(nil)
            window.close()
        }

        fullscreenWindow = nil
        fullscreenPlayerView = nil
    }

    func onPlayerLayerAttached(playerLayer: AVPlayerLayer?) {
        // Configure player layer for optimal rendering on macOS
        playerLayer?.backgroundColor = NSColor.clear.cgColor
    }

    func onPlayerViewControllerAttached(_ controller: Any, allowPip: Bool) {
        // On macOS, AVPlayerView handles PiP differently than iOS
        // Just ensure the controller is the right type, but no additional setup needed
        // PiP setup is done via AVPictureInPictureController separately
        guard controller is AVPlayerView else { return }
        // Note: allowPip is handled by the SharedVideoPlayer's PiP controller setup
    }

    func isPipSupported() -> Bool {
        // On macOS, AVPictureInPictureController.isPictureInPictureSupported() is unreliable
        // and often returns false even when PiP is available. Return true on macOS 10.15+.
        if #available(macOS 10.15, *) {
            return true
        }
        return false
    }

    func createPipController(playerLayer: AVPlayerLayer) -> AVPictureInPictureController? {
        // On macOS, just try to create the controller. The isPictureInPictureSupported() check
        // is unreliable and often returns false. If creation fails, we'll return nil.
        if #available(macOS 10.15, *) {
            return AVPictureInPictureController(playerLayer: playerLayer)
        }
        return nil
    }

    func setBackgroundPlayback(_ enabled: Bool) -> Bool {
        // macOS apps can play audio in background by default
        // No additional configuration needed
        return true
    }

    func isBackgroundPlaybackSupported() -> Bool {
        // Background playback is always supported on macOS
        return true
    }
}

// MARK: - Fullscreen Window

/// Custom window class to handle keyboard events for fullscreen mode.
class FullscreenWindow: NSWindow {
    var exitFullscreenHandler: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        // Handle ESC key to exit fullscreen
        if event.keyCode == 53 {  // ESC key
            exitFullscreenHandler?()
        } else {
            super.keyDown(with: event)
        }
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var acceptsFirstResponder: Bool {
        return true
    }
}
