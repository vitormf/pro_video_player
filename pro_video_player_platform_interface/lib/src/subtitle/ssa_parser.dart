import 'dart:ui' show Color;

import '../types/styled_text_span.dart';
import '../types/subtitle_cue.dart';
import 'subtitle_parser_base.dart';

/// Parser for SubStation Alpha (.ssa) and Advanced SubStation Alpha (.ass) formats.
///
/// SSA/ASS files have sections like `[Script Info]`, `[V4+ Styles]`, `[Events]`.
/// The subtitle cues are in the `[Events]` section as Dialogue lines.
///
/// Example:
/// ```
/// [Events]
/// Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
/// Dialogue: 0,0:00:01.00,0:00:05.00,Default,,0,0,0,,Hello world
/// ```
class SsaParser extends SubtitleParserBase {
  /// Creates an SSA/ASS parser.
  const SsaParser();

  /// Pattern for SSA/ASS timestamp: H:MM:SS.cc (centiseconds)
  static final _timestampPattern = RegExp(r'^(\d+):(\d{2}):(\d{2})\.(\d{2})$');

  /// Pattern for override tags like {\b1}, {\i0}, {\c&HFFFFFF&}
  static final _overrideTagPattern = RegExp(r'\{[^}]*\}');

  /// Pattern for newline escape sequences
  static final _newlinePattern = RegExp(r'\\[Nn]');

  @override
  List<SubtitleCue> parse(String content) {
    if (content.trim().isEmpty) return [];

    var processedContent = removeBom(content);
    processedContent = normalizeLineEndings(processedContent);

    final lines = processedContent.split('\n');
    final cues = <SubtitleCue>[];

    // Find the Format line in [Events] section
    List<String>? currentFormatFields;
    var index = 0;

    for (final line in lines) {
      final trimmed = line.trim();

      // Check for section headers - skip them
      if (trimmed.startsWith('[')) {
        continue;
      }

      // Look for Format line
      if (trimmed.toLowerCase().startsWith('format:')) {
        final formatPart = trimmed.substring(7).trim();
        currentFormatFields = formatPart.split(',').map((f) => f.trim().toLowerCase()).toList();
        continue;
      }

      // Parse Dialogue lines
      if (trimmed.toLowerCase().startsWith('dialogue:')) {
        final cue = _parseDialogue(trimmed, currentFormatFields, index);
        if (cue != null) {
          cues.add(cue);
          index++;
        }
      }
    }

    return cues;
  }

  SubtitleCue? _parseDialogue(String line, List<String>? formatFields, int index) {
    // Remove "Dialogue:" prefix
    final dialoguePart = line.substring(line.indexOf(':') + 1).trim();

    // Split by commas, but the last field (Text) may contain commas
    final parts = <String>[];
    var current = StringBuffer();
    var depth = 0;

    for (var i = 0; i < dialoguePart.length; i++) {
      final char = dialoguePart[i];
      if (char == ',' && depth == 0) {
        parts.add(current.toString());
        current = StringBuffer();
      } else {
        if (char == '{') depth++;
        if (char == '}') depth--;
        current.write(char);
      }
    }
    parts.add(current.toString());

    // Use default format if none specified
    final fields =
        formatFields ?? ['layer', 'start', 'end', 'style', 'name', 'marginl', 'marginr', 'marginv', 'effect', 'text'];

    // Find indices of start, end, and text fields
    final startIndex = fields.indexOf('start');
    final endIndex = fields.indexOf('end');
    final textIndex = fields.indexOf('text');

    if (startIndex == -1 || endIndex == -1 || textIndex == -1) return null;
    if (parts.length <= textIndex) return null;

    final start = parseTimestamp(parts[startIndex].trim());
    final end = parseTimestamp(parts[endIndex].trim());
    if (start == null || end == null) return null;

    // Text is everything from textIndex onwards (may have been split by commas)
    var rawText = parts.sublist(textIndex).join(',').trim();
    // Convert \N and \n to actual newlines first
    rawText = rawText.replaceAll(_newlinePattern, '\n');

    if (rawText.isEmpty) return null;

    // Parse styled spans and plain text
    final styledSpans = _parseStyledText(rawText);
    final plainText = _cleanText(rawText);

    if (plainText.isEmpty) return null;

    return SubtitleCue(
      index: index,
      start: start,
      end: end,
      text: plainText,
      styledSpans: styledSpans.isNotEmpty ? styledSpans : null,
    );
  }

  String _cleanText(String text) {
    // Replace \N and \n with actual newlines
    var result = text.replaceAll(_newlinePattern, '\n');
    // Remove override tags
    result = result.replaceAll(_overrideTagPattern, '');
    // Clean up extra whitespace
    return result.trim();
  }

  /// Parses SSA/ASS text with override tags into styled spans.
  ///
  /// Supports:
  /// - `{\b1}` / `{\b0}` - bold on/off
  /// - `{\i1}` / `{\i0}` - italic on/off
  /// - `{\u1}` / `{\u0}` - underline on/off
  /// - `{\s1}` / `{\s0}` - strikethrough on/off
  /// - `{\c&HBBGGRR&}` or `{\1c&HBBGGRR&}` - text color (BGR format)
  /// - `{\fs##}` - font size
  /// - `{\fn<name>}` - font family
  List<StyledTextSpan> _parseStyledText(String text) {
    final spans = <StyledTextSpan>[];
    var currentStyle = const SubtitleTextStyle();
    var currentText = StringBuffer();
    var i = 0;

    while (i < text.length) {
      if (text[i] == '{') {
        // Find closing }
        final closeIndex = text.indexOf('}', i);
        if (closeIndex == -1) {
          currentText.write(text[i]);
          i++;
          continue;
        }

        final tagContent = text.substring(i + 1, closeIndex);

        // Flush current text before style change
        if (currentText.isNotEmpty) {
          spans.add(_createSpan(currentText.toString(), currentStyle));
          currentText = StringBuffer();
        }

        // Parse override tags (may have multiple in one block, e.g., {\b1\i1})
        currentStyle = _parseOverrideTags(tagContent, currentStyle);

        i = closeIndex + 1;
      } else {
        currentText.write(text[i]);
        i++;
      }
    }

    // Flush remaining text
    if (currentText.isNotEmpty) {
      spans.add(_createSpan(currentText.toString(), currentStyle));
    }

    return spans;
  }

  /// Parses SSA override tags and returns updated style.
  SubtitleTextStyle _parseOverrideTags(String tagContent, SubtitleTextStyle currentStyle) {
    var style = currentStyle;

    // Split by \ to handle multiple tags
    final tags = tagContent.split(r'\');

    for (final tag in tags) {
      if (tag.isEmpty) continue;

      // Bold: \b1, \b0
      if (tag.startsWith('b')) {
        final value = tag.substring(1);
        style = SubtitleTextStyle(
          isBold: value == '1',
          isItalic: style.isItalic,
          isUnderline: style.isUnderline,
          isStrikethrough: style.isStrikethrough,
          color: style.color,
          backgroundColor: style.backgroundColor,
          fontSize: style.fontSize,
          fontFamily: style.fontFamily,
        );
      }
      // Italic: \i1, \i0
      else if (tag.startsWith('i') && tag.length <= 2) {
        final value = tag.substring(1);
        style = SubtitleTextStyle(
          isBold: style.isBold,
          isItalic: value == '1',
          isUnderline: style.isUnderline,
          isStrikethrough: style.isStrikethrough,
          color: style.color,
          backgroundColor: style.backgroundColor,
          fontSize: style.fontSize,
          fontFamily: style.fontFamily,
        );
      }
      // Underline: \u1, \u0
      else if (tag.startsWith('u') && tag.length <= 2) {
        final value = tag.substring(1);
        style = SubtitleTextStyle(
          isBold: style.isBold,
          isItalic: style.isItalic,
          isUnderline: value == '1',
          isStrikethrough: style.isStrikethrough,
          color: style.color,
          backgroundColor: style.backgroundColor,
          fontSize: style.fontSize,
          fontFamily: style.fontFamily,
        );
      }
      // Strikethrough: \s1, \s0
      else if (tag.startsWith('s') && tag.length <= 2) {
        final value = tag.substring(1);
        style = SubtitleTextStyle(
          isBold: style.isBold,
          isItalic: style.isItalic,
          isUnderline: style.isUnderline,
          isStrikethrough: value == '1',
          color: style.color,
          backgroundColor: style.backgroundColor,
          fontSize: style.fontSize,
          fontFamily: style.fontFamily,
        );
      }
      // Color: \c&HBBGGRR& or \1c&HBBGGRR&
      else if (tag.startsWith('c&') || tag.startsWith('1c&')) {
        final color = _parseSsaColor(tag);
        if (color != null) {
          style = SubtitleTextStyle(
            isBold: style.isBold,
            isItalic: style.isItalic,
            isUnderline: style.isUnderline,
            isStrikethrough: style.isStrikethrough,
            color: color,
            backgroundColor: style.backgroundColor,
            fontSize: style.fontSize,
            fontFamily: style.fontFamily,
          );
        }
      }
      // Font size: \fs##
      else if (tag.startsWith('fs')) {
        final sizeStr = tag.substring(2);
        final size = double.tryParse(sizeStr);
        if (size != null) {
          style = SubtitleTextStyle(
            isBold: style.isBold,
            isItalic: style.isItalic,
            isUnderline: style.isUnderline,
            isStrikethrough: style.isStrikethrough,
            color: style.color,
            backgroundColor: style.backgroundColor,
            fontSize: size,
            fontFamily: style.fontFamily,
          );
        }
      }
      // Font family: \fn<name>
      else if (tag.startsWith('fn')) {
        final fontFamily = tag.substring(2);
        if (fontFamily.isNotEmpty) {
          style = SubtitleTextStyle(
            isBold: style.isBold,
            isItalic: style.isItalic,
            isUnderline: style.isUnderline,
            isStrikethrough: style.isStrikethrough,
            color: style.color,
            backgroundColor: style.backgroundColor,
            fontSize: style.fontSize,
            fontFamily: fontFamily,
          );
        }
      }
    }

    return style;
  }

  /// Parses SSA color format (&HBBGGRR& or &HAABBGGRR&) to Color.
  Color? _parseSsaColor(String tag) {
    // Extract hex part: c&HBBGGRR& or 1c&HBBGGRR&
    final match = RegExp('&H([0-9A-Fa-f]+)&?').firstMatch(tag);
    if (match == null) return null;

    final hex = match.group(1)!;
    if (hex.length < 6) return null;

    try {
      // SSA uses BGR format, optionally with alpha: AABBGGRR or BBGGRR
      if (hex.length >= 8) {
        // AABBGGRR format
        final alpha = int.parse(hex.substring(0, 2), radix: 16);
        final blue = int.parse(hex.substring(2, 4), radix: 16);
        final green = int.parse(hex.substring(4, 6), radix: 16);
        final red = int.parse(hex.substring(6, 8), radix: 16);
        // SSA alpha is inverted (0 = opaque, 255 = transparent)
        return Color.fromARGB(255 - alpha, red, green, blue);
      } else {
        // BBGGRR format (no alpha, assume opaque)
        final blue = int.parse(hex.substring(0, 2), radix: 16);
        final green = int.parse(hex.substring(2, 4), radix: 16);
        final red = int.parse(hex.substring(4, 6), radix: 16);
        return Color.fromARGB(255, red, green, blue);
      }
    } catch (_) {
      return null;
    }
  }

  /// Creates a styled span from text and style.
  StyledTextSpan _createSpan(String text, SubtitleTextStyle style) {
    if (!style.hasFormatting) {
      return StyledTextSpan.plain(text);
    }
    return StyledTextSpan(text: text, style: style);
  }

  /// Parses an SSA/ASS timestamp string to a [Duration].
  ///
  /// Format: H:MM:SS.cc (centiseconds, 1/100th of a second)
  /// Returns `null` if the timestamp is invalid.
  static Duration? parseTimestamp(String timestamp) {
    final match = _timestampPattern.firstMatch(timestamp.trim());
    if (match == null) return null;

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final centiseconds = int.parse(match.group(4)!);

    return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: centiseconds * 10);
  }
}
