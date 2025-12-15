import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'verbose_logging.dart';

/// HLS.js CDN URL - using a stable version.
const String hlsJsCdnUrl = 'https://cdn.jsdelivr.net/npm/hls.js@1.5.7/dist/hls.min.js';

/// Checks if HLS.js is loaded in the browser.
bool get isHlsJsLoaded {
  try {
    final hlsConstructor = globalContext['Hls'];
    return hlsConstructor != null && !hlsConstructor.isUndefinedOrNull;
  } catch (_) {
    return false;
  }
}

/// Checks if the browser natively supports HLS (Safari).
bool get isNativeHlsSupported {
  final video = web.HTMLVideoElement();
  return video.canPlayType('application/vnd.apple.mpegurl').isNotEmpty;
}

/// Checks if HLS.js is supported in the current browser.
bool get isHlsJsSupported {
  if (!isHlsJsLoaded) return false;
  try {
    final hlsClass = globalContext['Hls'];
    if (hlsClass == null || hlsClass.isUndefinedOrNull) return false;
    final isSupported = (hlsClass as JSObject).callMethod('isSupported'.toJS) as JSBoolean?;
    return isSupported?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Creates a new HLS.js instance dynamically.
///
/// This uses dynamic JS access because HLS.js is loaded at runtime.
JSObject? _createHlsInstance([JSObject? config]) {
  try {
    final hlsConstructor = globalContext['Hls'];
    if (hlsConstructor == null || hlsConstructor.isUndefinedOrNull) return null;

    // Use JSObject.callAsConstructor to create new instance
    if (config != null) {
      return (hlsConstructor as JSFunction).callAsConstructor(config);
    } else {
      return (hlsConstructor as JSFunction).callAsConstructor();
    }
  } catch (e) {
    verboseLog('Failed to create HLS.js instance: $e', tag: 'HlsInterop');
    return null;
  }
}

/// Loads HLS.js from CDN dynamically.
///
/// Returns a Future that completes when the library is loaded.
/// If already loaded, completes immediately.
Future<bool> loadHlsJs() async {
  if (isHlsJsLoaded) {
    verboseLog('HLS.js already loaded', tag: 'HlsInterop');
    return true;
  }

  verboseLog('Loading HLS.js from CDN...', tag: 'HlsInterop');

  final completer = Completer<bool>();

  final script = web.HTMLScriptElement()
    ..src = hlsJsCdnUrl
    ..type = 'text/javascript'
    ..onload = ((web.Event event) {
      verboseLog('HLS.js loaded successfully', tag: 'HlsInterop');
      completer.complete(true);
    }).toJS
    ..onerror = ((web.Event event) {
      verboseLog('Failed to load HLS.js', tag: 'HlsInterop');
      completer.complete(false);
    }).toJS;

  web.document.head?.appendChild(script);

  return completer.future;
}

/// HLS.js event constants.
///
/// These match the event names used by HLS.js library.
class HlsEvents {
  HlsEvents._();

  /// Fired when manifest has been parsed.
  static const String manifestParsed = 'hlsManifestParsed';

  /// Fired when a level has been loaded.
  static const String levelLoaded = 'hlsLevelLoaded';

  /// Fired when level switch is effective.
  static const String levelSwitched = 'hlsLevelSwitched';

  /// Fired when level switching is requested.
  static const String levelSwitching = 'hlsLevelSwitching';

  /// Fired when audio track has been loaded.
  static const String audioTrackLoaded = 'hlsAudioTrackLoaded';

  /// Fired when audio track switch is effective.
  static const String audioTrackSwitched = 'hlsAudioTrackSwitched';

  /// Fired when audio tracks list is updated.
  static const String audioTracksUpdated = 'hlsAudioTracksUpdated';

  /// Fired when subtitle track has been loaded.
  static const String subtitleTrackLoaded = 'hlsSubtitleTrackLoaded';

  /// Fired when subtitle track switch is requested.
  static const String subtitleTrackSwitch = 'hlsSubtitleTrackSwitch';

  /// Fired when subtitle tracks list is updated.
  static const String subtitleTracksUpdated = 'hlsSubtitleTracksUpdated';

  /// Fired when a fragment has been buffered.
  static const String fragBuffered = 'hlsFragBuffered';

  /// Fired when an error occurred.
  static const String error = 'hlsError';

  /// Fired when media has been attached.
  static const String mediaAttached = 'hlsMediaAttached';

  /// Fired when media has been detached.
  static const String mediaDetached = 'hlsMediaDetached';
}

/// Wrapper for HLS.js instance providing Dart-friendly API.
///
/// Uses dynamic JS access since HLS.js is loaded at runtime from CDN.
class HlsPlayer {
  HlsPlayer._(this._hls);

  final JSObject _hls;
  final List<String> _registeredEvents = [];

  /// Creates a new HLS.js player instance.
  ///
  /// Returns null if HLS.js is not loaded or not supported.
  static HlsPlayer? create({Map<String, dynamic>? config}) {
    if (!isHlsJsLoaded) {
      verboseLog('HLS.js not loaded, cannot create player', tag: 'HlsPlayer');
      return null;
    }

    final jsConfig = config != null ? _mapToJsObject(config) : null;
    final hls = _createHlsInstance(jsConfig);
    if (hls == null) {
      verboseLog('Failed to create HLS.js instance', tag: 'HlsPlayer');
      return null;
    }
    return HlsPlayer._(hls);
  }

  /// Attaches the HLS.js player to a video element.
  void attachMedia(web.HTMLVideoElement video) {
    _hls.callMethod('attachMedia'.toJS, video);
    verboseLog('Media attached', tag: 'HlsPlayer');
  }

  /// Detaches the player from the video element.
  void detachMedia() {
    _hls.callMethod('detachMedia'.toJS);
    verboseLog('Media detached', tag: 'HlsPlayer');
  }

  /// Loads an HLS source URL.
  void loadSource(String url) {
    _hls.callMethod('loadSource'.toJS, url.toJS);
    verboseLog('Loading source: $url', tag: 'HlsPlayer');
  }

  /// Starts loading the stream.
  void startLoad([int startPosition = -1]) {
    _hls.callMethod('startLoad'.toJS, startPosition.toJS);
  }

  /// Stops loading the stream.
  void stopLoad() => _hls.callMethod('stopLoad'.toJS);

  /// Gets the current quality level index (-1 for auto).
  int get currentLevel => (_hls['currentLevel'] as JSNumber?)?.toDartInt ?? -1;

  /// Sets the current quality level index (-1 for auto).
  set currentLevel(int level) => _hls['currentLevel'] = level.toJS;

  /// Gets the next level to be loaded (-1 for auto).
  int get nextLevel => (_hls['nextLevel'] as JSNumber?)?.toDartInt ?? -1;

  /// Sets the next level to be loaded (-1 for auto).
  set nextLevel(int level) => _hls['nextLevel'] = level.toJS;

  /// Gets the auto level capping (-1 for no cap).
  int get autoLevelCapping => (_hls['autoLevelCapping'] as JSNumber?)?.toDartInt ?? -1;

  /// Sets the auto level capping (-1 for no cap).
  set autoLevelCapping(int level) => _hls['autoLevelCapping'] = level.toJS;

  /// Gets whether auto level selection is enabled.
  bool get autoLevelEnabled => (_hls['autoLevelEnabled'] as JSBoolean?)?.toDart ?? true;

  /// Gets the list of available quality levels.
  List<HlsLevel> get levels {
    final levelsJs = _hls['levels'] as JSArray?;
    if (levelsJs == null) return [];

    final result = <HlsLevel>[];
    final length = levelsJs.length;

    for (var i = 0; i < length; i++) {
      final levelJs = levelsJs[i] as JSObject?;
      if (levelJs != null) {
        result.add(HlsLevel._fromJs(levelJs, i));
      }
    }

    return result;
  }

  /// Gets the current audio track index.
  int get audioTrack => (_hls['audioTrack'] as JSNumber?)?.toDartInt ?? 0;

  /// Sets the current audio track index.
  set audioTrack(int index) => _hls['audioTrack'] = index.toJS;

  /// Gets the list of available audio tracks.
  List<HlsAudioTrack> get audioTracks {
    final tracksJs = _hls['audioTracks'] as JSArray?;
    if (tracksJs == null) return [];

    final result = <HlsAudioTrack>[];
    final length = tracksJs.length;

    for (var i = 0; i < length; i++) {
      final trackJs = tracksJs[i] as JSObject?;
      if (trackJs != null) {
        result.add(HlsAudioTrack._fromJs(trackJs, i));
      }
    }

    return result;
  }

  /// Gets the current subtitle track index (-1 for disabled).
  int get subtitleTrack => (_hls['subtitleTrack'] as JSNumber?)?.toDartInt ?? -1;

  /// Sets the current subtitle track index (-1 to disable).
  set subtitleTrack(int index) => _hls['subtitleTrack'] = index.toJS;

  /// Gets the list of available subtitle tracks.
  List<HlsSubtitleTrack> get subtitleTracks {
    final tracksJs = _hls['subtitleTracks'] as JSArray?;
    if (tracksJs == null) return [];

    final result = <HlsSubtitleTrack>[];
    final length = tracksJs.length;

    for (var i = 0; i < length; i++) {
      final trackJs = tracksJs[i] as JSObject?;
      if (trackJs != null) {
        result.add(HlsSubtitleTrack._fromJs(trackJs, i));
      }
    }

    return result;
  }

  /// Gets the estimated bandwidth in bits per second.
  double get bandwidthEstimate => (_hls['bandwidthEstimate'] as JSNumber?)?.toDartDouble ?? 0.0;

  /// Adds an event listener.
  void on(String event, void Function(String event, JSObject? data) callback) {
    _registeredEvents.add(event);
    final jsCallback = ((JSString eventName, JSObject? data) {
      callback(eventName.toDart, data);
    }).toJS;
    _hls.callMethod('on'.toJS, event.toJS, jsCallback);
  }

  /// Removes all event listeners.
  void offAll() {
    for (final event in _registeredEvents) {
      _hls.callMethod('off'.toJS, event.toJS);
    }
    _registeredEvents.clear();
  }

  /// Destroys the HLS.js instance and releases resources.
  void destroy() {
    offAll();
    _hls.callMethod('destroy'.toJS);
    verboseLog('HLS.js player destroyed', tag: 'HlsPlayer');
  }

  /// Recovers from a media error.
  void recoverMediaError() => _hls.callMethod('recoverMediaError'.toJS);

  /// Swaps the audio codec for error recovery.
  void swapAudioCodec() => _hls.callMethod('swapAudioCodec'.toJS);
}

/// Represents an HLS quality level.
class HlsLevel {
  HlsLevel._({
    required this.index,
    required this.bitrate,
    required this.width,
    required this.height,
    this.name,
    this.codecs,
  });

  factory HlsLevel._fromJs(JSObject js, int index) => HlsLevel._(
    index: index,
    bitrate: (js['bitrate'] as JSNumber?)?.toDartInt ?? 0,
    width: (js['width'] as JSNumber?)?.toDartInt ?? 0,
    height: (js['height'] as JSNumber?)?.toDartInt ?? 0,
    name: (js['name'] as JSString?)?.toDart,
    codecs: (js['codecs'] as JSString?)?.toDart,
  );

  /// The level index in the HLS manifest.
  final int index;

  /// The bitrate in bits per second.
  final int bitrate;

  /// The video width in pixels.
  final int width;

  /// The video height in pixels.
  final int height;

  /// Optional name from the manifest.
  final String? name;

  /// The codec string.
  final String? codecs;

  /// Returns a human-readable label for this quality level.
  String get label {
    if (name != null && name!.isNotEmpty) return name!;
    if (height > 0) return '${height}p';
    if (bitrate > 0) return '${(bitrate / 1000).round()} kbps';
    return 'Level $index';
  }

  @override
  String toString() => 'HlsLevel(index: $index, ${width}x$height, ${bitrate}bps)';
}

/// Represents an HLS audio track.
class HlsAudioTrack {
  HlsAudioTrack._({required this.index, this.id, this.name, this.lang, this.isDefault = false});

  factory HlsAudioTrack._fromJs(JSObject js, int index) => HlsAudioTrack._(
    index: index,
    id: (js['id'] as JSNumber?)?.toDartInt,
    name: (js['name'] as JSString?)?.toDart,
    lang: (js['lang'] as JSString?)?.toDart,
    isDefault: (js['default'] as JSBoolean?)?.toDart ?? false,
  );

  /// The track index in the list.
  final int index;

  /// The track ID from the manifest.
  final int? id;

  /// The track name.
  final String? name;

  /// The language code.
  final String? lang;

  /// Whether this is the default track.
  final bool isDefault;

  /// Returns a human-readable label for this audio track.
  String get label {
    if (name != null && name!.isNotEmpty) return name!;
    if (lang != null && lang!.isNotEmpty) return lang!;
    return 'Audio ${index + 1}';
  }

  @override
  String toString() => 'HlsAudioTrack(index: $index, name: $name, lang: $lang)';
}

/// Represents an HLS subtitle track.
class HlsSubtitleTrack {
  HlsSubtitleTrack._({required this.index, this.id, this.name, this.lang, this.isDefault = false, this.forced = false});

  factory HlsSubtitleTrack._fromJs(JSObject js, int index) => HlsSubtitleTrack._(
    index: index,
    id: (js['id'] as JSNumber?)?.toDartInt,
    name: (js['name'] as JSString?)?.toDart,
    lang: (js['lang'] as JSString?)?.toDart,
    isDefault: (js['default'] as JSBoolean?)?.toDart ?? false,
    forced: (js['forced'] as JSBoolean?)?.toDart ?? false,
  );

  /// The track index in the list.
  final int index;

  /// The track ID from the manifest.
  final int? id;

  /// The track name.
  final String? name;

  /// The language code.
  final String? lang;

  /// Whether this is the default track.
  final bool isDefault;

  /// Whether this is a forced track (for foreign language parts).
  final bool forced;

  /// Returns a human-readable label for this subtitle track.
  String get label {
    if (name != null && name!.isNotEmpty) return name!;
    if (lang != null && lang!.isNotEmpty) return lang!;
    return 'Subtitle ${index + 1}';
  }

  @override
  String toString() => 'HlsSubtitleTrack(index: $index, name: $name, lang: $lang)';
}

// Helper to convert Dart Map to JSObject
JSObject _mapToJsObject(Map<String, dynamic> map) {
  final obj = JSObject();
  for (final entry in map.entries) {
    obj[entry.key] = _dartToJs(entry.value);
  }
  return obj;
}

JSAny? _dartToJs(Object? value) {
  if (value == null) return null;
  if (value is bool) return value.toJS;
  if (value is int) return value.toJS;
  if (value is double) return value.toJS;
  if (value is String) return value.toJS;
  if (value is List) {
    final arr = <JSAny?>[];
    for (final item in value) {
      arr.add(_dartToJs(item));
    }
    return arr.toJS;
  }
  if (value is Map<String, dynamic>) {
    return _mapToJsObject(value);
  }
  return value.toString().toJS;
}
