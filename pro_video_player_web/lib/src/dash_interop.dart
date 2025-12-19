import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'abstractions/dash_player_interface.dart';
import 'verbose_logging.dart';

/// dash.js CDN URL - using a stable version.
const String dashJsCdnUrl = 'https://cdn.jsdelivr.net/npm/dashjs@4.7.4/dist/dash.all.min.js';

/// Checks if dash.js is loaded in the browser.
bool get isDashJsLoaded {
  try {
    final dashjs = globalContext['dashjs'];
    return dashjs != null && !dashjs.isUndefinedOrNull;
  } catch (_) {
    return false;
  }
}

/// Checks if the browser supports DASH playback via MSE (Media Source Extensions).
bool get isMseSupported {
  try {
    final mse = globalContext['MediaSource'];
    if (mse == null || mse.isUndefinedOrNull) return false;
    final isSupported = (mse as JSObject).callMethod('isTypeSupported'.toJS, 'video/mp4'.toJS) as JSBoolean?;
    return isSupported?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Checks if dash.js is supported in the current browser.
bool get isDashJsSupported => isDashJsLoaded && isMseSupported;

/// Loads dash.js from CDN dynamically.
///
/// Returns a Future that completes when the library is loaded.
/// If already loaded, completes immediately.
Future<bool> loadDashJs() async {
  if (isDashJsLoaded) {
    verboseLog('dash.js already loaded', tag: 'DashInterop');
    return true;
  }

  verboseLog('Loading dash.js from CDN...', tag: 'DashInterop');

  final completer = Completer<bool>();

  final script = web.HTMLScriptElement()
    ..src = dashJsCdnUrl
    ..type = 'text/javascript'
    ..onload = ((web.Event event) {
      verboseLog('dash.js loaded successfully', tag: 'DashInterop');
      completer.complete(true);
    }).toJS
    ..onerror = ((web.Event event) {
      verboseLog('Failed to load dash.js', tag: 'DashInterop');
      completer.complete(false);
    }).toJS;

  web.document.head?.appendChild(script);

  return completer.future;
}

/// Creates a new dash.js MediaPlayer instance dynamically.
JSObject? _createDashPlayer() {
  try {
    final dashjs = globalContext['dashjs'];
    if (dashjs == null || dashjs.isUndefinedOrNull) return null;

    // Call dashjs.MediaPlayer().create()
    final mediaPlayerFactory = (dashjs as JSObject).callMethod('MediaPlayer'.toJS) as JSObject?;
    if (mediaPlayerFactory == null) return null;

    final player = mediaPlayerFactory.callMethod('create'.toJS) as JSObject?;
    return player;
  } catch (e) {
    verboseLog('Failed to create dash.js player: $e', tag: 'DashInterop');
    return null;
  }
}

/// Parses a roles array from a DASH track JSObject.
///
/// Returns null if the array is null or empty, otherwise returns a list of role strings.
List<String>? _parseRolesFromJs(JSArray? rolesJs) {
  if (rolesJs == null) return null;

  final roles = <String>[];
  for (var i = 0; i < rolesJs.length; i++) {
    final role = rolesJs[i] as JSString?;
    if (role != null) {
      roles.add(role.toDart);
    }
  }

  return roles.isEmpty ? null : roles;
}

/// dash.js event constants.
///
/// These match the event names used by dash.js library.
class DashEvents {
  DashEvents._();

  /// Fired when the stream has been initialized.
  static const String streamInitialized = 'streamInitialized';

  /// Fired when playback metadata is loaded.
  static const String playbackMetaDataLoaded = 'playbackMetaDataLoaded';

  /// Fired when quality changes.
  static const String qualityChangeRendered = 'qualityChangeRendered';

  /// Fired when quality change is requested.
  static const String qualityChangeRequested = 'qualityChangeRequested';

  /// Fired when buffer state changes.
  static const String bufferStateChanged = 'bufferStateChanged';

  /// Fired when buffer level updated.
  static const String bufferLevelUpdated = 'bufferLevelUpdated';

  /// Fired when an error occurred.
  static const String error = 'error';

  /// Fired when playback started.
  static const String playbackStarted = 'playbackStarted';

  /// Fired when playback paused.
  static const String playbackPaused = 'playbackPaused';

  /// Fired when playback ended.
  static const String playbackEnded = 'playbackEnded';

  /// Fired when manifest is loaded.
  static const String manifestLoaded = 'manifestLoaded';

  /// Fired when tracks are added.
  static const String allTextTracksAdded = 'allTextTracksAdded';

  /// Fired when period switch completed.
  static const String periodSwitchCompleted = 'periodSwitchCompleted';

  /// Fired when adaptation set switch is completed.
  static const String adaptationSetRemovedNoCapabilities = 'adaptationSetRemovedNoCapabilities';
}

/// Wrapper for dash.js MediaPlayer instance providing Dart-friendly API.
///
/// Implements [DashPlayerInterface] for type-safe usage in managers.
/// Uses dynamic JS access since dash.js is loaded at runtime from CDN.
class DashPlayer implements DashPlayerInterface {
  DashPlayer._(this._player);

  final JSObject _player;
  final List<_EventRegistration> _registeredEvents = [];

  /// Creates a new dash.js player instance.
  ///
  /// Returns null if dash.js is not loaded or not supported.
  static DashPlayer? create() {
    if (!isDashJsLoaded) {
      verboseLog('dash.js not loaded, cannot create player', tag: 'DashPlayer');
      return null;
    }

    final player = _createDashPlayer();
    if (player == null) {
      verboseLog('Failed to create dash.js instance', tag: 'DashPlayer');
      return null;
    }
    return DashPlayer._(player);
  }

  @override
  void initialize({required Object view, required String url, bool autoPlay = false}) {
    _player
      ..callMethod('initialize'.toJS, view as web.HTMLVideoElement, url.toJS, autoPlay.toJS)
      ..callMethod('updateSettings'.toJS, _createSettings());
    verboseLog('dash.js initialized with URL: $url', tag: 'DashPlayer');
  }

  /// Creates default settings for dash.js.
  JSObject _createSettings() {
    final settings = JSObject();
    final streaming = JSObject()..['abr'] = _createAbrSettings();
    settings['streaming'] = streaming;
    return settings;
  }

  /// Creates ABR settings.
  JSObject _createAbrSettings() {
    final abr = JSObject()
      ..['autoSwitchBitrate'] = _createAutoSwitchSettings()
      ..['limitBitrateByPortal'] = false.toJS;
    return abr;
  }

  /// Creates auto-switch settings for video and audio.
  JSObject _createAutoSwitchSettings() {
    final autoSwitch = JSObject()
      ..['video'] = true.toJS
      ..['audio'] = true.toJS;
    return autoSwitch;
  }

  @override
  void attachView(Object view) {
    _player.callMethod('attachView'.toJS, view as web.HTMLVideoElement);
    verboseLog('View attached', tag: 'DashPlayer');
  }

  @override
  void attachSource(String url) {
    _player.callMethod('attachSource'.toJS, url.toJS);
    verboseLog('Source attached: $url', tag: 'DashPlayer');
  }

  @override
  List<DashBitrateInfo> getVideoBitrateInfoList() => _getBitrateInfoListFor('video');

  @override
  List<DashBitrateInfo> getAudioBitrateInfoList() => _getBitrateInfoListFor('audio');

  List<DashBitrateInfo> _getBitrateInfoListFor(String type) {
    try {
      final list = _player.callMethod('getBitrateInfoListFor'.toJS, type.toJS) as JSArray?;
      if (list == null) return [];

      final result = <DashBitrateInfo>[];
      final length = list.length;

      for (var i = 0; i < length; i++) {
        final info = list[i] as JSObject?;
        if (info != null) {
          result.add(DashBitrateInfo._fromJs(info, i));
        }
      }

      return result;
    } catch (e) {
      verboseLog('Failed to get $type bitrate list: $e', tag: 'DashPlayer');
      return [];
    }
  }

  @override
  int getQualityFor(String type) {
    try {
      final quality = _player.callMethod('getQualityFor'.toJS, type.toJS) as JSNumber?;
      return quality?.toDartInt ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  void setQualityFor(String type, int quality) {
    _player.callMethod('setQualityFor'.toJS, type.toJS, quality.toJS);
    verboseLog('Set $type quality to $quality', tag: 'DashPlayer');
  }

  @override
  void setAutoSwitchQualityFor(String type, {required bool enabled}) {
    try {
      final settings = JSObject();
      final streaming = JSObject();
      final abr = JSObject();
      final autoSwitch = JSObject()..['video'] = enabled.toJS;
      abr['autoSwitchBitrate'] = autoSwitch;
      streaming['abr'] = abr;
      settings['streaming'] = streaming;
      _player.callMethod('updateSettings'.toJS, settings);
      verboseLog('Set auto-switch for $type to $enabled', tag: 'DashPlayer');
    } catch (e) {
      verboseLog('Failed to set auto-switch: $e', tag: 'DashPlayer');
    }
  }

  @override
  void updateSettings(Map<String, dynamic> settings) {
    try {
      final jsSettings = _convertToJSObject(settings);
      _player.callMethod('updateSettings'.toJS, jsSettings);
      verboseLog('Updated settings: $settings', tag: 'DashPlayer');
    } catch (e) {
      verboseLog('Failed to update settings: $e', tag: 'DashPlayer');
    }
  }

  JSObject _convertToJSObject(Map<String, dynamic> map) {
    final result = JSObject();
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        result[entry.key] = _convertToJSObject(value);
      } else if (value is int) {
        result[entry.key] = value.toJS;
      } else if (value is double) {
        result[entry.key] = value.toJS;
      } else if (value is bool) {
        result[entry.key] = value.toJS;
      } else if (value is String) {
        result[entry.key] = value.toJS;
      } else if (value != null) {
        result[entry.key] = (value as Object).jsify();
      }
    }
    return result;
  }

  @override
  bool getAutoSwitchQualityFor(String type) {
    try {
      final settings = _player.callMethod('getSettings'.toJS) as JSObject?;
      if (settings == null) return true;
      final streaming = settings['streaming'] as JSObject?;
      if (streaming == null) return true;
      final abr = streaming['abr'] as JSObject?;
      if (abr == null) return true;
      final autoSwitch = abr['autoSwitchBitrate'] as JSObject?;
      if (autoSwitch == null) return true;
      final value = autoSwitch[type] as JSBoolean?;
      return value?.toDart ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  List<DashTextTrack> getTextTracks() {
    try {
      final tracks = _player.callMethod('getTracksFor'.toJS, 'text'.toJS) as JSArray?;
      if (tracks == null) return [];

      final result = <DashTextTrack>[];
      final length = tracks.length;

      for (var i = 0; i < length; i++) {
        final track = tracks[i] as JSObject?;
        if (track != null) {
          result.add(DashTextTrack._fromJs(track, i));
        }
      }

      return result;
    } catch (e) {
      verboseLog('Failed to get text tracks: $e', tag: 'DashPlayer');
      return [];
    }
  }

  @override
  void setTextTrack(int index) {
    try {
      final tracks = _player.callMethod('getTracksFor'.toJS, 'text'.toJS) as JSArray?;
      if (tracks != null && index >= 0 && index < tracks.length) {
        _player.callMethod('setCurrentTrack'.toJS, tracks[index]);
        verboseLog('Set text track to index $index', tag: 'DashPlayer');
      }
    } catch (e) {
      verboseLog('Failed to set text track: $e', tag: 'DashPlayer');
    }
  }

  @override
  void setTextTrackVisibility({required bool visible}) {
    _player.callMethod('enableText'.toJS, visible.toJS);
    verboseLog('Text track visibility: $visible', tag: 'DashPlayer');
  }

  @override
  List<DashAudioTrack> getAudioTracks() {
    try {
      final tracks = _player.callMethod('getTracksFor'.toJS, 'audio'.toJS) as JSArray?;
      if (tracks == null) return [];

      final result = <DashAudioTrack>[];
      final length = tracks.length;

      for (var i = 0; i < length; i++) {
        final track = tracks[i] as JSObject?;
        if (track != null) {
          result.add(DashAudioTrack._fromJs(track, i));
        }
      }

      return result;
    } catch (e) {
      verboseLog('Failed to get audio tracks: $e', tag: 'DashPlayer');
      return [];
    }
  }

  @override
  void setAudioTrack(int index) {
    try {
      final tracks = _player.callMethod('getTracksFor'.toJS, 'audio'.toJS) as JSArray?;
      if (tracks != null && index >= 0 && index < tracks.length) {
        _player.callMethod('setCurrentTrack'.toJS, tracks[index]);
        verboseLog('Set audio track to index $index', tag: 'DashPlayer');
      }
    } catch (e) {
      verboseLog('Failed to set audio track: $e', tag: 'DashPlayer');
    }
  }

  @override
  double getAverageThroughput() {
    try {
      final throughput = _player.callMethod('getAverageThroughput'.toJS, 'video'.toJS) as JSNumber?;
      return throughput?.toDartDouble ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  void on(String event, void Function(Object? data) callback) {
    final jsCallback = ((JSObject? data) {
      callback(data);
    }).toJS;
    _registeredEvents.add(_EventRegistration(event, jsCallback));
    _player.callMethod('on'.toJS, event.toJS, jsCallback);
  }

  @override
  void offAll() {
    for (final reg in _registeredEvents) {
      _player.callMethod('off'.toJS, reg.event.toJS, reg.callback);
    }
    _registeredEvents.clear();
  }

  @override
  void reset() {
    _player.callMethod('reset'.toJS);
    verboseLog('dash.js player reset', tag: 'DashPlayer');
  }

  @override
  void destroy() {
    offAll();
    _player.callMethod('destroy'.toJS);
    verboseLog('dash.js player destroyed', tag: 'DashPlayer');
  }
}

/// Helper class to store event registrations.
class _EventRegistration {
  _EventRegistration(this.event, this.callback);
  final String event;
  final JSFunction callback;
}

/// Represents a DASH bitrate/quality info.
class DashBitrateInfo implements DashBitrateInfoInterface {
  DashBitrateInfo._({
    required this.index,
    required this.bitrate,
    required this.width,
    required this.height,
    this.mediaType,
  });

  factory DashBitrateInfo._fromJs(JSObject js, int index) => DashBitrateInfo._(
    index: index,
    bitrate: (js['bitrate'] as JSNumber?)?.toDartInt ?? 0,
    width: (js['width'] as JSNumber?)?.toDartInt ?? 0,
    height: (js['height'] as JSNumber?)?.toDartInt ?? 0,
    mediaType: (js['mediaType'] as JSString?)?.toDart,
  );

  @override
  final int index;

  @override
  final int bitrate;

  @override
  final int width;

  @override
  final int height;

  @override
  final String? mediaType;

  @override
  String get label {
    if (height > 0) return '${height}p';
    if (bitrate > 0) return '${(bitrate / 1000).round()} kbps';
    return 'Quality $index';
  }

  @override
  String toString() => 'DashBitrateInfo(index: $index, ${width}x$height, ${bitrate}bps)';
}

/// Represents a DASH text/subtitle track.
class DashTextTrack implements DashTextTrackInterface {
  DashTextTrack._({required this.index, this.id, this.lang, this.roles, this.isDefault = false});

  factory DashTextTrack._fromJs(JSObject js, int index) => DashTextTrack._(
    index: index,
    id: (js['id'] as JSString?)?.toDart,
    lang: (js['lang'] as JSString?)?.toDart,
    roles: _parseRolesFromJs(js['roles'] as JSArray?),
    isDefault: (js['isDefault'] as JSBoolean?)?.toDart ?? false,
  );

  @override
  final int index;

  @override
  final String? id;

  @override
  final String? lang;

  @override
  final List<String>? roles;

  @override
  final bool isDefault;

  @override
  String get label {
    if (lang != null && lang!.isNotEmpty) return lang!;
    return 'Subtitle ${index + 1}';
  }

  @override
  String toString() => 'DashTextTrack(index: $index, lang: $lang)';
}

/// Represents a DASH audio track.
class DashAudioTrack implements DashAudioTrackInterface {
  DashAudioTrack._({required this.index, this.id, this.lang, this.roles, this.isDefault = false});

  factory DashAudioTrack._fromJs(JSObject js, int index) => DashAudioTrack._(
    index: index,
    id: (js['id'] as JSString?)?.toDart,
    lang: (js['lang'] as JSString?)?.toDart,
    roles: _parseRolesFromJs(js['roles'] as JSArray?),
    isDefault: (js['isDefault'] as JSBoolean?)?.toDart ?? false,
  );

  @override
  final int index;

  @override
  final String? id;

  @override
  final String? lang;

  @override
  final List<String>? roles;

  @override
  final bool isDefault;

  @override
  String get label {
    if (lang != null && lang!.isNotEmpty) return lang!;
    return 'Audio ${index + 1}';
  }

  @override
  String toString() => 'DashAudioTrack(index: $index, lang: $lang)';
}
