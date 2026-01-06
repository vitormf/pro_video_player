/// VideoPlayerValue for video_player API compatibility.
///
/// This class provides the exact video_player API signature for compatibility.
/// Import via `package:pro_video_player/video_player_compat.dart` for drop-in replacement.
library;

import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

import 'caption.dart';
import 'compat_annotation.dart';
import 'duration_range.dart';

/// The current state of a video player.
///
/// [video_player compatibility] This class matches the video_player API exactly.
@immutable
@videoPlayerCompat
class VideoPlayerValue {
  /// Creates a VideoPlayerValue with the given properties.
  ///
  /// This is the main constructor matching video_player's signature.
  @videoPlayerCompat
  const VideoPlayerValue({
    required this.duration,
    this.size = Size.zero,
    this.position = Duration.zero,
    this.caption = Caption.none,
    this.captionOffset = Duration.zero,
    this.buffered = const <DurationRange>[],
    this.isInitialized = false,
    this.isPlaying = false,
    this.isLooping = false,
    this.isBuffering = false,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.rotationCorrection = 0,
    this.errorDescription,
  });

  /// Creates a VideoPlayerValue in the uninitialized state.
  ///
  /// [video_player compatibility] This named constructor matches video_player exactly.
  @videoPlayerCompat
  const VideoPlayerValue.uninitialized()
    : duration = Duration.zero,
      size = Size.zero,
      position = Duration.zero,
      caption = Caption.none,
      captionOffset = Duration.zero,
      buffered = const <DurationRange>[],
      isInitialized = false,
      isPlaying = false,
      isLooping = false,
      isBuffering = false,
      volume = 1.0,
      playbackSpeed = 1.0,
      rotationCorrection = 0,
      errorDescription = null;

  /// Creates a VideoPlayerValue in an error state.
  ///
  /// [video_player compatibility] This named constructor matches video_player exactly.
  @videoPlayerCompat
  const VideoPlayerValue.erroneous(this.errorDescription)
    : duration = Duration.zero,
      size = Size.zero,
      position = Duration.zero,
      caption = Caption.none,
      captionOffset = Duration.zero,
      buffered = const <DurationRange>[],
      isInitialized = false,
      isPlaying = false,
      isLooping = false,
      isBuffering = false,
      volume = 1.0,
      playbackSpeed = 1.0,
      rotationCorrection = 0;

  /// The total duration of the video.
  final Duration duration;

  /// The dimensions of the video.
  final Size size;

  /// The current playback position.
  final Duration position;

  /// The current caption to display.
  final Caption caption;

  /// The offset applied to caption timing.
  ///
  /// Positive values delay captions, negative values show them earlier.
  final Duration captionOffset;

  /// The ranges of the video that have been buffered.
  final List<DurationRange> buffered;

  /// Whether the video has been loaded and is ready to play.
  final bool isInitialized;

  /// Whether the video is currently playing.
  final bool isPlaying;

  /// Whether the video will loop when it reaches the end.
  final bool isLooping;

  /// Whether the video is currently buffering.
  final bool isBuffering;

  /// The current volume level (0.0 to 1.0).
  final double volume;

  /// The current playback speed.
  final double playbackSpeed;

  /// Clockwise rotation in degrees for the video.
  ///
  /// This is typically 0, 90, 180, or 270.
  final int rotationCorrection;

  /// A description of the current error, if any.
  final String? errorDescription;

  /// Whether the video has an error.
  bool get hasError => errorDescription != null;

  /// Whether the video has finished playing.
  ///
  /// [video_player compatibility] This property matches video_player exactly.
  @videoPlayerCompat
  bool get isCompleted => position >= duration && duration > Duration.zero;

  /// The aspect ratio of the video.
  ///
  /// Returns 1.0 if the size is not available.
  double get aspectRatio {
    if (size.height == 0) return 1;
    return size.width / size.height;
  }

  /// Creates a copy of this value with the given fields replaced.
  @videoPlayerCompat
  VideoPlayerValue copyWith({
    Duration? duration,
    Size? size,
    Duration? position,
    Caption? caption,
    Duration? captionOffset,
    List<DurationRange>? buffered,
    bool? isInitialized,
    bool? isPlaying,
    bool? isLooping,
    bool? isBuffering,
    double? volume,
    double? playbackSpeed,
    int? rotationCorrection,
    String? errorDescription,
  }) => VideoPlayerValue(
    duration: duration ?? this.duration,
    size: size ?? this.size,
    position: position ?? this.position,
    caption: caption ?? this.caption,
    captionOffset: captionOffset ?? this.captionOffset,
    buffered: buffered ?? this.buffered,
    isInitialized: isInitialized ?? this.isInitialized,
    isPlaying: isPlaying ?? this.isPlaying,
    isLooping: isLooping ?? this.isLooping,
    isBuffering: isBuffering ?? this.isBuffering,
    volume: volume ?? this.volume,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    rotationCorrection: rotationCorrection ?? this.rotationCorrection,
    errorDescription: errorDescription ?? this.errorDescription,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoPlayerValue &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          size == other.size &&
          position == other.position &&
          caption == other.caption &&
          captionOffset == other.captionOffset &&
          _listEquals(buffered, other.buffered) &&
          isInitialized == other.isInitialized &&
          isPlaying == other.isPlaying &&
          isLooping == other.isLooping &&
          isBuffering == other.isBuffering &&
          volume == other.volume &&
          playbackSpeed == other.playbackSpeed &&
          rotationCorrection == other.rotationCorrection &&
          errorDescription == other.errorDescription;

  @override
  int get hashCode => Object.hash(
    duration,
    size,
    position,
    caption,
    captionOffset,
    Object.hashAll(buffered),
    isInitialized,
    isPlaying,
    isLooping,
    isBuffering,
    volume,
    playbackSpeed,
    rotationCorrection,
    errorDescription,
  );

  @override
  String toString() =>
      'VideoPlayerValue('
      'duration: $duration, '
      'size: $size, '
      'position: $position, '
      'caption: $caption, '
      'captionOffset: $captionOffset, '
      'buffered: ${buffered.length} ranges, '
      'isInitialized: $isInitialized, '
      'isPlaying: $isPlaying, '
      'isLooping: $isLooping, '
      'isBuffering: $isBuffering, '
      'volume: $volume, '
      'playbackSpeed: $playbackSpeed, '
      'rotationCorrection: $rotationCorrection, '
      'errorDescription: $errorDescription'
      ')';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
