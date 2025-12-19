import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../abstractions/video_element_interface.dart';
import '../manager_callbacks.dart';
import '../verbose_logging.dart';

/// Manages HTML5 video element event listeners for web video player.
///
/// This manager handles:
/// - Setting up all video element event listeners
/// - Playback state events (play, pause, ended, buffering)
/// - Position and buffering tracking
/// - Volume and playback speed changes
/// - Duration changes
/// - Cleanup and disposal
///
/// Event listener lifecycle is managed centrally to prevent memory leaks
/// and ensure proper cleanup on disposal.
class EventListenerManager with WebManagerCallbacks {
  /// Creates an event listener manager.
  EventListenerManager({
    required this.emitEvent,
    required this.videoElement,
    required this.onMetadataLoaded,
    required this.getDuration,
    required this.getPosition,
  });

  @override
  final EventEmitter emitEvent;

  @override
  final VideoElementInterface videoElement;

  /// Callback when metadata is loaded.
  ///
  /// This can be set after initialization to wire up metadata handling.
  void Function() onMetadataLoaded;

  /// Function to get current duration.
  final Duration Function() getDuration;

  /// Function to get current position.
  final Duration Function() getPosition;

  /// Whether the manager has been initialized.
  bool _isInitialized = false;

  /// Last sent position in milliseconds (for deduplication).
  int _lastSentPosition = -1;

  /// Last sent buffered position in milliseconds (for deduplication).
  int _lastSentBufferedPosition = -1;

  /// Initializes the event listener manager.
  ///
  /// Sets up all HTML5 video element event listeners.
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    _setupEventListeners();
    verboseLog('Event listeners initialized', tag: 'EventListenerManager');
  }

  /// Sets up all video element event listeners.
  void _setupEventListeners() {
    // Playback state events
    videoElement.addEventListener('loadedmetadata', (event) {
      final duration = getDuration();
      emitEvent(const PlaybackStateChangedEvent(PlaybackState.ready));
      emitEvent(DurationChangedEvent(duration));
      emitEvent(VideoSizeChangedEvent(width: videoElement.videoWidth as int, height: videoElement.videoHeight as int));

      // Call metadata loaded callback
      onMetadataLoaded();
    });

    videoElement.addEventListener('play', (event) {
      emitEvent(const PlaybackStateChangedEvent(PlaybackState.playing));
    });

    videoElement.addEventListener('pause', (event) {
      emitEvent(const PlaybackStateChangedEvent(PlaybackState.paused));
    });

    videoElement.addEventListener('ended', (event) {
      emitEvent(const PlaybackCompletedEvent());
      emitEvent(const PlaybackStateChangedEvent(PlaybackState.completed));
    });

    videoElement.addEventListener('waiting', (event) {
      emitEvent(const PlaybackStateChangedEvent(PlaybackState.buffering));
    });

    videoElement.addEventListener('canplay', (event) {
      if (!(videoElement.paused as bool)) {
        emitEvent(const PlaybackStateChangedEvent(PlaybackState.playing));
      }
    });

    // Position updates (with deduplication - only send if changed by 100ms+)
    videoElement.addEventListener('timeupdate', (event) {
      final position = getPosition();
      final positionMs = position.inMilliseconds;
      if ((positionMs - _lastSentPosition).abs() >= 100) {
        _lastSentPosition = positionMs;
        emitEvent(PositionChangedEvent(position));
      }
    });

    // Buffering updates (with deduplication - only send if increased)
    videoElement.addEventListener('progress', (event) {
      final buffered = videoElement.buffered;
      // ignore: avoid_dynamic_calls
      final length = buffered.length as int;
      if (length > 0) {
        // ignore: avoid_dynamic_calls
        final bufferedEnd = buffered.end(length - 1) as num;
        final bufferedMs = (bufferedEnd * 1000).round();
        if (bufferedMs > _lastSentBufferedPosition) {
          _lastSentBufferedPosition = bufferedMs;
          emitEvent(BufferedPositionChangedEvent(Duration(milliseconds: bufferedMs)));
        }
      }
    });

    // Stalled event for buffering detection
    videoElement.addEventListener('stalled', (event) {
      emitEvent(const BufferingStartedEvent(reason: BufferingReason.networkUnstable));
    });

    // Volume changes
    videoElement.addEventListener('volumechange', (event) {
      emitEvent(VolumeChangedEvent(videoElement.volume as double));
    });

    // Playback speed changes
    videoElement.addEventListener('ratechange', (event) {
      emitEvent(PlaybackSpeedChangedEvent(videoElement.playbackRate as double));
    });

    // Duration change - important for HLS streams where duration isn't available immediately
    videoElement.addEventListener('durationchange', (event) {
      final duration = getDuration();
      if (duration > Duration.zero) {
        emitEvent(DurationChangedEvent(duration));
      }
    });
  }

  /// Disposes the manager and cleans up resources.
  void dispose() {
    _isInitialized = false;
    _lastSentPosition = -1;
    _lastSentBufferedPosition = -1;

    verboseLog('Event listener manager disposed', tag: 'EventListenerManager');
  }
}
