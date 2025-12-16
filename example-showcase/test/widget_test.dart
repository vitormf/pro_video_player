import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player_example/constants/video_constants.dart';
import 'package:pro_video_player_example/main.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProVideoPlayerPlatform mockPlatform;
  late StreamController<VideoPlayerEvent> eventController;
  var nextPlayerId = 1;

  setUpAll(() {
    registerFallbackValue(const VideoSource.network(VideoUrls.exampleUrl));
    registerFallbackValue(const VideoPlayerOptions());
    registerFallbackValue(const PipOptions());
    registerFallbackValue(const SubtitleTrack(id: 'test', label: 'Test'));
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    nextPlayerId = 1;
    mockPlatform = MockProVideoPlayerPlatform();
    eventController = StreamController<VideoPlayerEvent>.broadcast();
    ProVideoPlayerPlatform.instance = mockPlatform;

    // Setup default mock behavior
    when(
      () => mockPlatform.create(
        source: any(named: 'source'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => nextPlayerId++);

    when(() => mockPlatform.events(any())).thenAnswer((_) => eventController.stream);
    when(() => mockPlatform.dispose(any())).thenAnswer((_) async {});
    when(() => mockPlatform.buildView(any())).thenReturn(const SizedBox(key: Key('video_view')));
    when(() => mockPlatform.play(any())).thenAnswer((_) async {});
    when(() => mockPlatform.pause(any())).thenAnswer((_) async {});
    when(() => mockPlatform.stop(any())).thenAnswer((_) async {});
    when(() => mockPlatform.seekTo(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setVolume(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setPlaybackSpeed(any(), any())).thenAnswer((_) async {});
    when(() => mockPlatform.setLooping(any(), any(named: 'looping'))).thenAnswer((_) async {});
    when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => true);
    when(() => mockPlatform.enterPip(any(), options: any(named: 'options'))).thenAnswer((_) async => true);
    when(() => mockPlatform.exitPip(any())).thenAnswer((_) async {});
    when(() => mockPlatform.enterFullscreen(any())).thenAnswer((_) async => true);
    when(() => mockPlatform.exitFullscreen(any())).thenAnswer((_) async => true);
    when(() => mockPlatform.setSubtitleTrack(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await eventController.close();
    ProVideoPlayerPlatform.instance = MockProVideoPlayerPlatform();
  });

  group('HomeScreen', () {
    testWidgets('renders home screen with all sections', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Verify home screen is displayed
      expect(find.text('Pro Video Player'), findsOneWidget);
      expect(find.text('Player Features'), findsOneWidget);
      expect(find.text('Video Sources'), findsOneWidget);
    });

    testWidgets('displays player features section chips', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Verify feature chips are displayed
      expect(find.text('Fullscreen mode'), findsOneWidget);
      expect(find.text('Picture-in-Picture'), findsOneWidget);
      expect(find.text('Background playback'), findsOneWidget);
      expect(find.text('Playback speed'), findsOneWidget);
      expect(find.text('Volume control'), findsOneWidget);
      expect(find.text('Loop mode'), findsOneWidget);
      expect(find.text('Seek controls'), findsOneWidget);
    });

    testWidgets('displays video sources section chips', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Verify source type chips are displayed
      expect(find.text('Network videos (HTTP/HTTPS)'), findsOneWidget);
      expect(find.text('Local file videos'), findsOneWidget);
      expect(find.text('Asset videos'), findsOneWidget);
    });

    testWidgets('displays advanced features section after scrolling', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make advanced features visible
      final advancedText = find.text('Advanced Features');
      await tester.scrollUntilVisible(advancedText, 100, scrollable: find.byType(Scrollable).first);

      // Verify advanced feature chips
      expect(find.text('Subtitle tracks'), findsOneWidget);
      expect(find.text('Error handling'), findsOneWidget);
      expect(find.text('Multiple simultaneous players'), findsOneWidget);
    });

    testWidgets('navigates to player features screen', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make Player Features visible (may be off-screen in grid layout)
      final playerFeaturesText = find.text('Player Features');
      await tester.scrollUntilVisible(playerFeaturesText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      // Find and tap the player features section
      final playerFeaturesCard = find.ancestor(of: playerFeaturesText, matching: find.byType(Card));
      await tester.tap(playerFeaturesCard.first);
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.text('Playback Controls'), findsOneWidget);
    });

    testWidgets('navigates to video sources screen', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make Video Sources visible (may be off-screen in grid layout)
      final videoSourcesText = find.text('Video Sources');
      await tester.scrollUntilVisible(videoSourcesText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      // Find and tap the video sources section
      final videoSourcesCard = find.ancestor(of: videoSourcesText, matching: find.byType(Card));
      await tester.tap(videoSourcesCard.first);
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Asset'), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
    });

    testWidgets('navigates to advanced features screen', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make advanced features visible
      final advancedText = find.text('Advanced Features');
      await tester.scrollUntilVisible(advancedText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      // Find and tap the advanced features section
      final advancedCard = find.ancestor(of: advancedText, matching: find.byType(Card));
      await tester.tap(advancedCard.first);
      await tester.pumpAndSettle();

      // Verify navigation occurred - tab bar should be visible
      expect(find.text('Subtitles'), findsOneWidget);
      expect(find.text('Error Handling'), findsOneWidget);
      expect(find.text('Multi-Player'), findsOneWidget);
    });

    testWidgets('lays out feature chips across multiple rows (no forced single-line scroll)', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      final chip = find.text('Fullscreen mode');
      final wrap = find.ancestor(
        of: chip,
        matching: find.byWidgetPredicate((widget) => widget is Wrap && widget.runSpacing > 0),
      );

      expect(wrap, findsOneWidget);

      final horizontalScroll = find.ancestor(
        of: chip,
        matching: find.byWidgetPredicate(
          (widget) => widget is SingleChildScrollView && widget.scrollDirection == Axis.horizontal,
        ),
      );

      expect(horizontalScroll, findsNothing);
    });

    testWidgets('uses a tighter grid aspect ratio on wide layouts', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.childAspectRatio, closeTo(1.5, 0.001));
    });
  });

  group('StreamSelectionScreen', () {
    Future<void> navigateToStreamSelection(WidgetTester tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      final streamSelectionText = find.text('Stream Selection');
      await tester.scrollUntilVisible(streamSelectionText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      final card = find.ancestor(of: streamSelectionText, matching: find.byType(Card));
      await tester.tap(card.first);
      await tester.pumpAndSettle();
    }

    testWidgets('initializes and auto-plays the demo source', (tester) async {
      await navigateToStreamSelection(tester);

      final captured = verify(
        () => mockPlatform.create(
          source: captureAny(named: 'source'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      final source = captured[0] as VideoSource;
      final options = captured[1] as VideoPlayerOptions;

      expect(source, isA<NetworkVideoSource>());
      expect((source as NetworkVideoSource).url, contains('angel-one-hls'));
      expect(options.autoPlay, isTrue);
      expect(options.subtitlesEnabled, isTrue);
      expect(options.showSubtitlesByDefault, isTrue);
      expect(options.preferredSubtitleLanguage, 'en');

      verify(() => mockPlatform.play(any())).called(1);
    });

    testWidgets('allows switching video source via dropdown', (tester) async {
      await navigateToStreamSelection(tester);

      final dropdown = find.byKey(const Key('streamSelection.videoDropdown'));
      expect(dropdown, findsOneWidget);

      // Open dropdown and pick an alternate source
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bitmovin (Sintel HLS)').last);
      await tester.pumpAndSettle();

      final captured = verify(
        () => mockPlatform.create(
          source: captureAny(named: 'source'),
          options: any(named: 'options'),
        ),
      ).captured;

      final urls = captured.whereType<NetworkVideoSource>().map((s) => s.url).toList();
      expect(urls.length, greaterThanOrEqualTo(2));
      expect(urls.last, contains('bitmovin-a.akamaihd.net/content/sintel'));
    });

    testWidgets('disposes previous player when switching source', (tester) async {
      await navigateToStreamSelection(tester);

      final dropdown = find.byKey(const Key('streamSelection.videoDropdown'));
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('AWS (Bipbop Advanced HLS)').last);
      await tester.pumpAndSettle();

      verify(() => mockPlatform.dispose(1)).called(1);
      verify(
        () => mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).called(greaterThanOrEqualTo(2));
    });
  });

  group('PlayerFeaturesScreen', () {
    Future<void> navigateToPlayerFeatures(WidgetTester tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make visible in grid layout
      final playerFeaturesText = find.text('Player Features');
      await tester.scrollUntilVisible(playerFeaturesText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      final card = find.ancestor(of: playerFeaturesText, matching: find.byType(Card));
      await tester.tap(card.first);
      await tester.pumpAndSettle();
    }

    testWidgets('displays playback controls when initialized', (tester) async {
      await navigateToPlayerFeatures(tester);

      expect(find.text('Playback Controls'), findsOneWidget);
      expect(find.text('Speed:'), findsOneWidget);
      expect(find.text('Volume:'), findsOneWidget);
      expect(find.text('Loop'), findsOneWidget);
    });

    testWidgets('displays player info section after scrolling', (tester) async {
      await navigateToPlayerFeatures(tester);

      // Scroll down to see Player Info
      await tester.scrollUntilVisible(find.text('Player Info'), 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(find.text('Player Info'), findsOneWidget);
      expect(find.text('State'), findsOneWidget);
    });

    testWidgets('play button is visible', (tester) async {
      await navigateToPlayerFeatures(tester);

      // Find the play button
      final playButton = find.byIcon(Icons.play_circle);
      expect(playButton, findsWidgets);
    });

    testWidgets('speed dropdown is visible', (tester) async {
      await navigateToPlayerFeatures(tester);

      // Find the speed dropdown
      final dropdown = find.byType(DropdownButton<double>);
      expect(dropdown, findsOneWidget);
    });

    testWidgets('loop switch is visible and tappable', (tester) async {
      await navigateToPlayerFeatures(tester);

      // Find the loop switch
      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);

      // Toggle loop - we just verify we can tap without error
      await tester.tap(switchWidget);
      await tester.pump();

      // Verify the switch is still there after tap
      expect(find.byType(Switch), findsOneWidget);
    });
  });

  group('VideoSourcesScreen', () {
    Future<void> navigateToVideoSources(WidgetTester tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make visible in grid layout
      final videoSourcesText = find.text('Video Sources');
      await tester.scrollUntilVisible(videoSourcesText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      final card = find.ancestor(of: videoSourcesText, matching: find.byType(Card));
      await tester.tap(card.first);
      await tester.pumpAndSettle();
    }

    testWidgets('displays source type segmented button', (tester) async {
      await navigateToVideoSources(tester);

      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Asset'), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
    });

    testWidgets('segmented button options are visible', (tester) async {
      await navigateToVideoSources(tester);

      // Verify all segment options are visible
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Asset'), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
    });
  });

  group('AdvancedFeaturesScreen', () {
    Future<void> navigateToAdvancedFeatures(WidgetTester tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make advanced features visible
      final advancedText = find.text('Advanced Features');
      await tester.scrollUntilVisible(advancedText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      final card = find.ancestor(of: advancedText, matching: find.byType(Card));
      await tester.tap(card.first);
      await tester.pumpAndSettle();
    }

    testWidgets('displays tabs', (tester) async {
      await navigateToAdvancedFeatures(tester);

      expect(find.text('Subtitles'), findsOneWidget);
      expect(find.text('Error Handling'), findsOneWidget);
      expect(find.text('Multi-Player'), findsOneWidget);
    });

    group('Subtitles Tab', () {
      testWidgets('displays subtitle info after scrolling', (tester) async {
        await navigateToAdvancedFeatures(tester);

        // Wait for initialization
        await tester.pumpAndSettle();

        // Default tab is Subtitles - try to scroll to the info section if needed
        // The content might already be visible in side-by-side layout on larger screens
        final aboutSubtitlesFinder = find.text('About Subtitles');
        if (aboutSubtitlesFinder.evaluate().isEmpty) {
          // Try scrolling within the tab content
          final singleChildScrollViews = find.byType(SingleChildScrollView);
          for (var i = singleChildScrollViews.evaluate().length - 1; i >= 0; i--) {
            try {
              await tester.scrollUntilVisible(
                aboutSubtitlesFinder,
                100,
                scrollable: find.descendant(of: singleChildScrollViews.at(i), matching: find.byType(Scrollable)),
              );
              break;
            } catch (_) {
              // Try next scrollable
            }
          }
          await tester.pumpAndSettle();
        }

        expect(aboutSubtitlesFinder, findsOneWidget);
      });

      testWidgets('shows subtitle tracks section', (tester) async {
        await navigateToAdvancedFeatures(tester);

        // Wait for player to initialize
        await tester.pumpAndSettle();

        // The subtitle tracks section should be visible
        expect(find.text('Subtitle Tracks'), findsOneWidget);
      });
    });

    group('Error Handling Tab', () {
      testWidgets('displays error handling info', (tester) async {
        await navigateToAdvancedFeatures(tester);

        // Navigate to Error Handling tab
        await tester.tap(find.text('Error Handling'));
        await tester.pumpAndSettle();

        expect(find.text('Error Handling Demo'), findsOneWidget);
        expect(find.text('Invalid URL'), findsOneWidget);
        expect(find.text('Invalid Format'), findsOneWidget);
        expect(find.text('Valid Video'), findsOneWidget);
      });

      testWidgets('can trigger invalid URL error', (tester) async {
        await navigateToAdvancedFeatures(tester);

        await tester.tap(find.text('Error Handling'));
        await tester.pumpAndSettle();

        // Tap Invalid URL button
        await tester.tap(find.text('Invalid URL'));
        await tester.pumpAndSettle();

        // Should trigger player creation (which may fail in real scenario)
        verify(
          () => mockPlatform.create(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).called(greaterThan(0));
      });
    });

    group('Multi-Player Tab', () {
      testWidgets('displays multi-player controls', (tester) async {
        await navigateToAdvancedFeatures(tester);

        // Navigate to Multi-Player tab
        await tester.tap(find.text('Multi-Player'));
        await tester.pumpAndSettle();

        expect(find.text('Add Player (0/4)'), findsOneWidget);
        expect(find.textContaining('Tap "Add Player"'), findsOneWidget);
      });

      testWidgets('can add players', (tester) async {
        await navigateToAdvancedFeatures(tester);

        await tester.tap(find.text('Multi-Player'));
        await tester.pumpAndSettle();

        // Tap Add Player button
        await tester.tap(find.text('Add Player (0/4)'));
        await tester.pumpAndSettle();

        // Button should now show 1/4
        expect(find.text('Add Player (1/4)'), findsOneWidget);

        // Player 1 indicator should be visible
        expect(find.text('Player 1'), findsOneWidget);
      });

      testWidgets('can add multiple players', (tester) async {
        await navigateToAdvancedFeatures(tester);

        await tester.tap(find.text('Multi-Player'));
        await tester.pumpAndSettle();

        // Add 2 players
        await tester.tap(find.text('Add Player (0/4)'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add Player (1/4)'));
        await tester.pumpAndSettle();

        expect(find.text('Add Player (2/4)'), findsOneWidget);
        expect(find.text('Player 1'), findsOneWidget);
        expect(find.text('Player 2'), findsOneWidget);
      });

      testWidgets('delete all button is present', (tester) async {
        await navigateToAdvancedFeatures(tester);

        await tester.tap(find.text('Multi-Player'));
        await tester.pumpAndSettle();

        // Verify the delete sweep icon button is present
        expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
      });
    });
  });

  group('Error State Handling', () {
    testWidgets('PlayerFeaturesScreen shows error state on initialization failure', (tester) async {
      when(
        () => mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenThrow(Exception('Network error'));

      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make visible in grid layout
      final playerFeaturesText = find.text('Player Features');
      await tester.scrollUntilVisible(playerFeaturesText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      final card = find.ancestor(of: playerFeaturesText, matching: find.byType(Card));
      await tester.tap(card.first);
      await tester.pumpAndSettle();

      // Should show error state
      expect(find.textContaining('Error:'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('can retry after error', (tester) async {
      var callCount = 0;
      when(
        () => mockPlatform.create(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('Network error');
        }
        return 1;
      });

      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make visible in grid layout
      final playerFeaturesText = find.text('Player Features');
      await tester.scrollUntilVisible(playerFeaturesText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      final card = find.ancestor(of: playerFeaturesText, matching: find.byType(Card));
      await tester.tap(card.first);
      await tester.pumpAndSettle();

      // Should show error state
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now show the player controls
      expect(find.text('Playback Controls'), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('can navigate back from player features', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make visible in grid layout
      final playerFeaturesText = find.text('Player Features');
      await tester.scrollUntilVisible(playerFeaturesText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      // Navigate to player features
      final card = find.ancestor(of: playerFeaturesText, matching: find.byType(Card));
      await tester.tap(card.first);
      await tester.pumpAndSettle();

      // Navigate back using the navigator
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();

      // Should be back on home screen
      expect(find.text('Pro Video Player'), findsOneWidget);
    });

    testWidgets('can navigate back from video sources', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to make visible in grid layout
      final videoSourcesText = find.text('Video Sources');
      await tester.scrollUntilVisible(videoSourcesText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      // Navigate to video sources
      final card = find.ancestor(of: videoSourcesText, matching: find.byType(Card));
      await tester.tap(card.first);
      await tester.pumpAndSettle();

      // Navigate back using the navigator
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();

      // Should be back on home screen
      expect(find.text('Pro Video Player'), findsOneWidget);
    });

    testWidgets('can navigate back from advanced features', (tester) async {
      await tester.pumpWidget(const ExampleApp());
      await tester.pumpAndSettle();

      // Scroll to advanced features card and tap
      final advancedText = find.text('Advanced Features');
      await tester.scrollUntilVisible(advancedText, 100, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      final card = find.ancestor(of: advancedText, matching: find.byType(Card));
      await tester.tap(card.first);
      await tester.pumpAndSettle();

      // Navigate back using the navigator
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();

      // Should be back on home screen
      expect(find.text('Pro Video Player'), findsOneWidget);
    });
  });
}
