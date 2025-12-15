# Subtitles & Closed Captions

Pro Video Player supports multiple subtitle formats and both embedded and external subtitle tracks.

## Supported Formats

**Current format support varies by platform** due to native player limitations:

| Format | Extension | iOS/macOS | Android | Web |
|--------|-----------|-----------|---------|-----|
| WebVTT | `.vtt` | ✅ Full | ✅ Full | ✅ Full |
| SubRip | `.srt` | ⚠️ Limited* | ✅ Full | ⚠️ Chrome/Firefox only |
| TTML | `.ttml`, `.xml` | ⚠️ Limited* | ✅ Full | ⚠️ Limited |
| SSA/ASS | `.ssa`, `.ass` | ❌ Not supported | ✅ Full | ❌ Not supported |
| CEA-608/708 | Embedded | ✅ Full | ✅ Full | ⚠️ If embedded in stream |
| Embedded (MP4/MKV) | Container | ✅ Full | ✅ Full | ✅ Full |

**\*Note:** Platform-specific subtitle format parsing is planned (medium priority) to provide consistent cross-platform support for all formats. This will use Dart-side parsing and conversion to WebVTT.

**Recommendation:** For maximum compatibility across all platforms, use **WebVTT** format for external subtitles.

## Platform Support

| Platform | External Subtitles | Embedded Subtitles | Notes |
|----------|-------------------|-------------------|-------|
| iOS | Yes | Yes | WebVTT recommended, limited SRT/TTML support |
| Android | Yes | Yes | Full format support via ExoPlayer |
| macOS | Yes | Yes | WebVTT recommended, limited SRT/TTML support |
| Web | Yes | Browser-dependent | WebVTT recommended |
| Windows | Planned | Planned | Via libmpv (all formats) |
| Linux | Planned | Planned | Via libmpv (all formats) |

## Usage

### Enable/Disable Subtitles

```dart
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    subtitlesEnabled: true,  // Default: true
  ),
);
```

### Show Subtitles by Default

```dart
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    subtitlesEnabled: true,
    showSubtitlesByDefault: true,  // Auto-show when available
  ),
);
```

### Set Preferred Language

```dart
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    subtitlesEnabled: true,
    showSubtitlesByDefault: true,
    preferredSubtitleLanguage: 'en',  // ISO 639-1 code
  ),
);
```

### Subtitle Rendering Modes

The library supports two rendering modes for subtitles:

- **Native Rendering** - Platform's native subtitle renderer (default)
- **Flutter Rendering** - Custom Flutter overlay with configurable styling

#### Native Rendering (Default)

```dart
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    subtitlesEnabled: true,
    subtitleRenderMode: SubtitleRenderMode.native,  // Default
  ),
);
```

Benefits:
- Platform-native styling and appearance
- Respects system accessibility settings
- Minimal overhead

#### Flutter Rendering

```dart
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    subtitlesEnabled: true,
    subtitleRenderMode: SubtitleRenderMode.flutter,
  ),
);
```

Benefits:
- **Works with all controls modes** - Subtitles display with native controls, Flutter controls, no controls, or custom UI
- **Customizable styling** - Configure font, size, color, background, position via `SubtitleStyle`
- **Consistent appearance** - Same look across all platforms
- **Always overlays** - Subtitles appear on top of native controls

#### Runtime Mode Switching

You can change the rendering mode at any time during playback:

```dart
// Switch to Flutter rendering for custom styling
await controller.setSubtitleRenderMode(SubtitleRenderMode.flutter);

// Switch back to native rendering
await controller.setSubtitleRenderMode(SubtitleRenderMode.native);

// Use auto mode (resolves to native)
await controller.setSubtitleRenderMode(SubtitleRenderMode.auto);
```

#### Custom Styling (Flutter Rendering Only)

When using `SubtitleRenderMode.flutter`, you can customize the subtitle appearance:

```dart
ProVideoPlayer(
  controller: controller,
  subtitleStyle: const SubtitleStyle(
    fontSize: 20,
    textColor: Colors.white,
    backgroundColor: Colors.black54,
    position: SubtitlePosition.bottom,
    textAlign: SubtitleTextAlignment.center,
  ),
)
```

**Note:** Custom styling only applies when using Flutter rendering mode. Native rendering follows system settings.

### Add External Subtitle Track

```dart
// Add subtitle from URL
await controller.addSubtitleTrack(
  SubtitleTrack.network(
    url: 'https://example.com/subtitles.vtt',
    language: 'en',
    label: 'English',
  ),
);

// Add subtitle from asset
await controller.addSubtitleTrack(
  SubtitleTrack.asset(
    assetPath: 'assets/subtitles/english.srt',
    language: 'en',
    label: 'English',
  ),
);
```

### Get Available Tracks

```dart
final tracks = await controller.getSubtitleTracks();
for (final track in tracks) {
  print('${track.label} (${track.language})');
}
```

### Select a Track

```dart
final tracks = await controller.getSubtitleTracks();
await controller.setSubtitleTrack(tracks.first);
```

### Hide Subtitles

```dart
await controller.setSubtitleTrack(null);
// or
await controller.hideSubtitles();
```

### Listen to Subtitle Changes

```dart
controller.onSubtitleChanged.listen((cue) {
  if (cue != null) {
    print('Current subtitle: ${cue.text}');
  }
});
```

## Disabling Subtitles Entirely

```dart
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    subtitlesEnabled: false,  // Disable subtitle support
  ),
);

// Subtitle methods will be no-ops
await controller.addSubtitleTrack(...);  // Does nothing
final tracks = await controller.getSubtitleTracks();  // Returns empty list
```

## Subtitle Styling

### Native Rendering (Default)

When using `SubtitleRenderMode.native` or `SubtitleRenderMode.auto` (default), subtitle styling is handled by the native player and respects system accessibility settings:

- **iOS/macOS**: Follows system caption preferences (Settings > Accessibility > Subtitles & Captioning)
- **Android**: Follows system caption preferences (Settings > Accessibility > Caption preferences)
- **Web**: Uses browser's default TextTrack styling

### Flutter Rendering

When using `SubtitleRenderMode.flutter`, you have full control over subtitle styling via the `SubtitleStyle` parameter:

```dart
ProVideoPlayer(
  controller: controller,
  subtitleStyle: const SubtitleStyle(
    // Text styling
    fontSize: 18,
    fontWeight: FontWeight.bold,
    textColor: Colors.white,

    // Background styling
    backgroundColor: Colors.black87,
    borderColor: Colors.white,
    borderWidth: 1.0,

    // Layout
    position: SubtitlePosition.bottom,
    textAlign: SubtitleTextAlignment.center,
    padding: EdgeInsets.all(8.0),
  ),
)
```

**Available Style Properties:**
- `fontSize` - Text size in logical pixels
- `fontWeight` - Font weight (e.g., `FontWeight.bold`)
- `textColor` - Subtitle text color
- `backgroundColor` - Background color behind text
- `borderColor` - Border color around subtitle box
- `borderWidth` - Border thickness
- `position` - Vertical position (`top`, `center`, `bottom`)
- `textAlign` - Text alignment (`left`, `center`, `right`)
- `padding` - Padding around subtitle text

All styling properties are optional and have sensible defaults for readability.

## Best Practices

1. **Use WebVTT for maximum compatibility** - WebVTT (`.vtt`) is the only format fully supported across all platforms (iOS, Android, macOS, Web)
2. **Provide multiple languages** - Support international users with multi-language subtitle tracks
3. **Format recommendations by platform**:
   - **Cross-platform apps**: Use WebVTT only
   - **Android-only apps**: All formats supported (SRT, VTT, TTML, SSA/ASS)
   - **iOS/macOS apps**: Use WebVTT; SRT/TTML support is limited
   - **Web apps**: Use WebVTT; SRT works in Chrome/Firefox but not universal
4. **Test with long subtitles** - Ensure text doesn't overflow on small screens
5. **Choose the right rendering mode**:
   - Use **native rendering** for standard playback (respects accessibility settings)
   - Use **Flutter rendering** when you need custom styling or subtitles with native controls
6. **Respect accessibility** - When using Flutter rendering, ensure sufficient contrast and readability
7. **Test across platforms** - Verify subtitle appearance and format support on target platforms

## Troubleshooting

### Subtitles Not Appearing

- Verify `subtitlesEnabled: true` in options
- **Check format compatibility** - If using SRT/TTML/SSA/ASS on iOS/macOS or Web, convert to WebVTT
- Ensure subtitle file URL is accessible (CORS for web)
- Verify timing matches video
- Check browser console (Web) or device logs for format errors

### Wrong Language Selected

- Set `preferredSubtitleLanguage` to desired ISO 639-1 code
- Check track language metadata is correct

### Format Not Supported on Platform

- **iOS/macOS limitation**: SRT, SSA/ASS, and TTML have limited or no native support
- **Web limitation**: SSA/ASS not supported in browsers
- **Solution**: Convert subtitles to WebVTT format using online converters or ffmpeg:
  ```bash
  # Convert SRT to VTT
  ffmpeg -i subtitles.srt subtitles.vtt
  ```
- **Future**: Dart-side subtitle parsing (medium priority roadmap item) will eliminate these limitations

See [Troubleshooting Guide](../troubleshooting.md) for more help.
