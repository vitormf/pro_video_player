# Migrating from video_player

This guide helps you migrate from Flutter's official `video_player` package to `pro_video_player`. The migration is straightforward because `pro_video_player` is designed to be API-compatible with `video_player` while providing additional features.

## Why Migrate?

`pro_video_player` provides all the functionality of `video_player` plus:

- **Native players on all platforms** (ExoPlayer, AVPlayer, libmpv, HTML5)
- **Advanced subtitle support** (SRT, VTT, SSA, ASS, TTML, CEA-608/708, embedded)
- **Chapter navigation** with metadata extraction
- **Playlist support** (M3U, PLS, XSPF)
- **Adaptive streaming** (HLS, DASH)
- **Picture-in-Picture** across platforms
- **Background playback** with media session controls
- **Casting support** (Chromecast, AirPlay)
- **Cross-platform Flutter controls** (optional)
- **Audio/video track selection**
- **Better error recovery**

## Quick Start

### 1. Update Dependencies

Replace in your `pubspec.yaml`:

```yaml
dependencies:
  # video_player: ^2.8.0  # Remove this
  pro_video_player: ^1.0.0  # Add this
```

### 2. Update Imports

```dart
// Before
import 'package:video_player/video_player.dart';

// After
import 'package:pro_video_player/pro_video_player.dart';
```

### 3. Minimal Code Changes

Most of your code will work without changes! Here's a comparison:

```dart
// video_player code
final controller = VideoPlayerController.network('https://example.com/video.mp4');
await controller.initialize();
controller.play();

// pro_video_player code (identical API!)
final controller = ProVideoPlayerController.network('https://example.com/video.mp4');
await controller.initialize();
controller.play();
```

## Side-by-Side Code Examples

### Basic Video Playback

<table>
<tr>
<th>video_player</th>
<th>pro_video_player</th>
</tr>
<tr>
<td>

```dart
class VideoScreen extends StatefulWidget {
  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
      'https://example.com/video.mp4',
    );
    _controller.initialize().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : CircularProgressIndicator();
  }
}
```

</td>
<td>

```dart
class VideoScreen extends StatefulWidget {
  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late ProVideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController.network(
      'https://example.com/video.mp4',
    );
    _controller.initialize().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: ProVideoPlayer(_controller),
          )
        : CircularProgressIndicator();
  }
}
```

</td>
</tr>
</table>

**Changes:** Just rename `VideoPlayerController` → `ProVideoPlayerController` and `VideoPlayer` → `ProVideoPlayer`.

### Playback Controls

<table>
<tr>
<th>video_player</th>
<th>pro_video_player</th>
</tr>
<tr>
<td>

```dart
// Play/Pause
controller.play();
controller.pause();

// Seek
controller.seekTo(Duration(seconds: 30));

// Volume
controller.setVolume(0.5);

// Playback speed
controller.setPlaybackSpeed(1.5);

// Looping
controller.setLooping(true);
```

</td>
<td>

```dart
// Play/Pause (identical)
controller.play();
controller.pause();

// Seek (identical)
controller.seekTo(Duration(seconds: 30));

// Volume (identical)
controller.setVolume(0.5);

// Playback speed (identical)
controller.setPlaybackSpeed(1.5);

// Looping (identical)
controller.setLooping(true);
```

</td>
</tr>
</table>

**Changes:** None! The API is identical.

### Video State

<table>
<tr>
<th>video_player</th>
<th>pro_video_player</th>
</tr>
<tr>
<td>

```dart
// Check state
if (controller.value.isPlaying) { ... }
if (controller.value.isBuffering) { ... }
if (controller.value.hasError) { ... }

// Get properties
final duration = controller.value.duration;
final position = controller.value.position;
final aspectRatio = controller.value.aspectRatio;
final buffered = controller.value.buffered;

// Listen to changes
controller.addListener(() {
  setState(() {});
});
```

</td>
<td>

```dart
// Check state (identical)
if (controller.value.isPlaying) { ... }
if (controller.value.isBuffering) { ... }
if (controller.value.hasError) { ... }

// Get properties (identical)
final duration = controller.value.duration;
final position = controller.value.position;
final aspectRatio = controller.value.aspectRatio;
final buffered = controller.value.buffered;

// Listen to changes (identical)
controller.addListener(() {
  setState(() {});
});
```

</td>
</tr>
</table>

**Changes:** None! All properties work identically.

### Captions/Subtitles

<table>
<tr>
<th>video_player</th>
<th>pro_video_player</th>
</tr>
<tr>
<td>

```dart
// Load captions
final captions = await loadCaptions();
controller.setClosedCaptionFile(captions);

// Get current caption
final caption = controller.value.caption;
if (caption != Caption.none) {
  print(caption.text);
}

// Adjust timing
controller.setCaptionOffset(
  Duration(milliseconds: 500),
);
```

</td>
<td>

```dart
// Load captions (compatible, but see note)
final captions = await loadCaptions();
controller.setClosedCaptionFile(captions);

// Get current caption (identical)
final caption = controller.value.caption;
if (caption != Caption.none) {
  print(caption.text);
}

// Adjust timing (identical)
controller.setCaptionOffset(
  Duration(milliseconds: 500),
);

// OR use enhanced subtitle API
await controller.addExternalSubtitle(
  SubtitleSource.network(
    'https://example.com/subs.srt',
    format: SubtitleFormat.srt,
  ),
);
```

</td>
</tr>
</table>

**Changes:** Compatible API works, but pro_video_player offers a more powerful subtitle system (see [Extended Features](#extended-features)).

**Note:** `setClosedCaptionFile()` is implemented as a compatibility stub. For production use, prefer `addExternalSubtitle()` with `SubtitleSource`.

### Video Sources

<table>
<tr>
<th>video_player</th>
<th>pro_video_player</th>
</tr>
<tr>
<td>

```dart
// Network URL
VideoPlayerController.network(
  'https://example.com/video.mp4',
  httpHeaders: {
    'Authorization': 'Bearer token',
  },
);

// Local file
VideoPlayerController.file(
  File('/path/to/video.mp4'),
);

// Asset
VideoPlayerController.asset(
  'assets/video.mp4',
  package: 'my_package',
);

// Content URI (Android)
VideoPlayerController.contentUri(
  Uri.parse('content://...'),
);
```

</td>
<td>

```dart
// Network URL (identical)
ProVideoPlayerController.network(
  'https://example.com/video.mp4',
  httpHeaders: {
    'Authorization': 'Bearer token',
  },
);

// Local file (identical)
ProVideoPlayerController.file(
  File('/path/to/video.mp4'),
);

// Asset (identical)
ProVideoPlayerController.asset(
  'assets/video.mp4',
  package: 'my_package',
);

// Content URI - use file source
ProVideoPlayerController.file(
  File.fromUri(Uri.parse('content://...')),
);
```

</td>
</tr>
</table>

**Changes:** `contentUri()` constructor not needed - use `file()` with URI.

### VideoPlayerOptions

<table>
<tr>
<th>video_player</th>
<th>pro_video_player</th>
</tr>
<tr>
<td>

```dart
VideoPlayerController.network(
  'https://example.com/video.mp4',
  videoPlayerOptions: VideoPlayerOptions(
    mixWithOthers: true,
    allowBackgroundPlayback: true,
  ),
);
```

</td>
<td>

```dart
ProVideoPlayerController.network(
  'https://example.com/video.mp4',
  videoPlayerOptions: VideoPlayerOptions(
    mixWithOthers: true,
    // allowBackgroundPlayback moved to method
  ),
);

// Enable background playback
await controller.setBackgroundPlayback(true);
```

</td>
</tr>
</table>

**Changes:** `allowBackgroundPlayback` is now a method for runtime control. See [Breaking Changes](#breaking-changes).

## Feature Comparison Table

| Feature | video_player | pro_video_player |
|---------|--------------|------------------|
| **Basic Playback** | ✅ | ✅ |
| Network videos | ✅ | ✅ |
| Local files | ✅ | ✅ |
| Asset videos | ✅ | ✅ |
| HTTP headers | ✅ | ✅ |
| **Playback Controls** | | |
| Play/Pause | ✅ | ✅ |
| Seek | ✅ | ✅ |
| Volume | ✅ | ✅ |
| Playback speed | ✅ | ✅ |
| Looping | ✅ | ✅ |
| **State Properties** | | |
| Duration | ✅ | ✅ |
| Position | ✅ | ✅ |
| Buffering | ✅ | ✅ |
| Aspect ratio | ✅ | ✅ |
| Error handling | ✅ | ✅ Enhanced |
| **Subtitles** | | |
| Basic captions | ✅ | ✅ |
| SRT format | ✅ | ✅ |
| VTT format | ✅ | ✅ |
| SSA/ASS format | ❌ | ✅ |
| TTML format | ❌ | ✅ |
| CEA-608/708 | ❌ | ✅ |
| Embedded subtitles | ❌ | ✅ |
| Multiple tracks | ❌ | ✅ |
| Track switching | ❌ | ✅ |
| **Advanced Features** | | |
| Adaptive streaming (HLS/DASH) | ✅ | ✅ Enhanced |
| Quality selection | ❌ | ✅ |
| Audio track selection | ❌ | ✅ |
| Chapter navigation | ❌ | ✅ |
| Playlists | ❌ | ✅ |
| Picture-in-Picture | iOS/Android | All platforms |
| Background playback | Limited | Full support |
| Casting | ❌ | ✅ |
| Cross-platform controls | ❌ | ✅ |
| Video scaling modes | ❌ | ✅ |
| Network monitoring | ❌ | ✅ |
| **Platform Support** | | |
| iOS | ✅ | ✅ (AVPlayer) |
| Android | ✅ | ✅ (ExoPlayer) |
| Web | ✅ | ✅ (HTML5) |
| macOS | ✅ | ✅ (AVPlayer) |
| Windows | ❌ | ✅ (libmpv) |
| Linux | ❌ | ✅ (libmpv) |

## Breaking Changes

### 1. Background Playback Configuration

**video_player:**
```dart
VideoPlayerController.network(
  url,
  videoPlayerOptions: VideoPlayerOptions(
    allowBackgroundPlayback: true,
  ),
);
```

**pro_video_player:**
```dart
final controller = ProVideoPlayerController.network(url);
await controller.initialize();
await controller.setBackgroundPlayback(true);
```

**Reason:** Runtime control is more flexible and matches platform capabilities.

### 2. Content URI (Android only)

**video_player:**
```dart
VideoPlayerController.contentUri(Uri.parse('content://...'));
```

**pro_video_player:**
```dart
ProVideoPlayerController.file(File.fromUri(Uri.parse('content://...')));
```

**Reason:** Unified file handling across platforms.

### 3. Error Handling

**video_player:**
```dart
if (controller.value.hasError) {
  print(controller.value.errorDescription);
}
```

**pro_video_player:**
```dart
if (controller.value.hasError) {
  final error = controller.value.error;
  print(error.message);
  print(error.code);  // Structured error codes
}
```

**Enhancement:** More detailed error information with structured codes.

## Migration Strategies

### Strategy 1: Drop-in Replacement (Recommended)

For most apps, you can simply:

1. Replace imports
2. Rename classes (VideoPlayerController → ProVideoPlayerController)
3. Test thoroughly

**Time estimate:** 15-30 minutes for a typical app.

### Strategy 2: Gradual Migration

For larger apps:

1. Start with new screens using pro_video_player
2. Keep existing screens on video_player temporarily
3. Migrate screen by screen
4. Both packages can coexist during migration

### Strategy 3: Feature-Enhanced Migration

Take advantage of migration to add features:

1. Migrate to pro_video_player with basic compatibility
2. Add subtitles with `addExternalSubtitle()`
3. Implement quality selection with `setQualityTrack()`
4. Add PiP support with `enterPictureInPicture()`
5. Enable background playback with `setBackgroundPlayback()`

## Extended Features

Beyond video_player compatibility, pro_video_player offers:

### 1. Advanced Subtitle System

```dart
// Add external subtitles
final track = await controller.addExternalSubtitle(
  SubtitleSource.network(
    'https://example.com/subtitles.srt',
    format: SubtitleFormat.srt,
    label: 'English',
  ),
);

// Switch subtitle tracks
await controller.setSubtitleTrack(track);

// Disable subtitles
await controller.setSubtitleTrack(null);

// List available tracks
final tracks = controller.value.subtitleTracks;
```

### 2. Quality Selection

```dart
// List available qualities
final qualities = controller.value.videoQualityTracks;

// Switch to specific quality
await controller.setQualityTrack(qualities.first);

// Enable auto quality (adaptive)
await controller.setQualityTrack(null);
```

### 3. Audio Track Selection

```dart
// List audio tracks
final audioTracks = controller.value.audioTracks;

// Switch audio track
await controller.setAudioTrack(audioTracks.first);
```

### 4. Chapter Navigation

```dart
// Get chapters (auto-extracted from metadata)
final chapters = controller.value.chapters;

// Jump to chapter
final chapter = chapters.first;
await controller.seekTo(chapter.startTime);

// Listen for chapter changes
controller.addListener(() {
  final currentChapter = controller.value.currentChapter;
  print('Now in chapter: ${currentChapter?.title}');
});
```

### 5. Playlist Support

```dart
// Load playlist
await controller.initialize(
  source: VideoSource.network('https://example.com/playlist.m3u'),
);

// Navigate playlist
await controller.playNextTrack();
await controller.playPreviousTrack();
await controller.playTrackAtIndex(2);

// Playlist state
final currentIndex = controller.value.currentPlaylistIndex;
final trackCount = controller.value.playlistTrackCount;
```

### 6. Picture-in-Picture

```dart
// Enter PiP
await controller.enterPictureInPicture();

// Exit PiP
await controller.exitPictureInPicture();

// Check if in PiP
if (controller.value.isPictureInPicture) { ... }

// Listen for PiP changes
controller.addListener(() {
  if (controller.value.isPictureInPicture) {
    // Minimize UI
  }
});
```

### 7. Background Playback

```dart
// Enable background playback
await controller.setBackgroundPlayback(true);

// Check if supported
final supported = await controller.isBackgroundPlaybackSupported();

// Check state
if (controller.value.isBackgroundPlaybackEnabled) { ... }
```

### 8. Casting

```dart
// Show cast button in UI (MaterialApp required)
CastButton(
  onPressed: () async {
    // Cast button automatically handles device selection
  },
);

// Check cast state
final castState = controller.value.castState;
if (castState == CastState.connected) {
  final device = controller.value.connectedCastDevice;
  print('Casting to: ${device?.name}');
}
```

### 9. Cross-Platform Controls

```dart
ProVideoPlayer(
  controller,
  // Show built-in controls (cross-platform)
  showControls: true,

  // Control visibility timeout
  controlsTimeout: Duration(seconds: 3),

  // Custom control overlay (optional)
  controlsBuilder: (context, controller) {
    return MyCustomControls(controller);
  },
);
```

### 10. Video Scaling Modes

```dart
// Adjust how video fills the viewport
await controller.setScalingMode(VideoScalingMode.fit);
await controller.setScalingMode(VideoScalingMode.fill);
await controller.setScalingMode(VideoScalingMode.zoom);
```

### 11. Network Monitoring

```dart
// Listen for network changes
controller.addListener(() {
  final isOnline = controller.value.isNetworkConnected;
  if (!isOnline) {
    // Show offline UI
  }
});

// Bandwidth estimate (for adaptive streaming)
final bandwidth = controller.value.bandwidthEstimate;
```

### 12. Error Recovery

```dart
// Automatic retry on network errors
controller.addListener(() {
  if (controller.value.hasError) {
    final error = controller.value.error;
    if (error.isNetworkError) {
      // Will auto-retry with exponential backoff
      print('Network error, retrying...');
    }
  }
});

// Manual retry
if (controller.value.hasError) {
  await controller.retry();
}
```

## Common Patterns

### Pattern 1: Fullscreen Toggle

**video_player:**
```dart
// No built-in support
// Developers implement custom fullscreen logic
```

**pro_video_player:**
```dart
// Built-in fullscreen support
await controller.enterFullscreen();
await controller.exitFullscreen();

// Toggle
if (controller.value.isFullscreen) {
  await controller.exitFullscreen();
} else {
  await controller.enterFullscreen();
}
```

### Pattern 2: Custom Controls with State

**video_player:**
```dart
class CustomControls extends StatelessWidget {
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        return IconButton(
          icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            value.isPlaying ? controller.pause() : controller.play();
          },
        );
      },
    );
  }
}
```

**pro_video_player:**
```dart
class CustomControls extends StatelessWidget {
  final ProVideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        return IconButton(
          icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            value.isPlaying ? controller.pause() : controller.play();
          },
        );
      },
    );
  }
}
```

**Changes:** None! Identical pattern works.

### Pattern 3: Video Progress Bar

**video_player:**
```dart
VideoProgressIndicator(
  controller,
  allowScrubbing: true,
  colors: VideoProgressColors(
    playedColor: Colors.red,
    bufferedColor: Colors.grey,
    backgroundColor: Colors.black,
  ),
);
```

**pro_video_player:**
```dart
// Option 1: Use built-in controls
ProVideoPlayer(controller, showControls: true);

// Option 2: Custom progress bar (same API as video_player)
VideoProgressIndicator(
  controller,
  allowScrubbing: true,
  colors: VideoProgressColors(
    playedColor: Colors.red,
    bufferedColor: Colors.grey,
    backgroundColor: Colors.black,
  ),
);
```

## Testing Your Migration

After migrating, verify:

1. **Basic Playback**
   - Videos play correctly
   - Play/pause works
   - Seeking works

2. **State Management**
   - Progress updates correctly
   - Buffering indicator shows
   - Error states display properly

3. **Subtitles** (if used)
   - Captions display correctly
   - Timing is accurate

4. **Platform-Specific**
   - iOS: Background playback, PiP
   - Android: Background playback, PiP, notification controls
   - Web: Controls render properly

5. **Performance**
   - Smooth video playback
   - No memory leaks on dispose
   - Quick initialization times

## Getting Help

If you encounter issues during migration:

1. Check the [API documentation](https://pub.dev/documentation/pro_video_player/latest/)
2. Review [troubleshooting guide](./troubleshooting.md)
3. See [example apps](../example-showcase) for working code
4. Open an issue on [GitHub](https://github.com/your-org/pro_video_player/issues)

## Summary

Migrating from video_player to pro_video_player is straightforward:

✅ **Minimal code changes** - mostly renaming classes
✅ **Compatible API** - existing code works as-is
✅ **Drop-in replacement** - can migrate in 15-30 minutes
✅ **Enhanced features** - unlock advanced capabilities when ready
✅ **Better platform support** - Windows, Linux, improved web

The migration preserves all your existing functionality while giving you access to professional features like advanced subtitles, quality selection, playlists, PiP, casting, and more.
