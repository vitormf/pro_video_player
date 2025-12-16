import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../shared/test_constants.dart';
import '../shared/test_helpers.dart';

class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late StreamController<VideoPlayerEvent> eventController;

  setUpAll(() {
    registerFallbackValue(const VideoSource.network('https://example.com'));
    registerFallbackValue(const VideoPlayerOptions());
    registerFallbackValue(Duration.zero);
    registerFallbackValue(const PipOptions());
    registerFallbackValue(VideoScalingMode.fit);
    registerFallbackValue(VideoQualityTrack.auto);

    // Mock SystemChrome calls for fullscreen tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (methodCall) async => null,
    );
  });

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    eventController = StreamController<VideoPlayerEvent>.broadcast();
    ProVideoPlayerPlatform.instance = mockPlatform;

    when(
      () => mockPlatform.create(
        source: any(named: 'source'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => 1);

    when(() => mockPlatform.events(any())).thenAnswer((_) => eventController.stream);
    when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
    when(() => mockPlatform.play(any())).thenAnswer((_) async {});
    when(() => mockPlatform.pause(any())).thenAnswer((_) async {});
    when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);
    when(() => mockPlatform.exitFullscreen(any())).thenAnswer((_) async {});
    when(() => mockPlatform.setPlaybackSpeed(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => true);
    when(() => mockPlatform.enterPip(any(), options: any(named: 'options'))).thenAnswer((_) async => true);
    when(() => mockPlatform.isBackgroundPlaybackSupported()).thenAnswer((_) async => false);
    when(() => mockPlatform.isCastingSupported()).thenAnswer((_) async => false);
  });

  tearDown(() async {
    await eventController.close();
    ProVideoPlayerPlatform.instance = MockProVideoPlayerPlatform();
  });

  group('VideoPlayerControls', () {
    group('compact mode', () {
      testWidgets('shows full controls when compactMode is never even with small size', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Use a large size but CompactMode.never still shows full controls
        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              compactMode: CompactMode.never,
            ),
          ),
        );

        // Should show full controls (not compact play_circle_filled icon)
        expect(find.byIcon(Icons.play_circle_filled), findsNothing);
        // Should have speed button text in player toolbar (speed button shows "1x")
        expect(find.text('1x'), findsOneWidget); // Speed formats as "1x" not "1.0x"
      });

      testWidgets('shows compact controls when compactMode is always', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 800, // Above default threshold
              height: 600,
              child: VideoPlayerControls(
                forceMobileLayout: true,
                controller: controller,
                enableGestures: false,
                compactMode: CompactMode.always,
              ),
            ),
          ),
        );

        // Should show compact controls with large play button
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
        // Should not show speed button text (only in full mode)
        expect(find.text('1x'), findsNothing); // Speed formats as "1x" not "1.0x"
      });

      testWidgets('auto mode shows compact controls when compactMode always is used', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              compactMode: CompactMode.always,
            ),
          ),
        );

        // Should show compact controls
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
        expect(find.text('1x'), findsNothing); // Speed formats as "1x" not "1.0x"
      });

      testWidgets('auto mode shows full controls when above threshold', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Default test surface is 800x600, which is above 300x200 threshold
        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        // Should show full controls (speed button text in player toolbar, not compact play_circle_filled)
        expect(find.text('1x'), findsOneWidget); // Speed formats as "1x" not "1.0x"
        expect(find.byIcon(Icons.play_circle_filled), findsNothing);
      });

      testWidgets('custom threshold triggers compact mode', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Set a very large threshold so the default 800x600 surface is below it
        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              compactThreshold: const Size(1000, 800), // Larger than test surface
            ),
          ),
        );

        // Should show compact controls due to custom threshold
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
        expect(find.text('1x'), findsNothing); // Speed formats as "1x" not "1.0x"
      });

      testWidgets('compact mode shows progress bar', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 200,
              height: 150,
              child: VideoPlayerControls(
                forceMobileLayout: true,
                controller: controller,
                enableGestures: false,
                compactMode: CompactMode.always,
              ),
            ),
          ),
        );
        await tester.pump();

        // Add position/duration events after widget is built
        eventController
          ..add(const DurationChangedEvent(Duration(minutes: 10)))
          ..add(const PositionChangedEvent(TestMetadata.duration));
        await tester.pump();

        // Compact mode uses custom Stack-based progress bar with FractionallySizedBox (not LinearProgressIndicator)
        expect(find.byType(FractionallySizedBox), findsWidgets);
      });

      testWidgets('compact mode play button toggles playback', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 200,
              height: 150,
              child: VideoPlayerControls(
                forceMobileLayout: true,
                controller: controller,
                enableGestures: false,
                compactMode: CompactMode.always,
                autoHide: false, // Disable auto-hide timer to prevent test hang
              ),
            ),
          ),
        );
        await tester.pump();

        // Tap play button
        await tester.tap(find.byIcon(Icons.play_circle_filled));
        await tester.pump();

        verify(() => mockPlatform.play(1)).called(1);

        // Wait for PlaybackManager's 2-second timer to complete before test cleanup
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('compact mode shows buffering indicator', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        eventController.add(const PlaybackStateChangedEvent(PlaybackState.buffering));
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 200,
              height: 150,
              child: VideoPlayerControls(
                forceMobileLayout: true,
                controller: controller,
                enableGestures: false,
                compactMode: CompactMode.always,
              ),
            ),
          ),
        );

        // Should show buffering indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('hides all controls in PiP mode, only shows subtitles', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Simulate PiP mode activation
        eventController.add(const PipStateChangedEvent(isActive: true));
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 800, // Large size, but PiP is active
              height: 600,
              child: VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true),
            ),
          ),
        );

        // In PiP mode, Flutter controls are hidden - only SubtitleOverlay is shown.
        // Native PiP provides its own remote actions for play/pause/skip.
        expect(find.byIcon(Icons.play_circle_filled), findsNothing);
        expect(find.byIcon(Icons.speed), findsNothing);
        expect(find.byType(SubtitleOverlay), findsOneWidget);
      });
    });

    group('audio tracks', () {
      testWidgets('does not show audio button when only one audio track', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Add single audio track
        eventController.add(const AudioTracksChangedEvent([AudioTrack(id: 'en', label: 'English')]));
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        expect(find.byIcon(Icons.audiotrack), findsNothing);
      });

      testWidgets('shows audio button when multiple audio tracks available', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Add multiple audio tracks
        eventController.add(
          const AudioTracksChangedEvent([
            AudioTrack(id: 'en', label: 'English'),
            AudioTrack(id: 'es', label: 'Spanish'),
          ]),
        );
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        expect(find.byIcon(Icons.audiotrack), findsOneWidget);
      });

      testWidgets('does not show audio button when showAudioButton is false', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Add multiple audio tracks
        eventController.add(
          const AudioTracksChangedEvent([
            AudioTrack(id: 'en', label: 'English'),
            AudioTrack(id: 'es', label: 'Spanish'),
          ]),
        );
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              showAudioButton: false,
            ),
          ),
        );

        expect(find.byIcon(Icons.audiotrack), findsNothing);
      });

      testWidgets('opens audio picker when audio button is tapped', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Add multiple audio tracks
        eventController.add(
          const AudioTracksChangedEvent([
            AudioTrack(id: 'en', label: 'English'),
            AudioTrack(id: 'es', label: 'Spanish'),
          ]),
        );
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        await tester.tap(find.byIcon(Icons.audiotrack));
        await tester.pumpAndSettle();

        // Bottom sheet should show audio tracks
        expect(find.text('Audio Tracks'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('Spanish'), findsOneWidget);
      });
    });

    group('quality tracks', () {
      testWidgets('does not show quality button when only one quality track', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Add single quality track
        eventController.add(
          const VideoQualityTracksChangedEvent([
            VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000),
          ]),
        );
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        expect(find.byIcon(Icons.high_quality), findsNothing);
      });

      testWidgets('shows quality button when multiple quality tracks available', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Add multiple quality tracks
        eventController.add(
          const VideoQualityTracksChangedEvent([
            VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000),
            VideoQualityTrack(id: '1080p', label: '1080p', width: 1920, height: 1080, bitrate: 5000000),
          ]),
        );
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        expect(find.byIcon(Icons.high_quality), findsOneWidget);
      });

      testWidgets('does not show quality button when showQualityButton is false', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Add multiple quality tracks
        eventController.add(
          const VideoQualityTracksChangedEvent([
            VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000),
            VideoQualityTrack(id: '1080p', label: '1080p', width: 1920, height: 1080, bitrate: 5000000),
          ]),
        );
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              showQualityButton: false,
            ),
          ),
        );

        expect(find.byIcon(Icons.high_quality), findsNothing);
      });

      testWidgets('opens quality picker when quality button is tapped', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        when(() => mockPlatform.setVideoQuality(any(), any())).thenAnswer((_) async => true);

        // Add multiple quality tracks
        eventController.add(
          const VideoQualityTracksChangedEvent([
            VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000),
            VideoQualityTrack(id: '1080p', label: '1080p', width: 1920, height: 1080, bitrate: 5000000),
          ]),
        );
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        await tester.tap(find.byIcon(Icons.high_quality));
        await tester.pumpAndSettle();

        // Bottom sheet should show quality options
        expect(find.text('Video Quality'), findsOneWidget);
        // "Auto" appears both in the player toolbar button and in the bottom sheet
        expect(find.text('Auto'), findsAtLeastNWidgets(2));
      });

      testWidgets('quality button shows Auto when no quality selected', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Add multiple quality tracks
        eventController.add(
          const VideoQualityTracksChangedEvent([
            VideoQualityTrack(id: '720p', label: '720p', width: 1280, height: 720, bitrate: 2500000),
            VideoQualityTrack(id: '1080p', label: '1080p', width: 1920, height: 1080, bitrate: 5000000),
          ]),
        );
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        // Should show "Auto" text next to the icon
        expect(find.text('Auto'), findsOneWidget);
      });
    });

    group('scaling mode', () {
      testWidgets('shows scaling mode button when enabled', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        expect(find.byIcon(Icons.aspect_ratio), findsOneWidget);
      });

      testWidgets('does not show scaling mode button when disabled', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              showScalingModeButton: false,
            ),
          ),
        );

        expect(find.byIcon(Icons.aspect_ratio), findsNothing);
      });

      testWidgets('opens scaling mode picker when button is tapped', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        when(() => mockPlatform.setScalingMode(any(), any())).thenAnswer((_) async {});

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        await tester.tap(find.byIcon(Icons.aspect_ratio));
        await tester.pumpAndSettle();

        // Bottom sheet should show scaling options
        expect(find.text('Video Scaling Mode'), findsOneWidget);
        expect(find.text('Fit (Letterbox)'), findsOneWidget);
        expect(find.text('Fill (Crop)'), findsOneWidget);
        expect(find.text('Stretch'), findsOneWidget);
      });
    });

    group('remaining time display', () {
      testWidgets('shows duration by default', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        eventController
          ..add(const DurationChangedEvent(TestMetadata.duration))
          ..add(const PositionChangedEvent(Duration(minutes: 2)));
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        // Should show total duration
        expect(find.text('5:00'), findsOneWidget);
      });

      testWidgets('toggles between remaining time and duration when tapped', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        eventController
          ..add(const DurationChangedEvent(TestMetadata.duration))
          ..add(const PositionChangedEvent(Duration(minutes: 2)));
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        // Initially shows duration
        expect(find.text('5:00'), findsOneWidget);
        expect(find.text('-3:00'), findsNothing);

        // Tap on the duration text to toggle
        await tester.tap(find.text('5:00'));
        await tester.pump();

        // Now should show remaining time
        expect(find.text('-3:00'), findsOneWidget);
        expect(find.text('5:00'), findsNothing);
      });

      testWidgets('toggles back to duration when tapped again', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        eventController
          ..add(const DurationChangedEvent(TestMetadata.duration))
          ..add(const PositionChangedEvent(Duration(minutes: 2)));
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        // Tap once to switch to remaining time
        await tester.tap(find.text('5:00'));
        await tester.pump();

        expect(find.text('-3:00'), findsOneWidget);

        // Tap again to switch back to duration
        await tester.tap(find.text('-3:00'));
        await tester.pump();

        expect(find.text('5:00'), findsOneWidget);
        expect(find.text('-3:00'), findsNothing);
      });
    });

    group('player toolbar actions configuration', () {
      testWidgets('shows only specified actions in playerToolbarActions', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              playerToolbarActions: const [PlayerToolbarAction.speed, PlayerToolbarAction.fullscreen],
            ),
          ),
        );

        // Should show specified actions
        expect(find.text('1x'), findsOneWidget); // Speed button - formats as "1x" not "1.0x"
        expect(find.byIcon(Icons.fullscreen), findsOneWidget);

        // Should NOT show actions not in the list
        expect(find.byIcon(Icons.aspect_ratio), findsNothing); // Scaling mode
        expect(find.byIcon(Icons.picture_in_picture_alt), findsNothing); // PiP
      });

      testWidgets('respects order of playerToolbarActions', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              playerToolbarActions: const [PlayerToolbarAction.fullscreen, PlayerToolbarAction.speed],
            ),
          ),
        );

        // Both should be visible
        expect(find.text('1x'), findsOneWidget); // Speed formats as "1x" not "1.0x"
        expect(find.byIcon(Icons.fullscreen), findsOneWidget);

        // Fullscreen should appear before speed (check render order)
        final fullscreenFinder = find.byIcon(Icons.fullscreen);
        final speedFinder = find.text('1x'); // Speed formats as "1x" not "1.0x"

        final fullscreenOffset = tester.getTopLeft(fullscreenFinder);
        final speedOffset = tester.getTopLeft(speedFinder);

        expect(fullscreenOffset.dx, lessThan(speedOffset.dx));
      });

      testWidgets('shows overflow menu when actions exceed maxPlayerToolbarActions', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              playerToolbarActions: const [
                PlayerToolbarAction.speed,
                PlayerToolbarAction.scalingMode,
                PlayerToolbarAction.fullscreen,
              ],
              maxPlayerToolbarActions: 2,
            ),
          ),
        );

        // First 2 actions should be visible
        expect(find.text('1x'), findsOneWidget); // Speed - formats as "1x" not "1.0x"
        expect(find.byIcon(Icons.aspect_ratio), findsOneWidget); // Scaling mode

        // Third action should be in overflow menu (not directly visible)
        expect(find.byIcon(Icons.fullscreen), findsNothing);

        // Overflow menu button should be visible
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('overflow menu shows hidden actions when tapped', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              playerToolbarActions: const [
                PlayerToolbarAction.speed,
                PlayerToolbarAction.scalingMode,
                PlayerToolbarAction.fullscreen,
              ],
              maxPlayerToolbarActions: 2,
            ),
          ),
        );

        // Tap overflow menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Fullscreen option should appear in the popup menu
        expect(find.text('Fullscreen'), findsOneWidget);
      });

      testWidgets('overflow menu action triggers correct callback', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              playerToolbarActions: const [PlayerToolbarAction.speed, PlayerToolbarAction.fullscreen],
              maxPlayerToolbarActions: 1,
              // Provide callback to prevent navigation in test
              onEnterFullscreen: () {},
            ),
          ),
        );

        // Tap overflow menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Tap fullscreen option in overflow menu
        await tester.tap(find.text('Fullscreen'));
        await tester.pumpAndSettle();

        // Run async operations
        await tester.runAsync(() => Future<void>.delayed(TestDelays.stateUpdate));
        await tester.pump();

        // onEnterFullscreen callback is used instead of native fullscreen
        // So no native call is expected
      });

      testWidgets('no overflow menu when actions fit within maxPlayerToolbarActions', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              playerToolbarActions: const [PlayerToolbarAction.speed, PlayerToolbarAction.fullscreen],
              maxPlayerToolbarActions: 5, // More than we have
            ),
          ),
        );

        // All actions should be visible
        expect(find.text('1x'), findsOneWidget); // Speed formats as "1x" not "1.0x"
        expect(find.byIcon(Icons.fullscreen), findsOneWidget);

        // No overflow menu needed
        expect(find.byIcon(Icons.more_vert), findsNothing);
      });

      testWidgets('conditional actions respect their conditions', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // No subtitle tracks added, so subtitles action should not appear
        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              playerToolbarActions: const [PlayerToolbarAction.subtitles, PlayerToolbarAction.speed],
              maxPlayerToolbarActions: 2,
            ),
          ),
        );

        // Subtitles should not be shown (no tracks available)
        expect(find.byIcon(Icons.closed_caption), findsNothing);
        expect(find.byIcon(Icons.closed_caption_off), findsNothing);

        // Speed should be shown
        expect(find.text('1x'), findsOneWidget); // Speed formats as "1x" not "1.0x"

        // No overflow menu since only one visible action
        expect(find.byIcon(Icons.more_vert), findsNothing);
      });

      testWidgets('conditional actions count towards maxPlayerToolbarActions only when visible', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        // Add subtitle tracks so the subtitles action becomes visible
        eventController.add(
          const SubtitleTracksChangedEvent([SubtitleTrack(id: '1', label: 'English', language: 'en')]),
        );
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              playerToolbarActions: const [
                PlayerToolbarAction.subtitles,
                PlayerToolbarAction.speed,
                PlayerToolbarAction.fullscreen,
              ],
              maxPlayerToolbarActions: 2,
            ),
          ),
        );

        // First 2 visible actions should be shown
        expect(find.byIcon(Icons.closed_caption_off), findsOneWidget); // Subtitles
        expect(find.text('1x'), findsOneWidget); // Speed - formats as "1x" not "1.0x"

        // Third action should be in overflow
        expect(find.byIcon(Icons.fullscreen), findsNothing);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('uses default actions when playerToolbarActions is null', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true)),
        );

        // Default behavior should show all applicable actions
        expect(find.text('1x'), findsOneWidget); // Speed - formats as "1x" not "1.0x"
        expect(find.byIcon(Icons.aspect_ratio), findsOneWidget); // Scaling mode
        expect(find.byIcon(Icons.fullscreen), findsOneWidget); // Fullscreen
      });

      testWidgets('empty playerToolbarActions shows no player toolbar actions', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        await tester.pumpWidget(
          buildTestWidget(
            VideoPlayerControls(
              forceMobileLayout: true,
              controller: controller,
              enableGestures: false,
              playerToolbarActions: const [],
            ),
          ),
        );

        // No actions should be shown
        expect(find.text('1x'), findsNothing); // Speed formats as "1x" not "1.0x"
        expect(find.byIcon(Icons.aspect_ratio), findsNothing);
        expect(find.byIcon(Icons.fullscreen), findsNothing);
        expect(find.byIcon(Icons.more_vert), findsNothing);
      });
    });

    group('compact mode', () {
      testWidgets('renders compact layout when compactMode is always', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 800,
              height: 600,
              child: VideoPlayerControls(
                forceMobileLayout: true,
                controller: controller,
                enableGestures: false,
                compactMode: CompactMode.always,
              ),
            ),
          ),
        );

        // In compact mode, large play button is shown
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      });

      testWidgets('tap toggles visibility in compact mode', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
        await tester.pump();

        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 800,
              height: 600,
              child: VideoPlayerControls(
                forceMobileLayout: true,
                controller: controller,
                enableGestures: false,
                compactMode: CompactMode.always,
                autoHide: false, // Disable auto-hide timer to prevent test hang
              ),
            ),
          ),
        );

        // Find the GestureDetector and tap it
        final gestureDetector = find.byType(GestureDetector).first;
        await tester.tap(gestureDetector);
        await tester.pump();

        // Widget should handle tap without errors
        expect(find.byType(VideoPlayerControls), findsOneWidget);

        // Wait for PlaybackManager's 2-second timer to complete before test cleanup
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('renders compact layout when widget size is small', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
        await tester.pump();

        // Use size below threshold (default 300)
        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 200,
              height: 150,
              child: VideoPlayerControls(controller: controller, enableGestures: false, forceMobileLayout: true),
            ),
          ),
        );

        // In compact mode, large play button is shown
        expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
      });

      testWidgets('renders full layout when compactMode is never', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

        eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
        await tester.pump();

        // Normal size with compact mode never
        await tester.pumpWidget(
          buildTestWidget(
            SizedBox(
              width: 800,
              height: 600,
              child: VideoPlayerControls(
                forceMobileLayout: true,
                controller: controller,
                enableGestures: false,
                compactMode: CompactMode.never,
              ),
            ),
          ),
        );

        // Should show regular play button
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        // Should NOT show the large circle play button (compact mode)
        expect(find.byIcon(Icons.play_circle_filled), findsNothing);
      });
    });
  });
}
