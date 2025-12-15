import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';

class MockProVideoPlayerController extends Mock implements ProVideoPlayerController {}

void main() {
  group('SubtitleOverlay', () {
    late MockProVideoPlayerController mockController;

    setUp(() {
      mockController = MockProVideoPlayerController();
    });

    testWidgets('renders nothing when no subtitle track is selected', (tester) async {
      when(() => mockController.value).thenReturn(const VideoPlayerValue());

      await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders nothing for embedded subtitle track', (tester) async {
      const embeddedTrack = SubtitleTrack(id: '0:1', label: 'English', language: 'en');

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: embeddedTrack, position: Duration(seconds: 5)));

      await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

      // Should not render anything for embedded tracks - native handles those
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders subtitle cue text when cue is active', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [
          SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello, world!'),
          SubtitleCue(index: 2, start: Duration(seconds: 6), end: Duration(seconds: 10), text: 'Goodbye, world!'),
        ],
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

      await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

      expect(find.text('Hello, world!'), findsOneWidget);
      expect(find.text('Goodbye, world!'), findsNothing);
    });

    testWidgets('renders nothing when no cue is active', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [SubtitleCue(index: 1, start: Duration(seconds: 5), end: Duration(seconds: 10), text: 'Hello, world!')],
      );

      when(() => mockController.value).thenReturn(
        const VideoPlayerValue(
          selectedSubtitleTrack: externalTrack,
          position: Duration(seconds: 2), // Before any cue
        ),
      );

      await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

      expect(find.text('Hello, world!'), findsNothing);
    });

    testWidgets('renders nothing when external track has no cues', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 5)));

      await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders nothing when cue text is empty', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [
          SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: ''),
          SubtitleCue(index: 2, start: Duration(seconds: 6), end: Duration(seconds: 10), text: '   '),
        ],
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: SubtitleOverlay(
              controller: mockController,
              style: const SubtitleStyle(backgroundColor: Color(0x80000000)),
            ),
          ),
        ),
      );

      // No text should be rendered for empty cue
      expect(find.byType(Text), findsNothing);
      // No background container should be shown
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders multiple overlapping cues simultaneously', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [
          // Overlapping cues (e.g., for karaoke or multi-speaker)
          SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Speaker 1: Hello'),
          SubtitleCue(index: 2, start: Duration(seconds: 2), end: Duration(seconds: 6), text: 'Speaker 2: Hi there'),
          SubtitleCue(index: 3, start: Duration(seconds: 7), end: Duration(seconds: 10), text: 'Non-overlapping'),
        ],
      );

      // Position 3s is within both cue 1 (1-5s) and cue 2 (2-6s)
      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(width: 400, height: 300, child: SubtitleOverlay(controller: mockController)),
        ),
      );

      // Both overlapping cues should be visible
      expect(find.text('Speaker 1: Hello'), findsOneWidget);
      expect(find.text('Speaker 2: Hi there'), findsOneWidget);
      // Non-overlapping cue should not be visible
      expect(find.text('Non-overlapping'), findsNothing);
    });

    testWidgets('renders single cue when only one is active at position', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [
          SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'First cue'),
          SubtitleCue(index: 2, start: Duration(seconds: 6), end: Duration(seconds: 10), text: 'Second cue'),
        ],
      );

      // Position 2s is only within cue 1
      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 2)));

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(width: 400, height: 300, child: SubtitleOverlay(controller: mockController)),
        ),
      );

      // Only first cue should be visible
      expect(find.text('First cue'), findsOneWidget);
      expect(find.text('Second cue'), findsNothing);
    });

    testWidgets('overlapping cues are stacked vertically in a Column', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [
          SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 10), text: 'Top subtitle'),
          SubtitleCue(index: 2, start: Duration(seconds: 1), end: Duration(seconds: 10), text: 'Bottom subtitle'),
        ],
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 5)));

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(width: 400, height: 300, child: SubtitleOverlay(controller: mockController)),
        ),
      );

      // Both cues should be visible
      expect(find.text('Top subtitle'), findsOneWidget);
      expect(find.text('Bottom subtitle'), findsOneWidget);

      // Should be in a Column for vertical stacking
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('updates when position changes', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [
          SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'First cue'),
          SubtitleCue(index: 2, start: Duration(seconds: 6), end: Duration(seconds: 10), text: 'Second cue'),
        ],
      );

      final valueNotifier = ValueNotifier<VideoPlayerValue>(
        const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)),
      );

      when(() => mockController.value).thenAnswer((_) => valueNotifier.value);
      when(() => mockController.addListener(any())).thenAnswer((invocation) {
        valueNotifier.addListener(invocation.positionalArguments[0] as VoidCallback);
      });
      when(() => mockController.removeListener(any())).thenAnswer((invocation) {
        valueNotifier.removeListener(invocation.positionalArguments[0] as VoidCallback);
      });

      await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

      expect(find.text('First cue'), findsOneWidget);
      expect(find.text('Second cue'), findsNothing);

      // Simulate position change
      valueNotifier.value = const VideoPlayerValue(
        selectedSubtitleTrack: externalTrack,
        position: Duration(seconds: 7),
      );
      await tester.pump();

      expect(find.text('First cue'), findsNothing);
      expect(find.text('Second cue'), findsOneWidget);
    });

    testWidgets('renders multiline subtitles', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [
          SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Line one\nLine two'),
        ],
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

      await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

      expect(find.text('Line one\nLine two'), findsOneWidget);
    });

    testWidgets('applies default styling', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello')],
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

      await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.style?.color, Colors.white);
      // Font size calculated from container height * default fontSizePercent (0.04)
      expect(text.style?.fontSize, greaterThan(0));
    });

    testWidgets('applies custom text style', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello')],
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

      await tester.pumpWidget(
        MaterialApp(
          home: SubtitleOverlay(
            controller: mockController,
            style: const SubtitleStyle(textColor: Colors.yellow),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.style?.color, Colors.yellow);
    });

    testWidgets('positions subtitles at bottom with padding', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello')],
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(height: 400, width: 600, child: SubtitleOverlay(controller: mockController)),
        ),
      );

      // The subtitle should be positioned towards the bottom
      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.bottom, isNotNull);
      expect(positioned.left, 0);
      expect(positioned.right, 0);
    });

    testWidgets('respects bottomPadding parameter', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello')],
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 400,
            width: 600,
            child: SubtitleOverlay(controller: mockController, style: const SubtitleStyle(marginFromEdge: 100)),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.bottom, 100);
    });

    testWidgets('has text shadow for readability', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello')],
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

      await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.style?.shadows, isNotNull);
      expect(text.style!.shadows!.isNotEmpty, isTrue);
    });

    testWidgets('has transparent background by default', (tester) async {
      const externalTrack = ExternalSubtitleTrack(
        id: 'ext-0',
        label: 'English',
        path: 'https://example.com/subs.srt',
        sourceType: 'network',
        format: SubtitleFormat.srt,
        language: 'en',
        cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Hello')],
      );

      when(
        () => mockController.value,
      ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

      await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

      // Find the Container that wraps the text
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.transparent);
    });

    group('subtitle offset', () {
      testWidgets('applies positive offset (delays subtitles)', (tester) async {
        // Cue is at 5-10 seconds. With +2s offset, it should appear at position 3-8.
        // At position 5, the cue SHOULD be visible (5 is within 3-8 adjusted window)
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [
            SubtitleCue(index: 1, start: Duration(seconds: 5), end: Duration(seconds: 10), text: 'Hello with offset'),
          ],
        );

        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: externalTrack,
            position: Duration(seconds: 3), // Before cue normally
            subtitleOffset: Duration(seconds: 2), // +2s offset means show earlier
          ),
        );

        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

        // With +2s offset, position 3 + 2 = 5, which is within [5, 10)
        expect(find.text('Hello with offset'), findsOneWidget);
      });

      testWidgets('applies negative offset (shows subtitles earlier)', (tester) async {
        // Cue is at 5-10 seconds. With -2s offset, effective position is lower.
        // At position 7, effective position is 7-2=5, which is within [5, 10)
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [
            SubtitleCue(
              index: 1,
              start: Duration(seconds: 5),
              end: Duration(seconds: 10),
              text: 'Hello with negative offset',
            ),
          ],
        );

        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: externalTrack,
            position: Duration(seconds: 12), // After cue normally
            subtitleOffset: Duration(seconds: -3), // -3s offset
          ),
        );

        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

        // With -3s offset, position 12 - 3 = 9, which is within [5, 10)
        expect(find.text('Hello with negative offset'), findsOneWidget);
      });

      testWidgets('zero offset has no effect', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [
            SubtitleCue(index: 1, start: Duration(seconds: 5), end: Duration(seconds: 10), text: 'Normal subtitle'),
          ],
        );

        when(
          () => mockController.value,
        ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 7)));

        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

        expect(find.text('Normal subtitle'), findsOneWidget);
      });

      testWidgets('offset hides subtitle when adjusted position is out of range', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [
            SubtitleCue(index: 1, start: Duration(seconds: 5), end: Duration(seconds: 10), text: 'Should be hidden'),
          ],
        );

        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: externalTrack,
            position: Duration(seconds: 7), // Within cue range
            subtitleOffset: Duration(seconds: -10), // Large negative offset
          ),
        );

        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

        // With -10s offset, position 7 - 10 = -3, which is before the cue
        expect(find.text('Should be hidden'), findsNothing);
      });
    });

    group('SubtitleStyle', () {
      testWidgets('applies SubtitleStyle text color and size', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [
            SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Styled subtitle'),
          ],
        );

        when(
          () => mockController.value,
        ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

        await tester.pumpWidget(
          MaterialApp(
            home: SubtitleOverlay(
              controller: mockController,
              style: const SubtitleStyle(fontSizePercent: 1.5, textColor: Colors.yellow),
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('Styled subtitle'));
        // Font size calculated from container height * base (0.04) * fontSizePercent (1.5)
        expect(text.style?.fontSize, greaterThan(0));
        expect(text.style?.color, Colors.yellow);
      });

      testWidgets('positions subtitles at top when position is top', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Top subtitle')],
        );

        when(
          () => mockController.value,
        ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              height: 400,
              width: 600,
              child: SubtitleOverlay(
                controller: mockController,
                style: const SubtitleStyle(position: SubtitlePosition.top, marginFromEdge: 32),
              ),
            ),
          ),
        );

        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.top, 32.0);
        expect(positioned.bottom, isNull);
      });

      testWidgets('renders stroke when strokeColor and strokeWidth are set', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Stroked text')],
        );

        when(
          () => mockController.value,
        ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

        await tester.pumpWidget(
          MaterialApp(
            home: SubtitleOverlay(
              controller: mockController,
              style: const SubtitleStyle(textColor: Colors.white, strokeColor: Colors.black, strokeWidth: 2),
            ),
          ),
        );

        // With stroke, there should be two Text widgets (stroke + fill)
        final textWidgets = tester.widgetList<Text>(find.text('Stroked text'));
        expect(textWidgets.length, 2);
      });

      testWidgets('applies custom container border radius', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Rounded')],
        );

        when(
          () => mockController.value,
        ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

        await tester.pumpWidget(
          MaterialApp(
            home: SubtitleOverlay(controller: mockController, style: const SubtitleStyle(containerBorderRadius: 16)),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration as BoxDecoration?;
        expect(decoration?.borderRadius, BorderRadius.circular(16));
      });

      testWidgets('applies custom container padding', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Padded')],
        );

        when(
          () => mockController.value,
        ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

        await tester.pumpWidget(
          MaterialApp(
            home: SubtitleOverlay(
              controller: mockController,
              style: const SubtitleStyle(containerPadding: EdgeInsets.all(20)),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container).first);
        expect(container.padding, const EdgeInsets.all(20));
      });

      testWidgets('aligns text to the left when textAlignment is left', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Left aligned')],
        );

        when(
          () => mockController.value,
        ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

        await tester.pumpWidget(
          MaterialApp(
            home: SubtitleOverlay(
              controller: mockController,
              style: const SubtitleStyle(textAlignment: SubtitleTextAlignment.left),
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('Left aligned'));
        expect(text.textAlign, TextAlign.left);
      });

      testWidgets('uses SubtitleStyle backgroundColor', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Custom bg')],
        );

        when(
          () => mockController.value,
        ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

        const customBgColor = Color(0xFF0000FF);
        await tester.pumpWidget(
          MaterialApp(
            home: SubtitleOverlay(
              controller: mockController,
              style: const SubtitleStyle(backgroundColor: customBgColor),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container).first);
        final decoration = container.decoration as BoxDecoration?;
        expect(decoration?.color, customBgColor);
      });

      testWidgets('updates style when widget is rebuilt with new style', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Dynamic style')],
        );

        when(
          () => mockController.value,
        ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

        // Initial style: white text, 18px
        await tester.pumpWidget(
          MaterialApp(
            home: SubtitleOverlay(
              controller: mockController,
              style: const SubtitleStyle(textColor: Colors.white), // uses default fontSizePercent: 1.0
            ),
          ),
        );

        var text = tester.widget<Text>(find.text('Dynamic style'));
        expect(text.style?.color, Colors.white);
        // Font size is calculated from container height * fontSizePercent
        final firstFontSize = text.style?.fontSize ?? 0;
        expect(firstFontSize, greaterThan(0));

        // Update style: yellow text, larger font (6% vs 4%)
        await tester.pumpWidget(
          MaterialApp(
            home: SubtitleOverlay(
              controller: mockController,
              style: const SubtitleStyle(textColor: Colors.yellow, fontSizePercent: 1.5),
            ),
          ),
        );

        text = tester.widget<Text>(find.text('Dynamic style'));
        expect(text.style?.color, Colors.yellow);
        // Font size should be 50% larger (fontSizePercent 1.5 vs 1.0)
        expect(text.style?.fontSize, firstFontSize * 1.5);
      });

      testWidgets('updates position when style position changes', (tester) async {
        const externalTrack = ExternalSubtitleTrack(
          id: 'ext-0',
          label: 'English',
          path: 'https://example.com/subs.srt',
          sourceType: 'network',
          format: SubtitleFormat.srt,
          language: 'en',
          cues: [SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 5), text: 'Position test')],
        );

        when(
          () => mockController.value,
        ).thenReturn(const VideoPlayerValue(selectedSubtitleTrack: externalTrack, position: Duration(seconds: 3)));

        // Initial: bottom position
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              height: 400,
              width: 600,
              child: SubtitleOverlay(
                controller: mockController,
                style: const SubtitleStyle(), // Using default position (bottom) and marginFromEdge (48)
              ),
            ),
          ),
        );

        var positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.bottom, 48.0);
        expect(positioned.top, isNull);

        // Update: top position
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              height: 400,
              width: 600,
              child: SubtitleOverlay(
                controller: mockController,
                style: const SubtitleStyle(position: SubtitlePosition.top, marginFromEdge: 32),
              ),
            ),
          ),
        );

        positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.top, 32.0);
        expect(positioned.bottom, isNull);
      });
    });

    group('embedded subtitle rendering', () {
      testWidgets('renders embedded cue when embedded track is selected', (tester) async {
        const embeddedTrack = SubtitleTrack(id: '0:1', label: 'English', language: 'en');
        const embeddedCue = SubtitleCue(
          text: 'Embedded subtitle text',
          start: Duration(seconds: 1),
          end: Duration(seconds: 5),
        );

        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: embeddedTrack,
            currentEmbeddedCue: embeddedCue,
            position: Duration(seconds: 3),
          ),
        );

        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

        expect(find.text('Embedded subtitle text'), findsOneWidget);
      });

      testWidgets('renders nothing when embedded track selected but no cue', (tester) async {
        const embeddedTrack = SubtitleTrack(id: '0:1', label: 'English', language: 'en');

        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: embeddedTrack,
            // currentEmbeddedCue defaults to null - no cue to render
            position: Duration(seconds: 3),
          ),
        );

        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));

        expect(find.byType(Text), findsNothing);
      });

      testWidgets('embedded cue respects subtitle style', (tester) async {
        const embeddedTrack = SubtitleTrack(id: '0:1', label: 'English', language: 'en');
        const embeddedCue = SubtitleCue(
          text: 'Styled embedded cue',
          start: Duration(seconds: 1),
          end: Duration(seconds: 5),
        );

        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: embeddedTrack,
            currentEmbeddedCue: embeddedCue,
            position: Duration(seconds: 3),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SubtitleOverlay(
              controller: mockController,
              style: const SubtitleStyle(textColor: Color(0xFFFF0000), fontSizePercent: 1.5),
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('Styled embedded cue'));
        expect(text.style?.color, const Color(0xFFFF0000));
        // Font size calculated from container height * base (0.04) * fontSizePercent (1.5)
        expect(text.style?.fontSize, greaterThan(0));
      });

      testWidgets('embedded cue updates when cue changes', (tester) async {
        const embeddedTrack = SubtitleTrack(id: '0:1', label: 'English', language: 'en');
        const firstCue = SubtitleCue(text: 'First cue', start: Duration(seconds: 1), end: Duration(seconds: 3));
        const secondCue = SubtitleCue(text: 'Second cue', start: Duration(seconds: 4), end: Duration(seconds: 6));

        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: embeddedTrack,
            currentEmbeddedCue: firstCue,
            position: Duration(seconds: 2),
          ),
        );

        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));
        expect(find.text('First cue'), findsOneWidget);
        expect(find.text('Second cue'), findsNothing);

        // Change the cue and rebuild the widget to simulate controller update
        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: embeddedTrack,
            currentEmbeddedCue: secondCue,
            position: Duration(seconds: 5),
          ),
        );

        // Rebuild the widget with the new controller value
        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));
        expect(find.text('First cue'), findsNothing);
        expect(find.text('Second cue'), findsOneWidget);
      });

      testWidgets('embedded cue respects subtitle offset (positive delay)', (tester) async {
        const embeddedTrack = SubtitleTrack(id: '0:1', label: 'English', language: 'en');
        // Cue is active from 5s to 10s
        const embeddedCue = SubtitleCue(text: 'Delayed cue', start: Duration(seconds: 5), end: Duration(seconds: 10));

        // Position is 7s, cue is 5-10s, normally would show
        // But with +3s offset, adjusted position = 10s, which is outside cue range
        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: embeddedTrack,
            currentEmbeddedCue: embeddedCue,
            position: Duration(seconds: 7),
            subtitleOffset: Duration(seconds: 3), // Delay subtitles
          ),
        );

        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));
        // Should NOT show because adjusted position (10s) is at the end of cue range
        expect(find.text('Delayed cue'), findsNothing);
      });

      testWidgets('embedded cue respects subtitle offset (negative earlier)', (tester) async {
        const embeddedTrack = SubtitleTrack(id: '0:1', label: 'English', language: 'en');
        // Cue is active from 5s to 10s
        const embeddedCue = SubtitleCue(text: 'Earlier cue', start: Duration(seconds: 5), end: Duration(seconds: 10));

        // Position is 3s, cue is 5-10s, normally would NOT show
        // But with -3s offset, adjusted position = 0s, still outside cue range
        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: embeddedTrack,
            currentEmbeddedCue: embeddedCue,
            position: Duration(seconds: 3),
            subtitleOffset: Duration(seconds: -3), // Show subtitles earlier
          ),
        );

        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));
        // Should NOT show because adjusted position (0s) is before cue start (5s)
        expect(find.text('Earlier cue'), findsNothing);

        // Now test where offset makes it show
        // Position is 8s, with -3s offset = 5s (at start of cue range)
        when(() => mockController.value).thenReturn(
          const VideoPlayerValue(
            selectedSubtitleTrack: embeddedTrack,
            currentEmbeddedCue: embeddedCue,
            position: Duration(seconds: 8),
            subtitleOffset: Duration(seconds: -3),
          ),
        );

        await tester.pumpWidget(MaterialApp(home: SubtitleOverlay(controller: mockController)));
        // Should show because adjusted position (5s) is within cue range
        expect(find.text('Earlier cue'), findsOneWidget);
      });
    });
  });
}
