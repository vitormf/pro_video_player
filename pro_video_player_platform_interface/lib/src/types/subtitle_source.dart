import 'subtitle_format.dart';

/// Represents the source of an external subtitle file to be loaded.
///
/// This is a sealed class with factory constructors for different source types:
/// - [SubtitleSource.network] — HTTP/HTTPS URLs for remote subtitle files
/// - [SubtitleSource.file] — Local file paths on the device
/// - [SubtitleSource.asset] — Flutter assets bundled with the app
///
/// Each source type includes optional metadata: [label], [language], [format],
/// and [isDefault]. If [format] is not provided, it will be auto-detected from
/// the file extension.
///
/// ## Example
///
/// ```dart
/// // Network subtitle
/// final networkSub = SubtitleSource.network(
///   'https://example.com/subtitles.vtt',
///   label: 'English',
///   language: 'en',
/// );
///
/// // Local file
/// final fileSub = SubtitleSource.file(
///   '/path/to/subtitles.srt',
///   label: 'Spanish',
///   language: 'es',
/// );
///
/// // Flutter asset
/// final assetSub = SubtitleSource.asset(
///   'assets/subtitles/french.vtt',
///   label: 'French',
///   language: 'fr',
/// );
///
/// // Auto-detect source type
/// final autoSub = SubtitleSource.from('https://example.com/subs.vtt');
/// ```
sealed class SubtitleSource {
  /// Creates a subtitle source with optional metadata.
  const SubtitleSource({this.label, this.language, this.format, this.isDefault = false});

  /// Creates a subtitle source from a network URL.
  ///
  /// Supports HTTP/HTTPS URLs to remote subtitle files.
  /// The file format is auto-detected from the URL extension if not specified.
  const factory SubtitleSource.network(
    String url, {
    String? label,
    String? language,
    SubtitleFormat? format,
    bool isDefault,
  }) = NetworkSubtitleSource;

  /// Creates a subtitle source from a local file path.
  ///
  /// The [path] should be an absolute path to a subtitle file on the device.
  /// Use `path_provider` package to get appropriate directories.
  const factory SubtitleSource.file(
    String path, {
    String? label,
    String? language,
    SubtitleFormat? format,
    bool isDefault,
  }) = FileSubtitleSource;

  /// Creates a subtitle source from a Flutter asset.
  ///
  /// The [assetPath] should match an asset declared in your `pubspec.yaml`.
  /// Example: `'assets/subtitles/english.vtt'`
  const factory SubtitleSource.asset(
    String assetPath, {
    String? label,
    String? language,
    SubtitleFormat? format,
    bool isDefault,
  }) = AssetSubtitleSource;

  /// Creates a subtitle source by auto-detecting the type from the input string.
  ///
  /// This factory intelligently determines the appropriate source type:
  ///
  /// **Network sources** (returns [NetworkSubtitleSource]):
  /// - URLs with `http://` or `https://` scheme
  /// - Bare domains like `example.com/subtitles.vtt` (https:// is added automatically)
  ///
  /// **File sources** (returns [FileSubtitleSource]):
  /// - Absolute Unix paths starting with `/`
  /// - Windows paths with drive letters like `C:\` or `D:/`
  /// - `file://` URIs (the scheme is stripped and path is decoded)
  /// - Android `content://` URIs (passed through as-is)
  ///
  /// **Asset sources** (returns [AssetSubtitleSource]):
  /// - Paths starting with `assets/`
  /// - Package asset paths starting with `packages/`
  ///
  /// Throws [ArgumentError] if [input] is empty or contains only whitespace.
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Network URLs
  /// SubtitleSource.from('https://example.com/subtitles.vtt');
  /// SubtitleSource.from('example.com/subtitles.vtt'); // https:// added
  ///
  /// // Local files
  /// SubtitleSource.from('/var/mobile/Documents/subtitles.srt');
  /// SubtitleSource.from('file:///path/to/subtitles.vtt');
  /// SubtitleSource.from(r'C:\Users\Subtitles\movie.srt');
  ///
  /// // Flutter assets
  /// SubtitleSource.from('assets/subtitles/english.vtt');
  /// ```
  factory SubtitleSource.from(
    String input, {
    String? label,
    String? language,
    SubtitleFormat? format,
    bool isDefault = false,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(input, 'input', 'Cannot be empty or whitespace');
    }

    final lowerInput = trimmed.toLowerCase();

    // Network schemes
    if (lowerInput.startsWith('http://') || lowerInput.startsWith('https://')) {
      return NetworkSubtitleSource(trimmed, label: label, language: language, format: format, isDefault: isDefault);
    }

    // File URI scheme
    if (lowerInput.startsWith('file://')) {
      final uri = Uri.parse(trimmed);
      final decodedPath = Uri.decodeComponent(uri.path);
      return FileSubtitleSource(decodedPath, label: label, language: language, format: format, isDefault: isDefault);
    }

    // Android content provider URI
    if (lowerInput.startsWith('content://')) {
      return FileSubtitleSource(trimmed, label: label, language: language, format: format, isDefault: isDefault);
    }

    // Absolute Unix path
    if (trimmed.startsWith('/')) {
      return FileSubtitleSource(trimmed, label: label, language: language, format: format, isDefault: isDefault);
    }

    // Windows absolute path (C:\ or C:/)
    if (trimmed.length >= 2 &&
        RegExp('^[A-Za-z]:').hasMatch(trimmed) &&
        (trimmed.length == 2 || trimmed[2] == r'\' || trimmed[2] == '/')) {
      return FileSubtitleSource(trimmed, label: label, language: language, format: format, isDefault: isDefault);
    }

    // Flutter assets
    if (trimmed.startsWith('assets/') || trimmed.startsWith('packages/')) {
      return AssetSubtitleSource(trimmed, label: label, language: language, format: format, isDefault: isDefault);
    }

    // Bare domain - add https:// and treat as network
    return NetworkSubtitleSource(
      'https://$trimmed',
      label: label,
      language: language,
      format: format,
      isDefault: isDefault,
    );
  }

  /// Optional display label for the subtitle track.
  ///
  /// If not provided, a default label will be generated.
  final String? label;

  /// ISO 639-1 language code (e.g., 'en', 'es', 'fr').
  final String? language;

  /// The subtitle format.
  ///
  /// If not provided, will be auto-detected from the file extension.
  final SubtitleFormat? format;

  /// Whether this should be the default subtitle track.
  final bool isDefault;

  /// Returns the path/URL string for this source.
  String get path;

  /// Returns the source type as a string ('network', 'file', 'asset').
  String get sourceType;
}

/// A subtitle source from a network URL.
final class NetworkSubtitleSource extends SubtitleSource {
  /// Creates a network subtitle source.
  const NetworkSubtitleSource(this.url, {super.label, super.language, super.format, super.isDefault});

  /// The URL of the subtitle file.
  final String url;

  @override
  String get path => url;

  @override
  String get sourceType => 'network';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NetworkSubtitleSource) return false;
    return url == other.url &&
        label == other.label &&
        language == other.language &&
        format == other.format &&
        isDefault == other.isDefault;
  }

  @override
  int get hashCode => Object.hash(url, label, language, format, isDefault);

  @override
  String toString() =>
      'NetworkSubtitleSource(url: $url, label: $label, language: $language, format: $format, isDefault: $isDefault)';
}

/// A subtitle source from a local file.
final class FileSubtitleSource extends SubtitleSource {
  /// Creates a file subtitle source.
  const FileSubtitleSource(this.filePath, {super.label, super.language, super.format, super.isDefault});

  /// The path to the local subtitle file.
  final String filePath;

  @override
  String get path => filePath;

  @override
  String get sourceType => 'file';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FileSubtitleSource) return false;
    return filePath == other.filePath &&
        label == other.label &&
        language == other.language &&
        format == other.format &&
        isDefault == other.isDefault;
  }

  @override
  int get hashCode => Object.hash(filePath, label, language, format, isDefault);

  @override
  String toString() =>
      'FileSubtitleSource(path: $filePath, label: $label, language: $language, format: $format, isDefault: $isDefault)';
}

/// A subtitle source from a Flutter asset.
final class AssetSubtitleSource extends SubtitleSource {
  /// Creates an asset subtitle source.
  const AssetSubtitleSource(this.assetPath, {super.label, super.language, super.format, super.isDefault});

  /// The path to the asset.
  final String assetPath;

  @override
  String get path => assetPath;

  @override
  String get sourceType => 'asset';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AssetSubtitleSource) return false;
    return assetPath == other.assetPath &&
        label == other.label &&
        language == other.language &&
        format == other.format &&
        isDefault == other.isDefault;
  }

  @override
  int get hashCode => Object.hash(assetPath, label, language, format, isDefault);

  @override
  String toString() =>
      'AssetSubtitleSource(assetPath: $assetPath, label: $label, language: $language, format: $format, isDefault: $isDefault)';
}
