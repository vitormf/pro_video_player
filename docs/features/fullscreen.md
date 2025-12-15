# Fullscreen Mode

Fullscreen mode expands the video player to fill the entire screen, hiding system UI and other app content.

## Platform Support

| Platform | Supported | Implementation |
|----------|-----------|----------------|
| iOS | Yes | Native fullscreen presentation |
| Android | Yes | System UI hiding + immersive mode |
| macOS | Yes | Native fullscreen window |
| Web | Yes | Fullscreen API |
| Windows | Planned | - |
| Linux | Planned | - |

## Usage

### Enter Fullscreen

```dart
await controller.enterFullscreen();
```

### Exit Fullscreen

```dart
await controller.exitFullscreen();
```

### Toggle Fullscreen

```dart
if (controller.isFullscreen) {
  await controller.exitFullscreen();
} else {
  await controller.enterFullscreen();
}
```

### Check Fullscreen State

```dart
final isFullscreen = controller.isFullscreen;
```

### Listen to Fullscreen Changes

```dart
controller.onFullscreenChanged.listen((isFullscreen) {
  if (isFullscreen) {
    // Hide app UI elements
  } else {
    // Restore app UI
  }
});
```

## Behavior by Platform

### iOS

- Uses `AVPlayerViewController` presentation
- Supports landscape orientation automatically
- System controls shown in fullscreen
- Swipe down to exit

### Android

- Hides status bar and navigation bar
- Uses immersive sticky mode
- Supports landscape orientation
- Back button or gesture to exit

### macOS

- Native macOS fullscreen window
- Green traffic light button
- Esc key or gesture to exit

### Web

- Uses browser Fullscreen API
- Esc key to exit
- May require user gesture to enter

## Orientation Handling

Fullscreen mode typically works best in landscape orientation. The plugin does not force orientation changes - your app should handle this:

```dart
import 'package:flutter/services.dart';

controller.onFullscreenChanged.listen((isFullscreen) async {
  if (isFullscreen) {
    // Allow landscape only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } else {
    // Restore all orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
});
```

## Best Practices

1. **Handle orientation** - Rotate to landscape in fullscreen
2. **Hide app UI** - Remove overlapping widgets
3. **Provide exit method** - Ensure users can exit fullscreen
4. **Test gestures** - Verify swipe/back gestures work

## Troubleshooting

### Fullscreen Not Working on Web

- Ensure fullscreen is triggered by user gesture (click/tap)
- Check browser permissions and settings
- Some browsers block fullscreen in iframes

### Orientation Not Changing

- The plugin doesn't force orientation - handle it in your app
- Check device orientation lock settings

See [Troubleshooting Guide](../troubleshooting.md) for more help.
