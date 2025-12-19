import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// The iOS implementation of [ProVideoPlayerPlatform].
///
/// This class uses AVPlayer for video playback on iOS.
class ProVideoPlayerIOS extends PigeonMethodChannelBase {
  /// Constructs a ProVideoPlayerIOS.
  ProVideoPlayerIOS() : super('pro_video_player_ios');

  /// Registers this class as the default instance of [ProVideoPlayerPlatform].
  static void registerWith() {
    ProVideoPlayerPlatform.instance = ProVideoPlayerIOS();
  }

  // Event stream controllers (one per player)
  final Map<int, Stream<VideoPlayerEvent>> _eventStreams = {};
  final Map<int, EventChannel> _eventChannels = {};

  @override
  Stream<VideoPlayerEvent> events(int playerId) {
    final stream = _eventStreams[playerId];
    if (stream == null) {
      throw StateError('Player $playerId has not been created');
    }
    return stream;
  }

  @override
  Future<int> create({required VideoSource source, VideoPlayerOptions options = const VideoPlayerOptions()}) async {
    final playerId = await super.create(source: source, options: options);
    _setupEventChannel(playerId);
    return playerId;
  }

  @override
  Future<void> dispose(int playerId) async {
    _eventChannels.remove(playerId);
    _eventStreams.remove(playerId);
    await super.dispose(playerId);
  }

  /// Sets up the event channel for a player.
  void _setupEventChannel(int playerId) {
    final eventChannel = EventChannel('dev.pro_video_player.$channelPrefix/events/$playerId');
    _eventChannels[playerId] = eventChannel;

    _eventStreams[playerId] = eventChannel.receiveBroadcastStream().transform(
      StreamTransformer<dynamic, VideoPlayerEvent>.fromHandlers(
        handleData: (event, sink) {
          if (event is Map<dynamic, dynamic>) {
            final parsed = EventParser.parseEvent(event);
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

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) => UiKitView(
    viewType: 'dev.pro_video_player.ios/video_view',
    creationParams: {'playerId': playerId, 'controlsMode': controlsMode.name},
    creationParamsCodec: const StandardMessageCodec(),
  );
}
