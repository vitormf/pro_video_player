# Troubleshooting

Common issues and solutions for pro_video_player.

## General Issues

### Video Won't Play

1. **Check URL accessibility** - Try opening the URL in a browser
2. **Verify format support** - Ensure video codec is supported
3. **Check network** - Ensure device has internet connectivity
4. **Listen for errors** - Check `onError` stream for details

```dart
controller.onError.listen((error) {
  print('Playback error: ${error.message}');
  print('Error code: ${error.code}');
});
```

### Video Loads But No Audio

1. **Check device volume** - Ensure not muted
2. **Check silent mode** - iOS silent switch affects playback
3. **Verify audio track** - Some videos have no audio

### Playback Stuttering

1. **Check network speed** - May need faster connection for HD
2. **Use adaptive streaming** - HLS/DASH adapts to bandwidth
3. **Check device resources** - Close other apps

---

## Android

### Build Errors

**Error: `minSdkVersion` too low**

```
Execution failed for task ':app:processDebugMainManifest'.
Manifest merger failed: uses-sdk:minSdkVersion 16 cannot be smaller than version 21
```

**Solution:** Update `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

**Error: Missing namespace**

```
Namespace not specified
```

**Solution:** Add namespace to `android/app/build.gradle`:

```gradle
android {
    namespace "com.yourcompany.yourapp"
}
```

### PiP Not Working

1. **Check Android version** - Requires Android 8.0+
2. **Verify manifest** - `android:supportsPictureInPicture="true"`
3. **Check system settings** - PiP may be disabled by user
4. **Verify activity is playing** - Video must be playing to enter PiP

### Background Playback Stops

1. **Check permissions** - `FOREGROUND_SERVICE` permission required
2. **Battery optimization** - App may be killed by battery saver
3. **Check notification** - Foreground service requires notification

---

## iOS

### Build Errors

**Error: Deployment target too low**

```
The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 9.0
```

**Solution:** Update `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

Then run:

```bash
cd ios && pod install
```

### PiP Not Working

1. **Check iOS version** - Requires iOS 14.0+
2. **Verify Info.plist** - `UIBackgroundModes` must include `audio`
3. **Check entitlements** - PiP capability must be enabled
4. **Verify playback state** - Video must be playing to enter PiP

### Background Audio Stops

1. **Check Info.plist** - `UIBackgroundModes` must include `audio`
2. **Check silent switch** - Hardware mute switch affects playback
3. **Audio session** - Another app may have taken audio focus

---

## macOS

### Sandbox Issues

**Error:** Network requests blocked

**Solution:** Ensure network entitlements in `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

### PiP Window Not Appearing

1. **Check macOS version** - Requires macOS 10.12+
2. **Verify video is playing** - Must be playing to enter PiP
3. **Check window state** - App must be active

---

## Web

### CORS Errors

**Error:** `Access to video at 'https://...' from origin 'http://...' has been blocked by CORS policy`

**Solution:** The video server must include CORS headers:

```
Access-Control-Allow-Origin: *
```

Or configure your server to allow your domain.

### Autoplay Blocked

**Error:** Video won't auto-play

**Solution:** Browsers block autoplay with sound. Either:

1. Start muted: `options: VideoPlayerOptions(volume: 0, autoPlay: true)`
2. Require user interaction before playing

### Fullscreen Not Working

1. **User gesture required** - Fullscreen must be triggered by click/tap
2. **Check iframe permissions** - If embedded, needs `allowfullscreen`

---

## Error Codes

| Code | Description | Common Cause |
|------|-------------|--------------|
| `source_not_found` | Video URL not accessible | Invalid URL, network error |
| `format_not_supported` | Codec not supported | Unsupported video format |
| `drm_not_supported` | DRM content cannot play | Protected content |
| `network_error` | Network request failed | No internet, timeout |
| `playback_error` | General playback failure | Corrupted file, decoder error |

---

## Getting Help

If your issue isn't covered here:

1. **Check the example app** - See working implementations
2. **Enable verbose logging** - May reveal more details
3. **File an issue** - Include platform, OS version, and error details

```dart
// Enable verbose logging
ProVideoPlayer.setLogLevel(LogLevel.verbose);
```
