import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('macOS Video Rendering Tests', () {
    // Only run these tests on macOS
    if (!Platform.isMacOS) {
      return;
    }

    testWidgets('Video player should render video content', (tester) async {
      // Create a controller
      final controller = ProVideoPlayerController();

      // Build the widget tree with the video player
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 640, height: 360, child: ProVideoPlayer(controller: controller)),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initialize with a test video
      await controller.initialize(
        source: const VideoSource.network(
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
        options: const VideoPlayerOptions(autoPlay: true),
      );

      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify the player is initialized
      expect(controller.isInitialized, isTrue);
      expect(controller.playerId, isNotNull);

      // Wait for video to start playing
      await tester.pump(const Duration(milliseconds: 500));

      // Check that the player is in playing state
      expect(controller.value.isPlaying, isTrue);

      // Wait a bit more to allow video to render
      await tester.pump(const Duration(seconds: 2));

      // Check that position is advancing (video is actually playing)
      final position1 = controller.value.position;
      await tester.pump(const Duration(seconds: 1));
      final position2 = controller.value.position;

      expect(position2, greaterThan(position1));

      // Check that we have video dimensions
      expect(controller.value.size, isNotNull);
      expect(controller.value.size!.width, greaterThan(0));
      expect(controller.value.size!.height, greaterThan(0));

      // Clean up
      await controller.dispose();
    });

    testWidgets('Video player with native controls should render', (tester) async {
      final controller = ProVideoPlayerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 640,
                height: 360,
                child: ProVideoPlayer(controller: controller, controlsMode: ControlsMode.native),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await controller.initialize(
        source: const VideoSource.network(
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(controller.isInitialized, isTrue);

      // Play the video
      await controller.play();
      await tester.pump(const Duration(seconds: 2));

      expect(controller.value.isPlaying, isTrue);

      // Check position is advancing
      final position1 = controller.value.position;
      await tester.pump(const Duration(seconds: 1));
      final position2 = controller.value.position;

      expect(position2, greaterThan(position1));

      await controller.dispose();
    });

    testWidgets('Multiple video players can render simultaneously', (tester) async {
      final controller1 = ProVideoPlayerController();
      final controller2 = ProVideoPlayerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(width: 320, height: 180, child: ProVideoPlayer(controller: controller1)),
                const SizedBox(height: 16),
                SizedBox(width: 320, height: 180, child: ProVideoPlayer(controller: controller2)),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initialize both players
      await Future.wait([
        controller1.initialize(
          source: const VideoSource.network(
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          ),
          options: const VideoPlayerOptions(autoPlay: true),
        ),
        controller2.initialize(
          source: const VideoSource.network(
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          ),
          options: const VideoPlayerOptions(autoPlay: true),
        ),
      ]);

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(controller1.isInitialized, isTrue);
      expect(controller2.isInitialized, isTrue);
      expect(controller1.value.isPlaying, isTrue);
      expect(controller2.value.isPlaying, isTrue);

      // Wait and verify both are playing
      await tester.pump(const Duration(seconds: 2));

      final pos1a = controller1.value.position;
      final pos2a = controller2.value.position;

      await tester.pump(const Duration(seconds: 1));

      final pos1b = controller1.value.position;
      final pos2b = controller2.value.position;

      expect(pos1b, greaterThan(pos1a));
      expect(pos2b, greaterThan(pos2a));

      await controller1.dispose();
      await controller2.dispose();
    });

    testWidgets('Video player should handle play/pause correctly', (tester) async {
      final controller = ProVideoPlayerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 640, height: 360, child: ProVideoPlayer(controller: controller)),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await controller.initialize(
        source: const VideoSource.network(
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Play
      await controller.play();
      await tester.pump(const Duration(seconds: 1));
      expect(controller.value.isPlaying, isTrue);

      // Verify position advances
      final pos1 = controller.value.position;
      await tester.pump(const Duration(milliseconds: 500));
      final pos2 = controller.value.position;
      expect(pos2, greaterThan(pos1));

      // Pause
      await controller.pause();
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.value.isPlaying, isFalse);

      // Verify position doesn't advance when paused
      final pos3 = controller.value.position;
      await tester.pump(const Duration(milliseconds: 500));
      final pos4 = controller.value.position;
      expect((pos4 - pos3).inMilliseconds.abs(), lessThan(100));

      await controller.dispose();
    });
  });
}
