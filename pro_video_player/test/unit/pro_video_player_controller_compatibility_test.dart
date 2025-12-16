import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../shared/test_constants.dart';
import '../shared/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerTestFixture fixture;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    fixture = VideoPlayerTestFixture()..setUp();
  });

  tearDown(() async {
    await fixture.tearDown();
  });

  group('video_player Compatibility', () {
    group('Named Constructors', () {
      group('network()', () {
        test('creates controller with network source', () {
          final controller = ProVideoPlayerController.network(TestMedia.networkUrl);

          expect(controller.isInitialized, isFalse);
          expect(controller.playerId, isNull);
        });

        test('initializes with network source from constructor', () async {
          final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
          await controller.initialize();

          expect(controller.isInitialized, isTrue);
          expect(controller.playerId, equals(1));

          // Verify correct source was passed
          final captured = verify(
            () => fixture.mockPlatform.create(
              source: captureAny(named: 'source'),
              options: any(named: 'options'),
            ),
          ).captured;

          final source = captured.first as VideoSource;
          expect(source, isA<NetworkVideoSource>());
          expect((source as NetworkVideoSource).url, equals(TestMedia.networkUrl));

          await controller.dispose();
        });

        test('passes httpHeaders to network source', () async {
          const headers = {'Authorization': 'Bearer token', 'Custom-Header': 'value'};
          final controller = ProVideoPlayerController.network(TestMedia.networkUrl, httpHeaders: headers);
          await controller.initialize();

          final captured = verify(
            () => fixture.mockPlatform.create(
              source: captureAny(named: 'source'),
              options: any(named: 'options'),
            ),
          ).captured;

          final source = captured.first as NetworkVideoSource;
          expect(source.headers, equals(headers));

          await controller.dispose();
        });

        test('passes videoPlayerOptions to initialize', () async {
          const options = VideoPlayerOptions(autoPlay: true, mixWithOthers: true);
          final controller = ProVideoPlayerController.network(TestMedia.networkUrl, videoPlayerOptions: options);
          await controller.initialize();

          verify(
            () => fixture.mockPlatform.create(
              source: any(named: 'source'),
              options: options,
            ),
          );
          verify(() => fixture.mockPlatform.play(1)).called(1); // autoPlay should trigger play

          await controller.dispose();
        });
      });

      group('file()', () {
        test('creates controller with file source', () {
          final controller = ProVideoPlayerController.file(File(TestMedia.filePath));

          expect(controller.isInitialized, isFalse);
          expect(controller.playerId, isNull);
        });

        test('initializes with file source from constructor', () async {
          final controller = ProVideoPlayerController.file(File(TestMedia.filePath));
          await controller.initialize();

          expect(controller.isInitialized, isTrue);
          expect(controller.playerId, equals(1));

          final captured = verify(
            () => fixture.mockPlatform.create(
              source: captureAny(named: 'source'),
              options: any(named: 'options'),
            ),
          ).captured;

          final source = captured.first as VideoSource;
          expect(source, isA<FileVideoSource>());
          expect((source as FileVideoSource).path, equals(TestMedia.filePath));

          await controller.dispose();
        });

        test('passes videoPlayerOptions to initialize', () async {
          const options = VideoPlayerOptions(mixWithOthers: true);
          final controller = ProVideoPlayerController.file(File(TestMedia.filePath), videoPlayerOptions: options);
          await controller.initialize();

          verify(
            () => fixture.mockPlatform.create(
              source: any(named: 'source'),
              options: options,
            ),
          );

          await controller.dispose();
        });
      });

      group('asset()', () {
        test('creates controller with asset source', () {
          final controller = ProVideoPlayerController.asset(TestMedia.assetPath);

          expect(controller.isInitialized, isFalse);
          expect(controller.playerId, isNull);
        });

        test('initializes with asset source from constructor', () async {
          final controller = ProVideoPlayerController.asset(TestMedia.assetPath);
          await controller.initialize();

          expect(controller.isInitialized, isTrue);
          expect(controller.playerId, equals(1));

          final captured = verify(
            () => fixture.mockPlatform.create(
              source: captureAny(named: 'source'),
              options: any(named: 'options'),
            ),
          ).captured;

          final source = captured.first as VideoSource;
          expect(source, isA<AssetVideoSource>());
          expect((source as AssetVideoSource).assetPath, equals(TestMedia.assetPath));

          await controller.dispose();
        });

        test('handles package parameter correctly', () async {
          final controller = ProVideoPlayerController.asset('videos/intro.mp4', package: 'my_package');
          await controller.initialize();

          final captured = verify(
            () => fixture.mockPlatform.create(
              source: captureAny(named: 'source'),
              options: any(named: 'options'),
            ),
          ).captured;

          final source = captured.first as AssetVideoSource;
          expect(source.assetPath, equals('packages/my_package/videos/intro.mp4'));

          await controller.dispose();
        });

        test('passes videoPlayerOptions to initialize', () async {
          const options = VideoPlayerOptions(volume: 0.5);
          final controller = ProVideoPlayerController.asset(TestMedia.assetPath, videoPlayerOptions: options);
          await controller.initialize();

          verify(
            () => fixture.mockPlatform.create(
              source: any(named: 'source'),
              options: options,
            ),
          );

          await controller.dispose();
        });
      });

      test('initialize throws if no source provided and none in constructor', () {
        final controller = ProVideoPlayerController();

        expect(
          controller.initialize,
          throwsA(isA<StateError>().having((e) => e.message, 'message', contains('No source provided'))),
        );
      });
    });

    group('Compatibility Properties', () {
      test('dataSource returns URL for network source', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        expect(controller.dataSource, equals(TestMedia.networkUrl));

        await controller.dispose();
      });

      test('dataSource returns path for file source', () async {
        final controller = ProVideoPlayerController.file(File(TestMedia.filePath));
        await controller.initialize();

        expect(controller.dataSource, equals(TestMedia.filePath));

        await controller.dispose();
      });

      test('dataSource returns asset path for asset source', () async {
        final controller = ProVideoPlayerController.asset(TestMedia.assetPath);
        await controller.initialize();

        expect(controller.dataSource, equals(TestMedia.assetPath));

        await controller.dispose();
      });

      test('dataSource returns null when not initialized', () {
        final controller = ProVideoPlayerController();
        expect(controller.dataSource, isNull);
      });

      test('dataSourceType returns network for network source', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        expect(controller.dataSourceType, equals(DataSourceType.network));

        await controller.dispose();
      });

      test('dataSourceType returns file for file source', () async {
        final controller = ProVideoPlayerController.file(File(TestMedia.filePath));
        await controller.initialize();

        expect(controller.dataSourceType, equals(DataSourceType.file));

        await controller.dispose();
      });

      test('dataSourceType returns contentUri for content:// paths', () async {
        final controller = ProVideoPlayerController.file(File('content://media/video/123'));
        await controller.initialize();

        expect(controller.dataSourceType, equals(DataSourceType.contentUri));

        await controller.dispose();
      });

      test('dataSourceType returns asset for asset source', () async {
        final controller = ProVideoPlayerController.asset(TestMedia.assetPath);
        await controller.initialize();

        expect(controller.dataSourceType, equals(DataSourceType.asset));

        await controller.dispose();
      });

      test('dataSourceType returns null when not initialized', () {
        final controller = ProVideoPlayerController();
        expect(controller.dataSourceType, isNull);
      });

      test('httpHeaders returns headers for network source', () async {
        const headers = {'Authorization': 'Bearer token'};
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl, httpHeaders: headers);
        await controller.initialize();

        expect(controller.httpHeaders, equals(headers));

        await controller.dispose();
      });

      test('httpHeaders returns null for non-network source', () async {
        final controller = ProVideoPlayerController.file(File(TestMedia.filePath));
        await controller.initialize();

        expect(controller.httpHeaders, isNull);

        await controller.dispose();
      });

      test('httpHeaders returns null when not initialized', () {
        final controller = ProVideoPlayerController();
        expect(controller.httpHeaders, isNull);
      });

      test('position returns Future<Duration> from value', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // Simulate position update
        fixture.emitEvent(const PositionChangedEvent(Duration(seconds: 10)));
        await Future<void>.delayed(TestDelays.eventPropagation);

        final position = await controller.position;
        expect(position, equals(const Duration(seconds: 10)));

        await controller.dispose();
      });

      test('position throws StateError when not initialized', () {
        final controller = ProVideoPlayerController();

        expect(() => controller.position, throwsA(isA<StateError>()));
      });

      test('aspectRatio returns width/height from size', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // Simulate video size update
        fixture.emitEvent(const VideoSizeChangedEvent(width: 1920, height: 1080));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(controller.value.aspectRatio, equals(1920 / 1080));

        await controller.dispose();
      });

      test('aspectRatio returns 1.0 for square video', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // Simulate square video size
        fixture.emitEvent(const VideoSizeChangedEvent(width: 1000, height: 1000));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(controller.value.aspectRatio, equals(1.0));

        await controller.dispose();
      });

      test('aspectRatio returns 0.0 when size is null', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // No size event sent, size should be null
        expect(controller.value.aspectRatio, equals(0.0));

        await controller.dispose();
      });

      test('aspectRatio returns 0.0 when height is zero', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // Invalid size with zero height
        fixture.emitEvent(const VideoSizeChangedEvent(width: 1920, height: 0));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(controller.value.aspectRatio, equals(0.0));

        await controller.dispose();
      });

      test('buffered returns list with single range from bufferedPosition', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // Simulate buffered position update
        fixture.emitEvent(const BufferedPositionChangedEvent(Duration(seconds: 30)));
        await Future<void>.delayed(TestDelays.eventPropagation);

        final buffered = controller.value.buffered;
        expect(buffered, hasLength(1));
        expect(buffered.first.start, equals(Duration.zero));
        expect(buffered.first.end, equals(const Duration(seconds: 30)));

        await controller.dispose();
      });

      test('buffered returns empty list when bufferedPosition is zero', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // No buffered position event sent, should be zero
        expect(controller.value.buffered, isEmpty);

        await controller.dispose();
      });

      test('buffered updates when bufferedPosition changes', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // First buffer update
        fixture.emitEvent(const BufferedPositionChangedEvent(Duration(seconds: 10)));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(controller.value.buffered.first.end, equals(const Duration(seconds: 10)));

        // Second buffer update
        fixture.emitEvent(const BufferedPositionChangedEvent(Duration(seconds: 20)));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(controller.value.buffered.first.end, equals(const Duration(seconds: 20)));

        await controller.dispose();
      });

      test('caption returns Caption.none when no subtitle cue', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // No subtitle cue sent
        expect(controller.value.caption, equals(Caption.none));

        await controller.dispose();
      });

      test('caption returns Caption from currentEmbeddedCue', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // Simulate subtitle cue
        const cue = SubtitleCue(text: 'Hello world', start: Duration(seconds: 1), end: Duration(seconds: 3));
        fixture.emitEvent(const EmbeddedSubtitleCueEvent(cue: cue));
        await Future<void>.delayed(TestDelays.eventPropagation);

        final caption = controller.value.caption;
        expect(caption.text, equals('Hello world'));
        expect(caption.start, equals(const Duration(seconds: 1)));
        expect(caption.end, equals(const Duration(seconds: 3)));

        await controller.dispose();
      });

      test('caption updates when subtitle cue changes', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // First cue
        const cue1 = SubtitleCue(text: 'First', start: Duration(seconds: 1), end: Duration(seconds: 2));
        fixture.emitEvent(const EmbeddedSubtitleCueEvent(cue: cue1));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(controller.value.caption.text, equals('First'));

        // Second cue
        const cue2 = SubtitleCue(text: 'Second', start: Duration(seconds: 3), end: Duration(seconds: 4));
        fixture.emitEvent(const EmbeddedSubtitleCueEvent(cue: cue2));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(controller.value.caption.text, equals('Second'));

        await controller.dispose();
      });

      test('caption returns Caption.none when cue cleared', () async {
        final controller = ProVideoPlayerController.network(TestMedia.networkUrl);
        await controller.initialize();

        // Set a cue
        const cue = SubtitleCue(text: 'Hello', start: Duration(seconds: 1), end: Duration(seconds: 2));
        fixture.emitEvent(const EmbeddedSubtitleCueEvent(cue: cue));
        await Future<void>.delayed(TestDelays.eventPropagation);
        expect(controller.value.caption.text, equals('Hello'));

        // Clear the cue
        fixture.emitEvent(const EmbeddedSubtitleCueEvent(cue: null));
        await Future<void>.delayed(TestDelays.eventPropagation);

        expect(controller.value.caption, equals(Caption.none));

        await controller.dispose();
      });
    });

    group('Caption Methods', () {
      setUp(() async {
        await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('setClosedCaptionFile with null disables captions', () async {
        await fixture.controller.setClosedCaptionFile(null);

        verify(() => fixture.mockPlatform.setSubtitleTrack(1, null)).called(1);
      });

      test('setClosedCaptionFile with captions succeeds (compatibility stub)', () async {
        const captions = ClosedCaptionFile(
          captions: [
            Caption(text: 'Hello', start: Duration(seconds: 1), end: Duration(seconds: 2)),
            Caption(text: 'World', start: Duration(seconds: 3), end: Duration(seconds: 4)),
          ],
        );

        // Should not throw - this is a compatibility stub
        await fixture.controller.setClosedCaptionFile(Future.value(captions));
      });

      test('setClosedCaptionFile handles Future captions (compatibility stub)', () async {
        // Simulate async loading of captions
        final captions = Future.delayed(
          const Duration(milliseconds: 10),
          () => const ClosedCaptionFile(
            captions: [Caption(text: 'Async', start: Duration(seconds: 1), end: Duration(seconds: 2))],
          ),
        );

        // Should not throw - this is a compatibility stub
        await fixture.controller.setClosedCaptionFile(captions);
      });

      test('setClosedCaptionFile throws when not initialized', () {
        final uninitializedController = ProVideoPlayerController();

        expect(() => uninitializedController.setClosedCaptionFile(null), throwsA(isA<StateError>()));
      });

      test('setCaptionOffset calls setSubtitleOffset', () async {
        when(() => fixture.mockPlatform.setSubtitleOffset(any(), any())).thenAnswer((_) async {});

        await fixture.controller.setCaptionOffset(const Duration(seconds: 2));

        verify(() => fixture.mockPlatform.setSubtitleOffset(1, const Duration(seconds: 2))).called(1);
      });

      test('setCaptionOffset with negative offset', () async {
        when(() => fixture.mockPlatform.setSubtitleOffset(any(), any())).thenAnswer((_) async {});

        await fixture.controller.setCaptionOffset(const Duration(seconds: -1));

        verify(() => fixture.mockPlatform.setSubtitleOffset(1, const Duration(seconds: -1))).called(1);
      });

      test('setCaptionOffset throws when not initialized', () {
        final uninitializedController = ProVideoPlayerController();

        expect(() => uninitializedController.setCaptionOffset(Duration.zero), throwsA(isA<StateError>()));
      });
    });

    group('Method Signature Standardization', () {
      setUp(() async {
        await fixture.controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));
      });

      test('setLooping accepts positional bool parameter (video_player style)', () async {
        when(() => fixture.mockPlatform.setLooping(any(), any())).thenAnswer((_) async {});

        await fixture.controller.setLooping(true);

        verify(() => fixture.mockPlatform.setLooping(1, true)).called(1);
      });

      test('setLooping with false disables looping', () async {
        when(() => fixture.mockPlatform.setLooping(any(), any())).thenAnswer((_) async {});

        await fixture.controller.setLooping(false);

        verify(() => fixture.mockPlatform.setLooping(1, false)).called(1);
      });

      test('setLooping throws when not initialized', () {
        final uninitializedController = ProVideoPlayerController();

        expect(() => uninitializedController.setLooping(true), throwsA(isA<StateError>()));
      });
    });
  });
}
