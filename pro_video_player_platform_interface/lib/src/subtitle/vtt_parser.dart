import '../types/styled_text_span.dart';
import '../types/subtitle_cue.dart';
import 'subtitle_parser_base.dart';

/// Parser for WebVTT (.vtt) subtitle format.
///
/// WebVTT is the standard subtitle format for HTML5 video.
/// ```
/// WEBVTT
///
/// 00:00:01.000 --> 00:00:05.000
/// Subtitle text
///
/// 00:00:06.000 --> 00:00:10.000
/// Next subtitle
/// ```
class VttParser extends SubtitleParserBase {
  /// Creates a VTT parser.
  const VttParser();

  /// Pattern for VTT timestamp: HH:MM:SS.mmm or MM:SS.mmm or HH:MM:SS or MM:SS
  /// Accepts 0-3 digit milliseconds (e.g., "00:01:39", "00:01:41.04", or "00:01:41.040")
  static final _timestampPatternFull = RegExp(r'^(\d{2}):(\d{2}):(\d{2})(?:\.(\d{2,3}))?$');
  static final _timestampPatternShort = RegExp(r'^(\d{2}):(\d{2})(?:\.(\d{2,3}))?$');

  /// Pattern for the timing line: start --> end (with optional settings)
  static final _timingPattern = RegExp(
    r'^(\d{2}:\d{2}:\d{2}(?:\.\d{2,3})?|\d{2}:\d{2}(?:\.\d{2,3})?)\s*-->\s*(\d{2}:\d{2}:\d{2}(?:\.\d{2,3})?|\d{2}:\d{2}(?:\.\d{2,3})?)',
  );

  /// Pattern for VTT tags like <v Speaker>, <c.class>, timestamps
  static final _vttTagPattern = RegExp('<[^>]*>');

  /// Pattern for inline timestamps like <00:00:02.000>
  static final _inlineTimestamp = RegExp(r'<\d{2}:\d{2}(?::\d{2})?(?:\.\d{2,3})?>');

  @override
  List<SubtitleCue> parse(String content) {
    if (content.trim().isEmpty) return [];

    var processedContent = removeBom(content);
    processedContent = normalizeLineEndings(processedContent);

    // Split into blocks
    final blocks = processedContent.split(RegExp(r'\n\n+'));
    final cues = <SubtitleCue>[];
    var index = 0;

    for (final block in blocks) {
      final trimmed = block.trim();

      // Skip WEBVTT header, NOTE, STYLE, REGION blocks
      if (trimmed.isEmpty ||
          trimmed.startsWith('WEBVTT') ||
          trimmed.startsWith('NOTE') ||
          trimmed.startsWith('STYLE') ||
          trimmed.startsWith('REGION')) {
        continue;
      }

      final cue = _parseBlock(trimmed, index);
      if (cue != null) {
        cues.add(cue);
        index++;
      }
    }

    return cues;
  }

  SubtitleCue? _parseBlock(String block, int index) {
    final lines = block.split('\n');
    if (lines.isEmpty) return null;

    // Find the timing line
    var timingLineIndex = 0;
    String? timingLine;

    for (var i = 0; i < lines.length; i++) {
      if (_timingPattern.hasMatch(lines[i])) {
        timingLineIndex = i;
        timingLine = lines[i];
        break;
      }
    }

    if (timingLine == null) return null;

    final timingMatch = _timingPattern.firstMatch(timingLine)!;
    final start = parseTimestamp(timingMatch.group(1)!);
    final end = parseTimestamp(timingMatch.group(2)!);
    if (start == null || end == null) return null;

    // Remaining lines are the subtitle text
    final textLines = lines.sublist(timingLineIndex + 1);
    if (textLines.isEmpty) return null;

    var rawText = textLines.join('\n').trim();
    // Remove inline timestamps first
    rawText = rawText.replaceAll(_inlineTimestamp, '');

    if (rawText.isEmpty) return null;

    // Parse styled spans and plain text
    final styledSpans = _parseStyledText(rawText);
    final plainText = _stripVttTags(rawText);

    if (plainText.isEmpty) return null;

    return SubtitleCue(
      index: index,
      start: start,
      end: end,
      text: plainText,
      styledSpans: styledSpans.isNotEmpty ? styledSpans : null,
    );
  }

  String _stripVttTags(String text) {
    // Remove inline timestamps first
    var result = text.replaceAll(_inlineTimestamp, '');
    // Remove all VTT tags
    result = result.replaceAll(_vttTagPattern, '');
    // Clean up extra whitespace
    return result.replaceAll(RegExp(' +'), ' ').trim();
  }

  /// Parses VTT text with styling tags into styled spans.
  ///
  /// Supports: `<b>`, `<i>`, `<u>` tags (including nested).
  /// Tags like `<v Speaker>`, `<c.class>`, `<lang>` are stripped.
  List<StyledTextSpan> _parseStyledText(String text) {
    final spans = <StyledTextSpan>[];
    final styleStack = <String>[];
    var currentText = StringBuffer();
    var i = 0;

    while (i < text.length) {
      if (text[i] == '<') {
        // Find closing >
        final closeIndex = text.indexOf('>', i);
        if (closeIndex == -1) {
          currentText.write(text[i]);
          i++;
          continue;
        }

        final tag = text.substring(i + 1, closeIndex).toLowerCase();

        // Flush current text before style change
        if (currentText.isNotEmpty) {
          spans.add(_createSpan(currentText.toString(), styleStack));
          currentText = StringBuffer();
        }

        // Handle opening/closing tags
        if (tag == 'b' || tag == 'i' || tag == 'u') {
          styleStack.add(tag);
        } else if (tag == '/b' || tag == '/i' || tag == '/u') {
          final openTag = tag.substring(1);
          // Remove the most recent matching tag
          for (var j = styleStack.length - 1; j >= 0; j--) {
            if (styleStack[j] == openTag) {
              styleStack.removeAt(j);
              break;
            }
          }
        }
        // Skip other tags like <v>, <c>, <lang>, etc.

        i = closeIndex + 1;
      } else {
        currentText.write(text[i]);
        i++;
      }
    }

    // Flush remaining text
    if (currentText.isNotEmpty) {
      spans.add(_createSpan(currentText.toString(), styleStack));
    }

    return spans;
  }

  /// Creates a styled span from text and active style tags.
  StyledTextSpan _createSpan(String text, List<String> activeTags) {
    if (activeTags.isEmpty) {
      return StyledTextSpan.plain(text);
    }

    final style = SubtitleTextStyle(
      isBold: activeTags.contains('b'),
      isItalic: activeTags.contains('i'),
      isUnderline: activeTags.contains('u'),
    );

    return StyledTextSpan(text: text, style: style);
  }

  /// Parses a VTT timestamp string to a [Duration].
  ///
  /// Accepts formats: HH:MM:SS.mmm, MM:SS.mmm, HH:MM:SS, or MM:SS
  /// Supports 0-3 digit milliseconds (e.g., "00:01:39", "04" is treated as "040" = 40ms)
  /// Returns `null` if the timestamp is invalid.
  static Duration? parseTimestamp(String timestamp) {
    final trimmedTimestamp = timestamp.trim();

    // Try full format first: HH:MM:SS.mmm or HH:MM:SS
    var match = _timestampPatternFull.firstMatch(trimmedTimestamp);
    if (match != null) {
      final millisecondsStr = match.group(4);
      return Duration(
        hours: int.parse(match.group(1)!),
        minutes: int.parse(match.group(2)!),
        seconds: int.parse(match.group(3)!),
        milliseconds: millisecondsStr != null ? _parseMilliseconds(millisecondsStr) : 0,
      );
    }

    // Try short format: MM:SS.mmm or MM:SS
    match = _timestampPatternShort.firstMatch(trimmedTimestamp);
    if (match != null) {
      final millisecondsStr = match.group(3);
      return Duration(
        minutes: int.parse(match.group(1)!),
        seconds: int.parse(match.group(2)!),
        milliseconds: millisecondsStr != null ? _parseMilliseconds(millisecondsStr) : 0,
      );
    }

    return null;
  }

  /// Parses milliseconds from a 2-3 digit string, padding 2 digits to 3.
  /// E.g., "04" -> 40, "040" -> 40, "123" -> 123
  static int _parseMilliseconds(String str) {
    // Pad 2-digit milliseconds to 3 digits (e.g., "04" -> "040")
    final paddedStr = str.length == 2 ? '${str}0' : str;
    return int.parse(paddedStr);
  }
}
