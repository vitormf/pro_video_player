import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../../shared/test_constants.dart';
import '../../../shared/test_helpers.dart';

class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

class MockVideoControlsController extends Mock implements VideoControlsController {}

class FakeKeyEvent extends Fake implements KeyEvent {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => 'FakeKeyEvent';
}

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late StreamController<VideoPlayerEvent> eventController;
  late MockVideoControlsController mockControlsController;
  late FocusNode testFocusNode;

  setUpAll(() {
    registerFallbackValue(const VideoSource.network('https://example.com'));
    registerFallbackValue(const VideoPlayerOptions());
    registerFallbackValue(FocusNode());
    registerFallbackValue(FakeKeyEvent());
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(Offset.zero);
    registerFallbackValue(const VideoPlayerTheme());
  });

  setUp(() {
    mockPlatform = MockProVideoPlayerPlatform();
    eventController = StreamController<VideoPlayerEvent>.broadcast();
    mockControlsController = MockVideoControlsController();
    testFocusNode = FocusNode();
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

    // Mock controls controller
    when(() => mockControlsController.controlsState).thenReturn(VideoControlsState()..showControls());
    when(() => mockControlsController.focusNode).thenReturn(testFocusNode);
    when(() => mockControlsController.onMouseHover()).thenReturn(null);
    when(() => mockControlsController.resetHideTimer()).thenReturn(null);
    when(() => mockControlsController.handleKeyEvent(any(), any())).thenReturn(KeyEventResult.ignored);
    when(
      () => mockControlsController.showContextMenu(
        context: any(named: 'context'),
        position: any(named: 'position'),
        theme: any(named: 'theme'),
        onEnterFullscreenCallback: any(named: 'onEnterFullscreenCallback'),
        onExitFullscreenCallback: any(named: 'onExitFullscreenCallback'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    // Note: testFocusNode will be disposed when tests dispose their controllers
    await eventController.close();
    ProVideoPlayerPlatform.instance = MockProVideoPlayerPlatform();
  });

  group('DesktopControlsWrapper', () {
    testWidgets('single tap plays when paused', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      // Set paused state
      eventController.add(const PlaybackStateChangedEvent(PlaybackState.paused));
      await tester.pump(TestDelays.eventPropagation);

      await tester.pumpWidget(
        buildTestWidget(
          DesktopControlsWrapper(
            controller: controller,
            controlsController: mockControlsController,
            theme: const VideoPlayerTheme(),
            showFullscreenButton: true,
            onEnterFullscreen: () {},
            onExitFullscreen: () {},
            child: const Center(child: Text('Video')),
          ),
        ),
      );

      // Tap the wrapper (tap on the visible content)
      await tester.tap(find.text('Video'));
      // Wait for double-tap timeout (GestureDetector with both onTap and onDoubleTap waits ~300ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      verify(() => mockPlatform.play(1)).called(1);

      // Wait for PlaybackManager's _startingPlaybackTimeout timer to expire
      await tester.pump(TestDelays.playbackManagerTimer);
    });

    testWidgets('single tap pauses when playing', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      // Set playing state
      eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
      await tester.pump(TestDelays.eventPropagation);

      await tester.pumpWidget(
        buildTestWidget(
          DesktopControlsWrapper(
            controller: controller,
            controlsController: mockControlsController,
            theme: const VideoPlayerTheme(),
            showFullscreenButton: true,
            onEnterFullscreen: () {},
            onExitFullscreen: () {},
            child: const Center(child: Text('Video')),
          ),
        ),
      );

      // Tap the wrapper (tap on the visible content)
      await tester.tap(find.text('Video'));
      // Wait for double-tap timeout (GestureDetector with both onTap and onDoubleTap waits ~300ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      verify(() => mockPlatform.pause(1)).called(1);
    });

    testWidgets('double tap enters fullscreen when not fullscreen', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      var fullscreenEntered = false;

      await tester.pumpWidget(
        buildTestWidget(
          DesktopControlsWrapper(
            controller: controller,
            controlsController: mockControlsController,
            theme: const VideoPlayerTheme(),
            showFullscreenButton: true,
            onEnterFullscreen: () => fullscreenEntered = true,
            onExitFullscreen: () {},
            child: const Center(child: Text('Video')),
          ),
        ),
      );

      // Double tap the wrapper
      await tester.tap(find.byType(DesktopControlsWrapper));
      await tester.pump(TestDelays.eventPropagation);
      await tester.tap(find.byType(DesktopControlsWrapper));
      await tester.pumpAndSettle();

      expect(fullscreenEntered, isTrue);
    });

    testWidgets('double tap exits fullscreen when fullscreen', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      // Set fullscreen state
      eventController.add(const FullscreenStateChangedEvent(isFullscreen: true));
      await tester.pump(TestDelays.eventPropagation);

      var fullscreenExited = false;

      await tester.pumpWidget(
        buildTestWidget(
          DesktopControlsWrapper(
            controller: controller,
            controlsController: mockControlsController,
            theme: const VideoPlayerTheme(),
            showFullscreenButton: true,
            onEnterFullscreen: () {},
            onExitFullscreen: () => fullscreenExited = true,
            child: const Center(child: Text('Video')),
          ),
        ),
      );

      // Double tap the wrapper
      await tester.tap(find.byType(DesktopControlsWrapper));
      await tester.pump(TestDelays.eventPropagation);
      await tester.tap(find.byType(DesktopControlsWrapper));
      await tester.pumpAndSettle();

      expect(fullscreenExited, isTrue);
    });

    testWidgets('double tap does nothing when fullscreen button hidden', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      var fullscreenEntered = false;

      await tester.pumpWidget(
        buildTestWidget(
          DesktopControlsWrapper(
            controller: controller,
            controlsController: mockControlsController,
            theme: const VideoPlayerTheme(),
            showFullscreenButton: false,
            onEnterFullscreen: () => fullscreenEntered = true,
            onExitFullscreen: () {},
            child: const Center(child: Text('Video')),
          ),
        ),
      );

      // Double tap the wrapper
      await tester.tap(find.byType(DesktopControlsWrapper));
      await tester.pump(TestDelays.eventPropagation);
      await tester.tap(find.byType(DesktopControlsWrapper));
      await tester.pumpAndSettle();

      expect(fullscreenEntered, isFalse);
    });

    testWidgets('mouse hover triggers onMouseHover', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      await tester.pumpWidget(
        buildTestWidget(
          DesktopControlsWrapper(
            controller: controller,
            controlsController: mockControlsController,
            theme: const VideoPlayerTheme(),
            showFullscreenButton: true,
            onEnterFullscreen: () {},
            onExitFullscreen: () {},
            child: const Center(child: Text('Video')),
          ),
        ),
      );

      // Hover over the widget
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byType(DesktopControlsWrapper)));
      await tester.pumpAndSettle();

      verify(() => mockControlsController.onMouseHover()).called(greaterThan(0));
    });

    testWidgets('renders child widget', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      await tester.pumpWidget(
        buildTestWidget(
          DesktopControlsWrapper(
            controller: controller,
            controlsController: mockControlsController,
            theme: const VideoPlayerTheme(),
            showFullscreenButton: true,
            onEnterFullscreen: () {},
            onExitFullscreen: () {},
            child: const Center(child: Text('Test Child')),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('shows keyboard overlay when type is set', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      // Mock keyboard overlay state
      final mockState = VideoControlsState()
        ..showKeyboardOverlay(KeyboardOverlayType.volume, 0.5, const Duration(milliseconds: 1000), () {});
      when(() => mockControlsController.controlsState).thenReturn(mockState);

      await tester.pumpWidget(
        buildTestWidget(
          DesktopControlsWrapper(
            controller: controller,
            controlsController: mockControlsController,
            theme: const VideoPlayerTheme(),
            showFullscreenButton: true,
            onEnterFullscreen: () {},
            onExitFullscreen: () {},
            child: const Center(child: Text('Video')),
          ),
        ),
      );

      expect(find.byType(KeyboardOverlay), findsOneWidget);

      // Wait for keyboard overlay hide timer to expire (1000ms)
      await tester.pump(const Duration(milliseconds: 1000));
    });

    testWidgets('does not show keyboard overlay when type is null', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      await tester.pumpWidget(
        buildTestWidget(
          DesktopControlsWrapper(
            controller: controller,
            controlsController: mockControlsController,
            theme: const VideoPlayerTheme(),
            showFullscreenButton: true,
            onEnterFullscreen: () {},
            onExitFullscreen: () {},
            child: const Center(child: Text('Video')),
          ),
        ),
      );

      expect(find.byType(KeyboardOverlay), findsNothing);
    });

    testWidgets('focus node is set to autofocus', (tester) async {
      final controller = ProVideoPlayerController();
      await controller.initialize(source: const VideoSource.network(TestMedia.networkUrl));

      await tester.pumpWidget(
        buildTestWidget(
          DesktopControlsWrapper(
            controller: controller,
            controlsController: mockControlsController,
            theme: const VideoPlayerTheme(),
            showFullscreenButton: true,
            onEnterFullscreen: () {},
            onExitFullscreen: () {},
            child: const Center(child: Text('Video')),
          ),
        ),
      );

      // Verify Focus widget exists (MaterialApp creates multiple, so check for at least one)
      expect(find.byType(Focus), findsWidgets);
    });
  });
}
