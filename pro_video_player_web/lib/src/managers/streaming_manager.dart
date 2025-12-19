import 'package:meta/meta.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../abstractions/video_element_interface.dart';
import '../manager_callbacks.dart';
import '../verbose_logging.dart';

/// Base class for streaming managers (HLS, DASH, etc.).
///
/// Type parameter [T] is the player interface type (e.g., HlsPlayerInterface).
///
/// Provides common infrastructure for adaptive streaming managers:
/// - Lifecycle management (initialization, disposal)
/// - Quality track management (available tracks, current selection)
/// - Event emission and callbacks
/// - Error recovery
///
/// Subclasses implement format-specific details via template methods.
abstract class StreamingManager<T> with WebManagerCallbacks {
  /// Creates a streaming manager.
  StreamingManager({required this.emitEvent, required this.videoElement});

  @override
  final EventEmitter emitEvent;

  @override
  final VideoElementInterface videoElement;

  /// The streaming player instance.
  ///
  /// Subclasses should store their player (HLS.js, DASH.js) here.
  T? _player;

  /// Available quality tracks.
  List<VideoQualityTrack> _availableQualities = [];

  /// Whether the manager has been initialized.
  bool _isInitialized = false;

  /// Whether the manager is initialized and active.
  bool get isInitialized => _isInitialized;

  /// Whether the manager has an active player.
  bool get isActive => _player != null;

  /// Gets the player instance (for coordination with other managers).
  ///
  /// Returns the format-specific player (HLS.js or DASH.js).
  T? get player => _player;

  /// Sets the player instance.
  ///
  /// Called by subclasses during initialization to store their player.
  @protected
  set player(T? value) => _player = value;

  /// Marks the manager as initialized.
  ///
  /// Called by subclasses after successful initialization.
  @protected
  void markInitialized() => _isInitialized = true;

  /// Marks the manager as not initialized.
  ///
  /// Called during disposal.
  @protected
  void markUninitialized() => _isInitialized = false;

  /// Gets the tag name for verbose logging.
  ///
  /// Subclasses should return their manager name (e.g., 'HlsManager', 'DashManager').
  String get logTag;

  /// Gets available quality tracks.
  ///
  /// Returns an unmodifiable list of quality tracks.
  List<VideoQualityTrack> getAvailableQualities() => List.unmodifiable(_availableQualities);

  /// Updates the available quality tracks.
  ///
  /// Subclasses call this after parsing the manifest/stream.
  @protected
  void updateAvailableQualities(List<VideoQualityTrack> qualities) {
    _availableQualities = qualities;
    verboseLog('Updated ${qualities.length} quality levels', tag: logTag);
  }

  /// Clears the available quality tracks.
  ///
  /// Called during disposal.
  @protected
  void clearAvailableQualities() {
    _availableQualities = [];
  }

  /// Sets up event handlers for the streaming player.
  ///
  /// Subclasses implement format-specific event registration:
  /// - Manifest/stream parsed events
  /// - Quality change events
  /// - Track change events (audio, subtitle)
  /// - Error events
  ///
  /// Note: Subclasses must also implement their own `initialize()` method
  /// with format-specific parameters (e.g., hlsPlayer, dashPlayer, bitrate limits).
  @protected
  void setupEventHandlers();

  /// Sets the video quality.
  ///
  /// Returns true if the quality was set successfully.
  bool setQuality(VideoQualityTrack track);

  /// Gets the current quality track.
  VideoQualityTrack getCurrentQuality();

  /// Recovers from an error.
  ///
  /// Subclasses implement format-specific recovery:
  /// - HLS: call startLoad()
  /// - DASH: reset and reattach source
  Future<void> recover();

  /// Cleans up the player instance.
  ///
  /// Subclasses implement format-specific cleanup:
  /// - HLS: call destroy()
  /// - DASH: call reset()
  ///
  /// Must set [player] to null after cleanup.
  @protected
  void cleanupPlayer();

  /// Disposes the manager and cleans up resources.
  ///
  /// Calls [cleanupPlayer] and resets all state.
  void dispose() {
    if (_player != null) {
      try {
        cleanupPlayer();
        verboseLog('Player cleaned up', tag: logTag);
      } catch (e) {
        verboseLog('Error cleaning up player: $e', tag: logTag);
      }
      _player = null;
    }

    clearAvailableQualities();
    markUninitialized();

    verboseLog('Manager disposed', tag: logTag);
  }
}
