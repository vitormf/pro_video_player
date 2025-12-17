import 'dart:async' show unawaited;

/// Manages horizontal swipe seeking gesture.
///
/// Handles:
/// - Horizontal swipe detection and calculation
/// - Seek target position computation (physical distance-based: seconds/inch)
/// - Pause/resume video during seek
/// - Boundary enforcement (0 to duration)
class SeekGestureManager {
  /// Creates a seek gesture manager with dependency injection via callbacks.
  SeekGestureManager({
    required this.getCurrentPosition,
    required this.getDuration,
    required this.getIsPlaying,
    required this.seekSecondsPerInch,
    required this.setSeekTarget,
    required this.seekTo,
    required this.pause,
    required this.play,
    required this.onSeekGestureUpdate,
  });

  /// Gets the current playback position.
  final Duration Function() getCurrentPosition;

  /// Gets the video duration.
  final Duration Function() getDuration;

  /// Gets whether the video is currently playing.
  final bool Function() getIsPlaying;

  /// How many seconds to seek per inch of horizontal swipe.
  final double seekSecondsPerInch;

  /// Updates the seek target position (for seek preview overlay).
  final void Function(Duration?) setSeekTarget;

  /// Seeks to the specified position.
  final Future<void> Function(Duration) seekTo;

  /// Pauses playback.
  final Future<void> Function() pause;

  /// Resumes playback.
  final Future<void> Function() play;

  /// Optional external callback when seek gesture updates.
  final void Function(Duration?)? onSeekGestureUpdate;

  // Internal state
  Duration? _dragStartPosition;
  Duration? _seekTargetPosition;
  bool _wasPlayingBeforeSeek = false;

  /// Starts a seek gesture at the given position.
  void startSeek(Duration startPosition, {required bool isPlaying}) {
    _dragStartPosition = startPosition;
    _seekTargetPosition = startPosition;
    _wasPlayingBeforeSeek = isPlaying;

    // Pause playback if currently playing
    if (isPlaying) {
      unawaited(pause());
    }
  }

  /// Updates the seek position based on horizontal delta.
  void updateSeek(double deltaX, double screenWidth) {
    if (_dragStartPosition == null) return;

    // Horizontal drag - seek using physical distance (inches)
    // 160 logical pixels ≈ 1 inch in Flutter's density-independent system
    const pixelsPerInch = 160.0;
    final seekSeconds = deltaX * seekSecondsPerInch / pixelsPerInch;
    final seekAmount = Duration(milliseconds: (seekSeconds * 1000).round());
    final duration = getDuration();
    final newPosition = _dragStartPosition! + seekAmount;

    // Clamp to valid range [0, duration]
    final Duration targetPosition;
    if (newPosition < Duration.zero) {
      targetPosition = Duration.zero;
    } else if (newPosition > duration) {
      targetPosition = duration;
    } else {
      targetPosition = newPosition;
    }

    _seekTargetPosition = targetPosition;
    setSeekTarget(targetPosition);
    onSeekGestureUpdate?.call(targetPosition);
  }

  /// Ends the seek gesture and commits the seek.
  Future<void> endSeek() async {
    if (_seekTargetPosition == null) return;

    // Commit the seek
    await seekTo(_seekTargetPosition!);

    // Resume playback if it was playing before seek
    if (_wasPlayingBeforeSeek) {
      await play();
    }

    // Clear state
    _clearState();
  }

  /// Cancels the seek gesture without seeking.
  void cancelSeek() {
    if (_dragStartPosition == null) return; // No active seek

    // Resume playback if it was playing before seek (without seeking)
    if (_wasPlayingBeforeSeek) {
      unawaited(play());
    }

    // Clear state
    _clearState();
  }

  /// Clears internal state.
  void _clearState() {
    _dragStartPosition = null;
    _seekTargetPosition = null;
    _wasPlayingBeforeSeek = false;
    setSeekTarget(null);
    onSeekGestureUpdate?.call(null);
  }

  /// Disposes resources.
  void dispose() {
    // No timers or subscriptions to clean up
  }
}
