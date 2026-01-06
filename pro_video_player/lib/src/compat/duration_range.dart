/// DurationRange for video_player API compatibility.
///
/// This class extends the platform_interface DurationRange with video_player-specific methods.
/// Import via `package:pro_video_player/video_player_compat.dart` for drop-in replacement.
library;

import 'package:flutter/foundation.dart';

import 'compat_annotation.dart';

/// Describes a discrete segment of time within a video.
///
/// [video_player compatibility] This class matches the video_player API exactly.
@immutable
@videoPlayerCompat
class DurationRange {
  /// Creates a [DurationRange] with the given start and end durations.
  const DurationRange(this.start, this.end);

  /// The start of the range.
  final Duration start;

  /// The end of the range.
  final Duration end;

  /// Calculates what fraction of the video the range starts at.
  ///
  /// Returns a value between 0.0 and 1.0 representing the percentage
  /// through the video where this range begins.
  ///
  /// [video_player compatibility] This method matches the video_player API exactly.
  @videoPlayerCompat
  double startFraction(Duration duration) {
    if (duration.inMilliseconds == 0) return 0;
    return start.inMilliseconds / duration.inMilliseconds;
  }

  /// Calculates what fraction of the video the range ends at.
  ///
  /// Returns a value between 0.0 and 1.0 representing the percentage
  /// through the video where this range ends.
  ///
  /// [video_player compatibility] This method matches the video_player API exactly.
  @videoPlayerCompat
  double endFraction(Duration duration) {
    if (duration.inMilliseconds == 0) return 0;
    return end.inMilliseconds / duration.inMilliseconds;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DurationRange && runtimeType == other.runtimeType && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DurationRange($start, $end)';
}
