import '../types/subtitle_cue.dart';
import '../types/subtitle_format.dart';
import 'srt_parser.dart';
import 'ssa_parser.dart';
import 'subtitle_parser_base.dart';
import 'ttml_parser.dart';
import 'vtt_parser.dart';

/// Unified subtitle parser that supports multiple formats.
///
/// Use [parse] with a known format, or [parseWithAutoDetect] to
/// automatically detect the format from the content.
///
/// Supported formats:
/// - SRT (SubRip)
/// - VTT (WebVTT)
/// - SSA (SubStation Alpha)
/// - ASS (Advanced SubStation Alpha)
/// - TTML (Timed Text Markup Language)
class SubtitleParser {
  /// Private constructor - use static methods.
  const SubtitleParser._();

  static const _srtParser = SrtParser();
  static const _vttParser = VttParser();
  static const _ssaParser = SsaParser();
  static const _ttmlParser = TtmlParser();

  /// Parses subtitle content with the specified format.
  ///
  /// Returns a list of [SubtitleCue] objects sorted by start time.
  /// Returns an empty list if parsing fails or content is empty.
  static List<SubtitleCue> parse(String content, SubtitleFormat format) {
    final parser = getParser(format);
    return parser.parse(content);
  }

  /// Parses subtitle content with automatic format detection.
  ///
  /// Attempts to detect the format from the content and parse it.
  /// Returns an empty list if the format cannot be detected or
  /// parsing fails.
  static List<SubtitleCue> parseWithAutoDetect(String content) {
    final format = detectFormat(content);
    if (format == null) return [];
    return parse(content, format);
  }

  /// Returns the appropriate parser for the given format.
  static SubtitleParserBase getParser(SubtitleFormat format) => switch (format) {
    SubtitleFormat.srt => _srtParser,
    SubtitleFormat.vtt => _vttParser,
    SubtitleFormat.ssa => _ssaParser,
    SubtitleFormat.ass => _ssaParser, // ASS uses the same parser as SSA
    SubtitleFormat.ttml => _ttmlParser,
  };

  /// Detects the subtitle format from content.
  ///
  /// Examines the content to determine which format it is.
  /// Returns `null` if the format cannot be determined.
  static SubtitleFormat? detectFormat(String content) {
    if (content.isEmpty) return null;

    // Remove BOM if present
    var trimmed = content;
    if (trimmed.startsWith('\uFEFF')) {
      trimmed = trimmed.substring(1);
    }
    trimmed = trimmed.trim();

    // Check for WEBVTT header
    if (trimmed.startsWith('WEBVTT')) {
      return SubtitleFormat.vtt;
    }

    // Check for XML/TTML
    if (trimmed.startsWith('<?xml') || trimmed.contains('<tt ') || trimmed.contains('<tt>')) {
      return SubtitleFormat.ttml;
    }

    // Check for SSA/ASS section headers
    if (trimmed.contains('[Script Info]') || trimmed.contains('[Events]')) {
      // Check for ASS-specific ScriptType
      if (trimmed.contains('ScriptType: v4.00+') || trimmed.contains('v4.00+')) {
        return SubtitleFormat.ass;
      }
      return SubtitleFormat.ssa;
    }

    // Check for SRT format (starts with number, then timestamp line)
    if (RegExp(r'^\d+\s*\n\d{2}:\d{2}:\d{2}[,.]\d{3}\s*-->').hasMatch(trimmed)) {
      return SubtitleFormat.srt;
    }

    // Could also be SSA without section headers (minimal format)
    if (trimmed.contains('Dialogue:') && trimmed.contains('Format:')) {
      return SubtitleFormat.ssa;
    }

    return null;
  }
}
