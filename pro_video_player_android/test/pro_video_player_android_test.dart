import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player_android/pro_video_player_android.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';
import 'package:pro_video_player_platform_interface/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProVideoPlayerAndroid plugin;
  late PigeonTestHarness harness;

  setUp(() {
    plugin = ProVideoPlayerAndroid();
    harness = PigeonTestHarness()..setUp();
  });

  tearDown(() {
    harness.tearDown();
  });

  group('ProVideoPlayerAndroid', () {
    test('registerWith registers the instance', () {
      ProVideoPlayerAndroid.registerWith();
      expect(ProVideoPlayerPlatform.instance, isA<ProVideoPlayerAndroid>());
    });

    group('create', () {
      test('creates player with network source', () async {
        final playerId = await plugin.create(source: const VideoSource.network('https://example.com/video.mp4'));

        expect(playerId, equals(1));
        expect(harness.log, hasLength(1));
        expect(harness.lastCall.method, equals('create'));
        expect(harness.lastCall.source.type, equals(VideoSourceType.network));
        expect(harness.lastCall.source.url, equals('https://example.com/video.mp4'));
      });

      test('creates player with file source', () async {
        final playerId = await plugin.create(source: const VideoSource.file('/path/to/video.mp4'));

        expect(playerId, equals(1));
        expect(harness.lastCall.source.type, equals(VideoSourceType.file));
        expect(harness.lastCall.source.path, equals('/path/to/video.mp4'));
      });

      test('creates player with asset source', () async {
        final playerId = await plugin.create(source: const VideoSource.asset('assets/video.mp4'));

        expect(playerId, equals(1));
        expect(harness.lastCall.source.type, equals(VideoSourceType.asset));
        expect(harness.lastCall.source.assetPath, equals('assets/video.mp4'));
      });

      test('creates player with custom options', () async {
        await plugin.create(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(autoPlay: true, looping: true, volume: 0.8, playbackSpeed: 1.5),
        );

        expect(harness.lastCall.options.autoPlay, isTrue);
        expect(harness.lastCall.options.looping, isTrue);
        expect(harness.lastCall.options.volume, equals(0.8));
        expect(harness.lastCall.options.playbackSpeed, equals(1.5));
      });

      test('creates player with headers for network source', () async {
        await plugin.create(
          source: const VideoSource.network(
            'https://example.com/video.mp4',
            headers: {'Authorization': 'Bearer token123'},
          ),
        );

        expect(harness.lastCall.source.headers, isNotEmpty);
        expect(harness.lastCall.source.headers!['Authorization'], equals('Bearer token123'));
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
        expect(harness.lastCall.playerId, equals(1));
      });

      test('pause calls native method', () async {
        await plugin.pause(1);

        expect(harness.lastCall.method, equals('pause'));
        expect(harness.lastCall.playerId, equals(1));
      });

      test('stop calls native method', () async {
        await plugin.stop(1);

        expect(harness.lastCall.method, equals('stop'));
        expect(harness.lastCall.playerId, equals(1));
      });

      test('seekTo calls native method with milliseconds', () async {
        await plugin.seekTo(1, const Duration(seconds: 30));

        expect(harness.lastCall.method, equals('seekTo'));
        expect(harness.lastCall.playerId, equals(1));
        expect(harness.lastCall.position, equals(30000));
      });

      test('dispose calls native method', () async {
        await plugin.dispose(1);

        expect(harness.lastCall.method, equals('dispose'));
        expect(harness.lastCall.playerId, equals(1));
      });
    });

    group('settings', () {
      test('setPlaybackSpeed calls native method', () async {
        await plugin.setPlaybackSpeed(1, 1.5);

        expect(harness.lastCall.method, equals('setPlaybackSpeed'));
        expect(harness.lastCall.playerId, equals(1));
        expect(harness.lastCall.speed, equals(1.5));
      });

      test('setVolume calls native method', () async {
        await plugin.setVolume(1, 0.7);

        expect(harness.lastCall.method, equals('setVolume'));
        expect(harness.lastCall.playerId, equals(1));
        expect(harness.lastCall.volume, equals(0.7));
      });

      test('setLooping calls native method', () async {
        await plugin.setLooping(1, true);

        expect(harness.lastCall.method, equals('setLooping'));
        expect(harness.lastCall.playerId, equals(1));
        expect(harness.lastCall.looping, isTrue);
      });

      test('setSubtitleTrack calls native method with track', () async {
        await plugin.setSubtitleTrack(1, const SubtitleTrack(id: 'en', label: 'English', language: 'en'));

        expect(harness.lastCall.method, equals('setSubtitleTrack'));
        expect(harness.lastCall.playerId, equals(1));
        expect(harness.lastCall.subtitleTrack!.id, equals('en'));
        expect(harness.lastCall.subtitleTrack!.label, equals('English'));
      });

      test('setSubtitleTrack calls native method with null', () async {
        await plugin.setSubtitleTrack(1, null);

        expect(harness.lastCall.method, equals('setSubtitleTrack'));
        expect(harness.lastCall.subtitleTrack, isNull);
      });
    });

    group('getters', () {
      test('getPosition returns duration from native', () async {
        final position = await plugin.getPosition(1);

        expect(position, equals(const Duration(seconds: 30)));
        expect(harness.lastCall.method, equals('getPosition'));
      });

      test('getDuration returns duration from native', () async {
        final duration = await plugin.getDuration(1);

        expect(duration, equals(const Duration(minutes: 2)));
        expect(harness.lastCall.method, equals('getDuration'));
      });
    });

    group('PiP', () {
      test('enterPip calls native method', () async {
        final result = await plugin.enterPip(1);

        expect(result, isTrue);
        expect(harness.lastCall.method, equals('enterPip'));
        expect(harness.lastCall.playerId, equals(1));
      });

      test('enterPip passes options', () async {
        await plugin.enterPip(1, options: const PipOptions(aspectRatio: 1.78, autoEnterOnBackground: true));

        expect(harness.lastCall.pipOptions!.aspectRatio, equals(1.78));
        expect(harness.lastCall.pipOptions!.autoEnterOnBackground, isTrue);
      });

      test('exitPip calls native method', () async {
        await plugin.exitPip(1);

        expect(harness.lastCall.method, equals('exitPip'));
        expect(harness.lastCall.playerId, equals(1));
      });

      test('isPipSupported returns native result', () async {
        final result = await plugin.isPipSupported();

        expect(result, isTrue);
        expect(harness.lastCall.method, equals('isPipSupported'));
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
        expect(harness.lastCall.playerId, equals(1));
      });
    });

    group('buildView', () {
      test('returns PlatformViewLink with correct parameters', () {
        final widget = plugin.buildView(1);

        // Uses PlatformViewLink with Hybrid Composition for stability
        expect(widget, isA<PlatformViewLink>());
      });
    });
  });
}
