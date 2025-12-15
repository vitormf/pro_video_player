# Platform-Specific Notes

Platform implementation details and capabilities.

## Platform Priority

- **Primary (equal):** iOS, Android, macOS, Web — feature parity, sync implementations
- **Secondary:** Windows, Linux — defer until primary complete

---

## Platform Details

| Platform | Player | Language | Min Version | Notes |
|----------|--------|----------|-------------|-------|
| iOS | AVPlayer | Swift | 13.0 | Extends MethodChannelBase |
| Android | ExoPlayer | Kotlin | TBD | Custom implementation |
| macOS | AVPlayer | Swift | 10.12 | Extends MethodChannelBase |
| Web | HTML5 Video | Dart | — | No method channels |
| Windows | libmpv | C++ | — | Stubs only, requires VM |
| Linux | libmpv | C++ | — | Stubs only, requires VM |

---

## iOS/macOS Shared Swift

iOS and macOS share significant Swift code via `shared_apple_sources/` because both use AVPlayer.

```
VideoPlayer → SharedVideoPlayer (~500 lines) → PlatformAdapter
                                                   ├── iOSPlatformAdapter (AVAudioSession, UIApplication)
                                                   └── macOSPlatformAdapter (fullscreen, NSApplication)
```

### Shared

- Player setup
- Playback controls
- Track handling
- Network resilience
- PiP setup
- Events

### Platform-Specific

- **iOS only:** AVAudioSession configuration, notifications
- **macOS only:** Fullscreen handling, NSApplication integration
- **Both:** Platform views (different host views)

See [architecture.md](architecture.md) for details on hard link setup and safeguards.

---

## Windows/Linux Shared C++ (Planned)

Windows and Linux will share C++ code via libmpv (same as media_kit approach).

```
VideoPlayer → SharedMpvPlayer → PlatformAdapter
                                   ├── WindowsAdapter (Win32, HWND)
                                   └── LinuxAdapter (GTK, X11/Wayland)
```

**libmpv benefits:**
- Cross-platform, simple C API
- Proven by media_kit
- MKV, WebM, and virtually all formats supported natively

**Note:** Binary size increase ~10-25MB per platform (only when libmpv included)

---

## Platform Capabilities

### Video Formats

| Platform | Native Formats | Adaptive Streaming |
|----------|----------------|-------------------|
| iOS/macOS | MP4, MOV, M4V | HLS only (no DASH) |
| Android | MP4, MKV, WebM, 3GP | HLS, DASH |
| Web | MP4, WebM, Ogg | HLS (via hls.js), DASH (via dash.js) |
| Windows/Linux (libmpv) | All | HLS, DASH |

### Subtitle Formats

| Platform | Native Rendering | Flutter Rendering |
|----------|------------------|-------------------|
| iOS/macOS | WebVTT (embedded only) | SRT, VTT, SSA/ASS, TTML, CEA-608/708 |
| Android | WebVTT, SRT | SRT, VTT, SSA/ASS, TTML, CEA-608/708 |
| Web | WebVTT | SRT, VTT, SSA/ASS, TTML |
| Windows/Linux | All (libmpv) | SRT, VTT, SSA/ASS, TTML |

**Note:** External subtitles on iOS/macOS always use Flutter rendering (AVPlayer limitation). Embedded subtitles use native rendering.

### Platform-Specific Features

| Feature | iOS | Android | macOS | Web | Windows | Linux |
|---------|-----|---------|-------|-----|---------|-------|
| PiP | ✅ True video PiP | ✅ Activity-level | ✅ True video PiP | ✅ Browser PiP | ⏳ Planned | ⏳ Planned |
| Background Audio | ✅ AVAudioSession | ✅ MediaSession | ✅ AVAudioSession | ❌ | ⏳ Planned | ⏳ Planned |
| AirPlay | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Chromecast | ⏳ Planned | ✅ | ⏳ Planned | ✅ Remote Playback API | ❌ | ❌ |
| Hardware Accel | ✅ | ✅ | ✅ | ✅ | ⏳ Planned | ⏳ Planned |

---

## Development Environment

### iOS/macOS

- Requires macOS with Xcode
- Swift 5.0+
- CocoaPods for dependency management
- Hard links managed via `make setup`

### Android

- Android Studio or IntelliJ IDEA
- Kotlin 1.x
- Gradle for builds
- Device/emulator required for instrumented tests

### Web

- Dart/Flutter web support
- Chrome for testing
- External libraries: hls.js, dash.js (dynamically loaded)

### Windows

- **⚠️ Requires Windows VM** — Cannot build on macOS/Linux
- Visual Studio with C++ support
- libmpv integration (planned)

### Linux

- **⚠️ Requires Linux VM** — Cannot build on macOS/Windows
- libmpv development libraries
- GTK or X11/Wayland support
