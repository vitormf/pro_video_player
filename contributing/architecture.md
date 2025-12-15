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

Swift code shared between iOS and macOS lives in `shared_apple_sources/`. Hard links connect this to both platform packages:

```
shared_apple_sources/          ← Source of truth
├── SharedVideoPlayer.swift
├── SharedPluginBase.swift
├── ...
pro_video_player_ios/ios/Classes/Shared/   ← Hard links
pro_video_player_macos/macos/Classes/Shared/ ← Hard links
```

### Setup After Cloning

```bash
make setup   # Creates hard links + installs git hooks
```

### Safeguards

- **Pre-commit hook** — Blocks commits if shared files are out of sync
- **`make check`** — Verifies sync (run before PRs)
- **CI** — Runs same verification

### If You Edit Shared Files Without Hard Links

- Files will diverge between iOS and macOS
- Pre-commit hook or `make check` will fail
- Fix with: `make setup-shared-links`

### Why Hard Links?

CocoaPods doesn't follow symlinks. Hard links appear as regular files to CocoaPods while ensuring all three locations point to the same file data on disk.

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

## File Size Guideline

**Dart files should not exceed 1,000 lines.** Large classes must be decoupled into smaller, focused components to remain short, maintainable, and testable. When a file approaches or exceeds this limit, refactor it by extracting components, controllers, or pure logic classes (see VideoPlayerControls refactoring as example).
