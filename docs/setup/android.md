# Android Setup

This guide covers Android-specific configuration required for pro_video_player features.

## Basic Setup

No additional configuration required for basic video playback.

## Feature-Specific Configuration

### Background Playback

To enable background audio playback, add the following to your `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Required for background playback -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

    <application ...>
        <!-- Foreground service for background playback -->
        <service
            android:name="com.example.pro_video_player_android.MediaPlaybackService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="false" />
    </application>
</manifest>
```

### Picture-in-Picture

PiP requires Android 8.0 (API 26) or higher. Add to your `AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:supportsPictureInPicture="true"
    android:configChanges="screenSize|smallestScreenSize|screenLayout|orientation" />
```

### Chromecast

Chromecast support requires additional setup:

1. **Use FlutterFragmentActivity** - Your `MainActivity` must extend `FlutterFragmentActivity`:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

2. **Use AppCompat themes with opaque background** - Update your `styles.xml`:

```xml
<!-- values/styles.xml -->
<style name="LaunchTheme" parent="Theme.AppCompat.Light.NoActionBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
    <item name="android:colorBackground">@android:color/white</item>
</style>

<style name="NormalTheme" parent="Theme.AppCompat.Light.NoActionBar">
    <item name="android:windowBackground">?android:colorBackground</item>
    <item name="android:colorBackground">@android:color/white</item>
</style>
```

```xml
<!-- values-night/styles.xml -->
<style name="LaunchTheme" parent="Theme.AppCompat.NoActionBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
    <item name="android:colorBackground">@android:color/black</item>
</style>

<style name="NormalTheme" parent="Theme.AppCompat.NoActionBar">
    <item name="android:windowBackground">?android:colorBackground</item>
    <item name="android:colorBackground">@android:color/black</item>
</style>
```

See [Casting Feature Guide](../features/casting.md) for full documentation including custom receiver apps and troubleshooting.

## Gradle Configuration

### Minimum SDK Version

Ensure your `android/app/build.gradle` has:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Minimum for ExoPlayer
    }
}
```

### ProGuard / R8

If using code shrinking, the plugin includes ProGuard rules automatically. No additional configuration needed.

## Troubleshooting

See [Troubleshooting Guide](../troubleshooting.md#android) for common Android issues.
