# Architecture Guide

Comprehensive architecture patterns and guidelines for Pro Video Player.

## Architecture Guidelines

### Layer Separation

1. **Platform Interface** — Abstract `ProVideoPlayerPlatform`, DTOs, events (no platform code)
2. **Platform Implementation** — Implements interface, method channels, native code
3. **Public API** — User-friendly controllers and widgets

### Dart-First Implementation

**Implement in Dart when:**
- Logic doesn't require platform APIs
- No external dependencies needed
- General player behavior (playlist, state machine, events)

**Implement native only when:**
1. Platform APIs required (PiP, background audio, hardware accel)
2. Dart would require external libraries
3. Performance critical (rare)

**Examples:**
- ✅ Dart: Playlist logic, subtitle parsing, state management
- ❌ Native: AVPlayer/ExoPlayer control, PiP, background playback

### Type Safety Requirements

**No dynamic types allowed.** All code must use explicit static types. Dynamic types compromise type safety, IDE support, and maintainability.

**Forbidden:**
- `dynamic` type annotations
- Untyped collections (`List`, `Map` without type parameters)
- `var` without clear type inference
- Implicit `dynamic` from missing type annotations

**Required:**
- Explicit return types on all functions/methods
- Typed parameters on all functions/methods
- Typed collections (`List<String>`, `Map<String, int>`)
- Explicit type annotations where inference is unclear

```dart
// ❌ BAD: Dynamic types
dynamic processData(data) {
  List items = [];
  Map config = {};
  return items;
}

// ✅ GOOD: Explicit types
VideoPlayerValue processData(VideoPlayerValue data) {
  List<VideoTrack> items = [];
  Map<String, dynamic> config = {};  // Acceptable only for JSON parsing
  return data.copyWith(tracks: items);
}
```

**Exception:** `Map<String, dynamic>` is acceptable ONLY for JSON serialization/deserialization. Even then, convert to strongly-typed DTOs as soon as possible.

**Web Platform Exception:** JS interop with external libraries (HLS.js, DASH.js, browser APIs) that lack Dart type definitions may require `// ignore: avoid_dynamic_calls` with clear justification in comments explaining why the dynamic call is necessary.

**Enforcement:** Static analysis with strict type checking enabled (`strict-casts`, `strict-inference`, `strict-raw-types`). The following rules are enforced as **errors** (blocking compilation):
- `avoid_dynamic_calls` - Method/property access on dynamic targets
- `avoid_annotating_with_dynamic` - Explicit dynamic type annotations
- `always_declare_return_types` - Missing return type declarations
- `library_private_types_in_public_api` - Private types exposed in public API

Code with `dynamic` types will not pass `make quick-check`.

---

## Code Sharing (MethodChannelBase)

1. **MethodChannelBase (platform_interface)** — ~230 lines shared
   - create, dispose, play, pause, seek, volume, speed, subtitles, PiP, fullscreen
   - Event channel setup and parsing

2. **Platform Classes (iOS, macOS, Windows, Linux)** — ~20-40 lines each
   - Extend with platform-specific channel prefix
   - Override `buildView()` and platform-specific PiP

3. **Android/Web** — Different architectures (don't extend MethodChannelBase)

---

## Shared Apple Sources (iOS/macOS)

Swift code shared between iOS and macOS lives in `shared_apple_sources/`. CocoaPods automatically creates symlinks during `pod install`:

```
shared_apple_sources/          ← Source of truth
├── SharedVideoPlayer.swift
├── SharedPluginBase.swift
├── ...
pro_video_player_ios/ios/Classes/Shared/   ← Symlinks (auto-generated)
pro_video_player_macos/macos/Classes/Shared/ ← Symlinks (auto-generated)
```

### How It Works

Each podspec includes a `prepare_command` that creates symlinks before CocoaPods processes the files:

```ruby
s.prepare_command = <<-CMD
  mkdir -p Classes/Shared
  SHARED_DIR="$(cd ../../shared_apple_sources && pwd)"
  for file in "$SHARED_DIR"/*.swift; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      ln -sf "$file" "Classes/Shared/$filename"
    fi
  done
CMD
```

### No Manual Setup Required

Symlinks are created automatically when:
- Running `pod install` in iOS/macOS example apps
- Building iOS/macOS apps via Flutter
- Running `make quick-check` or other build commands

The `Classes/Shared/` directories are in `.gitignore` - symlinks are never committed to git.

---

## Event System

Use streams: `onPlaybackStateChanged`, `onPositionChanged`, `onBufferingChanged`, `onError`, `onSubtitleChanged`, `onPipStateChanged`, etc.

---

## Error Handling

**The library must NEVER crash.** All failures handled gracefully:
1. Catch all exceptions → convert to `ErrorEvent`
2. Graceful degradation — player continues where possible
3. State consistency — `PlaybackState.error` after errors
4. Recoverable — allow retry/recovery
5. Network resilience — auto-resume on reconnection, buffering events for delays

```dart
try {
  await nativePlayer.play();
} catch (e) {
  _eventController.add(ErrorEvent(message: 'Failed to start playback: ${e.message}', code: ErrorCode.playbackFailed));
}
```

---

## Controller Pattern

```dart
final controller = ProVideoPlayerController();
await controller.initialize(source: VideoSource.network('https://...'));
await controller.play();
await controller.dispose();
```

---

## Dependency Injection: ControllerServices

The controller uses a dependency injection container (`ControllerServices`) to manage its 12 specialized managers. This provides:

- **Encapsulation**: Dependency wiring hidden in factory method
- **Testability**: Easy to mock entire service container if needed
- **Maintainability**: Single place to see all dependencies
- **Reduced complexity**: Controller has 1 services field instead of 12 manager fields

### Manager Creation Phases

Managers are created in 4 phases to handle dependencies correctly:

**Phase 1: Independent Managers** (9 managers)
- ErrorRecoveryManager
- TrackManager
- PlaybackManager
- PipManager
- FullscreenManager
- CastingManager
- DeviceControlsManager
- SubtitleManager
- ConfigurationManager

**Phase 2: Cross-Dependent Managers** (1 manager)
- MetadataManager (depends on PlaybackManager.seekTo)

**Phase 3: Circular Dependencies** (2 managers)
- PlaylistManager (needs EventCoordinator callback)
- EventCoordinator (needs PlaylistManager reference)

**Phase 4: Resolve Circular Dependency**
```dart
playlistManager.eventSubscriptionCallback = eventCoordinator.subscribeToEvents;
```

### Adding a New Manager

1. Create manager class in `lib/src/controller/` directory
2. Add field to `ControllerServices` class
3. Wire dependencies in `ControllerServices.create()` factory method
4. Expose via controller public API (add methods to `ProVideoPlayerController`)

### Example: Controller Initialization

```dart
// Internal: Services created during initialization
final services = ControllerServices.create(
  platform: platform,
  errorRecoveryOptions: errorRecoveryOptions,
  getValue: () => value,
  setValue: (v) => value = v,
  getPlayerId: () => _playerId,
  getOptions: () => _options,
  // ... other callbacks
);

// Controller stores single services instance
_services = services;

// Access managers through services
await _services.playbackManager.play();
await _services.trackManager.setSubtitleTrack(track);
```

---

## State Management Architecture

**Philosophy:** Use only Flutter built-ins (no external state management libraries). Separate concerns for better testability and performance.

### 1. Video Playback State

**Owner:** `ProVideoPlayerController` (extends `ValueNotifier<VideoPlayerValue>`)

**Contains:** Video-specific state (position, duration, isPlaying, buffering, tracks, volume, subtitle selection, etc.)

**Pattern:** Single source of truth, reactive updates via ValueNotifier

```dart
// Controller manages all video state
class ProVideoPlayerController extends ValueNotifier<VideoPlayerValue> {
  // Video state: position, duration, tracks, etc.
}
```

### 2. UI Controls State

**Owner:** `VideoControlsState` (extends `ChangeNotifier`)

**Contains:** UI-specific state (controls visibility, hide timer, menu positions, latest volume, display interactions, etc.)

**Pattern:** Separate ChangeNotifier for UI concerns, testable in isolation

```dart
// Separate UI state from video state
class VideoControlsState extends ChangeNotifier {
  bool _controlsVisible = true;
  Timer? _hideStuffTimer;
  double _latestVolume = 1.0;

  void showControls() {
    _controlsVisible = true;
    notifyListeners();
  }

  void hideControls() {
    _controlsVisible = false;
    notifyListeners();
  }

  // Clean separation: no video logic, only UI state
}
```

**Benefits:**
- Clean separation of concerns
- UI state testable without video controller
- No external dependencies (ChangeNotifier is `flutter/foundation.dart`)

### 3. Pure Logic Classes

**Pattern:** Extract complex logic into pure Dart classes (no UI, no state, just calculations)

**Example:** `VideoToolbarManager` for toolbar action calculations

```dart
// Pure function class - easy to unit test
class VideoToolbarManager {
  const VideoToolbarManager({
    required this.availableWidth,
    required this.actions,
    required this.minimalMode,
  });

  final double availableWidth;
  final List<PlayerToolbarAction> actions;
  final bool minimalMode;

  // Pure function - testable without widgets
  (List<PlayerToolbarAction>, List<PlayerToolbarAction>) calculateVisibleActions() {
    // Logic only - no BuildContext, no controllers, no side effects
  }

  bool isActionVisible(PlayerToolbarAction action, VideoPlayerValue value) {
    // Pure calculation
  }
}
```

**Benefits:**
- Testable with simple unit tests (no widget tests needed)
- No dependencies on Flutter framework
- Clear, focused responsibility
- Easy to reason about

### 4. Granular Rebuilds

**Pattern:** Use focused `ValueListenableBuilder` scopes to minimize unnecessary rebuilds

```dart
// BAD: Entire toolbar rebuilds on every position update
ValueListenableBuilder<VideoPlayerValue>(
  valueListenable: controller,
  builder: (context, value, child) {
    return Row(children: [
      PlayPauseButton(...),      // ❌ Rebuilds unnecessarily
      PositionDisplay(...),      // ✅ Needs to rebuild
      SubtitleButton(...),       // ❌ Rebuilds unnecessarily
    ]);
  },
)

// GOOD: Only position display rebuilds
Row(
  children: [
    PlayPauseButton(...),      // ✅ Stateless, no rebuild
    ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) => PositionDisplay(value.position),
    ),
    SubtitleButton(...),       // ✅ Stateless, no rebuild
  ],
)
```

**Benefits:**
- Massive performance improvement
- Only rebuild widgets that depend on changing data
- Position updates don't rebuild buttons

### 5. Stateless Components

**Pattern:** All extracted UI components (buttons, widgets) should be stateless

**Guidelines:**
- Accept state as parameters (theme, isEnabled, speed, etc.)
- Accept callbacks for coordination (onPressed, onEnter/onExit)
- No internal state management
- Purely presentational

```dart
class PipButton extends StatelessWidget {
  const PipButton({
    required this.theme,
    required this.onPressed,
    super.key,
  });

  final VideoPlayerTheme theme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(Icons.picture_in_picture_alt, color: theme.primaryColor),
        onPressed: onPressed,
      );
}
```

**Benefits:**
- Easily testable (no state to mock)
- Predictable behavior
- Composable and reusable
- Clear data flow

### State Management Summary

| Concern | Owner | Pattern | Dependencies |
|---------|-------|---------|--------------|
| Video state | `ProVideoPlayerController` | `ValueNotifier<VideoPlayerValue>` | flutter/foundation |
| UI state | `VideoControlsState` | `ChangeNotifier` | flutter/foundation |
| Business logic | Pure classes (e.g., `VideoToolbarManager`) | Static methods / const constructors | None |
| UI components | Stateless widgets | Accept state + callbacks | flutter/widgets |
| Rebuild optimization | Scoped builders | Granular `ValueListenableBuilder` | flutter/widgets |

**Key Principles:**
1. **No external dependencies** — Only Flutter built-ins
2. **Separation of concerns** — Video state ≠ UI state ≠ Business logic
3. **Testability first** — Pure functions, dependency injection, stateless components
4. **Performance** — Minimize rebuilds with scoped listeners
5. **Simplicity** — Use the simplest pattern that works

---

## Refactoring Architectural Patterns

When breaking down large controllers (like `ProVideoPlayerController`), we apply these complementary architectural patterns:

### 1. Manager Pattern

**Description:** Encapsulate distinct areas of functionality into specialized manager classes.

**Example:** `ErrorRecoveryManager`, `TrackManager`, `PlaylistManager`, `PipManager`

**Benefits:**
- Clear ownership of responsibilities
- Isolated testing
- Independent evolution of features

```dart
class ErrorRecoveryManager {
  ErrorRecoveryManager({
    required ErrorRecoveryOptions options,
    required this.getValue,
    required this.setValue,
    required this.onRetry,
  });

  void scheduleAutoRetry(VideoPlayerError error);
  Future<void> attemptRetry();
  void dispose();
}
```

### 2. Composition Over Inheritance

**Description:** Build the controller by composing multiple specialized managers rather than inheriting functionality.

**Pattern:**
```dart
class ProVideoPlayerController {
  late final ErrorRecoveryManager _errorRecovery;
  late final TrackManager _tracks;
  late final PlaylistManager _playlist;
  late final PipManager _pip;

  // Public API delegates to managers
  Future<void> retryPlayback() => _errorRecovery.attemptRetry();
  Future<void> selectSubtitle(int index) => _tracks.selectSubtitle(index);
}
```

**Benefits:**
- Flexible composition
- No deep inheritance hierarchies
- Easy to add/remove features

### 3. Extract Class Refactoring

**Description:** Take a class doing too much and split responsibilities into separate classes (Martin Fowler's refactoring technique).

**Process:**
1. Identify cohesive groups of methods and fields
2. Extract into manager class with clear interface
3. Replace direct calls with manager delegation
4. Delete old implementation from original class

**Example:** `ProVideoPlayerController` (1,957 lines) → 12 managers + 3 coordinators + controller core (1,286 lines, -34.3% reduction)

### 4. Dependency Injection via Callbacks

**Description:** Managers receive callbacks instead of depending on the controller directly. This is **Inversion of Control**.

**Pattern:**
```dart
class ErrorRecoveryManager {
  final VideoPlayerValue Function() getValue;
  final void Function(VideoPlayerValue) setValue;
  final Future<void> Function() onRetry;

  // Manager uses callbacks, doesn't know about controller
  Future<void> attemptRetry() async {
    final value = getValue();
    // ... recovery logic ...
    await onRetry();
  }
}
```

**Benefits:**
- No circular dependencies
- Managers testable in isolation (easy to mock callbacks)
- Controllers can be swapped without changing managers

### 5. Single Responsibility Principle (SRP)

**Description:** Each manager has one clear responsibility (SOLID principles).

**Examples:**
- `ErrorRecoveryManager` — Only handles error recovery and retry logic
- `TrackManager` — Only handles track selection (audio, subtitle, quality)
- `PlaylistManager` — Only handles playlist navigation and state
- `PipManager` — Only handles Picture-in-Picture state and transitions

**Benefits:**
- Easy to understand and maintain
- Changes to one feature don't affect others
- Clear testing boundaries

### 6. Facade Pattern

**Description:** The main controller acts as a simple facade over the underlying managers, providing a clean public API.

**Pattern:**
```dart
class ProVideoPlayerController {
  // Internal managers
  late final ErrorRecoveryManager _errorRecovery;
  late final TrackManager _tracks;

  // Public API facade - simple delegation
  Future<void> retryPlayback() => _errorRecovery.attemptRetry();
  Future<void> selectSubtitle(int index) => _tracks.selectSubtitle(index);
  List<SubtitleTrack> get availableSubtitles => _tracks.availableSubtitles;
}
```

**Benefits:**
- Simple, intuitive public API
- Hides internal complexity
- Users don't need to know about managers

### 7. Separation of Concerns

**Description:** The overarching principle guiding all architecture decisions.

**Application:**
- Video state ≠ UI state (different notifiers)
- Business logic ≠ Presentation (pure classes vs widgets)
- Platform interface ≠ Implementation (abstract vs concrete)
- Feature areas ≠ Each other (separate managers)

**Benefits:**
- Clear boundaries
- Independent testing
- Parallel development possible

### Pattern Summary

| Pattern | Purpose | Example |
|---------|---------|---------|
| **Manager Pattern** | Encapsulate feature areas | `ErrorRecoveryManager` |
| **Composition** | Build from parts, not inheritance | Controller has managers |
| **Extract Class** | Split oversized classes | 1,957 lines → 12 managers + 3 coordinators |
| **Dependency Injection** | Decouple via callbacks | `getValue`, `setValue`, `onRetry` |
| **Single Responsibility** | One reason to change | Each manager handles one concern |
| **Facade** | Simple public API | Controller delegates to managers |
| **Separation of Concerns** | Clear boundaries | Video ≠ UI ≠ Business logic |

**In Practice:** These patterns work together. We **extract classes** (manager pattern) using **composition**, inject **dependencies via callbacks**, ensure each has a **single responsibility**, hide them behind a **facade**, and maintain **separation of concerns** throughout.

---

## Platform Interface Pattern & Type Conversion Layer

**CRITICAL ARCHITECTURAL RULE:** Managers and controllers MUST go through the platform interface (`ProVideoPlayerPlatform`), NOT call Pigeon APIs directly.

### Why This Matters

The platform interface provides a **type conversion layer** between domain types and Pigeon message types:

```
Correct Architecture:
Controller → Manager → Platform Interface → PigeonMethodChannelBase → Pigeon API → Native
                                          ↑
                                   Type conversion happens here
```

**Domain Types (used by managers):**
- `VideoSource`, `PipOptions`, `MediaMetadata`, `SubtitleTrack`, `AudioTrack`
- User-friendly, feature-rich classes with methods and computed properties
- What the application logic works with

**Message Types (used by Pigeon):**
- `VideoSourceMessage`, `PipOptionsMessage`, `MediaMetadataMessage`, `SubtitleTrackMessage`
- Simple data classes generated by Pigeon for platform channel serialization
- What gets sent over the platform channel

### Type Conversion Example

```dart
// In PigeonMethodChannelBase:
@override
Future<void> enterPip(int playerId, {PipOptions? options}) async {
  // Convert domain type to message type
  final message = options != null
      ? PipOptionsMessage(
          aspectRatio: [options.aspectRatio.width, options.aspectRatio.height],
          actions: options.actions?.map(_convertPipAction).toList(),
        )
      : null;

  // Call Pigeon API with converted message
  await _hostApi.enterPip(playerId, message);
}
```

### What NOT To Do

**WRONG - Bypassing Platform Interface:**
```dart
// ❌ NEVER do this in managers or controllers
class PipManager {
  Future<void> enterPip({PipOptions? options}) async {
    final api = ProVideoPlayerHostApi();  // ❌ Direct Pigeon API call
    await api.enterPip(playerId, options);  // ❌ Type error! options is PipOptions, not PipOptionsMessage
  }
}
```

**Problems:**
1. **Type mismatch** - Pigeon APIs expect Message types, not domain types
2. **Lost abstraction** - Breaks the platform interface pattern
3. **Test failures** - Tests mock `MockProVideoPlayerPlatform`, not Pigeon APIs
4. **Tight coupling** - Direct dependency on Pigeon implementation details

### Correct Pattern

**RIGHT - Using Platform Interface:**
```dart
// ✅ Correct pattern in managers
class PipManager {
  final ProVideoPlayerPlatform platform;  // ✅ Use platform interface

  Future<void> enterPip({PipOptions? options}) async {
    ensureInitialized();
    await platform.enterPip(getPlayerId()!, options: options);  // ✅ Platform handles conversion
  }
}
```

**Benefits:**
1. ✅ **Type safety** - Platform interface handles all conversions
2. ✅ **Testability** - Easy to mock `MockProVideoPlayerPlatform`
3. ✅ **Maintainability** - Single place for type conversion logic
4. ✅ **Flexibility** - Can swap Pigeon for different platform channel implementation

### Test Infrastructure Dependency

All tests use `MockProVideoPlayerPlatform`:

```dart
// test/shared/mocks.dart
class MockProVideoPlayerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements ProVideoPlayerPlatform {}

// Manager tests verify platform calls:
test('calls platform method', () async {
  when(() => mockPlatform.enterPip(any(), options: any())).thenAnswer((_) async {});
  await manager.enterPip(options: testOptions);
  verify(() => mockPlatform.enterPip(1, options: testOptions)).called(1);
});
```

**If managers called Pigeon directly:**
- ❌ 100-150 unit tests would fail
- ❌ Would need to mock Pigeon APIs with `pigeon_test_harness`
- ❌ Massive test infrastructure rewrite (200-300 lines)

### When Pigeon Can Be Called Directly

**Only in ProVideoPlayerController capability methods** that return simple types:

```dart
// ✅ OK - Simple boolean return, no type conversion needed
Future<bool> isPipSupported() {
  final api = ProVideoPlayerHostApi();
  return api.isPipSupported();
}

// ❌ NOT OK - Returns complex type that needs conversion
Future<PlatformInfo> getPlatformInfo() {
  final api = ProVideoPlayerHostApi();
  return api.getPlatformInfo();  // ❌ Returns PlatformInfoMessage, not PlatformInfo
}
```

**Rule of thumb:** If the method involves complex types (classes with multiple fields), use the platform interface. Only simple boolean/numeric methods can bypass the platform interface.

### Historical Context

This pattern emerged from a critical incident (2025-12-18) where an attempt was made to have all managers call Pigeon directly, bypassing the platform interface. The attempt failed because:

1. **Type mismatches** - 50+ compilation errors due to domain vs message types
2. **Lost abstraction** - Broke the platform interface design pattern
3. **Test infrastructure** - Would have broken 100-150 existing tests
4. **Lost work** - Git checkout ran without permission, losing 2-3 hours of changes

**Lesson learned:** The platform interface exists for a reason. Don't bypass it.

---

## File Size Guideline

**Dart files should not exceed 1,000 lines.** Large classes must be decoupled into smaller, focused components to remain short, maintainable, and testable. When a file approaches or exceeds this limit, refactor it by extracting components, controllers, or pure logic classes (see VideoPlayerControls refactoring as example).
