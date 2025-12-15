import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Pure Dart helper functions for web video player.
///
/// These functions are extracted to enable unit testing without browser dependencies.

/// Checks if a URL is an HLS stream.
///
/// Returns `true` if the URL ends with `.m3u8` or contains `.m3u8?`.
bool isHlsUrl(String url) {
  final lowerUrl = url.toLowerCase();
  return lowerUrl.endsWith('.m3u8') || lowerUrl.contains('.m3u8?');
}

/// Checks if a URL is a DASH stream (MPD).
///
/// Returns `true` if the URL ends with `.mpd` or contains `.mpd?`.
bool isDashUrl(String url) {
  final lowerUrl = url.toLowerCase();
  return lowerUrl.endsWith('.mpd') || lowerUrl.contains('.mpd?');
}

/// Converts [VideoScalingMode] to CSS object-fit value.
///
/// - [VideoScalingMode.fit] -> 'contain' (letterboxed)
/// - [VideoScalingMode.fill] -> 'cover' (cropped)
/// - [VideoScalingMode.stretch] -> 'fill' (distorted)
String getObjectFitFromScalingMode(VideoScalingMode scalingMode) {
  switch (scalingMode) {
    case VideoScalingMode.fit:
      return 'contain';
    case VideoScalingMode.fill:
      return 'cover';
    case VideoScalingMode.stretch:
      return 'fill';
  }
}

/// Converts [BufferingTier] to HTML5 preload attribute value.
///
/// - [BufferingTier.min], [BufferingTier.low] -> 'metadata'
/// - [BufferingTier.medium], [BufferingTier.high], [BufferingTier.max] -> 'auto'
String getPreloadFromBufferingTier(BufferingTier tier) {
  switch (tier) {
    case BufferingTier.min:
    case BufferingTier.low:
      return 'metadata';
    case BufferingTier.medium:
    case BufferingTier.high:
    case BufferingTier.max:
      return 'auto';
  }
}

/// Infers container format from URL file extension.
///
/// Returns the container format string (e.g., 'mp4', 'webm', 'hls') or null
/// if the format cannot be determined.
String? inferContainerFormat(String url) {
  final lowerUrl = url.toLowerCase();
  if (lowerUrl.endsWith('.mp4') || lowerUrl.contains('.mp4?')) return 'mp4';
  if (lowerUrl.endsWith('.webm') || lowerUrl.contains('.webm?')) return 'webm';
  if (lowerUrl.endsWith('.mkv') || lowerUrl.contains('.mkv?')) return 'matroska';
  if (lowerUrl.endsWith('.m3u8') || lowerUrl.contains('.m3u8?')) return 'hls';
  if (lowerUrl.endsWith('.mpd') || lowerUrl.contains('.mpd?')) return 'dash';
  if (lowerUrl.endsWith('.ogg') || lowerUrl.contains('.ogg?')) return 'ogg';
  if (lowerUrl.endsWith('.mov') || lowerUrl.contains('.mov?')) return 'quicktime';
  return null;
}

/// Detects subtitle format from URL extension.
///
/// Returns the [SubtitleFormat] or null if the format cannot be determined.
SubtitleFormat? detectSubtitleFormat(String url) {
  final lowerUrl = url.toLowerCase();
  if (lowerUrl.endsWith('.vtt') || lowerUrl.contains('.vtt?')) {
    return SubtitleFormat.vtt;
  } else if (lowerUrl.endsWith('.srt') || lowerUrl.contains('.srt?')) {
    return SubtitleFormat.srt;
  } else if (lowerUrl.endsWith('.ass') || lowerUrl.contains('.ass?')) {
    return SubtitleFormat.ass;
  } else if (lowerUrl.endsWith('.ssa') || lowerUrl.contains('.ssa?')) {
    return SubtitleFormat.ssa;
  } else if (lowerUrl.endsWith('.ttml') || lowerUrl.contains('.ttml?') || lowerUrl.endsWith('.xml')) {
    return SubtitleFormat.ttml;
  }
  return null;
}

/// Extracts a label from a URL (uses filename without extension).
///
/// Returns the filename without extension, or 'External Subtitle' if
/// the filename cannot be extracted.
String labelFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final filename = pathSegments.last;
      // Remove extension
      final dotIndex = filename.lastIndexOf('.');
      if (dotIndex > 0) {
        return filename.substring(0, dotIndex);
      }
      return filename;
    }
  } catch (_) {
    // Ignore parsing errors
  }
  return 'External Subtitle';
}

/// Gets the source URL from a [VideoSource].
///
/// Throws [UnsupportedError] for playlist sources which are not yet supported.
String getSourceUrl(VideoSource source) => switch (source) {
  NetworkVideoSource(:final url) => url,
  FileVideoSource(:final path) => path, // For web, file paths are URLs
  AssetVideoSource(:final assetPath) => 'assets/$assetPath',
  PlaylistVideoSource() => throw UnsupportedError('Playlist sources not yet supported on web'),
};

/// Validates playback speed is within acceptable range.
///
/// Throws [ArgumentError] if speed is <= 0.0 or > 10.0.
void validatePlaybackSpeed(double speed) {
  if (speed <= 0.0 || speed > 10.0) {
    throw ArgumentError('Playback speed must be between 0.0 (exclusive) and 10.0');
  }
}

/// Validates volume is within acceptable range.
///
/// Throws [ArgumentError] if volume is < 0.0 or > 1.0.
void validateVolume(double volume) {
  if (volume < 0.0 || volume > 1.0) {
    throw ArgumentError('Volume must be between 0.0 and 1.0');
  }
}

/// Validates seek position is non-negative.
///
/// Throws [ArgumentError] if position is negative.
void validateSeekPosition(Duration position) {
  if (position.isNegative) {
    throw ArgumentError('Position must be non-negative');
  }
}
