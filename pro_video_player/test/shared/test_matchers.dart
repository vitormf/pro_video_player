import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

/// Custom matchers for domain-specific assertions.
///
/// These matchers make tests more readable and provide better error messages.
///
/// Example:
/// ```dart
/// // ❌ BAD: Verbose and unclear error messages
/// expect(controller.value.playbackState, PlaybackState.playing);
///
/// // ✅ GOOD: Concise and clear error messages
/// expect(controller, isPlaying);
/// ```

/// Matches a controller in playing state.
///
/// Example:
/// ```dart
/// await controller.play();
/// expect(controller, isPlaying);
/// ```
const Matcher isPlaying = _IsInPlaybackState(PlaybackState.playing);

/// Matches a controller in paused state.
///
/// Example:
/// ```dart
/// await controller.pause();
/// expect(controller, isPaused);
/// ```
const Matcher isPaused = _IsInPlaybackState(PlaybackState.paused);

/// Matches a controller in buffering state.
///
/// Example:
/// ```dart
/// expect(controller, isBuffering);
/// ```
const Matcher isBuffering = _IsInPlaybackState(PlaybackState.buffering);

/// Matches a controller in completed state.
///
/// Example:
/// ```dart
/// // Wait for video to complete
/// expect(controller, isCompleted);
/// ```
const Matcher isCompleted = _IsInPlaybackState(PlaybackState.completed);

/// Matches a controller in uninitialized state.
///
/// Example:
/// ```dart
/// final controller = ProVideoPlayerController();
/// expect(controller, isUninitialized);
/// ```
const Matcher isUninitialized = _IsInPlaybackState(PlaybackState.uninitialized);

/// Matches a controller in ready state.
///
/// Example:
/// ```dart
/// await controller.initialize(source: VideoSource.network('...'));
/// expect(controller, isReady);
/// ```
const Matcher isReady = _IsInPlaybackState(PlaybackState.ready);

/// Matches a controller in error state.
///
/// Example:
/// ```dart
/// // After initialization failure
/// expect(controller, hasError);
/// ```
const Matcher hasError = _IsInPlaybackState(PlaybackState.error);

/// Matches a controller in fullscreen mode.
///
/// Example:
/// ```dart
/// await controller.enterFullscreen();
/// expect(controller, isInFullscreen);
/// ```
const Matcher isInFullscreen = _IsInFullscreen();

/// Matches a controller not in fullscreen mode.
///
/// Example:
/// ```dart
/// await controller.exitFullscreen();
/// expect(controller, isNotInFullscreen);
/// ```
const Matcher isNotInFullscreen = _IsNotInFullscreen();

/// Matches a controller in PiP mode.
///
/// Example:
/// ```dart
/// await controller.enterPip();
/// expect(controller, isInPip);
/// ```
const Matcher isInPip = _IsInPip();

/// Matches a controller not in PiP mode.
///
/// Example:
/// ```dart
/// await controller.exitPip();
/// expect(controller, isNotInPip);
/// ```
const Matcher isNotInPip = _IsNotInPip();

/// Matches a controller at a specific position (with tolerance).
///
/// Allows for small timing variations (±100ms tolerance by default).
///
/// Example:
/// ```dart
/// await controller.seekTo(const Duration(minutes: 2));
/// expect(controller, hasPosition(const Duration(minutes: 2)));
///
/// // With custom tolerance
/// expect(controller, hasPosition(const Duration(minutes: 2), tolerance: const Duration(milliseconds: 50)));
/// ```
Matcher hasPosition(Duration expected, {Duration tolerance = const Duration(milliseconds: 100)}) =>
    _HasPosition(expected, tolerance);

/// Matches a controller with a specific duration.
///
/// Example:
/// ```dart
/// expect(controller, hasDuration(const Duration(minutes: 5)));
/// ```
Matcher hasDuration(Duration expected) => _HasDuration(expected);

/// Matches a controller with a specific playback speed.
///
/// Example:
/// ```dart
/// await controller.setPlaybackSpeed(1.5);
/// expect(controller, hasSpeed(1.5));
/// ```
Matcher hasSpeed(double expected) => _HasSpeed(expected);

/// Matches a controller with a specific volume.
///
/// Example:
/// ```dart
/// await controller.setVolume(0.5);
/// expect(controller, hasVolume(0.5));
/// ```
Matcher hasVolume(double expected) => _HasVolume(expected);

/// Matches a controller with looping enabled.
///
/// Example:
/// ```dart
/// await controller.setLooping(true);
/// expect(controller, isLooping);
/// ```
const Matcher isLooping = _IsLooping();

/// Matches a controller with looping disabled.
///
/// Example:
/// ```dart
/// await controller.setLooping(false);
/// expect(controller, isNotLooping);
/// ```
const Matcher isNotLooping = _IsNotLooping();

/// Matches a controller that is initialized.
///
/// Example:
/// ```dart
/// await controller.initialize(source: VideoSource.network('...'));
/// expect(controller, isInitialized);
/// ```
const Matcher isInitialized = _IsInitialized();

/// Matches a controller that is not initialized.
///
/// Example:
/// ```dart
/// final controller = ProVideoPlayerController();
/// expect(controller, isNotInitialized);
/// ```
const Matcher isNotInitialized = _IsNotInitialized();

/// Matches a controller that is disposed.
///
/// Example:
/// ```dart
/// await controller.dispose();
/// expect(controller, isDisposed);
/// ```
const Matcher isDisposed = _IsDisposed();

/// Matches a controller that is not disposed.
///
/// Example:
/// ```dart
/// final controller = ProVideoPlayerController();
/// expect(controller, isNotDisposed);
/// ```
const Matcher isNotDisposed = _IsNotDisposed();

// Implementation classes

class _IsInPlaybackState extends Matcher {
  const _IsInPlaybackState(this.expectedState);

  final PlaybackState expectedState;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return item.value.playbackState == expectedState;
  }

  @override
  Description describe(Description description) => description.add('is in $expectedState state');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('is in ${item.value.playbackState} state');
  }
}

class _IsInFullscreen extends Matcher {
  const _IsInFullscreen();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return item.value.isFullscreen;
  }

  @override
  Description describe(Description description) => description.add('is in fullscreen mode');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('is not in fullscreen mode');
  }
}

class _IsNotInFullscreen extends Matcher {
  const _IsNotInFullscreen();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return !item.value.isFullscreen;
  }

  @override
  Description describe(Description description) => description.add('is not in fullscreen mode');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('is in fullscreen mode');
  }
}

class _IsInPip extends Matcher {
  const _IsInPip();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return item.value.isPipActive;
  }

  @override
  Description describe(Description description) => description.add('is in PiP mode');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('is not in PiP mode');
  }
}

class _IsNotInPip extends Matcher {
  const _IsNotInPip();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return !item.value.isPipActive;
  }

  @override
  Description describe(Description description) => description.add('is not in PiP mode');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('is in PiP mode');
  }
}

class _HasPosition extends Matcher {
  const _HasPosition(this.expected, this.tolerance);

  final Duration expected;
  final Duration tolerance;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    final actual = item.value.position;
    final difference = (actual - expected).abs();
    return difference <= tolerance;
  }

  @override
  Description describe(Description description) => description.add('has position $expected (±$tolerance)');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    final actual = item.value.position;
    final difference = (actual - expected).abs();
    return mismatchDescription.add('has position $actual (difference: $difference)');
  }
}

class _HasDuration extends Matcher {
  const _HasDuration(this.expected);

  final Duration expected;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return item.value.duration == expected;
  }

  @override
  Description describe(Description description) => description.add('has duration $expected');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('has duration ${item.value.duration}');
  }
}

class _HasSpeed extends Matcher {
  const _HasSpeed(this.expected);

  final double expected;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return item.value.playbackSpeed == expected;
  }

  @override
  Description describe(Description description) => description.add('has playback speed $expected');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('has playback speed ${item.value.playbackSpeed}');
  }
}

class _HasVolume extends Matcher {
  const _HasVolume(this.expected);

  final double expected;

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return item.value.volume == expected;
  }

  @override
  Description describe(Description description) => description.add('has volume $expected');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('has volume ${item.value.volume}');
  }
}

class _IsLooping extends Matcher {
  const _IsLooping();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return item.value.isLooping;
  }

  @override
  Description describe(Description description) => description.add('has looping enabled');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('has looping disabled');
  }
}

class _IsNotLooping extends Matcher {
  const _IsNotLooping();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return !item.value.isLooping;
  }

  @override
  Description describe(Description description) => description.add('has looping disabled');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('has looping enabled');
  }
}

class _IsInitialized extends Matcher {
  const _IsInitialized();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return item.value.isInitialized;
  }

  @override
  Description describe(Description description) => description.add('is initialized');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('is not initialized');
  }
}

class _IsNotInitialized extends Matcher {
  const _IsNotInitialized();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return !item.value.isInitialized;
  }

  @override
  Description describe(Description description) => description.add('is not initialized');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('is initialized');
  }
}

class _IsDisposed extends Matcher {
  const _IsDisposed();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return item.isDisposed;
  }

  @override
  Description describe(Description description) => description.add('is disposed');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('is not disposed');
  }
}

class _IsNotDisposed extends Matcher {
  const _IsNotDisposed();

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! ProVideoPlayerController) return false;
    return !item.isDisposed;
  }

  @override
  Description describe(Description description) => description.add('is not disposed');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! ProVideoPlayerController) {
      return mismatchDescription.add('is not a ProVideoPlayerController');
    }
    return mismatchDescription.add('is disposed');
  }
}
