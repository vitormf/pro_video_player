import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:web/web.dart' as web;

import 'src/battery_interop.dart' as battery_interop;
import 'src/verbose_logging.dart';
import 'src/web_video_player.dart';

/// The web implementation of [ProVideoPlayerPlatform].
///
/// This class uses HTML5 VideoElement for video playback on web.
class ProVideoPlayerWeb extends ProVideoPlayerPlatform {
  /// Constructs a ProVideoPlayerWeb.
  ProVideoPlayerWeb();

  /// Registers this class as the default instance of [ProVideoPlayerPlatform].
  static void registerWith(Registrar registrar) {
    ProVideoPlayerPlatform.instance = ProVideoPlayerWeb();
  }

  final Map<int, WebVideoPlayer> _players = {};
  int _nextPlayerId = 0;

  // Battery updates stream controller
  StreamController<BatteryInfo>? _batteryUpdatesController;
  void Function()? _batteryCleanup;

  @override
  Future<int> create({required VideoSource source, VideoPlayerOptions options = const VideoPlayerOptions()}) async {
    verboseLog('create() called with source: ${source.runtimeType}', tag: 'Plugin');
    final playerId = _nextPlayerId++;
    final player = WebVideoPlayer(playerId, source, options);
    _players[playerId] = player;
    await player.initialize();
    verboseLog('Player created with ID: $playerId', tag: 'Plugin');
    return playerId;
  }

  @override
  Future<void> dispose(int playerId) async {
    verboseLog('dispose() called for playerId: $playerId', tag: 'Plugin');
    final player = _players.remove(playerId);
    player?.dispose();
  }

  @override
  Future<void> play(int playerId) async {
    verboseLog('play() called for playerId: $playerId', tag: 'Plugin');
    final player = _getPlayer(playerId);
    await player.play();
  }

  @override
  Future<void> pause(int playerId) async {
    verboseLog('pause() called for playerId: $playerId', tag: 'Plugin');
    await _getPlayer(playerId).pause();
  }

  @override
  Future<void> stop(int playerId) async {
    verboseLog('stop() called for playerId: $playerId', tag: 'Plugin');
    await _getPlayer(playerId).stop();
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    verboseLog('seekTo() called for playerId: $playerId, position: $position', tag: 'Plugin');
    if (position.isNegative) {
      throw ArgumentError('Position must be non-negative');
    }
    _getPlayer(playerId).seekTo(position);
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    if (speed <= 0.0 || speed > 10.0) {
      throw ArgumentError('Playback speed must be between 0.0 (exclusive) and 10.0');
    }
    _getPlayer(playerId).setPlaybackSpeed(speed);
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError('Volume must be between 0.0 and 1.0');
    }
    _getPlayer(playerId).setVolume(volume);
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async => _getPlayer(playerId).looping = looping;

  @override
  Future<void> setScalingMode(int playerId, VideoScalingMode mode) async => _getPlayer(playerId).setScalingMode(mode);

  @override
  Future<void> setSubtitleRenderMode(int playerId, SubtitleRenderMode mode) async =>
      _getPlayer(playerId).setSubtitleRenderMode(mode.name);

  @override
  Future<void> setSubtitleTrack(int playerId, SubtitleTrack? track) async =>
      _getPlayer(playerId).setSubtitleTrack(track);

  @override
  Future<void> setAudioTrack(int playerId, AudioTrack? track) async => _getPlayer(playerId).setAudioTrack(track);

  @override
  Future<Duration> getPosition(int playerId) async {
    final player = _getPlayer(playerId);
    return player.getPosition();
  }

  @override
  Future<Duration> getDuration(int playerId) async {
    final player = _getPlayer(playerId);
    return player.getDuration();
  }

  @override
  Future<bool> enterPip(int playerId, {PipOptions options = const PipOptions()}) async {
    final player = _getPlayer(playerId);
    return player.enterPip();
  }

  @override
  Future<void> exitPip(int playerId) async {
    final player = _getPlayer(playerId);
    await player.exitPip();
  }

  @override
  Future<bool> isPipSupported() async => WebVideoPlayer.isPipSupported();

  @override
  Future<bool> enterFullscreen(int playerId) async {
    final player = _getPlayer(playerId);
    return player.enterFullscreen();
  }

  @override
  Future<void> exitFullscreen(int playerId) async {
    final player = _getPlayer(playerId);
    await player.exitFullscreen();
  }

  @override
  Stream<VideoPlayerEvent> events(int playerId) {
    final player = _players[playerId];
    if (player == null) {
      throw StateError('Player $playerId has not been created');
    }
    return player.events;
  }

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) {
    final player = _getPlayer(playerId);
    return HtmlElementView(viewType: player.viewType);
  }

  @override
  Future<void> setVerboseLogging({required bool enabled}) async {
    isVerboseLoggingEnabled = enabled;
    verboseLog('Verbose logging ${enabled ? "enabled" : "disabled"}', tag: 'Plugin');
  }

  @override
  Future<PlatformInfo> getPlatformInfo() async {
    verboseLog('Getting platform info', tag: 'Plugin');

    final supportsPip = _checkPictureInPictureSupport();
    final supportsFullscreen = _checkFullscreenSupport();
    final supportsRemotePlayback = _checkRemotePlaybackSupport();
    final supportsMediaSession = _checkMediaSessionSupport();

    return PlatformInfo(
      platformName: 'Web',
      nativePlayerType: 'HTML5',
      additionalInfo: {
        'userAgent': web.window.navigator.userAgent,
        'pipAvailable': supportsPip,
        'fullscreenAvailable': supportsFullscreen,
        'remotePlaybackAvailable': supportsRemotePlayback,
        'mediaSessionAvailable': supportsMediaSession,
      },
    );
  }

  @override
  Future<bool> supportsPictureInPicture() async {
    return _checkPictureInPictureSupport();
  }

  @override
  Future<bool> supportsFullscreen() async {
    return _checkFullscreenSupport();
  }

  @override
  Future<bool> supportsBackgroundPlayback() async {
    return false; // Web doesn't support background playback
  }

  @override
  Future<bool> supportsCasting() async {
    return _checkRemotePlaybackSupport(); // Remote Playback API for casting
  }

  @override
  Future<bool> supportsAirPlay() async {
    return false; // AirPlay is iOS/macOS only
  }

  @override
  Future<bool> supportsChromecast() async {
    return false; // Chromecast is Android only (web uses Remote Playback API)
  }

  @override
  Future<bool> supportsRemotePlayback() async {
    return _checkRemotePlaybackSupport(); // Browser Remote Playback API
  }

  @override
  Future<bool> supportsQualitySelection() async {
    return true; // Web supports quality selection with HLS/DASH libraries
  }

  @override
  Future<bool> supportsPlaybackSpeedControl() async {
    return true; // HTML5 video supports playback rate
  }

  @override
  Future<bool> supportsSubtitles() async {
    return true; // HTML5 video has TextTrack support
  }

  @override
  Future<bool> supportsExternalSubtitles() async {
    return true; // Can add TextTrack programmatically
  }

  @override
  Future<bool> supportsAudioTrackSelection() async {
    return true; // HTML5 video has AudioTrack support
  }

  @override
  Future<bool> supportsChapters() async {
    return false; // Limited chapter support on web
  }

  @override
  Future<bool> supportsVideoMetadataExtraction() async {
    return true; // Can extract metadata from video element
  }

  @override
  Future<bool> supportsNetworkMonitoring() async {
    return true; // Navigator.connection API
  }

  @override
  Future<bool> supportsBandwidthEstimation() async {
    return false; // Limited bandwidth estimation on web
  }

  @override
  Future<bool> supportsAdaptiveBitrate() async {
    return true; // HLS.js and dash.js support ABR
  }

  @override
  Future<bool> supportsHLS() async {
    return true; // HLS.js library support
  }

  @override
  Future<bool> supportsDASH() async {
    return true; // dash.js library support
  }

  @override
  Future<bool> supportsDeviceVolumeControl() async {
    return false; // Web cannot control device volume
  }

  @override
  Future<bool> supportsScreenBrightnessControl() async {
    return false; // Web cannot control screen brightness
  }

  bool _checkPictureInPictureSupport() {
    try {
      // Check if document.pictureInPictureEnabled exists
      return web.document.pictureInPictureEnabled;
    } catch (e) {
      return false;
    }
  }

  bool _checkFullscreenSupport() {
    try {
      // Check if document.fullscreenEnabled exists
      return web.document.fullscreenEnabled;
    } catch (e) {
      return false;
    }
  }

  bool _checkRemotePlaybackSupport() {
    try {
      // Check if HTMLVideoElement has remote property
      // Note: Remote property may not be available in all browsers
      // We'll do a basic check by trying to create a video element
      final video = web.document.createElement('video') as web.HTMLVideoElement;
      // If we can create the video element, we assume basic support
      // Full remote playback API support is browser-dependent
      return video.readyState >= 0; // Basic check that video element works
    } catch (e) {
      return false;
    }
  }

  bool _checkMediaSessionSupport() {
    try {
      // Check if navigator.mediaSession exists
      // MediaSession is available on most modern browsers
      // MediaSession is a non-nullable type in the web package, so if we can access it, it exists
      web.window.navigator.mediaSession;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> setMediaMetadata(int playerId, MediaMetadata metadata) async {
    verboseLog('setMediaMetadata() called for playerId: $playerId', tag: 'Plugin');
    _getPlayer(playerId).setMediaMetadata(metadata);
  }

  @override
  Future<List<VideoQualityTrack>> getVideoQualities(int playerId) async => _getPlayer(playerId).getVideoQualities();

  @override
  Future<bool> setVideoQuality(int playerId, VideoQualityTrack track) async =>
      _getPlayer(playerId).setVideoQuality(track);

  @override
  Future<VideoQualityTrack> getCurrentVideoQuality(int playerId) async => _getPlayer(playerId).getCurrentVideoQuality();

  @override
  Future<bool> isQualitySelectionSupported(int playerId) async => _getPlayer(playerId).isQualitySelectionSupported();

  @override
  Future<bool> setBackgroundPlayback(int playerId, {required bool enabled}) async =>
      // Web doesn't have a concept of background playback like mobile platforms
      // Browsers handle audio playback in background tabs automatically
      false;

  @override
  Future<bool> isBackgroundPlaybackSupported() async =>
      // Background playback isn't configurable on web in the same way
      // Browsers may pause video in background tabs based on their own policies
      false;

  @override
  Future<VideoMetadata?> getVideoMetadata(int playerId) async => _getPlayer(playerId).getVideoMetadata();

  @override
  Future<ExternalSubtitleTrack?> addExternalSubtitle(int playerId, SubtitleSource source) async {
    verboseLog('addExternalSubtitle() called for playerId: $playerId, source: ${source.path}', tag: 'Plugin');
    return _getPlayer(playerId).addExternalSubtitle(source);
  }

  @override
  Future<bool> removeExternalSubtitle(int playerId, String trackId) async {
    verboseLog('removeExternalSubtitle() called for playerId: $playerId, trackId: $trackId', tag: 'Plugin');
    return _getPlayer(playerId).removeExternalSubtitle(trackId);
  }

  @override
  Future<List<ExternalSubtitleTrack>> getExternalSubtitles(int playerId) async =>
      _getPlayer(playerId).getExternalSubtitles();

  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    verboseLog('getBatteryInfo() called', tag: 'Plugin');
    final batteryData = await battery_interop.getBatteryInfo(web.window.navigator);
    if (batteryData == null) return null;
    return BatteryInfo(percentage: batteryData['percentage'] as int, isCharging: batteryData['isCharging'] as bool);
  }

  @override
  Stream<BatteryInfo> get batteryUpdates {
    _batteryUpdatesController ??= StreamController<BatteryInfo>.broadcast(
      onListen: () async {
        verboseLog('Battery updates stream listener added', tag: 'Plugin');
        // Send initial battery state
        final initialBattery = await getBatteryInfo();
        if (initialBattery != null) {
          _batteryUpdatesController?.add(initialBattery);
        }

        // Set up battery event listeners
        _batteryCleanup = await battery_interop.setupBatteryListeners(web.window.navigator, (batteryData) {
          final batteryInfo = BatteryInfo(
            percentage: batteryData['percentage'] as int,
            isCharging: batteryData['isCharging'] as bool,
          );
          _batteryUpdatesController?.add(batteryInfo);
        });
      },
      onCancel: () {
        verboseLog('Battery updates stream listener cancelled', tag: 'Plugin');
        _batteryCleanup?.call();
        _batteryCleanup = null;
      },
    );
    return _batteryUpdatesController!.stream;
  }

  @override
  Future<bool> isCastingSupported() async {
    // Check if any player can support casting (they all use the same API)
    // Or check the browser's general support
    if (_players.isEmpty) {
      // No players yet, but we can still check if Remote Playback API exists
      // This is a best-effort check - actual support is checked per-player
      return true; // Assume supported, will be validated when player is created
    }
    return _players.values.first.isCastingSupported();
  }

  @override
  Future<List<CastDevice>> getAvailableCastDevices(int playerId) async {
    verboseLog('getAvailableCastDevices() called for playerId: $playerId', tag: 'Plugin');
    return _getPlayer(playerId).getAvailableCastDevices();
  }

  @override
  Future<bool> startCasting(int playerId, {CastDevice? device}) async {
    verboseLog(
      'startCasting() called for playerId: $playerId, device: ${device?.name ?? 'show picker'}',
      tag: 'Plugin',
    );
    return _getPlayer(playerId).startCasting(device: device);
  }

  @override
  Future<bool> stopCasting(int playerId) async {
    verboseLog('stopCasting() called for playerId: $playerId', tag: 'Plugin');
    return _getPlayer(playerId).stopCasting();
  }

  @override
  Future<CastState> getCastState(int playerId) async {
    verboseLog('getCastState() called for playerId: $playerId', tag: 'Plugin');
    return _getPlayer(playerId).getCastState();
  }

  @override
  Future<CastDevice?> getCurrentCastDevice(int playerId) async {
    verboseLog('getCurrentCastDevice() called for playerId: $playerId', tag: 'Plugin');
    return _getPlayer(playerId).getCurrentCastDevice();
  }

  WebVideoPlayer _getPlayer(int playerId) {
    final player = _players[playerId];
    if (player == null) {
      throw StateError('Player $playerId has not been created');
    }
    return player;
  }
}
