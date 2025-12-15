import '../types/styled_text_span.dart';
import '../types/subtitle_cue.dart';

/// Converts subtitle cues to WebVTT format.
///
/// WebVTT (Web Video Text Tracks) is the standard subtitle format
/// for HTML5 video and is supported natively by most platforms.
///
/// This converter is used to convert other subtitle formats (SRT, SSA, TTML)
/// to WebVTT when using native rendering mode, allowing all formats to work
/// on platforms that only support WebVTT natively (like iOS/macOS).
///
/// ## Supported Styling
///
/// WebVTT supports basic text styling tags:
/// - `<b>...</b>` - Bold text
/// - `<i>...</i>` - Italic text
/// - `<u>...</u>` - Underlined text
///
/// Advanced styling (colors, fonts, positions) from SSA/ASS and TTML
/// is not preserved in the conversion, as WebVTT's basic tags don't
/// support these features.
///
/// Example:
/// ```dart
/// final cues = SubtitleParser.parse(srtContent, SubtitleFormat.srt);
/// final webvtt = WebVttConverter.convert(cues);
/// // webvtt is now a WebVTT-formatted string ready for native players
/// ```
class WebVttConverter {
  /// Private constructor - use static methods.
  const WebVttConverter._();

  /// Converts a list of subtitle cues to WebVTT format.
  ///
  /// Returns a complete WebVTT file content as a string, including
  /// the WEBVTT header and all cues with timestamps and text.
  ///
  /// If [cues] is empty, returns a minimal WebVTT file with just the header.
  static String convert(List<SubtitleCue> cues) {
    final buffer = StringBuffer()..writeln('WEBVTT'); // WebVTT header

    // Convert each cue
    for (final cue in cues) {
      buffer
        ..writeln() // Blank line before each cue
        // Timestamp line
        ..write(formatTimestamp(cue.start))
        ..write(' --> ')
        ..writeln(formatTimestamp(cue.end));

      // Text content (with or without styling)
      if (cue.hasStyledSpans) {
        buffer.writeln(_convertStyledText(cue.styledSpans!));
      } else {
        buffer.writeln(cue.text);
      }
    }

    return buffer.toString();
  }

  /// Converts styled text spans to WebVTT format with tags.
  ///
  /// Converts rich text spans with styling to WebVTT-compatible tags.
  /// Only supports basic styling (bold, italic, underline) as WebVTT
  /// doesn't support advanced features like colors or custom fonts.
  static String _convertStyledText(List<StyledTextSpan> spans) {
    final buffer = StringBuffer();

    for (final span in spans) {
      var text = span.text;
      final style = span.style;

      // Apply supported WebVTT tags in reverse order to get proper nesting
      // Final result: <b><i><u>text</u></i></b>
      if (style?.isUnderline ?? false) {
        text = '<u>$text</u>';
      }
      if (style?.isItalic ?? false) {
        text = '<i>$text</i>';
      }
      if (style?.isBold ?? false) {
        text = '<b>$text</b>';
      }

      buffer.write(text);
    }

    return buffer.toString();
  }

  /// Formats a duration as a WebVTT timestamp.
  ///
  /// WebVTT uses the format: HH:MM:SS.mmm
  /// Example: 01:23:45.678
  ///
  /// Hours, minutes, seconds, and milliseconds are zero-padded.
  static String formatTimestamp(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${milliseconds.toString().padLeft(3, '0')}';
  }
}
