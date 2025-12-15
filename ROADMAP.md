# Pro Video Player - Roadmap

This document tracks the development progress and planned features for the Pro Video Player library.

---

## Completed ✅

<details>
<summary>Click to expand completed features</summary>

### Core Infrastructure
- Federated plugin structure (iOS, Android, Web, macOS players)
- Windows/Linux Dart layer (native implementations pending VMs)
- MethodChannelBase code sharing
- Native test infrastructure (80%+ coverage)

### Playback Features
- Play, pause, seek, volume, playback speed, loop
- Event system (state, position, duration, buffering, errors)
- Video scaling modes (fit, fill, stretch)
- Buffering configuration (5-tier system)

### Advanced Features
- PiP support (iOS, Android, Web)
- PiP remote actions (skip, play/pause, return)
- Background playback (iOS, Android)
- Platform media controls (lock screen, Control Center, notifications)
- Fullscreen support
- Subtitle support (embedded tracks)
- Audio track selection
- Quality/bitrate selection

### Playlist Support
- Playlist navigation (next, previous, jump)
- Shuffle and repeat modes
- Auto-advance on completion
- Playlist file parsing (M3U/M3U8, PLS, XSPF, ASX, WPL, JSPF, CUE, DASH/MPD)
- HLS/DASH detection (adaptive vs simple)
- Dart-side playlist parsing with 70 fixture files and 201 passing tests

### UI & Controls
- Layout modes (video only, native controls, Flutter controls, custom)
- VideoPlayerControls widget
- Theme system
- Compact mode
- Live scrubbing
- Pause during seek interactions

### Network & Error Handling
- Automatic retry (exponential backoff)
- Network reachability monitoring
- Buffering events with reason tracking
- Bandwidth estimation

### Example App
- Comprehensive feature demos
- Adaptive/responsive UI
- E2E UI tests

### Developer Experience
- Dartdoc on all public APIs
- Verbose logging system
- VideoPlayerOptions configurability
- Dart-first architecture
- Video metadata extraction

### External Subtitle Loading
- External subtitle file support (VTT, SRT, ASS, SSA, TTML from URLs)
- addExternalSubtitle() method
- Auto-format detection
- Multiple external subtitle files per video
- Dart-side parsers (80 test fixtures)
- Rendering mode integration (native/Flutter)
- WebVTT auto-conversion
- Rich text formatting support (bold, italic, underline, colors, font sizes) for SSA/ASS, WebVTT, TTML (109+ tests)

### Casting Support
- AirPlay (iOS/macOS)
- Chromecast (Android)
- Remote Playback API (Web)
- CastButton widget
- Cast state events
- Programmatic control

### DASH Streaming Support
- Android DASH (ExoPlayer)
- Web DASH (dash.js)
- Format detection
- Quality/bitrate selection
- Multi-track support
- Note: iOS/macOS use HLS only

### Adaptive Bitrate Configuration
- ABR mode option (auto/manual)
- Bitrate constraints (min/max)
- Native integration
- Note: iOS/macOS maxBitrate only

### Custom Subtitle Overlay
- Flutter-rendered subtitles
- Cross-platform styling
- Full customization API (SubtitleStyle)
- Extended styling (border, radius, alignment, padding)
- Timing adjustment/sync

### Subtitle Rendering Modes
- SubtitleRenderMode enum (native/Flutter)
- Runtime mode switching
- Embedded subtitle extraction (iOS, Android, Web)
- Subtitle overlay positioning
- Auto mode resolution
- External subtitle mode integration

### Media Navigation
- Chapter markers (extraction from native players)
- Chapter navigation UI (button + picker)

### Desktop/Web Optimized Controls
- Keyboard shortcuts (space, arrows, M, F, Shift+arrows)
- Keyboard media keys
- Mobile keyboard support
- Keyboard shortcuts help dialog
- Mouse hover controls
- Seek bar hover preview
- Right-click context menu
- Fine-grained speed control (gestures, keyboard, modal)
- Scroll wheel volume control
- Seek gesture progress bar visualization

### Platform Media Controls
- iOS/macOS remote controls (MPRemoteCommandCenter)
- Android MediaSession (Media3)
- Background playback support

### Screen Sleep Prevention
- Automatic wake lock (iOS, macOS, Android, Web)
- Configurable via preventScreenSleep option
- Smart management (play/pause/PiP-aware)

### Android App Behavior
- example-simple-player manifest configuration (singleTop, no taskAffinity)

### Code Architecture Refactoring
- PlatformVideoPlayerController (1,957 → 1,286 lines)
  - 12 manager classes + 3 coordinators
  - 131 tests passing
- VideoPlayerControls (3,453 → 812 lines)
  - VideoControlsController extracted
  - 13 button components, 7 picker dialogs
  - MobileVideoControls + DesktopVideoControls
  - 120 tests (116 passing)

### Package Rename
- Renamed package from `platform_video_player` to `pro_video_player`
- Updated 8 package directories, pubspec files, and all dependencies
- Refactored Dart imports (~285 files), Kotlin packages, Swift code, C++ files
- Updated example apps, documentation, build scripts, and configuration
- 589 files modified, all tests passing

</details>

---

## In Progress 🚧

(No active tasks)

---

## Planned (High Priority) 🔥

<details>
<summary><strong>Fix hanging widget tests in pro_video_player package</strong></summary>

- **Issue:** Several widget tests hang and do not complete, causing test suite timeouts
- **Affected Files:**
  - `compact_layout_test.dart` - hangs on "renders large play button when paused" test
  - Other widget tests showing similar symptoms
- **Root Cause Investigation Needed:**
  - Tests hang for 60+ seconds before timing out
  - May be related to async operations not completing properly
  - Could be Flutter test framework interactions with timers/animations
  - Some tests fixed by replacing `Future.delayed()` with `tester.pump()` but more issues remain
- **Impact:**
  - Widget test suite takes ~2 minutes and still has failures
  - Prevents full test suite completion
  - Makes test-driven development slower
- **Tasks:**
  - [ ] Identify all hanging widget tests
  - [ ] Debug root cause of hangs (timers, async operations, focus nodes, etc.)
  - [ ] Fix hanging tests without changing test intent
  - [ ] Document solution in contributing/testing-guide.md
  - [ ] Verify all widget tests complete in reasonable time (<30s total)
  - [ ] Ensure no test framework errors (FocusManager disposal, PathNotFoundException)
- **Context:**
  - Test directory recently reorganized into `test/unit/` and `test/widget/`
  - Some `Future.delayed()` issues already fixed in:
    - `simple_tap_wrapper_test.dart`
    - `desktop_controls_wrapper_test.dart`
    - `mobile_video_controls_test.dart`
    - `video_controls_controller_test.dart`
- **Priority:** HIGH - Reliable test suite is critical for development velocity and code quality

</details>

<details>
<summary><strong>Refactor API to align with video_player Flutter library conventions</strong></summary>

- **Rationale:** API should feel familiar to users of the official video_player Flutter library. Maintaining compatible naming conventions and design patterns reduces learning curve and enables smooth migration from video_player.
- **Current Issues:**
  - Inconsistent naming with video_player (e.g., method/property names may differ from video_player equivalents)
  - API patterns that diverge from established Flutter plugin conventions
  - Potential migration friction for users coming from video_player
- **Design Goals:**
  - Match video_player naming for overlapping functionality (`initialize()`, `play()`, `pause()`, `seekTo()`, `setVolume()`, `value`, `position`, `duration`, `isPlaying`, etc.)
  - Maintain video_player's familiar patterns even when adding new capabilities (e.g., playlists, subtitles, advanced controls)
  - New/incompatible APIs should feel like natural extensions rather than completely different paradigms
  - Preserve Flutter ecosystem familiarity that video_player exemplifies
- **Implementation Tasks:**
  - [ ] **Audit current API against video_player reference implementation:**
    - Compare ProVideoPlayerController API with VideoPlayerController
    - Identify naming differences (methods, properties, enums)
    - Document API compatibility matrix (compatible/extended/different)
  - [ ] **Refactor core playback API:**
    - Align method names with video_player conventions
    - Match property naming patterns
    - Ensure value types match where possible (Duration, bool, etc.)
  - [ ] **Refactor state management API:**
    - Review value/state access patterns (e.g., `controller.value` pattern)
    - Align event/notification patterns with video_player
    - Ensure similar initialization/disposal lifecycle
  - [ ] **Design extended APIs to feel compatible:**
    - Playlist APIs should follow familiar controller patterns
    - Subtitle APIs should integrate naturally with existing patterns
    - Advanced features (PiP, casting) should feel like logical extensions
  - [ ] **Update all tests:**
    - Refactor tests to match new API
    - Verify backward compatibility where possible
    - Add migration tests if breaking changes needed
  - [ ] **Update documentation:**
    - Highlight video_player compatibility in README
    - Document migration path from video_player
    - Explain extensions/differences clearly
  - [ ] **Update example apps:**
    - Refactor example code to use aligned API
    - Show migration examples from video_player patterns
- **Success Criteria:**
  - Users familiar with video_player can use this library with minimal learning curve
  - Core playback APIs match video_player conventions
  - Extended APIs feel like natural additions to familiar patterns
  - Documentation clearly maps video_player concepts to this library
- **Priority:** HIGH - Foundational API design affects all future development and user adoption
- **Reference:** https://pub.dev/packages/video_player (official Flutter video_player plugin)

</details>

<details>
<summary><strong>Audit library code for example app references</strong></summary>

- **Rationale:** Library packages must be completely self-sufficient and independent from example apps. Any references to example app code, resources, or package names create coupling that breaks library portability and prevents proper distribution.
- **Critical Issue:** Library code referencing example app classes or resources means the library cannot work standalone - users would get compilation errors when integrating the plugin.
- **Scope:** Search all library packages for references to example apps:
  - [ ] **Dart code audit:**
    - [ ] Search for imports referencing `example-showcase` or `example-simple-player` packages
    - [ ] Check for hardcoded paths to example app assets
    - [ ] Look for class references to example-specific code
  - [ ] **Native code audit (Android):**
    - [ ] Search Kotlin files for `com.example.platform_video_player_example` or similar example app package references
    - [ ] Check for hardcoded resource references to example app resources (R.drawable, R.string, etc.)
    - [ ] Verify no dependencies on example app activities or services
  - [ ] **Native code audit (iOS/macOS):**
    - [ ] Search Swift files for example app bundle identifiers
    - [ ] Check for hardcoded paths to example app assets
    - [ ] Verify no dependencies on example app classes or resources
  - [ ] **Native code audit (Web):**
    - [ ] Search JavaScript for example app references
    - [ ] Check for hardcoded DOM element IDs specific to example apps
  - [ ] **Build configuration audit:**
    - [ ] Verify podspec files don't reference example app paths
    - [ ] Check gradle files for example app dependencies
    - [ ] Ensure no example app assets bundled in library packages
- **Implementation:**
  - [ ] Run grep/search for `example-showcase`, `example-simple-player`, `example_showcase`, `example_simple_player` across all library package directories
  - [ ] Search for package imports: `package:example` patterns
  - [ ] Check for suspicious hardcoded paths containing "example"
  - [ ] Remove any found references and refactor to library-internal solutions
  - [ ] Document findings and fixes
- **Success Criteria:**
  - Zero references from library code to example app code, resources, or package names
  - Library packages can be used independently without example apps present
  - All library tests pass without example app dependencies
- **Priority:** HIGH - This is a fundamental architectural requirement for a distributable library

</details>

<details>
<summary><strong>Evaluate and standardize testing architecture across all tests</strong></summary>

- **Rationale:** Tests are taking unexpectedly long to write correctly due to recurring issues. After fixing ~106 analyzer issues from controller refactoring, we identified patterns that would eliminate these time-consuming problems.
- **Current Issues:**
  - Inconsistent mock setup patterns (some files use different tearDown approaches)
  - Potential duplication of test infrastructure code
  - No standardized fixture/helper utilities across test suites (e.g., `buildTestWidget()` duplicated in 20+ files)
  - Different approaches to handling async operations and delays (magic numbers: 50ms, 100ms, 150ms, 200ms)
  - Unclear conventions for organizing test groups and helper functions
  - Missing domain-specific test patterns (builders, object mothers, custom matchers)
- **Recurring Pain Points (Time Sinks):**
  1. **Incomplete MockVideoControlsState** — Tests fail with `type 'Null' is not a subtype of type 'bool'` because required properties are missing. Developers discover this only at runtime, not compile time. **Solution:** Type-safe fixture that provides complete mock automatically.
  2. **Widget finder ambiguity** — Tests fail with "Expected one, found 7" because nested MaterialApp/Scaffold creates multiple MouseRegion/Column instances. Unclear when to use `findsOneWidget` vs `findsWidgets`. **Solution:** Document patterns + provide helpers that use correct matchers by default.
  3. **Async timing guesswork** — Tests intermittently fail because delays are too short. Developers cargo-cult delays (50ms, 100ms, 150ms) without understanding why. **Solution:** Named constants with documentation explaining purpose of each delay.
  4. **tearDown using wrong class** — Easy to write `MethodChannelPlatformVideoPlayer()` instead of `MockPlatformVideoPlayerPlatform()`. Only discovered when tests run. **Solution:** Fixture handles tearDown automatically - developers never write tearDown code.
  5. **Duplicated setup boilerplate** — Every test file has 50+ lines of identical mock setup. Copy-paste errors common. **Solution:** Fixture provides all mocks pre-configured. Tests just call `fixture.setUp()`.
  6. **BuildContext/MaterialApp errors** — "No MaterialApp ancestor found" errors require wrapping in MaterialApp > Scaffold. Developers forget this pattern. **Solution:** Provide `buildTestWidget()` helper that always wraps correctly.
  7. **Event propagation mysteries** — Events emitted but controller state doesn't update. Developers don't know to wait 50ms. **Solution:** Fixture methods like `fixture.emitAndWait(event)` handle timing automatically.
  8. **Missing fallback values** — Mocktail throws "No argument was defined for this invocation" at runtime. Developers must manually register each type. **Solution:** Fixture registers all common fallback values in `setUpAll()`.
  9. **Pump confusion (MAJOR TIME SINK)** — Developers don't know:
     - When to use `pump()` vs `pumpAndSettle()` vs `pump(duration)`
     - How many pumps are needed (one? two? multiple?)
     - Whether to add `await Future.delayed()` before or after pump
     - Why tests pass with `pumpAndSettle()` but hang with modals
     - What "frames" and "animation ticks" mean in pump context
     **Solution:** Fixture provides semantic helpers:
     - `fixture.renderWidget(widget)` — Pumps once after pumpWidget (standard case)
     - `fixture.waitForAnimation()` — Safe pumpAndSettle with timeout (for non-modal animations)
     - `fixture.triggerAction(action)` — Tap + pump in one call
     - Clear documentation: "pump() = render 1 frame, pumpAndSettle() = wait for animations to finish, pump(duration) = advance time"
- **Design Goals for Architecture:**
  1. **Compile-time safety** — Type errors caught by analyzer, not at runtime
  2. **Minimal boilerplate** — Common patterns automated away
  3. **Self-documenting** — Named constants and helpers explain timing/delays
  4. **Hard to misuse** — Correct usage is easier than incorrect usage
  5. **Fast to write** — New test files start from working template
  6. **Clear error messages** — When tests fail, errors point to actual problem
- **Recommended Architectural Patterns:**
  1. **Test Fixture Pattern** — Mandate `VideoPlayerTestFixture` for all controller tests (currently inconsistently applied)
  2. **Shared Test Helpers** — Move duplicated helpers (`buildTestWidget`, position calculations) to `test/shared/test_helpers.dart`
  3. **Test Data Builders** — Implement builder pattern for complex test objects (e.g., `VideoSourceBuilder`, `PlaylistBuilder`)
  4. **Object Mother Pattern** — Provide pre-configured test objects in `test/shared/test_data.dart` (e.g., `VideoPlayerTestData.playingState`)
  5. **Named Constants** — Replace magic numbers with named delays in `test/shared/test_constants.dart` (e.g., `TestDelays.eventPropagation`)
  6. **Custom Matchers** — Domain-specific assertions in `test/shared/test_matchers.dart` (e.g., `expect(controller, isPlaying)`)
  7. **Page Object Pattern** — For complex widget tests, encapsulate interactions in `test/shared/page_objects/` (e.g., `VideoControlsPage`)
  8. **Standard Test Structure** — Document mandatory test organization in contributing/testing-guide.md
- **Proposed Test Infrastructure:**
  ```
  test/
  ├── shared/
  │   ├── test_setup.dart         # Fixtures (existing)
  │   ├── test_helpers.dart       # Shared widget builders (NEW)
  │   ├── test_builders.dart      # Data builders (NEW)
  │   ├── test_data.dart          # Object Mother (NEW)
  │   ├── test_constants.dart     # Named delays, sizes (NEW)
  │   ├── test_matchers.dart      # Custom matchers (NEW)
  │   └── page_objects/           # Page objects for widgets (NEW)
  └── [test files]
  ```
- **Implementation Tasks:**
  - [ ] **Enhanced VideoPlayerTestFixture** — Add methods that solve pain points:
    - `fixture.emitAndWait(event)` — Emits event + waits appropriate delay automatically
    - `fixture.buildTestWidget(child)` — Returns properly wrapped widget
    - `fixture.renderWidget(tester, child)` — Combines pumpWidget + pump (standard case)
    - `fixture.waitForAnimation(tester)` — Safe pumpAndSettle with timeout (prevents hangs)
    - `fixture.tap(tester, finder)` — Combines tap + pump in one call
    - `fixture.tapAndSettle(tester, finder)` — Tap + wait for animations (e.g., bottom sheets)
    - Pre-configured complete `MockVideoControlsState` with all required properties
    - Automatic tearDown (no manual tearDown needed in tests)
  - [ ] **test/shared/test_helpers.dart** — Consolidate all duplicated helpers:
    - `buildTestWidget(child)` — MaterialApp > Scaffold wrapper
    - `buildSizedTestWidget(child, {width, height})` — With size constraints
    - `expectPlaying(controller)` — Self-documenting assertions
    - `expectPaused(controller)` — Self-documenting assertions
  - [ ] **test/shared/test_constants.dart** — Named delays with documentation:
    - `TestDelays.eventPropagation` (50ms) — "Wait for event stream to process and notify listeners"
    - `TestDelays.controllerInitialization` (150ms) — "Wait for async platform calls during init"
    - `TestDelays.stateUpdate` (100ms) — "Wait for state changes to propagate through notifiers"
  - [ ] **test/shared/test_matchers.dart** — Domain-specific matchers:
    - `isPlaying`, `isPaused`, `isBuffering` — Playback state matchers
    - `hasPosition(duration)` — Position matcher with tolerance
    - `isInFullscreen`, `isInPip` — State matchers
  - [ ] **Test file template** — VSCode/IDE snippet for new test files:
    ```dart
    // Template that always works correctly
    void main() {
      late VideoPlayerTestFixture fixture;

      setUpAll(registerVideoPlayerFallbackValues);

      setUp(() {
        fixture = VideoPlayerTestFixture()..setUp();
      });

      tearDown(() => fixture.tearDown()); // Fixture handles everything

      group('Feature Name', () {
        testWidgets('behavior description', (tester) async {
          await fixture.initializeController();

          // No more pump confusion - semantic helpers handle it
          await fixture.renderWidget(
            tester,
            YourWidget(controller: fixture.controller),
          );

          // Emit event with automatic timing
          await fixture.emitAndWait(const PlaybackStateChangedEvent(PlaybackState.playing));

          // Tap with automatic pump
          await fixture.tap(tester, find.byIcon(Icons.pause));

          // Self-documenting assertions
          expect(fixture.controller, isPaused);
        });

        testWidgets('bottom sheet interaction', (tester) async {
          await fixture.initializeController();
          await fixture.renderWidget(tester, YourWidget(controller: fixture.controller));

          // Tap + wait for animation (e.g., bottom sheet sliding in)
          await fixture.tapAndSettle(tester, find.byIcon(Icons.settings));

          // Now assert on bottom sheet content
          expect(find.text('Settings'), findsOneWidget);
        });
      });
    }
    ```
  - [ ] **Documentation updates:**
    - Add "Quick Start: Writing Your First Test" to testing-guide.md
    - Document all fixture helper methods with examples
    - **Pump helpers decision tree:** When to use which helper (visual flowchart)
      - Need to render widget? → `fixture.renderWidget(tester, widget)`
      - Need to tap button? → `fixture.tap(tester, finder)`
      - Need to wait for animation (non-modal)? → `fixture.tapAndSettle(tester, finder)`
      - Need to wait for event processing? → Already handled by `fixture.emitAndWait()`
      - Modal bottom sheet? → Use `tapAndSettle` then assert immediately
    - Create troubleshooting guide mapping error messages to solutions
  - [ ] **Audit and migration:**
    - Identify all test files not using fixture pattern
    - Create prioritized migration plan (start with most duplicated)
    - Refactor tests in batches, verify all pass before moving to next batch
- **Success Metrics:**
  - Time to write new correct test: **< 5 minutes** (from template to passing)
  - Runtime errors in tests: **< 1%** (most errors caught at compile time)
  - Test code duplication: **< 5%** (measured by jscpd)
  - Developer confidence: Can write widget tests without consulting existing tests
- **Benefits:**
  - Eliminate test code duplication
  - Consistent, predictable test structure across entire codebase
  - More readable tests (domain language vs technical details)
  - Easier to write new tests following established patterns
  - Reduced test maintenance burden
  - Prevention of future API migration issues like the one we just fixed
- **Scope:** Review all ~250+ test files across platform_video_player, platform_interface, and platform implementations
- **Note:** This is foundational work that will pay dividends as the codebase grows

</details>

<details>
<summary><strong>Refactor duplicate code - Eliminate all duplication (0% target)</strong></summary>

- **Current State:** jscpd detected 35 code clones across 563 lines (2.17% duplication)
- **Target:** Zero duplication (0%) through shared base classes and utilities (mandatory)
- **Primary Duplications:**
  - **Dialog pickers (11 clones):** `speed_picker_dialog.dart`, `subtitle_picker_dialog.dart`, `quality_picker_dialog.dart`, `audio_picker_dialog.dart`, `orientation_lock_picker_dialog.dart`, `scaling_mode_picker_dialog.dart`
    - Similar UI patterns for showing picker dialogs (~12-21 lines each)
    - Create base `PickerDialog<T>` widget with customization options
  - **Controller managers (3 clones):** `fullscreen_manager.dart`, `track_manager.dart`, `configuration_manager.dart`, `playback_manager.dart`
    - Similar initialization patterns (~17-21 lines each)
    - Extract common initialization logic to base class or mixin
  - **Progress bar rendering (2 clones):** `compact_layout.dart` vs `progress_bar.dart`
    - Shared rendering logic (~15-31 lines each)
    - Extract progress rendering to reusable widget/mixin
  - **Bottom controls bar (1 clone):** `bottom_controls_bar.dart` internal duplication
    - Button layout patterns repeated (~23 lines)
    - Create button row builder utility
  - **Status bar icons (2 clones):** `fullscreen_status_bar.dart` internal duplication
    - Icon rendering patterns (~12-13 lines each)
    - Extract icon builder utility
  - **Platform detection (1 clone):** `pro_video_player_linux.dart` vs `pro_video_player_windows.dart`
    - Identical buildView implementation (~12 lines)
    - Share via common base class or mixin
- **Implementation Tasks:**
  - [ ] Create base `PickerDialog<T>` widget for all dialog pickers
  - [ ] Extract controller manager initialization to base class/mixin
  - [ ] Create reusable progress bar rendering utilities
  - [ ] Extract button row builder for bottom controls
  - [ ] Create icon builder utility for status bar
  - [ ] Share Linux/Windows buildView implementation
  - [ ] Run `make check-duplicates` to verify < 1% duplication
- **Benefits:**
  - Improved maintainability (fix bugs in one place)
  - Consistent behavior across similar components
  - Easier to add new picker dialogs or controller managers
  - Cleaner, more focused code

</details>

<details>
<summary><strong>Enable memory leak tracking in all tests</strong></summary>

- **Rationale:** Video players manage native resources (players, textures, streams) that can leak if not properly disposed
- **Benefits:**
  - Catch memory leaks in controller lifecycle automatically
  - Verify native player resources are properly disposed
  - Detect stream subscription leaks (event channels, battery monitoring)
  - Prevent gradual memory accumulation in long-running apps
  - Essential for mobile platforms with limited memory
  - Built into Flutter 3.22+ (no additional dependencies)
- **Implementation approach:**
  - [ ] Enable leak tracking in controller disposal tests
  - [ ] Add leak tracking to widget tests (VideoPlayerControls, buttons, overlays)
  - [ ] Enable for platform channel communication tests
  - [ ] Configure appropriate ignore rules for known Flutter framework leaks
  - [ ] Add to CI pipeline (fail on detected leaks)
  - [ ] Document leak tracking patterns in contributing/testing-guide.md
- **Scope:** ~131 controller tests + ~120 controls tests + platform-specific tests
- **Note:** Zero runtime cost (dev-only), catches real bugs that integration tests miss

</details>

<details>
<summary><strong>Adopt Pigeon for type-safe platform channel communication</strong></summary>

- **Rationale:** Eliminate runtime errors from Dart-native interface mismatches with compile-time verification
- **Benefits:**
  - Type-safe API definitions with generated Dart, Kotlin, Swift code
  - Compile-time errors if interface doesn't match between Dart and native
  - No runtime string-based method lookups or dynamic casting
  - Better IDE autocomplete, refactoring, and navigation
  - Zero runtime dependencies for library users (pigeon is dev-only code generator)
  - Fast generation (~100ms for ~50 methods)
- **Implementation approach:**
  - [ ] Add pigeon as dev_dependency to platform_interface package only
  - [ ] Create `pigeons/video_player_api.dart` with API definitions
  - [ ] Generate initial code for subset of methods (proof of concept)
  - [ ] Incremental migration: New features use Pigeon, existing methods migrated gradually
  - [ ] Update MethodChannelBase to wrap generated Pigeon APIs
  - [ ] Verify no performance regression vs current MethodChannel
  - [ ] Update all platform implementations to use generated code
- **Scope:** ~50 method channel calls + ~25 event types across 4 primary platforms
- **Note:** Used by official Flutter plugins (video_player, camera, webview). No compilation slowdown - only runs when explicitly invoked, not on every build.

</details>


<details>
<summary><strong>Code Architecture Refactoring - Large Files</strong></summary>

- [ ] **Code Architecture Refactoring - Large Files**
  - [ ] **web_video_player.dart** (1,981 lines - exceeds 1,000 line guideline by ~98%)
    - Extract managers for distinct concerns (subtitle management, track management, casting, event handling)
    - Split initialization/disposal logic into coordinators
    - Create focused components for JS interop, element management, stream handling
    - Split monolithic test file into focused test suites
    - Target: Reduce to <1,000 lines with clean separation of concerns
  - [ ] **video_player_gesture_detector.dart** (943 lines - approaches 1,000 line guideline)
    - Extract gesture handlers into separate classes (seek, volume, brightness, speed)
    - Separate state management from gesture detection logic
    - Create coordinator for gesture→action mapping
    - Improve testability through dependency injection
    - Target: Reduce to ~500-600 lines
  - [ ] **video_controls_controller.dart** (925 lines - approaches 1,000 line guideline)
    - Extract managers for distinct UI concerns (visibility, timers, menu positioning)
    - Separate display state (brightness, volume) from control state
    - Create focused coordinators for control lifecycle
    - Improve test coverage with focused test suites
    - Target: Reduce to ~600-700 lines
  - **Benefits:**
    - Maintain file size guideline (<1,000 lines per file)
    - Improved testability and maintainability
    - Clear separation of concerns
    - Easier to understand and modify
    - Follow established patterns from PlatformVideoPlayerController and VideoPlayerControls refactorings

</details>

---

## Planned (Medium Priority) 📌

<details>
<summary><strong>Chapter navigation enhancements</strong></summary>

- [ ] Visual chapter markers in progress bar
  - Display chapter boundaries as markers/ticks on the seek bar
  - Highlight current chapter segment
  - Optional chapter titles on hover/tap
- [ ] Chapter navigation buttons in Flutter controls
  - Previous/Next chapter buttons (optional, configurable)
  - Skip to chapter start/end
  - Integrate with existing toolbar layout system
  - Respect compact mode (hide in minimal layouts)
- **Benefits:**
  - Quick visual reference of video structure
  - Faster navigation for long-form content (tutorials, movies, podcasts)
  - Better UX for chapter-heavy content

</details>


<details>
<summary><strong>Pure Dart container header parser</strong></summary>

- [ ] Pure Dart container header parser:
  - [ ] Parse container file headers without native player (MP4, MKV, WebM, MOV, etc.)
  - [ ] Extract ALL available streams (multiple video/audio/subtitle tracks)
  - [ ] Per-stream metadata: codec, bitrate, language, resolution, channel layout
  - [ ] Stream positioning data: byte offsets, duration, sample tables
  - [ ] Extract codec strings and profiles (e.g., "hvc1.1.6.L93.B0", "vp09.00.41.08", "av01")
  - [ ] No external dependencies (Dart-first approach using ByteData/Uint8List)
  - [ ] Benefits over current VideoMetadata:
    - Platform-independent (works on web without native APIs)
    - Reveals all tracks (current implementation only shows single video/audio codec)
    - No player initialization required (inspect before playback)
    - Foundation for remuxing (need stream positions for segmentation)
  - [ ] Implementation phases:
    - [ ] Phase 1: MP4/MOV parser (ISO base media file format - box/atom structure)
    - [ ] Phase 2: MKV/WebM parser (EBML/Matroska specification)
    - [ ] Phase 3: Additional formats as needed
  - [ ] Codec compatibility testing integration:
    - [ ] Query native platform capabilities with extracted codec info
    - [ ] iOS/macOS: AVAssetTrack.isPlayable, AVPlayer.availableVideoCodecTypes
    - [ ] Android: MediaCodecList.findDecoderForFormat, RendererCapabilities
    - [ ] Web: MediaSource.isTypeSupported(), HTMLMediaElement.canPlayType()
    - [ ] Benefits:
      - Pre-flight compatibility checks before playback attempt
      - Intelligent fallback suggestions (alternative quality/format)
      - Helpful error messages ("Requires iOS 17+ for AV1" vs generic failure)
      - Platform/device-specific warnings (HEVC on Android, VP9 on iOS, DASH on Apple)
      - Trigger remuxing only when needed
  - [ ] Use cases: Pre-playback inspection, stream selection UI, remuxing preparation, format compatibility checks, codec capability testing
  - [ ] Note: Header parsing only (not video decoding), reasonable performance

</details>

<details>
<summary><strong>Subtitle performance and preferences</strong></summary>

- [ ] **Subtitle performance and preferences**:
  - [ ] **Performance optimization for large subtitle files**:
    - Lazy loading - only parse cues near current playback position
    - Preload window (e.g., ±5 minutes from current position)
    - Cache parsed cues to avoid re-parsing
    - Handle 2000+ cue files efficiently (2-hour movies)
  - [ ] **Subtitle preferences persistence**:
    - Remember user subtitle choices across sessions
    - Save: language, enabled state, custom styling
    - Auto-restore preferences on next video
    - Per-user or per-app storage
  - [ ] Note: Monitor for user-reported performance issues before implementing

</details>

---

## Planned (Lower Priority) 💡

<details>
<summary><strong>Desktop platforms: libmpv for macOS, Windows, and Linux</strong></summary>

- [ ] Desktop platforms: libmpv for macOS, Windows, and Linux:
  - [ ] Shared C++ libmpv player core across all desktop platforms
  - [ ] macOS adapter: Add libmpv as interchangeable alternative to AVPlayer
    - [ ] Keep both implementations (AVPlayer + libmpv)
    - [ ] Allow switching between implementations (configuration option)
    - [ ] AVPlayer: AirPlay, PiP support, native integration
    - [ ] libmpv: Broader format support (MKV, WebM, etc.)
    - [ ] User chooses based on needs
  - [ ] Windows adapter: Win32/HWND integration (requires Windows VM + Visual Studio)
  - [ ] Linux adapter: GTK/X11/Wayland integration (requires Linux VM + libmpv dev libs)
  - [ ] Benefits: MKV, WebM, and virtually all formats supported natively
  - [ ] Note: Binary size increase ~10-25MB per platform (only when libmpv included)

</details>

<details>
<summary><strong>Video caching</strong></summary>

- [ ] Video caching:
  - [ ] Configurable cache size and location
  - [ ] Cache management (clear, preload)
  - [ ] Offline playback support

</details>

<details>
<summary><strong>Audio enhancements</strong></summary>

- [ ] Audio enhancements:
  - [ ] Audio boost/normalization - Amplify quiet audio
  - [ ] Audio delay/sync adjustment - Fix audio sync issues

</details>

<details>
<summary><strong>Subtitle UX and accessibility enhancements</strong></summary>

- [ ] **Subtitle UX and accessibility enhancements**:
  - [ ] **Dual subtitle tracks** - Display two tracks simultaneously (e.g., native + learning language)
    - Language learning use case (English + Spanish)
    - Configurable positioning (primary bottom, secondary top)
    - Separate styling for each track
  - [ ] **SDH (Subtitles for Deaf/Hard of hearing) support**:
    - Distinguish SDH/CC tracks from regular subtitles
    - Track metadata: `isSDH`, `isForced`, `isCommentary` flags
    - Auto-select SDH when accessibility settings detected
    - Sound effect descriptions, speaker identification
  - [ ] **Enhanced subtitle track metadata**:
    - Track title/description (e.g., "English (Full)" vs "English (Forced)")
    - Default/forced/hearing-impaired flags
    - Codec information for debugging
  - [ ] **Subtitle-aware seeking**:
    - `skipToNextSubtitle()` / `skipToPreviousSubtitle()` - Jump between dialogue
    - `replayCurrentSubtitle()` - Replay from subtitle start
    - Useful for language learning and review
  - [ ] **Subtitle search and navigation**:
    - Search subtitle text content
    - Jump to specific subtitle/dialogue
    - Navigate through search results
    - Educational content use case

</details>

<details>
<summary><strong>Advanced embedded subtitle extraction with full styling</strong></summary>

- [ ] Advanced embedded subtitle extraction with full styling:
  - [ ] Extract raw subtitle track data to preserve styling (before native player processing)
  - [ ] Parse embedded SSA/ASS, TTML formats in Dart to preserve styling
  - [ ] Full styling support for Flutter rendering mode (colors, fonts, positions, animations)
  - [ ] **Two different approaches based on source type:**
    - **Streaming (HLS/DASH) - Easier:**
      - [ ] Parse HLS m3u8 manifest to find subtitle track URLs
      - [ ] Parse DASH MPD manifest to find subtitle segments
      - [ ] Fetch subtitle files/segments directly (often WebVTT)
      - [ ] Bypass native player subtitle handling entirely
      - [ ] Benefit: Subtitles are already separate files in stream manifests
    - **Local files (MP4/MKV) - Complex:**
      - [ ] iOS/macOS: Use `AVAssetReader` to extract raw subtitle track data from container
      - [ ] Android: Custom ExoPlayer extractors or `MediaExtractor` API to demux
      - [ ] Web: Limited - may not be feasible due to browser API constraints
      - [ ] Requires: Container demuxing, track extraction
  - [ ] Benefits:
    - Preserve advanced SSA/ASS styling from embedded tracks (not just plain text)
    - Maintain TTML positioning and formatting metadata
    - **Works with both local files AND streaming content (HLS/DASH)**
    - Consistent with external subtitle file parsing approach
  - [ ] Current limitation: Native extraction only provides plain text cues, styling is lost
  - [ ] Note: Streaming implementation may be easier to start with (manifest parsing vs container demuxing)

</details>

<details>
<summary><strong>DLNA/UPnP streaming support</strong></summary>

- [ ] DLNA/UPnP streaming support:
  - [ ] Device discovery via SSDP (Simple Service Discovery Protocol)
  - [ ] Media streaming to DLNA receivers (smart TVs, speakers, media servers)
  - [ ] Transport control (play/pause/seek/volume on remote device)
  - [ ] Android and iOS/macOS implementations

</details>

<details>
<summary><strong>Miracast screen mirroring</strong></summary>

- [ ] Miracast screen mirroring:
  - [ ] Android Miracast source support (WifiP2pManager)
  - [ ] Windows Miracast source support
  - [ ] Note: iOS doesn't support Miracast (AirPlay only)

</details>

<details>
<summary><strong>iOS Chromecast support</strong></summary>

- [ ] iOS Chromecast support:
  - [ ] Integrate Google Cast SDK for iOS
  - [ ] Add GCKUICastButton alongside AVRoutePickerView in CastButton widget
  - [ ] Show combined picker or user-selectable mode (AirPlay vs Chromecast)
  - [ ] Note: Requires adding google-cast-sdk dependency (~2MB)

</details>

<details>
<summary><strong>Pure Dart video remuxer</strong></summary>

- [ ] Pure Dart video remuxer:
  - [ ] Convert various video formats into HLS
  - [ ] No external dependencies (Dart-first approach)
  - [ ] Container format parsing (MP4, MKV, WebM, etc.)
  - [ ] HLS manifest generation (M3U8)
  - [ ] Segment creation and packaging
  - [ ] Benefits: Enable HLS streaming for non-HLS sources on web and platforms without native format support
  - [ ] Use cases: Progressive MP4 → HLS conversion, format compatibility layer
  - [ ] Note: CPU-intensive operation, consider performance implications
  - [ ] Prerequisite: Container header parser (for stream positioning data)

</details>

<details>
<summary><strong>Golden Toolkit - Visual regression testing for UI controls</strong></summary>

- [ ] **Golden Toolkit - Visual regression testing**
  - **Rationale:** Catch visual regressions automatically in complex UI control layouts through screenshot comparison
  - **Benefits:**
    - Snapshot test control UI layouts (desktop vs mobile, themes, compact mode)
    - Automatically detect unintended visual changes (padding, sizing, positioning)
    - Test responsive layouts across multiple screen sizes in single test
    - Much faster than manual UI verification
    - Great for PR reviews - see visual diffs immediately
    - Prevent accidental control layout breakage during refactoring
  - **Use cases:**
    - VideoPlayerControls layout variations (desktop/mobile/compact)
    - Subtitle overlay positioning and styling
    - Button positioning and sizing across themes
    - Progress bar rendering states
    - Menu overlays and picker dialogs
    - Responsive breakpoint behavior
  - **Implementation approach:**
    - [ ] Add golden_toolkit as dev_dependency (~0.15.0)
    - [ ] Create golden tests for key control layouts
    - [ ] Start with high-value tests: DesktopVideoControls, MobileVideoControls
    - [ ] Add golden tests for subtitle overlay positioning
    - [ ] Test theme variations (light/dark) and compact mode
    - [ ] Configure CI to fail on visual regressions
    - [ ] Document golden test patterns in contributing/testing-guide.md
  - **Scope:** Focus on VideoPlayerControls and overlay components (~20-30 golden tests)
  - **Note:** Goldens need updating when UI intentionally changes. Pixel-perfect matching can be brittle on different platforms.

</details>

---

## Notes

- This roadmap is subject to change based on user feedback and project priorities
- Items are tracked from high to low priority
- Completed items are kept for historical reference
- **File Size Guideline**: Dart files should not exceed 1,000 lines. Large classes must be decoupled into smaller, focused components to remain short, maintainable, and testable. When a file approaches or exceeds this limit, refactor it by extracting components, controllers, or pure logic classes (see VideoPlayerControls refactoring as example)
