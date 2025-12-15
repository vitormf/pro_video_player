import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_ios/pro_video_player_ios.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:pro_video_player_platform_interface/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProVideoPlayerIOS plugin;
  late MethodChannelTestHarness harness;

  setUp(() {
    plugin = ProVideoPlayerIOS();
    harness = MethodChannelTestHarness(channelName: 'com.example.pro_video_player_ios/methods')..setUp();
  });

  tearDown(() {
    harness.tearDown();
  });

  group('ProVideoPlayerIOS', () {
    test('registerWith registers the instance', () {
      ProVideoPlayerIOS.registerWith();
      expect(ProVideoPlayerPlatform.instance, isA<ProVideoPlayerIOS>());
    });

    group('create', () {
      test('creates player with network source', () async {
        final playerId = await plugin.create(source: const VideoSource.network('https://example.com/video.mp4'));

        expect(playerId, equals(1));
        expect(harness.log, hasLength(1));
        expect(harness.lastCall.method, equals('create'));
        expect(harness.lastCall.sourceArg['type'], equals('network'));
        expect(harness.lastCall.sourceArg['url'], equals('https://example.com/video.mp4'));
      });

      test('creates player with file source', () async {
        final playerId = await plugin.create(source: const VideoSource.file('/path/to/video.mp4'));

        expect(playerId, equals(1));
        expect(harness.lastCall.sourceArg['type'], equals('file'));
        expect(harness.lastCall.sourceArg['path'], equals('/path/to/video.mp4'));
      });

      test('creates player with asset source', () async {
        final playerId = await plugin.create(source: const VideoSource.asset('assets/video.mp4'));

        expect(playerId, equals(1));
        expect(harness.lastCall.sourceArg['type'], equals('asset'));
        expect(harness.lastCall.sourceArg['assetPath'], equals('assets/video.mp4'));
      });

      test('creates player with custom options', () async {
        await plugin.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(autoPlay: true, looping: true, volume: 0.8, playbackSpeed: 1.5),
        );

        expect(harness.lastCall.optionsArg['autoPlay'], isTrue);
        expect(harness.lastCall.optionsArg['looping'], isTrue);
        expect(harness.lastCall.optionsArg['volume'], equals(0.8));
        expect(harness.lastCall.optionsArg['playbackSpeed'], equals(1.5));
      });

      test('creates player with bufferingTier option', () async {
        await plugin.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(bufferingTier: BufferingTier.high),
        );

        expect(harness.lastCall.optionsArg['bufferingTier'], equals('high'));
      });

      test('creates player with default bufferingTier as medium', () async {
        await plugin.create(source: const VideoSource.network('https://example.com/video.mp4'));

        expect(harness.lastCall.optionsArg['bufferingTier'], equals('medium'));
      });

      test('throws PlatformException when create returns null', () async {
        harness.setNullResponses();

        expect(
          () => plugin.create(source: const VideoSource.network('https://example.com/video.mp4')),
          throwsA(isA<PlatformException>()),
        );
      });
    });

    group('playback control', () {
      test('play calls native method', () async {
        await plugin.play(1);

        expect(harness.lastCall.method, equals('play'));
        expect(harness.lastCall.args['playerId'], equals(1));
      });

      test('pause calls native method', () async {
        await plugin.pause(1);

        expect(harness.lastCall.method, equals('pause'));
        expect(harness.lastCall.args['playerId'], equals(1));
      });

      test('stop calls native method', () async {
        await plugin.stop(1);

        expect(harness.lastCall.method, equals('stop'));
        expect(harness.lastCall.args['playerId'], equals(1));
      });

      test('seekTo calls native method with milliseconds', () async {
        await plugin.seekTo(1, const Duration(seconds: 30));

        expect(harness.lastCall.method, equals('seekTo'));
        expect(harness.lastCall.args['playerId'], equals(1));
        expect(harness.lastCall.args['position'], equals(30000));
      });

      test('dispose calls native method', () async {
        await plugin.dispose(1);

        expect(harness.lastCall.method, equals('dispose'));
        expect(harness.lastCall.args['playerId'], equals(1));
      });
    });

    group('settings', () {
      test('setPlaybackSpeed calls native method', () async {
        await plugin.setPlaybackSpeed(1, 1.5);

        expect(harness.lastCall.method, equals('setPlaybackSpeed'));
        expect(harness.lastCall.args['playerId'], equals(1));
        expect(harness.lastCall.args['speed'], equals(1.5));
      });

      test('setVolume calls native method', () async {
        await plugin.setVolume(1, 0.7);

        expect(harness.lastCall.method, equals('setVolume'));
        expect(harness.lastCall.args['playerId'], equals(1));
        expect(harness.lastCall.args['volume'], equals(0.7));
      });

      test('setLooping calls native method', () async {
        await plugin.setLooping(1, looping: true);

        expect(harness.lastCall.method, equals('setLooping'));
        expect(harness.lastCall.args['playerId'], equals(1));
        expect(harness.lastCall.args['looping'], isTrue);
      });

      test('setSubtitleTrack calls native method with track', () async {
        await plugin.setSubtitleTrack(1, const SubtitleTrack(id: 'en', label: 'English', language: 'en'));

        expect(harness.lastCall.method, equals('setSubtitleTrack'));
        expect(harness.lastCall.args['playerId'], equals(1));
        expect(harness.lastCall.trackArg!['id'], equals('en'));
        expect(harness.lastCall.trackArg!['label'], equals('English'));
      });

      test('setSubtitleTrack calls native method with null', () async {
        await plugin.setSubtitleTrack(1, null);

        expect(harness.lastCall.method, equals('setSubtitleTrack'));
        expect(harness.lastCall.trackArg, isNull);
      });
    });

    group('getters', () {
      test('getPosition returns duration from native', () async {
        final position = await plugin.getPosition(1);

        expect(position, equals(const Duration(seconds: 30)));
        expect(harness.lastCall.method, equals('getPosition'));
      });

      test('getPosition returns zero when native returns null', () async {
        harness.setNullResponses();

        final position = await plugin.getPosition(1);

        expect(position, equals(Duration.zero));
      });

      test('getDuration returns duration from native', () async {
        final duration = await plugin.getDuration(1);

        expect(duration, equals(const Duration(minutes: 2)));
        expect(harness.lastCall.method, equals('getDuration'));
      });

      test('getDuration returns zero when native returns null', () async {
        harness.setNullResponses();

        final duration = await plugin.getDuration(1);

        expect(duration, equals(Duration.zero));
      });
    });

    group('PiP', () {
      test('enterPip calls native method', () async {
        final result = await plugin.enterPip(1);

        expect(result, isTrue);
        expect(harness.lastCall.method, equals('enterPip'));
        expect(harness.lastCall.args['playerId'], equals(1));
      });

      test('enterPip passes options', () async {
        await plugin.enterPip(1, options: const PipOptions(aspectRatio: 1.78, autoEnterOnBackground: true));

        expect(harness.lastCall.args['aspectRatio'], equals(1.78));
        expect(harness.lastCall.args['autoEnterOnBackground'], isTrue);
      });

      test('enterPip returns false when native returns null', () async {
        harness.setNullResponses();

        final result = await plugin.enterPip(1);

        expect(result, isFalse);
      });

      test('exitPip calls native method', () async {
        await plugin.exitPip(1);

        expect(harness.lastCall.method, equals('exitPip'));
        expect(harness.lastCall.args['playerId'], equals(1));
      });

      test('isPipSupported returns native result', () async {
        final result = await plugin.isPipSupported();

        expect(result, isTrue);
        expect(harness.lastCall.method, equals('isPipSupported'));
      });

      test('isPipSupported returns false when native returns null', () async {
        harness.setNullResponses();

        final result = await plugin.isPipSupported();

        expect(result, isFalse);
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

    group('dispose', () {
      test('dispose calls native method and cleans up', () async {
        // First create a player to set up event controllers
        await plugin.create(source: const VideoSource.network('https://example.com/video.mp4'));

        await plugin.dispose(1);

        expect(harness.lastCall.method, equals('dispose'));
        expect(harness.lastCall.args['playerId'], equals(1));
      });
    });

    group('buildView', () {
      test('returns UiKitView with correct parameters', () {
        final widget = plugin.buildView(1);

        expect(widget, isA<UiKitView>());
      });
    });
  });
}
