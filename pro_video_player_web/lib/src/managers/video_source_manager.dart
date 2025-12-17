import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../abstractions/video_element_interface.dart';
import '../manager_callbacks.dart';
import '../verbose_logging.dart';
import '../web_player_helpers.dart' as helpers;

/// Manages video source setup and format detection for web video player.
///
/// This manager handles:
/// - Source type detection (HLS, DASH, regular video)
/// - Source URL extraction from VideoSource
/// - Native source setup
/// - Source format helpers
///
/// The manager provides utilities for determining the appropriate
/// playback method based on source format.
class VideoSourceManager with WebManagerCallbacks {
  /// Creates a video source manager.
  VideoSourceManager({required this.emitEvent, required this.videoElement});

  @override
  final EventEmitter emitEvent;

  @override
  final VideoElementInterface videoElement;

  /// Checks if a URL is an HLS stream.
  ///
  /// Returns `true` if the URL ends with `.m3u8` or contains `.m3u8?`.
  bool isHlsSource(String url) => helpers.isHlsUrl(url);

  /// Checks if a URL is a DASH stream (MPD).
  ///
  /// Returns `true` if the URL ends with `.mpd` or contains `.mpd?`.
  bool isDashSource(String url) => helpers.isDashUrl(url);

  /// Gets the source URL from a [VideoSource].
  ///
  /// Converts different source types to URL strings:
  /// - NetworkVideoSource: returns the URL
  /// - FileVideoSource: returns the file path
  /// - AssetVideoSource: returns 'assets/{assetPath}'
  ///
  /// Throws [UnsupportedError] for playlist sources.
  String getSourceUrl(VideoSource source) => helpers.getSourceUrl(source);

  /// Sets the video source directly on the video element (native playback).
  ///
  /// This is used for regular video files and Safari HLS playback.
  void setNativeSource(String url) {
    final element = videoElement as dynamic;
    element.src = url;
    verboseLog('Native source set: $url', tag: 'VideoSourceManager');
  }

  /// Infers container format from URL file extension.
  ///
  /// Returns the container format string (e.g., 'mp4', 'webm', 'hls') or null
  /// if the format cannot be determined.
  String? inferContainerFormat(String url) => helpers.inferContainerFormat(url);

  /// Disposes the manager and cleans up resources.
  void dispose() {
    verboseLog('Video source manager disposed', tag: 'VideoSourceManager');
  }
}
