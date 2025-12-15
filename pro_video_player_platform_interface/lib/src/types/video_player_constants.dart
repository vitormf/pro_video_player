/// Shared constants and utility functions for video player implementations.
///
/// This class centralizes lookup tables and mappings that are used across
/// all platform implementations, ensuring consistent behavior and reducing
/// code duplication in native code.
///
/// Following the Dart-First Implementation Principle, general lookup logic
/// is implemented here in Dart rather than duplicated in native code.
class VideoPlayerConstants {
  VideoPlayerConstants._();

  // ===========================================================================
  // Language Code to Display Name Mapping
  // ===========================================================================

  /// Maps ISO 639-1/639-2 language codes to human-readable display names.
  ///
  /// Supports both 2-letter (ISO 639-1) and 3-letter (ISO 639-2) codes.
  /// Returns the uppercase language code if not found in the map.
  ///
  /// Example:
  /// ```dart
  /// VideoPlayerConstants.getLanguageDisplayName('en'); // 'English'
  /// VideoPlayerConstants.getLanguageDisplayName('spa'); // 'Spanish'
  /// VideoPlayerConstants.getLanguageDisplayName('xyz'); // 'XYZ'
  /// ```
  static String getLanguageDisplayName(String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) {
      return 'Unknown';
    }

    final code = languageCode.toLowerCase();
    return _languageNames[code] ?? languageCode.toUpperCase();
  }

  /// Internal map of language codes to display names.
  ///
  /// Includes both ISO 639-1 (2-letter) and ISO 639-2 (3-letter) codes
  /// for maximum compatibility with different video sources.
  static const Map<String, String> _languageNames = {
    // ISO 639-1 (2-letter) and ISO 639-2 (3-letter) codes
    'en': 'English',
    'eng': 'English',
    'es': 'Spanish',
    'spa': 'Spanish',
    'fr': 'French',
    'fra': 'French',
    'fre': 'French',
    'de': 'German',
    'deu': 'German',
    'ger': 'German',
    'it': 'Italian',
    'ita': 'Italian',
    'pt': 'Portuguese',
    'por': 'Portuguese',
    'ru': 'Russian',
    'rus': 'Russian',
    'ja': 'Japanese',
    'jpn': 'Japanese',
    'zh': 'Chinese',
    'zho': 'Chinese',
    'chi': 'Chinese',
    'ko': 'Korean',
    'kor': 'Korean',
    'ar': 'Arabic',
    'ara': 'Arabic',
    'hi': 'Hindi',
    'hin': 'Hindi',
    'nl': 'Dutch',
    'nld': 'Dutch',
    'dut': 'Dutch',
    'pl': 'Polish',
    'pol': 'Polish',
    'tr': 'Turkish',
    'tur': 'Turkish',
    'sv': 'Swedish',
    'swe': 'Swedish',
    'da': 'Danish',
    'dan': 'Danish',
    'no': 'Norwegian',
    'nor': 'Norwegian',
    'fi': 'Finnish',
    'fin': 'Finnish',
    'cs': 'Czech',
    'ces': 'Czech',
    'cze': 'Czech',
    'el': 'Greek',
    'ell': 'Greek',
    'gre': 'Greek',
    'he': 'Hebrew',
    'heb': 'Hebrew',
    'th': 'Thai',
    'tha': 'Thai',
    'vi': 'Vietnamese',
    'vie': 'Vietnamese',
    'id': 'Indonesian',
    'ind': 'Indonesian',
    'ms': 'Malay',
    'msa': 'Malay',
    'may': 'Malay',
    'uk': 'Ukrainian',
    'ukr': 'Ukrainian',
    'ro': 'Romanian',
    'ron': 'Romanian',
    'rum': 'Romanian',
    'hu': 'Hungarian',
    'hun': 'Hungarian',
    'ca': 'Catalan',
    'cat': 'Catalan',
    'bg': 'Bulgarian',
    'bul': 'Bulgarian',
    'hr': 'Croatian',
    'hrv': 'Croatian',
    'sk': 'Slovak',
    'slk': 'Slovak',
    'slo': 'Slovak',
    'sl': 'Slovenian',
    'slv': 'Slovenian',
    'sr': 'Serbian',
    'srp': 'Serbian',
    'lt': 'Lithuanian',
    'lit': 'Lithuanian',
    'lv': 'Latvian',
    'lav': 'Latvian',
    'et': 'Estonian',
    'est': 'Estonian',
    'bn': 'Bengali',
    'ben': 'Bengali',
    'ta': 'Tamil',
    'tam': 'Tamil',
    'te': 'Telugu',
    'tel': 'Telugu',
    'mr': 'Marathi',
    'mar': 'Marathi',
    'gu': 'Gujarati',
    'guj': 'Gujarati',
    'kn': 'Kannada',
    'kan': 'Kannada',
    'ml': 'Malayalam',
    'mal': 'Malayalam',
    'pa': 'Punjabi',
    'pan': 'Punjabi',
    'fa': 'Persian',
    'fas': 'Persian',
    'per': 'Persian',
    'ur': 'Urdu',
    'urd': 'Urdu',
    'sw': 'Swahili',
    'swa': 'Swahili',
    'af': 'Afrikaans',
    'afr': 'Afrikaans',
    'fil': 'Filipino',
    'tl': 'Tagalog',
    'tgl': 'Tagalog',
    // Undetermined/special codes
    'und': 'Undetermined',
    'mul': 'Multiple Languages',
    'zxx': 'No Linguistic Content',
  };

  // ===========================================================================
  // Buffering Tier Durations
  // ===========================================================================

  /// Returns the preferred forward buffer duration in seconds for iOS/macOS.
  ///
  /// A value of 0 means automatic (system decides).
  ///
  /// Example:
  /// ```dart
  /// VideoPlayerConstants.getBufferDurationForTier('high'); // 30.0
  /// VideoPlayerConstants.getBufferDurationForTier('medium'); // 0.0 (auto)
  /// ```
  static double getBufferDurationForTier(String? tier) {
    if (tier == null) return 0;

    switch (tier.toLowerCase()) {
      case 'min':
        return 2; // 2 seconds
      case 'low':
        return 5; // 5 seconds
      case 'medium':
        return 0; // 0 = automatic (system decides)
      case 'high':
        return 30; // 30 seconds
      case 'max':
        return 60; // 60 seconds
      default:
        return 0; // Default to automatic
    }
  }

  /// Buffering tier configuration for Android ExoPlayer.
  ///
  /// Returns a map with buffer configuration values in milliseconds.
  static Map<String, int> getExoPlayerBufferConfig(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'min':
        return {
          'minBufferMs': 500,
          'maxBufferMs': 2000,
          'bufferForPlaybackMs': 500,
          'bufferForPlaybackAfterRebufferMs': 1000,
        };
      case 'low':
        return {
          'minBufferMs': 1000,
          'maxBufferMs': 5000,
          'bufferForPlaybackMs': 1000,
          'bufferForPlaybackAfterRebufferMs': 2000,
        };
      case 'high':
        return {
          'minBufferMs': 5000,
          'maxBufferMs': 30000,
          'bufferForPlaybackMs': 2500,
          'bufferForPlaybackAfterRebufferMs': 5000,
        };
      case 'max':
        return {
          'minBufferMs': 10000,
          'maxBufferMs': 60000,
          'bufferForPlaybackMs': 5000,
          'bufferForPlaybackAfterRebufferMs': 10000,
        };
      case 'medium':
      default:
        return {
          'minBufferMs': 2500,
          'maxBufferMs': 15000,
          'bufferForPlaybackMs': 2500,
          'bufferForPlaybackAfterRebufferMs': 5000,
        };
    }
  }

  // ===========================================================================
  // Video Scaling Mode
  // ===========================================================================

  /// Video gravity value for iOS/macOS AVPlayer.
  ///
  /// Maps scaling mode to AVLayerVideoGravity string values.
  static String getAVLayerVideoGravity(String? mode) {
    switch (mode?.toLowerCase()) {
      case 'fit':
        return 'resizeAspect';
      case 'fill':
        return 'resizeAspectFill';
      case 'stretch':
        return 'resize';
      default:
        return 'resizeAspect';
    }
  }

  /// Resize mode value for Android ExoPlayer.
  ///
  /// Maps scaling mode to AspectRatioFrameLayout resize mode constants.
  /// Returns the integer constant value used by ExoPlayer.
  static int getExoPlayerResizeMode(String? mode) {
    switch (mode?.toLowerCase()) {
      case 'fit':
        return 0; // RESIZE_MODE_FIT
      case 'fill':
        return 4; // RESIZE_MODE_ZOOM
      case 'stretch':
        return 3; // RESIZE_MODE_FILL
      default:
        return 0; // RESIZE_MODE_FIT
    }
  }

  /// CSS object-fit value for Web HTML5 video.
  static String getCssObjectFit(String? mode) {
    switch (mode?.toLowerCase()) {
      case 'fit':
        return 'contain';
      case 'fill':
        return 'cover';
      case 'stretch':
        return 'fill';
      default:
        return 'contain';
    }
  }

  // ===========================================================================
  // Track ID Utilities
  // ===========================================================================

  /// Formats a track ID from group and track indices.
  ///
  /// Uses the standard format "groupIndex:trackIndex" for consistency
  /// across all platforms.
  ///
  /// Example:
  /// ```dart
  /// VideoPlayerConstants.formatTrackId(0, 1); // '0:1'
  /// ```
  static String formatTrackId(int groupIndex, int trackIndex) => '$groupIndex:$trackIndex';

  /// Parses a track ID into group and track indices.
  ///
  /// Returns null if the format is invalid.
  ///
  /// Example:
  /// ```dart
  /// VideoPlayerConstants.parseTrackId('0:1'); // (groupIndex: 0, trackIndex: 1)
  /// VideoPlayerConstants.parseTrackId('invalid'); // null
  /// ```
  static ({int groupIndex, int trackIndex})? parseTrackId(String? id) {
    if (id == null || id.isEmpty) return null;

    final parts = id.split(':');
    if (parts.length != 2) return null;

    final groupIndex = int.tryParse(parts[0]);
    final trackIndex = int.tryParse(parts[1]);

    if (groupIndex == null || trackIndex == null) return null;

    return (groupIndex: groupIndex, trackIndex: trackIndex);
  }

  // ===========================================================================
  // Network Resilience Constants
  // ===========================================================================

  /// Default maximum number of network retries.
  static const int defaultMaxNetworkRetries = 3;

  /// Maximum retry delay in seconds (cap for exponential backoff).
  static const int maxRetryDelaySeconds = 30;

  /// Calculates the retry delay using exponential backoff.
  ///
  /// The delay doubles with each retry attempt, capped at [maxRetryDelaySeconds].
  ///
  /// Example:
  /// ```dart
  /// VideoPlayerConstants.calculateRetryDelay(0); // Duration(seconds: 1)
  /// VideoPlayerConstants.calculateRetryDelay(1); // Duration(seconds: 2)
  /// VideoPlayerConstants.calculateRetryDelay(2); // Duration(seconds: 4)
  /// VideoPlayerConstants.calculateRetryDelay(5); // Duration(seconds: 30) (capped)
  /// ```
  static Duration calculateRetryDelay(int retryCount) =>
      Duration(seconds: (1 << retryCount).clamp(1, maxRetryDelaySeconds));
}
