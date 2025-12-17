import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../abstractions/video_element_interface.dart';
import '../manager_callbacks.dart';
import '../verbose_logging.dart';

/// Manages video metadata extraction and reporting.
///
/// This manager extracts video metadata from the HTML5 video element and
/// optionally from HLS.js when using adaptive streaming. It provides:
/// - Basic metadata: width, height, duration
/// - Codec information: video and audio codecs (from HLS.js)
/// - Bitrate information: video and audio bitrates (from HLS.js)
/// - Container format: inferred from URL extension
///
/// Metadata extraction requires the video element to have loaded at least
/// minimal metadata (readyState >= 1).
class MetadataManager with WebManagerCallbacks {
  /// Creates a metadata manager.
  MetadataManager({required this.emitEvent, required this.videoElement});

  @override
  final EventEmitter emitEvent;

  @override
  final VideoElementInterface videoElement;

  /// Extracts video metadata and emits VideoMetadataExtractedEvent.
  ///
  /// [sourceUrl] is the video source URL for container format inference.
  /// [hlsPlayer] is the optional HLS.js player for codec/bitrate extraction.
  ///
  /// Emits [VideoMetadataExtractedEvent] if metadata is available, otherwise
  /// does nothing.
  Future<void> extractAndEmit({required String sourceUrl, dynamic hlsPlayer}) async {
    final metadata = getMetadata(sourceUrl: sourceUrl, hlsPlayer: hlsPlayer);
    if (metadata != null) {
      emitEvent(VideoMetadataExtractedEvent(metadata));
      verboseLog(
        'Metadata extracted: ${metadata.width}x${metadata.height}, '
        'codec: ${metadata.videoCodec}, format: ${metadata.containerFormat}',
        tag: 'MetadataManager',
      );
    }
  }

  /// Gets video metadata without emitting an event.
  ///
  /// [sourceUrl] is the video source URL for container format inference.
  /// [hlsPlayer] is the optional HLS.js player for codec/bitrate extraction.
  ///
  /// Returns null if metadata is not available yet (readyState < 1).
  VideoMetadata? getMetadata({required String sourceUrl, dynamic hlsPlayer}) {
    // Check if video has loaded enough metadata
    // Note: VideoElementInterface doesn't expose readyState, so we need to cast
    // In tests, we can set readyState on the mock
    final element = videoElement as dynamic;
    final readyState = element.readyState as int;
    if (readyState < 1) {
      return null;
    }

    // Extract basic metadata from video element
    final duration = _extractDuration();
    final width = element.videoWidth as int;
    final height = element.videoHeight as int;

    // Extract codec and bitrate info from HLS.js if available
    String? videoCodec;
    String? audioCodec;
    int? videoBitrate;
    int? audioBitrate;

    if (hlsPlayer != null) {
      final codecInfo = _extractHlsCodecInfo(hlsPlayer);
      videoCodec = codecInfo['videoCodec'] as String?;
      audioCodec = codecInfo['audioCodec'] as String?;
      videoBitrate = codecInfo['videoBitrate'] as int?;
      audioBitrate = codecInfo['audioBitrate'] as int?;
    }

    // Infer container format from URL
    final containerFormat = _inferContainerFormat(sourceUrl);

    return VideoMetadata(
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      width: width > 0 ? width : null,
      height: height > 0 ? height : null,
      videoBitrate: videoBitrate,
      audioBitrate: audioBitrate,
      duration: duration,
      containerFormat: containerFormat,
    );
  }

  /// Extracts duration from video element.
  Duration? _extractDuration() {
    final element = videoElement as dynamic;
    final duration = element.duration as double;
    if (duration.isNaN || duration.isInfinite) {
      return null;
    }
    if (duration <= 0) {
      return null;
    }
    return Duration(milliseconds: (duration * 1000).round());
  }

  /// Extracts codec and bitrate info from HLS.js player.
  Map<String, Object?> _extractHlsCodecInfo(dynamic hlsPlayer) {
    final result = <String, Object?>{};

    try {
      final currentLevel = hlsPlayer.currentLevel as int;
      if (currentLevel < 0) {
        // Auto quality mode - don't extract from specific level
        return result;
      }

      final levels = hlsPlayer.levels as List;
      final levelsLength = levels.length;
      if (currentLevel >= levelsLength) {
        return result;
      }

      final level = levels[currentLevel];

      // Extract bitrate
      final bitrate = level.bitrate as int;
      if (bitrate > 0) {
        result['videoBitrate'] = bitrate;
      }

      // Parse codecs string (e.g., "avc1.64001f,mp4a.40.2")
      final codecs = level.codecs as String?;
      if (codecs != null && codecs.isNotEmpty) {
        final codecParts = codecs.split(',') as List;
        for (final codec in codecParts) {
          final trimmed = (codec as String).trim();
          if (trimmed.startsWith('avc') || trimmed.startsWith('hvc') || trimmed.startsWith('vp')) {
            result['videoCodec'] = trimmed;
          } else if (trimmed.startsWith('mp4a') || trimmed.startsWith('opus') || trimmed.startsWith('ac-')) {
            result['audioCodec'] = trimmed;
          }
        }
      }
    } catch (e) {
      verboseLog('Error extracting HLS codec info: $e', tag: 'MetadataManager');
    }

    return result;
  }

  /// Infers container format from URL extension.
  String? _inferContainerFormat(String url) {
    try {
      // Remove query parameters
      final urlWithoutQuery = url.split('?').first;

      // Get extension
      final parts = urlWithoutQuery.split('.');
      if (parts.length < 2) {
        return null;
      }

      final extension = parts.last.toLowerCase();

      switch (extension) {
        case 'mp4':
        case 'm4v':
          return 'mp4';
        case 'webm':
          return 'webm';
        case 'm3u8':
          return 'hls';
        case 'mpd':
          return 'dash';
        case 'ogv':
        case 'ogg':
          return 'ogg';
        case 'mov':
          return 'quicktime';
        default:
          return null;
      }
    } catch (e) {
      verboseLog('Error inferring container format: $e', tag: 'MetadataManager');
      return null;
    }
  }

  /// Extracts video metadata from the current source.
  ///
  /// This is a convenience wrapper around getMetadata() that handles
  /// extracting the source URL from a VideoSource object.
  VideoMetadata? extractMetadata(VideoSource source) {
    // Import helpers at the top of the file to use getSourceUrl
    // For now, use a simple pattern match to extract the URL
    final sourceUrl = switch (source) {
      NetworkVideoSource(:final url) => url,
      FileVideoSource(:final path) => path,
      AssetVideoSource(:final assetPath) => 'assets/$assetPath',
      PlaylistVideoSource() => throw UnsupportedError('Playlist sources not yet supported'),
    };

    // Check if HLS player is available (would need to be passed from WebVideoPlayer)
    // For now, just use null for hlsPlayer
    return getMetadata(sourceUrl: sourceUrl);
  }

  /// Disposes the manager and cleans up resources.
  void dispose() {
    verboseLog('Metadata manager disposed', tag: 'MetadataManager');
  }
}
