import 'dart:async';

import 'package:pro_video_player_web/src/abstractions/video_element_interface.dart';

/// Mock HTMLVideoElement for testing without actual DOM.
///
/// Simulates the behavior of a real HTML5 video element with properties
/// and methods that can be controlled in tests.
class MockHTMLVideoElement implements VideoElementInterface {
  /// Current video source URL.
  String _src = '';

  @override
  String get src => _src;

  @override
  set src(Object? value) => _src = value! as String;

  /// Current playback position in seconds.
  @override
  double currentTime = 0;

  /// Total duration in seconds.
  @override
  double duration = 0;

  /// Whether video is paused.
  @override
  bool paused = true;

  /// Whether video has ended.
  @override
  bool ended = false;

  /// Current volume (0.0 to 1.0).
  double _volume = 1;

  @override
  double get volume => _volume;

  @override
  set volume(Object? value) => _volume = value! as double;

  /// Current playback rate (speed).
  double _playbackRate = 1;

  @override
  double get playbackRate => _playbackRate;

  @override
  set playbackRate(Object? value) => _playbackRate = value! as double;

  /// Whether video is muted.
  bool _muted = false;

  @override
  bool get muted => _muted;

  @override
  set muted(Object? value) => _muted = value! as bool;

  /// Whether video should loop.
  bool _loop = false;

  @override
  bool get loop => _loop;

  @override
  set loop(Object? value) => _loop = value! as bool;

  /// Video width in pixels.
  @override
  double videoWidth = 1920;

  /// Video height in pixels.
  @override
  double videoHeight = 1080;

  /// Ready state (0-4, where 4 = HAVE_ENOUGH_DATA).
  @override
  int readyState = 4;

  /// Network state (0-3).
  @override
  int networkState = 2; // NETWORK_LOADING

  /// Preload setting.
  String _preload = 'auto';

  @override
  String get preload => _preload;

  @override
  set preload(Object? value) => _preload = value! as String;

  /// Video controls visibility.
  bool _controls = false;

  @override
  bool get controls => _controls;

  @override
  set controls(Object? value) => _controls = value! as bool;

  /// Mock audio tracks (for testing audio track selection).
  List<MockAudioTrack> mockAudioTracks = [];

  /// Mock text tracks (for testing subtitle selection).
  List<MockTextTrack> mockTextTracks = [];

  /// Mock remote playback (for testing casting).
  MockRemotePlayback? mockRemotePlayback;

  /// Map of event listeners.
  final Map<String, List<Function>> _eventListeners = {};

  /// Adds an event listener.
  void addEventListener(String event, Function handler) {
    _eventListeners.putIfAbsent(event, () => []).add(handler);
  }

  /// Removes an event listener.
  void removeEventListener(String event, Function handler) {
    _eventListeners[event]?.remove(handler);
  }

  /// Checks if an event has listeners.
  bool hasListener(String event) => _eventListeners[event]?.isNotEmpty ?? false;

  /// Triggers an event with optional data.
  void triggerEvent(String event, [Map<String, dynamic>? data]) {
    final handlers = _eventListeners[event] ?? [];
    final eventData = data ?? {}; // Always pass at least empty object
    for (final handler in handlers) {
      handler(eventData);
    }
  }

  /// Simulates play() method.
  @override
  Future<void> play() async {
    paused = false;
    ended = false;
    triggerEvent('play');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    triggerEvent('playing');
  }

  /// Mock buffered time ranges.
  @override
  MockTimeRanges get buffered => MockTimeRanges();

  /// Simulates pause() method.
  @override
  void pause() {
    paused = true;
    triggerEvent('pause');
  }

  /// Simulates load() method.
  @override
  void load() {
    readyState = 0;
    triggerEvent('loadstart');
    Future.delayed(const Duration(milliseconds: 50), () {
      readyState = 4;
      triggerEvent('loadedmetadata');
      triggerEvent('canplay');
    });
  }
}

/// Mock TimeRanges for buffered property.
class MockTimeRanges {
  int get length => 0;
  num start(int index) => 0;
  num end(int index) => 0;
}

/// Mock HLS.js player for testing.
class MockHlsPlayer {
  /// Whether player is attached to media element.
  bool isAttached = false;

  /// Current source URL.
  String? sourceUrl;

  /// Available quality levels.
  List<MockHlsLevel> levels = [];

  /// Current quality level index (-1 = auto).
  int currentLevel = -1;

  /// Maximum bitrate in bits per second (0 = unlimited).
  int maxBitrate = 0;

  /// Available audio tracks.
  List<MockHlsAudioTrack> audioTracks = [];

  /// Available subtitle tracks.
  List<MockHlsSubtitleTrack> subtitleTracks = [];

  /// Current audio track index.
  int audioTrack = -1;

  /// Current subtitle track index.
  int subtitleTrack = -1;

  /// Event listeners.
  final Map<String, List<Function>> _eventListeners = {};

  /// Callback for startLoad() - used in tests.
  void Function()? onStartLoad;

  /// Attaches player to media element.
  void attachMedia(media) {
    isAttached = true;
  }

  /// Loads a source URL.
  void loadSource(String url) {
    sourceUrl = url;
    // Simulate manifest parsed event
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      triggerEvent('manifestParsed');
    });
  }

  /// Starts loading (used for recovery).
  void startLoad() {
    onStartLoad?.call();
  }

  /// Adds an event listener.
  void on(String event, Function handler) {
    _eventListeners.putIfAbsent(event, () => []).add(handler);
  }

  /// Removes an event listener.
  void off(String event, Function? handler) {
    if (handler != null) {
      _eventListeners[event]?.remove(handler);
    } else {
      _eventListeners.remove(event);
    }
  }

  /// Checks if an event has listeners.
  bool hasEventHandler(String event) => _eventListeners.containsKey(event) && _eventListeners[event]!.isNotEmpty;

  /// Triggers an event.
  void triggerEvent(String event, [Object? data]) {
    final handlers = _eventListeners[event] ?? [];
    for (final handler in handlers) {
      if (data != null) {
        handler(event, data);
      } else {
        handler(event);
      }
    }
  }

  /// Destroys the player.
  void destroy() {
    isAttached = false;
    sourceUrl = null;
    _eventListeners.clear();
  }
}

/// Mock HLS quality level.
class MockHlsLevel {
  MockHlsLevel({required this.height, required this.bitrate, this.width, this.name, this.codecs});

  final int height;
  final int bitrate;
  final int? width;
  final String? name;
  final String? codecs;
}

/// Mock HLS audio track.
class MockHlsAudioTrack {
  MockHlsAudioTrack({required this.id, required this.name, this.lang});

  final int id;
  final String name;
  final String? lang;
}

/// Mock HLS subtitle track.
class MockHlsSubtitleTrack {
  MockHlsSubtitleTrack({required this.id, required this.name, this.lang});

  final int id;
  final String name;
  final String? lang;
}

/// Mock DASH.js MediaPlayer for testing.
class MockDashPlayer {
  /// Whether player is initialized.
  bool isInitialized = false;

  /// Current source URL.
  String? sourceUrl;

  /// Available bitrate infos.
  List<MockDashBitrateInfo> bitrateInfos = [];

  /// Current quality index.
  int currentQuality = 0;

  /// ABR enabled state.
  bool abrEnabled = true;

  /// Available audio tracks.
  List<MockDashAudioTrack> audioTracks = [];

  /// Current audio track index.
  int currentAudioTrack = 0;

  /// Available text tracks.
  List<MockDashTextTrack> textTracks = [];

  /// Current text track index.
  int currentTextTrack = 0;

  /// Text track visibility.
  bool textTrackVisible = false;

  /// Average throughput in kbps (dash.js uses kbps).
  double averageThroughputKbps = 0;

  /// Event listeners.
  final Map<String, List<Function>> _eventListeners = {};

  /// Callback for reset() - used in tests.
  void Function()? onReset;

  /// Callback for attachSource() - used in tests.
  void Function()? onAttachSource;

  /// Initializes player with video element.
  void initialize(videoElement, [String? source, bool? autoPlay]) {
    isInitialized = true;
    if (source != null) {
      sourceUrl = source;
    }
  }

  /// Sets the source URL.
  void setSource(String url) {
    sourceUrl = url;
    // Simulate stream initialized event
    Future.delayed(const Duration(milliseconds: 50), () {
      triggerEvent('streamInitialized');
    });
  }

  /// Gets bitrate info for a media type.
  List<MockDashBitrateInfo> getBitrateInfoListFor(String type) => bitrateInfos;

  /// Gets video bitrate info list.
  List<MockDashBitrateInfo> getVideoBitrateInfoList() => bitrateInfos;

  /// Sets quality for a media type.
  void setQualityFor(String type, int value) {
    currentQuality = value;
  }

  /// Gets current quality for a media type.
  int getQualityFor(String type) => currentQuality;

  /// Sets auto switch quality for a media type.
  void setAutoSwitchQualityFor(String type, {required bool enabled}) {
    abrEnabled = enabled;
  }

  /// Gets auto switch quality for a media type.
  bool getAutoSwitchQualityFor(String type) => abrEnabled;

  /// Sets ABR (Adaptive Bitrate) enabled state.
  void setABREnabled(bool enabled) {
    abrEnabled = enabled;
  }

  /// Sets minimum bitrate in bps.
  void setMinBitrate(int bitrate) {
    // Store for testing verification if needed
  }

  /// Sets maximum bitrate in bps.
  void setMaxBitrate(int bitrate) {
    // Store for testing verification if needed
  }

  /// Gets audio tracks.
  List<MockDashAudioTrack> getAudioTracks() => audioTracks;

  /// Gets text tracks.
  List<MockDashTextTrack> getTextTracks() => textTracks;

  /// Sets audio track by index.
  void setAudioTrack(int index) {
    currentAudioTrack = index;
  }

  /// Sets text track by index.
  void setTextTrack(int index) {
    currentTextTrack = index;
  }

  /// Sets text track visibility.
  void setTextTrackVisibility({required bool visible}) {
    textTrackVisible = visible;
  }

  /// Gets average throughput in kbps.
  double getAverageThroughput() => averageThroughputKbps;

  /// Attaches source to player.
  void attachSource(String url) {
    sourceUrl = url;
    onAttachSource?.call();
  }

  /// Gets current track for a media type.
  dynamic getCurrentTrackFor(String type) {
    return null; // Simplified for testing
  }

  /// Sets current track for a media type.
  void setCurrentTrack(track) {
    // Simplified for testing
  }

  /// Updates settings with ABR config.
  void updateSettings(Map<String, dynamic> settings) {
    if (settings.containsKey('streaming')) {
      final streaming = settings['streaming'] as Map<String, dynamic>;
      if (streaming.containsKey('abr')) {
        final abr = streaming['abr'] as Map<String, dynamic>;
        if (abr.containsKey('autoSwitchBitrate')) {
          final autoSwitch = abr['autoSwitchBitrate'] as Map<String, dynamic>;
          abrEnabled = autoSwitch['video'] as bool? ?? true;
        }
      }
    }
  }

  /// Adds an event listener.
  void on(String event, Function handler) {
    _eventListeners.putIfAbsent(event, () => []).add(handler);
  }

  /// Removes an event listener.
  void off(String event, Function? handler) {
    if (handler != null) {
      _eventListeners[event]?.remove(handler);
    } else {
      _eventListeners.remove(event);
    }
  }

  /// Checks if an event has listeners.
  bool hasEventHandler(String event) => _eventListeners.containsKey(event) && _eventListeners[event]!.isNotEmpty;

  /// Triggers an event.
  void triggerEvent(String event, [Object? data]) {
    final handlers = _eventListeners[event] ?? [];
    for (final handler in handlers) {
      if (data != null) {
        handler(data);
      } else {
        handler();
      }
    }
  }

  /// Resets the player.
  void reset() {
    onReset?.call();
    isInitialized = false;
    sourceUrl = null;
    _eventListeners.clear();
  }
}

/// Mock DASH bitrate info.
class MockDashBitrateInfo {
  MockDashBitrateInfo({required this.bitrate, required this.width, required this.height, this.qualityIndex});

  final int bitrate;
  final int width;
  final int height;
  final int? qualityIndex;
}

/// Mock DASH audio track.
class MockDashAudioTrack {
  MockDashAudioTrack({required this.index, required this.lang, required this.label});

  final int index;
  final String lang;
  final String label;
}

/// Mock DASH text track.
class MockDashTextTrack {
  MockDashTextTrack({required this.index, required this.lang, required this.label});

  final int index;
  final String lang;
  final String label;
}

/// Mock HTML5 audio track.
class MockAudioTrack {
  MockAudioTrack({required this.id, required this.label, this.language, this.enabled = false});

  final String id;
  final String label;
  final String? language;
  bool enabled;
}

/// Mock HTML5 text track.
class MockTextTrack {
  MockTextTrack({required this.id, required this.label, this.language, this.mode = 'disabled'});

  final String id;
  final String label;
  final String? language;
  String mode; // 'disabled', 'hidden', 'showing'
}

/// Mock Wake Lock Sentinel.
class MockWakeLockSentinel {
  bool _released = false;
  final StreamController<void> _releaseController = StreamController<void>.broadcast();

  /// Whether the wake lock has been released.
  bool get released => _released;

  /// Stream that emits when wake lock is released.
  Stream<void> get onrelease => _releaseController.stream;

  /// Releases the wake lock.
  Future<void> release() async {
    if (_released) return;
    _released = true;
    _releaseController.add(null);
  }

  /// Disposes the controller.
  void dispose() {
    _releaseController.close();
  }
}

/// Mock Wake Lock API.
class MockWakeLock {
  MockWakeLockSentinel? _currentSentinel;

  /// Requests a wake lock.
  Future<MockWakeLockSentinel> request(String type) async {
    final sentinel = MockWakeLockSentinel();
    _currentSentinel = sentinel;
    return sentinel;
  }

  /// Gets the current wake lock sentinel.
  MockWakeLockSentinel? get currentSentinel => _currentSentinel;

  /// Clears the current sentinel.
  void clear() {
    _currentSentinel = null;
  }
}

/// Mock Remote Playback API for testing casting.
class MockRemotePlayback {
  /// Current state ('disconnected', 'connecting', 'connected').
  String state = 'disconnected';

  /// Event listeners.
  final Map<String, List<Function>> _eventListeners = {};

  /// Callback for prompt() - used in tests.
  void Function()? onPrompt;

  /// Adds an event listener.
  void addEventListener(String event, Function handler) {
    _eventListeners.putIfAbsent(event, () => []).add(handler);
  }

  /// Removes an event listener.
  void removeEventListener(String event, Function handler) {
    _eventListeners[event]?.remove(handler);
  }

  /// Checks if an event has listeners.
  bool hasListener(String event) => _eventListeners[event]?.isNotEmpty ?? false;

  /// Triggers an event with a dummy event object.
  void triggerEvent(String event) {
    final handlers = _eventListeners[event] ?? [];
    for (final handler in handlers) {
      handler(<String, dynamic>{}); // Pass dummy event object
    }
  }

  /// Shows the device picker prompt.
  Future<void> prompt() async {
    onPrompt?.call();
  }
}
