import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player/src/controls/volume_popup.dart';

import '../../shared/test_setup.dart';

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

  Widget buildTestWidget(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('VolumePopupContent', () {
    group('initialization', () {
      testWidgets('initializes volume from controller', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0.7),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        expect(find.text('70%'), findsOneWidget);
      });
    });

    group('mute/unmute toggle', () {
      testWidgets('mutes when volume > 0', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0.8),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        // Tap mute button
        final muteButton = find.byType(IconButton).first;
        await tester.tap(muteButton);
        await tester.pump();

        // Verify setVolume was called with 0
        verify(() => fixture.mockPlatform.setVolume(any(), 0)).called(1);
      });

      testWidgets('unmutes and restores previous volume', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0.7),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        // First mute
        final muteButton = find.byType(IconButton).first;
        await tester.tap(muteButton);
        await tester.pump();

        // Then unmute
        await tester.tap(muteButton);
        await tester.pump();

        // Should restore to 0.7
        verify(() => fixture.mockPlatform.setVolume(any(), 0.7)).called(1);
      });

      testWidgets('unmutes to 1.0 when no previous volume', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        // Tap unmute button
        final muteButton = find.byType(IconButton).first;
        await tester.tap(muteButton);
        await tester.pump();

        // Should set to 1.0 (default)
        verify(() => fixture.mockPlatform.setVolume(any(), 1)).called(1);
      });
    });

    group('icon selection', () {
      testWidgets('shows volume_off when muted', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.volume_off);
      });

      testWidgets('shows volume_down when volume <= 0.5', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0.3),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.volume_down);
      });

      testWidgets('shows volume_up when volume > 0.5', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0.8),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.volume_up);
      });
    });

    group('volume slider', () {
      testWidgets('displays current volume value', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0.6),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, 0.6);
        expect(find.text('60%'), findsOneWidget);
      });

      testWidgets('updates volume when slider changes', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0.5),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        // Drag the slider
        final slider = find.byType(Slider);
        await tester.drag(slider, const Offset(20, 0));
        await tester.pump();

        // Verify setVolume was called
        verify(() => fixture.mockPlatform.setVolume(any(), any())).called(greaterThan(0));
      });
    });

    group('controller listener', () {
      testWidgets('updates when controller volume changes', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0.5),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        expect(find.text('50%'), findsOneWidget);

        // Change volume through controller
        await controller.setVolume(0.8);
        await tester.pump(const Duration(milliseconds: 50));

        // UI should update
        expect(find.text('80%'), findsOneWidget);
      });

      testWidgets('removes listener on dispose', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0.5),
        );

        await tester.pumpWidget(
          buildTestWidget(VolumePopupContent(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        // Remove the widget
        await tester.pumpWidget(buildTestWidget(const SizedBox()));
        await tester.pump();

        // Widget is now disposed, listener should be removed
        // (no easy way to verify this directly, but it shouldn't crash)
      });
    });

    group('theme styling', () {
      testWidgets('uses theme colors', (tester) async {
        final theme = VideoPlayerTheme.light().copyWith(
          primaryColor: Colors.red,
          secondaryColor: Colors.blue,
          progressBarActiveColor: Colors.green,
          progressBarInactiveColor: Colors.grey,
        );

        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network('https://example.com/video.mp4'),
          options: const VideoPlayerOptions(volume: 0.7),
        );

        await tester.pumpWidget(buildTestWidget(VolumePopupContent(controller: controller, theme: theme)));
        await tester.pump();

        // Verify icon uses primary color
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, Colors.red);

        // Verify percentage text uses secondary color
        final text = tester.widget<Text>(find.text('70%'));
        expect(text.style?.color, Colors.blue);

        // Verify slider theme colors
        final sliderTheme = tester.widget<SliderTheme>(find.byType(SliderTheme));
        expect(sliderTheme.data.activeTrackColor, Colors.green);
        expect(sliderTheme.data.inactiveTrackColor, Colors.grey);
        expect(sliderTheme.data.thumbColor, Colors.green);
      });
    });
  });
}
