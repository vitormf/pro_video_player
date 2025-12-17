import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../abstractions/video_element_interface.dart';
import '../manager_callbacks.dart';
import '../verbose_logging.dart';

/// Manages playback controls for web video player.
///
/// This manager handles:
/// - Playback operations (play, pause, stop)
/// - Seeking to positions
/// - Volume control
/// - Playback speed control
/// - Looping state
/// - Duration and position queries
///
/// Core playback functionality is centralized here for consistency
/// and testability.
class PlaybackControlManager with WebManagerCallbacks {
  /// Creates a playback control manager.
  PlaybackControlManager({required this.emitEvent, required this.videoElement});

  @override
  final EventEmitter emitEvent;

  @override
  final VideoElementInterface videoElement;

  /// Starts playback.
  Future<void> play() async {
    try {
      await videoElement.play();
      verboseLog('Playback started', tag: 'PlaybackControlManager');
    } catch (e) {
      emitEvent(ErrorEvent('Failed to play video: $e'));
      verboseLog('Failed to play: $e', tag: 'PlaybackControlManager');
    }
  }

  /// Pauses playback.
  void pause() {
    final element = videoElement as dynamic;
    element.pause();
    verboseLog('Playback paused', tag: 'PlaybackControlManager');
  }

  /// Stops playback and resets position to beginning.
  void stop() {
    final element = videoElement as dynamic;
    element.pause();
    element.currentTime = 0.0;
    verboseLog('Playback stopped', tag: 'PlaybackControlManager');
  }

  /// Seeks to the specified position.
  ///
  /// Throws [ArgumentError] if position is negative.
  void seekTo(Duration position) {
    if (position.isNegative) {
      throw ArgumentError('Position must be non-negative');
    }

    final element = videoElement as dynamic;
    element.currentTime = position.inMilliseconds / 1000.0;
    verboseLog('Seeked to: $position', tag: 'PlaybackControlManager');
  }

  /// Sets the playback speed (0.0 < speed <= 10.0).
  ///
  /// Throws [ArgumentError] if speed is out of range.
  void setPlaybackSpeed(double speed) {
    if (speed <= 0.0 || speed > 10.0) {
      throw ArgumentError('Playback speed must be between 0.0 (exclusive) and 10.0');
    }

    final element = videoElement as dynamic;
    element.playbackRate = speed;
    verboseLog('Playback speed set to: $speed', tag: 'PlaybackControlManager');
  }

  /// Sets the volume (0.0 to 1.0).
  ///
  /// Values are clamped to the valid range.
  void setVolume(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    final element = videoElement as dynamic;
    element.volume = clampedVolume;
    verboseLog('Volume set to: $clampedVolume', tag: 'PlaybackControlManager');
  }

  /// Gets the current looping state.
  bool get looping {
    final element = videoElement as dynamic;
    return element.loop as bool;
  }

  /// Sets whether the video should loop.
  set looping(bool value) {
    final element = videoElement as dynamic;
    element.loop = value;
    verboseLog('Looping set to: $value', tag: 'PlaybackControlManager');
  }

  /// Gets the video duration.
  ///
  /// Returns [Duration.zero] for infinite or NaN durations.
  Duration getDuration() {
    final element = videoElement as dynamic;
    final duration = element.duration as double;

    if (duration.isInfinite || duration.isNaN) {
      return Duration.zero;
    }

    return Duration(milliseconds: (duration * 1000).round());
  }

  /// Gets the current playback position.
  Duration getPosition() => Duration(milliseconds: (videoElement.currentTime * 1000).round());

  /// Disposes the manager and cleans up resources.
  void dispose() {
    verboseLog('Playback control manager disposed', tag: 'PlaybackControlManager');
  }
}
