import 'styled_text_span.dart';

/// A single subtitle cue with timing and text.
///
/// Represents one subtitle entry with start and end times,
/// and the text to display. Used for both embedded and
/// external subtitle tracks.
///
/// ## Rich Text Support
///
/// For subtitle formats that support styling (WebVTT, SSA/ASS, TTML),
/// the [styledSpans] field contains the text broken into styled segments.
/// When rendering, use [styledSpans] if available, otherwise fall back to [text].
///
/// Example with styling:
/// ```dart
/// // SSA subtitle: "Hello {\b1}world{\b0}!"
/// SubtitleCue(
///   start: Duration.zero,
///   end: Duration(seconds: 5),
///   text: 'Hello world!',  // Plain text fallback
///   styledSpans: [
///     StyledTextSpan.plain('Hello '),
///     StyledTextSpan(text: 'world', style: SubtitleTextStyle(isBold: true)),
///     StyledTextSpan.plain('!'),
///   ],
/// )
/// ```
class SubtitleCue {
  /// Creates a subtitle cue.
  ///
  /// The [start] and [end] define the time range when this
  /// cue should be displayed. The [text] is the subtitle content.
  /// The optional [index] is the cue number in the subtitle file.
  /// The optional [styledSpans] contains rich text formatting.
  const SubtitleCue({required this.start, required this.end, required this.text, this.index, this.styledSpans});

  /// Creates a subtitle cue from a map.
  ///
  /// Used for deserializing cues from method channels.
  factory SubtitleCue.fromMap(Map<dynamic, dynamic> map) => SubtitleCue(
    index: map['index'] as int?,
    start: Duration(milliseconds: map['startMs'] as int),
    end: Duration(milliseconds: map['endMs'] as int),
    text: map['text'] as String,
  );

  /// The cue index/number in the subtitle file.
  ///
  /// This is optional as not all subtitle formats use numbering.
  final int? index;

  /// The start time when this cue should appear.
  final Duration start;

  /// The end time when this cue should disappear.
  final Duration end;

  /// The subtitle text content.
  ///
  /// May contain multiple lines separated by newlines.
  final String text;

  /// Rich text spans with styling information.
  ///
  /// For subtitle formats that support styling (WebVTT, SSA/ASS, TTML),
  /// this contains the text broken into styled segments. When rendering,
  /// use [styledSpans] if available, otherwise fall back to [text].
  ///
  /// This is null for plain text subtitles or formats without styling.
  final List<StyledTextSpan>? styledSpans;

  /// The duration this cue is displayed.
  Duration get duration => end - start;

  /// Whether this cue is active at the given [position].
  ///
  /// Returns `true` if [position] is >= [start] and < [end].
  bool isActiveAt(Duration position) => position >= start && position < end;

  /// Converts this cue to a map for serialization.
  ///
  /// Used for sending cues over method channels.
  Map<String, dynamic> toMap() => {
    if (index != null) 'index': index,
    'startMs': start.inMilliseconds,
    'endMs': end.inMilliseconds,
    'text': text,
  };

  /// Whether this cue has rich text styling.
  bool get hasStyledSpans => styledSpans != null && styledSpans!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SubtitleCue) return false;
    if (index != other.index || start != other.start || end != other.end || text != other.text) {
      return false;
    }
    // Compare styledSpans
    if (styledSpans == null && other.styledSpans == null) return true;
    if (styledSpans == null || other.styledSpans == null) return false;
    if (styledSpans!.length != other.styledSpans!.length) return false;
    for (var i = 0; i < styledSpans!.length; i++) {
      if (styledSpans![i] != other.styledSpans![i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(index, start, end, text, styledSpans != null ? Object.hashAll(styledSpans!) : null);

  @override
  String toString() =>
      'SubtitleCue(index: $index, start: $start, end: $end, text: $text, hasStyledSpans: $hasStyledSpans)';
}
