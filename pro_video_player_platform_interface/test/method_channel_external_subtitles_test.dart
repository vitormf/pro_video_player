// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Mock HTTP client for testing subtitle loading (from http package)
class MockHttpClient extends Mock implements http.Client {}

/// Test implementation of MethodChannelBase for testing.
class TestableMethodChannel extends MethodChannelBase {
  TestableMethodChannel({SubtitleLoader? subtitleLoader})
    : _customSubtitleLoader = subtitleLoader,
      super('test_platform');

  final SubtitleLoader? _customSubtitleLoader;

  @override
  SubtitleLoader get subtitleLoader => _customSubtitleLoader ?? super.subtitleLoader;

  @override
  Widget buildView(int playerId, {ControlsMode controlsMode = ControlsMode.none}) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('MethodChannelBase.addExternalSubtitle', () {
    late TestableMethodChannel methodChannel;
    late List<MethodCall> methodCalls;
    late Map<String, dynamic>? mockResponse;

    setUp(() {
      methodChannel = TestableMethodChannel();
      methodCalls = [];
      mockResponse = null;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        (call) async {
          methodCalls.add(call);

          if (call.method == 'create') {
            return 1;
          }
          if (call.method == 'addExternalSubtitle') {
            return mockResponse;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        null,
      );
    });

    test('sends correct method call with network source', () async {
      mockResponse = {
        'id': 'external_0',
        'label': 'English',
        'language': 'en',
        'isDefault': false,
        'path': 'https://example.com/subtitles.srt',
        'sourceType': 'network',
        'format': 'srt',
      };

      final track = await methodChannel.addExternalSubtitle(
        1,
        const SubtitleSource.network(
          'https://example.com/subtitles.srt',
          format: SubtitleFormat.srt,
          label: 'English',
          language: 'en',
        ),
      );

      expect(methodCalls, hasLength(1));
      expect(methodCalls[0].method, equals('addExternalSubtitle'));
      final args = Map<String, dynamic>.from(methodCalls[0].arguments as Map);
      expect(args['playerId'], equals(1));
      expect(args['path'], equals('https://example.com/subtitles.srt'));
      expect(args['sourceType'], equals('network'));
      expect(args['format'], equals('srt'));
      expect(args['label'], equals('English'));
      expect(args['language'], equals('en'));

      expect(track, isNotNull);
      expect(track!.id, equals('external_0'));
      expect(track.label, equals('English'));
      expect(track.language, equals('en'));
    });

    test('sends correct method call with file source', () async {
      mockResponse = {
        'id': 'external_0',
        'label': 'Local Subs',
        'language': 'es',
        'isDefault': false,
        'path': '/path/to/subtitles.vtt',
        'sourceType': 'file',
        'format': 'vtt',
      };

      final track = await methodChannel.addExternalSubtitle(
        1,
        const SubtitleSource.file(
          '/path/to/subtitles.vtt',
          label: 'Local Subs',
          language: 'es',
          format: SubtitleFormat.vtt,
        ),
      );

      expect(methodCalls, hasLength(1));
      final args = Map<String, dynamic>.from(methodCalls[0].arguments as Map);
      expect(args['path'], equals('/path/to/subtitles.vtt'));
      expect(args['sourceType'], equals('file'));
      expect(args['format'], equals('vtt'));
      expect(track, isNotNull);
    });

    test('sends correct method call with asset source', () async {
      mockResponse = {
        'id': 'external_0',
        'label': 'Bundled',
        'language': 'fr',
        'isDefault': false,
        'path': 'assets/subtitles/french.srt',
        'sourceType': 'asset',
        'format': 'srt',
      };

      final track = await methodChannel.addExternalSubtitle(
        1,
        const SubtitleSource.asset(
          'assets/subtitles/french.srt',
          label: 'Bundled',
          language: 'fr',
          format: SubtitleFormat.srt,
        ),
      );

      expect(methodCalls, hasLength(1));
      final args = Map<String, dynamic>.from(methodCalls[0].arguments as Map);
      expect(args['path'], equals('assets/subtitles/french.srt'));
      expect(args['sourceType'], equals('asset'));
      expect(track, isNotNull);
    });

    test('returns null when native returns null', () async {
      mockResponse = null;

      final track = await methodChannel.addExternalSubtitle(
        1,
        const SubtitleSource.network('https://example.com/invalid.xyz', format: SubtitleFormat.srt),
      );

      expect(track, isNull);
    });

    test('sends isDefault flag', () async {
      mockResponse = {
        'id': 'external_0',
        'label': 'Default',
        'language': 'en',
        'isDefault': true,
        'path': 'https://example.com/subtitles.srt',
        'sourceType': 'network',
        'format': 'srt',
      };

      await methodChannel.addExternalSubtitle(
        1,
        const SubtitleSource.network('https://example.com/subtitles.srt', format: SubtitleFormat.srt, isDefault: true),
      );

      final args = Map<String, dynamic>.from(methodCalls[0].arguments as Map);
      expect(args['isDefault'], isTrue);
    });

    test('throws ArgumentError when format cannot be auto-detected', () async {
      // Test that error is thrown when format detection fails
      expect(
        () =>
            methodChannel.addExternalSubtitle(1, const SubtitleSource.network('https://example.com/subtitles.unknown')),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Could not detect subtitle format'))),
      );
    });

    test('includes webvttContent in method channel args when subtitle is loaded successfully', () async {
      // Create a mock HTTP client that returns subtitle content
      final mockHttpClient = MockHttpClient();
      final subtitleLoader = SubtitleLoader(client: mockHttpClient);
      final testMethodChannel = TestableMethodChannel(subtitleLoader: subtitleLoader);

      // Setup method call handler for the test channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        (call) async {
          methodCalls.add(call);
          if (call.method == 'addExternalSubtitle') {
            return {
              'id': 'external_0',
              'label': 'English',
              'language': 'en',
              'isDefault': false,
              'path': 'https://example.com/subtitles.srt',
              'sourceType': 'network',
              'format': 'srt',
            };
          }
          return null;
        },
      );

      // Create a simple SRT subtitle content
      const srtContent = '''
1
00:00:01,000 --> 00:00:05,000
Test subtitle cue

''';

      // Mock HTTP client to return the SRT content
      when(() => mockHttpClient.get(any())).thenAnswer((_) async => http.Response(srtContent, 200));

      await testMethodChannel.addExternalSubtitle(
        1,
        const SubtitleSource.network(
          'https://example.com/subtitles.srt',
          format: SubtitleFormat.srt,
          label: 'English',
          language: 'en',
        ),
      );

      expect(methodCalls, hasLength(1));
      final args = Map<String, dynamic>.from(methodCalls[0].arguments as Map);

      // Verify webvttContent is included
      expect(args.containsKey('webvttContent'), isTrue);
      expect(args['webvttContent'], isNotNull);
      expect(args['webvttContent'], contains('WEBVTT'));
      expect(args['webvttContent'], contains('Test subtitle cue'));

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        null,
      );
      subtitleLoader.dispose();
    });

    test('returns track with cues when subtitle is loaded successfully', () async {
      final mockHttpClient = MockHttpClient();
      final subtitleLoader = SubtitleLoader(client: mockHttpClient);
      final testMethodChannel = TestableMethodChannel(subtitleLoader: subtitleLoader);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        (call) async {
          if (call.method == 'addExternalSubtitle') {
            return {
              'id': 'external_0',
              'label': 'English',
              'language': 'en',
              'isDefault': false,
              'path': 'https://example.com/subtitles.vtt',
              'sourceType': 'network',
              'format': 'vtt',
            };
          }
          return null;
        },
      );

      const vttContent = '''
WEBVTT

00:00:01.000 --> 00:00:05.000
First cue

00:00:06.000 --> 00:00:10.000
Second cue

''';

      when(() => mockHttpClient.get(any())).thenAnswer((_) async => http.Response(vttContent, 200));

      final track = await testMethodChannel.addExternalSubtitle(
        1,
        const SubtitleSource.network(
          'https://example.com/subtitles.vtt',
          format: SubtitleFormat.vtt,
          label: 'English',
          language: 'en',
        ),
      );

      // Verify track includes parsed cues
      expect(track, isNotNull);
      expect(track?.cues, isNotNull);
      expect(track?.cues, hasLength(2));
      expect(track?.cues?[0].text, contains('First cue'));
      expect(track?.cues?[1].text, contains('Second cue'));

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        null,
      );
      subtitleLoader.dispose();
    });

    test('returns track without cues when subtitle loading fails', () async {
      final mockHttpClient = MockHttpClient();
      final subtitleLoader = SubtitleLoader(client: mockHttpClient);
      final testMethodChannel = TestableMethodChannel(subtitleLoader: subtitleLoader);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        (call) async {
          if (call.method == 'addExternalSubtitle') {
            return {
              'id': 'external_0',
              'label': 'English',
              'language': 'en',
              'isDefault': false,
              'path': 'https://example.com/subtitles.srt',
              'sourceType': 'network',
              'format': 'srt',
            };
          }
          return null;
        },
      );

      // Simulate HTTP failure
      when(() => mockHttpClient.get(any())).thenAnswer((_) async => http.Response('Not Found', 404));

      final track = await testMethodChannel.addExternalSubtitle(
        1,
        const SubtitleSource.network(
          'https://example.com/subtitles.srt',
          format: SubtitleFormat.srt,
          label: 'English',
          language: 'en',
        ),
      );

      // Verify track is created but without cues (loading failed)
      expect(track, isNotNull);
      expect(track?.cues, isNull); // No cues because loading failed

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        null,
      );
      subtitleLoader.dispose();
    });

    test('does not include webvttContent when subtitle loading fails', () async {
      final mockHttpClient = MockHttpClient();
      final subtitleLoader = SubtitleLoader(client: mockHttpClient);
      final testMethodChannel = TestableMethodChannel(subtitleLoader: subtitleLoader);
      final calls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        (call) async {
          calls.add(call);
          if (call.method == 'addExternalSubtitle') {
            return {
              'id': 'external_0',
              'label': 'English',
              'language': 'en',
              'isDefault': false,
              'path': 'https://example.com/subtitles.srt',
              'sourceType': 'network',
              'format': 'srt',
            };
          }
          return null;
        },
      );

      // Simulate HTTP error
      when(() => mockHttpClient.get(any())).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      await testMethodChannel.addExternalSubtitle(
        1,
        const SubtitleSource.network(
          'https://example.com/subtitles.srt',
          format: SubtitleFormat.srt,
          label: 'English',
          language: 'en',
        ),
      );

      final args = Map<String, dynamic>.from(calls[0].arguments as Map);

      // Verify webvttContent is NOT included when loading fails
      expect(args.containsKey('webvttContent'), isFalse);

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        null,
      );
      subtitleLoader.dispose();
    });
  });

  group('ProVideoPlayerPlatform.addExternalSubtitle', () {
    test('throws UnimplementedError by default', () {
      final platform = _TestableProVideoPlayer();

      expect(
        () => platform.addExternalSubtitle(
          1,
          const SubtitleSource.network('https://example.com/subtitles.srt', format: SubtitleFormat.srt),
        ),
        throwsA(isA<UnimplementedError>().having((e) => e.message, 'message', contains('addExternalSubtitle()'))),
      );
    });
  });

  group('MethodChannelBase.removeExternalSubtitle', () {
    late TestableMethodChannel methodChannel;
    late List<MethodCall> methodCalls;
    late bool mockRemoveResult;

    setUp(() {
      methodChannel = TestableMethodChannel();
      methodCalls = [];
      mockRemoveResult = true;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        (call) async {
          methodCalls.add(call);

          if (call.method == 'removeExternalSubtitle') {
            return mockRemoveResult;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        null,
      );
    });

    test('sends correct method call', () async {
      final result = await methodChannel.removeExternalSubtitle(1, 'external_0');

      expect(methodCalls, hasLength(1));
      expect(methodCalls[0].method, equals('removeExternalSubtitle'));
      final args = Map<String, dynamic>.from(methodCalls[0].arguments as Map);
      expect(args['playerId'], equals(1));
      expect(args['trackId'], equals('external_0'));
      expect(result, isTrue);
    });

    test('returns false when track not found', () async {
      mockRemoveResult = false;

      final result = await methodChannel.removeExternalSubtitle(1, 'nonexistent');

      expect(result, isFalse);
    });
  });

  group('MethodChannelBase.getExternalSubtitles', () {
    late TestableMethodChannel methodChannel;
    late List<MethodCall> methodCalls;
    late List<Map<String, dynamic>> mockTracks;

    setUp(() {
      methodChannel = TestableMethodChannel();
      methodCalls = [];
      mockTracks = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        (call) async {
          methodCalls.add(call);

          if (call.method == 'getExternalSubtitles') {
            return mockTracks;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.pro_video_player.test_platform/methods'),
        null,
      );
    });

    test('returns empty list when no external subtitles', () async {
      mockTracks = [];

      final tracks = await methodChannel.getExternalSubtitles(1);

      expect(tracks, isEmpty);
    });

    test('returns list of external subtitle tracks', () async {
      mockTracks = [
        {
          'id': 'external_0',
          'label': 'English',
          'language': 'en',
          'isDefault': true,
          'path': 'https://example.com/en.srt',
          'sourceType': 'network',
          'format': 'srt',
        },
        {
          'id': 'external_1',
          'label': 'Spanish',
          'language': 'es',
          'isDefault': false,
          'path': 'https://example.com/es.vtt',
          'sourceType': 'network',
          'format': 'vtt',
        },
      ];

      final tracks = await methodChannel.getExternalSubtitles(1);

      expect(tracks, hasLength(2));
      expect(tracks[0].id, equals('external_0'));
      expect(tracks[0].label, equals('English'));
      expect(tracks[0].language, equals('en'));
      expect(tracks[0].isDefault, isTrue);
      expect(tracks[0].path, equals('https://example.com/en.srt'));
      expect(tracks[0].sourceType, equals('network'));
      expect(tracks[0].format, equals(SubtitleFormat.srt));

      expect(tracks[1].id, equals('external_1'));
      expect(tracks[1].format, equals(SubtitleFormat.vtt));
    });
  });
}

/// Test subclass for testing default implementations.
class _TestableProVideoPlayer extends ProVideoPlayerPlatform {
  _TestableProVideoPlayer();

  // Override token verification for testing
  @override
  // ignore: must_call_super - Necessary: mock implementation intentionally does nothing, calling super would throw
  void noSuchMethod(Invocation invocation) {
    // Allow MockPlatformInterfaceMixin behavior
  }
}
