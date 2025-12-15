import 'dart:ui' show Color;

import '../types/styled_text_span.dart';
import '../types/subtitle_cue.dart';
import 'subtitle_parser_base.dart';

/// Parser for Timed Text Markup Language (.ttml) subtitle format.
///
/// TTML is an XML-based format used in broadcast and streaming.
/// ```xml
/// <tt xmlns="http://www.w3.org/ns/ttml">
///   <body>
///     <div>
///       <p begin="00:00:01.000" end="00:00:05.000">Subtitle text</p>
///     </div>
///   </body>
/// </tt>
/// ```
class TtmlParser extends SubtitleParserBase {
  /// Creates a TTML parser.
  const TtmlParser();

  /// Default frame rate for SMPTE timestamps
  static const _defaultFrameRate = 25;

  /// Pattern for timestamp with colons: HH:MM:SS.mmm
  static final _colonTimestampMs = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})\.(\d+)$');

  /// Pattern for frame-based timestamp: HH:MM:SS:FF
  static final _colonTimestampFrame = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2}):(\d+)$');

  /// Pattern for timestamp without fraction: HH:MM:SS
  static final _colonTimestampSimple = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})$');

  /// Pattern for seconds format: 1.5s
  static final _secondsTimestamp = RegExp(r'^([\d.]+)s$');

  /// Pattern for milliseconds format: 1500ms
  static final _msTimestamp = RegExp(r'^(\d+)ms$');

  /// Pattern to find begin attribute
  static final _beginAttrPattern = RegExp(r'begin\s*=\s*"([^"]+)"', caseSensitive: false);

  /// Pattern to find end attribute
  static final _endAttrPattern = RegExp(r'end\s*=\s*"([^"]+)"', caseSensitive: false);

  /// Pattern to find dur attribute
  static final _durAttrPattern = RegExp(r'dur\s*=\s*"([^"]+)"', caseSensitive: false);

  /// Pattern to find <p> elements with content
  static final _pElementPattern = RegExp(r'<p\s[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true);

  /// Pattern for <br/> or <br> elements
  static final _brPattern = RegExp(r'<br\s*/?\s*>', caseSensitive: false);

  /// Pattern for frameRate attribute
  static final _frameRatePattern = RegExp('frameRate\\s*=\\s*["\']([0-9]+)["\']');

  @override
  List<SubtitleCue> parse(String content) {
    if (content.trim().isEmpty) return [];

    var processedContent = removeBom(content);
    processedContent = normalizeLineEndings(processedContent);

    // Extract frame rate if specified
    final frameRate = _extractFrameRate(processedContent);

    final cues = <SubtitleCue>[];
    var index = 0;

    // Find all <p> elements
    final pMatches = _pElementPattern.allMatches(processedContent);

    for (final pMatch in pMatches) {
      final fullTag = pMatch.group(0)!;
      final textContent = pMatch.group(1) ?? '';

      // Extract begin attribute
      final beginMatch = _beginAttrPattern.firstMatch(fullTag);
      if (beginMatch == null) continue;
      final beginStr = beginMatch.group(1)!;

      // Extract end or dur attribute
      final endMatch = _endAttrPattern.firstMatch(fullTag);
      final durMatch = _durAttrPattern.firstMatch(fullTag);

      final start = parseTimestamp(beginStr, frameRate: frameRate);
      if (start == null) continue;

      Duration? end;
      if (endMatch != null) {
        end = parseTimestamp(endMatch.group(1)!, frameRate: frameRate);
      } else if (durMatch != null) {
        final duration = parseTimestamp(durMatch.group(1)!, frameRate: frameRate);
        if (duration != null) {
          end = start + duration;
        }
      }

      if (end == null) continue;

      // Extract text content and styled spans
      final text = _extractText(textContent);

      if (text.isEmpty) continue;

      // Parse styled spans from content
      final styledSpans = _parseStyledText(fullTag, textContent);

      cues.add(
        SubtitleCue(
          index: index,
          start: start,
          end: end,
          text: text,
          styledSpans: styledSpans.isNotEmpty ? styledSpans : null,
        ),
      );
      index++;
    }

    return cues;
  }

  int _extractFrameRate(String content) {
    final match = _frameRatePattern.firstMatch(content);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? _defaultFrameRate;
    }
    return _defaultFrameRate;
  }

  String _extractText(String content) {
    // Replace <br/> with newlines
    var result = content.replaceAll(_brPattern, '\n');
    // Strip all remaining tags
    result = stripTags(result);
    // Collapse horizontal whitespace (spaces/tabs) but preserve newlines
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
    // Clean up whitespace around newlines
    result = result.replaceAll(RegExp(r' *\n *'), '\n');
    return result.trim();
  }

  /// Parses TTML content into styled spans.
  ///
  /// Supports TTML styling attributes:
  /// - `tts:fontWeight="bold"`
  /// - `tts:fontStyle="italic"`
  /// - `tts:textDecoration="underline"` or `"lineThrough"`
  /// - `tts:color="#RRGGBB"` or named colors
  /// - `tts:fontSize="20px"`
  List<StyledTextSpan> _parseStyledText(String pTag, String content) {
    final spans = <StyledTextSpan>[];

    // Extract base style from <p> tag attributes
    final baseStyle = _extractStyleFromAttributes(pTag);

    // Pattern to find <span> elements
    final spanPattern = RegExp(r'<span\s*([^>]*)>(.*?)</span>', caseSensitive: false, dotAll: true);

    var lastEnd = 0;
    for (final match in spanPattern.allMatches(content)) {
      // Add text before span with base style
      if (match.start > lastEnd) {
        final beforeText = _cleanInlineText(content.substring(lastEnd, match.start));
        if (beforeText.isNotEmpty) {
          spans.add(_createSpan(beforeText, baseStyle));
        }
      }

      // Extract span attributes and text
      final spanAttrs = match.group(1) ?? '';
      final spanText = _cleanInlineText(match.group(2) ?? '');

      if (spanText.isNotEmpty) {
        // Merge span style with base style
        final spanStyle = _extractStyleFromAttributes(spanAttrs);
        final mergedStyle = baseStyle.merge(spanStyle);
        spans.add(_createSpan(spanText, mergedStyle));
      }

      lastEnd = match.end;
    }

    // Add remaining text after last span
    if (lastEnd < content.length) {
      final afterText = _cleanInlineText(content.substring(lastEnd));
      if (afterText.isNotEmpty) {
        spans.add(_createSpan(afterText, baseStyle));
      }
    }

    // If no spans were created and we have base styling, create one span with all text
    if (spans.isEmpty && baseStyle.hasFormatting) {
      final allText = _extractText(content);
      if (allText.isNotEmpty) {
        spans.add(_createSpan(allText, baseStyle));
      }
    }

    return spans;
  }

  /// Cleans inline text (removes tags, normalizes whitespace).
  String _cleanInlineText(String text) {
    var result = text.replaceAll(_brPattern, '\n');
    result = stripTags(result);
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
    return result.trim();
  }

  /// Extracts style from TTML attributes.
  SubtitleTextStyle _extractStyleFromAttributes(String attributes) {
    var isBold = false;
    var isItalic = false;
    var isUnderline = false;
    var isStrikethrough = false;
    Color? color;
    double? fontSize;

    // Check for fontWeight="bold"
    final fontWeightMatch = RegExp(r'tts:fontWeight\s*=\s*"([^"]+)"', caseSensitive: false).firstMatch(attributes);
    if (fontWeightMatch != null) {
      isBold = fontWeightMatch.group(1)!.toLowerCase() == 'bold';
    }

    // Check for fontStyle="italic"
    final fontStyleMatch = RegExp(r'tts:fontStyle\s*=\s*"([^"]+)"', caseSensitive: false).firstMatch(attributes);
    if (fontStyleMatch != null) {
      isItalic = fontStyleMatch.group(1)!.toLowerCase() == 'italic';
    }

    // Check for textDecoration="underline" or "lineThrough"
    final textDecorationMatch = RegExp(
      r'tts:textDecoration\s*=\s*"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(attributes);
    if (textDecorationMatch != null) {
      final decoration = textDecorationMatch.group(1)!.toLowerCase();
      isUnderline = decoration.contains('underline');
      isStrikethrough = decoration.contains('linethrough');
    }

    // Check for color="#RRGGBB" or named colors
    final colorMatch = RegExp(r'tts:color\s*=\s*"([^"]+)"', caseSensitive: false).firstMatch(attributes);
    if (colorMatch != null) {
      color = _parseTtmlColor(colorMatch.group(1)!);
    }

    // Check for fontSize="20px" or "20"
    final fontSizeMatch = RegExp(r'tts:fontSize\s*=\s*"([^"]+)"', caseSensitive: false).firstMatch(attributes);
    if (fontSizeMatch != null) {
      final sizeStr = fontSizeMatch.group(1)!.replaceAll(RegExp('[^0-9.]'), '');
      fontSize = double.tryParse(sizeStr);
    }

    return SubtitleTextStyle(
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrikethrough: isStrikethrough,
      color: color,
      fontSize: fontSize,
    );
  }

  /// Parses TTML color value to Color.
  Color? _parseTtmlColor(String colorStr) {
    final trimmed = colorStr.trim().toLowerCase();

    // Named colors
    const namedColors = {
      'white': Color(0xFFFFFFFF),
      'black': Color(0xFF000000),
      'red': Color(0xFFFF0000),
      'green': Color(0xFF00FF00),
      'blue': Color(0xFF0000FF),
      'yellow': Color(0xFFFFFF00),
      'cyan': Color(0xFF00FFFF),
      'magenta': Color(0xFFFF00FF),
    };

    if (namedColors.containsKey(trimmed)) {
      return namedColors[trimmed];
    }

    // Hex color: #RRGGBB or #AARRGGBB
    if (trimmed.startsWith('#')) {
      final hex = trimmed.substring(1);
      try {
        if (hex.length == 6) {
          final value = int.parse(hex, radix: 16);
          return Color(0xFF000000 | value);
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      } catch (_) {
        return null;
      }
    }

    // RGB function: rgb(255, 0, 0)
    final rgbMatch = RegExp(r'rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)').firstMatch(trimmed);
    if (rgbMatch != null) {
      final r = int.tryParse(rgbMatch.group(1)!) ?? 0;
      final g = int.tryParse(rgbMatch.group(2)!) ?? 0;
      final b = int.tryParse(rgbMatch.group(3)!) ?? 0;
      return Color.fromARGB(255, r, g, b);
    }

    return null;
  }

  /// Creates a styled span from text and style.
  StyledTextSpan _createSpan(String text, SubtitleTextStyle style) {
    if (!style.hasFormatting) {
      return StyledTextSpan.plain(text);
    }
    return StyledTextSpan(text: text, style: style);
  }

  /// Parses a TTML timestamp string to a [Duration].
  ///
  /// Supports multiple formats:
  /// - HH:MM:SS.mmm (media time)
  /// - HH:MM:SS:FF (SMPTE with frames)
  /// - 1.5s (seconds)
  /// - 1500ms (milliseconds)
  ///
  /// Returns `null` if the timestamp is invalid.
  static Duration? parseTimestamp(String timestamp, {int frameRate = _defaultFrameRate}) {
    final trimmedTimestamp = timestamp.trim();

    // Try seconds format: 1.5s
    var match = _secondsTimestamp.firstMatch(trimmedTimestamp);
    if (match != null) {
      final seconds = double.tryParse(match.group(1)!);
      if (seconds != null) {
        return Duration(milliseconds: (seconds * 1000).round());
      }
    }

    // Try milliseconds format: 1500ms
    match = _msTimestamp.firstMatch(trimmedTimestamp);
    if (match != null) {
      final ms = int.tryParse(match.group(1)!);
      if (ms != null) {
        return Duration(milliseconds: ms);
      }
    }

    // Try milliseconds format: HH:MM:SS.mmm
    match = _colonTimestampMs.firstMatch(trimmedTimestamp);
    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final fraction = match.group(4)!;
      final milliseconds = int.parse(fraction.padRight(3, '0').substring(0, 3));

      return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: milliseconds);
    }

    // Try frame format: HH:MM:SS:FF
    match = _colonTimestampFrame.firstMatch(trimmedTimestamp);
    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final frames = int.parse(match.group(4)!);
      final milliseconds = (frames * 1000 / frameRate).round();

      return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: milliseconds);
    }

    // Try simple format: HH:MM:SS
    match = _colonTimestampSimple.firstMatch(trimmedTimestamp);
    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);

      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }

    return null;
  }
}
