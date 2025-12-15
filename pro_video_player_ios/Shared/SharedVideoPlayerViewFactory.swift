import AVFoundation
import AVKit
import Foundation

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
#endif

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
        let (playerLayer, videoPlayer, controlsMode) = createViewWithPlayer(
            frame: frame,
            arguments: args as? [String: Any]
        )
        
        return iOSVideoPlayerView(
            frame: frame,
            playerLayer: playerLayer,
            videoPlayer: videoPlayer,
            controlsMode: controlsMode
        )
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// iOS platform view
class iOSVideoPlayerView: NSObject, FlutterPlatformView {
    private let containerView: UIView
    private var playerLayer: AVPlayerLayer?
    private weak var videoPlayer: SharedVideoPlayerWrapper?
    private let controlsMode: ControlsMode
    private var playerViewController: AVPlayerViewController?
    
    init(frame: CGRect, playerLayer: AVPlayerLayer?, videoPlayer: SharedVideoPlayerWrapper?, controlsMode: ControlsMode) {
        self.containerView = UIView(frame: frame)
        self.playerLayer = playerLayer
        self.videoPlayer = videoPlayer
        self.controlsMode = controlsMode
        super.init()
        
        setupView()
    }
    
    private func setupView() {
        containerView.backgroundColor = .black
        
        guard let playerLayer = playerLayer else { return }
        
        switch controlsMode {
        case .native:
            setupNativeControls()
        case .none, .custom:
            setupLayerOnly()
        }
        
        videoPlayer?.onPlayerLayerAttachedToView()
    }
    
    private func setupNativeControls() {
        guard let player = videoPlayer?.getAVPlayer() else { return }
        
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.view.frame = containerView.bounds
        playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        containerView.addSubview(playerVC.view)
        self.playerViewController = playerVC
        
        videoPlayer?.onPlayerViewControllerAttached(playerVC)
    }
    
    private func setupLayerOnly() {
        guard let playerLayer = playerLayer else { return }
        
        playerLayer.frame = containerView.bounds
        playerLayer.videoGravity = .resizeAspect
        containerView.layer.addSublayer(playerLayer)
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
        let (playerLayer, videoPlayer, controlsMode) = createViewWithPlayer(
            frame: .zero,
            arguments: args as? [String: Any]
        )
        
        return macOSVideoPlayerView(
            frame: .zero,
            playerLayer: playerLayer,
            videoPlayer: videoPlayer,
            controlsMode: controlsMode
        )
    }
    
    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// macOS platform view
class macOSVideoPlayerView: NSView {
    private var playerLayer: AVPlayerLayer?
    private weak var videoPlayer: SharedVideoPlayerWrapper?
    private let controlsMode: ControlsMode
    private var playerView: AVPlayerView?
    
    init(frame: CGRect, playerLayer: AVPlayerLayer?, videoPlayer: SharedVideoPlayerWrapper?, controlsMode: ControlsMode) {
        self.playerLayer = playerLayer
        self.videoPlayer = videoPlayer
        self.controlsMode = controlsMode
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        
        guard let playerLayer = playerLayer else { return }
        
        switch controlsMode {
        case .native:
            setupNativeControls()
        case .none, .custom:
            setupLayerOnly()
        }
        
        videoPlayer?.onPlayerLayerAttachedToView()
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
