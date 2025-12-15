import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../../shared/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerTestFixture fixture;
  late StreamController<BatteryInfo> batteryController;

  setUpAll(registerVideoPlayerFallbackValues);

  setUp(() {
    fixture = VideoPlayerTestFixture()..setUp();
    batteryController = StreamController<BatteryInfo>.broadcast();

    // Add battery API mocks
    when(() => fixture.mockPlatform.getBatteryInfo()).thenAnswer((_) async => null);
    when(() => fixture.mockPlatform.batteryUpdates).thenAnswer((_) => batteryController.stream);
  });

  tearDown(() async {
    await batteryController.close();
    await fixture.tearDown();
  });

  Widget buildTestWidget(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('FullscreenStatusBar', () {
    testWidgets('renders with all components', (tester) async {
      await fixture.initializeController();

      // Set video state
      fixture
        ..emitDuration(const Duration(minutes: 5))
        ..emitPosition(const Duration(minutes: 2, seconds: 30));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(
          FullscreenStatusBar(
            controller: fixture.controller,
            enableTimeUpdates: false, // Disable timer in tests
            enableBatteryMonitoring: false, // Disable battery monitoring in most tests
          ),
        ),
      );
      await tester.pump();

      // Verify status bar is rendered
      expect(find.byType(FullscreenStatusBar), findsOneWidget);

      // Verify time is displayed (should show current time)
      // We can't test exact time, but verify the pattern exists
      final timeFinder = find.textContaining(RegExp(r'\d+:\d+ (AM|PM)'));
      expect(timeFinder, findsOneWidget);

      // Verify video position is displayed
      expect(find.textContaining('2:30'), findsOneWidget);
      expect(find.textContaining('5:00'), findsOneWidget);
    });

    testWidgets('displays battery info when available', (tester) async {
      await fixture.initializeController();

      await tester.pumpWidget(
        buildTestWidget(
          FullscreenStatusBar(
            controller: fixture.controller,
            enableTimeUpdates: false,
            enableBatteryMonitoring: false,
            testBatteryInfo: const BatteryInfo(percentage: 75, isCharging: false),
          ),
        ),
      );
      await tester.pump();

      // Verify battery percentage is shown
      expect(find.text('75%'), findsOneWidget);

      // Verify battery icon is shown
      expect(find.byIcon(Icons.battery_6_bar), findsOneWidget);
    });

    testWidgets('displays charging icon when battery is charging', (tester) async {
      await fixture.initializeController();

      await tester.pumpWidget(
        buildTestWidget(
          FullscreenStatusBar(
            controller: fixture.controller,
            enableTimeUpdates: false,
            enableBatteryMonitoring: false,
            testBatteryInfo: const BatteryInfo(percentage: 50, isCharging: true),
          ),
        ),
      );
      await tester.pump();

      // Verify charging icon is shown
      expect(find.byIcon(Icons.battery_charging_full), findsOneWidget);
    });

    testWidgets('hides battery info when not available', (tester) async {
      await fixture.initializeController();

      // Battery info not available (already set in setUp)
      await tester.pumpWidget(
        buildTestWidget(
          FullscreenStatusBar(
            controller: fixture.controller,
            enableTimeUpdates: false, // Disable timer in tests
            enableBatteryMonitoring: false, // Disable battery monitoring in most tests
          ),
        ),
      );
      await tester.pump();

      // Verify battery section is not shown (no async operations to wait for)
      expect(find.byIcon(Icons.battery_full), findsNothing);
      expect(find.byIcon(Icons.battery_charging_full), findsNothing);
    });

    testWidgets('updates battery info when widget rebuilds', (tester) async {
      await fixture.initializeController();

      // Initial battery state
      await tester.pumpWidget(
        buildTestWidget(
          FullscreenStatusBar(
            controller: fixture.controller,
            enableTimeUpdates: false,
            enableBatteryMonitoring: false,
            testBatteryInfo: const BatteryInfo(percentage: 75, isCharging: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('75%'), findsOneWidget);
      expect(find.byIcon(Icons.battery_6_bar), findsOneWidget);

      // Rebuild with updated battery info
      await tester.pumpWidget(
        buildTestWidget(
          FullscreenStatusBar(
            controller: fixture.controller,
            enableTimeUpdates: false,
            enableBatteryMonitoring: false,
            testBatteryInfo: const BatteryInfo(percentage: 25, isCharging: false),
          ),
        ),
      );
      await tester.pump();

      // Verify battery percentage is updated
      expect(find.text('25%'), findsOneWidget);

      // Verify low battery icon
      expect(find.byIcon(Icons.battery_2_bar), findsOneWidget);
    });

    testWidgets('displays video position correctly', (tester) async {
      await fixture.initializeController();

      // Set video state
      fixture
        ..emitDuration(const Duration(minutes: 10))
        ..emitPosition(const Duration(minutes: 5, seconds: 15));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(
          FullscreenStatusBar(
            controller: fixture.controller,
            enableTimeUpdates: false, // Disable timer in tests
            enableBatteryMonitoring: false, // Disable battery monitoring in most tests
          ),
        ),
      );
      await tester.pump();

      // Verify position is displayed
      expect(find.textContaining('5:15'), findsOneWidget);
      expect(find.textContaining('10:00'), findsOneWidget);
    });

    testWidgets('formats time correctly with hours', (tester) async {
      await fixture.initializeController();

      // Set position with hours
      fixture
        ..emitDuration(const Duration(hours: 2, minutes: 30))
        ..emitPosition(const Duration(hours: 1, minutes: 15, seconds: 30));
      await tester.pump();

      await tester.pumpWidget(
        buildTestWidget(
          FullscreenStatusBar(
            controller: fixture.controller,
            enableTimeUpdates: false, // Disable timer in tests
            enableBatteryMonitoring: false, // Disable battery monitoring in most tests
          ),
        ),
      );
      await tester.pump();

      // Verify time format with hours
      expect(find.textContaining('1:15:30'), findsOneWidget);
      expect(find.textContaining('2:30:00'), findsOneWidget);
    });

    testWidgets('applies theme colors', (tester) async {
      await fixture.initializeController();

      const customTheme = VideoPlayerTheme(primaryColor: Colors.red);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoPlayerThemeData(
              theme: customTheme,
              child: FullscreenStatusBar(
                controller: fixture.controller,
                enableTimeUpdates: false, // Disable timer in tests
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify theme is applied (check Text widgets have the right color)
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final textWidget in textWidgets) {
        expect(textWidget.style?.color, Colors.red);
      }
    });

    testWidgets('respects safe area padding', (tester) async {
      await fixture.initializeController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                padding: EdgeInsets.only(top: 50), // Simulate notch/status bar
              ),
              child: FullscreenStatusBar(
                controller: fixture.controller,
                enableTimeUpdates: false, // Disable timer in tests
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify status bar is hidden when system status bar is visible
      expect(find.byType(Container), findsNothing); // Should return SizedBox.shrink()
      expect(find.byType(FullscreenStatusBar), findsOneWidget);
    });

    testWidgets('disposes timers and subscriptions', (tester) async {
      await fixture.initializeController();

      await tester.pumpWidget(
        buildTestWidget(
          FullscreenStatusBar(
            controller: fixture.controller,
            enableTimeUpdates: false, // Disable timer in tests
            enableBatteryMonitoring: false, // Disable battery monitoring in most tests
          ),
        ),
      );
      await tester.pump();

      // Remove the widget
      await tester.pumpWidget(buildTestWidget(const SizedBox.shrink()));
      await tester.pump();

      // Verify no errors (timers and subscriptions should be properly disposed)
      // If dispose wasn't called, we might see memory leaks or errors
      // Widget is already unmounted (we pumped SizedBox.shrink()), so timer should be cancelled
    });

    testWidgets('selects correct battery icon for different levels', (tester) async {
      await fixture.initializeController();

      // Test different battery levels
      final testCases = [
        (percentage: 100, icon: Icons.battery_full),
        (percentage: 85, icon: Icons.battery_6_bar),
        (percentage: 65, icon: Icons.battery_5_bar),
        (percentage: 45, icon: Icons.battery_3_bar),
        (percentage: 25, icon: Icons.battery_2_bar),
        (percentage: 15, icon: Icons.battery_2_bar),
        (percentage: 5, icon: Icons.battery_1_bar),
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          buildTestWidget(
            FullscreenStatusBar(
              controller: fixture.controller,
              enableTimeUpdates: false,
              enableBatteryMonitoring: false,
              testBatteryInfo: BatteryInfo(percentage: testCase.percentage, isCharging: false),
            ),
          ),
        );
        await tester.pump();

        // Verify correct icon for battery level
        expect(
          find.byIcon(testCase.icon),
          findsOneWidget,
          reason: 'Expected ${testCase.icon} for ${testCase.percentage}%',
        );

        // Reset widget
        await tester.pumpWidget(buildTestWidget(const SizedBox.shrink()));
        await tester.pump();
      }
    });
  });
}
