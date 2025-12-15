# Developer Guide

Developer-focused guidelines for API documentation and configurability.

## Developer Configurability

All features configurable via `VideoPlayerOptions`:

| Feature | Option | Default | Description |
|---------|--------|---------|-------------|
| Auto-play | `autoPlay` | `false` | Start playback automatically |
| Looping | `looping` | `false` | Loop video when complete |
| Volume | `volume` | `1.0` | Initial volume (0.0-1.0) |
| Playback Speed | `playbackSpeed` | `1.0` | Initial speed |
| Background Playback | `allowBackgroundPlayback` | `false` | Allow audio when app is backgrounded |
| Mix with Others | `mixWithOthers` | `false` | Mix audio with other apps (iOS) |
| PiP Allowed | `allowPip` | `true` | Enable/disable PiP feature |
| Auto-enter PiP | `autoEnterPipOnBackground` | `false` | Enter PiP when app backgrounds |
| Subtitles Enabled | `subtitlesEnabled` | `true` | Enable/disable subtitle support |
| Show Subtitles | `showSubtitlesByDefault` | `false` | Auto-show subtitles when available |
| Subtitle Language | `preferredSubtitleLanguage` | `null` | ISO 639-1 code (e.g., 'en') |
| Scaling Mode | `scalingMode` | `fit` | How video fills player (fit/fill/stretch) |
| ABR Mode | `abrMode` | `auto` | Adaptive bitrate mode (auto/manual) |
| Min Bitrate | `minBitrate` | `null` | Minimum bitrate in bps (Android/Web only) |
| Max Bitrate | `maxBitrate` | `null` | Maximum bitrate in bps |

### Design Principles

1. **Opt-in vs Opt-out**: Performance/UX-impacting features (background playback, auto-PiP) are opt-in. Expected features (subtitles, PiP) are opt-out.
2. **Graceful Degradation**: Disabled features don't throw errors. `enterPip()` when `allowPip` is `false` returns `false`.
3. **Runtime Configuration**: Options passed at init; some (volume, looping, subtitles) changeable at runtime.

### Platform-Specific: Android Background Notification

When `allowBackgroundPlayback` is enabled, the foreground service notification is customizable:
- Custom icon, title, text
- Custom actions/buttons and channel settings

### Example Usage

```dart
// Full-featured player
final controller = ProVideoPlayerController();
await controller.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(
    autoPlay: true,
    allowBackgroundPlayback: true,
    allowPip: true,
    autoEnterPipOnBackground: true,
    subtitlesEnabled: true,
    showSubtitlesByDefault: true,
    preferredSubtitleLanguage: 'en',
    scalingMode: VideoScalingMode.fill,
  ),
);

// Minimal player
final simpleController = ProVideoPlayerController();
await simpleController.initialize(
  source: VideoSource.network('https://example.com/video.mp4'),
  options: const VideoPlayerOptions(allowPip: false, subtitlesEnabled: false),
);
```

---

## API Documentation Requirements

All public API must have dartdoc (`///`) with:
1. **Description** of the class/method/property
2. **Parameter descriptions** with purpose and valid values
3. **Return value descriptions**
4. **Examples** for complex APIs
5. **Exceptions** that can be thrown

### Example

```dart
/// Creates a new video player instance with the given [source].
///
/// The [options] parameter allows customizing playback behavior.
/// Returns a [Future] that completes when the player is initialized.
/// Throws [VideoPlayerException] if initialization fails.
///
/// Example:
/// ```dart
/// final controller = ProVideoPlayerController();
/// await controller.initialize(source: VideoSource.network('https://example.com/video.mp4'));
/// ```
Future<void> initialize({
  required VideoSource source,
  VideoPlayerOptions options = const VideoPlayerOptions(),
});
```

---

## README.md Guidelines

1. **Short and simple** — Concise and easy to scan
2. **Clear explanation** — What the library is and does
3. **Main capabilities** — Key features list
4. **Quick example** — Very short basic usage code

Avoid lengthy documentation in README. Keep detailed docs separate.

---

## File Creation Policy

### Allowed

- `README.md` — Short overview, quick start (for library users)
- `CLAUDE.md` — AI assistant instructions (for contributors)
- `ROADMAP.md` — Project roadmap and tracking
- `docs/` folder — **User documentation** (linked from README.md):
  ```
  docs/
  ├── setup/ (android.md, ios.md)
  ├── features/ (pip.md, background-playback.md, subtitles.md, fullscreen.md)
  └── troubleshooting.md
  ```
- `contributing/` folder — **Developer documentation** (linked from CLAUDE.md):
  ```
  contributing/
  ├── architecture.md
  ├── testing-guide.md
  ├── developer-guide.md
  ├── platform-notes.md
  └── copyright-compliance.md
  ```

### Not Allowed

- Random markdown files in project root
- Duplicate documentation
- Auto-generated docs (use dartdoc instead)
