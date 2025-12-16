/// Describes a range of time.
///
/// This is used to represent buffered ranges in video playback.
/// For example, if a video has buffered from 0 to 30 seconds,
/// there would be one [DurationRange] with [start] = Duration.zero
/// and [end] = Duration(seconds: 30).
///
/// This class is provided for compatibility with Flutter's video_player library.
class DurationRange {
  /// Creates a [DurationRange] with the given start and end durations.
  const DurationRange(this.start, this.end);

  /// The start of the range.
  final Duration start;

  /// The end of the range.
  final Duration end;

  /// Returns the total duration of this range.
  Duration get duration => end - start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DurationRange && runtimeType == other.runtimeType && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DurationRange($start, $end)';
}
