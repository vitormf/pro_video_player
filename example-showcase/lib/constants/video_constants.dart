/// Centralized video URLs and paths used throughout the example app.
library;

/// Network video URLs for testing and demos.
class VideoUrls {
  VideoUrls._();

  // Google Cloud Storage sample videos
  static const bigBuckBunny = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
  static const elephantsDream = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4';
  static const forBiggerBlazes =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
  static const forBiggerEscapes =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4';
  static const forBiggerFun = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4';

  // HLS streaming URLs
  static const appleHlsBipbop =
      'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8';
  static const shakaAngelOneHls = 'https://storage.googleapis.com/shaka-demo-assets/angel-one-hls/hls.m3u8';
  static const bitmovinSintelHls = 'https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8';
  static const awsBipbopHls = 'https://d2zihajmogu5jn.cloudfront.net/bipbop-advanced/bipbop_16x9_variant.m3u8';

  // DASH streaming URLs (supported on Android and Web with dash.js)
  static const shakaSintelDash = 'https://storage.googleapis.com/shaka-demo-assets/sintel/dash.mpd';
  static const bitmovinSintelDash = 'https://bitmovin-a.akamaihd.net/content/sintel/sintel.mpd';
  static const shakaAngelOneDash = 'https://storage.googleapis.com/shaka-demo-assets/angel-one/dash.mpd';

  // Videos with embedded subtitles (for testing embedded subtitle extraction)
  // Bitmovin Sintel has embedded subtitles in 4 languages (en, de, es, fr)
  // Shaka Angel One has embedded subtitles in 4 languages (en, el, fr, pt-BR)
  static const bitmovinSintelWithSubsHls = 'https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8';
  static const bitmovinSintelWithSubsDash = 'https://bitmovin-a.akamaihd.net/content/sintel/sintel.mpd';
  static const shakaAngelOneWithSubsHls = 'https://storage.googleapis.com/shaka-demo-assets/angel-one-hls/hls.m3u8';
  static const shakaAngelOneWithSubsDash = 'https://storage.googleapis.com/shaka-demo-assets/angel-one/dash.mpd';

  // Multi-video playlist file (M3U with multiple distinct videos)
  // Note: This is now a local asset. Use PlaylistAssets.sampleMultiVideo for asset path.
  // For testing remote playlist loading, you can host the playlist file on a CDN.
  @Deprecated('Use PlaylistAssets.sampleMultiVideo for local asset path')
  static const multiVideoPlaylistM3u = 'assets/playlists/sample_multi_video.m3u';

  // Invalid URLs for error testing
  static const invalidUrl = 'https://invalid.example.com/video.mp4';
  static const invalidTestUrl = 'https://invalid-url-that-does-not-exist.com/video.mp4';

  // Placeholder/example URLs
  static const exampleUrl = 'https://example.com';
}

/// Asset video paths.
class VideoAssets {
  VideoAssets._();

  static const sampleVideo = 'assets/videos/sample.mp4';

  /// Sample video with embedded chapter markers.
  ///
  /// A 15-second clip from Big Buck Bunny with 3 chapters:
  /// - Opening Scene (0:00 - 0:05)
  /// - The Meadow (0:05 - 0:10)
  /// - Butterflies (0:10 - 0:15)
  static const sampleWithChapters = 'assets/videos/sample_with_chapters.mp4';
}

/// Asset playlist paths.
class PlaylistAssets {
  PlaylistAssets._();

  /// Sample M3U playlist with 4 Google Cloud Storage video URLs.
  static const sampleMultiVideo = 'assets/playlists/sample_multi_video.m3u';
}

/// External subtitle URLs for testing external subtitle loading.
class SubtitleUrls {
  SubtitleUrls._();

  // Sintel movie subtitles from Bitmovin (public domain, VTT format)
  static const sintelEnglishVtt = 'https://bitmovin-a.akamaihd.net/content/sintel/subtitles/subtitles_en.vtt';
  static const sintelSpanishVtt = 'https://bitmovin-a.akamaihd.net/content/sintel/subtitles/subtitles_es.vtt';
  static const sintelGermanVtt = 'https://bitmovin-a.akamaihd.net/content/sintel/subtitles/subtitles_de.vtt';
  static const sintelFrenchVtt = 'https://bitmovin-a.akamaihd.net/content/sintel/subtitles/subtitles_fr.vtt';

  // Sample subtitle files in different formats (from mantas-done/subtitles test files)
  // These are short test files useful for demonstrating format support
  static const sampleSrt = 'https://raw.githubusercontent.com/mantas-done/subtitles/master/tests/files/srt.srt';
  static const sampleAss = 'https://raw.githubusercontent.com/mantas-done/subtitles/master/tests/files/ass.ass';
  static const sampleTtml = 'https://raw.githubusercontent.com/mantas-done/subtitles/master/tests/files/ttml.ttml';
  static const sampleVtt = 'https://raw.githubusercontent.com/mantas-done/subtitles/master/tests/files/vtt.vtt';

  // Rich text formatted subtitle samples (bundled as assets)
  // These demonstrate bold, italic, underline, colors, font sizes, and other formatting
  static const richTextAss = 'assets/subtitles/sample_rich_text.ass';
  static const richTextVtt = 'assets/subtitles/sample_rich_text.vtt';
  static const richTextTtml = 'assets/subtitles/sample_rich_text.ttml';
}

/// Common video lists for demos and testing.
class VideoLists {
  VideoLists._();

  /// Standard list of MP4 videos from Google Cloud Storage.
  static const List<String> googleCloudSamples = [
    VideoUrls.bigBuckBunny,
    VideoUrls.elephantsDream,
    VideoUrls.forBiggerBlazes,
    VideoUrls.forBiggerEscapes,
  ];

  /// List of HLS streaming sources.
  static const List<String> hlsSources = [
    VideoUrls.shakaAngelOneHls,
    VideoUrls.bitmovinSintelHls,
    VideoUrls.awsBipbopHls,
  ];

  /// List of DASH streaming sources.
  /// Note: DASH is supported on Android (ExoPlayer) and Web (with dash.js).
  /// iOS/macOS do NOT support DASH natively - use HLS instead.
  static const List<String> dashSources = [
    VideoUrls.shakaSintelDash,
    VideoUrls.bitmovinSintelDash,
    VideoUrls.shakaAngelOneDash,
  ];

  /// Videos with embedded subtitles for testing subtitle extraction.
  /// Bitmovin Sintel and Shaka Angel One have embedded text tracks.
  static const List<String> embeddedSubtitleSources = [
    VideoUrls.shakaAngelOneWithSubsHls, // HLS with WebVTT subs (en, el, fr, pt-BR)
    VideoUrls.bitmovinSintelWithSubsHls, // HLS with WebVTT subs (en, de, es, fr)
    VideoUrls.shakaAngelOneWithSubsDash, // DASH with embedded subs (Android/Web)
    VideoUrls.bitmovinSintelWithSubsDash, // DASH with embedded subs (Android/Web)
  ];
}
