import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

void main() {
  group('VideoToolbarManager', () {
    group('shouldShowVolumeButton', () {
      test('returns true on web platform', () {
        expect(VideoToolbarManager.shouldShowVolumeButton(isWeb: true, isMacOS: false), isTrue);
      });

      test('returns true on macOS platform', () {
        expect(VideoToolbarManager.shouldShowVolumeButton(isWeb: false, isMacOS: true), isTrue);
      });

      test('returns false on other platforms', () {
        expect(VideoToolbarManager.shouldShowVolumeButton(isWeb: false, isMacOS: false), isFalse);
      });
    });

    group('getActionLabel', () {
      test('returns correct labels for all actions', () {
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.shuffle), 'Shuffle');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.repeatMode), 'Repeat');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.subtitles), 'Subtitles');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.audio), 'Audio');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.chapters), 'Chapters');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.quality), 'Quality');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.speed), 'Speed');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.scalingMode), 'Scaling');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.backgroundPlayback), 'Background');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.pip), 'Picture-in-Picture');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.casting), 'Cast');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.orientationLock), 'Orientation');
        expect(VideoToolbarManager.getActionLabel(PlayerToolbarAction.fullscreen), 'Fullscreen');
      });
    });

    group('getActionIcon', () {
      test('returns shuffle icon based on state', () {
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.shuffle,
            isShuffled: true,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.shuffle_on,
        );
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.shuffle,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.shuffle,
        );
      });

      test('returns repeat icon based on mode', () {
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.repeatMode,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.one,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.repeat_one,
        );
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.repeatMode,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.all,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.repeat,
        );
      });

      test('returns subtitle icon based on selection state', () {
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.subtitles,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: true,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.closed_caption,
        );
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.subtitles,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.closed_caption_off,
        );
      });

      test('returns background playback icon based on state', () {
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.backgroundPlayback,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: true,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.headphones,
        );
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.backgroundPlayback,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.headphones_outlined,
        );
      });

      test('returns casting icon based on state', () {
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.casting,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: true,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.cast_connected,
        );
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.casting,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.cast,
        );
      });

      test('returns orientation lock icon based on state', () {
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.orientationLock,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: true,
            isFullscreen: false,
          ),
          Icons.screen_lock_rotation,
        );
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.orientationLock,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.screen_rotation,
        );
      });

      test('returns fullscreen icon based on state', () {
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.fullscreen,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: true,
          ),
          Icons.fullscreen_exit,
        );
        expect(
          VideoToolbarManager.getActionIcon(
            PlayerToolbarAction.fullscreen,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          ),
          Icons.fullscreen,
        );
      });

      test('returns static icons for actions without state dependency', () {
        const staticActions = [
          PlayerToolbarAction.audio,
          PlayerToolbarAction.chapters,
          PlayerToolbarAction.quality,
          PlayerToolbarAction.speed,
          PlayerToolbarAction.scalingMode,
          PlayerToolbarAction.pip,
        ];

        for (final action in staticActions) {
          final icon = VideoToolbarManager.getActionIcon(
            action,
            isShuffled: false,
            playlistRepeatMode: PlaylistRepeatMode.none,
            hasSelectedSubtitle: false,
            isBackgroundPlaybackEnabled: false,
            isCasting: false,
            isOrientationLocked: false,
            isFullscreen: false,
          );
          expect(icon, isA<IconData>());
        }
      });
    });

    group('shouldShowAction', () {
      test('shows shuffle and repeat mode only when playlist exists', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.shuffle,
            config: const ToolbarConfig(),
            state: const ToolbarState(hasPlaylist: true),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.shuffle,
            config: const ToolbarConfig(),
            state: const ToolbarState(),
          ),
          isFalse,
        );
      });

      test('shows subtitles only when enabled and tracks available', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.subtitles,
            config: const ToolbarConfig(),
            state: const ToolbarState(hasSubtitleTracks: true),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.subtitles,
            config: const ToolbarConfig(showSubtitleButton: false),
            state: const ToolbarState(hasSubtitleTracks: true),
          ),
          isFalse,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.subtitles,
            config: const ToolbarConfig(),
            state: const ToolbarState(),
          ),
          isFalse,
        );
      });

      test('shows audio only when enabled and multiple tracks available', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.audio,
            config: const ToolbarConfig(),
            state: const ToolbarState(audioTrackCount: 2),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.audio,
            config: const ToolbarConfig(),
            state: const ToolbarState(audioTrackCount: 1),
          ),
          isFalse,
        );
      });

      test('shows chapters only when chapters available', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.chapters,
            config: const ToolbarConfig(),
            state: const ToolbarState(hasChapters: true),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.chapters,
            config: const ToolbarConfig(),
            state: const ToolbarState(),
          ),
          isFalse,
        );
      });

      test('hides quality when casting', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.quality,
            config: const ToolbarConfig(),
            state: const ToolbarState(qualityTrackCount: 2),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.quality,
            config: const ToolbarConfig(),
            state: const ToolbarState(qualityTrackCount: 2, isCasting: true),
          ),
          isFalse,
        );
      });

      test('hides speed when casting', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.speed,
            config: const ToolbarConfig(),
            state: const ToolbarState(),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.speed,
            config: const ToolbarConfig(),
            state: const ToolbarState(isCasting: true),
          ),
          isFalse,
        );
      });

      test('hides scaling mode when casting', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.scalingMode,
            config: const ToolbarConfig(showScalingModeButton: true),
            state: const ToolbarState(),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.scalingMode,
            config: const ToolbarConfig(showScalingModeButton: true),
            state: const ToolbarState(isCasting: true),
          ),
          isFalse,
        );
      });

      test('hides background playback on desktop and when casting', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.backgroundPlayback,
            config: const ToolbarConfig(),
            state: const ToolbarState(isBackgroundPlaybackSupported: true),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.backgroundPlayback,
            config: const ToolbarConfig(),
            state: const ToolbarState(isBackgroundPlaybackSupported: true, isDesktopPlatform: true),
          ),
          isFalse,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.backgroundPlayback,
            config: const ToolbarConfig(),
            state: const ToolbarState(isBackgroundPlaybackSupported: true, isCasting: true),
          ),
          isFalse,
        );
      });

      test('hides PiP when casting', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.pip,
            config: const ToolbarConfig(),
            state: const ToolbarState(isPipAvailable: true),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.pip,
            config: const ToolbarConfig(),
            state: const ToolbarState(isPipAvailable: true, isCasting: true),
          ),
          isFalse,
        );
      });

      test('shows casting when supported', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.casting,
            config: const ToolbarConfig(),
            state: const ToolbarState(isCastingSupported: true),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.casting,
            config: const ToolbarConfig(),
            state: const ToolbarState(),
          ),
          isFalse,
        );
      });

      test('shows orientation lock only in fullscreen and not when casting', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.orientationLock,
            config: const ToolbarConfig(),
            state: const ToolbarState(isFullscreen: true),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.orientationLock,
            config: const ToolbarConfig(),
            state: const ToolbarState(),
          ),
          isFalse,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.orientationLock,
            config: const ToolbarConfig(),
            state: const ToolbarState(isFullscreen: true, isCasting: true),
          ),
          isFalse,
        );
      });

      test('hides fullscreen when casting or when in fullscreenOnly mode and fullscreen', () {
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.fullscreen,
            config: const ToolbarConfig(),
            state: const ToolbarState(),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.fullscreen,
            config: const ToolbarConfig(),
            state: const ToolbarState(isCasting: true),
          ),
          isFalse,
        );
        // fullscreenOnly mode: show button before fullscreen (to enter), hide once in fullscreen (can't exit)
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.fullscreen,
            config: const ToolbarConfig(fullscreenOnly: true),
            state: const ToolbarState(),
          ),
          isTrue,
        );
        expect(
          VideoToolbarManager.shouldShowAction(
            PlayerToolbarAction.fullscreen,
            config: const ToolbarConfig(fullscreenOnly: true),
            state: const ToolbarState(isFullscreen: true),
          ),
          isFalse,
        );
      });
    });

    group('getDefaultToolbarActions', () {
      test('returns empty list when all buttons are disabled', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(
            showSubtitleButton: false,
            showAudioButton: false,
            showQualityButton: false,
            showSpeedButton: false,
            showBackgroundPlaybackButton: false,
            showPipButton: false,
            showOrientationLockButton: false,
            showFullscreenButton: false,
          ),
          state: const ToolbarState(),
        );
        expect(actions, isEmpty);
      });

      test('includes casting first when supported', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(),
          state: const ToolbarState(isCastingSupported: true),
        );
        expect(actions.first, PlayerToolbarAction.casting);
      });

      test('includes playlist actions when playlist exists', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(),
          state: const ToolbarState(hasPlaylist: true),
        );
        expect(actions, contains(PlayerToolbarAction.shuffle));
        expect(actions, contains(PlayerToolbarAction.repeatMode));
      });

      test('includes subtitles when enabled and tracks available', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(),
          state: const ToolbarState(hasSubtitleTracks: true),
        );
        expect(actions, contains(PlayerToolbarAction.subtitles));
      });

      test('includes audio when enabled and multiple tracks available', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(),
          state: const ToolbarState(audioTrackCount: 2),
        );
        expect(actions, contains(PlayerToolbarAction.audio));
      });

      test('includes quality when enabled and multiple tracks available', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(),
          state: const ToolbarState(qualityTrackCount: 2),
        );
        expect(actions, contains(PlayerToolbarAction.quality));
      });

      test('includes speed when enabled', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(),
          state: const ToolbarState(),
        );
        expect(actions, contains(PlayerToolbarAction.speed));
      });

      test('includes scaling mode when enabled', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(showScalingModeButton: true),
          state: const ToolbarState(),
        );
        expect(actions, contains(PlayerToolbarAction.scalingMode));
      });

      test('includes background playback when enabled and supported on mobile', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(),
          state: const ToolbarState(isBackgroundPlaybackSupported: true),
        );
        expect(actions, contains(PlayerToolbarAction.backgroundPlayback));
      });

      test('includes PiP when enabled and available', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(),
          state: const ToolbarState(isPipAvailable: true),
        );
        expect(actions, contains(PlayerToolbarAction.pip));
      });

      test('includes orientation lock when enabled and in fullscreen', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(),
          state: const ToolbarState(isFullscreen: true),
        );
        expect(actions, contains(PlayerToolbarAction.orientationLock));
      });

      test('includes fullscreen when enabled', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(),
          state: const ToolbarState(),
        );
        expect(actions, contains(PlayerToolbarAction.fullscreen));
      });

      test('returns actions in expected order', () {
        final actions = VideoToolbarManager.getDefaultToolbarActions(
          config: const ToolbarConfig(showScalingModeButton: true),
          state: const ToolbarState(
            isCastingSupported: true,
            hasPlaylist: true,
            hasSubtitleTracks: true,
            audioTrackCount: 2,
            qualityTrackCount: 2,
            isBackgroundPlaybackSupported: true,
            isPipAvailable: true,
            isFullscreen: true,
          ),
        );

        // Casting should be first
        expect(actions.first, PlayerToolbarAction.casting);
        // Fullscreen should be last
        expect(actions.last, PlayerToolbarAction.fullscreen);
      });
    });

    group('isNonOverflowableAction', () {
      test('returns true for casting action', () {
        expect(VideoToolbarManager.isNonOverflowableAction(PlayerToolbarAction.casting), isTrue);
      });

      test('returns false for all other actions', () {
        const overflowableActions = [
          PlayerToolbarAction.shuffle,
          PlayerToolbarAction.repeatMode,
          PlayerToolbarAction.subtitles,
          PlayerToolbarAction.audio,
          PlayerToolbarAction.chapters,
          PlayerToolbarAction.quality,
          PlayerToolbarAction.speed,
          PlayerToolbarAction.scalingMode,
          PlayerToolbarAction.backgroundPlayback,
          PlayerToolbarAction.pip,
          PlayerToolbarAction.orientationLock,
          PlayerToolbarAction.fullscreen,
        ];

        for (final action in overflowableActions) {
          expect(VideoToolbarManager.isNonOverflowableAction(action), isFalse);
        }
      });
    });
  });
}
