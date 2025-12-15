import AVFoundation
import AVKit
import Foundation

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
#endif

/// Protocol for views that can change controls mode at runtime
protocol ControlsModeUpdatable: AnyObject {
    func setControlsMode(_ mode: ControlsMode)
}

/// Registry to store views by player ID for runtime controls mode updates
class VideoPlayerViewRegistry {
    static let shared = VideoPlayerViewRegistry()

    private var views: [Int: ControlsModeUpdatable] = [:]
    private let lock = NSLock()

    private init() {}

    func register(_ view: ControlsModeUpdatable, for playerId: Int) {
        lock.lock()
        defer { lock.unlock() }
        views[playerId] = view
    }

    func unregister(for playerId: Int) {
        lock.lock()
        defer { lock.unlock() }
        views.removeValue(forKey: playerId)
    }

    func setControlsMode(for playerId: Int, mode: ControlsMode) {
        lock.lock()
        let view = views[playerId]
        lock.unlock()
        view?.setControlsMode(mode)
    }
}

/// Shared factory base that creates platform views for video players.
/// Eliminates duplication between iOS and macOS view factory implementations.
open class SharedVideoPlayerViewFactory: NSObject {
    weak var pluginBase: SharedPluginBase?
    let config: PlatformConfig

    public init(pluginBase: SharedPluginBase, config: PlatformConfig) {
        self.pluginBase = pluginBase
        self.config = config
        super.init()
    }

    /// Gets player and creates view with parsed arguments
    func createViewWithPlayer(
        frame: CGRect,
        arguments: [String: Any]?
    ) -> (playerLayer: AVPlayerLayer?, videoPlayer: SharedVideoPlayerWrapper?, controlsMode: ControlsMode) {
        guard let arguments = arguments,
              let playerId = arguments["playerId"] as? Int,
              let player = pluginBase?.getPlayer(for: playerId) else {
            return (nil, nil, .none)
        }

        let controlsModeString = arguments["controlsMode"] as? String ?? "none"
        let controlsMode = ControlsMode(rawValue: controlsModeString) ?? .none

        return (player.getPlayerLayer(), player, controlsMode)
    }
}

#if os(iOS)
/// iOS-specific view factory implementation
open class SharediOSVideoPlayerViewFactory: SharedVideoPlayerViewFactory, FlutterPlatformViewFactory {
    public func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let arguments = args as? [String: Any]
        let playerId = arguments?["playerId"] as? Int ?? -1
        let (playerLayer, videoPlayer, controlsMode) = createViewWithPlayer(
            frame: frame,
            arguments: arguments
        )

        let view = iOSVideoPlayerView(
            frame: frame,
            playerId: playerId,
            playerLayer: playerLayer,
            videoPlayer: videoPlayer,
            controlsMode: controlsMode
        )

        // Register view for runtime controls mode updates
        if playerId >= 0 {
            VideoPlayerViewRegistry.shared.register(view, for: playerId)
        }

        return view
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Custom UIView that handles layer layout for video player.
/// Ensures player layer and player view controller frames are updated on layout changes.
class PlayerContainerView: UIView {
    var playerLayer: AVPlayerLayer?
    var playerViewController: AVPlayerViewController?

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
        playerViewController?.view.frame = bounds
    }
}

/// iOS platform view with runtime controls mode switching support
class iOSVideoPlayerView: NSObject, FlutterPlatformView, ControlsModeUpdatable {
    private let containerView: PlayerContainerView
    private let playerId: Int
    private var playerLayer: AVPlayerLayer?
    private weak var videoPlayer: SharedVideoPlayerWrapper?
    private var controlsMode: ControlsMode
    private var playerViewController: AVPlayerViewController?

    init(
        frame: CGRect,
        playerId: Int,
        playerLayer: AVPlayerLayer?,
        videoPlayer: SharedVideoPlayerWrapper?,
        controlsMode: ControlsMode
    ) {
        self.containerView = PlayerContainerView(frame: frame)
        self.playerId = playerId
        self.playerLayer = playerLayer
        self.videoPlayer = videoPlayer
        self.controlsMode = controlsMode
        super.init()

        setupView()
    }

    deinit {
        // Unregister from the view registry when the view is deallocated
        if playerId >= 0 {
            VideoPlayerViewRegistry.shared.unregister(for: playerId)
        }
    }

    private func setupView() {
        containerView.backgroundColor = .black
        applyControlsMode()
        videoPlayer?.onPlayerLayerAttachedToView()
    }

    /// Applies the current controls mode to the view
    private func applyControlsMode() {
        guard playerLayer != nil else { return }

        switch controlsMode {
        case .native:
            setupNativeControls()
        case .none, .custom:
            setupLayerOnly()
        }
    }

    /// Clears current controls before switching modes
    private func clearCurrentControls() {
        // Remove AVPlayerViewController if present
        if let playerVC = playerViewController {
            playerVC.view.removeFromSuperview()
            containerView.playerViewController = nil
            self.playerViewController = nil
        }

        // Remove player layer if it was added as sublayer
        if let layer = playerLayer, layer.superlayer == containerView.layer {
            layer.removeFromSuperlayer()
            containerView.playerLayer = nil
        }
    }

    private func setupNativeControls() {
        guard let player = videoPlayer?.getAVPlayer() else { return }

        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.view.frame = containerView.bounds
        playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        containerView.addSubview(playerVC.view)
        containerView.playerViewController = playerVC
        self.playerViewController = playerVC

        videoPlayer?.onPlayerViewControllerAttached(playerVC)
    }

    private func setupLayerOnly() {
        guard let playerLayer = playerLayer else { return }

        playerLayer.frame = containerView.bounds
        playerLayer.videoGravity = .resizeAspect
        containerView.layer.addSublayer(playerLayer)
        containerView.playerLayer = playerLayer
    }

    // MARK: - ControlsModeUpdatable

    func setControlsMode(_ mode: ControlsMode) {
        guard mode != controlsMode else { return }

        clearCurrentControls()
        controlsMode = mode
        applyControlsMode()
    }

    func view() -> UIView {
        return containerView
    }
}

#elseif os(macOS)

/// macOS-specific view factory implementation
open class SharedmacOSVideoPlayerViewFactory: SharedVideoPlayerViewFactory, FlutterPlatformViewFactory {
    public func create(
        withViewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> NSView {
        let arguments = args as? [String: Any]
        let playerId = arguments?["playerId"] as? Int ?? -1
        let (playerLayer, videoPlayer, controlsMode) = createViewWithPlayer(
            frame: .zero,
            arguments: arguments
        )

        let view = macOSVideoPlayerView(
            frame: .zero,
            playerId: playerId,
            playerLayer: playerLayer,
            videoPlayer: videoPlayer,
            controlsMode: controlsMode
        )

        // Register view for runtime controls mode updates
        if playerId >= 0 {
            VideoPlayerViewRegistry.shared.register(view, for: playerId)
        }

        return view
    }

    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// macOS platform view with runtime controls mode switching support
class macOSVideoPlayerView: NSView, ControlsModeUpdatable {
    private let playerId: Int
    private var playerLayer: AVPlayerLayer?
    private weak var videoPlayer: SharedVideoPlayerWrapper?
    private var controlsMode: ControlsMode
    private var playerView: AVPlayerView?

    init(
        frame: CGRect,
        playerId: Int,
        playerLayer: AVPlayerLayer?,
        videoPlayer: SharedVideoPlayerWrapper?,
        controlsMode: ControlsMode
    ) {
        self.playerId = playerId
        self.videoPlayer = videoPlayer
        self.controlsMode = controlsMode
        super.init(frame: frame)

        // Create our own AVPlayerLayer to avoid sharing issues
        // When multiple views share the same layer, disposing one view breaks the other
        if let player = videoPlayer?.getAVPlayer() {
            self.playerLayer = AVPlayerLayer(player: player)
        } else {
            self.playerLayer = playerLayer
        }

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Unregister from the view registry when the view is deallocated
        if playerId >= 0 {
            VideoPlayerViewRegistry.shared.unregister(for: playerId)
        }
    }

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        applyControlsMode()
        videoPlayer?.onPlayerLayerAttachedToView()
    }

    /// Applies the current controls mode to the view
    private func applyControlsMode() {
        guard playerLayer != nil else { return }

        switch controlsMode {
        case .native:
            setupNativeControls()
        case .none, .custom:
            setupLayerOnly()
        }
    }

    /// Clears current controls before switching modes
    private func clearCurrentControls() {
        // Remove AVPlayerView if present
        if let pv = playerView {
            pv.removeFromSuperview()
            self.playerView = nil
        }

        // Remove player layer if it was added as sublayer
        if let pl = playerLayer, pl.superlayer == layer {
            pl.removeFromSuperlayer()
        }
    }

    /// Sets the controls mode at runtime
    func setControlsMode(_ mode: ControlsMode) {
        guard mode != controlsMode else { return }

        clearCurrentControls()
        controlsMode = mode
        applyControlsMode()
    }

    private func setupNativeControls() {
        guard let player = videoPlayer?.getAVPlayer() else { return }

        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .default
        playerView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: topAnchor),
            playerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        self.playerView = playerView
        videoPlayer?.onPlayerViewControllerAttached(playerView)
    }

    private func setupLayerOnly() {
        guard let playerLayer = playerLayer else { return }

        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspect
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer?.addSublayer(playerLayer)
    }

    override func layout() {
        super.layout()

        if controlsMode != .native, let playerLayer = playerLayer {
            playerLayer.frame = bounds
        }
    }
}

#endif
