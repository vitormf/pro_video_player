import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../abstractions/video_element_interface.dart';
import '../manager_callbacks.dart';
import '../verbose_logging.dart';
import 'dash_manager.dart';
import 'hls_manager.dart';

/// Manages video quality selection across HLS.js, DASH.js, and native sources.
///
/// This manager coordinates quality selection by delegating to the
/// appropriate source (HLS.js or DASH.js). It follows a priority system:
/// HLS > DASH > default.
///
/// Quality level tracking and events are handled by the individual managers
/// (HlsManager, DashManager) when they detect quality changes.
///
/// When no adaptive streaming is active (neither HLS nor DASH), this manager
/// returns a default "auto" quality option.
class QualityManager with WebManagerCallbacks {
  /// Creates a quality manager.
  QualityManager({required this.emitEvent, required this.videoElement});

  @override
  final EventEmitter emitEvent;

  @override
  final VideoElementInterface videoElement;

  /// HLS manager for HLS.js quality handling.
  HlsManager? hlsManager;

  /// DASH manager for DASH.js quality handling.
  DashManager? dashManager;

  /// Whether an HLS manager is registered.
  bool get hasHlsManager => hlsManager != null && hlsManager!.isActive;

  /// Whether a DASH manager is registered.
  bool get hasDashManager => dashManager != null && dashManager!.isActive;

  /// Gets available quality tracks.
  ///
  /// Delegates to the appropriate source in priority order:
  /// 1. HLS.js (if active)
  /// 2. DASH.js (if active)
  /// 3. Default ([VideoQualityTrack.auto] only)
  ///
  /// Returns a list of [VideoQualityTrack] with "auto" as the first option,
  /// followed by available quality levels sorted by resolution.
  List<VideoQualityTrack> getAvailableQualities() {
    // Priority 1: HLS.js
    if (hasHlsManager) {
      final qualities = hlsManager!.getAvailableQualities();
      if (qualities.length > 1) {
        // Has quality levels beyond auto
        return qualities;
      }
    }

    // Priority 2: DASH.js
    if (hasDashManager) {
      final qualities = dashManager!.getAvailableQualities();
      if (qualities.length > 1) {
        // Has quality levels beyond auto
        return qualities;
      }
    }

    // Default: auto only
    return [VideoQualityTrack.auto];
  }

  /// Sets the video quality.
  ///
  /// Delegates to the appropriate source in priority order:
  /// 1. HLS.js (if active)
  /// 2. DASH.js (if active)
  /// 3. Returns false if no adaptive streaming active
  ///
  /// Returns true if the quality was set successfully.
  bool setQuality(VideoQualityTrack track) {
    // Priority 1: HLS.js
    if (hasHlsManager) {
      return hlsManager!.setQuality(track);
    }

    // Priority 2: DASH.js
    if (hasDashManager) {
      return dashManager!.setQuality(track);
    }

    // No adaptive streaming active
    verboseLog('Cannot set quality: no adaptive streaming active', tag: 'QualityManager');
    return false;
  }

  /// Gets the current quality track.
  ///
  /// Delegates to the appropriate source in priority order:
  /// 1. HLS.js (if active)
  /// 2. DASH.js (if active)
  /// 3. Returns [VideoQualityTrack.auto] if no adaptive streaming active
  VideoQualityTrack getCurrentQuality() {
    // Priority 1: HLS.js
    if (hasHlsManager) {
      return hlsManager!.getCurrentQuality();
    }

    // Priority 2: DASH.js
    if (hasDashManager) {
      return dashManager!.getCurrentQuality();
    }

    // Default: auto
    return VideoQualityTrack.auto;
  }

  /// Checks if quality selection is supported.
  ///
  /// Quality selection is supported when:
  /// - HLS.js is active with multiple quality levels, OR
  /// - DASH.js is active with multiple bitrate representations
  bool isQualitySelectionSupported() {
    final qualities = getAvailableQualities();
    // More than just "auto" means we have actual quality options
    return qualities.length > 1;
  }

  /// Disposes the manager and cleans up resources.
  void dispose() {
    hlsManager = null;
    dashManager = null;

    verboseLog('Quality manager disposed', tag: 'QualityManager');
  }
}
