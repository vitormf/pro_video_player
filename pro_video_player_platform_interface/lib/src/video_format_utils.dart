import 'dart:math' as math;

/// Utilities for video format detection, quality labels, and bitrate formatting.
///
/// These utilities consolidate logic that was duplicated across platform
/// implementations (iOS/macOS, Android, Web).
class VideoFormatUtils {
  VideoFormatUtils._();

  /// Gets a human-readable quality label from video height.
  ///
  /// Returns labels like "4K", "1080p", "720p", etc.
  /// If [frameRate] is provided and > 30, includes it in the label (e.g., "1080p60").
  ///
  /// Example:
  /// ```dart
  /// VideoFormatUtils.getQualityLabel(1080) // "1080p"
  /// VideoFormatUtils.getQualityLabel(1080, 60) // "1080p60"
  /// VideoFormatUtils.getQualityLabel(2160) // "4K"
  /// ```
  static String getQualityLabel(int height, [double? frameRate]) {
    final label = switch (height) {
      >= 2160 => '4K',
      >= 1440 => '1440p',
      >= 1080 => '1080p',
      >= 720 => '720p',
      >= 480 => '480p',
      >= 360 => '360p',
      >= 240 => '240p',
      >= 144 => '144p',
      _ => '${height}p',
    };

    if (frameRate != null && frameRate > 30) {
      return '$label${frameRate.toInt()}';
    }
    return label;
  }

  /// Formats a bitrate value to a human-readable string.
  ///
  /// Returns values like "2.5 Mbps", "500 Kbps", etc.
  ///
  /// Example:
  /// ```dart
  /// VideoFormatUtils.formatBitrate(2500000) // "2.5 Mbps"
  /// VideoFormatUtils.formatBitrate(500000) // "500 Kbps"
  /// VideoFormatUtils.formatBitrate(800) // "800 bps"
  /// ```
  static String formatBitrate(int bitrate) {
    if (bitrate >= 1000000) {
      return '${(bitrate / 1000000).toStringAsFixed(1)} Mbps';
    } else if (bitrate >= 1000) {
      return '${bitrate ~/ 1000} Kbps';
    } else {
      return '$bitrate bps';
    }
  }

  /// Calculates exponential backoff delay for retries.
  ///
  /// Returns a duration based on retry count using exponential backoff.
  /// The delay doubles with each retry up to [maxDelay].
  ///
  /// Example:
  /// ```dart
  /// VideoFormatUtils.calculateExponentialBackoff(0) // 1 second
  /// VideoFormatUtils.calculateExponentialBackoff(1) // 2 seconds
  /// VideoFormatUtils.calculateExponentialBackoff(2) // 4 seconds
  /// VideoFormatUtils.calculateExponentialBackoff(10) // 30 seconds (capped)
  /// ```
  static Duration calculateExponentialBackoff(
    int retryCount, {
    Duration baseDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
  }) {
    if (retryCount < 0) return baseDelay;
    final delay = baseDelay.inMilliseconds * (1 << math.min(retryCount, 30));
    return Duration(milliseconds: math.min(delay, maxDelay.inMilliseconds));
  }

  /// Determines whether a bandwidth update should be sent based on thresholds.
  ///
  /// Returns `true` if the bandwidth change exceeds [changeThreshold] (default 10%).
  /// Returns `true` for the first bandwidth report (when [lastSentBandwidth] is 0).
  /// Returns `false` if [currentBandwidth] is invalid (<= 0).
  ///
  /// This helps throttle bandwidth events to avoid flooding the event stream.
  ///
  /// Example:
  /// ```dart
  /// VideoFormatUtils.shouldUpdateBandwidth(1100000, 1000000) // false (10% change)
  /// VideoFormatUtils.shouldUpdateBandwidth(1200000, 1000000) // true (20% change)
  /// VideoFormatUtils.shouldUpdateBandwidth(500000, 0) // true (first report)
  /// ```
  static bool shouldUpdateBandwidth(int currentBandwidth, int lastSentBandwidth, {double changeThreshold = 0.1}) {
    if (currentBandwidth <= 0) return false;
    if (lastSentBandwidth <= 0) return true;
    final threshold = (lastSentBandwidth * changeThreshold).round();
    return (currentBandwidth - lastSentBandwidth).abs() >= threshold;
  }

  /// Determines whether a position update should be sent based on threshold.
  ///
  /// Returns `true` if the position change exceeds [thresholdMs] (default 100ms).
  /// This helps throttle position events to avoid flooding the event stream.
  ///
  /// Example:
  /// ```dart
  /// VideoFormatUtils.shouldUpdatePosition(1050, 1000) // false (50ms change)
  /// VideoFormatUtils.shouldUpdatePosition(1200, 1000) // true (200ms change)
  /// ```
  static bool shouldUpdatePosition(int currentPositionMs, int lastSentPositionMs, {int thresholdMs = 100}) =>
      (currentPositionMs - lastSentPositionMs).abs() >= thresholdMs;
}

// Note: SubtitleFormatDetector was removed as redundant.
// Use SubtitleFormat.fromUrl() instead - it's the canonical implementation.

/// Utilities for detecting container/video formats.
class ContainerFormatDetector {
  ContainerFormatDetector._();

  /// Detects the container format from a URL or file path.
  ///
  /// Returns `null` if the format cannot be determined.
  ///
  /// Example:
  /// ```dart
  /// ContainerFormatDetector.detectFromUrl('https://example.com/video.mp4') // 'mp4'
  /// ContainerFormatDetector.detectFromUrl('https://example.com/stream.m3u8') // 'hls'
  /// ContainerFormatDetector.detectFromUrl('https://example.com/manifest.mpd') // 'dash'
  /// ```
  static String? detectFromUrl(String? url) {
    if (url == null) return null;

    // Remove query parameters and fragment for extension detection
    final pathOnly = url.split('?').first.split('#').first.toLowerCase();

    if (pathOnly.endsWith('.mp4')) return 'mp4';
    if (pathOnly.endsWith('.m4v')) return 'mp4';
    if (pathOnly.endsWith('.mkv')) return 'matroska';
    if (pathOnly.endsWith('.webm')) return 'webm';
    if (pathOnly.endsWith('.m3u8')) return 'hls';
    if (pathOnly.endsWith('.mpd')) return 'dash';
    if (pathOnly.endsWith('.mov')) return 'quicktime';
    if (pathOnly.endsWith('.flv')) return 'flash';
    if (pathOnly.endsWith('.ts')) return 'mpegts';
    if (pathOnly.endsWith('.avi')) return 'avi';
    if (pathOnly.endsWith('.wmv')) return 'wmv';

    return null;
  }

  /// Returns `true` if the URL appears to be an adaptive streaming source.
  ///
  /// Example:
  /// ```dart
  /// ContainerFormatDetector.isAdaptiveStreaming('https://example.com/stream.m3u8') // true
  /// ContainerFormatDetector.isAdaptiveStreaming('https://example.com/video.mp4') // false
  /// ```
  static bool isAdaptiveStreaming(String url) {
    final format = detectFromUrl(url);
    return format == 'hls' || format == 'dash';
  }
}

/// Utilities for parsing and creating track identifiers.
class TrackIdParser {
  TrackIdParser._();

  /// Parses a track ID string in the format "groupIndex:trackIndex".
  ///
  /// Returns a record with (groupIndex, trackIndex), or `null` if parsing fails.
  ///
  /// Example:
  /// ```dart
  /// TrackIdParser.parse('0:1') // (0, 1)
  /// TrackIdParser.parse('invalid') // null
  /// ```
  static (int groupIndex, int trackIndex)? parse(String trackId) {
    final parts = trackId.split(':');
    if (parts.length != 2) return null;

    final group = int.tryParse(parts[0]);
    final track = int.tryParse(parts[1]);
    if (group == null || track == null) return null;

    return (group, track);
  }

  /// Creates a track ID string from group and track indices.
  ///
  /// Example:
  /// ```dart
  /// TrackIdParser.create(0, 1) // '0:1'
  /// ```
  static String create(int groupIndex, int trackIndex) => '$groupIndex:$trackIndex';
}
