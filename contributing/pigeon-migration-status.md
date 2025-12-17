# Pigeon Migration Status

This document tracks the migration from traditional Flutter MethodChannel to type-safe Pigeon APIs.

## Migration Status: ✅ COMPLETE

All platform method calls now use Pigeon-generated type-safe APIs. The migration is complete as of the Pigeon migration commit.

## Architecture Overview

### Current Call Flow (All Platforms)

```
Dart Layer:
  ProVideoPlayerController.isPipSupported()
    ↓
  PipManager.isPipSupported()
    ↓
  ProVideoPlayerPlatform.isPipSupported()
    ↓
  PigeonMethodChannelBase.isPipSupported() (via ProVideoPlayerMacOS/iOS/Android)
    ↓
  ProVideoPlayerHostApi.isPipSupported() [Pigeon-generated]
    ↓
Native Layer (Swift/Kotlin):
  PigeonHostApiHandler.isPipSupported()
    ↓
  ProVideoPlayerPlugin.isPipSupported() or platformBehavior.isPipSupported()
```

### What Changed

**Before Migration:**
- Dart used `MethodChannel` with string-based method names
- Native platforms received `FlutterMethodCall` with dynamic arguments
- Manual serialization/deserialization of all data
- No compile-time type safety
- Runtime errors for mismatched types

**After Migration:**
- Dart uses `ProVideoPlayerHostApi` (Pigeon-generated class)
- Native platforms implement `ProVideoPlayerHostApi` protocol/interface
- Automatic serialization/deserialization via Pigeon codec
- Full compile-time type safety
- Immediate feedback on API mismatches

## What Remains from Old MethodChannel Code

### 1. Stub `onMethodCall()` / `handle()` Methods

**Location:**
- `pro_video_player_ios/ios/Classes/PlatformVideoPlayerPlugin.swift:53`
- `pro_video_player_macos/macos/Classes/PlatformVideoPlayerPlugin.swift:53`
- `pro_video_player_android/.../ProVideoPlayerPlugin.kt:95`

**Why It Remains:**
- Tests may still reference the old interface
- Plugin registration requires implementing `FlutterPlugin` protocol/interface
- `MethodCallHandler` interface kept for backward compatibility

**Implementation:**
```swift
// iOS/macOS
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // No-op: All calls should go through Pigeon API now
    result(FlutterMethodNotImplemented)
}
```

```kotlin
// Android
override fun onMethodCall(call: MethodCall, result: Result) {
    // No-op: All calls should go through Pigeon API now
    result.notImplemented()
}
```

**Status:** ✅ Harmless - Returns "not implemented" immediately, no actual logic

**Can Be Removed?** In future, once tests are updated to not reference old interfaces

---

### 2. `SharedPluginBase` Class

**Location:** `shared_apple_sources/SharedPluginBase.swift`

**Why It Remains:**
- Contains shared video player management logic (creation, disposal, player lookup)
- Event stream handling and EventChannel setup
- Battery monitoring shared logic
- Platform view factories

**Current Role:**
- Player lifecycle management
- Event channel coordination
- Shared utilities between iOS/macOS

**Contains Old MethodChannel Code?** Yes, but it's NOT in the call path:
- Line 158: `case "isPipSupported": handleIsPipSupported(result: result)`
- This code path is NEVER called because no MethodChannel is registered to route to it
- The `handle(_ call:, result:)` method exists but is never invoked

**Status:** ⚠️ Contains dead code that could be cleaned up

**Can Be Removed?** Yes, the old `handle()` method and all `case` statements could be removed in a future cleanup PR

---

### 3. Platform View MethodChannels

**Location:**
- `shared_apple_sources/AirPlayRoutePickerView.swift:57` (iOS/macOS)
- `pro_video_player_android/.../MediaRouteButtonView.kt:66` (Android)

**Why It Remains:**
- Platform views (AirPlay picker, Chromecast button) use MethodChannel for **view-specific communication**
- This is separate from the plugin API and is a normal Flutter pattern
- Each platform view instance gets its own channel for UI updates

**Example:**
```swift
// AirPlay route picker view - each instance has its own channel
self.channel = FlutterMethodChannel(
    name: "dev.pro_video_player/airplay_picker_\(viewId)",
    binaryMessenger: messenger
)
```

**Status:** ✅ Correct usage - Not part of plugin API, used for platform view communication

**Can Be Removed?** No - This is the standard way to communicate with platform views

---

### 4. EventChannels

**Location:**
- Battery updates: `dev.pro_video_player.android/batteryUpdates`
- Player events: `dev.pro_video_player.{platform}/events/{playerId}`

**Why It Remains:**
- EventChannels are for **streaming data** from native to Dart
- Pigeon currently focuses on request/response APIs, not streaming
- EventChannels are still the recommended approach for streams

**Status:** ✅ Correct usage - EventChannels are separate from MethodChannels

**Can Be Removed?** No - EventChannels serve a different purpose than MethodChannels

---

### 5. Comments Mentioning "Migration"

**Status:** ✅ Cleaned up - All outdated migration comments have been updated

---

## What Was Fully Removed

### iOS/macOS
- ❌ Old `FlutterMethodChannel` registration in `register(with:)` method
- ❌ `registrar.addMethodCallDelegate(instance, channel: channel)`
- ❌ All routing through old MethodChannel to `SharedPluginBase.handle()`

### Android
- ❌ Old `MethodChannel` variable declaration (`private lateinit var channel: MethodChannel`)
- ❌ `MethodChannel` initialization in `onAttachedToEngine`
- ❌ `channel.setMethodCallHandler(this)` registration
- ❌ 50+ method handlers in `onMethodCall()` implementation
- ❌ `channel.setMethodCallHandler(null)` cleanup in `onDetachedFromEngine`

### All Platforms
- ❌ Outdated comments about "coexist during migration"
- ❌ "For backward compatibility during migration" notes

---

## Future Cleanup Opportunities

### Low Priority (Nice to Have)

1. **Remove `SharedPluginBase.handle()` method** (iOS/macOS)
   - File: `shared_apple_sources/SharedPluginBase.swift`
   - Lines: ~140-220 (entire switch statement)
   - Impact: None - this code is never called
   - Benefit: Reduced confusion, smaller codebase

2. **Remove all `handle*` methods in SharedPluginBase** (iOS/macOS)
   - Methods like `handleIsPipSupported(result:)`, `handleCreate(call:result:)`, etc.
   - Impact: None - only called from dead code
   - Benefit: Significant code reduction (~500-1000 lines)

3. **Remove `MethodCallHandler` protocol conformance** (All platforms)
   - Can remove once tests are updated
   - Requires test refactoring first
   - Benefit: Cleaner architecture

### Not Recommended for Removal

1. **Platform view MethodChannels** - Correct usage for platform views
2. **EventChannels** - Still the right tool for streaming data
3. **Battery/player event channels** - No Pigeon alternative for streams

---

## Verification

To verify no old MethodChannel code is in the call path:

```bash
# Search for old channel registrations (should find none in main plugin files)
grep -r "FlutterMethodChannel.*pro_video_player.*methods" pro_video_player_*/
grep -r "MethodChannel.*pro_video_player.*methods" pro_video_player_*/

# Search for method handler registrations (should find none)
grep -r "addMethodCallDelegate" pro_video_player_ios/ pro_video_player_macos/
grep -r "setMethodCallHandler(this)" pro_video_player_android/

# Verify Pigeon setup (should find these)
grep -r "ProVideoPlayerHostApi.setUp" pro_video_player_*/
grep -r "ProVideoPlayerHostApiSetup.setUp" pro_video_player_*/
```

Expected results:
- ❌ No old MethodChannel registrations for plugin API
- ❌ No method handler registrations
- ✅ Pigeon API setup in all platforms
- ✅ Platform view channels (AirPlay, Cast button) - these are correct

---

## Testing the Migration

All platform methods should work through Pigeon:

```dart
// This now uses Pigeon under the hood
final supported = await controller.isPipSupported();
await controller.play();
await controller.seekTo(Duration(seconds: 30));
```

Check logs with verbose logging enabled:
```
[Plugin] isPipSupported returning: true                    // Native side
[PigeonHandler] Pigeon isPipSupported called, returning: true  // Pigeon handler
[PigeonMethodChannelBase] isPipSupported returned: true    // Dart side
```

If you see "Old MethodChannel called" in logs, something is still using the old path.

---

## Related Documentation

- `contributing/pigeon-guide.md` - How to modify Pigeon definitions and regenerate code
- `CLAUDE.md` - Core development guidelines
- `contributing/architecture.md` - Overall architecture patterns
