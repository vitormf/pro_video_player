# pro_video_player

A Flutter plugin for video playback using native video players across all platforms.

## Platform Support

| Platform | Implementation | Status |
|----------|---------------|--------|
| **iOS** | AVPlayer | ✅ Fully implemented |
| **Android** | ExoPlayer | ✅ Fully implemented |
| **Web** | HTML5 VideoElement | ✅ Fully implemented |
| **macOS** | AVPlayer | ✅ Fully implemented |
| **Windows** | Media Foundation | 🚧 Native code needed |
| **Linux** | GStreamer | 🚧 Native code needed |

## Features

- Native video player integration per platform
- Network, file, and asset video sources
- Playlist support with automatic file parsing (M3U, M3U8, PLS, XSPF, JSPF, ASX, WPL, CUE)
- HLS adaptive streaming with automatic bitrate switching (via native players)
- DASH streaming support (Android and Web)
- Playback controls (play, pause, seek, stop)
- Playback speed control
- Volume control
- Loop mode
- Picture-in-Picture (PiP) support
- Subtitle/closed caption support with native or Flutter rendering
- Background playback support
- Comprehensive event system
- Customizable or native UI controls

## Platform-Specific Features

| Feature | iOS | Android | Web | macOS | Windows | Linux |
|---------|-----|---------|-----|-------|---------|-------|
| Video Playback | ✅ | ✅ | ✅ | ✅ | 🚧 | 🚧 |
| HLS Streaming | ✅ | ✅ | ✅ | ✅ | 🚧 | 🚧 |
| DASH Streaming | ❌ | ✅ | ✅ | ❌ | 🚧 | 🚧 |
| Picture-in-Picture | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Background Playback | ✅ | ✅ | ❌ | ✅ | 🚧 | 🚧 |
| Subtitles | ✅ | ✅ | ✅ | ✅ | 🚧 | 🚧 |
| Fullscreen | ✅ | ✅ | ✅ | ✅ | 🚧 | 🚧 |

**Legend:**
- ✅ Fully implemented
- 🚧 Dart implementation complete, native code needed
- ❌ Not supported on platform (AVPlayer doesn't support DASH)

## Platform Setup

### Android

**Picture-in-Picture (PiP):**

To enable PiP support, add the following attribute to your `MainActivity` in `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:supportsPictureInPicture="true"
    ...>
```

**Background Playback:**

Background audio playback on Android requires a foreground service. The plugin automatically declares the necessary permissions and service in its manifest, which merges with your app's manifest. No additional configuration is required in most cases.

However, if you're targeting Android 14 (API 34) or higher, you may need to add the foreground service permission to your app's manifest:

```xml
<manifest>
    <!-- Required for Android 14+ -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
    ...
</manifest>
```

**Enable in code:**

```dart
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: VideoPlayerOptions(
    allowBackgroundPlayback: true,  // Enable background audio
  ),
);
```

When background playback is enabled, a media notification will appear allowing users to control playback from outside the app.

### iOS

**Picture-in-Picture (PiP) and Background Playback:**

Both PiP and background audio playback require the same configuration. Add the following to your `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

**Using Xcode:** Select your target → Signing & Capabilities → Add "Background Modes" → Check "Audio, AirPlay, and Picture in Picture".

**Note:** iOS uses true video-only PiP where the video floats in a system-controlled window independently from your app. The main app continues to display normally while PiP is active.

**Enable in code:**

```dart
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: VideoPlayerOptions(
    allowBackgroundPlayback: true,  // Enable background audio
  ),
);
```

**Media Controls:**

When background playback is enabled, media controls appear in Control Center and on the Lock Screen. You can customize the metadata displayed:

```dart
await controller.setMediaMetadata(MediaMetadata(
  title: 'Video Title',
  artist: 'Channel Name',
  album: 'Series Name',
  artworkUrl: 'https://example.com/thumbnail.jpg',
));
```

### Web

Web support uses HTML5 VideoElement with native browser controls. No additional setup required.

**Picture-in-Picture:**
- Supported in browsers that implement the Picture-in-Picture API (Chrome, Edge, Safari)
- Automatically detected and enabled when available

**Limitations:**
- Background playback not supported (browser limitation)
- Some video formats may not be supported depending on the browser

### macOS

macOS uses AVPlayer (same as iOS).

**Picture-in-Picture:**
- Supported on macOS 10.12 (Sierra) and later
- No additional configuration needed

**Background Playback:**

macOS apps continue playing audio when minimized or in the background by default. Enable background playback in code:

```dart
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: VideoPlayerOptions(
    allowBackgroundPlayback: true,
  ),
);
```

**Media Controls:**

Media controls appear in the macOS Control Center. Customize the metadata:

```dart
await controller.setMediaMetadata(MediaMetadata(
  title: 'Video Title',
  artist: 'Channel Name',
));
```

### Windows

**Status:** 🚧 Dart implementation complete, native C++ code needed

Windows implementation will use Media Foundation for video playback.

**Current State:**
- ✅ Dart interface complete (shared via `MethodChannelBase`)
- ✅ Platform structure ready
- ✅ Method channel setup complete
- ❌ Native C++ code needs implementation (requires Windows + Visual Studio)

**To implement:** Requires Windows machine/VM with Visual Studio to implement Media Foundation player.

### Linux

**Status:** 🚧 Dart implementation complete, native C code needed

Linux implementation will use GStreamer for video playback.

**Current State:**
- ✅ Dart interface complete (shared via `MethodChannelBase`)
- ✅ Platform structure ready
- ✅ Method channel setup complete
- ❌ Native C/C++ code needs implementation (requires Linux + GStreamer)

**To implement:** Requires Linux machine/VM with GStreamer development libraries installed.

## Quick Example

```dart
import 'package:pro_video_player/pro_video_player.dart';

// Create a controller
final controller = ProVideoPlayerController();

// Initialize with a video source
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
);

// Display the video
ProVideoPlayer(controller: controller);

// Control playback
await controller.play();
await controller.pause();
await controller.seekTo(Duration(seconds: 30));

// Clean up
await controller.dispose();
```

See the `example/` directory for a complete working example.

## Advanced Usage

### Video Sources

Pro Video Player supports multiple types of video sources:

```dart
// Network video
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
);

// Local file
await controller.initialize(
  source: VideoSource.file('/path/to/video.mp4'),
);

// App asset
await controller.initialize(
  source: VideoSource.asset('assets/videos/intro.mp4'),
);

// Playlist file (M3U, M3U8, PLS, XSPF)
await controller.initialize(
  source: VideoSource.playlist('https://example.com/playlist.m3u'),
);
```

### Playlist Support

The library supports both manual playlists and automatic playlist file parsing:

#### Manual Playlists

```dart
// Create a playlist from individual video sources
final playlist = Playlist(
  items: [
    VideoSource.network('https://example.com/video1.mp4'),
    VideoSource.network('https://example.com/video2.mp4'),
    VideoSource.network('https://example.com/video3.mp4'),
  ],
);

// Initialize with the playlist
await controller.initializeWithPlaylist(playlist: playlist);

// Control playlist playback
await controller.playlistNext();     // Skip to next video
await controller.playlistPrevious(); // Go to previous video
await controller.playlistJumpTo(1);  // Jump to specific index

// Shuffle and repeat modes
await controller.setPlaylistShuffle(enabled: true);
await controller.setPlaylistRepeatMode(PlaylistRepeatMode.all);
```

#### Playlist File Parsing

The library automatically detects and parses playlist files. Supported formats:
- **M3U/M3U8** - Standard playlist format, also used for HLS adaptive streaming
- **PLS** - WinAmp/Shoutcast playlist format
- **XSPF** - XML Shareable Playlist Format
- **JSPF** - JSON Shareable Playlist Format
- **ASX** - Advanced Stream Redirector (Microsoft)
- **WPL** - Windows Media Player Playlist
- **CUE** - Cue Sheet (describes tracks within a single file)

```dart
// Simple usage - automatic detection and parsing
await controller.initialize(
  source: VideoSource.playlist('https://example.com/playlist.m3u'),
);
```

**Automatic HLS Detection:**

The library automatically distinguishes between:
- **HLS Adaptive Streams** (m3u8 master/media playlists) - Treated as a single video source with automatic quality adaptation
- **Simple Playlists** (basic M3U with multiple videos) - Parsed into a multi-video playlist

Detection is based on playlist markers:
- `#EXT-X-STREAM-INF` → HLS master playlist (adaptive stream)
- `#EXT-X-TARGETDURATION` → HLS media playlist (adaptive stream)
- Multiple `#EXTINF` entries → Simple multi-video playlist

Both URL-based and content-based detection are supported for reliable format identification.

### Adaptive Streaming (HLS & DASH)

The library supports both HLS and DASH adaptive streaming formats:

| Format | iOS | Android | Web | macOS |
|--------|-----|---------|-----|-------|
| **HLS** (.m3u8) | ✅ AVPlayer | ✅ ExoPlayer | ✅ HLS.js | ✅ AVPlayer |
| **DASH** (.mpd) | ❌ | ✅ ExoPlayer | ✅ dash.js | ❌ |

**Note:** iOS and macOS use AVPlayer which does not support DASH natively. Use HLS for Apple platforms.

**Adaptive Bitrate Switching:**

When playing HLS or DASH streams, the native players automatically handle bitrate switching based on network conditions. The player will:
- Monitor available bandwidth and buffer health
- Automatically switch to lower quality when network is poor
- Automatically switch back to higher quality when conditions improve

No configuration needed - this works out of the box.

**ABR Configuration:**

You can configure the adaptive bitrate behavior using `VideoPlayerOptions`:

```dart
// Auto mode with bitrate constraints
await controller.initialize(
  source: VideoSource.network('https://example.com/stream.m3u8'),
  options: VideoPlayerOptions(
    abrMode: AbrMode.auto,       // Automatic quality selection (default)
    minBitrate: 500000,          // Minimum 500 kbps
    maxBitrate: 5000000,         // Maximum 5 Mbps
  ),
);

// Manual mode - disable automatic switching
await controller.initialize(
  source: VideoSource.network('https://example.com/stream.m3u8'),
  options: VideoPlayerOptions(
    abrMode: AbrMode.manual,     // Manual quality selection only
  ),
);
```

**ABR options:**
| Option | Default | Description |
|--------|---------|-------------|
| `abrMode` | `AbrMode.auto` | Quality selection mode (auto/manual) |
| `minBitrate` | `null` | Minimum bitrate in bps (null = no limit) |
| `maxBitrate` | `null` | Maximum bitrate in bps (null = no limit) |

**Platform notes:**
- **Android (ExoPlayer):** Full support for all ABR options
- **iOS/macOS (AVPlayer):** Only `maxBitrate` supported (via `preferredPeakBitRate`)
- **Web (HLS.js/dash.js):** Full support for all ABR options

**Manual Quality Selection:**

For HLS and DASH streams, you can manually select video quality:

```dart
// Get available qualities
final qualities = await controller.getVideoQualities();

// Select a specific quality
await controller.setVideoQuality(qualities[1]);

// Return to auto-adaptive mode
await controller.setVideoQuality(null);

// Check if quality selection is supported
final supported = await controller.isQualitySelectionSupported();
```

### Runtime Background Playback Toggle

Background playback can be enabled/disabled at runtime on supported platforms:

```dart
// Check if background playback is supported on current platform
final supported = await controller.isBackgroundPlaybackSupported();

// Enable background playback at runtime
await controller.setBackgroundPlayback(enabled: true);

// Disable background playback
await controller.setBackgroundPlayback(enabled: false);

// Check current state
final enabled = controller.isBackgroundPlaybackEnabled;
```

**Platform Support:**
| Platform | Support | Requirements |
|----------|---------|--------------|
| iOS | ✅ | UIBackgroundModes with 'audio' in Info.plist |
| Android | ✅ | Foreground service permissions (auto-declared) |
| macOS | ✅ | Always available (no configuration needed) |
| Web | ❌ | Browser controls background audio policy |

**Note:** Even with runtime toggle, the platform must be properly configured first (see Platform Setup above).

### Control Modes

The library supports multiple control modes for different use cases:

```dart
// Flutter controls (default) - cross-platform custom UI
ProVideoPlayer(
  controller: controller,
  controlsMode: ControlsMode.flutter,
)

// Native controls - platform-specific UI (AVPlayerViewController on iOS, ExoPlayer on Android)
ProVideoPlayer(
  controller: controller,
  controlsMode: ControlsMode.native,
)

// No controls - video only, for custom external controls
ProVideoPlayer(
  controller: controller,
  controlsMode: ControlsMode.none,
)

// Custom controls - provide your own UI
ProVideoPlayer(
  controller: controller,
  controlsBuilder: (context, controller) => MyCustomControls(controller: controller),
)
```

### Compact Mode

For small player sizes or Picture-in-Picture mode, the library provides a compact control layout:

```dart
VideoPlayerControls(
  controller: controller,
  compactMode: CompactMode.auto, // Default: auto-detect based on size and PiP
)
```

**Compact mode options:**
- `CompactMode.auto` - Automatically use compact controls when player is small or in PiP mode (default)
- `CompactMode.always` - Always use compact controls
- `CompactMode.never` - Never use compact controls

**Customize the size threshold:**
```dart
VideoPlayerControls(
  controller: controller,
  compactMode: CompactMode.auto,
  compactThreshold: Size(300, 200), // Default threshold
)
```

**Compact UI features:**
- Large centered play/pause button (64px)
- Simple progress bar at bottom
- No gestures (only tap to toggle play/pause)
- Buffering indicator when loading

### Player Toolbar Actions

The Flutter controls' player toolbar can be customized to show specific actions and limit the number of visible buttons:

```dart
VideoPlayerControls(
  controller: controller,
  // Specify which actions to show and their order
  playerToolbarActions: [
    PlayerToolbarAction.subtitles,
    PlayerToolbarAction.speed,
    PlayerToolbarAction.pip,
    PlayerToolbarAction.fullscreen,
  ],
  // Limit visible actions - extras go to overflow menu
  maxPlayerToolbarActions: 3,
)
```

**Available actions:**
| Action | Description |
|--------|-------------|
| `PlayerToolbarAction.shuffle` | Playlist shuffle (only visible with playlist) |
| `PlayerToolbarAction.repeatMode` | Playlist repeat (only visible with playlist) |
| `PlayerToolbarAction.subtitles` | Subtitle track selection |
| `PlayerToolbarAction.audio` | Audio track selection |
| `PlayerToolbarAction.quality` | Video quality selection (HLS/DASH) |
| `PlayerToolbarAction.speed` | Playback speed |
| `PlayerToolbarAction.scalingMode` | Video scaling (fit/fill/stretch) |
| `PlayerToolbarAction.backgroundPlayback` | Background audio toggle |
| `PlayerToolbarAction.pip` | Picture-in-Picture |
| `PlayerToolbarAction.fullscreen` | Fullscreen toggle |

**Overflow menu:**

When `maxPlayerToolbarActions` is set and more actions are visible than the limit, extra actions appear in an overflow menu (⋮ button):

```dart
// Show only 2 actions directly, rest in overflow menu
VideoPlayerControls(
  controller: controller,
  playerToolbarActions: [
    PlayerToolbarAction.speed,
    PlayerToolbarAction.scalingMode,
    PlayerToolbarAction.pip,
    PlayerToolbarAction.fullscreen, // This goes to overflow menu
  ],
  maxPlayerToolbarActions: 2,
)
```

**Conditional visibility:**

Actions automatically hide when their conditions aren't met:
- Subtitle/audio/quality actions hide when no tracks are available
- Shuffle/repeat hide when no playlist is active
- PiP hides when not supported on the device
- Background playback hides when not supported on the platform

### Subtitle Rendering Modes

Choose between native platform rendering or customizable Flutter rendering for subtitles:

```dart
// Native rendering (default) - respects system accessibility settings
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    subtitleRenderMode: SubtitleRenderMode.native,
  ),
);

// Flutter rendering - custom styling, works with all controls modes
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    subtitleRenderMode: SubtitleRenderMode.flutter,
  ),
);

// Runtime mode switching
await controller.setSubtitleRenderMode(SubtitleRenderMode.flutter);
```

**Benefits of Flutter rendering:**
- Works with native controls, Flutter controls, no controls, or custom UI
- Customizable styling via `SubtitleStyle` (font, color, position, etc.)
- Consistent appearance across all platforms
- Always overlays on top of native controls

**Platform-specific behavior for external subtitles:**
- **Android/Web**: External subtitles (loaded via `addExternalSubtitle()`) can use either native or Flutter rendering
- **iOS/macOS**: External subtitles always use Flutter rendering, regardless of the mode setting (AVPlayer limitation)
- **All platforms**: Embedded subtitles (already in the video file) use native rendering when `SubtitleRenderMode.native` is active

For detailed subtitle documentation, see [docs/features/subtitles.md](docs/features/subtitles.md).

### Fullscreen and PiP with Consistent Controls

Use `ProVideoPlayerBuilder` to maintain consistent control modes across normal, fullscreen, and PiP views:

```dart
ProVideoPlayerBuilder(
  controller: controller,
  controlsMode: ControlsMode.flutter, // Used in all views
  builder: (context, controller, child) {
    return Scaffold(
      appBar: AppBar(title: Text('Video')),
      body: ProVideoPlayer(controller: controller),
    );
  },
)
```

**Default behavior:**
- **Fullscreen:** Automatically uses the same `controlsMode` and `controlsBuilder` as the normal view
- **PiP (Android):** Uses compact controls optimized for the small window
- **PiP (iOS):** Native system-managed controls (video floats independently)

**Customize with builders:**
```dart
ProVideoPlayerBuilder(
  controller: controller,
  controlsMode: ControlsMode.flutter,
  builder: (context, controller, child) => NormalView(controller: controller),
  fullscreenBuilder: (context, controller, child) {
    // Custom fullscreen layout
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ProVideoPlayer(controller: controller),
          MyFullscreenOverlay(),
        ],
      ),
    );
  },
  pipBuilder: (context, controller, child) {
    // Custom Android PiP layout
    return ProVideoPlayer(
      controller: controller,
      controlsMode: ControlsMode.none,
    );
  },
)
```

**Disable default fullscreen/PiP views:**
```dart
ProVideoPlayerBuilder(
  controller: controller,
  useDefaultFullscreen: false, // Use normal builder for fullscreen
  useDefaultPip: false,        // Use normal builder for Android PiP
  builder: (context, controller, child) => MyApp(),
)
### Fullscreen Status Bar

When in fullscreen mode, a persistent status bar is displayed at the top of the screen with:
- **Left side**: Video position/duration (e.g., "12:34 / 1:23:45")
- **Right side**: System time in 12-hour format (e.g., "2:30 PM") and battery level with charging indicator (when available)

The status bar uses small, unobtrusive text (11px) and automatically hides when the system status bar is visible (not in true fullscreen mode). It does not auto-hide with playback controls, providing persistent contextual information during fullscreen playback.

**Enable/disable the status bar:**
```dart
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    showFullscreenStatusBar: true, // Default: true
  ),
);
```

**Platform support for battery information:**

| Platform | Battery Support | Notes |
|----------|----------------|-------|
| iOS | ✅ Full support | UIDevice battery APIs |
| Android | ✅ Full support | BatteryManager |
| macOS | ✅ MacBooks only | Null on desktop Macs |
| Web | ✅ Limited | Chrome, Edge (Battery Status API) |
| Windows/Linux | ❌ Not implemented | Battery section hidden |

When battery information is unavailable, the status bar gracefully hides only the battery section while continuing to show time and video position.
