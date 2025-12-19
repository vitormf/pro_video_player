import 'dart:async';

import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../abstractions/video_element_interface.dart';
import '../manager_callbacks.dart';
import '../verbose_logging.dart';

/// Manages casting (Remote Playback API) for web video player.
///
/// This manager handles:
/// - Remote Playback API initialization and event listeners
/// - Cast state management (connecting, connected, disconnected)
/// - Starting/stopping casting
/// - Cast device information
///
/// Web casting uses the Remote Playback API, which is supported
/// in Chrome, Edge, and some other Chromium-based browsers.
class CastingManager with WebManagerCallbacks {
  /// Creates a casting manager.
  CastingManager({required this.emitEvent, required this.videoElement, required bool allowCasting})
    : _allowCasting = allowCasting;

  @override
  final EventEmitter emitEvent;

  @override
  final VideoElementInterface videoElement;

  /// Whether casting is allowed.
  final bool _allowCasting;

  /// Current cast state.
  CastState _castState = CastState.notConnected;

  /// Current cast device, or null if not casting.
  CastDevice? _currentCastDevice;

  /// Whether the manager has been initialized.
  bool _isInitialized = false;

  /// Initializes the casting manager.
  ///
  /// Sets up Remote Playback API event listeners if casting is allowed
  /// and the API is available.
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    if (!_allowCasting) return;
    if (!_isRemotePlaybackSupported()) return;

    _setupRemotePlayback();
  }

  /// Sets up remote playback (casting) using the Remote Playback API.
  void _setupRemotePlayback() {
    try {
      // Get the remote playback object via the typed interface
      final remotePlayback = videoElement.remotePlayback;
      if (remotePlayback == null) return;

      // Listen for state changes
      void onConnecting(Object? event) {
        _castState = CastState.connecting;
        emitEvent(const CastStateChangedEvent(state: CastState.connecting));
        verboseLog('Remote playback connecting', tag: 'CastingManager');
      }

      void onConnect(Object? event) {
        _castState = CastState.connected;
        // Create a generic cast device for web (we don't have detailed device info from the API)
        _currentCastDevice = const CastDevice(
          id: 'web-remote-device',
          name: 'Remote Device',
          type: CastDeviceType.webRemotePlayback,
        );
        emitEvent(CastStateChangedEvent(state: CastState.connected, device: _currentCastDevice));
        verboseLog('Remote playback connected', tag: 'CastingManager');
      }

      void onDisconnect(Object? event) {
        _castState = CastState.notConnected;
        _currentCastDevice = null;
        emitEvent(const CastStateChangedEvent(state: CastState.notConnected));
        verboseLog('Remote playback disconnected', tag: 'CastingManager');
      }

      // Add event listeners via the typed interface
      remotePlayback.addEventListener('connecting', onConnecting);
      remotePlayback.addEventListener('connect', onConnect);
      remotePlayback.addEventListener('disconnect', onDisconnect);

      verboseLog('Remote playback listeners set up', tag: 'CastingManager');
    } catch (e) {
      verboseLog('Failed to set up remote playback: $e', tag: 'CastingManager');
    }
  }

  /// Checks if remote playback (casting) is supported.
  bool _isRemotePlaybackSupported() => videoElement.remotePlayback != null;

  /// Checks if casting is currently supported.
  ///
  /// Returns true if casting is allowed and the Remote Playback API is available.
  bool isSupported() => _allowCasting && _isRemotePlaybackSupported();

  /// Gets the list of available cast devices.
  ///
  /// The Remote Playback API doesn't provide a way to enumerate devices,
  /// so this returns an empty list. Use [startCasting] to prompt the user
  /// to select a device.
  List<CastDevice> getAvailableDevices() => [];

  /// Starts casting by prompting the user to select a device.
  ///
  /// The device parameter is ignored on web because the Remote Playback API
  /// shows its own device picker. Returns true if the prompt was shown successfully.
  Future<bool> startCasting({CastDevice? device}) async {
    if (!_allowCasting || !_isRemotePlaybackSupported()) {
      return false;
    }

    try {
      final remotePlayback = videoElement.remotePlayback;
      if (remotePlayback == null) return false;

      // prompt() shows the browser's device picker (device parameter is ignored)
      await remotePlayback.prompt();
      return true;
    } catch (e) {
      verboseLog('Failed to start casting: $e', tag: 'CastingManager');
      return false;
    }
  }

  /// Stops casting and returns playback to the local device.
  ///
  /// Returns `true` if casting was stopped successfully, `false` if not
  /// currently casting or if the operation failed.
  ///
  /// [currentSource] is the current video source.
  /// [getSourceUrl] is a function that converts a VideoSource to a URL string.
  Future<bool> stopCasting({
    required VideoSource currentSource,
    required String Function(VideoSource) getSourceUrl,
  }) async {
    if (!_isRemotePlaybackSupported()) return false;

    try {
      final remotePlayback = videoElement.remotePlayback;
      if (remotePlayback == null) return false;

      // Check current state via the typed interface
      final state = remotePlayback.state;
      if (state == 'disconnected') return false;

      // The Remote Playback API spec doesn't provide a direct way to disconnect,
      // so we reload the video to force disconnection.
      // Capture state BEFORE modifying the element.
      final savedTime = videoElement.currentTime;
      final wasPaused = videoElement.paused as bool;

      _castState = CastState.disconnecting;
      emitEvent(const CastStateChangedEvent(state: CastState.disconnecting));

      videoElement.src = '';
      videoElement.load();
      videoElement.src = getSourceUrl(currentSource);

      // Restore position when ready
      videoElement.addEventListener('canplay', (event) {
        videoElement.currentTime = savedTime;
        if (!wasPaused) {
          unawaited(videoElement.play());
        }
      });

      _castState = CastState.notConnected;
      _currentCastDevice = null;
      emitEvent(const CastStateChangedEvent(state: CastState.notConnected));
      verboseLog('Casting stopped', tag: 'CastingManager');
      return true;
    } catch (e) {
      verboseLog('Failed to stop casting: $e', tag: 'CastingManager');
      return false;
    }
  }

  /// Gets the current cast state.
  CastState getState() => _castState;

  /// Gets the current cast state (alias for getState()).
  CastState getCastState() => _castState;

  /// Gets the current cast device, or null if not casting.
  CastDevice? getCurrentDevice() => _currentCastDevice;

  /// Gets the current cast device (alias for getCurrentDevice()).
  CastDevice? getCurrentCastDevice() => _currentCastDevice;

  /// Checks if casting is supported on this device/browser.
  ///
  /// Returns true if the Remote Playback API is available.
  bool isCastingSupported() => _isRemotePlaybackSupported();

  /// Gets the list of available cast devices.
  ///
  /// Note: The Remote Playback API doesn't provide a way to enumerate devices.
  /// This always returns an empty list. Devices are discovered when prompting.
  List<CastDevice> getAvailableCastDevices() => [];

  /// Disposes the manager and cleans up resources.
  void dispose() {
    _castState = CastState.notConnected;
    _currentCastDevice = null;
    _isInitialized = false;

    verboseLog('Casting manager disposed', tag: 'CastingManager');
  }
}
