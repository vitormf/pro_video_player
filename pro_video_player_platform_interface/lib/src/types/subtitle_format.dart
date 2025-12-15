/// Supported external subtitle file formats.
enum SubtitleFormat {
  /// SubRip format (.srt) - The most common subtitle format.
  ///
  /// Simple text-based format with numbered entries containing
  /// timestamps and text.
  srt,

  /// WebVTT format (.vtt) - Web Video Text Tracks.
  ///
  /// Standard format for HTML5 video subtitles, supports styling
  /// and positioning.
  vtt,

  /// SubStation Alpha format (.ssa) - Original SSA format.
  ///
  /// Supports advanced styling, fonts, and effects.
  ssa,

  /// Advanced SubStation Alpha format (.ass) - Enhanced SSA.
  ///
  /// Extends SSA with more styling options and effects.
  ass,

  /// Timed Text Markup Language format (.ttml) - XML-based format.
  ///
  /// W3C standard format used in broadcast and streaming.
  ttml;

  /// Detects subtitle format from a file extension.
  ///
  /// The [extension] can include or omit the leading dot.
  /// Returns `null` if the extension is not recognized.
  ///
  /// Example:
  /// ```dart
  /// SubtitleFormat.fromFileExtension('.srt'); // SubtitleFormat.srt
  /// SubtitleFormat.fromFileExtension('vtt');  // SubtitleFormat.vtt
  /// ```
  static SubtitleFormat? fromFileExtension(String extension) {
    final ext = extension.toLowerCase().replaceFirst('.', '');
    return switch (ext) {
      'srt' => SubtitleFormat.srt,
      'vtt' => SubtitleFormat.vtt,
      'ssa' => SubtitleFormat.ssa,
      'ass' => SubtitleFormat.ass,
      'ttml' => SubtitleFormat.ttml,
      _ => null,
    };
  }

  /// Detects subtitle format from a URL.
  ///
  /// Extracts the file extension from the URL path and detects
  /// the format. Query parameters are ignored.
  /// Returns `null` if the format cannot be determined.
  ///
  /// Example:
  /// ```dart
  /// SubtitleFormat.fromUrl('https://example.com/sub.srt?token=abc');
  /// // Returns SubtitleFormat.srt
  /// ```
  static SubtitleFormat? fromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final dotIndex = path.lastIndexOf('.');
      if (dotIndex == -1 || dotIndex == path.length - 1) {
        return null;
      }
      final extension = path.substring(dotIndex);
      return fromFileExtension(extension);
    } catch (_) {
      return null;
    }
  }

  /// The standard file extension for this format (with leading dot).
  String get fileExtension => switch (this) {
    SubtitleFormat.srt => '.srt',
    SubtitleFormat.vtt => '.vtt',
    SubtitleFormat.ssa => '.ssa',
    SubtitleFormat.ass => '.ass',
    SubtitleFormat.ttml => '.ttml',
  };

  /// The MIME type for this subtitle format.
  String get mimeType => switch (this) {
    SubtitleFormat.srt => 'application/x-subrip',
    SubtitleFormat.vtt => 'text/vtt',
    SubtitleFormat.ssa => 'text/x-ssa',
    SubtitleFormat.ass => 'text/x-ass',
    SubtitleFormat.ttml => 'application/ttml+xml',
  };
}
