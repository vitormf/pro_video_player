import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/controller/subtitle_manager.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../shared/mocks.dart';
import '../../shared/test_constants.dart';
import '../../shared/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late SubtitleManager manager;
  late int? playerId;
  late VideoPlayerOptions options;
  late bool isInitialized;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    playerId = 1;
    options = const VideoPlayerOptions();
    isInitialized = true;

    manager = SubtitleManager(
      getPlayerId: () => playerId,
      getOptions: () => options,
      platform: mockPlatform,
      ensureInitialized: () {
        if (!isInitialized) {
          throw StateError('Controller not initialized');
        }
      },
    );
  });

  group('SubtitleManager', () {
    group('addExternalSubtitle', () {
      test('calls ensureInitialized', () async {
        const source = SubtitleSource.network('https://example.com/sub.vtt', label: 'English');
        final track = ExternalSubtitleTrack(
          id: 'track-1',
          label: 'English',
          language: 'en',
          path: source.path,
          sourceType: source.sourceType,
          format: SubtitleFormat.vtt,
        );
        when(() => mockPlatform.addExternalSubtitle(any(), any())).thenAnswer((_) async => track);

        await manager.addExternalSubtitle(source);

        // Should not throw (ensureInitialized called successfully)
        verify(() => mockPlatform.addExternalSubtitle(1, source)).called(1);
      });

      test('throws when not initialized', () async {
        isInitialized = false;
        const source = SubtitleSource.network('https://example.com/sub.vtt', label: 'English');

        expect(() => manager.addExternalSubtitle(source), throwsStateError);
      });

      test('returns null when subtitlesEnabled is false', () async {
        options = const VideoPlayerOptions(subtitlesEnabled: false);
        const source = SubtitleSource.network('https://example.com/sub.vtt', label: 'English');

        final result = await manager.addExternalSubtitle(source);

        expect(result, isNull);
        verifyNever(() => mockPlatform.addExternalSubtitle(any(), any()));
      });

      test('calls platform addExternalSubtitle when enabled', () async {
        const source = SubtitleSource.network('https://example.com/sub.vtt', label: 'English');
        final track = ExternalSubtitleTrack(
          id: 'track-1',
          label: 'English',
          language: 'en',
          path: source.path,
          sourceType: source.sourceType,
          format: SubtitleFormat.vtt,
        );
        when(() => mockPlatform.addExternalSubtitle(any(), any())).thenAnswer((_) async => track);

        final result = await manager.addExternalSubtitle(source);

        expect(result, equals(track));
        verify(() => mockPlatform.addExternalSubtitle(1, source)).called(1);
      });

      test('returns track from platform', () async {
        const source = SubtitleSource.file('/path/to/sub.srt', label: 'Spanish');
        final track = ExternalSubtitleTrack(
          id: 'track-2',
          label: 'Spanish',
          language: 'es',
          path: source.path,
          sourceType: source.sourceType,
          format: SubtitleFormat.srt,
        );
        when(() => mockPlatform.addExternalSubtitle(any(), any())).thenAnswer((_) async => track);

        final result = await manager.addExternalSubtitle(source);

        expect(result, equals(track));
      });

      test('handles network source', () async {
        const source = SubtitleSource.network('https://example.com/sub.vtt', label: 'English');
        final track = ExternalSubtitleTrack(
          id: 'track-1',
          label: 'English',
          path: source.path,
          sourceType: source.sourceType,
          format: SubtitleFormat.vtt,
        );
        when(() => mockPlatform.addExternalSubtitle(any(), any())).thenAnswer((_) async => track);

        await manager.addExternalSubtitle(source);

        verify(() => mockPlatform.addExternalSubtitle(1, source)).called(1);
      });

      test('handles file source', () async {
        const source = SubtitleSource.file('/path/to/sub.srt', label: 'French');
        final track = ExternalSubtitleTrack(
          id: 'track-3',
          label: 'French',
          path: source.path,
          sourceType: source.sourceType,
          format: SubtitleFormat.srt,
        );
        when(() => mockPlatform.addExternalSubtitle(any(), any())).thenAnswer((_) async => track);

        await manager.addExternalSubtitle(source);

        verify(() => mockPlatform.addExternalSubtitle(1, source)).called(1);
      });

      test('handles asset source', () async {
        const source = SubtitleSource.asset('assets/subtitles/sub.srt', label: 'German');
        final track = ExternalSubtitleTrack(
          id: 'track-4',
          label: 'German',
          path: source.path,
          sourceType: source.sourceType,
          format: SubtitleFormat.srt,
        );
        when(() => mockPlatform.addExternalSubtitle(any(), any())).thenAnswer((_) async => track);

        await manager.addExternalSubtitle(source);

        verify(() => mockPlatform.addExternalSubtitle(1, source)).called(1);
      });

      test('returns null when platform returns null', () async {
        const source = SubtitleSource.network('https://example.com/invalid.vtt', label: 'Invalid');
        when(() => mockPlatform.addExternalSubtitle(any(), any())).thenAnswer((_) async => null);

        final result = await manager.addExternalSubtitle(source);

        expect(result, isNull);
      });
    });

    group('removeExternalSubtitle', () {
      test('calls ensureInitialized', () async {
        when(() => mockPlatform.removeExternalSubtitle(any(), any())).thenAnswer((_) async => true);

        await manager.removeExternalSubtitle('track-1');

        // Should not throw (ensureInitialized called successfully)
        verify(() => mockPlatform.removeExternalSubtitle(1, 'track-1')).called(1);
      });

      test('throws when not initialized', () async {
        isInitialized = false;

        expect(() => manager.removeExternalSubtitle('track-1'), throwsStateError);
      });

      test('calls platform removeExternalSubtitle with trackId', () async {
        when(() => mockPlatform.removeExternalSubtitle(any(), any())).thenAnswer((_) async => true);

        final result = await manager.removeExternalSubtitle('track-1');

        expect(result, isTrue);
        verify(() => mockPlatform.removeExternalSubtitle(1, 'track-1')).called(1);
      });

      test('returns false when track not found', () async {
        when(() => mockPlatform.removeExternalSubtitle(any(), any())).thenAnswer((_) async => false);

        final result = await manager.removeExternalSubtitle('nonexistent');

        expect(result, isFalse);
      });

      test('returns platform result', () async {
        when(() => mockPlatform.removeExternalSubtitle(any(), any())).thenAnswer((_) async => true);

        final result = await manager.removeExternalSubtitle('track-2');

        expect(result, isTrue);
      });
    });

    group('getExternalSubtitles', () {
      test('calls ensureInitialized', () async {
        when(() => mockPlatform.getExternalSubtitles(any())).thenAnswer((_) async => []);

        await manager.getExternalSubtitles();

        // Should not throw (ensureInitialized called successfully)
        verify(() => mockPlatform.getExternalSubtitles(1)).called(1);
      });

      test('throws when not initialized', () async {
        isInitialized = false;

        expect(() => manager.getExternalSubtitles(), throwsStateError);
      });

      test('calls platform getExternalSubtitles', () async {
        when(() => mockPlatform.getExternalSubtitles(any())).thenAnswer((_) async => []);

        await manager.getExternalSubtitles();

        verify(() => mockPlatform.getExternalSubtitles(1)).called(1);
      });

      test('returns empty list when no subtitles', () async {
        when(() => mockPlatform.getExternalSubtitles(any())).thenAnswer((_) async => []);

        final result = await manager.getExternalSubtitles();

        expect(result, isEmpty);
      });

      test('returns list of tracks from platform', () async {
        final tracks = [
          const ExternalSubtitleTrack(
            id: 'track-1',
            label: 'English',
            language: 'en',
            path: 'https://example.com/en.vtt',
            sourceType: 'network',
            format: SubtitleFormat.vtt,
          ),
          const ExternalSubtitleTrack(
            id: 'track-2',
            label: 'Spanish',
            language: 'es',
            path: 'https://example.com/es.vtt',
            sourceType: 'network',
            format: SubtitleFormat.vtt,
          ),
        ];
        when(() => mockPlatform.getExternalSubtitles(any())).thenAnswer((_) async => tracks);

        final result = await manager.getExternalSubtitles();

        expect(result, equals(tracks));
        expect(result.length, equals(2));
      });
    });

    group('discoverAndAddSubtitles', () {
      test('does not throw on discovery failure', () async {
        // SubtitleDiscovery is called directly, so we can't easily mock it
        // But the method should not throw even if discovery fails
        expect(
          () => manager.discoverAndAddSubtitles(TestMedia.filePath, SubtitleDiscoveryMode.strict),
          returnsNormally,
        );
      });
    });
  });
}
