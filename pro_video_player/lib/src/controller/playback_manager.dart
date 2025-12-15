import 'dart:async';

import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

// Alias for cleaner code
typedef _Logger = ProVideoPlayerLogger;

/// Manages playback control for the video player.
///
/// This manager handles:
/// - Playback control (play, pause, stop)
/// - Seeking (seekTo, seekForward, seekBackward)
/// - Playback speed control
/// - Volume control
/// - State synchronization with platform
class PlaybackManager {
  /// Creates a playback manager with dependency injection via callbacks.
  PlaybackManager({
    required this.getValue,
    required this.setValue,
    required this.getPlayerId,
    required this.platform,
    required this.ensureInitialized,
  });

  /// Gets the current video player value.
  final VideoPlayerValue Function() getValue;

  /// Updates the video player value.
  final void Function(VideoPlayerValue) setValue;

  /// Gets the player ID (null if not initialized).
  final int? Function() getPlayerId;

  /// Platform implementation for playback operations.
  final ProVideoPlayerPlatform platform;

  /// Ensures the controller is initialized before operations.
  final void Function() ensureInitialized;

  // State flags for synchronization
  bool _isStartingPlayback = false;
  Timer? _startingPlaybackTimeout;
  bool _isSeeking = false;
  Duration? _seekTargetPosition;
  Duration? _lastPositionForStateCheck;
  int _positionUpdateCount = 0;

  /// Whether the player is starting playback (flag to ignore stale events).
  bool get isStartingPlayback => _isStartingPlayback;

  /// Whether the player is currently seeking (flag to ignore stale position events).
  bool get isSeeking => _isSeeking;

  /// The target seek position (null if not seeking).
  Duration? get seekTargetPosition => _seekTargetPosition;

  /// Starts video playback.
  Future<void> play() async {
    ensureInitialized();
    _Logger.log('Playing video (playerId: ${getPlayerId()})', tag: 'Controller');

    // Set flag to ignore stale paused/ready events until native confirms playing
    _isStartingPlayback = true;
    // Reset position tracking for state mismatch detection
    _lastPositionForStateCheck = null;
    _positionUpdateCount = 0;

    // Set timeout to clear _isStartingPlayback flag if native doesn't confirm
    _startingPlaybackTimeout?.cancel();
    _startingPlaybackTimeout = Timer(const Duration(seconds: 2), () {
      if (_isStartingPlayback) {
        _Logger.log('Timeout: clearing _isStartingPlayback flag', tag: 'Controller');
        _isStartingPlayback = false;
      }
    });

    // Optimistically update state for immediate UI feedback
    final value = getValue();
    setValue(value.copyWith(playbackState: PlaybackState.playing));
    await platform.play(getPlayerId()!);
  }

  /// Pauses video playback.
  Future<void> pause() async {
    ensureInitialized();
    _Logger.log('Pausing video (playerId: ${getPlayerId()})', tag: 'Controller');

    // Clear starting flag since user explicitly paused
    _isStartingPlayback = false;
    _startingPlaybackTimeout?.cancel();
    _startingPlaybackTimeout = null;

    // Optimistically update state for immediate UI feedback
    final value = getValue();
    setValue(value.copyWith(playbackState: PlaybackState.paused));
    await platform.pause(getPlayerId()!);
  }

  /// Stops playback and resets position to the beginning.
  Future<void> stop() async {
    ensureInitialized();

    // Optimistically update state for immediate UI feedback
    final value = getValue();
    setValue(value.copyWith(playbackState: PlaybackState.ready, position: Duration.zero));
    await platform.stop(getPlayerId()!);
  }

  /// Seeks to the specified [position].
  Future<void> seekTo(Duration position) async {
    ensureInitialized();

    // Set seeking flag and target to ignore stale position events
    _isSeeking = true;
    _seekTargetPosition = position;

    // Optimistically update position for immediate UI feedback
    final value = getValue();
    setValue(value.copyWith(position: position));
    await platform.seekTo(getPlayerId()!, position);
  }

  /// Seeks forward by [duration].
  Future<void> seekForward(Duration duration) async {
    final value = getValue();
    final newPosition = value.position + duration;
    final clampedPosition = newPosition > value.duration ? value.duration : newPosition;
    await seekTo(clampedPosition);
  }

  /// Seeks backward by [duration].
  Future<void> seekBackward(Duration duration) async {
    final value = getValue();
    final newPosition = value.position - duration;
    final clampedPosition = newPosition < Duration.zero ? Duration.zero : newPosition;
    await seekTo(clampedPosition);
  }

  /// Toggles between play and pause states.
  Future<void> togglePlayPause() async {
    final value = getValue();
    if (value.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Sets the playback speed.
  ///
  /// [speed] must be greater than 0.
  Future<void> setPlaybackSpeed(double speed) async {
    ensureInitialized();
    if (speed <= 0) {
      throw ArgumentError.value(speed, 'speed', 'must be greater than 0');
    }
    await platform.setPlaybackSpeed(getPlayerId()!, speed);
    final value = getValue();
    setValue(value.copyWith(playbackSpeed: speed));
  }

  /// Sets the player volume.
  ///
  /// [volume] must be between 0.0 (muted) and 1.0 (full volume).
  Future<void> setVolume(double volume) async {
    ensureInitialized();
    if (volume < 0 || volume > 1) {
      throw ArgumentError.value(volume, 'volume', 'must be between 0.0 and 1.0');
    }
    await platform.setVolume(getPlayerId()!, volume);
    final value = getValue();
    setValue(value.copyWith(volume: volume));
  }

  /// Handles playback state changed events from the platform.
  ///
  /// Returns `true` if the event was handled and should be processed normally,
  /// `false` if the event should be ignored (stale event).
  bool handlePlaybackStateChanged(PlaybackState state) {
    // Ignore stale paused/ready events if we're starting playback
    if (_isStartingPlayback && (state == PlaybackState.paused || state == PlaybackState.ready)) {
      _Logger.log('Ignoring stale $state event (starting playback)', tag: 'Controller');
      return false;
    }

    // Clear starting playback flag when we get playing confirmation
    if (_isStartingPlayback && state == PlaybackState.playing) {
      _isStartingPlayback = false;
      _startingPlaybackTimeout?.cancel();
      _startingPlaybackTimeout = null;
    }

    return true;
  }

  /// Handles position changed events from the platform.
  ///
  /// Returns `true` if the position should be updated in the controller value,
  /// `false` if the position event should be ignored (stale or seeking).
  bool handlePositionChanged(Duration position) {
    // Ignore stale position events while seeking
    if (_isSeeking && _seekTargetPosition != null) {
      final targetMs = _seekTargetPosition!.inMilliseconds;
      final positionMs = position.inMilliseconds;
      final diff = (positionMs - targetMs).abs();

      // If position is close to target (within 500ms), we've arrived at seek target
      if (diff < 500) {
        final value = getValue();
        setValue(value.copyWith(position: _seekTargetPosition));
        _isSeeking = false;
        _seekTargetPosition = null;
        return false; // Already updated with exact target position
      }

      // Still seeking, ignore this position update
      return false;
    }

    // Detect state mismatches: if position is updating but state isn't playing
    final value = getValue();
    if (value.playbackState != PlaybackState.playing && value.playbackState != PlaybackState.buffering) {
      final lastPos = _lastPositionForStateCheck;
      if (lastPos != null && position != lastPos) {
        _positionUpdateCount++;
        // If we've seen 3 consecutive position changes while not playing, likely a state mismatch
        if (_positionUpdateCount >= 3) {
          _Logger.log(
            'Position mismatch detected: position updating but state is ${value.playbackState}. Correcting to playing.',
            tag: 'Controller',
          );
          setValue(value.copyWith(playbackState: PlaybackState.playing));
          _positionUpdateCount = 0;
          _lastPositionForStateCheck = position;
        }
      } else {
        _positionUpdateCount = 0;
      }
      _lastPositionForStateCheck = position;
    } else {
      // State is correct, reset tracking
      _positionUpdateCount = 0;
      _lastPositionForStateCheck = null;
    }

    return true;
  }

  /// Disposes the playback manager and cleans up resources.
  void dispose() {
    _startingPlaybackTimeout?.cancel();
    _startingPlaybackTimeout = null;
  }
}
