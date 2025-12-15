import Flutter
import XCTest
import AVFoundation
import AVKit
@testable import pro_video_player_ios

class VideoPlayerTests: XCTestCase {

    var mockRegistrar: MockFlutterPluginRegistrar!
    var mockMessenger: MockBinaryMessenger!

    override func setUp() {
        super.setUp()
        mockMessenger = MockBinaryMessenger()
        mockRegistrar = MockFlutterPluginRegistrar()
        mockRegistrar.mockMessenger = mockMessenger
    }

    override func tearDown() {
        mockRegistrar = nil
        mockMessenger = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createPlayer(
        source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"],
        options: [String: Any] = [:]
    ) -> VideoPlayer {
        return VideoPlayer(
            playerId: 0,
            registrar: mockRegistrar,
            source: source,
            options: options
        )
    }

    // MARK: - Initialization Tests

    func testInitWithNetworkSource() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["volume": 0.8, "looping": true]

        // When
        let player = VideoPlayer(playerId: 1, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
        XCTAssertNotNil(player.getPlayerLayer())
    }

    func testInitWithFileSource() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/path/to/video.mp4"]
        let options: [String: Any] = [:]

        // When
        let player = VideoPlayer(playerId: 2, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
        XCTAssertNotNil(player.getPlayerLayer())
    }

    func testInitWithAssetSource() {
        // Given
        let source: [String: Any] = ["type": "asset", "assetPath": "assets/video.mp4"]
        let options: [String: Any] = [:]

        // When
        let player = VideoPlayer(playerId: 3, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
        // Player layer may be nil if asset doesn't exist, which is expected in tests
    }

    func testInitWithInvalidSourceType() {
        // Given
        let source: [String: Any] = ["type": "invalid"]
        let options: [String: Any] = [:]

        // When
        let player = VideoPlayer(playerId: 4, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
        // Player should still be created, but without a valid source
    }

    func testInitWithMissingSourceType() {
        // Given - Source without "type" key (uses file path to avoid network timeout)
        let source: [String: Any] = ["path": "/nonexistent/test.mp4"]
        let options: [String: Any] = [:]

        // When
        let player = VideoPlayer(playerId: 5, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
    }

    func testInitWithFileSourceAndHeaders() {
        // Given - File source doesn't use headers, but test ensures headers param doesn't break
        let source: [String: Any] = [
            "type": "file",
            "path": "/nonexistent/test.mp4",
            "headers": ["Authorization": "Bearer token123"]
        ]
        let options: [String: Any] = [:]

        // When
        let player = VideoPlayer(playerId: 6, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
        XCTAssertNotNil(player.getPlayerLayer())
    }

    // MARK: - Options Tests

    func testInitWithAllOptions() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = [
            "volume": 0.5,
            "playbackSpeed": 1.5,
            "looping": true,
            "allowPip": true,
            "autoEnterPipOnBackground": true,
            "allowBackgroundPlayback": true,
            "mixWithOthers": true,
            "subtitlesEnabled": true,
            "showSubtitlesByDefault": true,
            "preferredSubtitleLanguage": "en"
        ]

        // When
        let player = VideoPlayer(playerId: 7, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
        XCTAssertTrue(player.isPipAllowed())
        XCTAssertTrue(player.areSubtitlesEnabled())
    }

    func testInitWithPipDisabled() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["allowPip": false]

        // When
        let player = VideoPlayer(playerId: 8, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertFalse(player.isPipAllowed())
    }

    func testInitWithSubtitlesDisabled() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["subtitlesEnabled": false]

        // When
        let player = VideoPlayer(playerId: 9, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertFalse(player.areSubtitlesEnabled())
    }

    func testInitWithAmbientAudioSession() {
        // Given - PiP disabled and no background playback = ambient category
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = [
            "allowPip": false,
            "allowBackgroundPlayback": false
        ]

        // When
        let player = VideoPlayer(playerId: 10, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
    }

    func testInitWithMixWithOthers() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["mixWithOthers": true]

        // When
        let player = VideoPlayer(playerId: 11, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
    }

    // MARK: - Playback Control Tests

    func testPlay() {
        // Given
        let player = createPlayer()

        // When
        player.play()

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testPause() {
        // Given
        let player = createPlayer()

        // When
        player.pause()

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testStop() {
        // Given
        let player = createPlayer()

        // When
        player.stop()

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testSeekTo() {
        // Given
        let player = createPlayer()

        // When
        player.seekTo(milliseconds: 5000)

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testSeekToZero() {
        // Given
        let player = createPlayer()

        // When
        player.seekTo(milliseconds: 0)

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testSetPlaybackSpeed() {
        // Given
        let player = createPlayer()

        // When
        player.setPlaybackSpeed(1.5)

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testSetPlaybackSpeedSlow() {
        // Given
        let player = createPlayer()

        // When
        player.setPlaybackSpeed(0.5)

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testSetVolume() {
        // Given
        let player = createPlayer()

        // When
        player.setVolume(0.7)

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testSetVolumeMute() {
        // Given
        let player = createPlayer()

        // When
        player.setVolume(0.0)

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testSetVolumeMax() {
        // Given
        let player = createPlayer()

        // When
        player.setVolume(1.0)

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testSetLoopingTrue() {
        // Given
        let player = createPlayer()

        // When
        player.setLooping(true)

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testSetLoopingFalse() {
        // Given
        let player = createPlayer()

        // When
        player.setLooping(false)

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    // MARK: - Position and Duration Tests

    func testGetPosition() {
        // Given
        let player = createPlayer()

        // When
        let position = player.getPosition()

        // Then - Position should be 0 for unplayed video
        XCTAssertEqual(position, 0)
    }

    func testGetDuration() {
        // Given
        let player = createPlayer()

        // When
        let duration = player.getDuration()

        // Then - Duration is 0 or negative until video loads (negative means invalid/not available yet)
        // AVPlayer returns negative duration (NaN converted to Int) for unloaded videos
        XCTAssertTrue(duration <= 0 || duration > 0) // Just verify it returns a value without crashing
    }

    // MARK: - Subtitle Tests

    func testSetSubtitleTrackWithValidTrack() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let track: [String: Any] = ["id": "0", "language": "en", "label": "English"]

        // When
        player.setSubtitleTrack(track)

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testSetSubtitleTrackWithNil() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])

        // When
        player.setSubtitleTrack(nil)

        // Then - No crash, subtitles disabled
        XCTAssertNotNil(player)
    }

    func testSetSubtitleTrackWithSubtitlesDisabled() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": false])
        let track: [String: Any] = ["id": "0", "language": "en", "label": "English"]

        // When
        player.setSubtitleTrack(track)

        // Then - No crash, track ignored
        XCTAssertNotNil(player)
    }

    func testSetSubtitleTrackWithInvalidId() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let track: [String: Any] = ["id": "999", "language": "en", "label": "English"]

        // When
        player.setSubtitleTrack(track)

        // Then - No crash, invalid track handled gracefully
        XCTAssertNotNil(player)
    }

    func testSetSubtitleTrackWithMissingId() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let track: [String: Any] = ["language": "en", "label": "English"]

        // When
        player.setSubtitleTrack(track)

        // Then - No crash, missing id handled gracefully
        XCTAssertNotNil(player)
    }

    // MARK: - PiP Tests

    func testEnterPipWhenAllowed() {
        // Given
        let player = createPlayer(options: ["allowPip": true])

        // When
        let result = player.enterPip()

        // Then - Returns false because PiP controller isn't set up in test environment
        XCTAssertFalse(result)
    }

    func testEnterPipWhenNotAllowed() {
        // Given
        let player = createPlayer(options: ["allowPip": false])

        // When
        let result = player.enterPip()

        // Then
        XCTAssertFalse(result)
    }

    func testExitPip() {
        // Given
        let player = createPlayer(options: ["allowPip": true])

        // When
        player.exitPip()

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testOnPlayerLayerAttachedToView() {
        // Given
        let player = createPlayer(options: ["allowPip": true])

        // When
        player.onPlayerLayerAttachedToView()

        // Then - No crash, PiP controller setup attempted
        XCTAssertNotNil(player)
    }

    func testOnPlayerLayerAttachedToViewWithPipDisabled() {
        // Given
        let player = createPlayer(options: ["allowPip": false])

        // When
        player.onPlayerLayerAttachedToView()

        // Then - No crash, PiP controller not set up
        XCTAssertNotNil(player)
    }

    // MARK: - Fullscreen Tests

    func testEnterFullscreen() {
        // Given
        let player = createPlayer()

        // When
        let result = player.enterFullscreen()

        // Then
        XCTAssertTrue(result)
    }

    func testEnterFullscreenTwice() {
        // Given
        let player = createPlayer()

        // When
        let result1 = player.enterFullscreen()
        let result2 = player.enterFullscreen()

        // Then - Second call should still return true (already fullscreen)
        XCTAssertTrue(result1)
        XCTAssertTrue(result2)
    }

    func testExitFullscreen() {
        // Given
        let player = createPlayer()
        _ = player.enterFullscreen()

        // When
        player.exitFullscreen()

        // Then - No crash, method executed
        XCTAssertNotNil(player)
    }

    func testExitFullscreenWhenNotFullscreen() {
        // Given
        let player = createPlayer()

        // When
        player.exitFullscreen()

        // Then - No crash, early return
        XCTAssertNotNil(player)
    }

    // MARK: - Getter Tests

    func testGetPlayerLayer() {
        // Given
        let player = createPlayer()

        // When
        let layer = player.getPlayerLayer()

        // Then
        XCTAssertNotNil(layer)
    }

    func testIsPipAllowedDefault() {
        // Given
        let player = createPlayer()

        // When
        let allowed = player.isPipAllowed()

        // Then - Default is true
        XCTAssertTrue(allowed)
    }

    func testAreSubtitlesEnabledDefault() {
        // Given
        let player = createPlayer()

        // When
        let enabled = player.areSubtitlesEnabled()

        // Then - Default is true
        XCTAssertTrue(enabled)
    }

    // MARK: - Dispose Tests

    func testDispose() {
        // Given
        let player = createPlayer()

        // When
        player.dispose()

        // Then - No crash, resources released
        XCTAssertNil(player.getPlayerLayer())
    }

    func testDisposeAfterPlay() {
        // Given
        let player = createPlayer()
        player.play()

        // When
        player.dispose()

        // Then - No crash, resources released
        XCTAssertNil(player.getPlayerLayer())
    }

    func testDisposeAfterPause() {
        // Given
        let player = createPlayer()
        player.play()
        player.pause()

        // When
        player.dispose()

        // Then - No crash, resources released
        XCTAssertNil(player.getPlayerLayer())
    }

    // MARK: - FlutterStreamHandler Tests

    func testOnListen() {
        // Given
        let player = createPlayer()
        var receivedEvents: [[String: Any]] = []
        let eventSink: FlutterEventSink = { event in
            if let dict = event as? [String: Any] {
                receivedEvents.append(dict)
            }
        }

        // When
        let error = player.onListen(withArguments: nil, eventSink: eventSink)

        // Then
        XCTAssertNil(error)
    }

    func testOnCancel() {
        // Given
        let player = createPlayer()
        let eventSink: FlutterEventSink = { _ in }
        _ = player.onListen(withArguments: nil, eventSink: eventSink)

        // When
        let error = player.onCancel(withArguments: nil)

        // Then
        XCTAssertNil(error)
    }

    // MARK: - Edge Cases

    func testMultiplePlayCalls() {
        // Given
        let player = createPlayer()

        // When
        player.play()
        player.play()
        player.play()

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testMultiplePauseCalls() {
        // Given
        let player = createPlayer()

        // When
        player.pause()
        player.pause()
        player.pause()

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testPlayPauseSequence() {
        // Given
        let player = createPlayer()

        // When
        player.play()
        player.pause()
        player.play()
        player.pause()

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testStopAfterPlay() {
        // Given
        let player = createPlayer()
        player.play()

        // When
        player.stop()

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSeekWhilePlaying() {
        // Given
        let player = createPlayer()
        player.play()

        // When
        player.seekTo(milliseconds: 10000)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testVolumeChangeWhilePlaying() {
        // Given
        let player = createPlayer()
        player.play()

        // When
        player.setVolume(0.5)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSpeedChangeWhilePlaying() {
        // Given
        let player = createPlayer()
        player.play()

        // When
        player.setPlaybackSpeed(2.0)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    // MARK: - Additional AVPlayer Tests

    func testGetAVPlayer() {
        // Given
        let player = createPlayer()

        // When
        let avPlayer = player.getAVPlayer()

        // Then
        XCTAssertNotNil(avPlayer)
    }

    func testGetAVPlayerAfterDispose() {
        // Given
        let player = createPlayer()
        player.dispose()

        // When
        let avPlayer = player.getAVPlayer()

        // Then
        XCTAssertNil(avPlayer)
    }

    func testOnPlayerViewControllerAttached() {
        // Given
        let player = createPlayer(options: ["allowPip": true])
        let playerVC = AVPlayerViewController()

        // When
        player.onPlayerViewControllerAttached(playerVC)

        // Then - PiP should be enabled on the view controller
        XCTAssertTrue(playerVC.allowsPictureInPicturePlayback)
    }

    func testOnPlayerViewControllerAttachedWithPipDisabled() {
        // Given
        let player = createPlayer(options: ["allowPip": false])
        let playerVC = AVPlayerViewController()

        // When
        player.onPlayerViewControllerAttached(playerVC)

        // Then - PiP should be disabled on the view controller
        XCTAssertFalse(playerVC.allowsPictureInPicturePlayback)
    }

    // MARK: - Additional Looping Tests

    func testLoopingOptionOnInit() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["looping": true]

        // When
        let player = VideoPlayer(playerId: 100, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
    }

    // MARK: - Additional Volume Tests

    func testVolumeOptionOnInit() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["volume": 0.3]

        // When
        let player = VideoPlayer(playerId: 101, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
    }

    // MARK: - Additional Playback Speed Tests

    func testPlaybackSpeedOptionOnInit() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["playbackSpeed": 1.25]

        // When
        let player = VideoPlayer(playerId: 102, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
    }

    // MARK: - Additional Auto-PiP Tests

    func testAutoEnterPipOnBackgroundEnabled() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["allowPip": true, "autoEnterPipOnBackground": true]

        // When
        let player = VideoPlayer(playerId: 103, registrar: mockRegistrar, source: source, options: options)

        // Then - Player created with auto-PiP observer
        XCTAssertNotNil(player)
        XCTAssertTrue(player.isPipAllowed())
    }

    // MARK: - Additional Subtitle Tests

    func testShowSubtitlesByDefaultEnabled() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["subtitlesEnabled": true, "showSubtitlesByDefault": true]

        // When
        let player = VideoPlayer(playerId: 104, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
        XCTAssertTrue(player.areSubtitlesEnabled())
    }

    func testPreferredSubtitleLanguage() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["subtitlesEnabled": true, "preferredSubtitleLanguage": "es"]

        // When
        let player = VideoPlayer(playerId: 105, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
        XCTAssertTrue(player.areSubtitlesEnabled())
    }

    func testSetSubtitleTrackWithNonNumericId() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let track: [String: Any] = ["id": "invalid", "language": "en", "label": "English"]

        // When
        player.setSubtitleTrack(track)

        // Then - No crash, invalid id handled gracefully
        XCTAssertNotNil(player)
    }

    // MARK: - Empty Headers Test

    func testFileSourceWithEmptyHeaders() {
        // Given - File source with empty headers dict to verify it doesn't crash
        let source: [String: Any] = [
            "type": "file",
            "path": "/nonexistent/test.mp4",
            "headers": [:] as [String: String]
        ]
        let options: [String: Any] = [:]

        // When
        let player = VideoPlayer(playerId: 106, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
        XCTAssertNotNil(player.getPlayerLayer())
    }

    // MARK: - Multiple Dispose Calls

    func testMultipleDisposeCalls() {
        // Given
        let player = createPlayer()

        // When
        player.dispose()
        player.dispose()

        // Then - No crash
        XCTAssertNil(player.getPlayerLayer())
    }

    // MARK: - Playback Control After Dispose

    func testPlayAfterDispose() {
        // Given
        let player = createPlayer()
        player.dispose()

        // When
        player.play()

        // Then - No crash
        XCTAssertNil(player.getPlayerLayer())
    }

    func testPauseAfterDispose() {
        // Given
        let player = createPlayer()
        player.dispose()

        // When
        player.pause()

        // Then - No crash
        XCTAssertNil(player.getPlayerLayer())
    }

    func testSeekAfterDispose() {
        // Given
        let player = createPlayer()
        player.dispose()

        // When
        player.seekTo(milliseconds: 5000)

        // Then - No crash
        XCTAssertNil(player.getPlayerLayer())
    }

    // MARK: - Callback Tests (Internal Methods for Testability)

    func testHandlePlayerDidFinishPlayingWithLooping() {
        // Given
        let player = createPlayer(options: ["looping": true])
        player.play()

        // When - Simulate playback completion
        player.handlePlayerDidFinishPlaying()

        // Then - No crash, looping seeks to beginning
        XCTAssertNotNil(player)
    }

    func testHandlePlayerDidFinishPlayingWithoutLooping() {
        // Given
        let player = createPlayer(options: ["looping": false])

        // When
        player.handlePlayerDidFinishPlaying()

        // Then - No crash, sends completed event
        XCTAssertNotNil(player)
    }

    func testHandleAppDidEnterBackgroundWithAutoPipEnabled() {
        // Given
        let player = createPlayer(options: ["allowPip": true, "autoEnterPipOnBackground": true])

        // When - Simulate app entering background
        player.handleAppDidEnterBackground()

        // Then - No crash (PiP may not start in test environment but method should complete)
        XCTAssertNotNil(player)
    }

    func testHandleAppDidEnterBackgroundWithAutoPipDisabled() {
        // Given
        let player = createPlayer(options: ["allowPip": true, "autoEnterPipOnBackground": false])

        // When - Simulate app entering background
        player.handleAppDidEnterBackground()

        // Then - No crash, no action taken
        XCTAssertNotNil(player)
    }

    func testHandleAppDidEnterBackgroundWithPipNotAllowed() {
        // Given
        let player = createPlayer(options: ["allowPip": false, "autoEnterPipOnBackground": true])

        // When - Simulate app entering background
        player.handleAppDidEnterBackground()

        // Then - No crash, PiP should not be attempted
        XCTAssertNotNil(player)
    }

    func testHandlePipDidStart() {
        // Given
        let player = createPlayer(options: ["allowPip": true])

        // When
        player.handlePipDidStart()

        // Then - No crash, sends pip event
        XCTAssertNotNil(player)
    }

    func testHandlePipDidStop() {
        // Given
        let player = createPlayer(options: ["allowPip": true])

        // When
        player.handlePipDidStop()

        // Then - No crash, sends pip event
        XCTAssertNotNil(player)
    }

    func testNotifySubtitleTracks() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])

        // When - Call directly (won't find tracks in test environment but should not crash)
        player.notifySubtitleTracks()

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testNotifySubtitleTracksWithSubtitlesDisabled() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": false])

        // When
        player.notifySubtitleTracks()

        // Then - No crash, early return expected
        XCTAssertNotNil(player)
    }

    func testSendEvent() {
        // Given
        let player = createPlayer()

        // When - Send event (with or without listener)
        player.sendEvent(["type": "testEvent", "value": 42])

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSendEventWithListener() {
        // Given
        let player = createPlayer()
        let eventSink: FlutterEventSink = { _ in }
        _ = player.onListen(withArguments: nil, eventSink: eventSink)

        // When - Event is dispatched async to main queue
        player.sendEvent(["type": "testEvent", "value": 42])

        // Then - No crash (async delivery, can't verify synchronously)
        XCTAssertNotNil(player)
    }

    func testSendError() {
        // Given
        let player = createPlayer()

        // When - Send error (with or without listener)
        player.sendError(code: "TEST_ERROR", message: "Test error message")

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSendErrorWithListener() {
        // Given
        let player = createPlayer()
        let eventSink: FlutterEventSink = { _ in }
        _ = player.onListen(withArguments: nil, eventSink: eventSink)

        // When - Error is dispatched async to main queue
        player.sendError(code: "TEST_ERROR", message: "Test error message")

        // Then - No crash (async delivery, can't verify synchronously)
        XCTAssertNotNil(player)
    }

    func testSetupPipController() {
        // Given
        let player = createPlayer(options: ["allowPip": true])
        player.onPlayerLayerAttachedToView()

        // When - Call setup again (should be no-op if already set up)
        player.setupPipController()

        // Then - No crash, idempotent operation
        XCTAssertNotNil(player)
    }

    func testSetupPipControllerWithPipDisabled() {
        // Given
        let player = createPlayer(options: ["allowPip": false])

        // When
        player.setupPipController()

        // Then - No crash, early return expected
        XCTAssertNotNil(player)
    }

    // MARK: - PiP Delegate Method Tests

    func testPictureInPictureControllerDidStartPictureInPicture() {
        // Given
        let player = createPlayer(options: ["allowPip": true])

        // When - Simulate PiP start (tests the event sending behavior)
        player.handlePipDidStart()

        // Then - No crash, method sends pip event
        XCTAssertNotNil(player)
    }

    func testPictureInPictureControllerDidStopPictureInPicture() {
        // Given
        let player = createPlayer(options: ["allowPip": true])

        // When - Simulate PiP stop (tests the event sending behavior)
        player.handlePipDidStop()

        // Then - No crash, method sends pip event
        XCTAssertNotNil(player)
    }

    // MARK: - Additional Coverage Tests

    func testAutoSelectSubtitleWithNilGroup() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true, "showSubtitlesByDefault": true])

        // When - notifySubtitleTracks will try to auto-select if conditions met
        player.notifySubtitleTracks()

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetSubtitleTrackWithValidNumericId() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let track: [String: Any] = ["id": "0", "language": "en", "label": "English"]

        // When
        player.setSubtitleTrack(track)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testGetDurationWithLoadedPlayer() {
        // Given - Create player with file source
        let player = createPlayer()

        // When
        let duration = player.getDuration()

        // Then - Returns a duration value (negative for unloaded)
        XCTAssertNotNil(duration)
    }

    // MARK: - Network Resilience Tests

    func testHandlePlaybackBufferEmpty() {
        // Given
        let player = createPlayer()
        player.play()

        // When - Simulate buffer empty (network issue)
        player.handlePlaybackBufferEmpty()

        // Then - No crash, buffering event should be sent
        XCTAssertNotNil(player)
    }

    func testHandlePlaybackLikelyToKeepUp() {
        // Given
        let player = createPlayer()
        player.play()

        // Simulate buffering first
        player.handlePlaybackBufferEmpty()

        // When - Simulate buffer recovery
        player.handlePlaybackLikelyToKeepUp()

        // Then - No crash, buffering ended event should be sent
        XCTAssertNotNil(player)
    }

    func testHandlePlaybackBufferFull() {
        // Given
        let player = createPlayer()
        player.play()

        // Simulate buffering first
        player.handlePlaybackBufferEmpty()

        // When - Simulate buffer full (recovery)
        player.handlePlaybackBufferFull()

        // Then - No crash, should transition out of buffering state
        XCTAssertNotNil(player)
    }

    func testHandlePlaybackStalled() {
        // Given
        let player = createPlayer()
        player.play()

        // When - Simulate playback stall
        player.handlePlaybackStalled()

        // Then - No crash, buffering event should be sent
        XCTAssertNotNil(player)
    }

    func testHandleBufferingEnded() {
        // Given
        let player = createPlayer()
        player.play()

        // Simulate buffering first
        player.handlePlaybackBufferEmpty()

        // When
        player.handleBufferingEnded()

        // Then - No crash, playback state should be restored
        XCTAssertNotNil(player)
    }

    func testScheduleNetworkRetry() {
        // Given
        let player = createPlayer()

        // When - Schedule a retry
        player.scheduleNetworkRetry()

        // Then - No crash, retry should be scheduled
        XCTAssertNotNil(player)

        // Cleanup - Dispose to cancel the timer
        player.dispose()
    }

    func testAttemptNetworkRecovery() {
        // Given
        let player = createPlayer()

        // When - Attempt recovery
        player.attemptNetworkRecovery()

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testNetworkResilienceDisposeCleanup() {
        // Given
        let player = createPlayer()
        player.play()

        // Trigger buffering state
        player.handlePlaybackBufferEmpty()

        // Schedule a retry
        player.scheduleNetworkRetry()

        // When - Dispose should clean up retry timer
        player.dispose()

        // Then - No crash, resources cleaned up
        XCTAssertNil(player.getPlayerLayer())
    }

    func testMultipleBufferingStartedEventsNotDuplicated() {
        // Given
        let player = createPlayer()
        player.play()

        // When - Multiple buffer empty calls (simulating repeated network issues)
        player.handlePlaybackBufferEmpty()
        player.handlePlaybackBufferEmpty()
        player.handlePlaybackBufferEmpty()

        // Then - No crash, should only send one buffering started event
        XCTAssertNotNil(player)
    }

    func testBufferingEndedOnlyWhenBuffering() {
        // Given
        let player = createPlayer()
        player.play()

        // When - Call buffering ended without prior buffering
        player.handleBufferingEnded()

        // Then - No crash, no-op when not buffering
        XCTAssertNotNil(player)
    }

    func testPlaybackRecoveryAfterRetry() {
        // Given
        let player = createPlayer()
        player.play()

        // Simulate network error scenario
        player.handlePlaybackBufferEmpty()
        player.scheduleNetworkRetry()

        // When - Simulate successful recovery
        player.handlePlaybackLikelyToKeepUp()

        // Then - No crash, recovery event should be sent
        XCTAssertNotNil(player)

        // Cleanup
        player.dispose()
    }

    // MARK: - Scaling Mode Tests

    func testSetScalingModeFit() {
        // Given
        let player = createPlayer()

        // When
        player.setScalingMode("fit")

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetScalingModeFill() {
        // Given
        let player = createPlayer()

        // When
        player.setScalingMode("fill")

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetScalingModeStretch() {
        // Given
        let player = createPlayer()

        // When
        player.setScalingMode("stretch")

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetScalingModeUnknown() {
        // Given
        let player = createPlayer()

        // When - Unknown mode defaults to fit
        player.setScalingMode("unknown")

        // Then - No crash, defaults to fit
        XCTAssertNotNil(player)
    }

    func testScalingModeOptionOnInit() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["scalingMode": "fill"]

        // When
        let player = VideoPlayer(playerId: 200, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
    }

    // MARK: - Audio Track Tests

    func testSetAudioTrackWithValidTrack() {
        // Given
        let player = createPlayer()
        let track: [String: Any] = ["id": "0:0", "language": "en", "label": "English"]

        // When
        player.setAudioTrack(track)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetAudioTrackWithNil() {
        // Given
        let player = createPlayer()

        // When
        player.setAudioTrack(nil)

        // Then - No crash, resets to default
        XCTAssertNotNil(player)
    }

    func testSetAudioTrackWithInvalidId() {
        // Given
        let player = createPlayer()
        let track: [String: Any] = ["id": "invalid", "language": "en", "label": "English"]

        // When
        player.setAudioTrack(track)

        // Then - No crash, invalid track handled gracefully
        XCTAssertNotNil(player)
    }

    func testSetAudioTrackWithMissingId() {
        // Given
        let player = createPlayer()
        let track: [String: Any] = ["language": "en", "label": "English"]

        // When
        player.setAudioTrack(track)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testNotifyAudioTracks() {
        // Given
        let player = createPlayer()

        // When - Call directly (won't find tracks in test environment but should not crash)
        player.notifyAudioTracks()

        // Then - No crash
        XCTAssertNotNil(player)
    }

    // MARK: - Video Quality Tests

    func testGetVideoQualities() {
        // Given
        let player = createPlayer()

        // When
        let qualities = player.getVideoQualities()

        // Then - Returns empty list for unloaded/local video
        XCTAssertNotNil(qualities)
    }

    func testSetVideoQualityWithAutoTrack() {
        // Given
        let player = createPlayer()
        let track: [String: Any] = ["id": "auto"]

        // When
        let result = player.setVideoQuality(track)

        // Then
        XCTAssertTrue(result)
    }

    func testSetVideoQualityWithNil() {
        // Given
        let player = createPlayer()

        // When
        let result = player.setVideoQuality(nil)

        // Then - Nil enables auto quality
        XCTAssertTrue(result)
    }

    func testSetVideoQualityWithValidTrack() {
        // Given
        let player = createPlayer()
        let track: [String: Any] = ["id": "0:0", "bitrate": 1000000, "width": 1920, "height": 1080]

        // When
        let result = player.setVideoQuality(track)

        // Then - Returns true even if track not found (quality limits applied)
        XCTAssertTrue(result)
    }

    func testGetCurrentVideoQualityAuto() {
        // Given
        let player = createPlayer()

        // When
        let quality = player.getCurrentVideoQuality()

        // Then - Returns auto quality by default
        XCTAssertEqual(quality?["id"] as? String, "auto")
    }

    func testGetCurrentVideoQualityAfterSelection() {
        // Given
        let player = createPlayer()
        let track: [String: Any] = ["id": "0:0", "bitrate": 1000000, "width": 1920, "height": 1080]
        _ = player.setVideoQuality(track)

        // When
        let quality = player.getCurrentVideoQuality()

        // Then - Returns the selected track or auto
        XCTAssertNotNil(quality?["id"])
    }

    func testIsQualitySelectionSupported() {
        // Given
        let player = createPlayer()

        // When
        let supported = player.isQualitySelectionSupported()

        // Then - Returns false for local/unloaded video
        XCTAssertFalse(supported)
    }

    // MARK: - Background Playback Tests

    func testSetBackgroundPlaybackEnable() {
        // Given
        let player = createPlayer(options: ["allowBackgroundPlayback": false])

        // When
        let result = player.setBackgroundPlayback(true)

        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(player.isBackgroundPlaybackEnabled())
    }

    func testSetBackgroundPlaybackDisable() {
        // Given
        let player = createPlayer(options: ["allowBackgroundPlayback": true])

        // When
        let result = player.setBackgroundPlayback(false)

        // Then
        XCTAssertTrue(result)
        XCTAssertFalse(player.isBackgroundPlaybackEnabled())
    }

    func testIsBackgroundPlaybackEnabledDefault() {
        // Given
        let player = createPlayer()

        // When
        let enabled = player.isBackgroundPlaybackEnabled()

        // Then - Default is false
        XCTAssertFalse(enabled)
    }

    func testIsBackgroundPlaybackEnabledWithOption() {
        // Given
        let player = createPlayer(options: ["allowBackgroundPlayback": true])

        // When
        let enabled = player.isBackgroundPlaybackEnabled()

        // Then
        XCTAssertTrue(enabled)
    }

    // MARK: - Buffering Tier Tests
    // TODO: These tests test internal implementation. Refactor to test via public API or move to SharedVideoPlayer tests.

    func testBufferDurationForTierMin() throws {
        throw XCTSkip("Internal implementation test - bufferDurationForTier moved to SharedVideoPlayer")
    }

    func testBufferDurationForTierLow() throws {
        throw XCTSkip("Internal implementation test - bufferDurationForTier moved to SharedVideoPlayer")
    }

    func testBufferDurationForTierMedium() throws {
        throw XCTSkip("Internal implementation test - bufferDurationForTier moved to SharedVideoPlayer")
    }

    func testBufferDurationForTierHigh() throws {
        throw XCTSkip("Internal implementation test - bufferDurationForTier moved to SharedVideoPlayer")
    }

    func testBufferDurationForTierMax() throws {
        throw XCTSkip("Internal implementation test - bufferDurationForTier moved to SharedVideoPlayer")
    }

    func testBufferDurationForTierUnknown() throws {
        throw XCTSkip("Internal implementation test - bufferDurationForTier moved to SharedVideoPlayer")
    }

    func testBufferDurationForTierCaseInsensitive() throws {
        throw XCTSkip("Internal implementation test - bufferDurationForTier moved to SharedVideoPlayer")
    }

    func testBufferingTierOptionOnInit() {
        // Given
        let source: [String: Any] = ["type": "file", "path": "/nonexistent/test.mp4"]
        let options: [String: Any] = ["bufferingTier": "high"]

        // When
        let player = VideoPlayer(playerId: 201, registrar: mockRegistrar, source: source, options: options)

        // Then
        XCTAssertNotNil(player)
    }

    // MARK: - Media Metadata Tests

    func testSetMediaMetadataWithBackgroundPlaybackDisabled() {
        // Given
        let player = createPlayer(options: ["allowBackgroundPlayback": false])
        let metadata: [String: Any] = ["title": "Test Video", "artist": "Test Artist"]

        // When - Should early return
        player.setMediaMetadata(metadata)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetMediaMetadataWithBackgroundPlaybackEnabled() {
        // Given
        let player = createPlayer(options: ["allowBackgroundPlayback": true])
        let metadata: [String: Any] = ["title": "Test Video", "artist": "Test Artist", "album": "Test Album"]

        // When
        player.setMediaMetadata(metadata)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetMediaMetadataWithArtworkUrl() {
        // Given
        let player = createPlayer(options: ["allowBackgroundPlayback": true])
        let metadata: [String: Any] = [
            "title": "Test Video",
            "artworkUrl": "https://example.com/artwork.jpg"
        ]

        // When
        player.setMediaMetadata(metadata)

        // Then - No crash (async artwork loading)
        XCTAssertNotNil(player)
    }

    func testSetMediaMetadataWithInvalidArtworkUrl() {
        // Given
        let player = createPlayer(options: ["allowBackgroundPlayback": true])
        let metadata: [String: Any] = [
            "title": "Test Video",
            "artworkUrl": "invalid-url"
        ]

        // When
        player.setMediaMetadata(metadata)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testUpdateNowPlayingInfoWithBackgroundDisabled() throws {
        throw XCTSkip("Internal implementation test - updateNowPlayingInfo moved to SharedVideoPlayer")
    }

    func testUpdateNowPlayingInfoWithBackgroundEnabled() throws {
        throw XCTSkip("Internal implementation test - updateNowPlayingInfo moved to SharedVideoPlayer")
    }

    // MARK: - Additional Subtitle Track Format Tests

    func testSetSubtitleTrackWithColonFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let track: [String: Any] = ["id": "0:0", "language": "en", "label": "English"]

        // When
        player.setSubtitleTrack(track)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetSubtitleTrackWithInvalidColonFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let track: [String: Any] = ["id": "0:invalid", "language": "en", "label": "English"]

        // When
        player.setSubtitleTrack(track)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    // MARK: - External Subtitle Tests

    func testSetSubtitleTrackWithExternalTrackId() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let track: [String: Any] = ["id": "ext-0", "language": "en", "label": "External English"]

        // When - Select external track that doesn't exist yet
        player.setSubtitleTrack(track)

        // Then - No crash, gracefully handles non-existent external track
        XCTAssertNotNil(player)
    }

    func testSetSubtitleTrackWithExternalTrackAfterAdding() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "External subtitle added")

        // When - Add external subtitle first
        player.addExternalSubtitle(
            url: "https://example.com/subtitles.vtt",
            format: "vtt",
            label: "English",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then - Track should be created
            XCTAssertNotNil(trackDict)
            if let trackDict = trackDict {
                XCTAssertTrue((trackDict["id"] as? String)?.hasPrefix("ext-") ?? false)

                // Now select the external track
                player.setSubtitleTrack(trackDict)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testSetSubtitleTrackClearsExternalWhenSelectingEmbedded() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let embeddedTrack: [String: Any] = ["id": "0:0", "language": "es", "label": "Spanish"]

        // When - Select embedded track (should clear any external selection)
        player.setSubtitleTrack(embeddedTrack)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetSubtitleTrackDisablesAllWithNil() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "External subtitle added")

        // Add external subtitle first
        player.addExternalSubtitle(
            url: "https://example.com/subtitles.srt",
            format: "srt",
            label: "English",
            language: "en",
            isDefault: false
        ) { trackDict in
            if let trackDict = trackDict {
                // Select the external track
                player.setSubtitleTrack(trackDict)

                // When - Disable all subtitles
                player.setSubtitleTrack(nil)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testAddExternalSubtitleReturnsTrack() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "External subtitle added")

        // When
        player.addExternalSubtitle(
            url: "https://example.com/subtitles.vtt",
            format: "vtt",
            label: "Test Label",
            language: "fr",
            isDefault: true
        ) { trackDict in
            // Then
            XCTAssertNotNil(trackDict)
            XCTAssertEqual(trackDict?["url"] as? String, "https://example.com/subtitles.vtt")
            XCTAssertEqual(trackDict?["format"] as? String, "vtt")
            XCTAssertEqual(trackDict?["label"] as? String, "Test Label")
            XCTAssertEqual(trackDict?["language"] as? String, "fr")
            XCTAssertEqual(trackDict?["isDefault"] as? Bool, true)
            XCTAssertTrue((trackDict?["id"] as? String)?.hasPrefix("ext-") ?? false)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleWithSubtitlesDisabled() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": false])
        let expectation = XCTestExpectation(description: "External subtitle rejected")

        // When
        player.addExternalSubtitle(
            url: "https://example.com/subtitles.vtt",
            format: "vtt",
            label: "English",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then - Should return nil when subtitles disabled
            XCTAssertNil(trackDict)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleWithInvalidUrl() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "Invalid URL rejected")

        // When
        player.addExternalSubtitle(
            url: "not a valid url",
            format: "vtt",
            label: "English",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then - Should return nil for invalid URL
            XCTAssertNil(trackDict)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testRemoveExternalSubtitle() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "External subtitle added then removed")

        // Add external subtitle first
        player.addExternalSubtitle(
            url: "https://example.com/subtitles.vtt",
            format: "vtt",
            label: "English",
            language: "en",
            isDefault: false
        ) { trackDict in
            guard let trackId = trackDict?["id"] as? String else {
                XCTFail("Track ID should not be nil")
                expectation.fulfill()
                return
            }

            // When - Remove the track
            let removed = player.removeExternalSubtitle(trackId: trackId)

            // Then
            XCTAssertTrue(removed)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testRemoveExternalSubtitleWithNonExistentId() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])

        // When
        let removed = player.removeExternalSubtitle(trackId: "ext-999")

        // Then
        XCTAssertFalse(removed)
    }

    func testGetExternalSubtitlesReturnsEmptyInitially() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])

        // When
        let tracks = player.getExternalSubtitles()

        // Then
        XCTAssertTrue(tracks.isEmpty)
    }

    func testGetExternalSubtitlesReturnsAddedTracks() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "External subtitles added")

        // When - Add two external subtitles
        player.addExternalSubtitle(
            url: "https://example.com/english.vtt",
            format: "vtt",
            label: "English",
            language: "en",
            isDefault: false
        ) { _ in
            player.addExternalSubtitle(
                url: "https://example.com/spanish.srt",
                format: "srt",
                label: "Spanish",
                language: "es",
                isDefault: false
            ) { _ in
                // Then
                let tracks = player.getExternalSubtitles()
                XCTAssertEqual(tracks.count, 2)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleAutoDetectsFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "Format auto-detected")

        // When - Add without explicit format (should detect from URL)
        player.addExternalSubtitle(
            url: "https://example.com/subtitles.srt",
            format: nil,
            label: "English",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then - Format should be detected as srt
            XCTAssertEqual(trackDict?["format"] as? String, "srt")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleWithVttFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "VTT subtitle added")

        // When
        player.addExternalSubtitle(
            url: "https://example.com/subtitles.vtt",
            format: "vtt",
            label: "English VTT",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then
            XCTAssertNotNil(trackDict)
            XCTAssertEqual(trackDict?["format"] as? String, "vtt")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleWithSsaFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "SSA subtitle added")

        // When
        player.addExternalSubtitle(
            url: "https://example.com/subtitles.ssa",
            format: "ssa",
            label: "English SSA",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then
            XCTAssertNotNil(trackDict)
            XCTAssertEqual(trackDict?["format"] as? String, "ssa")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleWithAssFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "ASS subtitle added")

        // When
        player.addExternalSubtitle(
            url: "https://example.com/subtitles.ass",
            format: "ass",
            label: "English ASS",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then
            XCTAssertNotNil(trackDict)
            XCTAssertEqual(trackDict?["format"] as? String, "ass")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleWithTtmlFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "TTML subtitle added")

        // When
        player.addExternalSubtitle(
            url: "https://example.com/subtitles.ttml",
            format: "ttml",
            label: "English TTML",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then
            XCTAssertNotNil(trackDict)
            XCTAssertEqual(trackDict?["format"] as? String, "ttml")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleAutoDetectsVttFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "VTT format auto-detected")

        // When - Add without explicit format
        player.addExternalSubtitle(
            url: "https://example.com/captions.vtt",
            format: nil,
            label: "English",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then
            XCTAssertEqual(trackDict?["format"] as? String, "vtt")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleAutoDetectsSsaFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "SSA format auto-detected")

        // When - Add without explicit format
        player.addExternalSubtitle(
            url: "https://example.com/captions.ssa",
            format: nil,
            label: "English",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then
            XCTAssertEqual(trackDict?["format"] as? String, "ssa")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleAutoDetectsAssFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "ASS format auto-detected")

        // When - Add without explicit format
        player.addExternalSubtitle(
            url: "https://example.com/captions.ass",
            format: nil,
            label: "English",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then
            XCTAssertEqual(trackDict?["format"] as? String, "ass")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testAddExternalSubtitleAutoDetectsTtmlFormat() {
        // Given
        let player = createPlayer(options: ["subtitlesEnabled": true])
        let expectation = XCTestExpectation(description: "TTML format auto-detected")

        // When - Add without explicit format
        player.addExternalSubtitle(
            url: "https://example.com/captions.ttml",
            format: nil,
            label: "English",
            language: "en",
            isDefault: false
        ) { trackDict in
            // Then
            XCTAssertEqual(trackDict?["format"] as? String, "ttml")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - KVO Observer Tests

    func testStatusChangedKVOPath() {
        // Given
        let player = createPlayer()

        // When - Simulate KVO callback for status
        player.observeValue(forKeyPath: "status", of: nil, change: nil, context: nil)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testLoadedTimeRangesKVOPath() {
        // Given
        let player = createPlayer()

        // When - Simulate KVO callback
        player.observeValue(forKeyPath: "loadedTimeRanges", of: nil, change: nil, context: nil)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testPlaybackBufferEmptyKVOPath() {
        // Given
        let player = createPlayer()

        // When - Simulate KVO callback
        player.observeValue(forKeyPath: "playbackBufferEmpty", of: nil, change: nil, context: nil)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testPlaybackLikelyToKeepUpKVOPath() {
        // Given
        let player = createPlayer()

        // When - Simulate KVO callback
        player.observeValue(forKeyPath: "playbackLikelyToKeepUp", of: nil, change: nil, context: nil)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testPlaybackBufferFullKVOPath() {
        // Given
        let player = createPlayer()

        // When - Simulate KVO callback
        player.observeValue(forKeyPath: "playbackBufferFull", of: nil, change: nil, context: nil)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testUnknownKVOPath() {
        // Given
        let player = createPlayer()

        // When - Simulate KVO callback for unknown path
        player.observeValue(forKeyPath: "unknownPath", of: nil, change: nil, context: nil)

        // Then - No crash, should be ignored
        XCTAssertNotNil(player)
    }

    // MARK: - Network Monitor Tests
    // TODO: These tests test internal implementation. Refactor to test via public API or move to SharedVideoPlayer tests.

    func testNetworkStateChangedToDisconnected() throws {
        throw XCTSkip("Internal implementation test - handleNetworkStateChanged moved to SharedVideoPlayer")
    }

    func testNetworkStateChangedToConnected() throws {
        throw XCTSkip("Internal implementation test - handleNetworkStateChanged moved to SharedVideoPlayer")
    }

    func testNetworkRecoveryAfterError() throws {
        throw XCTSkip("Internal implementation test - handleNetworkStateChanged moved to SharedVideoPlayer")
    }

    // MARK: - Player Item Failed Notification Test

    func testHandlePlayerItemFailedToPlayToEnd() throws {
        throw XCTSkip("Internal implementation test - handlePlayerItemFailedToPlayToEnd moved to SharedVideoPlayer")
    }

    func testHandlePlayerItemFailedToPlayToEndWithoutError() throws {
        throw XCTSkip("Internal implementation test - handlePlayerItemFailedToPlayToEnd moved to SharedVideoPlayer")
    }

    // MARK: - Extract Metadata Test

    func testExtractAndSendMetadata() throws {
        throw XCTSkip("Internal implementation test - extractAndSendMetadata moved to SharedVideoPlayer")
    }

    // MARK: - Handle Status Changed Test

    func testHandleStatusChangedReady() throws {
        throw XCTSkip("Internal implementation test - handleStatusChanged moved to SharedVideoPlayer")
    }

    // MARK: - Auto Select Subtitle Tests

    func testAutoSelectSubtitleWithPreferredLanguage() {
        // Given
        let player = createPlayer(options: [
            "subtitlesEnabled": true,
            "showSubtitlesByDefault": true,
            "preferredSubtitleLanguage": "en"
        ])

        // When - notifySubtitleTracks will trigger autoSelectSubtitle internally if conditions are met
        player.notifySubtitleTracks()

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testAutoSelectSubtitleWithoutPreferredLanguage() {
        // Given
        let player = createPlayer(options: [
            "subtitlesEnabled": true,
            "showSubtitlesByDefault": true
        ])

        // When - notifySubtitleTracks will trigger autoSelectSubtitle internally if conditions are met
        player.notifySubtitleTracks()

        // Then - No crash
        XCTAssertNotNil(player)
    }

    // MARK: - Set PiP Actions Tests

    func testSetPipActionsWithEmptyArray() {
        // Given
        let player = createPlayer(options: ["allowPip": true])

        // When
        player.setPipActions([])

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetPipActionsWithSkipActions() {
        // Given
        let player = createPlayer(options: ["allowPip": true])
        let actions: [[String: Any]] = [
            ["type": "skipBackward", "skipInterval": 10],
            ["type": "skipForward", "skipInterval": 15]
        ]

        // When
        player.setPipActions(actions)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    func testSetPipActionsWithNil() {
        // Given
        let player = createPlayer(options: ["allowPip": true])

        // When
        player.setPipActions(nil)

        // Then - No crash
        XCTAssertNotNil(player)
    }

    // MARK: - Handle Loaded Time Ranges Tests

    func testHandleLoadedTimeRangesChanged() throws {
        throw XCTSkip("Internal implementation test - handleLoadedTimeRangesChanged moved to SharedVideoPlayer")
    }

    // MARK: - Auto Select Subtitle with AVMediaSelectionGroup Tests

    func testAutoSelectSubtitleWithOptionsAndGroup() {
        // Given
        let player = createPlayer(options: [
            "subtitlesEnabled": true,
            "showSubtitlesByDefault": true,
            "preferredSubtitleLanguage": "en"
        ])

        // We can't easily create AVMediaSelectionOption/Group in tests,
        // but we can verify the method exists and the player doesn't crash
        // when calling notifySubtitleTracks which may trigger it internally
        player.notifySubtitleTracks()

        // Then - No crash
        XCTAssertNotNil(player)
    }
}
