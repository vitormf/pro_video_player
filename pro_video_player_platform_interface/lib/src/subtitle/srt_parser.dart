import '../types/subtitle_cue.dart';
import 'subtitle_parser_base.dart';

/// Parser for SubRip (.srt) subtitle format.
///
/// SRT is the most common subtitle format with a simple structure:
/// ```
/// 1
/// 00:00:01,000 --> 00:00:05,000
/// Subtitle text
///
/// 2
/// 00:00:06,000 --> 00:00:10,000
/// Next subtitle
/// ```
class SrtParser extends SubtitleParserBase {
  /// Creates an SRT parser.
  const SrtParser();

  /// Pattern for SRT timestamp: HH:MM:SS,mmm or HH:MM:SS.mmm or HH:MM:SS
  /// Accepts 0-3 digit milliseconds (e.g., "00:01:39", "00:01:41,04", or "00:01:41,040")
  static final _timestampPattern = RegExp(r'^(\d{2}):(\d{2}):(\d{2})(?:[,.](\d{2,3}))?$');

  /// Pattern for the timing line: start --> end (with optional position info)
  static final _timingPattern = RegExp(
    r'^(\d{2}:\d{2}:\d{2}(?:[,.]\d{2,3})?)\s*-->\s*(\d{2}:\d{2}:\d{2}(?:[,.]\d{2,3})?)',
  );

  @override
  List<SubtitleCue> parse(String content) {
    if (content.trim().isEmpty) return [];

    var processedContent = removeBom(content);
    processedContent = normalizeLineEndings(processedContent);

    final cues = <SubtitleCue>[];
    final blocks = processedContent.split(RegExp(r'\n\n+'));

    for (final block in blocks) {
      final cue = _parseBlock(block.trim());
      if (cue != null) {
        cues.add(cue);
      }
    }

    return cues;
  }

  SubtitleCue? _parseBlock(String block) {
    if (block.isEmpty) return null;

    final lines = block.split('\n');
    if (lines.length < 2) return null;

    // First line should be the index number
    final index = int.tryParse(lines[0].trim());
    if (index == null) return null;

    // Find the timing line (could be line 1 or line 0 if index is missing)
    const timingLineIndex = 1;
    final timingMatch = _timingPattern.firstMatch(lines[timingLineIndex]);
    if (timingMatch == null) return null;

    final start = parseTimestamp(timingMatch.group(1)!);
    final end = parseTimestamp(timingMatch.group(2)!);
    if (start == null || end == null) return null;

    // Remaining lines are the subtitle text
    final textLines = lines.sublist(timingLineIndex + 1);
    if (textLines.isEmpty) return null;

    var text = textLines.join('\n').trim();
    text = stripAllTags(text);

    if (text.isEmpty) return null;

    return SubtitleCue(index: index, start: start, end: end, text: text);
  }

  /// Parses an SRT timestamp string to a [Duration].
  ///
  /// Accepts formats: HH:MM:SS,mmm or HH:MM:SS.mmm or HH:MM:SS
  /// Supports 0-3 digit milliseconds (e.g., "00:01:39", "04" is treated as "040" = 40ms)
  /// Returns `null` if the timestamp is invalid.
  static Duration? parseTimestamp(String timestamp) {
    final match = _timestampPattern.firstMatch(timestamp.trim());
    if (match == null) return null;

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);

    // Group 4 is optional (milliseconds)
    final millisecondsStr = match.group(4);
    final milliseconds = millisecondsStr != null ? _parseMilliseconds(millisecondsStr) : 0;

    return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: milliseconds);
  }

  /// Parses milliseconds from a 2-3 digit string, padding 2 digits to 3.
  /// E.g., "04" -> 40, "040" -> 40, "123" -> 123
  static int _parseMilliseconds(String str) {
    // Pad 2-digit milliseconds to 3 digits (e.g., "04" -> "040")
    final paddedStr = str.length == 2 ? '${str}0' : str;
    return int.parse(paddedStr);
  }
}
