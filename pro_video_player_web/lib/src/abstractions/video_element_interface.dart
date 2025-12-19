import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Interface for Remote Playback API.
///
/// Abstracts the RemotePlayback object to allow for testing without actual
/// browser APIs. Provides access to remote playback state and methods.
abstract interface class RemotePlaybackInterface {
  /// Current state of the remote playback connection.
  ///
  /// Values: 'disconnected', 'connecting', 'connected'
  String? get state;

  /// Prompts the user to select a remote playback device.
  ///
  /// Shows the browser's device picker dialog. Returns a Future that completes
  /// when a device is selected or the user cancels.
  Future<void> prompt();

  /// Adds an event listener for remote playback events.
  ///
  /// Supported events: 'connecting', 'connect', 'disconnect'
  void addEventListener(String event, void Function(Object? event) callback);
}

/// Interface for HTML Video Element.
///
/// Abstracts the HTMLVideoElement to allow for testing without actual browser
/// APIs. Provides access to video playback properties and methods.
///
/// This interface includes all properties that managers access when casting
/// to dynamic, enabling type-safe testing with mocks while supporting real
/// HTMLVideoElement in production.
abstract interface class VideoElementInterface {
  /// Current playback time in seconds.
  double get currentTime;
  set currentTime(double value);

  /// Initiates playback of the video.
  ///
  /// Returns a Future that completes when playback starts.
  Future<void> play();

  // Additional properties accessed by managers via dynamic casting
  // These are implemented by BrowserVideoElement to forward to the real element

  /// Video source URL.
  dynamic get src;
  set src(Object? value);

  /// Video duration in seconds.
  dynamic get duration;

  /// Whether video is paused.
  dynamic get paused;

  /// Whether video has ended.
  dynamic get ended;

  /// Playback volume (0.0 to 1.0).
  dynamic get volume;
  set volume(Object? value);

  /// Playback rate/speed.
  dynamic get playbackRate;
  set playbackRate(Object? value);

  /// Whether video is muted.
  dynamic get muted;
  set muted(Object? value);

  /// Whether video should loop.
  dynamic get loop;
  set loop(Object? value);

  /// Video width in pixels.
  dynamic get videoWidth;

  /// Video height in pixels.
  dynamic get videoHeight;

  /// Ready state (0-4).
  dynamic get readyState;

  /// Network state (0-3).
  dynamic get networkState;

  /// Buffered time ranges.
  dynamic get buffered;

  /// Preload setting.
  dynamic get preload;
  set preload(Object? value);

  /// Video controls visibility.
  dynamic get controls;
  set controls(Object? value);

  /// Load the video.
  dynamic load();

  /// Pause the video.
  dynamic pause();

  /// Audio tracks list (for multi-audio track support).
  ///
  /// Returns null if AudioTrackList API is not supported (most browsers).
  /// Safari supports this API. For HLS/DASH, managers use HLS.js/DASH.js APIs instead.
  List<dynamic>? get mockAudioTracks;

  /// Text tracks list (for subtitles/captions).
  ///
  /// Returns TextTrackList containing all text tracks (subtitles, captions, etc).
  /// Managers use this for native HTML5 subtitle support.
  List<dynamic>? get mockTextTracks;

  /// Remote playback interface (for casting).
  ///
  /// Returns the Remote Playback API object if supported by the browser,
  /// or null if not available.
  RemotePlaybackInterface? get remotePlayback;

  /// Adds an event listener to the video element.
  ///
  /// Used for listening to media events like 'canplay', 'ended', etc.
  void addEventListener(String event, void Function(Object? event) callback);
}

/// Browser implementation of [VideoElementInterface].
///
/// Wraps a real HTMLVideoElement and forwards all property/method access.
/// Implements all properties that managers access to avoid noSuchMethod overhead.
class BrowserVideoElement implements VideoElementInterface {
  /// Creates a browser video element wrapper.
  BrowserVideoElement(this._element);

  final web.HTMLVideoElement _element;

  @override
  double get currentTime => _element.currentTime;

  @override
  set currentTime(double value) => _element.currentTime = value;

  @override
  Future<void> play() => _element.play().toDart.then((_) {});

  @override
  dynamic get src => _element.src;

  @override
  set src(Object? value) => _element.src = value! as String;

  @override
  dynamic get duration => _element.duration;

  @override
  dynamic get paused => _element.paused;

  @override
  dynamic get ended => _element.ended;

  @override
  dynamic get volume => _element.volume;

  @override
  set volume(Object? value) => _element.volume = value! as double;

  @override
  dynamic get playbackRate => _element.playbackRate;

  @override
  set playbackRate(Object? value) => _element.playbackRate = value! as double;

  @override
  dynamic get muted => _element.muted;

  @override
  set muted(Object? value) => _element.muted = value! as bool;

  @override
  dynamic get loop => _element.loop;

  @override
  set loop(Object? value) => _element.loop = value! as bool;

  @override
  dynamic get videoWidth => _element.videoWidth;

  @override
  dynamic get videoHeight => _element.videoHeight;

  @override
  dynamic get readyState => _element.readyState;

  @override
  dynamic get networkState => _element.networkState;

  @override
  dynamic get buffered => _element.buffered;

  @override
  dynamic get preload => _element.preload;

  @override
  set preload(Object? value) => _element.preload = value! as String;

  @override
  dynamic get controls => _element.controls;

  @override
  set controls(Object? value) => _element.controls = value! as bool;

  @override
  dynamic load() => _element.load();

  @override
  dynamic pause() => _element.pause();

  @override
  List<dynamic>? get mockAudioTracks {
    // AudioTrackList is only supported in Safari
    // Returns null for other browsers
    try {
      final tracks = _element.audioTracks;
      if (tracks.length == 0) return null;

      // Convert AudioTrackList to List for consistent interface
      final trackList = <dynamic>[];
      for (var i = 0; i < tracks.length; i++) {
        trackList.add(tracks[i]);
      }
      return trackList;
    } catch (_) {
      return null;
    }
  }

  @override
  List<dynamic>? get mockTextTracks {
    try {
      final tracks = _element.textTracks;
      if (tracks.length == 0) return null;

      // Convert TextTrackList to List for consistent interface
      final trackList = <dynamic>[];
      for (var i = 0; i < tracks.length; i++) {
        trackList.add((tracks as dynamic)[i]);
      }
      return trackList;
    } catch (_) {
      return null;
    }
  }

  @override
  RemotePlaybackInterface? get remotePlayback {
    try {
      // Check if Remote Playback API is available
      // The Remote Playback API is not fully typed in the web package,
      // so we access it via dynamic interop
      // ignore: avoid_dynamic_calls
      final remote = (_element as dynamic).remote;
      if (remote == null) return null;
      return _BrowserRemotePlayback(remote as web.EventTarget);
    } catch (_) {
      return null;
    }
  }

  @override
  void addEventListener(String event, void Function(Object? event) callback) {
    _element.addEventListener(
      event,
      (web.Event e) {
        callback(e);
      }.toJS,
    );
  }
}

/// Browser implementation of [RemotePlaybackInterface].
///
/// This class wraps the browser's RemotePlayback API which is accessed
/// via dynamic interop since it's not fully typed in the web package.
class _BrowserRemotePlayback implements RemotePlaybackInterface {
  _BrowserRemotePlayback(this._remote);

  final web.EventTarget _remote;

  @override
  String? get state {
    try {
      // ignore: avoid_dynamic_calls
      return (_remote as dynamic).state as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> prompt() async {
    try {
      // ignore: avoid_dynamic_calls
      final result = (_remote as dynamic).prompt();
      if (result != null) {
        await (result as JSPromise).toDart;
      }
    } catch (_) {
      rethrow;
    }
  }

  @override
  void addEventListener(String event, void Function(Object? event) callback) {
    _remote.addEventListener(
      event,
      (web.Event e) {
        callback(e);
      }.toJS,
    );
  }
}
