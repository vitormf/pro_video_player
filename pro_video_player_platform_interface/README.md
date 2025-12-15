# pro_video_player_platform_interface

A common platform interface for the [`pro_video_player`](../pro_video_player) plugin.

This interface allows platform-specific implementations of the `pro_video_player` plugin, as well as the plugin itself, to ensure they are supporting the same interface.

## Usage

To implement a new platform-specific implementation of `pro_video_player`, extend [`ProVideoPlayerPlatform`](lib/s../pro_video_player_platform.dart) with an implementation that performs the platform-specific behavior.

Most platforms can extend [`MethodChannelBase`](lib/src/method_channel_base.dart) which provides a shared method channel implementation.

## Key Types

### Video Sources
- `VideoSource` - Represents a video source (network, file, asset, playlist)
- `Playlist` - A collection of video sources for sequential playback

### Player Options
- `VideoPlayerOptions` - Configuration options for the player including:
  - Playback: `autoPlay`, `looping`, `volume`, `playbackSpeed`
  - ABR (Adaptive Bitrate): `abrMode`, `minBitrate`, `maxBitrate`
  - Features: `allowPip`, `allowBackgroundPlayback`, `subtitlesEnabled`
  - Subtitles: `showSubtitlesByDefault`, `preferredSubtitleLanguage`, `subtitleStyle`

### ABR Configuration
- `AbrMode` - Adaptive bitrate selection mode (`auto` or `manual`)
- Options work with HLS and DASH adaptive streams
- Platform support varies (see main package README)

### Events and State
- `VideoPlayerEvent` - Events emitted by the player
- `VideoPlayerValue` - Current player state
- `PlaybackState` - Playback status enum

### Tracks
- `AudioTrack` - Audio track metadata
- `SubtitleTrack` - Embedded subtitle track
- `ExternalSubtitleTrack` - External subtitle file
- `VideoQualityTrack` - Video quality/bitrate option

## For Maintainers

See [`CLAUDE.md`](../CLAUDE.md) for development guidelines and architecture details.
