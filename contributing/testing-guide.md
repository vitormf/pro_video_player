# Testing Guide

Comprehensive guide to testing in Pro Video Player.

## Test-Driven Development (TDD)

**Strict TDD practices:**
1. Write tests first — failing tests before implementation
2. Red → Green → Refactor cycle
3. Test categories: unit (mocked deps), widget, integration, platform channel

**CRITICAL: Do NOT skip tests without explicit user permission.**

---

## Writing Tests: Best Practices

### When Tests Fail, Investigate Implementation First

**Failing tests often reveal implementation bugs**, not test bugs — this is exactly what tests should do!
- Before assuming a test is wrong, thoroughly examine the implementation code it's testing
- Example bugs caught by "failing" tests: missing state updates, incomplete logic, forgotten cleanup

### DO:
- ✅ **Write complete implementations** — Ensure all state is properly managed (capture positions, clear values, track changes)
- ✅ **Notify listeners on all state changes** — Not just play/pause, but also fullscreen, PiP, dragging, etc.
- ✅ **Test async operations with appropriate delays** — Give time for events to propagate (50-150ms for initialization)
- ✅ **Understand what you're testing** — Know how the mock infrastructure works (e.g., `videoController.value` is read-only)
- ✅ **Fix root causes** — If implementation is incomplete, fix it; don't adjust tests to match broken behavior

### DON'T:
- ❌ **Don't assume tests are wrong** — Investigate the implementation first
- ❌ **Don't add excessive delays** — Understand why async timing is needed, don't cargo-cult delays
- ❌ **Don't make flawed assumptions** — Verify test infrastructure behavior (e.g., events don't update controller.value directly)
- ❌ **Don't skip tests to "make them pass"** — Fix the underlying issue or ask for guidance
- ❌ **Don't write partial implementations** — Complete all related logic (mute needs unmute, start needs end, show needs hide)

### Common Patterns:
- **State management:** Every `start*()` needs corresponding `end*()`, every value set needs proper cleanup
- **Event notifications:** State changes must call `notifyListeners()` when UI needs to react
- **Timer management:** Check all conditions before starting timers (isDragging, isCasting, isMouseOver, etc.)
- **Value tracking:** Track previous values for toggle operations (volume for mute/unmute, etc.)

---

## Test Structure Patterns

### Mock Setup

```dart
// setUpAll() - One-time setup for entire test suite
setUpAll(() {
  registerFallbackValue(const VideoSource.network('https://example.com'));
  registerFallbackValue(const VideoPlayerOptions());
  registerFallbackValue(Duration.zero);
});

// setUp() - Fresh mocks before each test
setUp(() {
  mockPlatform = MockProVideoPlayerPlatform();
  eventController = StreamController<VideoPlayerEvent>.broadcast(); // Use broadcast!
  ProVideoPlayerPlatform.instance = mockPlatform;

  when(() => mockPlatform.events(any())).thenAnswer((_) => eventController.stream);
});

// tearDown() - Cleanup after each test
tearDown(() async {
  await eventController.close(); // Prevent stream leaks
  ProVideoPlayerPlatform.instance = MockProVideoPlayerPlatform();
});
```

### Testing State Changes

```dart
test('method updates state and notifies listeners', () {
  var notifyCount = 0;
  state.addListener(() => notifyCount++);

  state.someMethod(); // Trigger change

  expect(state.someProperty, expectedValue); // Verify state
  expect(notifyCount, greaterThan(0));       // Verify notification
});
```

### Widget Testing

```dart
testWidgets('description', (tester) async {
  // 1. Wrap in MaterialApp > Scaffold for proper context
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: YourWidget(/* params */),
      ),
    ),
  );

  // 2. Wait for initial render
  await tester.pump();

  // 3. Perform interactions
  await tester.tap(find.byType(IconButton));
  await tester.pump(); // Single frame update

  // 4. Verify results
  expect(find.text('Expected'), findsOneWidget);
});
```

### Hit-Testable Widgets

```dart
// ❌ BAD - Colors.transparent has alpha=0, doesn't participate in hit testing
child: Container(color: Colors.transparent)

// ✅ GOOD - Near-transparent but hit-testable
child: Container(color: const Color(0x01000000))
```

### Async Testing Delays

```dart
// Controller initialization - wait for platform async calls
await controller.initialize(source: VideoSource.network('...'));
await Future<void>.delayed(const Duration(milliseconds: 150));

// Event propagation - wait for stream processing
eventController.add(const PlaybackStateChangedEvent(PlaybackState.playing));
await Future<void>.delayed(const Duration(milliseconds: 50));

// Timer testing - wait for timer callback
state.startHideTimer(const Duration(milliseconds: 100), callback);
await Future<void>.delayed(const Duration(milliseconds: 150));
expect(callbackExecuted, isTrue);
```

### Widget Pump Methods

```dart
await tester.pump();              // Single frame, use for immediate updates
await tester.pump(duration);      // Advance clock by duration
await tester.pumpAndSettle();     // ⚠️ Wait for all animations - HANGS with modals!
```

### Mock Verification

```dart
verify(() => mock.method(arg)).called(1);     // Expect exactly 1 call
verify(() => mock.method(arg)).called(greaterThan(0)); // At least 1 call
verifyNever(() => mock.method(arg));          // Expect no calls

// Debug: See all calls
// No matching calls. All calls: [list of actual calls]
```

---

## Testing Control Widgets: Special Patterns

### MockVideoControlsState Requirements

When testing control widgets that receive a `controlsState` parameter, you must implement specific boolean properties in your mock object. This is required because some widgets (like `PlayerToolbar`) cast the state dynamically to access these properties.

**Why This Is Needed:**

The `PlayerToolbar` widget (lines 310-312) casts `controlsState as dynamic` to access platform feature availability:

```dart
isBackgroundPlaybackSupported: (controlsState as dynamic).isBackgroundPlaybackSupported as bool,
isPipAvailable: (controlsState as dynamic).isPipAvailable as bool,
isCastingSupported: (controlsState as dynamic).isCastingSupported as bool,
```

**Complete MockVideoControlsState Implementation:**

```dart
// Mock for VideoControlsState
class MockVideoControlsState {
  // Dragging state (for progress bar tests)
  bool isDragging = false;
  double? dragProgress;

  // Time display toggle (for time display tests)
  bool showRemainingTime = false;

  // Platform feature availability (REQUIRED - accessed via dynamic cast)
  bool get isBackgroundPlaybackSupported => false;
  bool get isPipAvailable => true;
  bool get isCastingSupported => false;
}
```

**What Happens If You Forget These Properties:**

```
type 'Null' is not a subtype of type 'bool' in type cast
```

The test will fail when the widget attempts to cast `null` to `bool`.

**Real Examples:**
- `test/controls/player_toolbar_test.dart` - PlayerToolbar requires all three boolean properties
- `test/controls/mobile_video_controls_test.dart` - Requires all properties plus `showRemainingTime`
- `test/controls/desktop_video_controls_test.dart` - Requires all properties plus dragging state

### Widget Finder Specificity with Nested Widgets

When testing widgets wrapped in `MaterialApp` and `Scaffold`, you may encounter multiple instances of common widget types due to nested hierarchies.

**Problem:**

```dart
// ❌ FAILS: Multiple MouseRegion widgets exist in nested hierarchy
expect(find.byType(MouseRegion), findsOneWidget);

// Error:
// Expected: exactly one matching candidate
// Actual: _TypeWidgetFinder:<Found 7 widgets with type "MouseRegion">
```

**Why This Happens:**

`MaterialApp`, `Scaffold`, and other framework widgets create their own instances of common widgets (MouseRegion, Column, Row, etc.). Your test wrapper creates additional nested instances.

**Solution:**

Use `findsWidgets` (plural) instead of `findsOneWidget` when testing for widgets that may appear multiple times in the hierarchy:

```dart
// ✅ GOOD: Accept multiple instances
expect(find.byType(MouseRegion), findsWidgets);
expect(find.byType(Column), findsWidgets);
expect(find.byType(Row), findsWidgets);
```

**When to Use Each Matcher:**

| Matcher | Use When | Example |
|---------|----------|---------|
| `findsOneWidget` | Testing for unique widgets specific to your component | `expect(find.byType(DesktopVideoControls), findsOneWidget)` |
| `findsWidgets` | Testing for common widgets that may appear in nested hierarchies | `expect(find.byType(MouseRegion), findsWidgets)` |
| `findsNothing` | Verifying a widget is not present | `expect(find.byIcon(Icons.skip_previous), findsNothing)` |

**Real Examples:**

From `test/controls/desktop_video_controls_test.dart`:

```dart
// ❌ BEFORE: Expected one, found multiple
expect(find.byType(MouseRegion), findsOneWidget);

// ✅ AFTER: Accept multiple instances from nested hierarchy
expect(find.byType(MouseRegion), findsWidgets);
```

**Alternative Approach - Find Specific Instances:**

If you need to verify a specific instance, use a more specific finder:

```dart
// Find by key
expect(find.byKey(const Key('my-unique-key')), findsOneWidget);

// Find by widget with specific properties
expect(find.widgetWithIcon(IconButton, Icons.play_arrow), findsOneWidget);

// Find by descendant relationship
expect(find.descendant(
  of: find.byType(DesktopVideoControls),
  matching: find.byType(MouseRegion),
), findsWidgets);
```

---

## Common Test Pitfalls

1. **Modal widgets with pumpAndSettle** → Use `skip: true` with documentation
2. **Event streams not broadcast** → Multiple listeners fail, use `StreamController.broadcast()`
3. **Forgetting to dispose/close** → Memory leaks and test pollution
4. **Testing read-only properties** → `controller.value` is read-only, events don't update it directly
5. **Assuming event timing** → Always add delays for async event propagation
6. **Colors.transparent widgets** → Don't participate in hit testing, use `Color(0x01000000)`
7. **Missing MaterialApp wrapper** → Theme/navigator errors in widget tests
8. **Not resetting notification flags** → Set `notified = false` before each assertion
9. **Async operations in widget initState** → `Timer.periodic` and async stream subscriptions cause tests to hang indefinitely (see detailed solution below)
10. **Incomplete MockVideoControlsState** → Must implement required boolean properties (see "Testing Control Widgets" section above)
11. **Widget finder expects one, finds many** → Use `findsWidgets` for common widget types in nested hierarchies (see "Widget Finder Specificity" section above)

---

## Testing Widgets with Async Operations

### Problem: Tests Hanging with Timer.periodic and Async Subscriptions

When testing StatefulWidgets that create `Timer.periodic` or initiate async stream subscriptions in `initState()`, tests will hang indefinitely.

**Symptoms:**
- `testWidgets` freezes and never completes
- Test output shows the test "running" for minutes without progress
- Happens even with proper `dispose()` cleanup

**Root Cause:**
- Flutter's test environment doesn't automatically handle `Timer.periodic` cleanup
- Async operations initiated in `initState()` (like platform channel calls + stream subscriptions) don't complete in the test environment
- The test waits for async operations that will never resolve

### Solution: Test-Only Parameters for Dependency Injection

Add `@visibleForTesting` parameters to control async behavior in tests:

**Widget Implementation:**

```dart
class MyWidget extends StatefulWidget {
  const MyWidget({
    required this.controller,
    super.key,
    this.enableTimeUpdates = true,       // Disable Timer.periodic in tests
    this.enableAsyncFetching = true,     // Disable async operations in tests
    this.testData,                        // Direct data injection for tests
  });

  final Controller controller;

  @visibleForTesting
  final bool enableTimeUpdates;

  @visibleForTesting
  final bool enableAsyncFetching;

  @visibleForTesting
  final Data? testData;

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Timer? _timer;
  StreamSubscription? _subscription;
  Data? _data;

  @override
  void initState() {
    super.initState();
    _startTimeUpdates();

    // Use test data if provided (test-only path)
    if (widget.testData != null) {
      _data = widget.testData;
    } else if (widget.enableAsyncFetching) {
      unawaited(_fetchDataAsync());
    }
  }

  @override
  void didUpdateWidget(MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update data if test injection changed
    if (widget.testData != oldWidget.testData) {
      setState(() {
        _data = widget.testData;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _startTimeUpdates() {
    if (!widget.enableTimeUpdates) {
      // For tests: don't start the timer
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        // Update state
      });
    });
  }

  Future<void> _fetchDataAsync() async {
    try {
      final updates = widget.controller.dataUpdates;
      _subscription = updates.listen((data) {
        if (mounted) {
          setState(() {
            _data = data;
          });
        }
      });

      // Also get initial data
      final initialData = await widget.controller.getData();
      if (mounted && initialData != null) {
        setState(() {
          _data = initialData;
        });
      }
    } catch (e) {
      // Handle error gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_data?.value ?? 'No data');
  }
}
```

**Test Implementation:**

```dart
testWidgets('displays data correctly', (tester) async {
  await fixture.initializeController();

  await tester.pumpWidget(
    buildTestWidget(
      MyWidget(
        controller: fixture.controller,
        enableTimeUpdates: false,      // Disable timer
        enableAsyncFetching: false,    // Disable async subscription
        testData: const Data(value: 'Test Value'), // Inject data directly
      ),
    ),
  );
  await tester.pump();

  expect(find.text('Test Value'), findsOneWidget);
});

testWidgets('updates data when widget rebuilds', (tester) async {
  await fixture.initializeController();

  // Initial render with first data
  await tester.pumpWidget(
    buildTestWidget(
      MyWidget(
        controller: fixture.controller,
        enableTimeUpdates: false,
        enableAsyncFetching: false,
        testData: const Data(value: 'Initial'),
      ),
    ),
  );
  await tester.pump();

  expect(find.text('Initial'), findsOneWidget);

  // Rebuild with updated data (didUpdateWidget handles this)
  await tester.pumpWidget(
    buildTestWidget(
      MyWidget(
        controller: fixture.controller,
        enableTimeUpdates: false,
        enableAsyncFetching: false,
        testData: const Data(value: 'Updated'),
      ),
    ),
  );
  await tester.pump();

  expect(find.text('Updated'), findsOneWidget);
});

testWidgets('hides data when not available', (tester) async {
  await fixture.initializeController();

  await tester.pumpWidget(
    buildTestWidget(
      MyWidget(
        controller: fixture.controller,
        enableTimeUpdates: false,
        enableAsyncFetching: false,
        // testData is null (default)
      ),
    ),
  );
  await tester.pump();

  // No async delay needed - everything is synchronous
  expect(find.text('No data'), findsOneWidget);
});
```

### Key Points:

1. **Always disable async operations in tests** — Use `enableTimeUpdates: false` and `enableAsyncFetching: false`
2. **Inject test data directly** — Use `testData` parameter to bypass async fetching entirely
3. **Implement didUpdateWidget** — Handle test data changes during widget rebuilds
4. **No delays needed** — When async operations are disabled, everything is synchronous
5. **Production code unaffected** — Default parameter values preserve production behavior

### Real Example:

See `lib/src/controls/fullscreen_status_bar.dart` and `test/controls/fullscreen_status_bar_test.dart` for a complete implementation:
- `enableTimeUpdates` controls `Timer.periodic` for system time updates
- `enableBatteryMonitoring` controls async battery subscription
- `testBatteryInfo` injects battery data directly
- All 11 tests pass in ~1 second without hanging

---

## Testing Controllers with Async Initialization

Controllers that perform async operations in their constructors (like checking platform feature availability) create similar testing challenges.

### Problem: Async Constructor Operations

When a controller calls async methods with `unawaited()` in its constructor, tests cannot reliably wait for the state to be set:

```dart
// ❌ PROBLEM: Async operations in constructor
class VideoControlsController extends ChangeNotifier {
  VideoControlsController({
    required ProVideoPlayerController videoController,
    // ... other parameters
  }) : _videoController = videoController {
    _videoController.addListener(_onPlayerValueChanged);
    unawaited(_checkPipAvailability());        // Fire-and-forget
    unawaited(_checkBackgroundPlaybackSupport());  // No way to wait
    unawaited(_checkCastingSupport());         // State set asynchronously
  }

  Future<void> _checkPipAvailability() async {
    final available = await _videoController.isPipAvailable();
    _controlsState.setIsPipAvailable(available: available);
  }
}
```

**Symptoms:**
- Tests cannot find buttons that depend on async state (e.g., PiP button)
- Adding `pumpAndSettle()` or delays doesn't help reliably
- State is eventually set, but timing is unpredictable in tests

### Solution: Test Parameters for Dependency Injection

Add `@visibleForTesting` parameters to both enable/disable async checks and inject test values directly:

**Controller Implementation:**

```dart
class VideoControlsController extends ChangeNotifier {
  VideoControlsController({
    required ProVideoPlayerController videoController,
    // ... other parameters
    this.enablePipCheck = true,
    this.enableBackgroundCheck = true,
    this.enableCastingCheck = true,
    @visibleForTesting bool? testIsPipAvailable,
    @visibleForTesting bool? testIsBackgroundPlaybackSupported,
    @visibleForTesting bool? testIsCastingSupported,
  }) : _videoController = videoController {
    _videoController.addListener(_onPlayerValueChanged);

    // Use test values if provided (test-only path)
    if (testIsPipAvailable != null) {
      _controlsState.setIsPipAvailable(available: testIsPipAvailable);
    } else if (enablePipCheck) {
      unawaited(_checkPipAvailability());
    }

    if (testIsBackgroundPlaybackSupported != null) {
      _controlsState.setIsBackgroundPlaybackSupported(supported: testIsBackgroundPlaybackSupported);
    } else if (enableBackgroundCheck) {
      unawaited(_checkBackgroundPlaybackSupport());
    }

    if (testIsCastingSupported != null) {
      _controlsState.setIsCastingSupported(supported: testIsCastingSupported);
    } else if (enableCastingCheck) {
      unawaited(_checkCastingSupport());
    }
  }

  /// Whether to check PiP availability asynchronously.
  ///
  /// This should only be set to false in tests to avoid async issues.
  @visibleForTesting
  final bool enablePipCheck;

  // ... similar for enableBackgroundCheck, enableCastingCheck
}
```

**Widget Implementation:**

If the controller is created inside a widget (like `VideoPlayerControls`), the widget must also expose these test parameters and pass them through:

```dart
class VideoPlayerControls extends StatefulWidget {
  const VideoPlayerControls({
    required this.controller,
    super.key,
    // ... other parameters
    @visibleForTesting this.testIsPipAvailable,
    @visibleForTesting this.testIsBackgroundPlaybackSupported,
    @visibleForTesting this.testIsCastingSupported,
  });

  final ProVideoPlayerController controller;

  /// Test-only: Directly inject PiP availability instead of checking asynchronously.
  ///
  /// When provided, bypasses async PiP check for testing.
  @visibleForTesting
  final bool? testIsPipAvailable;

  // ... similar for other test parameters

  @override
  State<VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<VideoPlayerControls> {
  late final VideoControlsController _controlsController;

  @override
  void initState() {
    super.initState();

    _controlsController = VideoControlsController(
      videoController: widget.controller,
      // ... other parameters
      testIsPipAvailable: widget.testIsPipAvailable,
      testIsBackgroundPlaybackSupported: widget.testIsBackgroundPlaybackSupported,
      testIsCastingSupported: widget.testIsCastingSupported,
    );
  }
}
```

**Test Implementation:**

```dart
testWidgets('shows PiP button when PiP is available', (tester) async {
  when(() => mockPlatform.isPipSupported()).thenAnswer((_) async => true);

  final controller = ProVideoPlayerController();
  await controller.initialize(source: const VideoSource.network('https://example.com/video.mp4'));

  await tester.pumpWidget(
    buildTestWidget(
      VideoPlayerControls(
        controller: controller,
        testIsPipAvailable: true, // Inject test value directly - no async wait needed
      ),
    ),
  );
  await tester.pump();

  // State is set synchronously - test passes reliably
  expect(find.byIcon(Icons.picture_in_picture_alt), findsOneWidget);
});
```

### Key Points:

1. **Enable/disable parameters** — Default to `true` for production, set to `false` in tests
2. **Test value injection** — Use nullable `bool?` parameters to inject values when non-null
3. **Conditional logic** — Check test value first, then check enable flag, then call async method
4. **Widget pass-through** — If controller is created in a widget, expose test parameters there too
5. **Synchronous testing** — When test values are injected, everything is synchronous - no delays needed
6. **Production unaffected** — Default parameter values preserve production behavior

### Real Example:

See `lib/src/video_controls_controller.dart` and `lib/src/video_player_controls.dart` for a complete implementation:
- `enablePipCheck`, `enableBackgroundCheck`, `enableCastingCheck` control async checks
- `testIsPipAvailable`, `testIsBackgroundPlaybackSupported`, `testIsCastingSupported` inject values
- PiP button tests pass reliably without async timing issues

---

## Test Organization

```dart
group('Feature Name', () {
  // Group-level setup
  setUp(() {
    // Setup specific to this group
  });

  group('sub-feature', () {
    test('does specific thing', () {
      // Test names read like sentences
      // "Feature Name sub-feature does specific thing"
    });
  });
});
```

### Helper Functions

```dart
// Build complex widgets
Widget buildTestWidget(Widget child) => MaterialApp(home: Scaffold(body: child));

// Position calculations
Offset getWidgetCenter(WidgetTester tester, Finder finder) {
  final renderBox = tester.renderObject<RenderBox>(finder);
  return renderBox.localToGlobal(renderBox.size.center(Offset.zero));
}

// Common controller setup
Future<VideoControlsController> createController({
  required ProVideoPlayerController videoController,
  // ... parameters with defaults
}) async {
  final controller = VideoControlsController(/* ... */);
  await Future<void>.delayed(const Duration(milliseconds: 150));
  return controller;
}
```

---

## Test Coverage

### Coverage Commands

```bash
make coverage              # Full Dart + Native coverage with summary
make test-coverage         # Dart tests with coverage only
make coverage-html         # HTML report (requires lcov)
make coverage-summary      # Summary without running tests
make test-android-native-coverage
make test-ios-native-coverage
make test-macos-native-coverage
```

### Coverage Targets

- **Dart code:** 95% line coverage per file (target)
- **Native code:** 80% line coverage (target)
- **Global minimum:** 80% line coverage overall (mandatory)
- **Public API methods:** 100% highly recommended
- Platform-specific code (platform views, Android-only paths) may have lower coverage due to test environment limitations

---

## Android Native Coverage (Important!)

Android has **three types of coverage reports** - understanding this is critical:

| Report Type | Command | Requires Device | What It Tests |
|-------------|---------|-----------------|---------------|
| **Unit tests** | `make test-android-native-coverage` | No | JVM-only code (utilities, parsing, configs) |
| **Instrumented tests** | `make test-android-instrumented-coverage` | Yes | Real Android code on device/emulator |
| **Combined** | `make test-android-full-coverage` | Yes | Both unit + instrumented (PRIMARY report) |

### Why Unit Test Coverage Appears Low

- Unit tests run on JVM without Android runtime
- Cannot test ExoPlayer, Android APIs, or platform views
- Only cover isolated utility/helper code (~10% of codebase)

**For accurate Android coverage:** Always use `make test-android-full-coverage` with a running emulator/device. This runs instrumented tests that exercise real code paths.

### Test File Locations

```
pro_video_player_android/android/src/
├── test/kotlin/          # Unit tests (JVM) - 4 files, ~170 tests
│   ├── VideoPlayerUnitTest.kt
│   ├── VideoFormatUtilsTest.kt
│   ├── BufferingConfigTest.kt
│   └── MediaPlaybackServiceTest.kt
└── androidTest/kotlin/   # Instrumented tests (device) - 3 files
    ├── VideoPlayerIntegrationTest.kt
    ├── ProVideoPlayerPluginIntegrationTest.kt
    └── PipFullscreenEspressoTest.kt
```

---

## E2E UI Tests

Located in `example-showcase/integration_test/e2e_ui_test.dart`. Covers:
- Navigation, playback controls, fullscreen, PiP detection
- Video source switching, multiple simultaneous players
- Error handling, subtitles, loop toggle

Test keys defined in `example-showcase/lib/test_keys.dart`. Requires device/simulator.

### Cross-Platform E2E Test Guidelines

**E2E tests MUST pass on ALL platforms** (iOS, Android, macOS, web). Do NOT skip tests gracefully - fix the underlying issues instead.

#### Core Principles

1. **No graceful skipping**: Tests must actually run and pass, not just skip with warnings. If a test can't run on a platform, fix the test or the app code.

2. **Handle platform differences in the test logic**: Use `tester.ensureVisible()` to scroll elements into view. Tap on video to show auto-hidden controls before asserting. Use platform-appropriate timeouts.

3. **Use longer timeouts for mobile**: Mobile simulators/emulators are slower. Use 45+ second timeouts for video loading on iOS/Android vs 15 seconds on desktop.

4. **Make controls visible before testing them**: If controls auto-hide, tap the video player to show them before asserting their presence.

5. **Ensure widgets are in viewport**: Use `tester.ensureVisible(finder)` before tapping or asserting widgets that may be off-screen.

#### Pattern for Handling Auto-Hidden Controls

```dart
// Tap to show controls before testing
await tester.tap(find.byType(VideoPlayer));
await tester.pump(const Duration(milliseconds: 500));

// Now assert controls are visible
expect(find.byKey(TestKeys.playButton), findsOneWidget);
```

#### Platform-Specific Wait Times

```dart
final maxAttempts = (kIsWeb || isMacOSPlatform) ? 15 : 45;
for (var i = 0; i < maxAttempts; i++) {
  // Wait for condition...
  await tester.pump(const Duration(seconds: 1));
}
```

**If a test fails on a platform**, investigate and fix the root cause rather than adding skip logic.

---

## Test Workarounds for Known Limitations

This section documents workarounds for Flutter testing framework limitations that cannot be resolved through code changes.

### 1. Timer Tests: Waiting for Internal Timers to Complete

**Problem:** When controller methods create internal timers (e.g., `PlaybackManager.play()` creates a 2-second timeout timer), tests hang during tearDown if timers are still pending.

**Symptom:**
```
Pending timers:
Timer (duration: 0:00:02.000000, periodic: false), created:
#5 PlaybackManager.play (package:pro_video_player/src/controller/playback_manager.dart:71:32)
```

**Workaround:** Add a delay after the operation to allow the internal timer to complete before test cleanup:

```dart
testWidgets('play button triggers playback', (tester) async {
  final controller = ProVideoPlayerController();
  await controller.initialize(source: const VideoSource.network('...'));

  await tester.pumpWidget(buildTestWidget(VideoPlayerControls(controller: controller)));
  await tester.pump();

  // Tap play button (triggers PlaybackManager.play() which creates 2-second timer)
  await tester.tap(find.byIcon(Icons.play_circle_filled));
  await tester.pump();

  verify(() => mockPlatform.play(1)).called(1);

  // Wait for PlaybackManager's 2-second timer to complete before test cleanup
  await tester.pump(const Duration(seconds: 3));
});
```

**Key Points:**
- The delay must be **longer** than the internal timer duration (3 seconds for a 2-second timer)
- This is a **temporary workaround** until the controller refactoring adds `@visibleForTesting` parameters to disable timers in tests
- Tests with this pattern are documented in ROADMAP.md under "ProVideoPlayerController refactoring → Testing Requirements"

**Examples:**
- `test/video_player_controls_settings_test.dart:189` - "compact mode play button toggles playback"
- `test/video_player_controls_settings_test.dart:840` - "tap toggles visibility in compact mode"
- `test/video_player_controls_playback_test.dart:497` - "shows controls when tapped while hidden with gestures enabled"

### 2. Modal/Bottom Sheet Tests: Verify Method Calls Instead of UI Rendering

**Problem:** Modal bottom sheets (`showModalBottomSheet`) don't render properly in unit tests, even with multiple `pump()` calls or `pumpAndSettle()` (which hangs).

**Symptom:**
```
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Speed": []>
   Which: means none were found but one was expected
```

**Workaround:** Skip UI rendering tests for modals and verify method calls instead. Modal functionality is covered by integration tests.

```dart
// Skip: pumpAndSettle() hangs with modals (bottom sheets), and pump() doesn't render modal content.
// Modal functionality is verified via integration tests. See "Common Test Pitfalls #1"
testWidgets('opens speed picker when speed button is tapped', (tester) async {}, skip: true);
```

**Alternative Approach (when applicable):** If testing the behavior triggered by a modal choice, verify the controller method is called:

```dart
testWidgets('selecting speed option calls setPlaybackSpeed', (tester) async {
  final controller = ProVideoPlayerController();
  await controller.initialize(source: const VideoSource.network('...'));

  // Simulate the user selecting a speed (bypassing modal UI)
  await controller.setPlaybackSpeed(1.5);

  verify(() => mockPlatform.setPlaybackSpeed(1, 1.5)).called(1);
});
```

**Examples:**
- `test/video_player_controls_playback_test.dart:213` - "opens speed picker when speed button is tapped" (skipped)
- `test/video_player_controls_playback_test.dart:218` - "calls setPlaybackSpeed when speed is selected" (skipped)
- `test/video_player_controls_playback_test.dart:250` - "uses custom speed options when provided" (skipped)

### 3. Keyboard Shortcut Tests: Tap + pumpAndSettle() Hit Test Failures

**Problem:** Tests that require focusing a widget for keyboard events (via `tester.tap()` + `pumpAndSettle()`) fail with hit test errors. The widget's AnimatedOpacity/IgnorePointer prevents the tap from registering.

**Symptom:**
```
Hit test failure: The finder 'VideoPlayerControls' derived an Offset that would not hit test on the specified widget.
Maybe the widget is actually off-screen, or another widget is obscuring it, or the widget cannot receive pointer events.
```

**Workaround:** Skip keyboard shortcut tests in widget tests. Keyboard shortcuts are verified via integration tests where the focus system works correctly.

```dart
// Skip: Focus/tap with pumpAndSettle() causes hit test failures.
// Keyboard shortcuts are verified via integration tests.
testWidgets('Escape key exits fullscreen', (tester) async {}, skip: true);
```

**Why This Happens:**
- Widget tests don't have a real focus system like integration tests
- `AnimatedOpacity(opacity: 0)` or `IgnorePointer` widgets prevent hit testing
- `tester.tap()` requires the widget to participate in hit testing

**Examples:**
- `test/video_player_controls_interactions_test.dart:623` - "Escape key exits fullscreen when in fullscreen mode" (skipped)
- `test/video_player_controls_interactions_test.dart:662` - "Escape key does nothing when not in fullscreen mode" (skipped)
- `test/video_player_controls_interactions_test.dart:696` - "F key toggles fullscreen" (skipped)

### 4. Native Platform View Tests: CastButton Rendering

**Problem:** Native platform views (like `CastButton` on Android) don't render in Flutter widget tests. They require a real platform environment.

**Workaround:** Skip tests that verify native platform view rendering. Casting functionality is verified via integration tests on real devices.

```dart
// Skip: CastButton uses native platform views that don't render in unit tests.
// Casting functionality is verified via integration tests.
testWidgets('shows cast button when casting is supported', (tester) async {}, skip: true);
```

**Examples:**
- `test/video_player_controls_interactions_test.dart:135` - "shows cast button when casting is supported" (skipped)
- `test/video_player_controls_interactions_test.dart:169` - "shows cast_connected icon when casting is active" (skipped)
- `test/video_player_controls_interactions_test.dart:197` - "calls startCasting when cast button is tapped" (skipped)
- `test/video_player_controls_interactions_test.dart:218` - "calls stopCasting when cast_connected button is tapped" (skipped)

### Summary: When to Skip vs. When to Fix

| Test Type | Action | Reason |
|-----------|--------|--------|
| **Internal timers** | Add 3s delay workaround | Temporary until controller refactoring adds test parameters |
| **Modal UI rendering** | Skip with documentation | Flutter limitation - modals don't render in widget tests |
| **Modal behavior** | Test controller methods | Bypass modal UI, verify the actual behavior |
| **Keyboard shortcuts** | Skip with documentation | Hit test failures with focus - covered by integration tests |
| **Native platform views** | Skip with documentation | Native views don't render in widget tests |
| **Everything else** | Fix the test or implementation | No known workaround needed |

**Current Test Status (as of 2025-12-15):**
- **110 passing** widget tests
- **10 skipped** tests (3 modal, 3 keyboard, 4 casting)
- **0 failing** tests

---

## Continuous Code Quality Review

1. **Identify missing tests** — Review edge case coverage after implementing
2. **Review for improvements** — Duplication, complexity, error handling, performance, naming
3. **Maintain coverage** — Verify coverage hasn't decreased
4. **Proactive testing** — Add tests for untested code paths
