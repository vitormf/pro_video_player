import AVFoundation
import AVKit
import Foundation

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
#endif

/// Shared video player wrapper that handles all common Flutter bridging logic.
/// This eliminates duplication between iOS and macOS VideoPlayer classes.
open class SharedVideoPlayerWrapper: NSObject {
    let playerId: Int
    let registrar: Any
    let eventChannel: FlutterEventChannel
    var eventSink: FlutterEventSink?
    
    let sharedPlayer: SharedVideoPlayer
    let platformAdapter: PlatformAdapter
    
    public init(
        playerId: Int,
        registrar: Any,
        eventChannelName: String,
        binaryMessenger: Any,
        platformAdapter: PlatformAdapter,
        source: [String: Any],
        options: [String: Any]
    ) {
        self.playerId = playerId
        self.registrar = registrar
        
        #if os(iOS)
        self.eventChannel = FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: binaryMessenger as! FlutterBinaryMessenger
        )
        #elseif os(macOS)
        self.eventChannel = FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: binaryMessenger as! FlutterBinaryMessenger
        )
        #endif
        
        self.platformAdapter = platformAdapter
        self.sharedPlayer = SharedVideoPlayer(
            playerId: playerId,
            platformAdapter: platformAdapter,
            source: source,
            options: options
        )
        
        super.init()
        
        eventChannel.setStreamHandler(self)
        sharedPlayer.eventSink = self
    }
    
    // MARK: - Public API (delegates to SharedVideoPlayer)
    
    public func getPlayerLayer() -> AVPlayerLayer? {
        return sharedPlayer.getPlayerLayer()
    }
    
    public func getAVPlayer() -> AVPlayer? {
        return sharedPlayer.getAVPlayer()
    }
    
    public func onPlayerLayerAttachedToView() {
        sharedPlayer.onPlayerLayerAttachedToView()
    }
    
    #if os(iOS)
    public func onPlayerViewControllerAttached(_ playerVC: AVPlayerViewController) {
        sharedPlayer.onPlayerViewControllerAttached(playerVC)
    }
    #elseif os(macOS)
    public func onPlayerViewControllerAttached(_ playerView: AVPlayerView) {
        sharedPlayer.onPlayerViewControllerAttached(playerView)
    }
    #endif
    
    public func play() {
        sharedPlayer.play()
    }
    
    public func pause() {
        sharedPlayer.pause()
    }
    
    public func stop() {
        sharedPlayer.stop()
    }
    
    public func seekTo(milliseconds: Int) {
        sharedPlayer.seekTo(milliseconds: milliseconds)
    }
    
    public func setPlaybackSpeed(_ speed: Float) {
        sharedPlayer.setPlaybackSpeed(speed)
    }
    
    public func setVolume(_ volume: Float) {
        sharedPlayer.setVolume(volume)
    }
    
    public func setLooping(_ looping: Bool) {
        sharedPlayer.setLooping(looping)
    }
    
    public func setScalingMode(_ mode: String) {
        sharedPlayer.setScalingMode(mode)
    }
    
    public func setSubtitleTrack(_ track: [String: Any]?) {
        sharedPlayer.setSubtitleTrack(track)
    }
    
    public func setAudioTrack(_ track: [String: Any]?) {
        sharedPlayer.setAudioTrack(track)
    }
    
    public func getPosition() -> Int {
        return sharedPlayer.getPosition()
    }
    
    public func getDuration() -> Int {
        return sharedPlayer.getDuration()
    }
    
    public func enterPip() -> Bool {
        return sharedPlayer.enterPip()
    }
    
    public func exitPip() {
        sharedPlayer.exitPip()
    }
    
    #if os(iOS)
    public func setPipActions(_ actions: [[String: Any]]?) {
        sharedPlayer.setPipActions(actions)
    }
    #endif
    
    public func enterFullscreen() -> Bool {
        return sharedPlayer.enterFullscreen()
    }
    
    public func exitFullscreen() {
        sharedPlayer.exitFullscreen()
    }
    
    public func setMediaMetadata(_ metadata: [String: Any]) {
        sharedPlayer.setMediaMetadata(metadata)
    }
    
    public func getVideoQualities() -> [[String: Any]] {
        return sharedPlayer.getVideoQualities()
    }
    
    public func setVideoQuality(_ quality: [String: Any]?) -> Bool {
        return sharedPlayer.setVideoQuality(quality)
    }
    
    public func getCurrentVideoQuality() -> [String: Any]? {
        return sharedPlayer.getCurrentVideoQuality()
    }
    
    public func isQualitySelectionSupported() -> Bool {
        return sharedPlayer.isQualitySelectionSupported()
    }
    
    public func setBackgroundPlayback(_ enabled: Bool) -> Bool {
        return sharedPlayer.setBackgroundPlayback(enabled)
    }
    
    public func dispose() {
        sharedPlayer.dispose()
        eventChannel.setStreamHandler(nil)
        eventSink = nil
    }
}

// MARK: - FlutterStreamHandler
extension SharedVideoPlayerWrapper: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
        -> FlutterError?
    {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - EventSink
extension SharedVideoPlayerWrapper: EventSink {
    public func send(_ event: [String: Any]) {
        eventSink?(event)
    }
}
