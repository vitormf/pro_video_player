/// Test media URLs and paths for E2E integration tests.
///
/// These are REAL working video URLs that can be used in integration tests
/// on actual devices/simulators/browsers. Unlike unit test mocks, E2E tests
/// need actual playable media files.
///
/// All videos are public domain or openly licensed test content.
library;

/// Network video URLs for E2E testing.
///
/// These URLs point to real video files hosted on reliable CDNs.
/// Use these for E2E tests that verify video playback, controls, and features.
class E2ETestMedia {
  E2ETestMedia._();

  // ==========================================================================
  // Primary Test Videos (MP4)
  // ==========================================================================

  /// Big Buck Bunny - 596 seconds (~10 minutes), 1080p, public domain.
  ///
  /// Best for: General playback testing, seeking, controls, fullscreen.
  /// Fast loading, reliable, widely used test video.
  static const bigBuckBunny = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  /// Elephants Dream - 653 seconds (~11 minutes), 1080p, Creative Commons.
  ///
  /// Best for: Longer video testing, playlist testing, chapter navigation.
  static const elephantsDream = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4';

  /// For Bigger Blazes - 15 seconds, 720p.
  ///
  /// Best for: Quick loading tests, minimal test time, fast initialization.
  static const forBiggerBlazes =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';

  /// For Bigger Fun - 60 seconds, 1080p.
  ///
  /// Best for: Medium-length tests, playback position verification.
  static const forBiggerFun = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4';

  // ==========================================================================
  // Default Test Video (Use this unless you need something specific)
  // ==========================================================================

  /// Default video for E2E tests when no specific video is needed.
  ///
  /// Currently: Big Buck Bunny (~10 min, reliable, well-known).
  /// Good balance of: loading time, duration for testing, reliability.
  static const defaultVideo = bigBuckBunny;

  /// Quick-loading test video for fast tests (<20 seconds).
  ///
  /// Currently: For Bigger Blazes (15 sec).
  /// Use when test doesn't need long video duration.
  static const quickVideo = forBiggerBlazes;

  // ==========================================================================
  // HLS Streaming URLs (for adaptive streaming tests)
  // ==========================================================================

  /// Apple HLS Bipbop - Multi-bitrate adaptive streaming test.
  ///
  /// Best for: HLS testing, quality switching, adaptive bitrate.
  /// Platform support: iOS, Android, macOS, Web (all platforms).
  static const hlsBipbop =
      'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8';

  /// Bitmovin Sintel HLS - Public domain movie with chapters.
  ///
  /// Best for: HLS testing, subtitle testing, chapter testing.
  /// Duration: ~15 minutes, has embedded subtitles (en, de, es, fr).
  static const sintelHls = 'https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8';

  /// Shaka Angel One HLS - Short test content.
  ///
  /// Best for: HLS testing, subtitle testing.
  /// Duration: ~2 minutes, has embedded subtitles (en, el, fr, pt-BR).
  static const angelOneHls = 'https://storage.googleapis.com/shaka-demo-assets/angel-one-hls/hls.m3u8';

  // ==========================================================================
  // DASH Streaming URLs (Android + Web only)
  // ==========================================================================

  /// Shaka Sintel DASH - Public domain movie.
  ///
  /// Best for: DASH testing on Android/Web.
  /// Platform support: Android (ExoPlayer), Web (dash.js). NOT supported on iOS/macOS.
  static const sintelDash = 'https://storage.googleapis.com/shaka-demo-assets/sintel/dash.mpd';

  /// Shaka Angel One DASH - Short test content.
  ///
  /// Best for: Quick DASH tests, subtitle testing.
  /// Platform support: Android, Web. NOT iOS/macOS.
  static const angelOneDash = 'https://storage.googleapis.com/shaka-demo-assets/angel-one/dash.mpd';

  // ==========================================================================
  // Videos with Embedded Subtitles
  // ==========================================================================

  /// Bitmovin Sintel with embedded subtitles (HLS).
  ///
  /// Languages: English, German, Spanish, French
  /// Best for: Testing embedded subtitle extraction and display.
  static const sintelWithSubsHls = 'https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8';

  /// Shaka Angel One with embedded subtitles (HLS).
  ///
  /// Languages: English, Greek, French, Portuguese (Brazil)
  /// Best for: Testing embedded subtitle extraction, language selection.
  static const angelOneWithSubsHls = 'https://storage.googleapis.com/shaka-demo-assets/angel-one-hls/hls.m3u8';

  // ==========================================================================
  // External Subtitle URLs (for testing external subtitle loading)
  // ==========================================================================

  /// Sintel English subtitles (WebVTT).
  static const sintelSubtitlesEn = 'https://bitmovin-a.akamaihd.net/content/sintel/subtitles/subtitles_en.vtt';

  /// Sintel Spanish subtitles (WebVTT).
  static const sintelSubtitlesEs = 'https://bitmovin-a.akamaihd.net/content/sintel/subtitles/subtitles_es.vtt';

  /// Sintel German subtitles (WebVTT).
  static const sintelSubtitlesDe = 'https://bitmovin-a.akamaihd.net/content/sintel/subtitles/subtitles_de.vtt';

  // ==========================================================================
  // Invalid/Error Testing URLs
  // ==========================================================================

  /// Invalid URL for error testing (404 response expected).
  static const invalidUrl = 'https://invalid-url-that-does-not-exist.example.com/video.mp4';

  /// Invalid domain for network error testing.
  static const invalidDomain = 'https://nonexistent.invalid/video.mp4';

  // ==========================================================================
  // Asset Paths (for testing local videos in example app)
  // ==========================================================================

  /// Sample video asset path (bundled with example app).
  static const assetSampleVideo = 'assets/videos/sample.mp4';

  /// Sample video with chapters (bundled with example app).
  ///
  /// 15-second clip with 3 chapters:
  /// - Opening Scene (0:00 - 0:05)
  /// - The Meadow (0:05 - 0:10)
  /// - Butterflies (0:10 - 0:15)
  static const assetWithChapters = 'assets/videos/sample_with_chapters.mp4';

  // ==========================================================================
  // Video Lists for Multi-Video Tests
  // ==========================================================================

  /// Short list for quick multi-video tests (3 videos, all quick-loading).
  static const List<String> shortPlaylist = [
    forBiggerBlazes, // 15 sec
    forBiggerFun, // 60 sec
    bigBuckBunny, // 10 min (if test needs longer video)
  ];

  /// Standard playlist for comprehensive testing (4 diverse videos).
  static const List<String> standardPlaylist = [bigBuckBunny, elephantsDream, forBiggerBlazes, forBiggerFun];

  /// HLS playlist for adaptive streaming tests.
  static const List<String> hlsPlaylist = [angelOneHls, sintelHls, hlsBipbop];
}

/// Video metadata for E2E test videos.
///
/// Known durations and properties of test videos for assertion purposes.
class E2ETestMetadata {
  E2ETestMetadata._();

  /// Big Buck Bunny duration: ~10 minutes (596 seconds).
  static const bigBuckBunnyDuration = Duration(seconds: 596);

  /// Elephants Dream duration: ~11 minutes (653 seconds).
  static const elephantsDreamDuration = Duration(seconds: 653);

  /// For Bigger Blazes duration: 15 seconds.
  static const forBiggerBlazesDuration = Duration(seconds: 15);

  /// For Bigger Fun duration: 60 seconds.
  static const forBiggerFunDuration = Duration(seconds: 60);

  /// Sintel (Bitmovin) duration: ~15 minutes (888 seconds).
  static const sintelDuration = Duration(seconds: 888);

  /// Angel One duration: ~2 minutes (126 seconds).
  static const angelOneDuration = Duration(seconds: 126);

  /// Standard aspect ratio for test videos (16:9).
  static const standardAspectRatio = 16.0 / 9.0;

  /// 1080p resolution.
  static const hd1080Width = 1920;
  static const hd1080Height = 1080;

  /// 720p resolution.
  static const hd720Width = 1280;
  static const hd720Height = 720;
}
