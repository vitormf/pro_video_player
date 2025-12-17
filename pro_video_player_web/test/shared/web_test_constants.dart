/// Test media URLs for web video player tests.
class WebTestMedia {
  /// Standard MP4 video URL.
  static const mp4Url = 'https://example.com/video.mp4';

  /// HLS manifest URL (.m3u8).
  static const hlsUrl = 'https://example.com/stream.m3u8';

  /// DASH manifest URL (.mpd).
  static const dashUrl = 'https://example.com/manifest.mpd';

  /// WebM video URL.
  static const webmUrl = 'https://example.com/video.webm';

  /// WebVTT subtitle URL.
  static const vttSubtitle = 'https://example.com/subs.vtt';

  /// SRT subtitle URL.
  static const srtSubtitle = 'https://example.com/subs.srt';

  /// SSA subtitle URL.
  static const ssaSubtitle = 'https://example.com/subs.ssa';

  /// ASS subtitle URL.
  static const assSubtitle = 'https://example.com/subs.ass';

  /// TTML subtitle URL.
  static const ttmlSubtitle = 'https://example.com/subs.ttml';
}

/// Test delays for async operations in web video player tests.
class WebTestDelays {
  /// Short delay for event propagation (50ms).
  static const eventPropagation = Duration(milliseconds: 50);

  /// Delay for network retry operations (1s).
  static const networkRetry = Duration(seconds: 1);

  /// Delay for HLS manifest loading (200ms).
  static const hlsManifestLoad = Duration(milliseconds: 200);

  /// Delay for DASH manifest loading (200ms).
  static const dashManifestLoad = Duration(milliseconds: 200);

  /// Delay for wake lock request (100ms).
  static const wakeLockRequest = Duration(milliseconds: 100);

  /// Delay for video element ready state changes (100ms).
  static const readyStateChange = Duration(milliseconds: 100);

  /// Delay for library loading (200ms).
  static const libraryLoad = Duration(milliseconds: 200);
}

/// Test video dimensions.
class WebTestSizes {
  /// Standard HD video width.
  static const videoWidth = 1920.0;

  /// Standard HD video height.
  static const videoHeight = 1080.0;

  /// 720p video width.
  static const video720pWidth = 1280.0;

  /// 720p video height.
  static const video720pHeight = 720.0;

  /// 480p video width.
  static const video480pWidth = 854.0;

  /// 480p video height.
  static const video480pHeight = 480.0;
}

/// Test video metadata.
class WebTestMetadata {
  /// Standard test video duration (60 seconds).
  static const duration = Duration(seconds: 60);

  /// Sample bitrate (5 Mbps).
  static const bitrate = 5000000;

  /// Sample frame rate (30 fps).
  static const frameRate = 30.0;

  /// Sample video codec.
  static const videoCodec = 'avc1.64001F';

  /// Sample audio codec.
  static const audioCodec = 'mp4a.40.2';
}
