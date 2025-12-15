import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

class MockVideoControlsController extends Mock implements VideoControlsController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late StreamController<VideoPlayerEvent> eventController;
  late MockVideoControlsController mockControlsController;

  setUpAll(() {
    registerFallbackValue(const VideoSource.network('https://example.com'));
    registerFallbackValue(const VideoPlayerOptions());
  });

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    eventController = StreamController<VideoPlayerEvent>.broadcast();
    mockControlsController = MockVideoControlsController();
    ProVideoPlayerPlatform.instance = mockPlatform;

    when(
      () => mockPlatform.create(
        source: any(named: 'source'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => 1);

    when(() => mockPlatform.events(any())).thenAnswer((_) => eventController.stream);
    when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});

    // Mock controls controller state
    when(() => mockControlsController.controlsState).thenReturn(VideoControlsState()..showControls());
    when(() => mockControlsController.showControls()).thenReturn(null);
    when(() => mockControlsController.toggleControlsVisibility()).thenReturn(null);
    when(() => mockControlsController.resetHideTimer()).thenReturn(null);
  });

  tearDown(() async {
    await eventController.close();
    ProVideoPlayerPlatform.instance = MockProVideoPlayerPlatform();
  });

  group('SimpleTapWrapper', () {
    testWidgets('taps toggle controls visibility when not casting', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleTapWrapper(
              controller: controller,
              controlsController: mockControlsController,
              child: const Center(child: Text('Video')),
            ),
          ),
        ),
      );

      // Tap the wrapper
      await tester.tap(find.byType(SimpleTapWrapper));
      await tester.pump();

      verify(() => mockControlsController.toggleControlsVisibility()).called(1);
    });

    testWidgets('shows controls when tapped during casting', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      // Set casting state
      eventController.add(const CastStateChangedEvent(state: CastState.connected));
      await tester.pump(const Duration(milliseconds: 50));

      // Mock controls as hidden
      when(() => mockControlsController.controlsState).thenReturn(VideoControlsState()..hideControls());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleTapWrapper(
              controller: controller,
              controlsController: mockControlsController,
              child: const Center(child: Text('Video')),
            ),
          ),
        ),
      );

      // Tap the wrapper
      await tester.tap(find.byType(SimpleTapWrapper));
      await tester.pump();

      verify(() => mockControlsController.showControls()).called(1);
      verifyNever(() => mockControlsController.toggleControlsVisibility());
    });

    testWidgets('resets hide timer when controls become visible', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleTapWrapper(
              controller: controller,
              controlsController: mockControlsController,
              child: const Center(child: Text('Video')),
            ),
          ),
        ),
      );

      // Tap the wrapper (controls are visible by default)
      await tester.tap(find.byType(SimpleTapWrapper));
      await tester.pump();

      verify(() => mockControlsController.resetHideTimer()).called(1);
    });

    testWidgets('does not reset hide timer when controls are hidden', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      // Mock controls as hidden
      when(() => mockControlsController.controlsState).thenReturn(VideoControlsState()..hideControls());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleTapWrapper(
              controller: controller,
              controlsController: mockControlsController,
              child: const Center(child: Text('Video')),
            ),
          ),
        ),
      );

      // Tap the wrapper
      await tester.tap(find.byType(SimpleTapWrapper));
      await tester.pump();

      verifyNever(() => mockControlsController.resetHideTimer());
    });

    testWidgets('renders child widget', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleTapWrapper(
              controller: controller,
              controlsController: mockControlsController,
              child: const Center(child: Text('Test Child')),
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('does not intercept child gestures when not casting', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

      var childTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleTapWrapper(
              controller: controller,
              controlsController: mockControlsController,
              child: GestureDetector(
                onTap: () => childTapped = true,
                child: const Center(child: Text('Tappable Child')),
              ),
            ),
          ),
        ),
      );

      // Tap the child
      await tester.tap(find.text('Tappable Child'));
      await tester.pump();

      // Both wrapper and child should receive tap
      expect(childTapped, isTrue);
      verify(() => mockControlsController.toggleControlsVisibility()).called(1);
    });
  });
}
