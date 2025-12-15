import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pro_video_player_logger.dart';
import 'pro_video_player_platform.dart';
import 'subtitle/subtitle_loader.dart';
import 'types/types.dart';
import 'video_format_utils.dart';

/// Base class for platform implementations that use method channels.
///
/// This class provides common functionality for iOS, macOS, Windows, and Linux
/// implementations, eliminating code duplication across platforms.
abstract class MethodChannelBase extends ProVideoPlayerPlatform {
  /// Creates a [MethodChannelBase] with the given [channelPrefix].
  ///
  /// The [channelPrefix] is used to construct the method channel name
  /// as 'com.example.$channelPrefix/methods'.
  MethodChannelBase(this.channelPrefix) : _methodChannel = MethodChannel('com.example.$channelPrefix/methods');

  /// The channel prefix used for method and event channels.
  final String channelPrefix;

  /// The method channel for communication with native code.
  final MethodChannel _methodChannel;

  /// Map of event channels for each player.
  final Map<int, EventChannel> _eventChannels = {};

  /// Map of event streams for each player.
  final Map<int, Stream<VideoPlayerEvent>> _eventStreams = {};

  /// Subtitle loader for downloading and parsing external subtitle files.
  final SubtitleLoader _subtitleLoader = SubtitleLoader();

  /// Protected getter for subtitle loader to allow overriding in tests.
  @protected
  SubtitleLoader get subtitleLoader => _subtitleLoader;

  @override
  Future<int> create({required VideoSource source, VideoPlayerOptions options = const VideoPlayerOptions()}) async {
    ProVideoPlayerLogger.log('Creating player with source: ${source.runtimeType}', tag: 'MethodChannel');
    final sourceData = _encodeVideoSource(source);
    final result = await _methodChannel.invokeMethod<int>('create', {
      'source': sourceData,
      'options': _encodeOptions(options),
    });
    if (result == null) {
      throw PlatformException(code: 'CREATE_FAILED', message: 'Failed to create video player');
    }
    _setupEventChannel(result);
    ProVideoPlayerLogger.log('Player created with ID: $result', tag: 'MethodChannel');
    return result;
  }

  @override
  Future<void> dispose(int playerId) async {
    _eventChannels.remove(playerId);
    _eventStreams.remove(playerId);
    await _methodChannel.invokeMethod<void>('dispose', {'playerId': playerId});
  }

  @override
  Future<void> play(int playerId) async {
    ProVideoPlayerLogger.log('play() called for playerId: $playerId', tag: 'MethodChannel');
    await _methodChannel.invokeMethod<void>('play', {'playerId': playerId});
  }

  @override
  Future<void> pause(int playerId) async {
    ProVideoPlayerLogger.log('pause() called for playerId: $playerId', tag: 'MethodChannel');
    await _methodChannel.invokeMethod<void>('pause', {'playerId': playerId});
  }

  @override
  Future<void> stop(int playerId) async {
    await _methodChannel.invokeMethod<void>('stop', {'playerId': playerId});
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    await _methodChannel.invokeMethod<void>('seekTo', {'playerId': playerId, 'position': position.inMilliseconds});
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    await _methodChannel.invokeMethod<void>('setPlaybackSpeed', {'playerId': playerId, 'speed': speed});
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    await _methodChannel.invokeMethod<void>('setVolume', {'playerId': playerId, 'volume': volume});
  }

  @override
  Future<double> getDeviceVolume() async {
    final result = await _methodChannel.invokeMethod<double>('getDeviceVolume');
    return result ?? 1.0;
  }

  @override
  Future<void> setDeviceVolume(double volume) async {
    await _methodChannel.invokeMethod<void>('setDeviceVolume', {'volume': volume});
  }

  @override
  Future<double> getScreenBrightness() async {
    final result = await _methodChannel.invokeMethod<double>('getScreenBrightness');
    return result ?? 1.0;
  }

  @override
  Future<void> setScreenBrightness(double brightness) async {
    await _methodChannel.invokeMethod<void>('setScreenBrightness', {'brightness': brightness});
  }

  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getBatteryInfo');
    if (result == null) return null;
    return BatteryInfo.fromJson(Map<String, dynamic>.from(result));
  }

  Stream<BatteryInfo>? _batteryUpdatesStream;

  @override
  Stream<BatteryInfo> get batteryUpdates {
    _batteryUpdatesStream ??= EventChannel('com.example.$channelPrefix/batteryUpdates')
        .receiveBroadcastStream()
        .transform(
          StreamTransformer<dynamic, BatteryInfo>.fromHandlers(
            handleData: (event, sink) {
              if (event is Map<dynamic, dynamic>) {
                try {
                  final batteryInfo = BatteryInfo.fromJson(Map<String, dynamic>.from(event));
                  sink.add(batteryInfo);
                } catch (e) {
                  // Ignore malformed events
                }
              }
            },
            handleError: (error, stackTrace, sink) {
              // Battery monitoring not supported - complete the stream
              sink.close();
            },
          ),
        )
        .asBroadcastStream();

    return _batteryUpdatesStream!;
  }

  @override
  Future<void> setLooping(int playerId, {required bool looping}) async {
    await _methodChannel.invokeMethod<void>('setLooping', {'playerId': playerId, 'looping': looping});
  }

  @override
  Future<void> setScalingMode(int playerId, VideoScalingMode mode) async {
    await _methodChannel.invokeMethod<void>('setScalingMode', {'playerId': playerId, 'scalingMode': mode.name});
  }

  @override
  Future<void> setSubtitleTrack(int playerId, SubtitleTrack? track) async {
    await _methodChannel.invokeMethod<void>('setSubtitleTrack', {
      'playerId': playerId,
      'track': track != null ? _encodeSubtitleTrack(track) : null,
    });
  }

  @override
  Future<void> setSubtitleRenderMode(int playerId, SubtitleRenderMode mode) async {
    ProVideoPlayerLogger.log(
      'setSubtitleRenderMode() called for playerId: $playerId, mode: ${mode.name}',
      tag: 'MethodChannel',
    );
    await _methodChannel.invokeMethod<void>('setSubtitleRenderMode', {'playerId': playerId, 'renderMode': mode.name});
  }

  @override
  Future<void> setAudioTrack(int playerId, AudioTrack? track) async {
    await _methodChannel.invokeMethod<void>('setAudioTrack', {
      'playerId': playerId,
      'track': track != null ? _encodeAudioTrack(track) : null,
    });
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    final result = await _methodChannel.invokeMethod<int>('getPosition', {'playerId': playerId});
    return Duration(milliseconds: result ?? 0);
  }

  @override
  Future<Duration> getDuration(int playerId) async {
    final result = await _methodChannel.invokeMethod<int>('getDuration', {'playerId': playerId});
    return Duration(milliseconds: result ?? 0);
  }

  @override
  Future<bool> enterPip(int playerId, {PipOptions options = const PipOptions()}) async {
    final result = await _methodChannel.invokeMethod<bool>('enterPip', {
      'playerId': playerId,
      'aspectRatio': options.aspectRatio,
      'autoEnterOnBackground': options.autoEnterOnBackground,
    });
    return result ?? false;
  }

  @override
  Future<void> exitPip(int playerId) async {
    await _methodChannel.invokeMethod<void>('exitPip', {'playerId': playerId});
  }

  @override
  Future<bool> isPipSupported() async {
    final result = await _methodChannel.invokeMethod<bool>('isPipSupported');
    return result ?? false;
  }

  @override
  Future<void> setPipActions(int playerId, List<PipAction>? actions) async {
    await _methodChannel.invokeMethod<void>('setPipActions', {
      'playerId': playerId,
      'actions': actions?.map((a) => a.toMap()).toList(),
    });
  }

  @override
  Future<bool> enterFullscreen(int playerId) async {
    final result = await _methodChannel.invokeMethod<bool>('enterFullscreen', {'playerId': playerId});
    return result ?? false;
  }

  @override
  Future<void> exitFullscreen(int playerId) async {
    await _methodChannel.invokeMethod<void>('exitFullscreen', {'playerId': playerId});
  }

  @override
  Future<void> setControlsMode(int playerId, ControlsMode controlsMode) async {
    ProVideoPlayerLogger.log(
      'setControlsMode() called for playerId: $playerId, mode: ${controlsMode.name}',
      tag: 'MethodChannel',
    );
    await _methodChannel.invokeMethod<void>('setControlsMode', {
      'playerId': playerId,
      'controlsMode': controlsMode.name,
    });
  }

  @override
  Future<bool> setBackgroundPlayback(int playerId, {required bool enabled}) async {
    final result = await _methodChannel.invokeMethod<bool>('setBackgroundPlayback', {
      'playerId': playerId,
      'enabled': enabled,
    });
    return result ?? false;
  }

  @override
  Future<bool> isBackgroundPlaybackSupported() async {
    final result = await _methodChannel.invokeMethod<bool>('isBackgroundPlaybackSupported');
    return result ?? false;
  }

  @override
  Stream<VideoPlayerEvent> events(int playerId) {
    final stream = _eventStreams[playerId];
    if (stream == null) {
      throw StateError('Player $playerId has not been created');
    }
    return stream;
  }

  /// Sets up the event channel for a player.
  void _setupEventChannel(int playerId) {
    final eventChannel = EventChannel('com.example.$channelPrefix/events/$playerId');
    _eventChannels[playerId] = eventChannel;

    _eventStreams[playerId] = eventChannel.receiveBroadcastStream().transform(
      StreamTransformer<dynamic, VideoPlayerEvent>.fromHandlers(
        handleData: (event, sink) {
          if (event is Map<dynamic, dynamic>) {
            final parsed = _parseEvent(event);
            if (parsed != null) {
              sink.add(parsed);
            }
          }
        },
        handleError: (error, stackTrace, sink) {
          sink.add(ErrorEvent(error.toString()));
        },
      ),
    );
  }

  /// Encodes a [VideoSource] to a map for method channel communication.
  Map<String, dynamic> _encodeVideoSource(VideoSource source) => switch (source) {
    NetworkVideoSource(:final url, :final headers) => {'type': 'network', 'url': url, 'headers': headers},
    FileVideoSource(:final path) => {'type': 'file', 'path': path},
    AssetVideoSource(:final assetPath) => {'type': 'asset', 'assetPath': assetPath},
    PlaylistVideoSource() => throw StateError(
      'PlaylistVideoSource should be converted to NetworkVideoSource or Playlist before encoding',
    ),
  };

  /// Encodes [VideoPlayerOptions] to a map for method channel communication.
  ///
  /// Computed values are sent instead of enum names where possible,
  /// following the Dart-First Implementation Principle. This reduces
  /// duplicated lookup logic in native code.
  Map<String, dynamic> _encodeOptions(VideoPlayerOptions options) => {
    'autoPlay': options.autoPlay,
    'looping': options.looping,
    'volume': options.volume,
    'playbackSpeed': options.playbackSpeed,
    'allowBackgroundPlayback': options.allowBackgroundPlayback,
    'mixWithOthers': options.mixWithOthers,
    'allowPip': options.allowPip,
    'autoEnterPipOnBackground': options.autoEnterPipOnBackground,
    'subtitlesEnabled': options.subtitlesEnabled,
    'showSubtitlesByDefault': options.showSubtitlesByDefault,
    'preferredSubtitleLanguage': options.preferredSubtitleLanguage,
    'fullscreenOrientation': options.fullscreenOrientation.name,
    // Send scaling mode as enum name - native code uses platform-specific APIs
    'scalingMode': options.scalingMode.name,
    // Send buffering tier name - native platforms need to map to their specific APIs
    // (AVPlayer preferredForwardBufferDuration vs ExoPlayer LoadControl)
    'bufferingTier': options.bufferingTier.name,
    'allowCasting': options.allowCasting,
    // Embedded subtitle rendering in Flutter
    'renderEmbeddedSubtitlesInFlutter': options.subtitleRenderMode == SubtitleRenderMode.flutter,
    // ABR (Adaptive Bitrate) options
    'abrMode': options.abrMode.name,
    'minBitrate': options.minBitrate,
    'maxBitrate': options.maxBitrate,
  };

  /// Encodes a [SubtitleTrack] to a map for method channel communication.
  Map<String, dynamic> _encodeSubtitleTrack(SubtitleTrack track) => {
    'id': track.id,
    'label': track.label,
    'language': track.language,
    'isDefault': track.isDefault,
  };

  /// Encodes an [AudioTrack] to a map for method channel communication.
  Map<String, dynamic> _encodeAudioTrack(AudioTrack track) => {
    'id': track.id,
    'label': track.label,
    'language': track.language,
    'isDefault': track.isDefault,
  };

  /// Parses an event from native code into a [VideoPlayerEvent].
  VideoPlayerEvent? _parseEvent(Map<dynamic, dynamic> event) {
    final type = event['type'] as String?;
    if (type == null) return null;

    return switch (type) {
      'playbackStateChanged' => PlaybackStateChangedEvent(_parsePlaybackState(event['state'] as String)),
      'positionChanged' => PositionChangedEvent(Duration(milliseconds: event['position'] as int)),
      'bufferedPositionChanged' => BufferedPositionChangedEvent(
        Duration(milliseconds: event['bufferedPosition'] as int),
      ),
      'durationChanged' => DurationChangedEvent(Duration(milliseconds: event['duration'] as int)),
      'playbackCompleted' => const PlaybackCompletedEvent(),
      'error' => ErrorEvent(event['message'] as String, code: event['code'] as String?),
      'videoSizeChanged' => VideoSizeChangedEvent(width: event['width'] as int, height: event['height'] as int),
      'subtitleTracksChanged' => SubtitleTracksChangedEvent(_parseSubtitleTracks(event['tracks'] as List<dynamic>)),
      'selectedSubtitleChanged' => SelectedSubtitleChangedEvent(
        event['track'] != null ? _parseSubtitleTrack(event['track'] as Map<dynamic, dynamic>) : null,
      ),
      'audioTracksChanged' => AudioTracksChangedEvent(_parseAudioTracks(event['tracks'] as List<dynamic>)),
      'selectedAudioChanged' => SelectedAudioChangedEvent(
        event['track'] != null ? _parseAudioTrack(event['track'] as Map<dynamic, dynamic>) : null,
      ),
      'videoQualityTracksChanged' => VideoQualityTracksChangedEvent(
        _parseVideoQualityTracks(event['tracks'] as List<dynamic>? ?? []),
      ),
      'selectedQualityChanged' => SelectedQualityChangedEvent(
        _parseVideoQualityTrack(event['track'] as Map<dynamic, dynamic>),
        isAutoSwitch: event['isAutoSwitch'] as bool? ?? false,
      ),
      'pipStateChanged' => PipStateChangedEvent(isActive: event['isActive'] as bool),
      'fullscreenStateChanged' => FullscreenStateChangedEvent(isFullscreen: event['isFullscreen'] as bool),
      'backgroundPlaybackChanged' => BackgroundPlaybackChangedEvent(isEnabled: event['isEnabled'] as bool),
      'playbackSpeedChanged' => PlaybackSpeedChangedEvent(event['speed'] as double),
      'volumeChanged' => VolumeChangedEvent(event['volume'] as double),
      'metadataChanged' => MetadataChangedEvent(title: event['title'] as String?),
      // Network resilience events
      'bufferingStarted' => BufferingStartedEvent(reason: _parseBufferingReason(event['reason'] as String?)),
      'bufferingEnded' => const BufferingEndedEvent(),
      'networkError' => NetworkErrorEvent(
        message: event['message'] as String? ?? 'Network error',
        willRetry: event['willRetry'] as bool? ?? false,
        retryAttempt: event['retryAttempt'] as int? ?? 0,
        maxRetries: event['maxRetries'] as int? ?? 3,
      ),
      'playbackRecovered' => PlaybackRecoveredEvent(retriesUsed: event['retriesUsed'] as int? ?? 0),
      'networkStateChanged' => NetworkStateChangedEvent(isConnected: event['isConnected'] as bool? ?? false),
      // PiP action events
      'pipActionTriggered' => PipActionTriggeredEvent(action: _parsePipActionType(event['action'] as String?)),
      'pipRestoreUserInterface' => const PipRestoreUserInterfaceEvent(),
      // Bandwidth estimation
      'bandwidthEstimateChanged' => BandwidthEstimateChangedEvent(event['bandwidth'] as int? ?? 0),
      // Video metadata
      'videoMetadataExtracted' => VideoMetadataExtractedEvent(
        VideoMetadata.fromMap(Map<String, dynamic>.from(event['metadata'] as Map<dynamic, dynamic>)),
      ),
      // Casting events
      'castStateChanged' => CastStateChangedEvent(
        state: _parseCastState(event['state'] as String?),
        device: event['device'] != null ? _parseCastDevice(event['device'] as Map<dynamic, dynamic>) : null,
      ),
      'castDevicesChanged' => CastDevicesChangedEvent(_parseCastDevices(event['devices'] as List<dynamic>? ?? [])),
      // Chapter events
      'chaptersExtracted' => ChaptersExtractedEvent(_parseChapters(event['chapters'] as List<dynamic>? ?? [])),
      'currentChapterChanged' => CurrentChapterChangedEvent(
        event['chapter'] != null ? _parseChapter(event['chapter'] as Map<dynamic, dynamic>) : null,
      ),
      // Embedded subtitle cue event
      'embeddedSubtitleCue' => EmbeddedSubtitleCueEvent(
        cue: _parseEmbeddedSubtitleCue(event),
        trackId: event['trackId'] as String?,
      ),
      _ => null,
    };
  }

  /// Parses a PiP action type string into a [PipActionType].
  PipActionType _parsePipActionType(String? action) => switch (action) {
    'playPause' => PipActionType.playPause,
    'skipPrevious' => PipActionType.skipPrevious,
    'skipNext' => PipActionType.skipNext,
    'skipBackward' => PipActionType.skipBackward,
    'skipForward' => PipActionType.skipForward,
    _ => PipActionType.playPause,
  };

  /// Parses a buffering reason string into a [BufferingReason].
  BufferingReason _parseBufferingReason(String? reason) => switch (reason) {
    'initial' => BufferingReason.initial,
    'seeking' => BufferingReason.seeking,
    'insufficientBandwidth' => BufferingReason.insufficientBandwidth,
    'networkUnstable' => BufferingReason.networkUnstable,
    _ => BufferingReason.unknown,
  };

  /// Parses a playback state string into a [PlaybackState].
  PlaybackState _parsePlaybackState(String state) => switch (state) {
    'uninitialized' => PlaybackState.uninitialized,
    'initializing' => PlaybackState.initializing,
    'ready' => PlaybackState.ready,
    'playing' => PlaybackState.playing,
    'paused' => PlaybackState.paused,
    'completed' => PlaybackState.completed,
    'buffering' => PlaybackState.buffering,
    'error' => PlaybackState.error,
    'disposed' => PlaybackState.disposed,
    _ => PlaybackState.uninitialized,
  };

  /// Parses a list of subtitle tracks.
  List<SubtitleTrack> _parseSubtitleTracks(List<dynamic> tracks) =>
      tracks.map((t) => _parseSubtitleTrack(t as Map<dynamic, dynamic>)).toList();

  /// Parses a subtitle track map into a [SubtitleTrack].
  ///
  /// If no label is provided by native, generates one from the language code
  /// using [VideoPlayerConstants.getLanguageDisplayName].
  SubtitleTrack _parseSubtitleTrack(Map<dynamic, dynamic> track) {
    final language = track['language'] as String?;
    final nativeLabel = track['label'] as String?;

    // Use native label if provided, otherwise generate from language code
    final label = (nativeLabel != null && nativeLabel.isNotEmpty)
        ? nativeLabel
        : VideoPlayerConstants.getLanguageDisplayName(language);

    return SubtitleTrack(
      id: track['id'] as String,
      label: label,
      language: language,
      isDefault: track['isDefault'] as bool? ?? false,
    );
  }

  /// Parses a list of audio tracks.
  List<AudioTrack> _parseAudioTracks(List<dynamic> tracks) =>
      tracks.map((t) => _parseAudioTrack(t as Map<dynamic, dynamic>)).toList();

  /// Parses an audio track map into an [AudioTrack].
  ///
  /// If no label is provided by native, generates one from the language code
  /// using [VideoPlayerConstants.getLanguageDisplayName].
  AudioTrack _parseAudioTrack(Map<dynamic, dynamic> track) {
    final language = track['language'] as String?;
    final nativeLabel = track['label'] as String?;

    // Use native label if provided, otherwise generate from language code
    final label = (nativeLabel != null && nativeLabel.isNotEmpty)
        ? nativeLabel
        : VideoPlayerConstants.getLanguageDisplayName(language);

    return AudioTrack(
      id: track['id'] as String,
      label: label,
      language: language,
      isDefault: track['isDefault'] as bool? ?? false,
    );
  }

  /// Parses a list of chapters.
  List<Chapter> _parseChapters(List<dynamic> chapters) =>
      chapters.map((c) => _parseChapter(c as Map<dynamic, dynamic>)).toList();

  /// Parses a chapter map into a [Chapter].
  Chapter _parseChapter(Map<dynamic, dynamic> chapter) => Chapter(
    id: chapter['id'] as String,
    title: chapter['title'] as String,
    startTime: Duration(milliseconds: chapter['startTimeMs'] as int),
    endTime: chapter['endTimeMs'] != null ? Duration(milliseconds: chapter['endTimeMs'] as int) : null,
    thumbnailUrl: chapter['thumbnailUrl'] as String?,
  );

  /// Parses an embedded subtitle cue from the event map.
  ///
  /// Returns `null` if the text is null (indicates subtitle should be hidden).
  SubtitleCue? _parseEmbeddedSubtitleCue(Map<dynamic, dynamic> event) {
    final text = event['text'] as String?;
    if (text == null) return null;

    return SubtitleCue(
      text: text,
      start: Duration(milliseconds: event['startMs'] as int? ?? 0),
      end: Duration(milliseconds: event['endMs'] as int? ?? 0),
    );
  }

  @override
  Future<void> setVerboseLogging({required bool enabled}) async {
    ProVideoPlayerLogger.log('Setting verbose logging to: $enabled', tag: 'MethodChannel');
    await _methodChannel.invokeMethod<void>('setVerboseLogging', {'enabled': enabled});
  }

  @override
  Future<PlatformCapabilities> getPlatformCapabilities() async {
    ProVideoPlayerLogger.log('Getting platform capabilities', tag: 'MethodChannel');
    final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getPlatformCapabilities');
    if (result == null) {
      throw PlatformException(code: 'CAPABILITIES_FAILED', message: 'Failed to get platform capabilities');
    }
    return PlatformCapabilities.fromMap(result);
  }

  @override
  Future<void> setMediaMetadata(int playerId, MediaMetadata metadata) async {
    ProVideoPlayerLogger.log('Setting media metadata for playerId: $playerId', tag: 'MethodChannel');
    await _methodChannel.invokeMethod<void>('setMediaMetadata', {'playerId': playerId, 'metadata': metadata.toMap()});
  }

  // ==================== Video Quality Selection ====================

  @override
  Future<List<VideoQualityTrack>> getVideoQualities(int playerId) async {
    ProVideoPlayerLogger.log('getVideoQualities() called for playerId: $playerId', tag: 'MethodChannel');
    final result = await _methodChannel.invokeMethod<List<dynamic>>('getVideoQualities', {'playerId': playerId});
    if (result == null || result.isEmpty) {
      return [VideoQualityTrack.auto];
    }
    return result.map((t) => _parseVideoQualityTrack(t as Map<dynamic, dynamic>)).toList();
  }

  @override
  Future<bool> setVideoQuality(int playerId, VideoQualityTrack track) async {
    ProVideoPlayerLogger.log(
      'setVideoQuality() called for playerId: $playerId, track: ${track.id}',
      tag: 'MethodChannel',
    );
    final result = await _methodChannel.invokeMethod<bool>('setVideoQuality', {
      'playerId': playerId,
      'track': _encodeVideoQualityTrack(track),
    });
    return result ?? false;
  }

  @override
  Future<VideoQualityTrack> getCurrentVideoQuality(int playerId) async {
    final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getCurrentVideoQuality', {
      'playerId': playerId,
    });
    if (result == null) {
      return VideoQualityTrack.auto;
    }
    return _parseVideoQualityTrack(result);
  }

  @override
  Future<bool> isQualitySelectionSupported(int playerId) async {
    final result = await _methodChannel.invokeMethod<bool>('isQualitySelectionSupported', {'playerId': playerId});
    return result ?? false;
  }

  /// Encodes a [VideoQualityTrack] to a map for method channel communication.
  Map<String, dynamic> _encodeVideoQualityTrack(VideoQualityTrack track) => {
    'id': track.id,
    'bitrate': track.bitrate,
    'width': track.width,
    'height': track.height,
    if (track.frameRate != null) 'frameRate': track.frameRate,
    'label': track.label,
    'isDefault': track.isDefault,
  };

  /// Parses a video quality track map into a [VideoQualityTrack].
  ///
  /// If no label is provided by native, generates one from height/framerate
  /// using [VideoFormatUtils.getQualityLabel]. This implements the Dart-First
  /// approach by handling label generation in Dart rather than native code.
  VideoQualityTrack _parseVideoQualityTrack(Map<dynamic, dynamic> track) {
    final id = track['id'] as String;
    if (id == 'auto') {
      return VideoQualityTrack.auto;
    }

    final height = track['height'] as int? ?? 0;
    final frameRate = track['frameRate'] as double?;
    final nativeLabel = track['label'] as String?;

    // Use native label if provided, otherwise generate from height/framerate
    final label = (nativeLabel != null && nativeLabel.isNotEmpty)
        ? nativeLabel
        : height > 0
        ? VideoFormatUtils.getQualityLabel(height, frameRate)
        : '';

    return VideoQualityTrack(
      id: id,
      bitrate: track['bitrate'] as int? ?? 0,
      width: track['width'] as int? ?? 0,
      height: height,
      frameRate: frameRate,
      label: label,
      isDefault: track['isDefault'] as bool? ?? false,
    );
  }

  /// Parses a list of video quality tracks.
  List<VideoQualityTrack> _parseVideoQualityTracks(List<dynamic> tracks) =>
      tracks.map((t) => _parseVideoQualityTrack(t as Map<dynamic, dynamic>)).toList();

  // ==================== Video Metadata ====================

  @override
  Future<VideoMetadata?> getVideoMetadata(int playerId) async {
    ProVideoPlayerLogger.log('getVideoMetadata() called for playerId: $playerId', tag: 'MethodChannel');
    final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getVideoMetadata', {'playerId': playerId});
    if (result == null || result.isEmpty) {
      return null;
    }
    return VideoMetadata.fromMap(Map<String, dynamic>.from(result));
  }

  // ==================== Casting ====================

  @override
  Future<bool> isCastingSupported() async {
    ProVideoPlayerLogger.log('isCastingSupported() called', tag: 'MethodChannel');
    final result = await _methodChannel.invokeMethod<bool>('isCastingSupported');
    return result ?? false;
  }

  @override
  Future<List<CastDevice>> getAvailableCastDevices(int playerId) async {
    ProVideoPlayerLogger.log('getAvailableCastDevices() called for playerId: $playerId', tag: 'MethodChannel');
    final result = await _methodChannel.invokeMethod<List<dynamic>>('getAvailableCastDevices', {'playerId': playerId});
    if (result == null || result.isEmpty) {
      return [];
    }
    return _parseCastDevices(result);
  }

  @override
  Future<bool> startCasting(int playerId, {CastDevice? device}) async {
    ProVideoPlayerLogger.log(
      'startCasting() called for playerId: $playerId, device: ${device?.name ?? 'show picker'}',
      tag: 'MethodChannel',
    );
    final result = await _methodChannel.invokeMethod<bool>('startCasting', {
      'playerId': playerId,
      if (device != null) 'device': _encodeCastDevice(device),
    });
    return result ?? false;
  }

  @override
  Future<bool> stopCasting(int playerId) async {
    ProVideoPlayerLogger.log('stopCasting() called for playerId: $playerId', tag: 'MethodChannel');
    final result = await _methodChannel.invokeMethod<bool>('stopCasting', {'playerId': playerId});
    return result ?? false;
  }

  @override
  Future<CastState> getCastState(int playerId) async {
    final result = await _methodChannel.invokeMethod<String>('getCastState', {'playerId': playerId});
    return _parseCastState(result);
  }

  @override
  Future<CastDevice?> getCurrentCastDevice(int playerId) async {
    final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getCurrentCastDevice', {
      'playerId': playerId,
    });
    if (result == null || result.isEmpty) {
      return null;
    }
    return _parseCastDevice(result);
  }

  /// Encodes a [CastDevice] to a map for method channel communication.
  Map<String, dynamic> _encodeCastDevice(CastDevice device) => {
    'id': device.id,
    'name': device.name,
    'type': device.type.name,
  };

  /// Parses a cast device map into a [CastDevice].
  CastDevice _parseCastDevice(Map<dynamic, dynamic> device) => CastDevice(
    id: device['id'] as String,
    name: device['name'] as String,
    type: _parseCastDeviceType(device['type'] as String?),
  );

  /// Parses a list of cast devices.
  List<CastDevice> _parseCastDevices(List<dynamic> devices) =>
      devices.map((d) => _parseCastDevice(d as Map<dynamic, dynamic>)).toList();

  /// Parses a cast state string into a [CastState].
  CastState _parseCastState(String? state) => switch (state) {
    'notConnected' => CastState.notConnected,
    'connecting' => CastState.connecting,
    'connected' => CastState.connected,
    'disconnecting' => CastState.disconnecting,
    _ => CastState.notConnected,
  };

  /// Parses a cast device type string into a [CastDeviceType].
  CastDeviceType _parseCastDeviceType(String? type) => switch (type) {
    'airPlay' => CastDeviceType.airPlay,
    'chromecast' => CastDeviceType.chromecast,
    'webRemotePlayback' => CastDeviceType.webRemotePlayback,
    _ => CastDeviceType.unknown,
  };

  // ==================== External Subtitles ====================

  @override
  Future<ExternalSubtitleTrack?> addExternalSubtitle(int playerId, SubtitleSource source) async {
    // Auto-detect format from path if not provided
    final resolvedFormat = source.format ?? SubtitleFormat.fromUrl(source.path);
    if (resolvedFormat == null) {
      throw ArgumentError('Could not detect subtitle format from path. Please provide the format explicitly.');
    }

    ProVideoPlayerLogger.log(
      'addExternalSubtitle() called for playerId: $playerId, '
      'sourceType: ${source.sourceType}, path: ${source.path}, format: ${resolvedFormat.name}',
      tag: 'MethodChannel',
    );

    // Load and process subtitle content in Dart for both rendering modes
    List<SubtitleCue>? cues;
    String? webvttContent;

    try {
      // Parse subtitle to get cues (for Flutter rendering mode)
      cues = await subtitleLoader.loadSubtitles(source);
      ProVideoPlayerLogger.log(
        'Successfully parsed ${cues.length} subtitle cues from ${source.path}',
        tag: 'MethodChannel',
      );

      // Convert to WebVTT format (for native rendering mode)
      // Native platform will use this if in native rendering mode
      webvttContent = await subtitleLoader.loadAndConvertToWebVTT(source);
      ProVideoPlayerLogger.log(
        'Successfully converted subtitle to WebVTT format (${webvttContent.length} chars)',
        tag: 'MethodChannel',
      );
    } catch (e) {
      ProVideoPlayerLogger.log('Failed to load/parse subtitle from ${source.path}: $e', tag: 'MethodChannel');
      // Continue with null cues/content - native platform may still be able to load from path
    }

    // Pass subtitle info and WebVTT content to native platform
    // Native decides whether to use WebVTT content based on its current render mode:
    // - Native mode: Uses webvttContent for rendering
    // - Flutter mode: Ignores webvttContent, relies on cues from Dart
    final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('addExternalSubtitle', {
      'playerId': playerId,
      'sourceType': source.sourceType,
      'path': source.path,
      'format': resolvedFormat.name,
      'label': source.label,
      'language': source.language,
      'isDefault': source.isDefault,
      // Pass WebVTT content for native rendering mode support
      if (webvttContent != null) 'webvttContent': webvttContent,
    });

    if (result == null) {
      return null;
    }

    // Parse the track and add the cues we parsed
    final track = _parseExternalSubtitleTrack(result);

    // If we successfully parsed cues, return a new track with the cues included
    if (cues != null) {
      return ExternalSubtitleTrack(
        id: track.id,
        label: track.label,
        language: track.language,
        isDefault: track.isDefault,
        path: track.path,
        sourceType: track.sourceType,
        format: track.format,
        cues: cues, // Add the parsed cues for Flutter rendering mode
      );
    }

    // Return track without cues if parsing failed
    return track;
  }

  @override
  Future<bool> removeExternalSubtitle(int playerId, String trackId) async {
    ProVideoPlayerLogger.log(
      'removeExternalSubtitle() called for playerId: $playerId, trackId: $trackId',
      tag: 'MethodChannel',
    );

    final result = await _methodChannel.invokeMethod<bool>('removeExternalSubtitle', {
      'playerId': playerId,
      'trackId': trackId,
    });

    return result ?? false;
  }

  @override
  Future<List<ExternalSubtitleTrack>> getExternalSubtitles(int playerId) async {
    ProVideoPlayerLogger.log('getExternalSubtitles() called for playerId: $playerId', tag: 'MethodChannel');

    final result = await _methodChannel.invokeMethod<List<dynamic>>('getExternalSubtitles', {'playerId': playerId});

    if (result == null || result.isEmpty) {
      return [];
    }

    return result.map((t) => _parseExternalSubtitleTrack(t as Map<dynamic, dynamic>)).toList();
  }

  /// Parses an external subtitle track map into an [ExternalSubtitleTrack].
  ExternalSubtitleTrack _parseExternalSubtitleTrack(Map<dynamic, dynamic> track) {
    final formatStr = track['format'] as String?;
    final format = SubtitleFormat.values.firstWhere(
      (f) => f.name == formatStr,
      orElse: () => SubtitleFormat.srt, // Default fallback
    );

    return ExternalSubtitleTrack(
      id: track['id'] as String,
      label: track['label'] as String? ?? 'External',
      path: track['path'] as String? ?? track['url'] as String, // Support both for backwards compat
      sourceType: track['sourceType'] as String? ?? 'network',
      format: format,
      language: track['language'] as String?,
      isDefault: track['isDefault'] as bool? ?? false,
    );
  }

  // ==================== Window Fullscreen ====================

  @override
  Future<void> setWindowFullscreen({required bool fullscreen}) async {
    ProVideoPlayerLogger.log('setWindowFullscreen() called: $fullscreen', tag: 'MethodChannel');
    await _methodChannel.invokeMethod<void>('setWindowFullscreen', {'fullscreen': fullscreen});
  }
}
