/// The type of playlist detected from file content or URL.
///
/// Used by playlist parsers to identify the format of playlist files
/// and determine how they should be handled.
///
/// ## Adaptive Streaming Types
///
/// - [hlsMaster], [hlsMedia] — HLS streams (supported on all platforms)
/// - [dash] — DASH streams (Android and Web only)
///
/// These are treated as single video sources and passed directly to the
/// native player for adaptive bitrate handling.
///
/// ## Multi-Video Playlist Types
///
/// - [m3uSimple], [pls], [xspf], [jspf], [asx], [wpl], [cue]
///
/// These are parsed into a list of video sources for playlist navigation.
enum PlaylistType {
  /// HLS adaptive streaming master playlist (contains #EXT-X-STREAM-INF).
  ///
  /// Contains multiple quality variants. Should be treated as a single
  /// adaptive video source - the native player handles quality switching.
  ///
  /// Supported on all platforms (iOS, Android, Web, macOS).
  hlsMaster,

  /// HLS media playlist (contains #EXT-X-TARGETDURATION).
  ///
  /// Contains video segments at a single quality level. Should be treated
  /// as a single video source.
  ///
  /// Supported on all platforms (iOS, Android, Web, macOS).
  hlsMedia,

  /// DASH adaptive streaming manifest (MPD - Media Presentation Description).
  ///
  /// An XML-based format for adaptive streaming. Should be treated as a
  /// single adaptive video source - the native player handles quality switching.
  ///
  /// **Platform Support:**
  /// - ✅ Android — ExoPlayer native support
  /// - ✅ Web — dash.js library integration
  /// - ❌ iOS — AVPlayer does not support DASH
  /// - ❌ macOS — AVPlayer does not support DASH
  ///
  /// For Apple platforms, use HLS (.m3u8) instead of DASH (.mpd).
  dash,

  /// Simple M3U/M3U8 playlist with multiple video URLs.
  /// Should be parsed into a list of video sources.
  m3uSimple,

  /// PLS playlist format.
  pls,

  /// XSPF (XML Shareable Playlist Format).
  xspf,

  /// JSPF (JSON Shareable Playlist Format).
  jspf,

  /// ASX (Advanced Stream Redirector - Microsoft).
  asx,

  /// WPL (Windows Media Player Playlist).
  wpl,

  /// CUE (Cue Sheet - describes tracks within a single file).
  cue,

  /// Unknown or unsupported format.
  unknown,
}
