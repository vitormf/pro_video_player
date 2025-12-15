/// Represents the source of a video to be played.
///
/// This is a sealed class with factory constructors for different source types:
/// - [VideoSource.network] — HTTP/HTTPS URLs for streaming or downloading
/// - [VideoSource.file] — Local file paths on the device
/// - [VideoSource.asset] — Flutter assets bundled with the app
/// - [VideoSource.playlist] — Playlist file URLs (M3U, M3U8, PLS, XSPF)
///
/// ## Example
///
/// ```dart
/// // Network video (supports HTTP/HTTPS, HLS, DASH)
/// final networkSource = VideoSource.network(
///   'https://example.com/video.mp4',
///   headers: {'Authorization': 'Bearer token'},
/// );
///
/// // Local file
/// final fileSource = VideoSource.file('/path/to/video.mp4');
///
/// // Flutter asset (must be declared in pubspec.yaml)
/// final assetSource = VideoSource.asset('assets/videos/intro.mp4');
///
/// // Playlist file
/// final playlistSource = VideoSource.playlist('https://example.com/playlist.m3u8');
/// ```
sealed class VideoSource {
  const VideoSource();

  /// Creates a video source by auto-detecting the type from the input string.
  ///
  /// This factory intelligently determines the appropriate source type:
  ///
  /// **Network sources** (returns [NetworkVideoSource]):
  /// - URLs with `http://` or `https://` scheme
  /// - URLs with streaming schemes: `rtsp://`, `rtmp://`, `rtp://`, `mms://`
  /// - Bare domains like `example.com/video.mp4` (https:// is added automatically)
  ///
  /// **File sources** (returns [FileVideoSource]):
  /// - Absolute Unix paths starting with `/`
  /// - Windows paths with drive letters like `C:\` or `D:/`
  /// - `file://` URIs (the scheme is stripped and path is decoded)
  /// - Android `content://` URIs (passed through as-is)
  ///
  /// **Asset sources** (returns [AssetVideoSource]):
  /// - Paths starting with `assets/`
  /// - Package asset paths starting with `packages/`
  ///
  /// The optional [headers] parameter is only used for network sources and
  /// is ignored for file and asset sources.
  ///
  /// Throws [ArgumentError] if [input] is empty or contains only whitespace.
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Network URLs
  /// VideoSource.from('https://example.com/video.mp4');
  /// VideoSource.from('example.com/video.mp4'); // https:// added
  /// VideoSource.from('rtsp://camera.local/stream');
  ///
  /// // Local files
  /// VideoSource.from('/var/mobile/Documents/video.mp4');
  /// VideoSource.from('file:///path/to/video.mp4');
  /// VideoSource.from(r'C:\Users\Videos\video.mp4');
  ///
  /// // Flutter assets
  /// VideoSource.from('assets/videos/intro.mp4');
  /// ```
  factory VideoSource.from(String input, {Map<String, String>? headers}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(input, 'input', 'Cannot be empty or whitespace');
    }

    // Check for explicit schemes first
    final lowerInput = trimmed.toLowerCase();

    // Network schemes
    if (lowerInput.startsWith('http://') || lowerInput.startsWith('https://')) {
      return NetworkVideoSource(trimmed, headers: headers);
    }

    // Streaming protocols
    if (lowerInput.startsWith('rtsp://') ||
        lowerInput.startsWith('rtmp://') ||
        lowerInput.startsWith('rtp://') ||
        lowerInput.startsWith('mms://')) {
      return NetworkVideoSource(trimmed, headers: headers);
    }

    // File URI scheme
    if (lowerInput.startsWith('file://')) {
      final uri = Uri.parse(trimmed);
      final decodedPath = Uri.decodeComponent(uri.path);
      return FileVideoSource(decodedPath);
    }

    // Android content provider URI
    if (lowerInput.startsWith('content://')) {
      return FileVideoSource(trimmed);
    }

    // Absolute Unix path
    if (trimmed.startsWith('/')) {
      return FileVideoSource(trimmed);
    }

    // Windows absolute path (C:\ or C:/)
    if (trimmed.length >= 2 &&
        RegExp('^[A-Za-z]:').hasMatch(trimmed) &&
        (trimmed.length == 2 || trimmed[2] == r'\' || trimmed[2] == '/')) {
      return FileVideoSource(trimmed);
    }

    // Flutter assets
    if (trimmed.startsWith('assets/') || trimmed.startsWith('packages/')) {
      return AssetVideoSource(trimmed);
    }

    // Bare domain - add https:// and treat as network
    return NetworkVideoSource('https://$trimmed', headers: headers);
  }

  /// Creates a video source from a network URL.
  ///
  /// Supports HTTP/HTTPS URLs including:
  /// - Standard video files (MP4, WebM, MKV, etc.)
  /// - HLS adaptive streaming (.m3u8) - Supported on all platforms
  /// - DASH adaptive streaming (.mpd) - Supported on Android and Web only
  ///
  /// **DASH Platform Support:**
  /// | Platform | Support | Implementation |
  /// |----------|---------|----------------|
  /// | Android  | ✅      | ExoPlayer native |
  /// | Web      | ✅      | dash.js library |
  /// | iOS      | ❌      | AVPlayer limitation |
  /// | macOS    | ❌      | AVPlayer limitation |
  ///
  /// For Apple platforms (iOS/macOS), use HLS instead of DASH.
  ///
  /// The optional [headers] parameter allows passing custom HTTP headers
  /// for authenticated or protected content.
  const factory VideoSource.network(String url, {Map<String, String>? headers}) = NetworkVideoSource;

  /// Creates a video source from a local file path.
  ///
  /// The [path] should be an absolute path to a video file on the device.
  /// Use `path_provider` package to get appropriate directories.
  const factory VideoSource.file(String path) = FileVideoSource;

  /// Creates a video source from a Flutter asset.
  ///
  /// The [assetPath] should match an asset declared in your `pubspec.yaml`.
  /// Example: `'assets/videos/intro.mp4'`
  const factory VideoSource.asset(String assetPath) = AssetVideoSource;

  /// Creates a video source from a playlist file URL.
  ///
  /// The playlist file will be downloaded and parsed automatically.
  /// Supported formats: M3U, M3U8, PLS, XSPF.
  ///
  /// For HLS adaptive streaming playlists (master or media playlists),
  /// the URL is treated as a single video source and passed to the native player.
  ///
  /// For simple playlists (multiple video URLs), the playlist is parsed
  /// and can be initialized using `ProVideoPlayerController.initializeWithPlaylist`.
  const factory VideoSource.playlist(String url, {Map<String, String>? headers}) = PlaylistVideoSource;
}

/// A video source from a network URL.
final class NetworkVideoSource extends VideoSource {
  /// Creates a network video source.
  const NetworkVideoSource(this.url, {this.headers});

  /// The URL of the video.
  final String url;

  /// Optional HTTP headers to include in the request.
  final Map<String, String>? headers;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NetworkVideoSource) return false;
    return url == other.url && _mapsEqual(headers, other.headers);
  }

  @override
  int get hashCode => Object.hash(url, headers);

  @override
  String toString() => 'NetworkVideoSource(url: $url, headers: $headers)';
}

/// A video source from a local file.
final class FileVideoSource extends VideoSource {
  /// Creates a file video source.
  const FileVideoSource(this.path);

  /// The path to the local video file.
  final String path;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FileVideoSource) return false;
    return path == other.path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'FileVideoSource(path: $path)';
}

/// A video source from a Flutter asset.
final class AssetVideoSource extends VideoSource {
  /// Creates an asset video source.
  const AssetVideoSource(this.assetPath);

  /// The path to the asset.
  final String assetPath;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AssetVideoSource) return false;
    return assetPath == other.assetPath;
  }

  @override
  int get hashCode => assetPath.hashCode;

  @override
  String toString() => 'AssetVideoSource(assetPath: $assetPath)';
}

/// A video source from a playlist file URL.
final class PlaylistVideoSource extends VideoSource {
  /// Creates a playlist video source.
  const PlaylistVideoSource(this.url, {this.headers});

  /// The URL of the playlist file.
  final String url;

  /// Optional HTTP headers to include in the request.
  final Map<String, String>? headers;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlaylistVideoSource) return false;
    return url == other.url && _mapsEqual(headers, other.headers);
  }

  @override
  int get hashCode => Object.hash(url, headers);

  @override
  String toString() => 'PlaylistVideoSource(url: $url, headers: $headers)';
}

bool _mapsEqual<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
