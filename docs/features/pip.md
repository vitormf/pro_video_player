# Picture-in-Picture (PiP)

Picture-in-Picture allows video playback to continue in a floating window while the user navigates to other apps.

## Platform Support

| Platform | Supported | Minimum Version |
|----------|-----------|-----------------|
| iOS | Yes | iOS 14.0 |
| Android | Yes | Android 8.0 (API 26) |
| macOS | Yes | macOS 10.12 |
| Web | Yes | Browser with PiP API |
| Windows | No | - |
| Linux | No | - |

## Setup

### iOS

See [iOS Setup Guide](../setup/ios.md#picture-in-picture)

### Android

See [Android Setup Guide](../setup/android.md#picture-in-picture)

## Usage

### Enable PiP Support

```dart
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    allowPip: true,  // Enable PiP (default: true)
  ),
);
```

### Enter PiP Manually

```dart
// Check if PiP is supported on this device
if (await controller.isPipSupported()) {
  await controller.enterPip();
}
```

### Auto-Enter PiP on Background

```dart
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    allowPip: true,
    autoEnterPipOnBackground: true,  // Auto-enter when app backgrounds
  ),
);
```

### Listen to PiP State Changes

```dart
controller.onPipStateChanged.listen((isPip) {
  if (isPip) {
    // Hide UI elements not needed in PiP
  } else {
    // Restore full UI
  }
});
```

### Exit PiP

```dart
await controller.exitPip();
```

## Disabling PiP

```dart
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    allowPip: false,  // Disable PiP entirely
  ),
);

// Calling enterPip() will return false and do nothing
final entered = await controller.enterPip();  // false
```

## Best Practices

1. **Check support first** - Always check `isPipSupported()` before showing PiP UI
2. **Handle state changes** - Update your UI when PiP state changes
3. **Respect user preference** - Provide a setting to disable auto-PiP
4. **Test on real devices** - PiP behavior varies between devices

## Troubleshooting

### PiP Not Working on iOS

- Verify `UIBackgroundModes` includes `audio` in Info.plist
- Check minimum deployment target is iOS 14.0+
- Ensure video is playing when entering PiP

### PiP Not Working on Android

- Verify `android:supportsPictureInPicture="true"` in manifest
- Check device is Android 8.0+
- Some devices have PiP disabled in system settings

See [Troubleshooting Guide](../troubleshooting.md) for more help.
