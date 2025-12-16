/// A single caption to show at a particular point in time.
///
/// This class is provided for compatibility with Flutter's video_player library.
/// For new code, prefer using SubtitleCue which provides more features.
class Caption {
  /// Creates a [Caption] with the given text and time range.
  const Caption({required this.text, this.start = Duration.zero, this.end = Duration.zero});

  /// A special caption that represents no caption (empty text).
  static const Caption none = Caption(text: '');

  /// The text to display for this caption.
  final String text;

  /// The time at which this caption should start displaying.
  final Duration start;

  /// The time at which this caption should stop displaying.
  final Duration end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Caption &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(text, start, end);

  @override
  String toString() => 'Caption(text: $text, start: $start, end: $end)';
}
