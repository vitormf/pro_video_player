# Pigeon Migration Guide

This document describes the per-platform Pigeon architecture for type-safe platform channel communication.

## Status: Per-Platform Implementation Complete ✅

The Pigeon integration uses a **per-platform architecture** with hard-linked API definitions to ensure version compatibility while maintaining a single source of truth.

### Architecture Overview

**Per-Platform Pigeon with Hard Links:**
- Each platform package (Android, iOS, macOS) has its own Pigeon definitions and generated code
- API definitions are hard-linked from `shared_pigeon_sources/` to each platform's `pigeons/` directory
- Each platform generates code locally with platform-specific configurations
- Web platform does not use Pigeon (uses JavaScript interop instead)

**Why Per-Platform?** See [PIGEON_ARCHITECTURE.md](PIGEON_ARCHITECTURE.md) for detailed rationale. TL;DR: Prevents version-mismatch crashes in production when packages are updated independently.

### Completed

- ✅ Pigeon v22.7.4 added to each platform package as dev_dependency
- ✅ Hard links from `shared_pigeon_sources/` to Android/iOS `pigeons/` directories
- ✅ macOS uses platform-specific configuration (not hard-linked)
- ✅ Complete API with 50+ methods, 9 enums, 14 message classes
- ✅ Generated code for Dart + Kotlin (Android), Dart + Swift (iOS/macOS)
- ✅ Native handlers implemented for iOS/macOS/Android
- ✅ Automated setup and verification scripts in makefiles
- ✅ All compilation checks passing (Dart, Kotlin, Swift, format, logging, duplicates)

### Hard Link Structure

```
shared_pigeon_sources/          # Master copies (single source of truth)
├── messages.dart               # Complete API definition
└── copyright_header.txt        # Copyright header for generated code

pro_video_player_android/
└── pigeons/
    ├── messages.dart           # Hard link → shared_pigeon_sources/messages.dart
    └── copyright_header.txt    # Hard link → shared_pigeon_sources/copyright_header.txt

pro_video_player_ios/
└── pigeons/
    ├── messages.dart           # Hard link → shared_pigeon_sources/messages.dart
    └── copyright_header.txt    # Hard link → shared_pigeon_sources/copyright_header.txt

pro_video_player_macos/
└── pigeons/
    ├── messages.dart           # Copy with platform-specific @ConfigurePigeon (NOT hard-linked)
    └── copyright_header.txt    # Hard link → shared_pigeon_sources/copyright_header.txt
```

Hard links ensure editing any copy updates all copies automatically. Run `make setup` after cloning to create hard links.

**macOS Exception:** The macOS `messages.dart` file is a copy (not hard-linked) because it needs a platform-specific `@ConfigurePigeon` annotation. The message class definitions must be kept in sync with `shared_pigeon_sources/messages.dart` manually. The verification script checks that message definitions match.

## Generated Files

Each platform package generates its own code:

**Android (pro_video_player_android):**
- `lib/src/pigeon_generated/messages.g.dart` (~75KB)
- `test/pigeon_generated/test_messages.g.dart`
- `android/src/main/kotlin/dev/pro_video_player/pro_video_player_android/PigeonMessages.kt` (~72KB)

**iOS (pro_video_player_ios):**
- `lib/src/pigeon_generated/messages.g.dart` (~75KB)
- `test/pigeon_generated/test_messages.g.dart`
- `ios/Classes/PigeonMessages.swift` (~73KB)

**macOS (pro_video_player_macos):**
- `lib/src/pigeon_generated/messages.g.dart` (~75KB)
- `test/pigeon_generated/test_messages.g.dart`
- `macos/Classes/PigeonMessages.swift` (~73KB)

## Complete API

### Message Types

**Enums (9 total):**
- `VideoSourceType` - network, file, asset
- `PlaybackStateEnum` - Player states (uninitialized, initialized, playing, paused, buffering, ended, error)
- `ControlsMode` - none, embed, fullscreen, custom
- `ScalingMode` - fit, fill, fillWidth, fillHeight
- `SubtitleRenderMode` - native, custom
- `PipActionType` - play, pause, skipForward, skipBackward, custom
- `MediaMetadataType` - audio, video
- `HlsMediaPlaylistType` - event, vod
- `SeekOrigin` - start, current, end

**Message Classes (14 total):**
- `VideoSourceMessage` - Video source with type, URL/path, headers
- `VideoPlayerOptionsMessage` - Player options (autoPlay, looping, volume, speed, brightness, pip, background, etc.)
- `PlatformCapabilitiesMessage` - Platform capability flags
- `VideoPlayerEventMessage` - Event data (state, position, duration, size, errors, tracks, etc.)
- `SubtitleTrackMessage` - Subtitle track info
- `AudioTrackMessage` - Audio track info
- `VideoQualityMessage` - Video quality info (bitrate, resolution)
- `BatteryInfoMessage` - Battery level and charging state
- `PipActionMessage` - PiP action configuration
- `MediaMetadataMessage` - Media metadata (title, artist, album, artwork)
- `VideoMetadataMessage` - Technical video metadata
- `CastDeviceMessage` - Cast device info
- `PlaylistItemMessage` - Playlist item (source + metadata)
- `ChapterMessage` - Chapter markers

**APIs:**
- `ProVideoPlayerHostApi` (@HostApi) - 50+ methods for Dart → native calls
- `ProVideoPlayerFlutterApi` (@FlutterApi) - Methods for native → Dart callbacks

### Methods in Pigeon API

**Core Playback (11 methods):**
- `create()` - Create player with source and options
- `dispose()` - Dispose player
- `play()` - Start playback
- `pause()` - Pause playback
- `stop()` - Stop playback
- `seekTo()` - Seek to position with optional origin
- `setPlaybackSpeed()` - Set playback speed
- `setVolume()` - Set volume
- `getPosition()` - Get current position
- `getDuration()` - Get video duration
- `setLooping()` - Set looping mode

**Configuration (8 methods):**
- `setScalingMode()` - Set video scaling mode
- `setControlsMode()` - Set native controls mode
- `setVerboseLogging()` - Enable/disable verbose logging
- `getPlatformCapabilities()` - Get platform capabilities
- `setSubtitleRenderMode()` - Set subtitle rendering mode
- `setPreferredAudioLanguage()` - Set preferred audio language
- `setPreferredSubtitleLanguage()` - Set preferred subtitle language
- `setAutoSelectQuality()` - Enable/disable auto quality selection

**Track Management (6 methods):**
- `getSubtitleTracks()` - Get available subtitle tracks
- `setSubtitleTrack()` - Select subtitle track
- `addExternalSubtitle()` - Add external subtitle file
- `getAudioTracks()` - Get available audio tracks
- `setAudioTrack()` - Select audio track
- `setSubtitleTextStyle()` - Customize subtitle appearance

**Quality Control (4 methods):**
- `getVideoQualities()` - Get available quality levels
- `setVideoQuality()` - Select quality level
- `getCurrentVideoQuality()` - Get current quality
- `getManifestDetails()` - Get HLS/DASH manifest info

**Picture-in-Picture (4 methods):**
- `isPipSupported()` - Check PiP support
- `enterPip()` - Enter PiP mode
- `exitPip()` - Exit PiP mode
- `setPipActions()` - Configure PiP controls

**Fullscreen (3 methods):**
- `enterFullscreen()` - Enter fullscreen
- `exitFullscreen()` - Exit fullscreen
- `setWindowFullscreen()` - Platform-specific fullscreen

**Device Controls (4 methods):**
- `getDeviceVolume()` - Get system volume
- `setDeviceVolume()` - Set system volume
- `getScreenBrightness()` - Get screen brightness
- `setScreenBrightness()` - Set screen brightness

**Battery (1 method):**
- `getBatteryInfo()` - Get battery level and charging state

**Metadata (3 methods):**
- `getVideoMetadata()` - Get technical video metadata
- `setMediaMetadata()` - Set media session metadata
- `getChapters()` - Get chapter markers

**Background Playback (2 methods):**
- `isBackgroundPlaybackSupported()` - Check background support
- `setBackgroundPlayback()` - Enable/disable background playback

**Casting (4 methods):**
- `isCastingSupported()` - Check casting support
- `getAvailableCastDevices()` - Get available cast devices
- `startCasting()` - Start casting to device
- `stopCasting()` - Stop casting

**Playlist (2 methods):**
- `loadPlaylist()` - Load playlist from URL
- `setPlaylistItems()` - Set playlist items programmatically

## Editing Pigeon Definitions

**IMPORTANT:** Always edit the master copy in `shared_pigeon_sources/messages.dart`. Changes automatically propagate to all platform packages via hard links.

### Adding New Methods

1. Edit `shared_pigeon_sources/messages.dart`
2. Add message classes if needed (data structures)
3. Add method to `ProVideoPlayerHostApi` with `@async` annotation
4. Regenerate code for each platform (see below)
5. Implement native handlers in Swift/Kotlin
6. Export new types from platform package main file if needed

Example:
```dart
// In shared_pigeon_sources/messages.dart

// Add message class
class NewFeatureMessage {
  final String parameter;
  final int value;
}

// Add to ProVideoPlayerHostApi
@HostApi()
abstract class ProVideoPlayerHostApi {
  // ... existing methods ...

  @async
  void newFeature(int playerId, NewFeatureMessage config);
}
```

## Regenerating Pigeon Code

After editing `shared_pigeon_sources/messages.dart`, regenerate code for all platforms:

```bash
# Recommended: Regenerate all platforms at once
cd /Users/vitor/resilio/Dev/goodinside/git/pro_video_player
make pigeon-generate

# Or manually for specific platforms:
# Android
cd pro_video_player_android
fvm dart run pigeon --input pigeons/messages.dart

# iOS
cd ../pro_video_player_ios
fvm dart run pigeon --input pigeons/messages.dart

# macOS
cd ../pro_video_player_macos
fvm dart run pigeon --input pigeons/messages.dart
```

Each package has its own `@ConfigurePigeon` settings:
- Android: Generates Dart + Kotlin (hard-linked messages.dart with full config)
- iOS: Generates Dart + Swift (hard-linked messages.dart with full config)
- macOS: Generates Swift only (separate messages.dart with `oneLanguage: true`)

**Note:** macOS `pigeons/messages.dart` is not hard-linked. It contains the same message class definitions as the shared source, but uses a simplified `@ConfigurePigeon` annotation with only `swiftOut` and `oneLanguage: true`. This is necessary because macOS needs a different output path than iOS. The verification script (`verify-shared-links.sh`) compares only the message definitions (not the configuration) for macOS.

## Native Implementation Status

### iOS/macOS (Swift) ✅

Complete implementation in `shared_apple_sources/PigeonHostApiHandler.swift`:
- Implements all `ProVideoPlayerHostApi` protocol methods
- Bridges Pigeon type-safe API to existing `SharedPluginBase`
- Registered in both iOS and macOS plugins
- All methods functional and tested

### Android (Kotlin) ✅

Complete implementation in `PigeonHostApiHandler.kt`:
- Implements all `ProVideoPlayerHostApi` interface methods
- Bridges Pigeon type-safe API to existing ExoPlayer `VideoPlayer` implementation
- Converts between Pigeon messages and Map-based legacy API
- Registered in `ProVideoPlayerPlugin.kt`
- All methods functional and compilation verified

**Implementation Details:**
- Created `PigeonHostApiHandler.kt` (838 lines)
- Added helper methods to `ProVideoPlayerPlugin`:
  - `getActivity()` - Access Android activity context
  - `createPlayer()` - Create player instance with source and options
  - `removePlayer()` - Remove player from registry
  - `setVerboseLogging()` - Configure logging level
- Conversion utilities for 20+ message types to/from Map format
- Handles asset path resolution for bundled video files
- Type-safe error handling with `FlutterError` integration

## Type Safety Benefits

```dart
// Before (Manual MethodChannel) - Runtime errors possible
await _methodChannel.invokeMethod('create', {
  'source': {'type': 'network', 'url': url}, // Typos, type mismatches
  'options': {'autoPlay': true, 'voume': 1.0}, // Typo in 'volume'
});

// After (Pigeon) - Compile-time safety
final source = VideoSourceMessage(type: VideoSourceType.network, url: url);
final options = VideoPlayerOptionsMessage(autoPlay: true, volume: 1.0);
final playerId = await _hostApi.create(source, options);
```

## Setup and Verification

### Initial Setup

```bash
# After cloning the repository
cd /Users/vitor/resilio/Dev/goodinside/git/pro_video_player
make setup
```

This creates hard links from `shared_pigeon_sources/` to all platform packages.

### Verify Hard Links

```bash
# Check hard links are intact
make quick-check
```

The `verify-shared-links.sh` script runs automatically and checks:
- Swift files: `shared_apple_sources/` → iOS/macOS
- Pigeon files: `shared_pigeon_sources/` → Android/iOS/macOS

If hard links break (e.g., after git operations on some filesystems):
```bash
make setup-shared-links
```

### Verify Hard Link Manually

```bash
# Check inode numbers (should match for hard links)
ls -li shared_pigeon_sources/messages.dart
ls -li pro_video_player_android/pigeons/messages.dart
ls -li pro_video_player_ios/pigeons/messages.dart
ls -li pro_video_player_macos/pigeons/messages.dart
```

All four files should have the same inode number (first column).

## Migration Strategy

### Completed Phases

1. ✅ **Phase 1:** Per-platform architecture design and implementation
2. ✅ **Phase 2:** Complete API definition with 50+ methods
3. ✅ **Phase 3:** Hard link infrastructure and automation
4. ✅ **Phase 4:** iOS/macOS native handler implementation
5. ✅ **Phase 5:** Generated code exports from platform packages
6. ✅ **Phase 6:** Android native handler implementation

### Next Phases

7. ⏳ **Phase 7:** Update main package to use Pigeon-based platform implementations
8. ⏳ **Phase 8:** Deprecate and remove old MethodChannelBase
9. ⏳ **Phase 9:** Event streaming migration to FlutterApi callbacks

## Performance

Pigeon generates efficient binary serialization code:
- Generation time: ~100ms for 50+ methods per platform
- Runtime overhead: Minimal (similar to manual MethodChannel)
- Zero runtime dependencies (code generator is dev-only)
- Compile-time type checking prevents runtime errors
- Binary serialization more efficient than JSON

## Testing

```bash
# Run all tests
cd /Users/vitor/resilio/Dev/goodinside/git/pro_video_player
make test

# Run platform-specific tests
cd pro_video_player_platform_interface
fvm flutter test test/pigeon_messages_test.dart

# Verify compilation across all platforms
make quick-check
```

## Troubleshooting

### Hard Links Not Working

**Problem:** Files appear as copies instead of hard links.

**Solution:**
```bash
cd /Users/vitor/resilio/Dev/goodinside/git/pro_video_player
make setup-shared-links
```

### Pigeon Version Mismatch

**Problem:** Different Pigeon versions across platform packages.

**Solution:** Per-platform architecture eliminates this issue. Each package has its own Pigeon dependency and generates code locally. Packages can have different Pigeon versions without conflicts.

### Generated Code Out of Sync

**Problem:** Generated files don't match API definition.

**Solution:**
```bash
# Regenerate for specific platform
cd pro_video_player_[platform]
fvm dart run pigeon --input pigeons/messages.dart

# Or regenerate all
cd /Users/vitor/resilio/Dev/goodinside/git/pro_video_player
# Run pigeon for each platform
```

### Code Duplication Detection

**Problem:** jscpd reports high duplication due to Pigeon files.

**Solution:** Already configured. Pigeon files are excluded in `.jscpd.json` and `.jscpdignore`:
```json
"ignore": [
  "**/pigeon_generated/**",
  "**/pigeons/**"
]
```

## References

- [PIGEON_ARCHITECTURE.md](PIGEON_ARCHITECTURE.md) - Detailed architectural decision record
- [Pigeon Package](https://pub.dev/packages/pigeon) - Official Pigeon documentation
- [Pigeon Inter-version Compatibility](https://pub.dev/packages/pigeon#inter-version-compatibility) - Why per-platform approach is required
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Flutter video_player](https://github.com/flutter/packages/tree/main/packages/video_player) - Reference implementation
