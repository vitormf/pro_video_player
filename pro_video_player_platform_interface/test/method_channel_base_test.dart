// ignore_for_file: deprecated_member_use_from_same_package

// ignore_for_file: avoid_dynamic_calls - Necessary: testing method channel communication requires dynamic access to mock method call arguments

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Test implementation of [MethodChannelBase].
class TestMethodChannelPlatform extends MethodChannelBase {
  TestMethodChannelPlatform() : super('test_platform');

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) => const Text('Test view');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestMethodChannelPlatform platform;
  late List<MethodCall> methodCallLog;

  setUp(() {
    platform = TestMethodChannelPlatform();
    methodCallLog = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.pro_video_player.test_platform/methods'),
      (methodCall) async {
        methodCallLog.add(methodCall);
        switch (methodCall.method) {
          case 'create':
            return 42;
          case 'getPosition':
            return 1000;
          case 'getDuration':
            return 5000;
          case 'enterPip':
            return true;
          case 'isPipSupported':
            return true;
          case 'enterFullscreen':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.pro_video_player.test_platform/methods'),
      null,
    );
  });

  group('MethodChannelBase', () {
    group('create', () {
      test('calls native create method with network source', () async {
        final playerId = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        expect(playerId, 42);
        expect(methodCallLog.length, 1);
        expect(methodCallLog[0].method, 'create');
        expect(methodCallLog[0].arguments['source']['type'], 'network');
        expect(methodCallLog[0].arguments['source']['url'], 'https://example.com/video.mp4');
      });

      test('calls native create method with file source', () async {
        await platform.create(source: const VideoSource.file('/path/to/video.mp4'));

        expect(methodCallLog[0].arguments['source']['type'], 'file');
        expect(methodCallLog[0].arguments['source']['path'], '/path/to/video.mp4');
      });

      test('calls native create method with asset source', () async {
        await platform.create(source: const VideoSource.asset('assets/video.mp4'));

        expect(methodCallLog[0].arguments['source']['type'], 'asset');
        expect(methodCallLog[0].arguments['source']['assetPath'], 'assets/video.mp4');
      });

      test('passes options correctly', () async {
        await platform.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(
            autoPlay: true,
            looping: true,
            volume: 0.5,
            playbackSpeed: 1.5,
            allowBackgroundPlayback: true,
            mixWithOthers: true,
          ),
        );

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['autoPlay'], true);
        expect(options['looping'], true);
        expect(options['volume'], 0.5);
        expect(options['playbackSpeed'], 1.5);
        expect(options['allowBackgroundPlayback'], true);
        expect(options['mixWithOthers'], true);
      });

      test('passes bufferingTier correctly', () async {
        await platform.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(bufferingTier: BufferingTier.high),
        );

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['bufferingTier'], 'high');
      });

      test('passes default bufferingTier as medium', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['bufferingTier'], 'medium');
      });

      test('passes abrMode correctly', () async {
        await platform.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(abrMode: AbrMode.manual),
        );

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['abrMode'], 'manual');
      });

      test('passes default abrMode as auto', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['abrMode'], 'auto');
      });

      test('passes minBitrate correctly', () async {
        await platform.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(minBitrate: 500000),
        );

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['minBitrate'], 500000);
      });

      test('passes maxBitrate correctly', () async {
        await platform.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(maxBitrate: 5000000),
        );

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['maxBitrate'], 5000000);
      });

      test('passes null minBitrate when not set', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['minBitrate'], isNull);
      });

      test('passes null maxBitrate when not set', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['maxBitrate'], isNull);
      });

      test('passes all ABR options together', () async {
        await platform.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(minBitrate: 1000000, maxBitrate: 8000000),
        );

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['abrMode'], 'auto');
        expect(options['minBitrate'], 1000000);
        expect(options['maxBitrate'], 8000000);
      });

      test('passes subtitleRenderMode correctly', () async {
        await platform.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(subtitleRenderMode: SubtitleRenderMode.flutter),
        );

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        // Legacy field still sent for backward compatibility
        expect(options['renderEmbeddedSubtitlesInFlutter'], true);
      });

      test('passes default renderEmbeddedSubtitlesInFlutter as false', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final options = methodCallLog[0].arguments['options'] as Map<Object?, Object?>;
        expect(options['renderEmbeddedSubtitlesInFlutter'], false);
      });

      test('throws when create returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('dev.pro_video_player.test_platform/methods'),
          (methodCall) async => null,
        );

        expect(
          () => platform.create(source: const VideoSource.network('https://example.com/video.mp4')),
          throwsA(isA<PlatformException>()),
        );
      });
    });

    group('dispose', () {
      test('calls native dispose method', () async {
        await platform.dispose(42);

        expect(methodCallLog.length, 1);
        expect(methodCallLog[0].method, 'dispose');
        expect(methodCallLog[0].arguments['playerId'], 42);
      });
    });

    group('playback control', () {
      test('play calls native play method', () async {
        await platform.play(42);

        expect(methodCallLog[0].method, 'play');
        expect(methodCallLog[0].arguments['playerId'], 42);
      });

      test('pause calls native pause method', () async {
        await platform.pause(42);

        expect(methodCallLog[0].method, 'pause');
        expect(methodCallLog[0].arguments['playerId'], 42);
      });

      test('stop calls native stop method', () async {
        await platform.stop(42);

        expect(methodCallLog[0].method, 'stop');
        expect(methodCallLog[0].arguments['playerId'], 42);
      });
    });

    group('seek', () {
      test('seekTo calls native method with position', () async {
        await platform.seekTo(42, const Duration(seconds: 10));

        expect(methodCallLog[0].method, 'seekTo');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['position'], 10000);
      });
    });

    group('playback settings', () {
      test('setPlaybackSpeed calls native method', () async {
        await platform.setPlaybackSpeed(42, 1.5);

        expect(methodCallLog[0].method, 'setPlaybackSpeed');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['speed'], 1.5);
      });

      test('setVolume calls native method', () async {
        await platform.setVolume(42, 0.8);

        expect(methodCallLog[0].method, 'setVolume');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['volume'], 0.8);
      });

      test('setLooping calls native method', () async {
        await platform.setLooping(42, true);

        expect(methodCallLog[0].method, 'setLooping');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['looping'], true);
      });
    });

    group('subtitles', () {
      test('setSubtitleTrack calls native method with track', () async {
        const track = SubtitleTrack(id: 'track1', label: 'English', language: 'en', isDefault: true);

        await platform.setSubtitleTrack(42, track);

        expect(methodCallLog[0].method, 'setSubtitleTrack');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['track']['id'], 'track1');
        expect(methodCallLog[0].arguments['track']['label'], 'English');
        expect(methodCallLog[0].arguments['track']['language'], 'en');
        expect(methodCallLog[0].arguments['track']['isDefault'], true);
      });

      test('setSubtitleTrack calls native method with null', () async {
        await platform.setSubtitleTrack(42, null);

        expect(methodCallLog[0].method, 'setSubtitleTrack');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['track'], null);
      });
    });

    group('audio tracks', () {
      test('setAudioTrack calls native method with track', () async {
        const track = AudioTrack(id: 'audio1', label: 'English (5.1)', language: 'en', isDefault: true);

        await platform.setAudioTrack(42, track);

        expect(methodCallLog[0].method, 'setAudioTrack');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['track']['id'], 'audio1');
        expect(methodCallLog[0].arguments['track']['label'], 'English (5.1)');
        expect(methodCallLog[0].arguments['track']['language'], 'en');
        expect(methodCallLog[0].arguments['track']['isDefault'], true);
      });

      test('setAudioTrack calls native method with null', () async {
        await platform.setAudioTrack(42, null);

        expect(methodCallLog[0].method, 'setAudioTrack');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['track'], null);
      });
    });

    group('getters', () {
      test('getPosition returns duration', () async {
        final position = await platform.getPosition(42);

        expect(position, const Duration(milliseconds: 1000));
        expect(methodCallLog[0].method, 'getPosition');
        expect(methodCallLog[0].arguments['playerId'], 42);
      });

      test('getPosition returns zero when native returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('dev.pro_video_player.test_platform/methods'),
          (methodCall) async => null,
        );

        final position = await platform.getPosition(42);
        expect(position, Duration.zero);
      });

      test('getDuration returns duration', () async {
        final duration = await platform.getDuration(42);

        expect(duration, const Duration(milliseconds: 5000));
        expect(methodCallLog[0].method, 'getDuration');
        expect(methodCallLog[0].arguments['playerId'], 42);
      });

      test('getDuration returns zero when native returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('dev.pro_video_player.test_platform/methods'),
          (methodCall) async => null,
        );

        final duration = await platform.getDuration(42);
        expect(duration, Duration.zero);
      });
    });

    group('PiP', () {
      test('enterPip calls native method', () async {
        final result = await platform.enterPip(42);

        expect(result, true);
        expect(methodCallLog[0].method, 'enterPip');
        expect(methodCallLog[0].arguments['playerId'], 42);
      });

      test('enterPip passes options', () async {
        await platform.enterPip(42, options: const PipOptions(aspectRatio: 16 / 9, autoEnterOnBackground: true));

        expect(methodCallLog[0].arguments['aspectRatio'], 16 / 9);
        expect(methodCallLog[0].arguments['autoEnterOnBackground'], true);
      });

      test('enterPip returns false when native returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('dev.pro_video_player.test_platform/methods'),
          (methodCall) async => null,
        );

        final result = await platform.enterPip(42);
        expect(result, false);
      });

      test('exitPip calls native method', () async {
        await platform.exitPip(42);

        expect(methodCallLog[0].method, 'exitPip');
        expect(methodCallLog[0].arguments['playerId'], 42);
      });

      test('isPipSupported returns native result', () async {
        final result = await platform.isPipSupported();

        expect(result, true);
        expect(methodCallLog[0].method, 'isPipSupported');
      });

      test('isPipSupported returns false when native returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('dev.pro_video_player.test_platform/methods'),
          (methodCall) async => null,
        );

        final result = await platform.isPipSupported();
        expect(result, false);
      });
    });

    group('fullscreen', () {
      test('enterFullscreen calls native method', () async {
        final result = await platform.enterFullscreen(42);

        expect(result, true);
        expect(methodCallLog[0].method, 'enterFullscreen');
        expect(methodCallLog[0].arguments['playerId'], 42);
      });

      test('enterFullscreen returns false when native returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('dev.pro_video_player.test_platform/methods'),
          (methodCall) async => null,
        );

        final result = await platform.enterFullscreen(42);
        expect(result, false);
      });

      test('exitFullscreen calls native method', () async {
        await platform.exitFullscreen(42);

        expect(methodCallLog[0].method, 'exitFullscreen');
        expect(methodCallLog[0].arguments['playerId'], 42);
      });
    });

    group('events', () {
      test('events throws StateError for uncreated player', () {
        expect(() => platform.events(42), throwsStateError);
      });

      test('events returns stream after create', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final stream = platform.events(42);
        expect(stream, isA<Stream<VideoPlayerEvent>>());
      });

      test('events stream is broadcast', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

        final stream = platform.events(42);
        expect(stream.isBroadcast, true);
      });
    });

    group('buildView', () {
      test('returns widget', () {
        final widget = platform.buildView(42);
        expect(widget, isA<Widget>());
      });
    });

    group('event parsing', () {
      late StreamController<dynamic> eventController;

      setUp(() {
        eventController = StreamController<dynamic>.broadcast();
        const eventChannel = EventChannel('dev.pro_video_player.test_platform/events/42');

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              eventController.stream.listen(events.success);
            },
          ),
        );
      });

      tearDown(() async {
        await eventController.close();
      });

      test('parses bandwidthEstimateChanged event', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'bandwidthEstimateChanged', 'bandwidth': 5000000});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events[0], isA<BandwidthEstimateChangedEvent>());
        expect((events[0] as BandwidthEstimateChangedEvent).bandwidth, 5000000);
      });

      test('parses bandwidthEstimateChanged with zero bandwidth', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'bandwidthEstimateChanged', 'bandwidth': 0});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect((events[0] as BandwidthEstimateChangedEvent).bandwidth, 0);
      });

      test('parses bandwidthEstimateChanged with null bandwidth defaults to 0', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'bandwidthEstimateChanged', 'bandwidth': null});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect((events[0] as BandwidthEstimateChangedEvent).bandwidth, 0);
      });

      test('parses pipActionTriggered event', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'pipActionTriggered', 'action': 'skipForward'});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events[0], isA<PipActionTriggeredEvent>());
        expect((events[0] as PipActionTriggeredEvent).action, PipActionType.skipForward);
      });

      test('parses pipActionTriggered with playPause action', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'pipActionTriggered', 'action': 'playPause'});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect((events[0] as PipActionTriggeredEvent).action, PipActionType.playPause);
      });

      test('parses pipRestoreUserInterface event', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'pipRestoreUserInterface'});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events[0], isA<PipRestoreUserInterfaceEvent>());
      });

      test('parses playbackStateChanged event', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'playbackStateChanged', 'state': 'playing'});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events[0], isA<PlaybackStateChangedEvent>());
        expect((events[0] as PlaybackStateChangedEvent).state, PlaybackState.playing);
      });

      test('parses positionChanged event', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'positionChanged', 'position': 5000});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events[0], isA<PositionChangedEvent>());
        expect((events[0] as PositionChangedEvent).position, const Duration(milliseconds: 5000));
      });

      test('parses durationChanged event', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'durationChanged', 'duration': 120000});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events[0], isA<DurationChangedEvent>());
        expect((events[0] as DurationChangedEvent).duration, const Duration(milliseconds: 120000));
      });

      test('parses error event', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'error', 'message': 'Playback failed', 'code': 'PLAYBACK_ERROR'});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events[0], isA<ErrorEvent>());
        final errorEvent = events[0] as ErrorEvent;
        expect(errorEvent.message, 'Playback failed');
        expect(errorEvent.code, 'PLAYBACK_ERROR');
      });

      test('parses embeddedSubtitleCue event with cue', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({
          'type': 'embeddedSubtitleCue',
          'text': 'Hello world',
          'startMs': 1000,
          'endMs': 3000,
          'trackId': 'track-1',
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events[0], isA<EmbeddedSubtitleCueEvent>());
        final cueEvent = events[0] as EmbeddedSubtitleCueEvent;
        expect(cueEvent.cue?.text, 'Hello world');
        expect(cueEvent.cue?.start, const Duration(milliseconds: 1000));
        expect(cueEvent.cue?.end, const Duration(milliseconds: 3000));
        expect(cueEvent.trackId, 'track-1');
      });

      test('parses embeddedSubtitleCue event with null text (hides subtitle)', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({
          'type': 'embeddedSubtitleCue',
          'text': null,
          'startMs': null,
          'endMs': null,
          'trackId': 'track-1',
        });

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        expect(events[0], isA<EmbeddedSubtitleCueEvent>());
        final cueEvent = events[0] as EmbeddedSubtitleCueEvent;
        expect(cueEvent.cue, isNull);
        expect(cueEvent.trackId, 'track-1');
      });

      test('parses embeddedSubtitleCue event without trackId', () async {
        await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));
        final events = <VideoPlayerEvent>[];
        platform.events(42).listen(events.add);

        eventController.add({'type': 'embeddedSubtitleCue', 'text': 'Subtitle text', 'startMs': 5000, 'endMs': 7000});

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(events, hasLength(1));
        final cueEvent = events[0] as EmbeddedSubtitleCueEvent;
        expect(cueEvent.cue?.text, 'Subtitle text');
        expect(cueEvent.trackId, isNull);
      });
    });

    group('setSubtitleRenderMode', () {
      test('calls native setSubtitleRenderMode method with native mode', () async {
        await platform.setSubtitleRenderMode(42, SubtitleRenderMode.native);

        expect(methodCallLog.length, 1);
        expect(methodCallLog[0].method, 'setSubtitleRenderMode');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['renderMode'], 'native');
      });

      test('calls native setSubtitleRenderMode method with flutter mode', () async {
        await platform.setSubtitleRenderMode(42, SubtitleRenderMode.flutter);

        expect(methodCallLog.length, 1);
        expect(methodCallLog[0].method, 'setSubtitleRenderMode');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['renderMode'], 'flutter');
      });

      test('calls native setSubtitleRenderMode method with auto mode', () async {
        await platform.setSubtitleRenderMode(42, SubtitleRenderMode.auto);

        expect(methodCallLog.length, 1);
        expect(methodCallLog[0].method, 'setSubtitleRenderMode');
        expect(methodCallLog[0].arguments['playerId'], 42);
        expect(methodCallLog[0].arguments['renderMode'], 'auto');
      });
    });
  });
}
