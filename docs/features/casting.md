# Casting

This guide covers casting functionality for streaming video to external devices.

## Platform Support

| Platform | Technology | Setup Required |
|----------|------------|----------------|
| iOS | AirPlay | None (built-in) |
| macOS | AirPlay | None (built-in) |
| Android | Chromecast | Yes (see below) |
| Web | Remote Playback API | None (browser-dependent) |
| Windows | Not supported | - |
| Linux | Not supported | - |

## Android Chromecast Setup

Android requires additional configuration for Chromecast support. Follow all steps below.

### 1. Use FlutterFragmentActivity

Your `MainActivity` **must** extend `FlutterFragmentActivity` (not `FlutterActivity`). This is required for the MediaRouteButton dialog to work.

**File:** `android/app/src/main/kotlin/.../MainActivity.kt`

```kotlin
package com.example.yourapp

import io.flutter.embedding.android.FlutterFragmentActivity

// IMPORTANT: Must extend FlutterFragmentActivity for Chromecast support
class MainActivity : FlutterFragmentActivity()
```

### 2. Use AppCompat Themes with Opaque Background

The MediaRouter library requires AppCompat themes with an opaque (non-transparent) `colorBackground`. Flutter's default themes often have transparent backgrounds which cause crashes.

**File:** `android/app/src/main/res/values/styles.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- IMPORTANT: Use AppCompat theme with opaque colorBackground for Chromecast -->
    <style name="LaunchTheme" parent="Theme.AppCompat.Light.NoActionBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:colorBackground">@android:color/white</item>
    </style>

    <style name="NormalTheme" parent="Theme.AppCompat.Light.NoActionBar">
        <item name="android:windowBackground">?android:colorBackground</item>
        <item name="android:colorBackground">@android:color/white</item>
    </style>
</resources>
```

**File:** `android/app/src/main/res/values-night/styles.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Dark mode: Use AppCompat dark theme with opaque colorBackground -->
    <style name="LaunchTheme" parent="Theme.AppCompat.NoActionBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:colorBackground">@android:color/black</item>
    </style>

    <style name="NormalTheme" parent="Theme.AppCompat.NoActionBar">
        <item name="android:windowBackground">?android:colorBackground</item>
        <item name="android:colorBackground">@android:color/black</item>
    </style>
</resources>
```

### 3. Custom Receiver App ID (Optional)

By default, the plugin uses Google's Default Media Receiver (`CC1AD845`). To use a custom Cast receiver app:

**File:** `android/app/src/main/res/values/strings.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Custom Cast receiver app ID (optional) -->
    <string name="cast_receiver_app_id">YOUR_RECEIVER_APP_ID</string>
</resources>
```

## Usage

### CastButton Widget

The simplest way to add casting is with the `CastButton` widget:

```dart
import 'package:pro_video_player/pro_video_player.dart';

// In your widget tree
CastButton(
  tintColor: Colors.white,
  activeTintColor: Colors.blue,
  size: 24.0,
  alwaysVisible: true,
  onCastStateChanged: (state) {
    print('Cast state: $state'); // noDevices, notConnected, connecting, connected
  },
)
```

### Programmatic Control

You can also control casting programmatically:

```dart
final controller = ProVideoPlayerController();

// Check if casting is supported
final supported = await controller.isCastingSupported();

// Start casting (shows device picker)
await controller.startCasting();

// Stop casting
await controller.stopCasting();

// Check current state
final isCasting = controller.isCasting;
final castState = controller.castState;
final device = controller.currentCastDevice;
```

### Casting Behavior

When casting is active:
- The local video is hidden (`View.GONE`)
- Play/pause/seek controls are routed to the cast device
- When casting ends, the video resumes locally at the cast position

### VideoPlayerControls Integration

The built-in controls automatically show a cast button when casting is supported:

```dart
VideoPlayerControls(
  controller: controller,
  // Cast button is shown automatically when available
)
```

During casting, controls that don't apply are automatically hidden:
- Speed control (not supported on most cast devices)
- Scaling mode (doesn't apply to cast)
- PiP (doesn't make sense while casting)
- Fullscreen (doesn't apply to cast)

## Troubleshooting

### "background can not be translucent: #0"

**Cause:** Your app theme has a transparent `colorBackground`.

**Solution:** Use AppCompat themes with opaque `colorBackground` as shown in step 2 above.

### "The activity must be a subclass of FragmentActivity"

**Cause:** Your `MainActivity` extends `FlutterActivity` instead of `FlutterFragmentActivity`.

**Solution:** Change to extend `FlutterFragmentActivity` as shown in step 1 above.

### Cast button appears but no devices are found

**Possible causes:**
1. VPN is active (VPNs block local network discovery)
2. Device and Chromecast are on different networks
3. Chromecast is not in discoverable mode

**Solutions:**
- Disable VPN when testing casting
- Ensure both devices are on the same WiFi network
- Check Chromecast is powered on and connected

### Cast button icon is black/invisible

**Cause:** Theme's `colorControlNormal` doesn't match your UI background.

**Solution:** The plugin automatically uses a dark theme with white icons. If you need different colors, use the `tintColor` parameter on `CastButton`.

## iOS/macOS (AirPlay)

AirPlay works out of the box with no additional setup. The `CastButton` widget automatically shows the native `AVRoutePickerView`.

## Web (Remote Playback API)

Web casting depends on browser support for the Remote Playback API. Currently supported in Chromium-based browsers with Cast extension.
