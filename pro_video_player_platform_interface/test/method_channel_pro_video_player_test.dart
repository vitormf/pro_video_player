import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'test_method_channel_platform.dart';

/// Helper extension to get typed arguments from MethodCall.
extension MethodCallArgs on MethodCall {
  Map<String, dynamic> get args => Map<String, dynamic>.from(arguments as Map<Object?, Object?>);
  Map<String, dynamic> get sourceArg => Map<String, dynamic>.from(args['source'] as Map<Object?, Object?>);
  Map<String, dynamic> get optionsArg => Map<String, dynamic>.from(args['options'] as Map<Object?, Object?>);
  Map<String, dynamic>? get trackArg =>
      args['track'] != null ? Map<String, dynamic>.from(args['track'] as Map<Object?, Object?>) : null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('com.example.pro_video_player/methods');
  late TestMethodChannelPlatform plugin;
  late List<MethodCall> log;

  setUp(() {
    plugin = TestMethodChannelPlatform();
    log = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (
      call,
    ) async {
      log.add(call);
      switch (call.method) {
        case 'create':
          return 1;
        case 'getPosition':
          return 30000;
        case 'getDuration':
          return 120000;
        case 'enterPip':
        case 'isPipSupported':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, null);
  });

  group('TestMethodChannelPlatform', () {
    group('create', () {
      test('creates player with network source', () async {
        final playerId = await plugin.create(source: const VideoSource.network('https://example.com/video.mp4'));

        expect(playerId, equals(1));
        expect(log, hasLength(1));
        expect(log.last.method, equals('create'));
        expect(log.last.sourceArg['type'], equals('network'));
        expect(log.last.sourceArg['url'], equals('https://example.com/video.mp4'));
      });

      test('creates player with file source', () async {
        final playerId = await plugin.create(source: const VideoSource.file('/path/to/video.mp4'));

        expect(playerId, equals(1));
        expect(log.last.sourceArg['type'], equals('file'));
        expect(log.last.sourceArg['path'], equals('/path/to/video.mp4'));
      });

      test('creates player with asset source', () async {
        final playerId = await plugin.create(source: const VideoSource.asset('assets/video.mp4'));

        expect(playerId, equals(1));
        expect(log.last.sourceArg['type'], equals('asset'));
        expect(log.last.sourceArg['assetPath'], equals('assets/video.mp4'));
      });

      test('creates player with custom options', () async {
        await plugin.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(
            autoPlay: true,
            looping: true,
            volume: 0.8,
            playbackSpeed: 1.5,
            allowBackgroundPlayback: true,
            mixWithOthers: true,
          ),
        );

        expect(log.last.optionsArg['autoPlay'], isTrue);
        expect(log.last.optionsArg['looping'], isTrue);
        expect(log.last.optionsArg['volume'], equals(0.8));
        expect(log.last.optionsArg['playbackSpeed'], equals(1.5));
        expect(log.last.optionsArg['allowBackgroundPlayback'], isTrue);
        expect(log.last.optionsArg['mixWithOthers'], isTrue);
      });

      test('creates player with headers for network source', () async {
        await plugin.create(
          source: const VideoSource.network(
            'https://example.com/video.mp4',
            headers: {'Authorization': 'Bearer token123'},
          ),
        );

        final headers = log.last.sourceArg['headers'] as Map<Object?, Object?>?;
        expect(headers, isNotNull);
        expect(headers!['Authorization'], equals('Bearer token123'));
      });

      test('throws PlatformException when create returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel,
          (call) async => null,
        );

        expect(
          () => plugin.create(source: const VideoSource.network('https://example.com/video.mp4')),
          throwsA(isA<PlatformException>()),
        );
      });
    });

    group('playback control', () {
      test('play calls native method', () async {
        await plugin.play(1);

        expect(log.last.method, equals('play'));
        expect(log.last.args['playerId'], equals(1));
      });

      test('pause calls native method', () async {
        await plugin.pause(1);

        expect(log.last.method, equals('pause'));
        expect(log.last.args['playerId'], equals(1));
      });

      test('stop calls native method', () async {
        await plugin.stop(1);

        expect(log.last.method, equals('stop'));
        expect(log.last.args['playerId'], equals(1));
      });

      test('seekTo calls native method with milliseconds', () async {
        await plugin.seekTo(1, const Duration(seconds: 30));

        expect(log.last.method, equals('seekTo'));
        expect(log.last.args['playerId'], equals(1));
        expect(log.last.args['position'], equals(30000));
      });

      test('dispose calls native method and cleans up', () async {
        // First create a player to set up event controllers
        await plugin.create(source: const VideoSource.network('https://example.com/video.mp4'));

        await plugin.dispose(1);

        expect(log.last.method, equals('dispose'));
        expect(log.last.args['playerId'], equals(1));
      });
    });

    group('settings', () {
      test('setPlaybackSpeed calls native method', () async {
        await plugin.setPlaybackSpeed(1, 1.5);

        expect(log.last.method, equals('setPlaybackSpeed'));
        expect(log.last.args['playerId'], equals(1));
        expect(log.last.args['speed'], equals(1.5));
      });

      test('setVolume calls native method', () async {
        await plugin.setVolume(1, 0.7);

        expect(log.last.method, equals('setVolume'));
        expect(log.last.args['playerId'], equals(1));
        expect(log.last.args['volume'], equals(0.7));
      });

      test('setLooping calls native method', () async {
        await plugin.setLooping(1, looping: true);

        expect(log.last.method, equals('setLooping'));
        expect(log.last.args['playerId'], equals(1));
        expect(log.last.args['looping'], isTrue);
      });

      test('setSubtitleTrack calls native method with track', () async {
        await plugin.setSubtitleTrack(
          1,
          const SubtitleTrack(id: 'en', label: 'English', language: 'en', isDefault: true),
        );

        expect(log.last.method, equals('setSubtitleTrack'));
        expect(log.last.args['playerId'], equals(1));
        expect(log.last.trackArg!['id'], equals('en'));
        expect(log.last.trackArg!['label'], equals('English'));
        expect(log.last.trackArg!['language'], equals('en'));
        expect(log.last.trackArg!['isDefault'], isTrue);
      });

      test('setSubtitleTrack calls native method with null', () async {
        await plugin.setSubtitleTrack(1, null);

        expect(log.last.method, equals('setSubtitleTrack'));
        expect(log.last.trackArg, isNull);
      });
    });

    group('getters', () {
      test('getPosition returns duration from native', () async {
        final position = await plugin.getPosition(1);

        expect(position, equals(const Duration(seconds: 30)));
        expect(log.last.method, equals('getPosition'));
      });

      test('getPosition returns zero when native returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel,
          (call) async => null,
        );

        final position = await plugin.getPosition(1);

        expect(position, equals(Duration.zero));
      });

      test('getDuration returns duration from native', () async {
        final duration = await plugin.getDuration(1);

        expect(duration, equals(const Duration(minutes: 2)));
        expect(log.last.method, equals('getDuration'));
      });

      test('getDuration returns zero when native returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel,
          (call) async => null,
        );

        final duration = await plugin.getDuration(1);

        expect(duration, equals(Duration.zero));
      });
    });

    group('PiP', () {
      test('enterPip calls native method', () async {
        final result = await plugin.enterPip(1);

        expect(result, isTrue);
        expect(log.last.method, equals('enterPip'));
        expect(log.last.args['playerId'], equals(1));
      });

      test('enterPip passes options', () async {
        await plugin.enterPip(1, options: const PipOptions(aspectRatio: 1.78, autoEnterOnBackground: true));

        expect(log.last.args['aspectRatio'], equals(1.78));
        expect(log.last.args['autoEnterOnBackground'], isTrue);
      });

      test('enterPip returns false when native returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel,
          (call) async => null,
        );

        final result = await plugin.enterPip(1);

        expect(result, isFalse);
      });

      test('exitPip calls native method', () async {
        await plugin.exitPip(1);

        expect(log.last.method, equals('exitPip'));
        expect(log.last.args['playerId'], equals(1));
      });

      test('isPipSupported returns native result', () async {
        final result = await plugin.isPipSupported();

        expect(result, isTrue);
        expect(log.last.method, equals('isPipSupported'));
      });

      test('isPipSupported returns false when native returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel,
          (call) async => null,
        );

        final result = await plugin.isPipSupported();

        expect(result, isFalse);
      });
    });

    group('fullscreen', () {
      test('enterFullscreen calls native method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (
          call,
        ) async {
          log.add(call);
          if (call.method == 'enterFullscreen') return true;
          return null;
        });

        final result = await plugin.enterFullscreen(1);

        expect(result, isTrue);
        expect(log.last.method, equals('enterFullscreen'));
        expect(log.last.args['playerId'], equals(1));
      });

      test('enterFullscreen returns false when native returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel,
          (call) async => null,
        );

        final result = await plugin.enterFullscreen(1);

        expect(result, isFalse);
      });

      test('exitFullscreen calls native method', () async {
        await plugin.exitFullscreen(1);

        expect(log.last.method, equals('exitFullscreen'));
        expect(log.last.args['playerId'], equals(1));
      });
    });

    group('events', () {
      test('events throws StateError for uncreated player', () {
        expect(() => plugin.events(999), throwsA(isA<StateError>()));
      });

      test('events returns stream after create', () async {
        await plugin.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final stream = plugin.events(1);

        expect(stream, isA<Stream<VideoPlayerEvent>>());
      });

      test('events stream is broadcast', () async {
        await plugin.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final stream = plugin.events(1);
        // Broadcast streams can have multiple listeners
        final sub1 = stream.listen((_) {});
        final sub2 = stream.listen((_) {});

        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        await sub1.cancel();
        await sub2.cancel();
      });
    });

    group('buildView', () {
      testWidgets('returns platform view widget with default controlsMode', (tester) async {
        final widget = plugin.buildView(1);

        // The widget should be a platform-specific view or fallback
        expect(widget, isA<Widget>());
      });

      testWidgets('returns platform view widget with native controlsMode', (tester) async {
        final widget = plugin.buildView(1, controlsMode: ControlsMode.native);

        // The widget should be a platform-specific view or fallback
        expect(widget, isA<Widget>());
      });

      testWidgets('passes controlsMode in creation params', (tester) async {
        // Test that both modes are passed correctly
        final noneWidget = plugin.buildView(1);
        final nativeWidget = plugin.buildView(1, controlsMode: ControlsMode.native);

        expect(noneWidget, isA<Widget>());
        expect(nativeWidget, isA<Widget>());
      });
    });

    group('event parsing', () {
      late EventChannel eventChannel;
      late StreamController<dynamic> nativeEventController;

      setUp(() async {
        // Create a fresh plugin for event parsing tests
        plugin = TestMethodChannelPlatform();
        log = [];

        // Setup method channel mock
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (
          call,
        ) async {
          log.add(call);
          if (call.method == 'create') return 1;
          return null;
        });

        // Setup event channel mock
        nativeEventController = StreamController<dynamic>.broadcast();
        eventChannel = const EventChannel('com.example.pro_video_player/events/1');

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (args, events) {
              nativeEventController.stream.listen(
                events.success,
                onError: (Object error) => events.error(code: 'ERROR', message: error.toString()),
                onDone: events.endOfStream,
              );
            },
          ),
        );

        // Create a player to set up event handling
        await plugin.create(source: const VideoSource.network('https://example.com/video.mp4'));
      });

      tearDown(() async {
        await nativeEventController.close();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(eventChannel, null);
      });

      test('parses playbackStateChanged event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'playbackStateChanged', 'state': 'playing'});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<PlaybackStateChangedEvent>());
        expect((events.first as PlaybackStateChangedEvent).state, equals(PlaybackState.playing));

        await sub.cancel();
      });

      test('parses all playback states', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        final states = [
          'uninitialized',
          'initializing',
          'ready',
          'playing',
          'paused',
          'completed',
          'buffering',
          'error',
          'disposed',
          'unknown_state', // Should default to uninitialized
        ];

        for (final state in states) {
          nativeEventController.add({'type': 'playbackStateChanged', 'state': state});
          await Future<void>.delayed(Duration.zero);
        }

        expect(events, hasLength(states.length));
        expect((events[0] as PlaybackStateChangedEvent).state, equals(PlaybackState.uninitialized));
        expect((events[1] as PlaybackStateChangedEvent).state, equals(PlaybackState.initializing));
        expect((events[2] as PlaybackStateChangedEvent).state, equals(PlaybackState.ready));
        expect((events[3] as PlaybackStateChangedEvent).state, equals(PlaybackState.playing));
        expect((events[4] as PlaybackStateChangedEvent).state, equals(PlaybackState.paused));
        expect((events[5] as PlaybackStateChangedEvent).state, equals(PlaybackState.completed));
        expect((events[6] as PlaybackStateChangedEvent).state, equals(PlaybackState.buffering));
        expect((events[7] as PlaybackStateChangedEvent).state, equals(PlaybackState.error));
        expect((events[8] as PlaybackStateChangedEvent).state, equals(PlaybackState.disposed));
        expect((events[9] as PlaybackStateChangedEvent).state, equals(PlaybackState.uninitialized));

        await sub.cancel();
      });

      test('parses positionChanged event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'positionChanged', 'position': 30000});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<PositionChangedEvent>());
        expect((events.first as PositionChangedEvent).position, equals(const Duration(seconds: 30)));

        await sub.cancel();
      });

      test('parses bufferedPositionChanged event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'bufferedPositionChanged', 'bufferedPosition': 60000});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<BufferedPositionChangedEvent>());
        expect((events.first as BufferedPositionChangedEvent).bufferedPosition, equals(const Duration(seconds: 60)));

        await sub.cancel();
      });

      test('parses durationChanged event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'durationChanged', 'duration': 120000});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<DurationChangedEvent>());
        expect((events.first as DurationChangedEvent).duration, equals(const Duration(minutes: 2)));

        await sub.cancel();
      });

      test('parses playbackCompleted event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'playbackCompleted'});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<PlaybackCompletedEvent>());

        await sub.cancel();
      });

      test('parses error event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'error', 'message': 'Playback failed', 'code': 'ERR_001'});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<ErrorEvent>());
        final errorEvent = events.first as ErrorEvent;
        expect(errorEvent.message, equals('Playback failed'));
        expect(errorEvent.code, equals('ERR_001'));

        await sub.cancel();
      });

      test('parses videoSizeChanged event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'videoSizeChanged', 'width': 1920, 'height': 1080});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<VideoSizeChangedEvent>());
        final sizeEvent = events.first as VideoSizeChangedEvent;
        expect(sizeEvent.width, equals(1920));
        expect(sizeEvent.height, equals(1080));

        await sub.cancel();
      });

      test('parses subtitleTracksChanged event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({
          'type': 'subtitleTracksChanged',
          'tracks': [
            {'id': 'en', 'label': 'English', 'language': 'en', 'isDefault': true},
            {'id': 'es', 'label': 'Spanish', 'language': 'es', 'isDefault': false},
          ],
        });
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<SubtitleTracksChangedEvent>());
        final tracksEvent = events.first as SubtitleTracksChangedEvent;
        expect(tracksEvent.tracks, hasLength(2));
        expect(tracksEvent.tracks[0].id, equals('en'));
        expect(tracksEvent.tracks[0].label, equals('English'));
        expect(tracksEvent.tracks[0].language, equals('en'));
        expect(tracksEvent.tracks[0].isDefault, isTrue);
        expect(tracksEvent.tracks[1].id, equals('es'));
        expect(tracksEvent.tracks[1].isDefault, isFalse);

        await sub.cancel();
      });

      test('parses subtitleTracksChanged with minimal track data', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({
          'type': 'subtitleTracksChanged',
          'tracks': [
            {'id': 'track1', 'label': 'Track 1', 'language': null}, // No isDefault
          ],
        });
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        final tracksEvent = events.first as SubtitleTracksChangedEvent;
        expect(tracksEvent.tracks[0].isDefault, isFalse); // Default to false

        await sub.cancel();
      });

      test('parses selectedSubtitleChanged event with track', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({
          'type': 'selectedSubtitleChanged',
          'track': {'id': 'en', 'label': 'English', 'language': 'en', 'isDefault': true},
        });
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<SelectedSubtitleChangedEvent>());
        final selectedEvent = events.first as SelectedSubtitleChangedEvent;
        expect(selectedEvent.track, isNotNull);
        expect(selectedEvent.track!.id, equals('en'));

        await sub.cancel();
      });

      test('parses selectedSubtitleChanged event with null track', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'selectedSubtitleChanged', 'track': null});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        final selectedEvent = events.first as SelectedSubtitleChangedEvent;
        expect(selectedEvent.track, isNull);

        await sub.cancel();
      });

      test('parses pipStateChanged event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'pipStateChanged', 'isActive': true});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<PipStateChangedEvent>());
        expect((events.first as PipStateChangedEvent).isActive, isTrue);

        await sub.cancel();
      });

      test('parses fullscreenStateChanged event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'fullscreenStateChanged', 'isFullscreen': true});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<FullscreenStateChangedEvent>());
        expect((events.first as FullscreenStateChangedEvent).isFullscreen, isTrue);

        await sub.cancel();
      });

      test('parses playbackSpeedChanged event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'playbackSpeedChanged', 'speed': 1.5});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<PlaybackSpeedChangedEvent>());
        expect((events.first as PlaybackSpeedChangedEvent).speed, equals(1.5));

        await sub.cancel();
      });

      test('parses volumeChanged event', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'volumeChanged', 'volume': 0.7});
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<VolumeChangedEvent>());
        expect((events.first as VolumeChangedEvent).volume, equals(0.7));

        await sub.cancel();
      });

      test('ignores unknown event types', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'type': 'unknownEventType', 'data': 'some data'});
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);

        await sub.cancel();
      });

      test('ignores events without type', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add({'data': 'some data'});
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);

        await sub.cancel();
      });

      test('ignores non-Map events', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.add('not a map');
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);

        await sub.cancel();
      });

      test('converts event channel errors to ErrorEvent', () async {
        final events = <VideoPlayerEvent>[];
        final sub = plugin.events(1).listen(events.add);

        nativeEventController.addError('Native error occurred');
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.first, isA<ErrorEvent>());
        expect((events.first as ErrorEvent).message, contains('Native error occurred'));

        await sub.cancel();
      });
    });
  });
}
