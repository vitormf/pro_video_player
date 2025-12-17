import 'dart:async';

import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'html_element_helpers.dart';
import 'mock_js_interop.dart';
import 'web_test_constants.dart';

/// Standardized test fixture for web video player manager tests.
///
/// Provides mock HTML video element, event stream management, and helper
/// methods for common test operations. Use this fixture in all manager tests
/// for consistency.
///
/// Example usage:
/// ```dart
/// late WebVideoPlayerTestFixture fixture;
///
/// setUp(() {
///   fixture = WebVideoPlayerTestFixture()..setUp();
/// });
///
/// tearDown(() async {
///   await fixture.tearDown();
/// });
///
/// test('manager does something', () {
///   fixture.emitPlayingEvent();
///   // ... test logic ...
///   fixture.verifyEventEmitted<PlaybackStateChangedEvent>();
/// });
/// ```
class WebVideoPlayerTestFixture {
  /// Mock HTML video element.
  late MockHTMLVideoElement videoElement;

  /// Mock HLS.js player (null until needed).
  MockHlsPlayer? hlsPlayer;

  /// Mock DASH.js player (null until needed).
  MockDashPlayer? dashPlayer;

  /// Mock Wake Lock API.
  late MockWakeLock wakeLock;

  /// Event stream controller for emitted events.
  late StreamController<VideoPlayerEvent> eventController;

  /// List of emitted events for verification.
  final List<VideoPlayerEvent> emittedEvents = [];

  /// Whether the fixture has been set up.
  bool _isSetUp = false;

  /// Sets up the fixture with default mocks.
  ///
  /// Call this in your test's `setUp()` function.
  void setUp({String? sourceUrl, double? duration, double? width, double? height}) {
    if (_isSetUp) {
      throw StateError('Fixture already set up. Call tearDown() first.');
    }

    videoElement = createMockVideoElement(
      src: sourceUrl ?? WebTestMedia.mp4Url,
      duration: duration ?? WebTestMetadata.duration.inSeconds.toDouble(),
      width: width ?? WebTestSizes.videoWidth,
      height: height ?? WebTestSizes.videoHeight,
    );

    wakeLock = MockWakeLock();

    eventController = StreamController<VideoPlayerEvent>.broadcast();

    // Listen to events and store them for verification
    eventController.stream.listen(emittedEvents.add);

    _isSetUp = true;
  }

  /// Tears down the fixture and cleans up resources.
  ///
  /// Call this in your test's `tearDown()` function.
  Future<void> tearDown() async {
    if (!_isSetUp) return;

    await eventController.close();
    hlsPlayer?.destroy();
    dashPlayer?.reset();
    wakeLock.clear();
    emittedEvents.clear();

    _isSetUp = false;
  }

  // ============================================================================
  // Event Emission Helpers
  // ============================================================================

  /// Emits an event via the event controller.
  void emitEvent(VideoPlayerEvent event) {
    if (!_isSetUp) {
      throw StateError('Fixture not set up. Call setUp() first.');
    }
    eventController.add(event);
  }

  /// Simulates playing state.
  void emitPlayingEvent() {
    videoElement.paused = false;
    simulateCanPlay(videoElement);
  }

  /// Simulates paused state.
  void emitPausedEvent() {
    videoElement.paused = true;
    videoElement.triggerEvent('pause');
  }

  /// Simulates buffering state.
  void emitBufferingEvent({required bool isBuffering}) {
    simulateBuffering(videoElement, isBuffering);
  }

  /// Simulates an error.
  void emitErrorEvent({int code = 2, String message = 'Test error'}) {
    simulateError(videoElement, code: code, message: message);
  }

  /// Simulates time update.
  void emitTimeUpdate(double timeInSeconds) {
    simulateTimeUpdate(videoElement, timeInSeconds);
  }

  /// Simulates volume change.
  void emitVolumeChange(double volume) {
    simulateVolumeChange(videoElement, volume);
  }

  /// Simulates playback speed change.
  void emitSpeedChange(double speed) {
    simulateRateChange(videoElement, speed);
  }

  /// Simulates entering PiP.
  void emitEnterPip() {
    simulateEnterPip(videoElement);
  }

  /// Simulates leaving PiP.
  void emitLeavePip() {
    simulateLeavePip(videoElement);
  }

  /// Simulates entering fullscreen.
  void emitEnterFullscreen() {
    simulateEnterFullscreen(videoElement);
  }

  /// Simulates leaving fullscreen.
  void emitLeaveFullscreen() {
    simulateLeaveFullscreen(videoElement);
  }

  // ============================================================================
  // HLS.js Helpers
  // ============================================================================

  /// Creates and initializes a mock HLS.js player.
  MockHlsPlayer createHlsPlayer({
    List<MockHlsLevel>? levels,
    List<MockHlsAudioTrack>? audioTracks,
    List<MockHlsSubtitleTrack>? subtitleTracks,
  }) {
    hlsPlayer = MockHlsPlayer()
      ..levels =
          levels ??
          [
            MockHlsLevel(height: 1080, bitrate: 5000000, width: 1920, name: '1080p'),
            MockHlsLevel(height: 720, bitrate: 2500000, width: 1280, name: '720p'),
            MockHlsLevel(height: 480, bitrate: 1000000, width: 854, name: '480p'),
          ]
      ..audioTracks = audioTracks ?? []
      ..subtitleTracks = subtitleTracks ?? [];

    return hlsPlayer!;
  }

  /// Simulates HLS manifest parsed event.
  void emitHlsManifestParsed() {
    if (hlsPlayer == null) {
      throw StateError('HLS player not created. Call createHlsPlayer() first.');
    }
    hlsPlayer!.triggerEvent('manifestParsed');
  }

  /// Simulates HLS level switched event.
  void emitHlsLevelSwitched(int levelIndex) {
    if (hlsPlayer == null) {
      throw StateError('HLS player not created. Call createHlsPlayer() first.');
    }
    hlsPlayer!.currentLevel = levelIndex;
    hlsPlayer!.triggerEvent('levelSwitched', {'level': levelIndex});
  }

  /// Simulates HLS error event.
  void emitHlsError({required bool fatal, String type = 'networkError'}) {
    if (hlsPlayer == null) {
      throw StateError('HLS player not created. Call createHlsPlayer() first.');
    }
    hlsPlayer!.triggerEvent('error', {'fatal': fatal, 'type': type});
  }

  // ============================================================================
  // DASH.js Helpers
  // ============================================================================

  /// Creates and initializes a mock DASH.js player.
  MockDashPlayer createDashPlayer({List<MockDashBitrateInfo>? bitrateInfos}) {
    dashPlayer = MockDashPlayer()
      ..bitrateInfos =
          bitrateInfos ??
          [
            MockDashBitrateInfo(bitrate: 5000000, width: 1920, height: 1080, qualityIndex: 0),
            MockDashBitrateInfo(bitrate: 2500000, width: 1280, height: 720, qualityIndex: 1),
            MockDashBitrateInfo(bitrate: 1000000, width: 854, height: 480, qualityIndex: 2),
          ];

    return dashPlayer!;
  }

  /// Simulates DASH stream initialized event.
  void emitDashStreamInitialized() {
    if (dashPlayer == null) {
      throw StateError('DASH player not created. Call createDashPlayer() first.');
    }
    dashPlayer!.triggerEvent('streamInitialized');
  }

  /// Simulates DASH quality change event.
  void emitDashQualityChanged(int qualityIndex) {
    if (dashPlayer == null) {
      throw StateError('DASH player not created. Call createDashPlayer() first.');
    }
    dashPlayer!.currentQuality = qualityIndex;
    dashPlayer!.triggerEvent('qualityChangeRendered', {'mediaType': 'video', 'newQuality': qualityIndex});
  }

  /// Simulates DASH error event.
  void emitDashError({required String errorCode, String? message}) {
    if (dashPlayer == null) {
      throw StateError('DASH player not created. Call createDashPlayer() first.');
    }
    dashPlayer!.triggerEvent('error', {
      'error': {'code': errorCode, 'message': message ?? 'DASH error'},
    });
  }

  // ============================================================================
  // Verification Helpers
  // ============================================================================

  /// Verifies that an event of type [T] was emitted.
  ///
  /// Returns the first matching event if found, throws if not found.
  T verifyEventEmitted<T extends VideoPlayerEvent>() {
    final event = emittedEvents.whereType<T>().firstOrNull;
    if (event == null) {
      throw StateError(
        'Expected event of type $T but none was emitted. '
        'Emitted events: ${emittedEvents.map((e) => e.runtimeType).toList()}',
      );
    }
    return event;
  }

  /// Verifies that no events of type [T] were emitted.
  void verifyNoEventEmitted<T extends VideoPlayerEvent>() {
    final events = emittedEvents.whereType<T>().toList();
    if (events.isNotEmpty) {
      throw StateError('Expected no events of type $T but ${events.length} were emitted: $events');
    }
  }

  /// Verifies that exactly [count] events of type [T] were emitted.
  void verifyEventEmittedCount<T extends VideoPlayerEvent>(int count) {
    final events = emittedEvents.whereType<T>().toList();
    if (events.length != count) {
      throw StateError('Expected $count events of type $T but ${events.length} were emitted: $events');
    }
  }

  /// Clears all emitted events.
  void clearEmittedEvents() {
    emittedEvents.clear();
  }

  /// Gets all emitted events of type [T].
  List<T> getEmittedEvents<T extends VideoPlayerEvent>() => emittedEvents.whereType<T>().toList();

  // ============================================================================
  // Wake Lock Helpers
  // ============================================================================

  /// Verifies that wake lock was requested.
  void verifyWakeLockRequested() {
    if (wakeLock.currentSentinel == null) {
      throw StateError('Expected wake lock to be requested but it was not');
    }
  }

  /// Verifies that wake lock was released.
  void verifyWakeLockReleased() {
    if (wakeLock.currentSentinel == null || !wakeLock.currentSentinel!.released) {
      throw StateError('Expected wake lock to be released but it was not');
    }
  }

  /// Verifies that no wake lock is active.
  void verifyNoWakeLock() {
    if (wakeLock.currentSentinel != null && !wakeLock.currentSentinel!.released) {
      throw StateError('Expected no wake lock but one is active');
    }
  }
}

// Extension to add firstOrNull for backwards compatibility
extension _IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
