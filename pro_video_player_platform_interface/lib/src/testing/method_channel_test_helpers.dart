import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pro_video_player_platform.dart';
import '../types/types.dart';

/// Helper extension to get typed arguments from [MethodCall].
///
/// Provides convenient typed accessors for common method call argument patterns
/// used in pro video player tests.
extension MethodCallArgs on MethodCall {
  /// Gets all arguments as a typed map.
  Map<String, dynamic> get args => Map<String, dynamic>.from(arguments as Map<Object?, Object?>);

  /// Gets the 'source' argument as a typed map.
  Map<String, dynamic> get sourceArg => Map<String, dynamic>.from(args['source'] as Map<Object?, Object?>);

  /// Gets the 'options' argument as a typed map.
  Map<String, dynamic> get optionsArg => Map<String, dynamic>.from(args['options'] as Map<Object?, Object?>);

  /// Gets the 'track' argument as a typed map, or null if not present.
  Map<String, dynamic>? get trackArg =>
      args['track'] != null ? Map<String, dynamic>.from(args['track'] as Map<Object?, Object?>) : null;

  /// Gets the 'headers' argument from source as a typed map, or null if not present.
  Map<String, dynamic>? get headersArg =>
      sourceArg['headers'] != null ? Map<String, dynamic>.from(sourceArg['headers'] as Map<Object?, Object?>) : null;
}

/// A test harness for pro video player implementations.
///
/// This class provides common setup and test utilities for testing
/// platform-specific video player implementations that use method channels.
class MethodChannelTestHarness {
  /// Creates a new test harness for the given [channelName].
  MethodChannelTestHarness({required this.channelName});

  /// The name of the method channel to mock.
  final String channelName;

  /// The method channel being tested.
  late MethodChannel methodChannel;

  /// Log of all method calls made to the channel.
  final List<MethodCall> log = [];

  /// Custom response handler for specific methods.
  Map<String, dynamic Function(MethodCall)>? customResponses;

  /// Sets up the mock method channel handler.
  ///
  /// Call this in [setUp] before running tests.
  void setUp() {
    methodChannel = MethodChannel(channelName);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (
      call,
    ) async {
      log.add(call);

      // Check for custom response first
      if (customResponses != null && customResponses!.containsKey(call.method)) {
        return customResponses![call.method]!(call);
      }

      // Default responses
      switch (call.method) {
        case 'create':
          return 1;
        case 'getPosition':
          return 30000;
        case 'getDuration':
          return 120000;
        case 'enterPip':
        case 'isPipSupported':
        case 'enterFullscreen':
          return true;
        default:
          return null;
      }
    });
  }

  /// Clears the mock method channel handler.
  ///
  /// Call this in [tearDown] after running tests.
  void tearDown() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, null);
    log.clear();
    customResponses = null;
  }

  /// Sets a custom response for a specific method.
  void setCustomResponse(String method, dynamic Function(MethodCall) handler) {
    customResponses ??= {};
    customResponses![method] = handler;
  }

  /// Sets the mock handler to return null for all methods.
  void setNullResponses() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (
      call,
    ) async {
      log.add(call);
      return null;
    });
  }

  /// Gets the last method call from the log.
  MethodCall get lastCall => log.last;
}

/// Common test cases for pro video player implementations.
///
/// Use this mixin to run standard tests against any [ProVideoPlayerPlatform]
/// implementation that uses method channels.
mixin MethodChannelPlatformTests {
  /// The test harness to use.
  MethodChannelTestHarness get harness;

  /// The platform implementation to test.
  ProVideoPlayerPlatform get platform;

  /// Runs common create tests.
  void runCreateTests() {
    test('creates player with network source', () async {
      final playerId = await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

      expect(playerId, equals(1));
      expect(harness.log, hasLength(1));
      expect(harness.lastCall.method, equals('create'));
      expect(harness.lastCall.sourceArg['type'], equals('network'));
      expect(harness.lastCall.sourceArg['url'], equals('https://example.com/video.mp4'));
    });

    test('creates player with file source', () async {
      final playerId = await platform.create(source: const VideoSource.file('/path/to/video.mp4'));

      expect(playerId, equals(1));
      expect(harness.lastCall.sourceArg['type'], equals('file'));
      expect(harness.lastCall.sourceArg['path'], equals('/path/to/video.mp4'));
    });

    test('creates player with asset source', () async {
      final playerId = await platform.create(source: const VideoSource.asset('assets/video.mp4'));

      expect(playerId, equals(1));
      expect(harness.lastCall.sourceArg['type'], equals('asset'));
      expect(harness.lastCall.sourceArg['assetPath'], equals('assets/video.mp4'));
    });

    test('creates player with custom options', () async {
      await platform.create(
        source: const VideoSource.network('https://example.com/video.mp4'),
        options: const VideoPlayerOptions(autoPlay: true, looping: true, volume: 0.8, playbackSpeed: 1.5),
      );

      expect(harness.lastCall.optionsArg['autoPlay'], isTrue);
      expect(harness.lastCall.optionsArg['looping'], isTrue);
      expect(harness.lastCall.optionsArg['volume'], equals(0.8));
      expect(harness.lastCall.optionsArg['playbackSpeed'], equals(1.5));
    });

    test('throws PlatformException when create returns null', () async {
      harness.setNullResponses();

      expect(
        () => platform.create(source: const VideoSource.network('https://example.com/video.mp4')),
        throwsA(isA<PlatformException>()),
      );
    });
  }

  /// Runs common playback control tests.
  void runPlaybackControlTests() {
    test('play calls native method', () async {
      await platform.play(1);

      expect(harness.lastCall.method, equals('play'));
      expect(harness.lastCall.args['playerId'], equals(1));
    });

    test('pause calls native method', () async {
      await platform.pause(1);

      expect(harness.lastCall.method, equals('pause'));
      expect(harness.lastCall.args['playerId'], equals(1));
    });

    test('stop calls native method', () async {
      await platform.stop(1);

      expect(harness.lastCall.method, equals('stop'));
      expect(harness.lastCall.args['playerId'], equals(1));
    });

    test('seekTo calls native method with milliseconds', () async {
      await platform.seekTo(1, const Duration(seconds: 30));

      expect(harness.lastCall.method, equals('seekTo'));
      expect(harness.lastCall.args['playerId'], equals(1));
      expect(harness.lastCall.args['position'], equals(30000));
    });

    test('dispose calls native method', () async {
      await platform.dispose(1);

      expect(harness.lastCall.method, equals('dispose'));
      expect(harness.lastCall.args['playerId'], equals(1));
    });
  }

  /// Runs common settings tests.
  void runSettingsTests() {
    test('setPlaybackSpeed calls native method', () async {
      await platform.setPlaybackSpeed(1, 1.5);

      expect(harness.lastCall.method, equals('setPlaybackSpeed'));
      expect(harness.lastCall.args['playerId'], equals(1));
      expect(harness.lastCall.args['speed'], equals(1.5));
    });

    test('setVolume calls native method', () async {
      await platform.setVolume(1, 0.7);

      expect(harness.lastCall.method, equals('setVolume'));
      expect(harness.lastCall.args['playerId'], equals(1));
      expect(harness.lastCall.args['volume'], equals(0.7));
    });

    test('setLooping calls native method', () async {
      await platform.setLooping(1, true);

      expect(harness.lastCall.method, equals('setLooping'));
      expect(harness.lastCall.args['playerId'], equals(1));
      expect(harness.lastCall.args['looping'], isTrue);
    });

    test('setSubtitleTrack calls native method with track', () async {
      await platform.setSubtitleTrack(1, const SubtitleTrack(id: 'en', label: 'English', language: 'en'));

      expect(harness.lastCall.method, equals('setSubtitleTrack'));
      expect(harness.lastCall.args['playerId'], equals(1));
      expect(harness.lastCall.trackArg!['id'], equals('en'));
      expect(harness.lastCall.trackArg!['label'], equals('English'));
    });

    test('setSubtitleTrack calls native method with null', () async {
      await platform.setSubtitleTrack(1, null);

      expect(harness.lastCall.method, equals('setSubtitleTrack'));
      expect(harness.lastCall.trackArg, isNull);
    });
  }

  /// Runs common getter tests.
  void runGetterTests() {
    test('getPosition returns duration from native', () async {
      final position = await platform.getPosition(1);

      expect(position, equals(const Duration(seconds: 30)));
      expect(harness.lastCall.method, equals('getPosition'));
    });

    test('getPosition returns zero when native returns null', () async {
      harness.setNullResponses();

      final position = await platform.getPosition(1);

      expect(position, equals(Duration.zero));
    });

    test('getDuration returns duration from native', () async {
      final duration = await platform.getDuration(1);

      expect(duration, equals(const Duration(minutes: 2)));
      expect(harness.lastCall.method, equals('getDuration'));
    });

    test('getDuration returns zero when native returns null', () async {
      harness.setNullResponses();

      final duration = await platform.getDuration(1);

      expect(duration, equals(Duration.zero));
    });
  }

  /// Runs common PiP tests.
  void runPipTests() {
    test('enterPip calls native method', () async {
      final result = await platform.enterPip(1);

      expect(result, isTrue);
      expect(harness.lastCall.method, equals('enterPip'));
      expect(harness.lastCall.args['playerId'], equals(1));
    });

    test('enterPip passes options', () async {
      await platform.enterPip(1, options: const PipOptions(aspectRatio: 1.78, autoEnterOnBackground: true));

      expect(harness.lastCall.args['aspectRatio'], equals(1.78));
      expect(harness.lastCall.args['autoEnterOnBackground'], isTrue);
    });

    test('enterPip returns false when native returns null', () async {
      harness.setNullResponses();

      final result = await platform.enterPip(1);

      expect(result, isFalse);
    });

    test('exitPip calls native method', () async {
      await platform.exitPip(1);

      expect(harness.lastCall.method, equals('exitPip'));
      expect(harness.lastCall.args['playerId'], equals(1));
    });

    test('isPipSupported returns native result', () async {
      final result = await platform.isPipSupported();

      expect(result, isTrue);
      expect(harness.lastCall.method, equals('isPipSupported'));
    });

    test('isPipSupported returns false when native returns null', () async {
      harness.setNullResponses();

      final result = await platform.isPipSupported();

      expect(result, isFalse);
    });
  }

  /// Runs common events tests.
  void runEventsTests() {
    test('events throws StateError for uncreated player', () {
      expect(() => platform.events(999), throwsA(isA<StateError>()));
    });

    test('events returns stream after create', () async {
      await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

      final stream = platform.events(1);

      expect(stream, isA<Stream<VideoPlayerEvent>>());
    });

    test('events stream is broadcast', () async {
      await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

      final stream = platform.events(1);
      // Broadcast streams can have multiple listeners
      final sub1 = stream.listen((_) {});
      final sub2 = stream.listen((_) {});

      expect(sub1, isNotNull);
      expect(sub2, isNotNull);

      await sub1.cancel();
      await sub2.cancel();
    });
  }

  /// Runs common dispose tests.
  void runDisposeTests() {
    test('dispose calls native method and cleans up', () async {
      // First create a player to set up event controllers
      await platform.create(source: const VideoSource.network('https://example.com/video.mp4'));

      await platform.dispose(1);

      expect(harness.lastCall.method, equals('dispose'));
      expect(harness.lastCall.args['playerId'], equals(1));
    });
  }
}
