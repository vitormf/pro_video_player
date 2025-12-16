import 'dart:async';

import 'pigeon_generated/messages.g.dart';
import 'pro_video_player_logger.dart';
import 'pro_video_player_platform.dart';
import 'types/types.dart';

/// Base class for platform implementations using Pigeon-generated type-safe APIs.
///
/// This class provides complete type-safe platform channel communication using
/// Pigeon-generated code for all platform methods and events.
abstract class PigeonMethodChannelBase extends ProVideoPlayerPlatform {
  /// Creates a [PigeonMethodChannelBase] with the given [channelPrefix].
  PigeonMethodChannelBase(this.channelPrefix) : _hostApi = ProVideoPlayerHostApi(), _eventStreamControllers = {};

  /// The channel prefix used for method and event channels.
  final String channelPrefix;

  /// The Pigeon-generated host API for type-safe communication.
  final ProVideoPlayerHostApi _hostApi;

  /// Event stream controllers for each player.
  final Map<int, StreamController<VideoPlayerEvent>> _eventStreamControllers;

  // ==================== Core Player Methods ====================

  @override
  Future<int> create({required VideoSource source, VideoPlayerOptions options = const VideoPlayerOptions()}) async {
    ProVideoPlayerLogger.log('Creating player with source: ${source.runtimeType}', tag: 'PigeonMethodChannel');

    final sourceMessage = _convertVideoSource(source);
    final optionsMessage = _convertOptions(options);

    final playerId = await _hostApi.create(sourceMessage, optionsMessage);

    ProVideoPlayerLogger.log('Player created with ID: $playerId', tag: 'PigeonMethodChannel');

    return playerId;
  }

  @override
  Future<void> dispose(int playerId) async {
    ProVideoPlayerLogger.log('Disposing player: $playerId', tag: 'PigeonMethodChannel');
    await _hostApi.dispose(playerId);
    // Clean up event stream controller
    await _eventStreamControllers[playerId]?.close();
    _eventStreamControllers.remove(playerId);
  }

  @override
  Future<void> play(int playerId) async {
    ProVideoPlayerLogger.log('play() called for playerId: $playerId', tag: 'PigeonMethodChannel');
    await _hostApi.play(playerId);
  }

  @override
  Future<void> pause(int playerId) async {
    ProVideoPlayerLogger.log('pause() called for playerId: $playerId', tag: 'PigeonMethodChannel');
    await _hostApi.pause(playerId);
  }

  @override
  Future<void> stop(int playerId) async {
    ProVideoPlayerLogger.log('stop() called for playerId: $playerId', tag: 'PigeonMethodChannel');
    await _hostApi.stop(playerId);
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    ProVideoPlayerLogger.log(
      'seekTo() called for playerId: $playerId, position: $position',
      tag: 'PigeonMethodChannel',
    );
    await _hostApi.seekTo(playerId, position.inMilliseconds);
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    ProVideoPlayerLogger.log(
      'setPlaybackSpeed() called for playerId: $playerId, speed: $speed',
      tag: 'PigeonMethodChannel',
    );
    await _hostApi.setPlaybackSpeed(playerId, speed);
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    ProVideoPlayerLogger.log('setVolume() called for playerId: $playerId, volume: $volume', tag: 'PigeonMethodChannel');
    await _hostApi.setVolume(playerId, volume);
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    final positionMs = await _hostApi.getPosition(playerId);
    return Duration(milliseconds: positionMs);
  }

  @override
  Future<Duration> getDuration(int playerId) async {
    final durationMs = await _hostApi.getDuration(playerId);
    return Duration(milliseconds: durationMs);
  }

  @override
  Future<PlatformCapabilities> getPlatformCapabilities() async {
    ProVideoPlayerLogger.log('Getting platform capabilities', tag: 'PigeonMethodChannel');
    final message = await _hostApi.getPlatformCapabilities();
    return _convertPlatformCapabilities(message);
  }

  @override
  Future<void> setVerboseLogging({required bool enabled}) async {
    ProVideoPlayerLogger.log('Setting verbose logging to: $enabled', tag: 'PigeonMethodChannel');
    await _hostApi.setVerboseLogging(enabled);
  }

  // ==================== Device Controls ====================

  @override
  Future<double> getDeviceVolume() async => _hostApi.getDeviceVolume();

  @override
  Future<void> setDeviceVolume(double volume) async => _hostApi.setDeviceVolume(volume);

  @override
  Future<double> getScreenBrightness() async => _hostApi.getScreenBrightness();

  @override
  Future<void> setScreenBrightness(double brightness) async => _hostApi.setScreenBrightness(brightness);

  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    final message = await _hostApi.getBatteryInfo();
    if (message == null) return null;
    return BatteryInfo(percentage: (message.level * 100).round(), isCharging: message.isCharging);
  }

  @override
  Stream<BatteryInfo> get batteryUpdates {
    // TODO: Implement battery updates stream using Pigeon FlutterApi
    throw UnimplementedError('Battery updates stream not yet implemented with Pigeon');
  }

  // ==================== Player Configuration ====================

  @override
  Future<void> setLooping(int playerId, bool looping) async => _hostApi.setLooping(playerId, looping);

  @override
  Future<void> setScalingMode(int playerId, VideoScalingMode mode) async {
    final pigeonMode = switch (mode) {
      VideoScalingMode.fit => VideoScalingModeEnum.fit,
      VideoScalingMode.fill => VideoScalingModeEnum.fill,
      VideoScalingMode.stretch => VideoScalingModeEnum.stretch,
    };
    await _hostApi.setScalingMode(playerId, pigeonMode);
  }

  @override
  Future<void> setControlsMode(int playerId, ControlsMode controlsMode) async {
    final pigeonMode = switch (controlsMode) {
      ControlsMode.none => ControlsModeEnum.videoOnly,
      ControlsMode.flutter => ControlsModeEnum.flutterControls,
      ControlsMode.native => ControlsModeEnum.nativeControls,
    };
    await _hostApi.setControlsMode(playerId, pigeonMode);
  }

  // ==================== Subtitle Management ====================

  @override
  Future<void> setSubtitleTrack(int playerId, SubtitleTrack? track) async {
    final message = track == null
        ? null
        : SubtitleTrackMessage(id: track.id, label: track.label, language: track.language, isDefault: track.isDefault);
    await _hostApi.setSubtitleTrack(playerId, message);
  }

  @override
  Future<void> setSubtitleRenderMode(int playerId, SubtitleRenderMode mode) async {
    final pigeonMode = switch (mode) {
      SubtitleRenderMode.auto => SubtitleRenderModeEnum.auto,
      SubtitleRenderMode.native => SubtitleRenderModeEnum.native,
      SubtitleRenderMode.flutter => SubtitleRenderModeEnum.flutter,
    };
    await _hostApi.setSubtitleRenderMode(playerId, pigeonMode);
  }

  @override
  Future<ExternalSubtitleTrack?> addExternalSubtitle(int playerId, SubtitleSource source) async {
    final message = SubtitleSourceMessage(
      sourceType: source.runtimeType.toString(),
      path: _getSubtitlePath(source),
      format: source.format != null ? _convertSubtitleFormat(source.format!) : SubtitleFormatEnum.srt,
      label: source.label,
      language: source.language,
      isDefault: source.isDefault,
    );
    final result = await _hostApi.addExternalSubtitle(playerId, message);
    if (result == null) return null;
    return ExternalSubtitleTrack(
      id: result.id,
      label: result.label,
      language: result.language,
      isDefault: result.isDefault,
      path: result.path,
      sourceType: result.sourceType,
      format: _convertFromPigeonSubtitleFormat(result.format),
    );
  }

  @override
  Future<bool> removeExternalSubtitle(int playerId, String trackId) async =>
      _hostApi.removeExternalSubtitle(playerId, trackId);

  @override
  Future<List<ExternalSubtitleTrack>> getExternalSubtitles(int playerId) async {
    final messages = await _hostApi.getExternalSubtitles(playerId);
    return messages
        .whereType<ExternalSubtitleTrackMessage>()
        .map(
          (msg) => ExternalSubtitleTrack(
            id: msg.id,
            label: msg.label,
            language: msg.language,
            isDefault: msg.isDefault,
            path: msg.path,
            sourceType: msg.sourceType,
            format: _convertFromPigeonSubtitleFormat(msg.format),
          ),
        )
        .toList();
  }

  // ==================== Audio Management ====================

  @override
  Future<void> setAudioTrack(int playerId, AudioTrack? track) async {
    final message = track == null
        ? null
        : AudioTrackMessage(id: track.id, label: track.label, language: track.language, isDefault: track.isDefault);
    await _hostApi.setAudioTrack(playerId, message);
  }

  // ==================== Picture-in-Picture ====================

  @override
  Future<bool> enterPip(int playerId, {PipOptions options = const PipOptions()}) async {
    final message = PipOptionsMessage(
      aspectRatio: options.aspectRatio,
      autoEnterOnBackground: options.autoEnterOnBackground,
    );
    return _hostApi.enterPip(playerId, message);
  }

  @override
  Future<void> exitPip(int playerId) async => _hostApi.exitPip(playerId);

  @override
  Future<bool> isPipSupported() async => _hostApi.isPipSupported();

  @override
  Future<void> setPipActions(int playerId, List<PipAction>? actions) async {
    final messages =
        actions?.map((action) {
          final type = switch (action.type) {
            PipActionType.playPause => PipActionTypeEnum.playPause,
            PipActionType.skipPrevious => PipActionTypeEnum.skipPrevious,
            PipActionType.skipNext => PipActionTypeEnum.skipNext,
            PipActionType.skipBackward => PipActionTypeEnum.skipBackward,
            PipActionType.skipForward => PipActionTypeEnum.skipForward,
          };
          final skipInterval = (action.type == PipActionType.skipBackward || action.type == PipActionType.skipForward)
              ? action.skipInterval.inMilliseconds
              : null;
          return PipActionMessage(type: type, skipIntervalMs: skipInterval);
        }).toList() ??
        [];
    await _hostApi.setPipActions(playerId, messages);
  }

  // ==================== Fullscreen ====================

  @override
  Future<bool> enterFullscreen(int playerId) async => _hostApi.enterFullscreen(playerId);

  @override
  Future<void> exitFullscreen(int playerId) async => _hostApi.exitFullscreen(playerId);

  @override
  Future<void> setWindowFullscreen({required bool fullscreen}) async => _hostApi.setWindowFullscreen(fullscreen);

  // ==================== Background Playback ====================

  @override
  Future<bool> setBackgroundPlayback(int playerId, {required bool enabled}) async =>
      _hostApi.setBackgroundPlayback(playerId, enabled);

  @override
  Future<bool> isBackgroundPlaybackSupported() async => _hostApi.isBackgroundPlaybackSupported();

  // ==================== Quality Selection ====================

  @override
  Future<List<VideoQualityTrack>> getVideoQualities(int playerId) async {
    final messages = await _hostApi.getVideoQualities(playerId);
    return messages
        .whereType<VideoQualityTrackMessage>()
        .map(
          (msg) => VideoQualityTrack(
            id: msg.id,
            bitrate: msg.bitrate,
            width: msg.width,
            height: msg.height,
            frameRate: msg.frameRate,
            label: msg.label,
            isDefault: msg.isDefault,
          ),
        )
        .toList();
  }

  @override
  Future<bool> setVideoQuality(int playerId, VideoQualityTrack track) async {
    final message = VideoQualityTrackMessage(
      id: track.id,
      bitrate: track.bitrate,
      width: track.width,
      height: track.height,
      frameRate: track.frameRate,
      label: track.label,
      isDefault: track.isDefault,
    );
    return _hostApi.setVideoQuality(playerId, message);
  }

  @override
  Future<VideoQualityTrack> getCurrentVideoQuality(int playerId) async {
    final message = await _hostApi.getCurrentVideoQuality(playerId);
    return VideoQualityTrack(
      id: message.id,
      bitrate: message.bitrate,
      width: message.width,
      height: message.height,
      frameRate: message.frameRate,
      label: message.label,
      isDefault: message.isDefault,
    );
  }

  @override
  Future<bool> isQualitySelectionSupported(int playerId) async => _hostApi.isQualitySelectionSupported(playerId);

  // ==================== Video Metadata ====================

  @override
  Future<VideoMetadata?> getVideoMetadata(int playerId) async {
    final message = await _hostApi.getVideoMetadata(playerId);
    if (message == null) return null;
    return VideoMetadata(
      width: message.width,
      height: message.height,
      duration: message.durationMs != null ? Duration(milliseconds: message.durationMs!) : null,
      videoCodec: message.videoCodec,
      audioCodec: message.audioCodec,
      videoBitrate: message.bitrate,
      frameRate: message.frameRate,
    );
  }

  @override
  Future<void> setMediaMetadata(int playerId, MediaMetadata metadata) async {
    final message = MediaMetadataMessage(
      title: metadata.title,
      artist: metadata.artist,
      album: metadata.album,
      artworkUrl: metadata.artworkUrl,
    );
    await _hostApi.setMediaMetadata(playerId, message);
  }

  // ==================== Casting ====================

  @override
  Future<bool> isCastingSupported() async => _hostApi.isCastingSupported();

  @override
  Future<List<CastDevice>> getAvailableCastDevices(int playerId) async {
    final messages = await _hostApi.getAvailableCastDevices(playerId);
    return messages.whereType<CastDeviceMessage>().map((msg) {
      final type = switch (msg.type) {
        CastDeviceTypeEnum.airPlay => CastDeviceType.airPlay,
        CastDeviceTypeEnum.chromecast => CastDeviceType.chromecast,
        CastDeviceTypeEnum.webRemotePlayback => CastDeviceType.webRemotePlayback,
        CastDeviceTypeEnum.unknown => CastDeviceType.unknown,
      };
      return CastDevice(id: msg.id, name: msg.name, type: type);
    }).toList();
  }

  @override
  Future<bool> startCasting(int playerId, {CastDevice? device}) async {
    final message = device == null
        ? null
        : CastDeviceMessage(
            id: device.id,
            name: device.name,
            type: switch (device.type) {
              CastDeviceType.airPlay => CastDeviceTypeEnum.airPlay,
              CastDeviceType.chromecast => CastDeviceTypeEnum.chromecast,
              CastDeviceType.webRemotePlayback => CastDeviceTypeEnum.webRemotePlayback,
              CastDeviceType.unknown => CastDeviceTypeEnum.unknown,
            },
          );
    return _hostApi.startCasting(playerId, message);
  }

  @override
  Future<bool> stopCasting(int playerId) async => _hostApi.stopCasting(playerId);

  @override
  Future<CastState> getCastState(int playerId) async {
    final state = await _hostApi.getCastState(playerId);
    return switch (state) {
      CastStateEnum.notConnected => CastState.notConnected,
      CastStateEnum.connecting => CastState.connecting,
      CastStateEnum.connected => CastState.connected,
      CastStateEnum.disconnecting => CastState.disconnecting,
    };
  }

  @override
  Future<CastDevice?> getCurrentCastDevice(int playerId) async {
    final message = await _hostApi.getCurrentCastDevice(playerId);
    if (message == null) return null;
    final type = switch (message.type) {
      CastDeviceTypeEnum.airPlay => CastDeviceType.airPlay,
      CastDeviceTypeEnum.chromecast => CastDeviceType.chromecast,
      CastDeviceTypeEnum.webRemotePlayback => CastDeviceType.webRemotePlayback,
      CastDeviceTypeEnum.unknown => CastDeviceType.unknown,
    };
    return CastDevice(id: message.id, name: message.name, type: type);
  }

  // ==================== Events ====================

  @override
  Stream<VideoPlayerEvent> events(int playerId) {
    // TODO: Implement using Pigeon FlutterApi for callbacks
    // For now, return an empty stream
    _eventStreamControllers[playerId] ??= StreamController<VideoPlayerEvent>.broadcast();
    return _eventStreamControllers[playerId]!.stream;
  }

  // ==================== Conversion Helpers ====================

  /// Converts a [VideoSource] to a Pigeon [VideoSourceMessage].
  VideoSourceMessage _convertVideoSource(VideoSource source) => switch (source) {
    NetworkVideoSource(:final url, :final headers) => VideoSourceMessage(
      type: VideoSourceType.network,
      url: url,
      headers: headers?.map((k, v) => MapEntry(k as String?, v as String?)),
    ),
    FileVideoSource(:final path) => VideoSourceMessage(type: VideoSourceType.file, path: path),
    AssetVideoSource(:final assetPath) => VideoSourceMessage(type: VideoSourceType.asset, assetPath: assetPath),
    PlaylistVideoSource() => throw StateError(
      'PlaylistVideoSource should be converted to NetworkVideoSource or Playlist before encoding',
    ),
  };

  /// Converts [VideoPlayerOptions] to a Pigeon [VideoPlayerOptionsMessage].
  VideoPlayerOptionsMessage _convertOptions(VideoPlayerOptions options) => VideoPlayerOptionsMessage(
    autoPlay: options.autoPlay,
    looping: options.looping,
    volume: options.volume,
    playbackSpeed: options.playbackSpeed,
    allowBackgroundPlayback: options.allowBackgroundPlayback,
    mixWithOthers: options.mixWithOthers,
    allowPip: options.allowPip,
    autoEnterPipOnBackground: options.autoEnterPipOnBackground,
  );

  /// Converts a Pigeon [PlatformCapabilitiesMessage] to [PlatformCapabilities].
  PlatformCapabilities _convertPlatformCapabilities(PlatformCapabilitiesMessage message) => PlatformCapabilities(
    supportsPictureInPicture: message.supportsPip,
    supportsFullscreen: true,
    supportsBackgroundPlayback: message.supportsBackgroundPlayback,
    supportsCasting: message.supportsCasting,
    supportsAirPlay: false,
    supportsChromecast: false,
    supportsRemotePlayback: false,
    supportsQualitySelection: true,
    supportsPlaybackSpeedControl: true,
    supportsSubtitles: true,
    supportsExternalSubtitles: true,
    supportsAudioTrackSelection: true,
    supportsChapters: true,
    supportsVideoMetadataExtraction: true,
    supportsNetworkMonitoring: true,
    supportsBandwidthEstimation: true,
    supportsAdaptiveBitrate: true,
    supportsHLS: true,
    supportsDASH: false,
    supportsDeviceVolumeControl: true,
    supportsScreenBrightnessControl: true,
  );

  String _getSubtitlePath(SubtitleSource source) => switch (source) {
    NetworkSubtitleSource(:final url) => url,
    FileSubtitleSource(:final path) => path,
    AssetSubtitleSource(:final assetPath) => assetPath,
  };

  SubtitleFormatEnum _convertSubtitleFormat(SubtitleFormat format) => switch (format) {
    SubtitleFormat.srt => SubtitleFormatEnum.srt,
    SubtitleFormat.vtt => SubtitleFormatEnum.vtt,
    SubtitleFormat.ssa => SubtitleFormatEnum.ssa,
    SubtitleFormat.ass => SubtitleFormatEnum.ass,
    SubtitleFormat.ttml => SubtitleFormatEnum.ttml,
  };

  SubtitleFormat _convertFromPigeonSubtitleFormat(SubtitleFormatEnum format) => switch (format) {
    SubtitleFormatEnum.srt => SubtitleFormat.srt,
    SubtitleFormatEnum.vtt => SubtitleFormat.vtt,
    SubtitleFormatEnum.ssa => SubtitleFormat.ssa,
    SubtitleFormatEnum.ass => SubtitleFormat.ass,
    SubtitleFormatEnum.ttml => SubtitleFormat.ttml,
  };
}
