import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player/src/controls/desktop_volume_control.dart';

import '../../shared/test_constants.dart';
import '../../shared/test_helpers.dart';
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

  group('DesktopVolumeControl', () {
    group('icon selection', () {
      testWidgets('displays volume_off icon when volume is 0', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0),
        );

        await tester.pumpWidget(
          buildTestWidget(DesktopVolumeControl(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.volume_off);
      });

      testWidgets('displays volume_down icon when volume > 0 and <= 0.5', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0.3),
        );

        await tester.pumpWidget(
          buildTestWidget(DesktopVolumeControl(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.volume_down);
      });

      testWidgets('displays volume_down icon at exactly 0.5', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0.5),
        );

        await tester.pumpWidget(
          buildTestWidget(DesktopVolumeControl(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.volume_down);
      });

      testWidgets('displays volume_up icon when volume > 0.5', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0.8),
        );

        await tester.pumpWidget(
          buildTestWidget(DesktopVolumeControl(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.icon, Icons.volume_up);
      });
    });

    group('mute/unmute button', () {
      testWidgets('shows "Mute" tooltip when unmuted', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0.8),
        );

        await tester.pumpWidget(
          buildTestWidget(DesktopVolumeControl(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final button = tester.widget<IconButton>(find.byType(IconButton));
        expect(button.tooltip, 'Mute');
      });

      testWidgets('shows "Unmute" tooltip when muted', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0),
        );

        await tester.pumpWidget(
          buildTestWidget(DesktopVolumeControl(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final button = tester.widget<IconButton>(find.byType(IconButton));
        expect(button.tooltip, 'Unmute');
      });

      testWidgets('mutes when unmuted', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0.8),
        );

        await tester.pumpWidget(
          buildTestWidget(DesktopVolumeControl(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        // Tap the mute button
        await tester.tap(find.byType(IconButton));
        await tester.pump();

        // Verify setVolume was called with 0.0
        verify(() => fixture.mockPlatform.setVolume(any(), 0)).called(1);
      });

      testWidgets('unmutes when muted', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0),
        );

        await tester.pumpWidget(
          buildTestWidget(DesktopVolumeControl(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        // Tap the unmute button
        await tester.tap(find.byType(IconButton));
        await tester.pump();

        // Verify setVolume was called with 1.0
        verify(() => fixture.mockPlatform.setVolume(any(), 1)).called(1);
      });
    });

    group('volume slider', () {
      testWidgets('displays current volume value', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0.6),
        );

        await tester.pumpWidget(
          buildTestWidget(DesktopVolumeControl(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, 0.6);
      });

      testWidgets('changes volume when slider is dragged', (tester) async {
        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0.5),
        );

        await tester.pumpWidget(
          buildTestWidget(DesktopVolumeControl(controller: controller, theme: VideoPlayerTheme.light())),
        );
        await tester.pump();

        // Find the slider and drag it
        final slider = find.byType(Slider);
        await tester.drag(slider, const Offset(20, 0));
        await tester.pump();

        // Verify setVolume was called (value will vary based on drag)
        verify(() => fixture.mockPlatform.setVolume(any(), any())).called(greaterThan(0));
      });
    });

    group('theme colors', () {
      testWidgets('uses theme primary color for icon and slider', (tester) async {
        final theme = VideoPlayerTheme.light().copyWith(
          primaryColor: Colors.red,
          progressBarInactiveColor: Colors.grey,
        );

        final controller = ProVideoPlayerController();
        await controller.initialize(
          source: const VideoSource.network(TestMedia.networkUrl),
          options: const VideoPlayerOptions(volume: 0.8),
        );

        await tester.pumpWidget(buildTestWidget(DesktopVolumeControl(controller: controller, theme: theme)));
        await tester.pump();

        // Verify icon color
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, Colors.red);

        // Verify slider theme colors
        final sliderTheme = tester.widget<SliderTheme>(find.byType(SliderTheme));
        expect(sliderTheme.data.activeTrackColor, Colors.red);
        expect(sliderTheme.data.thumbColor, Colors.red);
        expect(sliderTheme.data.inactiveTrackColor, Colors.grey);
      });
    });
  });
}
