import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/src/controller/metadata_manager.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late MetadataManager manager;
  late VideoPlayerValue value;
  late int? playerId;
  late bool isInitialized;
  late Duration? seekToPosition;

  setUpAll(registerFallbackValues);

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    playerId = 1;
    isInitialized = true;
    seekToPosition = null;
    value = const VideoPlayerValue();

    manager = MetadataManager(
      getValue: () => value,
      getPlayerId: () => playerId,
      platform: mockPlatform,
      ensureInitialized: () {
        if (!isInitialized) {
          throw StateError('Controller not initialized');
        }
      },
      onSeekTo: (position) async {
        seekToPosition = position;
      },
    );
  });

  group('MetadataManager', () {
    group('fetchVideoMetadata', () {
      test('calls ensureInitialized', () async {
        when(() => mockPlatform.getVideoMetadata(any())).thenAnswer((_) async => null);

        await manager.fetchVideoMetadata();

        // Should not throw (ensureInitialized called successfully)
        verify(() => mockPlatform.getVideoMetadata(1)).called(1);
      });

      test('throws when not initialized', () async {
        isInitialized = false;

        expect(() => manager.fetchVideoMetadata(), throwsStateError);
      });

      test('calls platform getVideoMetadata with playerId', () async {
        when(() => mockPlatform.getVideoMetadata(any())).thenAnswer((_) async => null);

        await manager.fetchVideoMetadata();

        verify(() => mockPlatform.getVideoMetadata(1)).called(1);
      });

      test('returns null when metadata not available', () async {
        when(() => mockPlatform.getVideoMetadata(any())).thenAnswer((_) async => null);

        final metadata = await manager.fetchVideoMetadata();

        expect(metadata, isNull);
      });

      test('returns metadata from platform', () async {
        const expectedMetadata = VideoMetadata(videoCodec: 'h264', width: 1920, height: 1080, videoBitrate: 5000000);
        when(() => mockPlatform.getVideoMetadata(any())).thenAnswer((_) async => expectedMetadata);

        final metadata = await manager.fetchVideoMetadata();

        expect(metadata, equals(expectedMetadata));
      });
    });

    group('setMediaMetadata', () {
      test('calls ensureInitialized', () async {
        when(() => mockPlatform.setMediaMetadata(any(), any())).thenAnswer((_) async {});
        const metadata = MediaMetadata(title: 'Test Title');

        await manager.setMediaMetadata(metadata);

        // Should not throw (ensureInitialized called successfully)
        verify(() => mockPlatform.setMediaMetadata(1, metadata)).called(1);
      });

      test('throws when not initialized', () async {
        isInitialized = false;
        const metadata = MediaMetadata(title: 'Test Title');

        expect(() => manager.setMediaMetadata(metadata), throwsStateError);
      });

      test('calls platform setMediaMetadata with playerId and metadata', () async {
        when(() => mockPlatform.setMediaMetadata(any(), any())).thenAnswer((_) async {});
        const metadata = MediaMetadata(title: 'Test Title', artist: 'Test Artist', album: 'Test Album');

        await manager.setMediaMetadata(metadata);

        verify(() => mockPlatform.setMediaMetadata(1, metadata)).called(1);
      });
    });

    group('seekToChapter', () {
      test('calls ensureInitialized', () async {
        const chapter = Chapter(
          id: 'ch1',
          title: 'Chapter 1',
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 30),
        );

        await manager.seekToChapter(chapter);

        // Should not throw (ensureInitialized called successfully)
        expect(seekToPosition, equals(const Duration(seconds: 10)));
      });

      test('throws when not initialized', () async {
        isInitialized = false;
        const chapter = Chapter(
          id: 'ch1',
          title: 'Chapter 1',
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 30),
        );

        expect(() => manager.seekToChapter(chapter), throwsStateError);
      });

      test('calls onSeekTo with chapter startTime', () async {
        const chapter = Chapter(
          id: 'ch1',
          title: 'Chapter 1',
          startTime: Duration(seconds: 42),
          endTime: Duration(seconds: 100),
        );

        await manager.seekToChapter(chapter);

        expect(seekToPosition, equals(const Duration(seconds: 42)));
      });
    });

    group('seekToNextChapter', () {
      test('returns false when no chapters available', () async {
        value = const VideoPlayerValue().copyWith(chapters: []);

        final result = await manager.seekToNextChapter();

        expect(result, isFalse);
        expect(seekToPosition, isNull);
      });

      test('seeks to first chapter when no current chapter', () async {
        final chapters = [
          const Chapter(id: 'ch1', title: 'Chapter 1', startTime: Duration.zero, endTime: Duration(seconds: 30)),
          const Chapter(
            id: 'ch2',
            title: 'Chapter 2',
            startTime: Duration(seconds: 30),
            endTime: Duration(seconds: 60),
          ),
        ];
        value = const VideoPlayerValue().copyWith(chapters: chapters, position: const Duration(seconds: 5));

        final result = await manager.seekToNextChapter();

        expect(result, isTrue);
        expect(seekToPosition, equals(Duration.zero));
      });

      test('seeks to next chapter when available', () async {
        final chapters = [
          const Chapter(id: 'ch1', title: 'Chapter 1', startTime: Duration.zero, endTime: Duration(seconds: 30)),
          const Chapter(
            id: 'ch2',
            title: 'Chapter 2',
            startTime: Duration(seconds: 30),
            endTime: Duration(seconds: 60),
          ),
          const Chapter(
            id: 'ch3',
            title: 'Chapter 3',
            startTime: Duration(seconds: 60),
            endTime: Duration(seconds: 90),
          ),
        ];
        value = const VideoPlayerValue().copyWith(
          chapters: chapters,
          position: const Duration(seconds: 15), // In chapter 1
          currentChapter: chapters[0], // Explicitly set current chapter
        );

        final result = await manager.seekToNextChapter();

        expect(result, isTrue);
        expect(seekToPosition, equals(const Duration(seconds: 30)));
      });

      test('returns false when already at last chapter', () async {
        final chapters = [
          const Chapter(id: 'ch1', title: 'Chapter 1', startTime: Duration.zero, endTime: Duration(seconds: 30)),
          const Chapter(
            id: 'ch2',
            title: 'Chapter 2',
            startTime: Duration(seconds: 30),
            endTime: Duration(seconds: 60),
          ),
        ];
        value = const VideoPlayerValue().copyWith(
          chapters: chapters,
          position: const Duration(seconds: 45), // In chapter 2 (last)
          currentChapter: chapters[1], // Explicitly set current chapter
        );

        final result = await manager.seekToNextChapter();

        expect(result, isFalse);
        expect(seekToPosition, isNull);
      });

      test('handles single chapter correctly', () async {
        final chapters = [
          const Chapter(id: 'ch1', title: 'Only Chapter', startTime: Duration.zero, endTime: Duration(seconds: 60)),
        ];
        value = const VideoPlayerValue().copyWith(
          chapters: chapters,
          position: const Duration(seconds: 30),
          currentChapter: chapters[0], // Explicitly set current chapter
        );

        final result = await manager.seekToNextChapter();

        expect(result, isFalse);
      });
    });

    group('seekToPreviousChapter', () {
      test('returns false when no chapters available', () async {
        value = const VideoPlayerValue().copyWith(chapters: []);

        final result = await manager.seekToPreviousChapter();

        expect(result, isFalse);
        expect(seekToPosition, isNull);
      });

      test('returns false when no current chapter', () async {
        final chapters = [
          const Chapter(
            id: 'ch1',
            title: 'Chapter 1',
            startTime: Duration(seconds: 10),
            endTime: Duration(seconds: 30),
          ),
        ];
        value = const VideoPlayerValue().copyWith(
          chapters: chapters,
          position: const Duration(seconds: 5), // Before first chapter
        );

        final result = await manager.seekToPreviousChapter();

        expect(result, isFalse);
      });

      test('restarts current chapter when more than 3 seconds elapsed', () async {
        final chapters = [
          const Chapter(id: 'ch1', title: 'Chapter 1', startTime: Duration.zero, endTime: Duration(seconds: 30)),
          const Chapter(
            id: 'ch2',
            title: 'Chapter 2',
            startTime: Duration(seconds: 30),
            endTime: Duration(seconds: 60),
          ),
        ];
        value = const VideoPlayerValue().copyWith(
          chapters: chapters,
          position: const Duration(seconds: 35), // 5 seconds into chapter 2
          currentChapter: chapters[1], // Explicitly set current chapter
        );

        final result = await manager.seekToPreviousChapter();

        expect(result, isTrue);
        expect(seekToPosition, equals(const Duration(seconds: 30))); // Restart chapter 2
      });

      test('goes to previous chapter when less than 3 seconds elapsed', () async {
        final chapters = [
          const Chapter(id: 'ch1', title: 'Chapter 1', startTime: Duration.zero, endTime: Duration(seconds: 30)),
          const Chapter(
            id: 'ch2',
            title: 'Chapter 2',
            startTime: Duration(seconds: 30),
            endTime: Duration(seconds: 60),
          ),
        ];
        value = const VideoPlayerValue().copyWith(
          chapters: chapters,
          position: const Duration(seconds: 31), // 1 second into chapter 2
          currentChapter: chapters[1], // Explicitly set current chapter
        );

        final result = await manager.seekToPreviousChapter();

        expect(result, isTrue);
        expect(seekToPosition, equals(Duration.zero)); // Go to chapter 1
      });

      test('restarts first chapter when at beginning', () async {
        final chapters = [
          const Chapter(id: 'ch1', title: 'Chapter 1', startTime: Duration.zero, endTime: Duration(seconds: 30)),
          const Chapter(
            id: 'ch2',
            title: 'Chapter 2',
            startTime: Duration(seconds: 30),
            endTime: Duration(seconds: 60),
          ),
        ];
        value = const VideoPlayerValue().copyWith(
          chapters: chapters,
          position: const Duration(seconds: 2), // 2 seconds into chapter 1
          currentChapter: chapters[0], // Explicitly set current chapter
        );

        final result = await manager.seekToPreviousChapter();

        expect(result, isTrue);
        expect(seekToPosition, equals(Duration.zero)); // Restart chapter 1
      });

      test('uses exactly 3 seconds as threshold', () async {
        final chapters = [
          const Chapter(id: 'ch1', title: 'Chapter 1', startTime: Duration.zero, endTime: Duration(seconds: 30)),
          const Chapter(
            id: 'ch2',
            title: 'Chapter 2',
            startTime: Duration(seconds: 30),
            endTime: Duration(seconds: 60),
          ),
        ];

        // Exactly 3 seconds - should go to previous
        value = value.copyWith(
          chapters: chapters,
          position: const Duration(seconds: 33), // Exactly 3 seconds into chapter 2
          currentChapter: chapters[1], // Explicitly set current chapter
        );
        final result1 = await manager.seekToPreviousChapter();
        expect(result1, isTrue);
        expect(seekToPosition, equals(Duration.zero)); // Go to chapter 1

        seekToPosition = null;

        // Slightly more than 3 seconds - should restart current
        value = value.copyWith(
          position: const Duration(seconds: 33, milliseconds: 1),
          currentChapter: chapters[1], // Explicitly set current chapter
        );
        final result2 = await manager.seekToPreviousChapter();
        expect(result2, isTrue);
        expect(seekToPosition, equals(const Duration(seconds: 30))); // Restart chapter 2
      });
    });
  });
}
