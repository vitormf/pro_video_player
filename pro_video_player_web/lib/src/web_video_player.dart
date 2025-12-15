import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:web/web.dart' as web;

import 'dash_interop.dart';
import 'hls_interop.dart';
import 'media_session_interop.dart' as media_session;
import 'verbose_logging.dart';
import 'wake_lock_interop.dart' as wake_lock;
import 'web_player_helpers.dart' as helpers;

/// Web video player implementation using HTML5 VideoElement.
///
/// For HLS sources on non-Safari browsers, this player automatically loads
/// and uses HLS.js for playback, enabling quality selection, audio track
/// selection, and adaptive bitrate streaming.
///
/// For DASH sources (MPD), this player automatically loads and uses dash.js
/// for playback, enabling quality selection, audio track selection, and
/// adaptive bitrate streaming.
class WebVideoPlayer {
  /// Creates a new web video player.
  WebVideoPlayer(this.playerId, this.source, this.options);

  /// The unique player ID.
  final int playerId;

  /// The video source.
  final VideoSource source;

  /// Player options.
  final VideoPlayerOptions options;

  late final web.HTMLVideoElement _videoElement;

  /// The view type for platform view registration.
  late final String viewType;

  final StreamController<VideoPlayerEvent> _eventController = StreamController<VideoPlayerEvent>.broadcast();
  bool _isDisposed = false;

  // HLS.js player (only used for HLS sources on non-Safari browsers)
  HlsPlayer? _hlsPlayer;
  bool _isUsingHlsJs = false;

  // dash.js player (only used for DASH/MPD sources)
  DashPlayer? _dashPlayer;
  bool _isUsingDashJs = false;

  // Network resilience state
  bool _isNetworkAvailable = true;
  bool _hadNetworkError = false;
  bool _wasPlayingBeforeError = false;
  int _networkRetryCount = 0;
  static const int _maxNetworkRetries = 3;

  // Track selection state
  bool _hasManuallySelectedSubtitle = false;
  bool _isInitialSubtitleSelection = true;

  // Embedded subtitle extraction for Flutter rendering
  String _subtitleRenderMode = 'auto';

  // External subtitle storage
  final Map<String, ExternalSubtitleTrack> _externalSubtitles = {};
  final Map<String, web.HTMLTrackElement> _externalTrackElements = {};
  int _nextExternalSubtitleId = 0;

  // Quality selection state (for HLS.js)
  List<VideoQualityTrack> _availableQualities = [];
  int _selectedQualityIndex = -1; // -1 = auto

  // Performance optimization: track last sent values to avoid redundant events
  int _lastSentPosition = -1;
  int _lastSentBufferedPosition = -1;
  double _lastSentBandwidth = -1;

  // Casting state
  bool _allowCasting = true;
  CastState _castState = CastState.notConnected;
  CastDevice? _currentCastDevice;

  // Screen sleep prevention state
  bool _preventScreenSleep = true;
  JSObject? _wakeLockSentinel;

  // Playback and background state for wake lock management
  bool _isPlaying = false;
  bool _isPipActive = false;
  bool _isInBackground = false;

  /// Stream of player events.
  Stream<VideoPlayerEvent> get events => _eventController.stream;

  /// Safely adds an event to the stream, ignoring if disposed.
  void _addEvent(VideoPlayerEvent event) {
    if (!_isDisposed) {
      _eventController.add(event);
    }
  }

  /// Safely adds multiple events to the stream, ignoring if disposed.
  void _addEvents(List<VideoPlayerEvent> events) {
    if (!_isDisposed) {
      for (final event in events) {
        _eventController.add(event);
      }
    }
  }

  /// Initializes the video player.
  Future<void> initialize() async {
    viewType = 'pro_video_player_web_$playerId';

    _videoElement = web.HTMLVideoElement()
      ..style.width = '100%'
      ..style.height = '100%';

    // Set video scaling mode
    final objectFit = helpers.getObjectFitFromScalingMode(options.scalingMode);
    _videoElement.style.setProperty('object-fit', objectFit);

    // Set preload behavior based on buffering tier
    _videoElement.preload = helpers.getPreloadFromBufferingTier(options.bufferingTier);

    // Set initial options
    _videoElement.loop = options.looping;
    _videoElement.volume = options.volume;
    _videoElement.playbackRate = options.playbackSpeed;
    _videoElement.controls = false; // We'll manage controls separately
    _allowCasting = options.allowCasting;
    _preventScreenSleep = options.preventScreenSleep;
    _subtitleRenderMode = options.subtitleRenderMode.toJson();

    // Register platform view
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) => _videoElement);

    // Set up event listeners BEFORE setting source
    // This ensures we don't miss onloadedmetadata if the browser loads cached content quickly
    _setupEventListeners();

    // Set up network monitoring
    _setupNetworkMonitoring();

    // Set up remote playback (casting)
    _setupRemotePlayback();

    // Set up media session for browser controls (Bluetooth, media keys, etc.)
    _setupMediaSession();

    // Set up video source (must be after event listeners are attached)
    await _setupVideoSource();

    // Auto-play if requested
    if (options.autoPlay) {
      await play();
    }
  }

  /// Sets up the video source, using HLS.js or dash.js if needed.
  Future<void> _setupVideoSource() async {
    final sourceUrl = helpers.getSourceUrl(source);
    final isHlsSource = helpers.isHlsUrl(sourceUrl);
    final isDashSource = helpers.isDashUrl(sourceUrl);

    if (isDashSource) {
      // Load dash.js for DASH/MPD sources
      verboseLog('DASH source detected, loading dash.js...', tag: 'WebVideoPlayer');
      final loaded = await loadDashJs();

      if (loaded && isDashJsSupported) {
        _isUsingDashJs = true;
        _setupDashJs(sourceUrl);
        return;
      } else {
        verboseLog('dash.js not available, DASH playback may not work', tag: 'WebVideoPlayer');
      }
    } else if (isHlsSource && !isNativeHlsSupported) {
      // Load HLS.js for non-Safari browsers
      verboseLog('HLS source detected, loading HLS.js...', tag: 'WebVideoPlayer');
      final loaded = await loadHlsJs();

      if (loaded && isHlsJsSupported) {
        _isUsingHlsJs = true;
        _setupHlsJs(sourceUrl);
        return;
      } else {
        verboseLog('HLS.js not available, falling back to native', tag: 'WebVideoPlayer');
      }
    }

    // Native playback (Safari for HLS, or regular video files)
    _videoElement.src = sourceUrl;
  }

  /// Sets up HLS.js for playback.
  void _setupHlsJs(String sourceUrl) {
    final config = <String, dynamic>{
      'enableWorker': true,
      'lowLatencyMode': false,
      'startPosition': -1,
      // ABR configuration: enable bitrate-based auto level capping
      'abrMaxWithRealBitrate': true,
    };

    // Apply ABR mode - in manual mode, start at level 0 (will be overridden by setVideoQuality)
    if (options.abrMode == AbrMode.manual) {
      config['startLevel'] = 0;
    }

    _hlsPlayer = HlsPlayer.create(config: config);
    if (_hlsPlayer == null) {
      verboseLog('Failed to create HLS.js player', tag: 'WebVideoPlayer');
      _videoElement.src = sourceUrl; // Fallback
      return;
    }

    // Set up HLS.js event handlers
    _setupHlsJsEventHandlers();

    // Attach to video element and load source
    _hlsPlayer!.attachMedia(_videoElement);
    _hlsPlayer!.loadSource(sourceUrl);

    verboseLog('HLS.js player initialized', tag: 'WebVideoPlayer');
  }

  /// Sets up HLS.js event handlers.
  void _setupHlsJsEventHandlers() {
    final hls = _hlsPlayer;
    if (hls == null) return;

    hls
      // Manifest parsed - quality levels available
      ..on(HlsEvents.manifestParsed, (event, data) {
        verboseLog('HLS manifest parsed', tag: 'WebVideoPlayer');
        _updateAvailableQualities();
        _updateHlsSubtitleTracks();
        _updateHlsAudioTracks();

        // Apply ABR max bitrate cap if configured
        _applyHlsMaxBitrateCap();

        // Send duration update - HLS duration is available after manifest is parsed
        final duration = getDuration();
        if (duration > Duration.zero) {
          _addEvent(DurationChangedEvent(duration));
        }
      })
      // Level loaded - actual content info available, reliable duration
      ..on(HlsEvents.levelLoaded, (event, data) {
        final duration = getDuration();
        if (duration > Duration.zero) {
          _addEvent(DurationChangedEvent(duration));
        }
      })
      // Level switched - quality changed
      ..on(HlsEvents.levelSwitched, (event, data) {
        final newLevel = hls.currentLevel;
        verboseLog('HLS level switched to $newLevel', tag: 'WebVideoPlayer');
        _notifyQualityChange(newLevel);
      })
      // Audio tracks updated
      ..on(HlsEvents.audioTracksUpdated, (event, data) {
        verboseLog('HLS audio tracks updated', tag: 'WebVideoPlayer');
        _updateHlsAudioTracks();
      })
      // Subtitle tracks updated
      ..on(HlsEvents.subtitleTracksUpdated, (event, data) {
        verboseLog('HLS subtitle tracks updated', tag: 'WebVideoPlayer');
        _updateHlsSubtitleTracks();
      })
      // Fragment buffered - update bandwidth estimate
      ..on(HlsEvents.fragBuffered, (event, data) {
        _updateBandwidthEstimate();
      })
      // Error handling
      ..on(HlsEvents.error, (event, data) {
        _handleHlsError(data);
      });
  }

  /// Applies max bitrate cap for HLS.js after manifest is loaded.
  void _applyHlsMaxBitrateCap() {
    final hls = _hlsPlayer;
    if (hls == null) return;

    final maxBitrate = options.maxBitrate;
    if (maxBitrate == null || maxBitrate <= 0) return;

    // Find the highest quality level that is under the max bitrate
    final levels = hls.levels;
    var capLevel = -1;

    for (final level in levels) {
      if (level.bitrate <= maxBitrate) {
        if (capLevel == -1 || level.bitrate > levels[capLevel].bitrate) {
          capLevel = level.index;
        }
      }
    }

    if (capLevel >= 0) {
      hls.autoLevelCapping = capLevel;
      verboseLog(
        'HLS max bitrate cap applied: level $capLevel (${levels[capLevel].bitrate} bps)',
        tag: 'WebVideoPlayer',
      );
    }
  }

  /// Updates available quality tracks from HLS.js.
  void _updateAvailableQualities() {
    final hls = _hlsPlayer;
    if (hls == null) return;

    final levels = hls.levels;
    _availableQualities = [
      VideoQualityTrack.auto, // Always add auto option
      ...levels.map(
        (level) => VideoQualityTrack(
          id: level.index.toString(),
          label: level.label,
          width: level.width,
          height: level.height,
          bitrate: level.bitrate,
        ),
      ),
    ];

    _addEvent(VideoQualityTracksChangedEvent(_availableQualities));
    verboseLog('Available qualities: ${_availableQualities.length}', tag: 'WebVideoPlayer');
  }

  /// Notifies about quality change.
  void _notifyQualityChange(int levelIndex) {
    if (levelIndex < 0 || levelIndex >= _availableQualities.length - 1) {
      // Auto mode or invalid
      _addEvent(const SelectedQualityChangedEvent(VideoQualityTrack.auto, isAutoSwitch: true));
    } else {
      // +1 because index 0 is "auto"
      final quality = _availableQualities[levelIndex + 1];
      _addEvent(SelectedQualityChangedEvent(quality, isAutoSwitch: _selectedQualityIndex == -1));
    }
  }

  /// Updates bandwidth estimate from HLS.js.
  void _updateBandwidthEstimate() {
    final hls = _hlsPlayer;
    if (hls == null) return;

    final bandwidth = hls.bandwidthEstimate;
    if (bandwidth > 0 && (bandwidth - _lastSentBandwidth).abs() > 100000) {
      _lastSentBandwidth = bandwidth;
      _addEvent(BandwidthEstimateChangedEvent(bandwidth.toInt()));
    }
  }

  /// Updates subtitle tracks from HLS.js.
  void _updateHlsSubtitleTracks() {
    final hls = _hlsPlayer;
    if (hls == null) return;

    final hlsTracks = hls.subtitleTracks;
    if (hlsTracks.isEmpty) return;

    final tracks = hlsTracks
        .map((t) => SubtitleTrack(id: t.index.toString(), label: t.label, language: t.lang, isDefault: t.isDefault))
        .toList();

    _addEvent(SubtitleTracksChangedEvent(tracks));
  }

  /// Updates audio tracks from HLS.js.
  void _updateHlsAudioTracks() {
    final hls = _hlsPlayer;
    if (hls == null) return;

    final hlsTracks = hls.audioTracks;
    if (hlsTracks.isEmpty) return;

    final tracks = hlsTracks
        .map((t) => AudioTrack(id: t.index.toString(), label: t.label, language: t.lang, isDefault: t.isDefault))
        .toList();

    _addEvent(AudioTracksChangedEvent(tracks));
  }

  /// Handles HLS.js errors.
  void _handleHlsError(JSObject? data) {
    final hls = _hlsPlayer;
    if (hls == null || data == null) return;

    // Try to recover from media errors
    final fatal = (data['fatal'] as JSBoolean?)?.toDart ?? false;
    final type = (data['type'] as JSString?)?.toDart ?? '';

    verboseLog('HLS error: type=$type, fatal=$fatal', tag: 'WebVideoPlayer');

    if (fatal) {
      switch (type) {
        case 'mediaError':
          verboseLog('Attempting media error recovery', tag: 'WebVideoPlayer');
          hls.recoverMediaError();

        case 'networkError':
          _hadNetworkError = true;
          _wasPlayingBeforeError = !_videoElement.paused;
          _addEvent(
            NetworkErrorEvent(
              message: 'HLS network error',
              willRetry: _networkRetryCount < _maxNetworkRetries,
              retryAttempt: _networkRetryCount,
            ),
          );

        default:
          _addEvents([ErrorEvent('Fatal HLS error: $type'), const PlaybackStateChangedEvent(PlaybackState.error)]);
      }
    }
  }

  /// Sets up dash.js for DASH/MPD playback.
  void _setupDashJs(String sourceUrl) {
    _dashPlayer = DashPlayer.create();
    if (_dashPlayer == null) {
      verboseLog('Failed to create dash.js player', tag: 'WebVideoPlayer');
      _videoElement.src = sourceUrl; // Fallback (won't work but consistent)
      return;
    }

    // Set up dash.js event handlers
    _setupDashJsEventHandlers();

    // Initialize with video element and source
    _dashPlayer!.initialize(view: _videoElement, url: sourceUrl, autoPlay: options.autoPlay);

    // Apply ABR configuration
    _applyDashAbrConfig();

    verboseLog('dash.js player initialized', tag: 'WebVideoPlayer');
  }

  /// Applies ABR configuration for dash.js.
  void _applyDashAbrConfig() {
    final dash = _dashPlayer;
    if (dash == null) return;

    // Apply ABR mode
    if (options.abrMode == AbrMode.manual) {
      dash.setAutoSwitchQualityFor('video', enabled: false);
      verboseLog('DASH ABR auto-switch disabled (manual mode)', tag: 'WebVideoPlayer');
    }

    // Apply bitrate constraints via updateSettings
    final minBitrate = options.minBitrate;
    final maxBitrate = options.maxBitrate;

    if (minBitrate != null && minBitrate > 0) {
      // dash.js uses kbps for bitrate settings
      final minKbps = minBitrate ~/ 1000;
      dash.updateSettings({
        'streaming': {
          'abr': {
            'minBitrate': {'video': minKbps},
          },
        },
      });
      verboseLog('DASH min bitrate set to $minKbps kbps', tag: 'WebVideoPlayer');
    }

    if (maxBitrate != null && maxBitrate > 0) {
      // dash.js uses kbps for bitrate settings
      final maxKbps = maxBitrate ~/ 1000;
      dash.updateSettings({
        'streaming': {
          'abr': {
            'maxBitrate': {'video': maxKbps},
          },
        },
      });
      verboseLog('DASH max bitrate set to $maxKbps kbps', tag: 'WebVideoPlayer');
    }
  }

  /// Sets up dash.js event handlers.
  void _setupDashJsEventHandlers() {
    final dash = _dashPlayer;
    if (dash == null) return;

    dash
      // Stream initialized - quality levels available
      ..on(DashEvents.streamInitialized, (data) {
        verboseLog('DASH stream initialized', tag: 'WebVideoPlayer');
        _updateDashAvailableQualities();
        _updateDashSubtitleTracks();
        _updateDashAudioTracks();
      })
      // Metadata loaded - duration and other info
      ..on(DashEvents.playbackMetaDataLoaded, (data) {
        final duration = getDuration();
        if (duration > Duration.zero) {
          _addEvent(DurationChangedEvent(duration));
        }
      })
      // Quality changed
      ..on(DashEvents.qualityChangeRendered, (data) {
        final newQuality = dash.getQualityFor('video');
        verboseLog('DASH quality changed to $newQuality', tag: 'WebVideoPlayer');
        _notifyDashQualityChange(newQuality);
      })
      // Buffer level updated - can update bandwidth estimate
      ..on(DashEvents.bufferLevelUpdated, (data) {
        _updateDashBandwidthEstimate();
      })
      // Text tracks added
      ..on(DashEvents.allTextTracksAdded, (data) {
        verboseLog('DASH text tracks added', tag: 'WebVideoPlayer');
        _updateDashSubtitleTracks();
      })
      // Error handling
      ..on(DashEvents.error, _handleDashError);
  }

  /// Updates available quality tracks from dash.js.
  void _updateDashAvailableQualities() {
    final dash = _dashPlayer;
    if (dash == null) return;

    final bitrateList = dash.getVideoBitrateInfoList();
    _availableQualities = [
      VideoQualityTrack.auto, // Always add auto option
      ...bitrateList.map(
        (info) => VideoQualityTrack(
          id: info.index.toString(),
          label: info.label,
          width: info.width,
          height: info.height,
          bitrate: info.bitrate,
        ),
      ),
    ];

    _addEvent(VideoQualityTracksChangedEvent(_availableQualities));
    verboseLog('DASH available qualities: ${_availableQualities.length}', tag: 'WebVideoPlayer');
  }

  /// Notifies about DASH quality change.
  void _notifyDashQualityChange(int qualityIndex) {
    if (qualityIndex < 0 || qualityIndex >= _availableQualities.length - 1) {
      // Auto mode or invalid
      _addEvent(const SelectedQualityChangedEvent(VideoQualityTrack.auto, isAutoSwitch: true));
    } else {
      // +1 because index 0 is "auto"
      final quality = _availableQualities[qualityIndex + 1];
      _addEvent(SelectedQualityChangedEvent(quality, isAutoSwitch: _selectedQualityIndex == -1));
    }
  }

  /// Updates bandwidth estimate from dash.js.
  void _updateDashBandwidthEstimate() {
    final dash = _dashPlayer;
    if (dash == null) return;

    // dash.js returns throughput in kbps, convert to bps
    final throughputKbps = dash.getAverageThroughput();
    final bandwidth = throughputKbps * 1000;
    if (bandwidth > 0 && (bandwidth - _lastSentBandwidth).abs() > 100000) {
      _lastSentBandwidth = bandwidth;
      _addEvent(BandwidthEstimateChangedEvent(bandwidth.toInt()));
    }
  }

  /// Updates subtitle tracks from dash.js.
  void _updateDashSubtitleTracks() {
    final dash = _dashPlayer;
    if (dash == null) return;

    final dashTracks = dash.getTextTracks();
    if (dashTracks.isEmpty) return;

    final tracks = dashTracks
        .map((t) => SubtitleTrack(id: t.index.toString(), label: t.label, language: t.lang, isDefault: t.isDefault))
        .toList();

    _addEvent(SubtitleTracksChangedEvent(tracks));
  }

  /// Updates audio tracks from dash.js.
  void _updateDashAudioTracks() {
    final dash = _dashPlayer;
    if (dash == null) return;

    final dashTracks = dash.getAudioTracks();
    if (dashTracks.isEmpty) return;

    final tracks = dashTracks
        .map((t) => AudioTrack(id: t.index.toString(), label: t.label, language: t.lang, isDefault: t.isDefault))
        .toList();

    _addEvent(AudioTracksChangedEvent(tracks));
  }

  /// Handles dash.js errors.
  void _handleDashError(JSObject? data) {
    if (data == null) return;

    final errorObj = data['error'] as JSObject?;
    final message = (errorObj?['message'] as JSString?)?.toDart ?? 'Unknown DASH error';

    verboseLog('DASH error: $message', tag: 'WebVideoPlayer');

    // Check if it's a network-related error
    final isNetworkError = message.toLowerCase().contains('network') || message.toLowerCase().contains('fetch');

    if (isNetworkError) {
      _hadNetworkError = true;
      _wasPlayingBeforeError = !_videoElement.paused;
      _addEvent(
        NetworkErrorEvent(
          message: 'DASH network error: $message',
          willRetry: _networkRetryCount < _maxNetworkRetries,
          retryAttempt: _networkRetryCount,
        ),
      );
    } else {
      _addEvents([ErrorEvent('DASH error: $message'), const PlaybackStateChangedEvent(PlaybackState.error)]);
    }
  }

  /// Sets up network connectivity monitoring using the Navigator.onLine API.
  void _setupNetworkMonitoring() {
    _isNetworkAvailable = web.window.navigator.onLine;

    web.window.addEventListener(
      'online',
      ((web.Event event) {
        final wasAvailable = _isNetworkAvailable;
        _isNetworkAvailable = true;
        _addEvent(const NetworkStateChangedEvent(isConnected: true));

        // Attempt recovery if we had a network error
        if (!wasAvailable && _hadNetworkError) {
          _attemptNetworkRecovery();
        }
      }).toJS,
    );

    web.window.addEventListener(
      'offline',
      ((web.Event event) {
        _isNetworkAvailable = false;
        _addEvent(const NetworkStateChangedEvent(isConnected: false));
      }).toJS,
    );
  }

  /// Attempts to recover from a network error.
  void _attemptNetworkRecovery() {
    if (_networkRetryCount >= _maxNetworkRetries) {
      return;
    }

    _networkRetryCount++;

    if (_isUsingHlsJs && _hlsPlayer != null) {
      // HLS.js recovery
      _hlsPlayer!.startLoad();
      if (_wasPlayingBeforeError) {
        _videoElement.play();
      }
      _hadNetworkError = false;
      _addEvent(PlaybackRecoveredEvent(retriesUsed: _networkRetryCount));
      _networkRetryCount = 0;
    } else if (_isUsingDashJs && _dashPlayer != null) {
      // dash.js recovery - reset and reinitialize
      final currentPosition = _videoElement.currentTime;
      final sourceUrl = helpers.getSourceUrl(source);
      _dashPlayer!.attachSource(sourceUrl);
      _videoElement.oncanplay = ((web.Event event) {
        _videoElement.currentTime = currentPosition;
        if (_wasPlayingBeforeError) {
          _videoElement.play();
        }
        _hadNetworkError = false;
        _addEvent(PlaybackRecoveredEvent(retriesUsed: _networkRetryCount));
        _networkRetryCount = 0;
      }).toJS;
    } else {
      // Native recovery
      final currentPosition = _videoElement.currentTime;
      _videoElement
        ..load()
        ..oncanplay = ((web.Event event) {
          _videoElement.currentTime = currentPosition;
          if (_wasPlayingBeforeError) {
            _videoElement.play();
          }
          _hadNetworkError = false;
          _addEvent(PlaybackRecoveredEvent(retriesUsed: _networkRetryCount));
          _networkRetryCount = 0;
        }).toJS;
    }
  }

  /// Sets up remote playback (casting) using the Remote Playback API.
  void _setupRemotePlayback() {
    if (!_allowCasting) return;
    if (!_isRemotePlaybackSupported()) return;

    try {
      // Get the remote playback object
      final remotePlayback = (_videoElement as JSObject)['remote'] as JSObject?;
      if (remotePlayback == null) return;

      // Listen for state changes
      final onConnecting = ((web.Event event) {
        _castState = CastState.connecting;
        _addEvent(const CastStateChangedEvent(state: CastState.connecting));
        verboseLog('Remote playback connecting', tag: 'WebVideoPlayer');
      }).toJS;

      final onConnect = ((web.Event event) {
        _castState = CastState.connected;
        // Create a generic cast device for web (we don't have detailed device info from the API)
        _currentCastDevice = const CastDevice(
          id: 'web-remote-device',
          name: 'Remote Device',
          type: CastDeviceType.webRemotePlayback,
        );
        _addEvent(CastStateChangedEvent(state: CastState.connected, device: _currentCastDevice));
        verboseLog('Remote playback connected', tag: 'WebVideoPlayer');
      }).toJS;

      final onDisconnect = ((web.Event event) {
        _castState = CastState.notConnected;
        _currentCastDevice = null;
        _addEvent(const CastStateChangedEvent(state: CastState.notConnected));
        verboseLog('Remote playback disconnected', tag: 'WebVideoPlayer');
      }).toJS;

      // Add event listeners
      remotePlayback
        ..callMethod('addEventListener'.toJS, 'connecting'.toJS, onConnecting)
        ..callMethod('addEventListener'.toJS, 'connect'.toJS, onConnect)
        ..callMethod('addEventListener'.toJS, 'disconnect'.toJS, onDisconnect);

      verboseLog('Remote playback listeners set up', tag: 'WebVideoPlayer');
    } catch (e) {
      verboseLog('Failed to set up remote playback: $e', tag: 'WebVideoPlayer');
    }
  }

  /// Checks if remote playback (casting) is supported.
  bool _isRemotePlaybackSupported() {
    try {
      final remotePlayback = (_videoElement as JSObject)['remote'] as JSObject?;
      return remotePlayback != null;
    } catch (_) {
      return false;
    }
  }

  /// Sets up media session for browser media controls (Bluetooth, media keys, etc.).
  ///
  /// This enables playback control from:
  /// - Bluetooth headphones/speakers
  /// - Keyboard media keys
  /// - Browser media controls (Chrome, Edge, Firefox)
  /// - macOS Control Center
  /// - Windows media overlay
  void _setupMediaSession() {
    final navigator = web.window.navigator;
    if (!media_session.hasMediaSession(navigator)) {
      verboseLog('Media Session API not available', tag: 'WebVideoPlayer');
      return;
    }

    try {
      final mediaSession = media_session.getMediaSession(navigator);
      if (mediaSession == null) return;

      _setupMediaSessionActionHandlers(mediaSession);
      verboseLog('Media session action handlers set up', tag: 'WebVideoPlayer');
    } catch (e) {
      verboseLog('Failed to set up media session: $e', tag: 'WebVideoPlayer');
    }
  }

  /// Checks if casting is currently supported.
  ///
  /// Web casting uses the Remote Playback API, which is supported
  /// in Chrome, Edge, and some other Chromium-based browsers.
  bool isCastingSupported() => _allowCasting && _isRemotePlaybackSupported();

  /// Gets the list of available cast devices.
  ///
  /// The Remote Playback API doesn't provide a way to enumerate devices,
  /// so this returns an empty list. Use [startCasting] to prompt the user
  /// to select a device.
  List<CastDevice> getAvailableCastDevices() => []; // Browser prompts user to select

  /// Starts casting by prompting the user to select a device.
  ///
  /// The [device] parameter is ignored on web because the Remote Playback API
  /// shows its own device picker. Returns true if the prompt was shown successfully.
  Future<bool> startCasting({CastDevice? device}) async {
    if (!_allowCasting || !_isRemotePlaybackSupported()) {
      return false;
    }

    try {
      final remotePlayback = (_videoElement as JSObject)['remote'] as JSObject?;
      if (remotePlayback == null) return false;

      // prompt() shows the browser's device picker (device parameter is ignored)
      await (remotePlayback.callMethod('prompt'.toJS) as JSPromise?)!.toDart;
      return true;
    } catch (e) {
      verboseLog('Failed to start casting: $e', tag: 'WebVideoPlayer');
      return false;
    }
  }

  /// Stops casting and returns playback to the local device.
  ///
  /// Returns `true` if casting was stopped successfully, `false` if not
  /// currently casting or if the operation failed.
  Future<bool> stopCasting() async {
    if (!_isRemotePlaybackSupported()) return false;

    try {
      final remotePlayback = (_videoElement as JSObject)['remote'] as JSObject?;
      if (remotePlayback == null) return false;

      // Check current state
      final state = (remotePlayback['state'] as JSString?)?.toDart;
      if (state == 'disconnected') return false;

      _castState = CastState.disconnecting;
      _addEvent(const CastStateChangedEvent(state: CastState.disconnecting));

      // cancelWatchAvailability() doesn't stop casting, we need to reload the video
      // The spec doesn't provide a direct way to disconnect, so we reload
      final currentTime = _videoElement.currentTime;
      final wasPaused = _videoElement.paused;

      _videoElement
        ..src = ''
        ..load()
        ..src = helpers.getSourceUrl(source)
        // Restore position when ready
        ..oncanplay = ((web.Event event) {
          _videoElement
            ..currentTime = currentTime
            ..oncanplay = null;
          if (!wasPaused) {
            _videoElement.play();
          }
        }).toJS;

      _castState = CastState.notConnected;
      _currentCastDevice = null;
      _addEvent(const CastStateChangedEvent(state: CastState.notConnected));
      verboseLog('Casting stopped', tag: 'WebVideoPlayer');
      return true;
    } catch (e) {
      verboseLog('Failed to stop casting: $e', tag: 'WebVideoPlayer');
      return false;
    }
  }

  /// Gets the current cast state.
  CastState getCastState() => _castState;

  /// Gets the current cast device, or null if not casting.
  CastDevice? getCurrentCastDevice() => _currentCastDevice;

  void _setupEventListeners() {
    // Playback state events
    _videoElement.onloadedmetadata = ((web.Event event) {
      final duration = getDuration();
      _addEvents([
        const PlaybackStateChangedEvent(PlaybackState.ready),
        DurationChangedEvent(duration),
        VideoSizeChangedEvent(width: _videoElement.videoWidth, height: _videoElement.videoHeight),
      ]);

      // For non-HLS or native HLS playback, notify about tracks
      if (!_isUsingHlsJs) {
        _notifySubtitleTracks();
        _notifyAudioTracks();
      }

      // Extract and send video metadata
      _extractAndSendVideoMetadata();

      // Auto-select subtitle if configured
      if (options.showSubtitlesByDefault && _isInitialSubtitleSelection && !_hasManuallySelectedSubtitle) {
        _autoSelectSubtitle();
        _isInitialSubtitleSelection = false;
      }
    }).toJS;

    _videoElement.onplay = ((web.Event event) {
      _addEvent(const PlaybackStateChangedEvent(PlaybackState.playing));
    }).toJS;

    _videoElement.onpause = ((web.Event event) {
      _addEvent(const PlaybackStateChangedEvent(PlaybackState.paused));
    }).toJS;

    _videoElement.onended = ((web.Event event) {
      _addEvents([const PlaybackCompletedEvent(), const PlaybackStateChangedEvent(PlaybackState.completed)]);
    }).toJS;

    _videoElement.onwaiting = ((web.Event event) {
      _addEvent(const PlaybackStateChangedEvent(PlaybackState.buffering));
    }).toJS;

    _videoElement.oncanplay = ((web.Event event) {
      if (!_videoElement.paused) {
        _addEvent(const PlaybackStateChangedEvent(PlaybackState.playing));
      }
    }).toJS;

    // Position updates (with deduplication - only send if changed by 100ms+)
    _videoElement.ontimeupdate = ((web.Event event) {
      final position = getPosition();
      final positionMs = position.inMilliseconds;
      if ((positionMs - _lastSentPosition).abs() >= 100) {
        _lastSentPosition = positionMs;
        _addEvent(PositionChangedEvent(position));
      }
    }).toJS;

    // Buffering updates (with deduplication - only send if increased)
    _videoElement.onprogress = ((web.Event event) {
      final buffered = _videoElement.buffered;
      if (buffered.length > 0) {
        final bufferedEnd = buffered.end(buffered.length - 1);
        final bufferedMs = (bufferedEnd * 1000).round();
        if (bufferedMs > _lastSentBufferedPosition) {
          _lastSentBufferedPosition = bufferedMs;
          _addEvent(BufferedPositionChangedEvent(Duration(milliseconds: bufferedMs)));
        }
      }
    }).toJS;

    // Error handling with network resilience (for non-HLS.js playback)
    _videoElement.onerror = ((web.Event event) {
      if (_isUsingHlsJs) return; // HLS.js handles its own errors

      final error = _videoElement.error;
      final errorCode = error?.code ?? 0;

      // Check if this is a network error (MEDIA_ERR_NETWORK = 2)
      final isNetworkError = errorCode == 2;

      if (isNetworkError) {
        _hadNetworkError = true;
        _wasPlayingBeforeError = !_videoElement.paused;

        _addEvent(
          NetworkErrorEvent(
            message: error?.message ?? 'Network error',
            willRetry: _networkRetryCount < _maxNetworkRetries,
            retryAttempt: _networkRetryCount,
          ),
        );

        // Auto-retry if network is available
        if (_isNetworkAvailable && _networkRetryCount < _maxNetworkRetries) {
          _attemptNetworkRecovery();
        }
      } else {
        _addEvents([
          ErrorEvent('Video playback error: ${error?.message ?? "Unknown error"}', code: errorCode.toString()),
          const PlaybackStateChangedEvent(PlaybackState.error),
        ]);
      }
    }).toJS;

    // Stalled event for buffering detection
    _videoElement.onstalled = ((web.Event event) {
      _addEvent(const BufferingStartedEvent(reason: BufferingReason.networkUnstable));
    }).toJS;

    // Volume changes
    _videoElement.onvolumechange = ((web.Event event) {
      _addEvent(VolumeChangedEvent(_videoElement.volume));
    }).toJS;

    // Playback speed changes
    _videoElement.onratechange = ((web.Event event) {
      _addEvent(PlaybackSpeedChangedEvent(_videoElement.playbackRate));
    }).toJS;

    // Duration change - important for HLS streams where duration isn't available immediately
    _videoElement.ondurationchange = ((web.Event event) {
      final duration = getDuration();
      if (duration > Duration.zero) {
        _addEvent(DurationChangedEvent(duration));
      }
    }).toJS;

    // Fullscreen changes
    web.document.onfullscreenchange = ((web.Event event) {
      final isFullscreen = web.document.fullscreenElement == _videoElement;
      _addEvent(FullscreenStateChangedEvent(isFullscreen: isFullscreen));
    }).toJS;

    // PiP state changes
    _videoElement
      ..addEventListener(
        'enterpictureinpicture',
        ((web.Event event) {
          _isPipActive = true;
          _addEvent(const PipStateChangedEvent(isActive: true));
          unawaited(_updateScreenSleepPrevention());
        }).toJS,
      )
      ..addEventListener(
        'leavepictureinpicture',
        ((web.Event event) {
          _isPipActive = false;
          _addEvent(const PipStateChangedEvent(isActive: false));
          unawaited(_updateScreenSleepPrevention());
        }).toJS,
      );

    // Page Visibility API - track when page goes to background/foreground
    web.document.addEventListener(
      'visibilitychange',
      ((web.Event event) {
        _isInBackground = web.document.hidden;
        unawaited(_updateScreenSleepPrevention());
      }).toJS,
    );
  }

  /// Starts playback.
  Future<void> play() async {
    try {
      await _videoElement.play().toDart;
      _isPlaying = true;
      await _updateScreenSleepPrevention();
    } catch (e) {
      _addEvent(ErrorEvent('Failed to play video: $e'));
    }
  }

  /// Pauses playback.
  Future<void> pause() async {
    _videoElement.pause();
    _isPlaying = false;
    await _updateScreenSleepPrevention();
  }

  /// Stops playback and resets position.
  Future<void> stop() async {
    _videoElement
      ..pause()
      ..currentTime = 0;
    _isPlaying = false;
    await _updateScreenSleepPrevention();
  }

  // Screen Sleep Prevention

  /// Enables screen sleep prevention using the Screen Wake Lock API.
  Future<void> _enableScreenSleepPrevention() async {
    if (!_preventScreenSleep) return;
    if (_wakeLockSentinel != null) return; // Already acquired

    try {
      _wakeLockSentinel = await wake_lock.requestWakeLock(web.window.navigator);
      if (_wakeLockSentinel != null) {
        verboseLog('Screen wake lock acquired', tag: 'WebVideoPlayer');
      }
    } catch (e) {
      // Silently fail - wake lock is a nice-to-have feature
      verboseLog('Failed to acquire wake lock: $e', tag: 'WebVideoPlayer');
    }
  }

  /// Disables screen sleep prevention by releasing the wake lock.
  Future<void> _disableScreenSleepPrevention() async {
    if (_wakeLockSentinel == null) return;

    try {
      await wake_lock.releaseWakeLock(_wakeLockSentinel);
      verboseLog('Screen wake lock released', tag: 'WebVideoPlayer');
    } catch (e) {
      // Silently fail
      verboseLog('Failed to release wake lock: $e', tag: 'WebVideoPlayer');
    } finally {
      _wakeLockSentinel = null;
    }
  }

  /// Smart wake lock management based on playback, PiP, and background state.
  /// Wake lock is enabled when: Video is playing AND (NOT in background OR in PiP mode)
  /// Wake lock is disabled when: Video is paused OR (in background AND NOT in PiP)
  Future<void> _updateScreenSleepPrevention() async {
    if (!_preventScreenSleep) return;

    // Keep wake lock if playing and (not in background OR in PiP)
    final shouldKeepAwake = _isPlaying && (!_isInBackground || _isPipActive);

    if (shouldKeepAwake) {
      await _enableScreenSleepPrevention();
    } else {
      await _disableScreenSleepPrevention();
    }
  }

  /// Seeks to the specified position.
  void seekTo(Duration position) {
    if (position.isNegative) {
      throw ArgumentError('Position must be non-negative');
    }
    verboseLog('seekTo: $position', tag: 'WebVideoPlayer');
    // Reset last sent position to ensure new position is sent after seek
    _lastSentPosition = -1;
    _videoElement.currentTime = position.inMilliseconds / 1000.0;
  }

  /// Sets the playback speed.
  void setPlaybackSpeed(double speed) {
    if (speed <= 0.0 || speed > 10.0) {
      throw ArgumentError('Playback speed must be between 0.0 (exclusive) and 10.0');
    }
    _videoElement.playbackRate = speed;
  }

  /// Sets the volume.
  void setVolume(double volume) {
    _videoElement.volume = volume.clamp(0.0, 1.0);
  }

  /// Whether the video should loop.
  bool get looping => _videoElement.loop;

  /// Sets whether the video should loop.
  set looping(bool value) {
    _videoElement.loop = value;
  }

  /// Sets the video scaling mode.
  void setScalingMode(VideoScalingMode mode) {
    final objectFit = helpers.getObjectFitFromScalingMode(mode);
    _videoElement.style.setProperty('object-fit', objectFit);
  }

  /// Sets the active subtitle track.
  void setSubtitleTrack(SubtitleTrack? track) {
    _hasManuallySelectedSubtitle = true;

    if (_isUsingHlsJs && _hlsPlayer != null) {
      // Use HLS.js subtitle selection
      if (track == null) {
        _hlsPlayer!.subtitleTrack = -1;
        // Also hide external track elements
        for (final element in _externalTrackElements.values) {
          element.track.mode = 'hidden';
        }
      } else if (track.id.startsWith('ext_')) {
        // External subtitle track
        _hlsPlayer!.subtitleTrack = -1; // Disable HLS.js subtitles
        // Show the selected external track, hide others
        for (final entry in _externalTrackElements.entries) {
          entry.value.track.mode = entry.key == track.id ? 'showing' : 'hidden';
        }
      } else {
        // Embedded HLS.js track
        final index = int.tryParse(track.id) ?? -1;
        _hlsPlayer!.subtitleTrack = index;
        // Hide external tracks
        for (final element in _externalTrackElements.values) {
          element.track.mode = 'hidden';
        }
      }
    } else if (_isUsingDashJs && _dashPlayer != null) {
      // Use dash.js subtitle selection
      if (track == null) {
        _dashPlayer!.setTextTrackVisibility(visible: false);
        // Also hide external track elements
        for (final element in _externalTrackElements.values) {
          element.track.mode = 'hidden';
        }
      } else if (track.id.startsWith('ext_')) {
        // External subtitle track
        _dashPlayer!.setTextTrackVisibility(visible: false); // Disable dash.js subtitles
        // Show the selected external track, hide others
        for (final entry in _externalTrackElements.entries) {
          entry.value.track.mode = entry.key == track.id ? 'showing' : 'hidden';
        }
      } else {
        // Embedded dash.js track
        final index = int.tryParse(track.id) ?? 0;
        _dashPlayer!.setTextTrack(index);
        _dashPlayer!.setTextTrackVisibility(visible: true);
        // Hide external tracks
        for (final element in _externalTrackElements.values) {
          element.track.mode = 'hidden';
        }
      }
    } else {
      // HTML5 video text tracks
      final textTracks = _videoElement.textTracks;

      if (track == null) {
        // Disable all tracks
        for (var i = 0; i < textTracks.length; i++) {
          textTracks[i].mode = 'hidden';
        }
      } else if (track.id.startsWith('ext_')) {
        // External subtitle track - find by track element
        for (var i = 0; i < textTracks.length; i++) {
          final textTrack = textTracks[i];
          // Check if this textTrack corresponds to our external track element
          final element = _externalTrackElements[track.id];
          if (element != null && element.track == textTrack) {
            textTrack.mode = 'showing';
          } else {
            textTrack.mode = 'hidden';
          }
        }
      } else if (track.id.startsWith('embedded_')) {
        // Embedded track with "embedded_N" format
        final indexStr = track.id.replaceFirst('embedded_', '');
        final targetIndex = int.tryParse(indexStr);
        for (var i = 0; i < textTracks.length; i++) {
          final textTrack = textTracks[i];
          // Skip external tracks when counting
          final isExternal = _externalTrackElements.values.any((el) => el.track == textTrack);
          if (!isExternal && i == targetIndex) {
            textTrack.mode = 'showing';
          } else {
            textTrack.mode = 'hidden';
          }
        }
      } else {
        // Legacy numeric index format (for backwards compatibility)
        for (var i = 0; i < textTracks.length; i++) {
          final textTrack = textTracks[i];
          if (i.toString() == track.id) {
            textTrack.mode = 'showing';
          } else {
            textTrack.mode = 'hidden';
          }
        }
      }
    }

    _addEvent(SelectedSubtitleChangedEvent(track));
  }

  /// Sets the subtitle rendering mode (native or flutter).
  ///
  /// - native: Browser's TextTrack API renders subtitles
  /// - flutter: Subtitle text is extracted and streamed to Flutter for rendering
  /// - auto: Defaults to native rendering
  void setSubtitleRenderMode(String mode) {
    verboseLog('Subtitle render mode set to: $mode', tag: 'Subtitles');
    _subtitleRenderMode = mode;

    final shouldUseFlutterRendering = (mode == 'flutter');

    if (shouldUseFlutterRendering) {
      // Enable Flutter rendering: set up cue listeners and hide native display
      _setupCueChangeListeners();
    } else {
      // Enable native rendering: remove cue listeners and show native display
      _removeCueChangeListeners();
    }

    verboseLog('Subtitle rendering ${shouldUseFlutterRendering ? "Flutter" : "native"}', tag: 'Subtitles');
  }

  /// Sets the active audio track.
  void setAudioTrack(AudioTrack? track) {
    if (_isUsingHlsJs && _hlsPlayer != null) {
      // Use HLS.js audio track selection
      if (track != null) {
        final index = int.tryParse(track.id) ?? 0;
        _hlsPlayer!.audioTrack = index;
      }
    } else if (_isUsingDashJs && _dashPlayer != null) {
      // Use dash.js audio track selection
      if (track != null) {
        final index = int.tryParse(track.id) ?? 0;
        _dashPlayer!.setAudioTrack(index);
      }
    } else {
      // HTML5 AudioTrackList - limited browser support (Safari only)
      // Chrome, Firefox, Edge return null for audioTracks
      try {
        final audioTracks = _videoElement.audioTracks;
        for (var i = 0; i < audioTracks.length; i++) {
          audioTracks[i].enabled = track != null && i.toString() == track.id;
        }
      } catch (e) {
        // AudioTrackList not supported in this browser
        verboseLog('AudioTrackList not supported: $e', tag: 'WebVideoPlayer');
      }
    }

    _addEvent(SelectedAudioChangedEvent(track));
  }

  /// Gets the available video qualities.
  List<VideoQualityTrack> getVideoQualities() {
    final isUsingAdaptivePlayer = (_isUsingHlsJs && _hlsPlayer != null) || (_isUsingDashJs && _dashPlayer != null);
    if (!isUsingAdaptivePlayer || _availableQualities.isEmpty) {
      // Return auto option when HLS.js/dash.js is not being used, not initialized,
      // or when qualities haven't been parsed yet from the manifest
      return [VideoQualityTrack.auto];
    }
    return List.unmodifiable(_availableQualities);
  }

  /// Sets the video quality.
  ///
  /// Returns true if the quality was set successfully.
  bool setVideoQuality(VideoQualityTrack track) {
    if (_isUsingHlsJs && _hlsPlayer != null) {
      return _setHlsQuality(track);
    } else if (_isUsingDashJs && _dashPlayer != null) {
      return _setDashQuality(track);
    }
    return track.isAuto;
  }

  /// Sets HLS.js quality.
  bool _setHlsQuality(VideoQualityTrack track) {
    if (track.isAuto) {
      _selectedQualityIndex = -1;
      _hlsPlayer!.currentLevel = -1;
      verboseLog('Set HLS quality to auto', tag: 'WebVideoPlayer');
      return true;
    }

    final index = int.tryParse(track.id);
    if (index == null || index < 0 || index >= _hlsPlayer!.levels.length) {
      return false;
    }

    _selectedQualityIndex = index;
    _hlsPlayer!.currentLevel = index;
    verboseLog('Set HLS quality to level $index', tag: 'WebVideoPlayer');
    return true;
  }

  /// Sets dash.js quality.
  bool _setDashQuality(VideoQualityTrack track) {
    if (track.isAuto) {
      _selectedQualityIndex = -1;
      _dashPlayer!.setAutoSwitchQualityFor('video', enabled: true);
      verboseLog('Set DASH quality to auto', tag: 'WebVideoPlayer');
      return true;
    }

    final index = int.tryParse(track.id);
    final bitrateList = _dashPlayer!.getVideoBitrateInfoList();
    if (index == null || index < 0 || index >= bitrateList.length) {
      return false;
    }

    _selectedQualityIndex = index;
    _dashPlayer!.setAutoSwitchQualityFor('video', enabled: false);
    _dashPlayer!.setQualityFor('video', index);
    verboseLog('Set DASH quality to level $index', tag: 'WebVideoPlayer');
    return true;
  }

  /// Gets the current video quality.
  VideoQualityTrack getCurrentVideoQuality() {
    if (_isUsingHlsJs && _hlsPlayer != null) {
      final currentLevel = _hlsPlayer!.currentLevel;
      if (currentLevel < 0 || currentLevel >= _availableQualities.length - 1) {
        return VideoQualityTrack.auto;
      }
      // +1 because index 0 is "auto"
      return _availableQualities[currentLevel + 1];
    } else if (_isUsingDashJs && _dashPlayer != null) {
      if (_dashPlayer!.getAutoSwitchQualityFor('video')) {
        return VideoQualityTrack.auto;
      }
      final currentQuality = _dashPlayer!.getQualityFor('video');
      if (currentQuality < 0 || currentQuality >= _availableQualities.length - 1) {
        return VideoQualityTrack.auto;
      }
      // +1 because index 0 is "auto"
      return _availableQualities[currentQuality + 1];
    }
    return VideoQualityTrack.auto;
  }

  /// Checks if quality selection is supported.
  bool isQualitySelectionSupported() {
    final hasHlsQualities = _isUsingHlsJs && _hlsPlayer != null && _availableQualities.length > 1;
    final hasDashQualities = _isUsingDashJs && _dashPlayer != null && _availableQualities.length > 1;
    return hasHlsQualities || hasDashQualities;
  }

  /// Notifies Flutter about available subtitle tracks.
  void _notifySubtitleTracks() {
    final textTracks = _videoElement.textTracks;
    final tracks = <SubtitleTrack>[];

    for (var i = 0; i < textTracks.length; i++) {
      final textTrack = textTracks[i];
      tracks.add(
        SubtitleTrack(
          id: i.toString(),
          label: textTrack.label.isNotEmpty ? textTrack.label : 'Track ${i + 1}',
          language: textTrack.language.isNotEmpty ? textTrack.language : null,
          isDefault: i == 0,
        ),
      );
    }

    if (tracks.isNotEmpty) {
      _addEvent(SubtitleTracksChangedEvent(tracks));
    }

    // Set up cuechange listeners for embedded subtitle extraction
    if (_subtitleRenderMode == 'flutter') {
      _setupCueChangeListeners();
    }
  }

  /// Sets up cuechange listeners on text tracks for Flutter subtitle rendering.
  void _setupCueChangeListeners() {
    final textTracks = _videoElement.textTracks;

    for (var i = 0; i < textTracks.length; i++) {
      final textTrack = textTracks[i];
      // Set mode to 'hidden' so we receive cues but native rendering is suppressed
      // Listen for cue changes
      textTrack
        ..mode = 'hidden'
        ..oncuechange = ((web.Event event) {
          _handleCueChange(textTrack);
        }).toJS;
    }
  }

  /// Removes cuechange listeners from text tracks and restores native rendering.
  void _removeCueChangeListeners() {
    final textTracks = _videoElement.textTracks;

    for (var i = 0; i < textTracks.length; i++) {
      final textTrack = textTracks[i]..oncuechange = null;
      // Restore native rendering: set mode based on selection state
      // The selected track should be 'showing', others 'disabled'
      if (textTrack.mode == 'hidden') {
        textTrack.mode = 'showing';
      }
    }

    // Clear any lingering subtitle cue
    _addEvent(const EmbeddedSubtitleCueEvent(cue: null));
  }

  /// Handles cue change events from text tracks.
  void _handleCueChange(web.TextTrack textTrack) {
    final activeCues = textTrack.activeCues;
    if (activeCues == null || activeCues.length == 0) {
      // No active cue - send null to clear the subtitle
      _addEvent(const EmbeddedSubtitleCueEvent(cue: null));
      return;
    }

    // Combine text from all active cues
    final texts = <String>[];
    Duration? startTime;
    Duration? endTime;

    for (var i = 0; i < activeCues.length; i++) {
      final cue = activeCues[i];
      // VTTCue has a text property; we access it via JS interop
      final text = (cue as dynamic).text as String?;
      if (text != null && text.isNotEmpty) {
        texts.add(text);
      }

      // Capture timing from first cue
      if (i == 0) {
        startTime = Duration(milliseconds: (cue.startTime * 1000).round());
        endTime = Duration(milliseconds: (cue.endTime * 1000).round());
      }
    }

    if (texts.isEmpty) {
      _addEvent(const EmbeddedSubtitleCueEvent(cue: null));
      return;
    }

    final combinedText = texts.join('\n');
    final subtitleCue = SubtitleCue(
      text: combinedText,
      start: startTime ?? Duration.zero,
      end: endTime ?? Duration.zero,
    );

    _addEvent(EmbeddedSubtitleCueEvent(cue: subtitleCue));
  }

  /// Notifies Flutter about available audio tracks.
  void _notifyAudioTracks() {
    // HTML5 AudioTrackList - limited browser support (Safari only)
    // Most browsers return null for audioTracks
    try {
      final audioTracks = _videoElement.audioTracks;
      final tracks = <AudioTrack>[];

      for (var i = 0; i < audioTracks.length; i++) {
        final audioTrack = audioTracks[i];
        tracks.add(
          AudioTrack(
            id: i.toString(),
            label: audioTrack.label.isNotEmpty ? audioTrack.label : 'Audio ${i + 1}',
            language: audioTrack.language.isNotEmpty ? audioTrack.language : null,
            isDefault: audioTrack.enabled,
          ),
        );
      }

      if (tracks.isNotEmpty) {
        _addEvent(AudioTracksChangedEvent(tracks));
      }
    } catch (e) {
      // AudioTrackList not supported in this browser (Chrome, Firefox, Edge)
      verboseLog('AudioTrackList not supported: $e', tag: 'WebVideoPlayer');
    }
  }

  /// Auto-selects a subtitle track based on preferred language.
  void _autoSelectSubtitle() {
    if (_isUsingHlsJs && _hlsPlayer != null) {
      // HLS.js subtitle auto-selection
      final preferredLanguage = options.preferredSubtitleLanguage;
      final tracks = _hlsPlayer!.subtitleTracks;

      if (tracks.isEmpty) return;

      var selectedIndex = -1;

      if (preferredLanguage != null) {
        for (final track in tracks) {
          if (track.lang == preferredLanguage) {
            selectedIndex = track.index;
            break;
          }
        }
      }

      // Fall back to first or default track
      if (selectedIndex == -1) {
        for (final track in tracks) {
          if (track.isDefault) {
            selectedIndex = track.index;
            break;
          }
        }
        if (selectedIndex == -1 && tracks.isNotEmpty) {
          selectedIndex = 0;
        }
      }

      if (selectedIndex >= 0) {
        _hlsPlayer!.subtitleTrack = selectedIndex;
        final track = tracks.firstWhere((t) => t.index == selectedIndex);
        _addEvent(
          SelectedSubtitleChangedEvent(
            SubtitleTrack(id: track.index.toString(), label: track.label, language: track.lang, isDefault: true),
          ),
        );
      }
    } else {
      // Native subtitle auto-selection
      final textTracks = _videoElement.textTracks;
      if (textTracks.length == 0) return;

      var selectedIndex = -1;

      // Try to find track matching preferred language
      final preferredLanguage = options.preferredSubtitleLanguage;
      if (preferredLanguage != null) {
        for (var i = 0; i < textTracks.length; i++) {
          final textTrack = textTracks[i];
          if (textTrack.language == preferredLanguage) {
            selectedIndex = i;
            break;
          }
        }
      }

      // Fall back to first track
      if (selectedIndex == -1 && textTracks.length > 0) {
        selectedIndex = 0;
      }

      // Enable the selected track
      if (selectedIndex >= 0) {
        for (var i = 0; i < textTracks.length; i++) {
          textTracks[i].mode = i == selectedIndex ? 'showing' : 'hidden';
        }

        final selectedTrack = textTracks[selectedIndex];
        _addEvent(
          SelectedSubtitleChangedEvent(
            SubtitleTrack(
              id: selectedIndex.toString(),
              label: selectedTrack.label.isNotEmpty ? selectedTrack.label : 'Track ${selectedIndex + 1}',
              language: selectedTrack.language.isNotEmpty ? selectedTrack.language : null,
              isDefault: true,
            ),
          ),
        );
      }
    }
  }

  /// Gets the current playback position.
  Duration getPosition() => Duration(milliseconds: (_videoElement.currentTime * 1000).round());

  /// Gets the video duration.
  Duration getDuration() {
    final duration = _videoElement.duration;
    if (duration.isNaN || duration.isInfinite) {
      return Duration.zero;
    }
    return Duration(milliseconds: (duration * 1000).round());
  }

  /// Gets video metadata (codec, resolution, bitrate, etc.).
  ///
  /// Returns null if metadata is not available yet.
  VideoMetadata? getVideoMetadata() {
    // Check if video has loaded enough metadata
    if (_videoElement.readyState < 1) {
      return null;
    }

    final duration = getDuration();
    final width = _videoElement.videoWidth;
    final height = _videoElement.videoHeight;

    // Get codec and bitrate info from HLS.js if available
    String? videoCodec;
    String? audioCodec;
    int? videoBitrate;
    int? audioBitrate;
    double? frameRate;

    if (_isUsingHlsJs && _hlsPlayer != null) {
      final currentLevel = _hlsPlayer!.currentLevel;
      if (currentLevel >= 0) {
        final levels = _hlsPlayer!.levels;
        if (currentLevel < levels.length) {
          final level = levels[currentLevel];
          videoBitrate = level.bitrate > 0 ? level.bitrate : null;

          // Parse codecs string (e.g., "avc1.64001f,mp4a.40.2")
          final codecs = level.codecs;
          if (codecs != null && codecs.isNotEmpty) {
            final codecParts = codecs.split(',');
            for (final codec in codecParts) {
              final trimmed = codec.trim();
              if (trimmed.startsWith('avc') || trimmed.startsWith('hvc') || trimmed.startsWith('vp')) {
                videoCodec = trimmed;
              } else if (trimmed.startsWith('mp4a') || trimmed.startsWith('opus') || trimmed.startsWith('ac-')) {
                audioCodec = trimmed;
              }
            }
          }
        }
      }
    }

    // Infer container format from URL
    final sourceUrl = helpers.getSourceUrl(source);
    final containerFormat = helpers.inferContainerFormat(sourceUrl);

    return VideoMetadata(
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      width: width > 0 ? width : null,
      height: height > 0 ? height : null,
      videoBitrate: videoBitrate,
      audioBitrate: audioBitrate,
      frameRate: frameRate,
      duration: duration > Duration.zero ? duration : null,
      containerFormat: containerFormat,
    );
  }

  /// Extracts and sends video metadata event.
  void _extractAndSendVideoMetadata() {
    final metadata = getVideoMetadata();
    if (metadata != null) {
      _addEvent(VideoMetadataExtractedEvent(metadata));
    }
  }

  /// Checks if Picture-in-Picture is supported in the current browser.
  static bool isPipSupported() => web.document.pictureInPictureEnabled;

  /// Enters Picture-in-Picture mode.
  Future<bool> enterPip() async {
    if (!isPipSupported()) {
      return false;
    }
    try {
      await _videoElement.requestPictureInPicture().toDart;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Exits Picture-in-Picture mode.
  Future<void> exitPip() async {
    if (web.document.pictureInPictureElement != null) {
      try {
        await web.document.exitPictureInPicture().toDart;
      } catch (_) {
        // Ignore errors when exiting PiP
      }
    }
  }

  /// Enters fullscreen mode.
  Future<bool> enterFullscreen() async {
    try {
      await _videoElement.requestFullscreen().toDart;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Exits fullscreen mode.
  Future<void> exitFullscreen() async {
    try {
      await web.document.exitFullscreen().toDart;
    } catch (_) {
      // Ignore errors when exiting fullscreen
    }
  }

  /// Sets media metadata for browser media controls (Media Session API).
  void setMediaMetadata(MediaMetadata metadata) {
    final navigator = web.window.navigator;
    if (!media_session.hasMediaSession(navigator)) {
      verboseLog('Media Session API not available', tag: 'WebVideoPlayer');
      return;
    }

    try {
      final mediaSession = media_session.getMediaSession(navigator);
      if (mediaSession == null) return;

      final jsMetadata = media_session.createMediaMetadata(
        title: metadata.title ?? '',
        artist: metadata.artist ?? '',
        album: metadata.album ?? '',
        artwork: metadata.artworkUrl,
      );

      media_session.setMediaSessionMetadata(mediaSession, jsMetadata);
      _setupMediaSessionActionHandlers(mediaSession);

      verboseLog('Media metadata set: ${metadata.title}', tag: 'WebVideoPlayer');
    } catch (e) {
      verboseLog('Failed to set media metadata: $e', tag: 'WebVideoPlayer');
    }
  }

  /// Sets up action handlers for media session playback controls.
  void _setupMediaSessionActionHandlers(JSObject mediaSession) {
    media_session.setMediaSessionActionHandler(mediaSession, 'play', play);
    media_session.setMediaSessionActionHandler(mediaSession, 'pause', pause);
    media_session.setMediaSessionActionHandler(mediaSession, 'stop', stop);
    media_session.setMediaSessionActionHandler(mediaSession, 'seekforward', () {
      final currentPos = _videoElement.currentTime;
      final newPos = currentPos + 15;
      _videoElement.currentTime = newPos;
    });
    media_session.setMediaSessionActionHandler(mediaSession, 'seekbackward', () {
      final currentPos = _videoElement.currentTime;
      final newPos = (currentPos - 15).clamp(0, _videoElement.duration);
      _videoElement.currentTime = newPos;
    });
  }

  // MARK: - External Subtitles

  /// Adds an external subtitle track from a URL.
  ///
  /// For web, browsers natively support VTT format. Other formats (SRT, SSA, TTML)
  /// are converted to VTT on load if possible, but browser support may vary.
  ///
  /// Returns the created [ExternalSubtitleTrack] on success, or null on failure.
  Future<ExternalSubtitleTrack?> addExternalSubtitle(SubtitleSource source) async {
    try {
      // Generate unique ID
      final trackId = 'ext_${_nextExternalSubtitleId++}';

      var subtitleUrl = source.path;
      final format = source.format;
      final label = source.label;
      final language = source.language;
      final isDefault = source.isDefault;

      // Detect format from URL if not provided
      final detectedFormat = format ?? helpers.detectSubtitleFormat(subtitleUrl);

      // Create label from URL if not provided
      final trackLabel = label ?? helpers.labelFromUrl(subtitleUrl);

      // If format is not WebVTT, load and convert to WebVTT, then create a blob URL
      // This ensures all subtitle formats work on Web via browser's native TextTrack API
      if (detectedFormat != null && detectedFormat != SubtitleFormat.vtt) {
        try {
          verboseLog('Converting ${detectedFormat.name} to WebVTT for browser compatibility', tag: 'WebVideoPlayer');

          // Use SubtitleLoader to load and convert to WebVTT
          final loader = SubtitleLoader();
          final webvttContent = await loader.loadAndConvertToWebVTT(source);
          loader.dispose();

          // Create a Blob from the WebVTT content
          final blob = web.Blob(<JSAny>[webvttContent.toJS].toJS, web.BlobPropertyBag(type: 'text/vtt'));

          // Create a blob URL
          subtitleUrl = web.URL.createObjectURL(blob);

          verboseLog('Created blob URL for converted WebVTT subtitle', tag: 'WebVideoPlayer');
        } catch (e) {
          verboseLog('Failed to convert subtitle to WebVTT: $e, using original URL', tag: 'WebVideoPlayer');
          // Fall back to using the original URL - browser may still handle it
        }
      }

      // Create the track element
      final trackElement = web.HTMLTrackElement()
        ..kind = 'subtitles'
        ..src = subtitleUrl
        ..label = trackLabel
        ..srclang = language ?? '';

      // Set as default if requested
      if (isDefault) {
        trackElement.default_ = true;
      }

      // Add to video element
      _videoElement.appendChild(trackElement);

      // Store the track
      final track = ExternalSubtitleTrack(
        id: trackId,
        label: trackLabel,
        language: language,
        isDefault: isDefault,
        path: source.path, // Store original path, not blob URL
        sourceType: source.sourceType,
        format: detectedFormat ?? SubtitleFormat.vtt,
      );

      _externalSubtitles[trackId] = track;
      _externalTrackElements[trackId] = trackElement;

      verboseLog('Added external subtitle: $trackId ($trackLabel)', tag: 'WebVideoPlayer');

      // Notify about updated subtitle tracks
      _notifySubtitleTracksWithExternal();

      return track;
    } catch (e) {
      verboseLog('Failed to add external subtitle: $e', tag: 'WebVideoPlayer');
      return null;
    }
  }

  /// Removes an external subtitle track.
  ///
  /// Returns true if the track was removed successfully.
  bool removeExternalSubtitle(String trackId) {
    final track = _externalSubtitles.remove(trackId);
    final element = _externalTrackElements.remove(trackId);

    if (track == null || element == null) {
      return false;
    }

    // Remove from video element
    _videoElement.removeChild(element);

    verboseLog('Removed external subtitle: $trackId', tag: 'WebVideoPlayer');

    // Notify about updated subtitle tracks
    _notifySubtitleTracksWithExternal();

    return true;
  }

  /// Gets all external subtitle tracks.
  List<ExternalSubtitleTrack> getExternalSubtitles() => _externalSubtitles.values.toList();

  /// Notifies about subtitle tracks including external ones.
  void _notifySubtitleTracksWithExternal() {
    final allTracks = <SubtitleTrack>[];

    // Add embedded tracks (from video element)
    if (_isUsingHlsJs && _hlsPlayer != null) {
      final hlsTracks = _hlsPlayer!.subtitleTracks;
      for (final t in hlsTracks) {
        allTracks.add(SubtitleTrack(id: t.index.toString(), label: t.label, language: t.lang, isDefault: t.isDefault));
      }
    } else {
      final textTracks = _videoElement.textTracks;
      // Only add non-external tracks (those not created by us)
      for (var i = 0; i < textTracks.length; i++) {
        final textTrack = textTracks[i];
        // Skip external tracks - they're handled separately
        final isExternal = _externalTrackElements.values.any((el) => el.label == textTrack.label);
        if (!isExternal) {
          allTracks.add(
            SubtitleTrack(
              id: 'embedded_$i',
              label: textTrack.label.isNotEmpty ? textTrack.label : 'Track ${i + 1}',
              language: textTrack.language.isNotEmpty ? textTrack.language : null,
              isDefault: i == 0 && _externalSubtitles.isEmpty,
            ),
          );
        }
      }
    }

    // Add external tracks
    allTracks.addAll(_externalSubtitles.values);

    _addEvent(SubtitleTracksChangedEvent(allTracks));
  }

  /// Disposes of the player and releases resources.
  void dispose() {
    _isDisposed = true;

    // Release wake lock
    unawaited(_disableScreenSleepPrevention());

    // Destroy HLS.js player if used
    _hlsPlayer?.destroy();
    _hlsPlayer = null;

    // Destroy dash.js player if used
    _dashPlayer?.destroy();
    _dashPlayer = null;

    _videoElement
      ..pause()
      ..src = ''
      ..load();

    unawaited(_eventController.close());
  }
}
