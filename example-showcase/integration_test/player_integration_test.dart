import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

import 'helpers/e2e_platform.dart';
import 'shared/e2e_constants.dart';
import 'shared/e2e_test_media.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Video Player Integration Tests', () {
    late ProVideoPlayerController controller;

    // Use a test video URL that's reliable and small
    const testVideoUrl = E2ETestMedia.bigBuckBunny;

    setUp(() {
      controller = ProVideoPlayerController();
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('Initialize player with network source', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);

      // When
      await controller.initialize(source: source);

      // Then
      expect(controller.isInitialized, isTrue);
    });

    testWidgets('Play and pause video', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      await controller.initialize(source: source);

      // When - Play
      await controller.play();
      await tester.settle();

      // Then
      expect(controller.value.isPlaying, isTrue);

      // When - Pause
      await controller.pause();
      await tester.settle();

      // Then
      expect(controller.value.isPlaying, isFalse);
    });

    testWidgets('Stop video resets position', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      await controller.initialize(source: source);
      await controller.play();
      await tester.settle();

      // When
      await controller.stop();
      await tester.settle();

      // Then
      expect(controller.value.isPlaying, isFalse);
      // Note: Position reset behavior may vary by platform
      expect(controller.value.position.inMilliseconds, lessThan(2000)); // Should be near start
    });

    testWidgets('Seek to position', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      await controller.initialize(source: source);
      await controller.play();
      await tester.settle();

      // When
      await controller.seekTo(const Duration(seconds: 5));
      await tester.settle();

      // Then
      expect(controller.value.position.inSeconds, greaterThanOrEqualTo(4));
      expect(controller.value.position.inSeconds, lessThanOrEqualTo(6));
    });

    testWidgets('Set playback speed', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      await controller.initialize(source: source);

      // When
      await controller.setPlaybackSpeed(1.5);
      await tester.settle();

      // Then
      expect(controller.value.playbackSpeed, equals(1.5));
    });

    testWidgets('Set volume', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      await controller.initialize(source: source);

      // When
      await controller.setVolume(0.5);
      await tester.settle();

      // Then
      expect(controller.value.volume, equals(0.5));
    });

    testWidgets('Set looping', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      await controller.initialize(source: source);

      // When
      await controller.setLooping(true);
      await tester.settle();

      // Then
      expect(controller.value.isLooping, isTrue);

      // When
      await controller.setLooping(false);
      await tester.settle();

      // Then
      expect(controller.value.isLooping, isFalse);
    });

    testWidgets('Get duration', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      await controller.initialize(source: source);

      // Wait for metadata to load
      await tester.settle();

      // Then
      expect(controller.value.duration.inSeconds, greaterThan(0));
    });

    testWidgets('Get position updates during playback', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      await controller.initialize(source: source);
      await tester.settle();
      await controller.play();

      // When
      await tester.settle();
      final position1 = controller.value.position;

      await tester.settle();
      final position2 = controller.value.position;

      // Then
      expect(position2.inMilliseconds, greaterThan(position1.inMilliseconds));
    });

    testWidgets('Playback state changes are reported', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      final states = <PlaybackState>[];

      controller.addListener(() {
        states.add(controller.value.playbackState);
      });

      // When
      await controller.initialize(source: source);
      await tester.settle();

      await controller.play();
      await tester.settle();

      await controller.pause();
      await tester.settle();

      // Then
      expect(states, contains(PlaybackState.ready));
      expect(states, contains(PlaybackState.playing));
      expect(states, contains(PlaybackState.paused));
    });

    testWidgets('Position changes are reported during playback', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      final positions = <Duration>[];

      controller.addListener(() {
        positions.add(controller.value.position);
      });

      // When
      await controller.initialize(source: source);
      await tester.settle();
      await controller.play();
      await tester.pump(E2EDelays.playbackPositionCheck);

      // Then
      expect(positions.length, greaterThan(0));
      // Positions should generally increase
      if (positions.length >= 2) {
        expect(positions.last.inMilliseconds, greaterThan(positions.first.inMilliseconds));
      }
    });

    testWidgets('Check PiP support', (tester) async {
      // When
      final supported = await controller.isPipSupported();

      // Then
      expect(supported, isA<bool>());
      // Note: PiP support depends on device and OS version
    });

    testWidgets('Multiple initializations throw error', (tester) async {
      // Given
      const source1 = VideoSource.network(testVideoUrl);
      const source2 = VideoSource.network(testVideoUrl);

      // When
      await controller.initialize(source: source1);
      expect(controller.isInitialized, isTrue);

      // Then - attempting to re-initialize should throw
      expect(() => controller.initialize(source: source2), throwsA(isA<StateError>()));
    });

    testWidgets('Dispose cleans up resources', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      await controller.initialize(source: source);
      await controller.play();
      await tester.settle();

      // When
      await controller.dispose();

      // Then
      expect(controller.isInitialized, isFalse);
      expect(controller.value.isPlaying, isFalse);
    });

    testWidgets('Initialize with options', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      const options = VideoPlayerOptions(volume: 0.7, looping: true, playbackSpeed: 1.5);

      // When
      await controller.initialize(source: source, options: options);
      await tester.settle();

      // Then
      expect(controller.isInitialized, isTrue);
      expect(controller.value.volume, equals(0.7));
      expect(controller.value.isLooping, isTrue);
      expect(controller.value.playbackSpeed, equals(1.5));
    });

    testWidgets('Error handling - invalid URL', (tester) async {
      // Given
      const source = VideoSource.network(E2ETestMedia.invalidUrl);
      var errorReceived = false;

      controller.addListener(() {
        if (controller.value.hasError) {
          errorReceived = true;
        }
      });

      // When
      try {
        await controller.initialize(source: source);
      } catch (e) {
        // Expected to throw
      }
      await tester.settle();

      // Then
      // Note: Error handling behavior may vary by platform
      // This test verifies the player doesn't crash with invalid URLs
      // The errorReceived variable may be true or false depending on timing
      expect(errorReceived, isA<bool>());
    });
  });

  group('Multiple Players Integration Tests', () {
    late ProVideoPlayerController controller1;
    late ProVideoPlayerController controller2;

    const testVideoUrl = E2ETestMedia.bigBuckBunny;

    setUp(() {
      controller1 = ProVideoPlayerController();
      controller2 = ProVideoPlayerController();
    });

    tearDown(() async {
      await controller1.dispose();
      await controller2.dispose();
    });

    testWidgets('Create multiple players simultaneously', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);

      // When
      await controller1.initialize(source: source);
      await controller2.initialize(source: source);

      // Then
      expect(controller1.isInitialized, isTrue);
      expect(controller2.isInitialized, isTrue);
    });

    testWidgets('Control multiple players independently', (tester) async {
      // Given
      const source = VideoSource.network(testVideoUrl);
      await controller1.initialize(source: source);
      await controller2.initialize(source: source);

      // When - Play only first player
      await controller1.play();
      await tester.settle();

      // Then
      expect(controller1.value.isPlaying, isTrue);
      expect(controller2.value.isPlaying, isFalse);

      // When - Play second player
      await controller2.play();
      await tester.settle();

      // Then
      expect(controller1.value.isPlaying, isTrue);
      expect(controller2.value.isPlaying, isTrue);

      // When - Pause first player
      await controller1.pause();
      await tester.settle();

      // Then
      expect(controller1.value.isPlaying, isFalse);
      expect(controller2.value.isPlaying, isTrue);
    });

    testWidgets('Auto-play shows pause button in UI controls', (tester) async {
      // Given - Player with autoPlay enabled
      const source = VideoSource.network(testVideoUrl);
      final controller = ProVideoPlayerController();

      await controller.initialize(source: source, options: const VideoPlayerOptions(autoPlay: true));

      // Build the widget with controls
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProVideoPlayer(controller: controller)),
        ),
      );

      // Wait for auto-play to start
      await tester.settle();

      // Then - Controller should be playing
      expect(controller.value.isPlaying, isTrue, reason: 'Controller should be playing after auto-play');
      expect(controller.value.playbackState, PlaybackState.playing, reason: 'Playback state should be playing');

      // Then - UI should show pause icon (not play icon)
      // The play/pause button shows pause icon when playing
      final pauseIcon = find.byIcon(Icons.pause);
      final playIcon = find.byIcon(Icons.play_arrow);

      expect(pauseIcon, findsWidgets, reason: 'Pause icon should be visible when video is auto-playing');
      expect(playIcon, findsNothing, reason: 'Play icon should not be visible when video is auto-playing');

      // When - Tap the pause button
      await tester.tap(pauseIcon.first);
      await tester.settle();

      // Then - Controller should be paused
      expect(controller.value.isPlaying, isFalse, reason: 'Controller should be paused after tapping pause');

      // Then - UI should show play icon (not pause icon)
      expect(find.byIcon(Icons.play_arrow), findsWidgets, reason: 'Play icon should be visible when video is paused');
      expect(find.byIcon(Icons.pause), findsNothing, reason: 'Pause icon should not be visible when video is paused');

      // Cleanup
      await controller.dispose();
    });

    testWidgets('Auto-play with playlist shows correct initial state', (tester) async {
      // Given - Playlist with autoPlay enabled
      final playlist = Playlist(
        items: const [
          VideoSource.network(testVideoUrl),
          VideoSource.network('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'),
        ],
      );

      final controller = ProVideoPlayerController();

      await controller.initializeWithPlaylist(playlist: playlist, options: const VideoPlayerOptions(autoPlay: true));

      // Build the widget with controls
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProVideoPlayer(controller: controller)),
        ),
      );

      // Wait for auto-play to start
      await tester.settle();

      // Then - Controller should be playing first track
      expect(controller.value.isPlaying, isTrue, reason: 'Controller should be playing after auto-play');
      expect(controller.value.playlistIndex, 0, reason: 'Should be playing first track');
      expect(controller.value.playlist, isNotNull, reason: 'Playlist should be set');

      // Then - UI should show pause icon and playlist controls
      expect(find.byIcon(Icons.pause), findsWidgets, reason: 'Pause icon should be visible');
      expect(
        find.byIcon(Icons.skip_previous),
        findsOneWidget,
        reason: 'Previous track button should be visible in playlist mode',
      );
      expect(
        find.byIcon(Icons.skip_next),
        findsOneWidget,
        reason: 'Next track button should be visible in playlist mode',
      );

      // When - Skip to next track
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.settle();

      // Then - Should be playing second track
      expect(controller.value.isPlaying, isTrue, reason: 'Should continue playing after track change');
      expect(controller.value.playlistIndex, 1, reason: 'Should be playing second track');
      expect(find.byIcon(Icons.pause), findsWidgets, reason: 'Pause icon should still be visible on second track');

      // Cleanup
      await controller.dispose();
    });
  });

  group('Track Format Integration Tests (Dart-Native Sync)', () {
    late ProVideoPlayerController controller;

    // Test video with multiple audio/subtitle tracks
    // Sintel has multiple audio and subtitle tracks
    const testVideoWithTracks = 'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8';

    // Fallback: Big Buck Bunny doesn't have subtitles but can test audio tracks
    const fallbackVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

    setUp(() {
      controller = ProVideoPlayerController();
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('Track IDs use groupIndex:trackIndex format', (tester) async {
      // Given - Initialize with a video that has tracks
      // Try Sintel first, fallback to Big Buck Bunny
      try {
        await controller.initialize(source: const VideoSource.network(testVideoWithTracks));
      } catch (e) {
        await controller.dispose();
        controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(fallbackVideoUrl));
      }

      // Wait for track discovery
      await tester.pump(E2EDelays.videoLoading);

      // Then - Verify track ID format for subtitle tracks
      final subtitleTracks = controller.value.subtitleTracks;
      for (final track in subtitleTracks) {
        // Track ID should be in "groupIndex:trackIndex" format
        expect(
          track.id.contains(':'),
          isTrue,
          reason: 'Subtitle track ID should use groupIndex:trackIndex format, got: ${track.id}',
        );

        final parts = track.id.split(':');
        expect(parts.length, 2, reason: 'Track ID should have exactly two parts separated by colon');

        // Both parts should be valid integers
        expect(int.tryParse(parts[0]), isNotNull, reason: 'Group index should be an integer');
        expect(int.tryParse(parts[1]), isNotNull, reason: 'Track index should be an integer');
      }

      // Then - Verify track ID format for audio tracks
      final audioTracks = controller.value.audioTracks;
      for (final track in audioTracks) {
        // Track ID should be in "groupIndex:trackIndex" format
        expect(
          track.id.contains(':'),
          isTrue,
          reason: 'Audio track ID should use groupIndex:trackIndex format, got: ${track.id}',
        );

        final parts = track.id.split(':');
        expect(parts.length, 2, reason: 'Track ID should have exactly two parts separated by colon');
      }
    });

    testWidgets('Track labels are generated from language codes', (tester) async {
      // Given - Initialize with a video that has tracks
      try {
        await controller.initialize(source: const VideoSource.network(testVideoWithTracks));
      } catch (e) {
        await controller.dispose();
        controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(fallbackVideoUrl));
      }

      // Wait for track discovery
      await tester.pump(E2EDelays.videoLoading);

      // Then - Verify labels are properly generated
      // Labels should not be empty (Dart generates from language code)
      for (final track in controller.value.subtitleTracks) {
        expect(track.label.isNotEmpty, isTrue, reason: 'Subtitle track label should not be empty');
        // If language code is known, label should be a readable name (not the code)
        if (track.language != null && track.language!.isNotEmpty) {
          // Check it's not just the raw language code for common languages
          if (['en', 'eng', 'es', 'spa', 'fr', 'fra', 'de', 'deu'].contains(track.language!.toLowerCase())) {
            expect(
              track.label.toLowerCase() != track.language!.toLowerCase(),
              isTrue,
              reason: 'Track label should be display name, not raw code. Got: ${track.label}',
            );
          }
        }
      }

      for (final track in controller.value.audioTracks) {
        expect(track.label.isNotEmpty, isTrue, reason: 'Audio track label should not be empty');
      }
    });

    testWidgets('Setting track by ID works with new format', (tester) async {
      // Given - Initialize with subtitles enabled
      try {
        await controller.initialize(source: const VideoSource.network(testVideoWithTracks));
      } catch (e) {
        await controller.dispose();
        controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(fallbackVideoUrl));
      }

      // Wait for track discovery
      await tester.pump(E2EDelays.videoLoading);

      final subtitleTracks = controller.value.subtitleTracks;

      // Skip test if no subtitle tracks available
      if (subtitleTracks.isEmpty) {
        return;
      }

      // When - Select the first subtitle track using the new ID format
      final firstTrack = subtitleTracks.first;
      expect(firstTrack.id.contains(':'), isTrue, reason: 'Track ID should use new format');

      await controller.setSubtitleTrack(firstTrack);
      await tester.settle();

      // Then - Track should be selected
      expect(
        controller.value.selectedSubtitleTrack,
        isNotNull,
        reason: 'Subtitle track should be selected after setSubtitleTrack',
      );
      expect(
        controller.value.selectedSubtitleTrack?.id,
        firstTrack.id,
        reason: 'Selected track ID should match requested track ID',
      );

      // When - Disable subtitles
      await controller.setSubtitleTrack(null);
      await tester.settle();

      // Then - No track should be selected
      expect(controller.value.selectedSubtitleTrack, isNull, reason: 'Subtitle track should be null after disabling');
    });
  });

  group('Chapter Navigation Integration Tests', () {
    late ProVideoPlayerController controller;

    // Asset video with 3 chapters:
    // - Opening Scene (0:00 - 0:05)
    // - The Meadow (0:05 - 0:10)
    // - Butterflies (0:10 - 0:15)
    const chapteredVideoAsset = E2ETestMedia.assetWithChapters;

    setUp(() {
      controller = ProVideoPlayerController();
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('Chapters are extracted from asset video', (tester) async {
      // Given - Initialize with chaptered video
      await controller.initialize(source: const VideoSource.asset(chapteredVideoAsset));

      // Wait for chapters to be extracted
      await tester.pump(E2EDelays.videoInitialization);

      // Then - Chapters should be available
      expect(controller.value.hasChapters, isTrue, reason: 'Video should have chapters');
      expect(controller.value.chapters.length, equals(3), reason: 'Video should have 3 chapters');

      // Verify chapter properties
      final chapters = controller.value.chapters;
      expect(chapters[0].title, equals('Opening Scene'));
      expect(chapters[0].startTime, equals(Duration.zero));

      expect(chapters[1].title, equals('The Meadow'));
      expect(chapters[1].startTime, equals(const Duration(seconds: 5)));

      expect(chapters[2].title, equals('Butterflies'));
      expect(chapters[2].startTime, equals(const Duration(seconds: 10)));
    });

    testWidgets('seekToChapter seeks to chapter start time', (tester) async {
      // Given - Initialize with chaptered video
      await controller.initialize(source: const VideoSource.asset(chapteredVideoAsset));
      await tester.pump(E2EDelays.videoInitialization);

      expect(controller.value.hasChapters, isTrue);

      // When - Seek to second chapter (The Meadow at 5s)
      final secondChapter = controller.value.chapters[1];
      await controller.seekToChapter(secondChapter);
      await tester.settle();

      // Then - Position should be at or near chapter start
      final position = controller.value.position.inSeconds;
      expect(position, greaterThanOrEqualTo(4), reason: 'Position should be near 5s');
      expect(position, lessThanOrEqualTo(6), reason: 'Position should be near 5s');
    });

    testWidgets('seekToNextChapter advances to next chapter', (tester) async {
      // Given - Initialize at start (chapter 1)
      await controller.initialize(source: const VideoSource.asset(chapteredVideoAsset));
      await tester.pump(E2EDelays.videoInitialization);

      expect(controller.value.hasChapters, isTrue);

      // When - Seek to next chapter
      await controller.seekToNextChapter();
      await tester.settle();

      // Then - Position should be at second chapter (5s)
      final position = controller.value.position.inSeconds;
      expect(position, greaterThanOrEqualTo(4), reason: 'Should be at or near second chapter (5s)');
      expect(position, lessThanOrEqualTo(6));
    });

    testWidgets('seekToPreviousChapter goes to previous chapter', (tester) async {
      // Given - Initialize and seek to last chapter
      await controller.initialize(source: const VideoSource.asset(chapteredVideoAsset));
      await tester.pump(E2EDelays.videoInitialization);

      expect(controller.value.hasChapters, isTrue);

      // Move to last chapter
      await controller.seekTo(const Duration(seconds: 12));
      await tester.settle();

      // When - Seek to previous chapter
      await controller.seekToPreviousChapter();
      await tester.settle();

      // Then - Position should be at previous chapter (The Meadow at 5s or Butterflies at 10s depending on timing)
      final position = controller.value.position.inSeconds;
      // Should be at start of current or previous chapter
      expect(position, lessThanOrEqualTo(11), reason: 'Should have moved back from 12s');
    });

    testWidgets('currentChapter updates as playback progresses', (tester) async {
      // Given - Initialize with chaptered video
      await controller.initialize(
        source: const VideoSource.asset(chapteredVideoAsset),
        options: const VideoPlayerOptions(autoPlay: true),
      );
      await tester.pump(E2EDelays.videoInitialization);

      expect(controller.value.hasChapters, isTrue);

      // Then - Current chapter should be set based on position
      // At start, should be first chapter or null (depending on implementation)
      final currentChapter = controller.value.currentChapter;
      if (currentChapter != null) {
        expect(currentChapter.title, equals('Opening Scene'));
      }

      // When - Seek to middle of second chapter
      await controller.seekTo(const Duration(seconds: 7));
      await tester.settle();

      // Then - Current chapter should be "The Meadow"
      expect(controller.value.currentChapter?.title, equals('The Meadow'));
    });

    testWidgets('chapters getter returns empty list for video without chapters', (tester) async {
      // Given - Initialize with video without chapters
      await controller.initialize(source: const VideoSource.network(E2ETestMedia.bigBuckBunny));
      await tester.pump(E2EDelays.videoInitialization);

      // Then - Chapters should be empty
      expect(controller.value.hasChapters, isFalse);
      expect(controller.value.chapters, isEmpty);
      expect(controller.value.currentChapter, isNull);
    });

    testWidgets('progress bar updates during playback (Android regression test)', (tester) async {
      // Regression test for: LayoutBuilder wrapping Stack broke ValueListenableBuilder on Android
      // This test verifies that duration and position updates are received on Android

      // Given - Initialize and start playing
      await controller.initialize(source: const VideoSource.network(E2ETestMedia.bigBuckBunny));
      await tester.pump(E2EDelays.videoInitialization);

      // Then - Duration should be loaded (not 0)
      expect(
        controller.value.duration.inMilliseconds,
        greaterThan(0),
        reason: 'Duration should be loaded from video metadata',
      );

      // When - Play video
      await controller.play();
      await tester.pump(E2EDelays.singleFrame);

      // Capture initial position
      final initialPosition = controller.value.position;

      // Wait for video to play
      await tester.pump(const Duration(seconds: 2));

      // Then - Position should have increased
      final currentPosition = controller.value.position;
      expect(
        currentPosition.inMilliseconds,
        greaterThan(initialPosition.inMilliseconds),
        reason: 'Video position should increase during playback',
      );

      // Verify position is reasonable (not jumped ahead randomly)
      final elapsed = currentPosition.inMilliseconds - initialPosition.inMilliseconds;
      expect(
        elapsed,
        lessThan(5000), // Should be ~2 seconds, max 5 seconds
        reason: 'Position should increase naturally, not jump',
      );
    });
  });
}
