# Background Playback

Background playback allows audio to continue when the app is not in the foreground.

## Platform Support

| Platform | Supported | Notes |
|----------|-----------|-------|
| iOS | Yes | Requires background mode capability |
| Android | Yes | Uses foreground service with notification |
| macOS | Yes | Works by default |
| Web | No | Browser limitation |
| Windows | Planned | Native code needed |
| Linux | Planned | Native code needed |

## Setup

### iOS

See [iOS Setup Guide](../setup/ios.md#background-playback)

### Android

See [Android Setup Guide](../setup/android.md#background-playback)

## Usage

### Enable Background Playback

```dart
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    allowBackgroundPlayback: true,  // Default: false
  ),
);
```

### Mix with Other Audio (iOS)

By default, starting playback will pause other audio apps (Music, Podcasts, etc.). To mix instead:

```dart
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    allowBackgroundPlayback: true,
    mixWithOthers: true,  // Mix audio instead of interrupting
  ),
);
```

## Android Notification (Foreground Service)

On Android, background playback requires a foreground service notification. This is handled automatically by the plugin.

### Default Notification

The plugin provides a default notification with:
- Play/Pause button
- Video title (from metadata or filename)
- App icon

### Custom Notification (Coming Soon)

```dart
// Future API for customizing the notification
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    allowBackgroundPlayback: true,
    // androidNotificationOptions: AndroidNotificationOptions(
    //   channelId: 'video_playback',
    //   channelName: 'Video Playback',
    //   icon: 'ic_notification',
    // ),
  ),
);
```

## Behavior When Backgrounded

| Scenario | allowBackgroundPlayback: false | allowBackgroundPlayback: true |
|----------|-------------------------------|------------------------------|
| App goes to background | Playback pauses | Audio continues |
| Screen locks | Playback pauses | Audio continues |
| Another app plays audio | Playback pauses | Depends on `mixWithOthers` |

## Best Practices

1. **Opt-in only** - Background playback is disabled by default for good reason
2. **Respect battery** - Background playback uses more battery
3. **Handle interruptions** - Phone calls, alarms, etc. will interrupt playback
4. **Test thoroughly** - Background behavior varies by platform and OS version

## Troubleshooting

### Audio Stops When App Backgrounds (iOS)

- Verify `audio` is in `UIBackgroundModes` in Info.plist
- Check that `allowBackgroundPlayback: true` is set
- Ensure audio session category is correct (handled by plugin)

### No Notification Appears (Android)

- Verify foreground service permission in AndroidManifest.xml
- Check Android 13+ notification permission is granted
- Ensure `allowBackgroundPlayback: true` is set

See [Troubleshooting Guide](../troubleshooting.md) for more help.
