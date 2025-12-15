import '../types/subtitle_cue.dart';

/// Base interface for subtitle parsers.
///
/// Each subtitle format (SRT, VTT, SSA/ASS, TTML) has its own
/// parser implementation that extends this base class.
abstract class SubtitleParserBase {
  /// Creates a subtitle parser.
  const SubtitleParserBase();

  /// Parses subtitle content and returns a list of cues.
  ///
  /// The [content] is the raw text content of the subtitle file.
  /// Returns a list of [SubtitleCue] objects sorted by start time.
  /// Returns an empty list if parsing fails or content is empty.
  List<SubtitleCue> parse(String content);

  /// Normalizes line endings to Unix-style (LF).
  ///
  /// Converts Windows (CRLF) and old Mac (CR) line endings to LF.
  String normalizeLineEndings(String content) => content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  /// Removes BOM (Byte Order Mark) from the beginning of content.
  String removeBom(String content) {
    if (content.startsWith('\uFEFF')) {
      return content.substring(1);
    }
    return content;
  }

  /// Strips HTML/XML tags from text.
  ///
  /// Removes all tags like <b>, <i>, <font>, etc.
  String stripTags(String text) => text.replaceAll(RegExp('<[^>]*>'), '');

  /// Strips ASS/SSA-style override tags from text.
  ///
  /// Removes tags like {\an8}, {\pos(x,y)}, {\fad(in,out)}, etc.
  /// These are sometimes found in SRT files as a non-standard extension.
  String stripAssTags(String text) => text.replaceAll(RegExp(r'\{\\[^}]*\}'), '');

  /// Strips both HTML and ASS-style tags from text.
  String stripAllTags(String text) => stripAssTags(stripTags(text));
}
