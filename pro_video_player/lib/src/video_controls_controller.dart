import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show ChangeNotifier, ValueNotifier, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey, SystemChrome, SystemUiMode;
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'controls/dialogs/audio_picker_dialog.dart';
import 'controls/dialogs/chapters_picker_dialog.dart';
import 'controls/dialogs/keyboard_shortcuts_dialog.dart';
import 'controls/dialogs/orientation_lock_picker_dialog.dart';
import 'controls/dialogs/quality_picker_dialog.dart';
import 'controls/dialogs/scaling_mode_picker_dialog.dart';
import 'controls/dialogs/speed_picker_dialog.dart';
import 'controls/dialogs/subtitle_picker_dialog.dart';
import 'controls/video_controls_utils.dart';
import 'pro_video_player_controller.dart';
import 'video_controls_state.dart';
import 'video_player_theme.dart';
import 'video_toolbar_manager.dart';

/// Controller for managing video player controls state and behavior.
///
/// This class handles all state management, event handling, and business logic
/// for video player controls, separating concerns from the presentation layer.
///
/// The controller manages:
/// - Controls visibility and auto-hide behavior
/// - Keyboard shortcuts and mouse interactions
/// - Fullscreen transitions
/// - Platform-specific features (PiP, background playback, casting)
/// - Drag/seek state during user interactions
class VideoControlsController extends ChangeNotifier {
  /// Creates a video controls controller.
  VideoControlsController({
    required ProVideoPlayerController videoController,
    required this.autoHide,
    required this.autoHideDuration,
    required this.enableKeyboardShortcuts,
    required this.keyboardSeekDuration,
    required this.enableContextMenu,
    required this.minimalToolbarOnDesktop,
    required this.showFullscreenButton,
    required this.showPipButton,
    required this.showBackgroundPlaybackButton,
    required this.showSubtitleButton,
    required this.showAudioButton,
    required this.showQualityButton,
    required this.showSpeedButton,
    required this.speedOptions,
    required this.scalingModeOptions,
    required this.onEnterFullscreen,
    required this.onExitFullscreen,
    required this.fullscreenOrientation,
    this.onShowKeyboardShortcuts,
    this.enablePipCheck = true,
    this.enableBackgroundCheck = true,
    this.enableCastingCheck = true,
    bool? testIsPipAvailable,
    bool? testIsBackgroundPlaybackSupported,
    bool? testIsCastingSupported,
  }) : _videoController = videoController {
    _videoController.addListener(_onPlayerValueChanged);
    _resetHideTimer();

    // Use test values if provided (test-only path)
    if (testIsPipAvailable != null) {
      _controlsState.setIsPipAvailable(available: testIsPipAvailable);
    } else if (enablePipCheck) {
      unawaited(_checkPipAvailability());
    }

    if (testIsBackgroundPlaybackSupported != null) {
      _controlsState.setIsBackgroundPlaybackSupported(supported: testIsBackgroundPlaybackSupported);
    } else if (enableBackgroundCheck) {
      unawaited(_checkBackgroundPlaybackSupport());
    }

    if (testIsCastingSupported != null) {
      _controlsState.setIsCastingSupported(supported: testIsCastingSupported);
    } else if (enableCastingCheck) {
      unawaited(_checkCastingSupport());
    }
  }

  final ProVideoPlayerController _videoController;

  /// Whether to automatically hide controls when playing.
  final bool autoHide;

  /// Duration before controls are hidden when [autoHide] is enabled.
  final Duration autoHideDuration;

  /// Whether to enable keyboard shortcuts on desktop platforms.
  final bool enableKeyboardShortcuts;

  /// Duration to seek when using keyboard arrow keys.
  final Duration keyboardSeekDuration;

  /// Whether to enable right-click context menu.
  final bool enableContextMenu;

  /// Whether to use minimal toolbar on desktop platforms.
  final bool minimalToolbarOnDesktop;

  /// Whether to show the fullscreen button.
  final bool showFullscreenButton;

  /// Whether to show the Picture-in-Picture button.
  final bool showPipButton;

  /// Whether to show the background playback toggle button.
  final bool showBackgroundPlaybackButton;

  /// Whether to show the subtitle selection button.
  final bool showSubtitleButton;

  /// Whether to show the audio track selection button.
  final bool showAudioButton;

  /// Whether to show the video quality selection button.
  final bool showQualityButton;

  /// Whether to show the playback speed button.
  final bool showSpeedButton;

  /// Available playback speed options.
  final List<double> speedOptions;

  /// Available scaling mode options.
  final List<VideoScalingMode> scalingModeOptions;

  /// Callback invoked when fullscreen mode is entered.
  final VoidCallback? onEnterFullscreen;

  /// Callback invoked when fullscreen mode is exited.
  final VoidCallback? onExitFullscreen;

  /// Preferred screen orientation when entering fullscreen.
  final FullscreenOrientation fullscreenOrientation;

  /// Callback invoked when the user presses the "?" key to show keyboard shortcuts.
  final VoidCallback? onShowKeyboardShortcuts;

  /// Whether to check PiP availability asynchronously.
  ///
  /// This should only be set to false in tests to avoid async issues.
  @visibleForTesting
  final bool enablePipCheck;

  /// Whether to check background playback support asynchronously.
  ///
  /// This should only be set to false in tests to avoid async issues.
  @visibleForTesting
  final bool enableBackgroundCheck;

  /// Whether to check casting support asynchronously.
  ///
  /// This should only be set to false in tests to avoid async issues.
  @visibleForTesting
  final bool enableCastingCheck;

  // State
  late final VideoControlsState _controlsState = VideoControlsState();
  final FocusNode _focusNode = FocusNode();

  // Notifiers for reactive UI
  final ValueNotifier<Duration?> _dragStartPosition = ValueNotifier(null);
  final ValueNotifier<Duration?> _gestureSeekPosition = ValueNotifier(null);

  // Track previous volume for mute/unmute toggle
  double _previousVolume = 1;

  // Track whether video was playing before dragging started
  bool _wasPlayingBeforeDrag = false;

  /// The video player controller.
  ProVideoPlayerController get videoController => _videoController;

  /// The controls state.
  VideoControlsState get controlsState => _controlsState;

  /// Focus node for keyboard shortcuts.
  FocusNode get focusNode => _focusNode;

  /// Current drag start position notifier.
  ValueNotifier<Duration?> get dragStartPosition => _dragStartPosition;

  /// Current drag start position value.
  Duration? get dragStartPositionValue => _dragStartPosition.value;

  /// Current gesture seek position notifier.
  ValueNotifier<Duration?> get gestureSeekPosition => _gestureSeekPosition;

  /// Current gesture seek position value.
  Duration? get gestureSeekPositionValue => _gestureSeekPosition.value;

  /// Whether the current platform is desktop (macOS, Windows, Linux, or web).
  bool get isDesktopPlatform {
    if (kIsWeb) return true;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Whether the volume button should be shown.
  bool get shouldShowVolumeButton =>
      VideoToolbarManager.shouldShowVolumeButton(isWeb: kIsWeb, isMacOS: !kIsWeb && Platform.isMacOS);

  Future<void> _checkPipAvailability() async {
    if (!showPipButton) return;
    final available = await _videoController.isPipAvailable();
    _controlsState.setIsPipAvailable(available: available);
  }

  Future<void> _checkBackgroundPlaybackSupport() async {
    if (!showBackgroundPlaybackButton) return;
    final supported = await _videoController.isBackgroundPlaybackSupported();
    _controlsState.setIsBackgroundPlaybackSupported(supported: supported);
  }

  Future<void> _checkCastingSupport() async {
    final supported = await _videoController.isCastingSupported();
    _controlsState.setIsCastingSupported(supported: supported);
  }

  void _onPlayerValueChanged() {
    final isPlaying = _videoController.value.isPlaying;
    final isCasting = _videoController.value.isCasting;
    final isFullscreen = _videoController.value.isFullscreen;
    final isPipActive = _videoController.value.isPipActive;

    // Track state changes that should trigger listener notifications
    var stateChanged = false;

    // During casting, always ensure controls are visible
    if (isCasting && !_controlsState.visible) {
      _controlsState.showControls();
      notifyListeners();
      return;
    }

    // Reset hide timer when play/pause state changes
    if (_controlsState.lastIsPlaying != isPlaying) {
      _controlsState.lastIsPlaying = isPlaying;
      _resetHideTimer();
    }

    // Notify listeners when fullscreen state changes
    if (_controlsState.lastIsFullscreen != isFullscreen) {
      _controlsState.lastIsFullscreen = isFullscreen;
      stateChanged = true;
    }

    // Notify listeners when PiP state changes
    if (_controlsState.lastIsPipActive != isPipActive) {
      _controlsState.lastIsPipActive = isPipActive;
      stateChanged = true;
    }

    if (stateChanged) {
      notifyListeners();
    }
  }

  void _resetHideTimer() {
    _controlsState.cancelHideTimer();
    final isCasting = _videoController.value.isCasting;

    // During casting, always show controls (no auto-hide)
    if (isCasting) {
      if (!_controlsState.visible) {
        _controlsState.showControls();
        notifyListeners();
      }
      return;
    }

    // When mouse is hovering over controls area (desktop), keep controls visible
    if (_controlsState.isMouseOverControls) {
      if (!_controlsState.visible) {
        _controlsState.showControls();
        notifyListeners();
      }
      return;
    }

    if (autoHide && _videoController.value.isPlaying && !_controlsState.isDragging) {
      _controlsState.startHideTimer(autoHideDuration, () {
        if (_videoController.value.isPlaying &&
            !_videoController.value.isCasting &&
            !_controlsState.isMouseOverControls &&
            !_controlsState.isDragging) {
          _controlsState.hideControls();
          notifyListeners();
        }
      });
    } else if (!_videoController.value.isPlaying) {
      // When video is paused, show controls
      if (!_controlsState.visible) {
        _controlsState.showControls();
        notifyListeners();
      }
    }
  }

  /// Resets the auto-hide timer (called from UI on user interaction).
  void resetHideTimer() {
    _resetHideTimer();
  }

  /// Shows controls.
  void showControls() {
    _controlsState
      ..showControls()
      ..setFullyVisible(fullyVisible: true);
    notifyListeners();
  }

  /// Hides controls.
  void hideControls() {
    _controlsState.hideControls();
    notifyListeners();
  }

  /// Toggles controls visibility.
  void toggleControlsVisibility() {
    _controlsState.toggleVisibility();
    if (_controlsState.visible) {
      _controlsState.setFullyVisible(fullyVisible: true);
    }
    notifyListeners();
  }

  /// Handles mouse hover on desktop platforms.
  void onMouseHover() {
    if (!_controlsState.visible) {
      _controlsState
        ..showControls()
        ..setFullyVisible(fullyVisible: true);
      notifyListeners();
    }
    _resetHideTimer();
  }

  /// Sets mouse over controls state.
  void setMouseOverControls({required bool isOver}) {
    _controlsState.setMouseOverControls(isOver: isOver);
    notifyListeners();
  }

  /// Shows keyboard overlay for feedback (public API for external components).
  void showKeyboardOverlay(KeyboardOverlayType type, double value) {
    _controlsState.showKeyboardOverlay(type, value, const Duration(milliseconds: 800), () {
      _controlsState.hideKeyboardOverlay();
    });
    // Notify listeners to show overlay
    notifyListeners();
  }

  /// Shows keyboard overlay for feedback (internal use).
  void _showKeyboardOverlay(KeyboardOverlayType type, double value) {
    showKeyboardOverlay(type, value);
  }

  /// Starts dragging.
  void startDragging() {
    _controlsState.startDragging();
    _dragStartPosition.value = _videoController.value.position;

    // Pause video during seek if it's currently playing
    _wasPlayingBeforeDrag = _videoController.value.isPlaying;
    if (_wasPlayingBeforeDrag) {
      unawaited(_videoController.pause());
    }

    notifyListeners();
  }

  /// Ends dragging.
  void endDragging() {
    _controlsState.endDragging();
    _dragStartPosition.value = null;

    // Resume playback only if video was playing before drag started
    if (_wasPlayingBeforeDrag) {
      unawaited(_videoController.play());
      _wasPlayingBeforeDrag = false;
    }

    notifyListeners();
  }

  /// Toggles time display format.
  void toggleTimeDisplay() {
    _controlsState.toggleTimeDisplay();
    notifyListeners();
  }

  /// Sets gesture seek position.
  set gestureSeekPositionValue(Duration? position) {
    _gestureSeekPosition.value = position;
  }

  /// Sets drag start position.
  set dragStartPositionValue(Duration? position) {
    _dragStartPosition.value = position;
  }

  /// Handles keyboard events for video player shortcuts.
  ///
  /// Works on all platforms including mobile devices with keyboards
  /// (tablets with keyboard cases, Bluetooth keyboards, etc.).
  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!enableKeyboardShortcuts) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isKeyDown = event is KeyDownEvent;
    final isKeyRepeat = event is KeyRepeatEvent;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Arrow keys: handle both key down and key repeat (for holding)
    if (isKeyDown || isKeyRepeat) {
      // Left Arrow: Seek backward (Shift = longer jump)
      if (key == LogicalKeyboardKey.arrowLeft) {
        final seekAmount = isShiftPressed ? keyboardSeekDuration * 3 : keyboardSeekDuration;
        final position = _videoController.value.position;
        final newPosition = position - seekAmount;
        unawaited(_videoController.seekTo(newPosition.isNegative ? Duration.zero : newPosition));
        _showKeyboardOverlay(KeyboardOverlayType.seek, -seekAmount.inSeconds.toDouble());
        _resetHideTimer();
        return KeyEventResult.handled;
      }

      // Right Arrow: Seek forward (Shift = longer jump)
      if (key == LogicalKeyboardKey.arrowRight) {
        final seekAmount = isShiftPressed ? keyboardSeekDuration * 3 : keyboardSeekDuration;
        final position = _videoController.value.position;
        final duration = _videoController.value.duration;
        final newPosition = position + seekAmount;
        unawaited(_videoController.seekTo(newPosition > duration ? duration : newPosition));
        _showKeyboardOverlay(KeyboardOverlayType.seek, seekAmount.inSeconds.toDouble());
        _resetHideTimer();
        return KeyEventResult.handled;
      }

      // Up Arrow: Increase volume / Shift+Up: Increase playback speed
      if (key == LogicalKeyboardKey.arrowUp) {
        if (isShiftPressed) {
          final currentSpeed = _videoController.value.playbackSpeed;
          final newSpeed = (currentSpeed + 0.25).clamp(0.25, 2.0);
          unawaited(_videoController.setPlaybackSpeed(newSpeed));
          _showKeyboardOverlay(KeyboardOverlayType.speed, newSpeed);
        } else {
          final currentVolume = _videoController.value.volume;
          final newVolume = (currentVolume + 0.05).clamp(0.0, 1.0);
          unawaited(_videoController.setVolume(newVolume));
          _showKeyboardOverlay(KeyboardOverlayType.volume, newVolume);
        }
        _resetHideTimer();
        return KeyEventResult.handled;
      }

      // Down Arrow: Decrease volume / Shift+Down: Decrease playback speed
      if (key == LogicalKeyboardKey.arrowDown) {
        if (isShiftPressed) {
          final currentSpeed = _videoController.value.playbackSpeed;
          final newSpeed = (currentSpeed - 0.25).clamp(0.25, 2.0);
          unawaited(_videoController.setPlaybackSpeed(newSpeed));
          _showKeyboardOverlay(KeyboardOverlayType.speed, newSpeed);
        } else {
          final currentVolume = _videoController.value.volume;
          final newVolume = (currentVolume - 0.05).clamp(0.0, 1.0);
          unawaited(_videoController.setVolume(newVolume));
          _showKeyboardOverlay(KeyboardOverlayType.volume, newVolume);
        }
        _resetHideTimer();
        return KeyEventResult.handled;
      }
    }

    // Only handle key down for toggle actions (not repeat)
    if (!isKeyDown) {
      return KeyEventResult.ignored;
    }

    // Space: Toggle play/pause
    if (key == LogicalKeyboardKey.space) {
      if (_videoController.value.isPlaying) {
        unawaited(_videoController.pause());
      } else {
        unawaited(_videoController.play());
      }
      _resetHideTimer();
      return KeyEventResult.handled;
    }

    // M: Toggle mute
    if (key == LogicalKeyboardKey.keyM) {
      final currentVolume = _videoController.value.volume;
      if (currentVolume > 0) {
        // Mute: save current volume and set to 0
        _previousVolume = currentVolume;
        unawaited(_videoController.setVolume(0));
      } else {
        // Unmute: restore previous volume
        unawaited(_videoController.setVolume(_previousVolume));
      }
      _resetHideTimer();
      return KeyEventResult.handled;
    }

    // ?: Show keyboard shortcuts help
    if (key == LogicalKeyboardKey.slash && isShiftPressed) {
      onShowKeyboardShortcuts?.call();
      return KeyEventResult.handled;
    }

    // F and Escape keys are handled by the widget for fullscreen
    // (skipped here because they require navigation/routing)

    // Media keys: Play/Pause
    if (key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause) {
      if (_videoController.value.isPlaying) {
        unawaited(_videoController.pause());
      } else {
        unawaited(_videoController.play());
      }
      _resetHideTimer();
      return KeyEventResult.handled;
    }

    // Media keys: Stop
    if (key == LogicalKeyboardKey.mediaStop) {
      unawaited(_videoController.pause());
      unawaited(_videoController.seekTo(Duration.zero));
      _resetHideTimer();
      return KeyEventResult.handled;
    }

    // Media keys: Next/Previous track (for playlists)
    if (key == LogicalKeyboardKey.mediaTrackNext) {
      if (_videoController.value.playlist != null) {
        unawaited(_videoController.playlistNext());
      }
      _resetHideTimer();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.mediaTrackPrevious) {
      if (_videoController.value.playlist != null) {
        unawaited(_videoController.playlistPrevious());
      }
      _resetHideTimer();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Shows context menu at the given position.
  Future<void> showContextMenu({
    required BuildContext context,
    required Offset position,
    required VideoPlayerTheme theme,
    required VoidCallback onEnterFullscreenCallback,
    required VoidCallback onExitFullscreenCallback,
  }) async {
    if (!enableContextMenu || !isDesktopPlatform) return;

    _controlsState.lastContextMenuPosition = position;
    final value = _videoController.value;
    final isPlaying = value.isPlaying;
    final isMuted = value.volume == 0;
    final currentSpeed = value.playbackSpeed;
    final hasSubtitles = value.subtitleTracks.isNotEmpty;
    final hasAudioTracks = value.audioTracks.length > 1;
    final hasQualityTracks = value.qualityTracks.length > 1;
    final hasChapters = value.chapters.isNotEmpty;
    final hasPlaylist = value.playlist != null;
    final isMinimalMode = minimalToolbarOnDesktop;

    final selectedValue = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        // Basic playback controls
        PopupMenuItem<String>(
          value: 'play_pause',
          child: Row(
            children: [
              Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 20),
              const SizedBox(width: 12),
              Text(isPlaying ? 'Pause' : 'Play'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'mute',
          child: Row(
            children: [
              Icon(isMuted ? Icons.volume_up : Icons.volume_off, size: 20),
              const SizedBox(width: 12),
              Text(isMuted ? 'Unmute' : 'Mute'),
            ],
          ),
        ),

        // Track selection options (when in minimal mode or tracks available)
        if (isMinimalMode && (hasSubtitles || hasAudioTracks || hasQualityTracks || hasChapters)) ...[
          const PopupMenuDivider(),
          if (hasSubtitles && showSubtitleButton)
            PopupMenuItem<String>(
              value: 'subtitles',
              child: Row(
                children: [
                  const Icon(Icons.closed_caption, size: 20),
                  const SizedBox(width: 12),
                  Text('Subtitles${value.selectedSubtitleTrack != null ? ' (On)' : ''}'),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          if (hasAudioTracks && showAudioButton)
            const PopupMenuItem<String>(
              value: 'audio',
              child: Row(
                children: [
                  Icon(Icons.audiotrack, size: 20),
                  SizedBox(width: 12),
                  Text('Audio Track'),
                  Spacer(),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          if (hasQualityTracks && showQualityButton)
            const PopupMenuItem<String>(
              value: 'quality',
              child: Row(
                children: [
                  Icon(Icons.high_quality, size: 20),
                  SizedBox(width: 12),
                  Text('Quality'),
                  Spacer(),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          if (hasChapters)
            const PopupMenuItem<String>(
              value: 'chapters',
              child: Row(
                children: [
                  Icon(Icons.list, size: 20),
                  SizedBox(width: 12),
                  Text('Chapters'),
                  Spacer(),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
        ],

        // Speed submenu
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'speed',
          child: Row(
            children: [
              const Icon(Icons.speed, size: 20),
              const SizedBox(width: 12),
              Text('Speed (${currentSpeed}x)'),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),

        // PiP and Fullscreen
        if (isMinimalMode && _controlsState.isPipAvailable && showPipButton || showFullscreenButton) ...[
          const PopupMenuDivider(),
          if (isMinimalMode && _controlsState.isPipAvailable && showPipButton)
            PopupMenuItem<String>(
              value: 'pip',
              child: Row(
                children: [
                  Icon(value.isPipActive ? Icons.picture_in_picture_alt : Icons.picture_in_picture, size: 20),
                  const SizedBox(width: 12),
                  Text(value.isPipActive ? 'Exit Picture-in-Picture' : 'Picture-in-Picture'),
                ],
              ),
            ),
          if (showFullscreenButton)
            PopupMenuItem<String>(
              value: 'fullscreen',
              child: Row(
                children: [
                  Icon(value.isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, size: 20),
                  const SizedBox(width: 12),
                  Text(value.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen'),
                ],
              ),
            ),
        ],

        // Playlist controls (when in minimal mode and playlist exists)
        if (isMinimalMode && hasPlaylist) ...[
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'playlist_previous',
            child: Row(children: [Icon(Icons.skip_previous, size: 20), SizedBox(width: 12), Text('Previous')]),
          ),
          const PopupMenuItem<String>(
            value: 'playlist_next',
            child: Row(children: [Icon(Icons.skip_next, size: 20), SizedBox(width: 12), Text('Next')]),
          ),
          PopupMenuItem<String>(
            value: 'shuffle',
            child: Row(
              children: [
                Icon(Icons.shuffle, size: 20, color: value.isShuffled ? theme.primaryColor : null),
                const SizedBox(width: 12),
                Text('Shuffle${value.isShuffled ? ' (On)' : ''}'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'repeat',
            child: Row(
              children: [
                Icon(
                  value.playlistRepeatMode == PlaylistRepeatMode.one ? Icons.repeat_one : Icons.repeat,
                  size: 20,
                  color: value.playlistRepeatMode != PlaylistRepeatMode.none ? theme.primaryColor : null,
                ),
                const SizedBox(width: 12),
                Text('Repeat${VideoControlsUtils.getRepeatModeLabel(value.playlistRepeatMode)}'),
              ],
            ),
          ),
        ],

        // Keyboard shortcuts help
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'keyboard_shortcuts',
          child: Row(children: [Icon(Icons.help_outline, size: 20), SizedBox(width: 12), Text('Keyboard Shortcuts')]),
        ),
      ],
    );

    if (selectedValue == null || !context.mounted) return;

    switch (selectedValue) {
      case 'play_pause':
        if (isPlaying) {
          unawaited(_videoController.pause());
        } else {
          unawaited(_videoController.play());
        }
      case 'mute':
        unawaited(_videoController.setVolume(isMuted ? 1 : 0));
      case 'subtitles':
        if (context.mounted) showSubtitlePicker(context: context, theme: theme);
      case 'audio':
        if (context.mounted) showAudioPicker(context: context, theme: theme);
      case 'quality':
        if (context.mounted) showQualityPicker(context: context, theme: theme);
      case 'chapters':
        if (context.mounted) showChaptersPicker(context: context, theme: theme);
      case 'speed':
        if (context.mounted) showSpeedPicker(context: context, theme: theme);
      case 'pip':
        if (value.isPipActive) {
          unawaited(_videoController.exitPip());
        } else {
          unawaited(_videoController.enterPip());
        }
      case 'fullscreen':
        if (value.isFullscreen) {
          onExitFullscreenCallback();
        } else {
          onEnterFullscreenCallback();
        }
      case 'playlist_previous':
        unawaited(_videoController.playlistPrevious());
      case 'playlist_next':
        unawaited(_videoController.playlistNext());
      case 'shuffle':
        _videoController.setPlaylistShuffle(enabled: !value.isShuffled);
      case 'repeat':
        final nextMode = VideoControlsUtils.getNextRepeatMode(value.playlistRepeatMode);
        _videoController.setPlaylistRepeatMode(nextMode);
      case 'keyboard_shortcuts':
        if (context.mounted) {
          KeyboardShortcutsDialog.show(context: context, theme: theme);
        }
    }
    _resetHideTimer();
  }

  /// Updates system UI visibility for fullscreen mode.
  Future<void> updateSystemUiForFullscreen() async {
    // Only manage system UI in fullscreen mode on mobile platforms
    if (!_videoController.value.isFullscreen) return;
    if (kIsWeb || isDesktopPlatform) return;

    if (_controlsState.visible) {
      // Show system UI when controls are visible
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      // Hide system UI when controls are hidden (leanBack uses fade animation)
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    }
  }

  /// Shows orientation lock picker dialog.
  void showOrientationLockPicker({required BuildContext context, required VideoPlayerTheme theme}) {
    OrientationLockPickerDialog.show(context: context, controller: _videoController, theme: theme);
  }

  /// Shows quality picker dialog.
  void showQualityPicker({required BuildContext context, required VideoPlayerTheme theme}) {
    QualityPickerDialog.show(
      context: context,
      controller: _videoController,
      theme: theme,
      lastContextMenuPosition: _controlsState.lastContextMenuPosition,
      onDismiss: _resetHideTimer,
    );
  }

  /// Shows audio picker dialog.
  void showAudioPicker({required BuildContext context, required VideoPlayerTheme theme}) {
    AudioPickerDialog.show(
      context: context,
      controller: _videoController,
      theme: theme,
      lastContextMenuPosition: _controlsState.lastContextMenuPosition,
      onDismiss: _resetHideTimer,
    );
  }

  /// Shows chapters picker dialog.
  void showChaptersPicker({required BuildContext context, required VideoPlayerTheme theme}) {
    ChaptersPickerDialog.show(context: context, controller: _videoController, theme: theme);
  }

  /// Shows scaling mode picker dialog.
  void showScalingModePicker({required BuildContext context, required VideoPlayerTheme theme}) {
    ScalingModePickerDialog.show(
      context: context,
      controller: _videoController,
      theme: theme,
      scalingModeOptions: scalingModeOptions,
      onDismiss: _resetHideTimer,
    );
  }

  /// Shows subtitle picker dialog.
  void showSubtitlePicker({required BuildContext context, required VideoPlayerTheme theme}) {
    SubtitlePickerDialog.show(
      context: context,
      controller: _videoController,
      theme: theme,
      lastContextMenuPosition: _controlsState.lastContextMenuPosition,
      onDismiss: _resetHideTimer,
    );
  }

  /// Shows speed picker dialog.
  void showSpeedPicker({required BuildContext context, required VideoPlayerTheme theme}) {
    SpeedPickerDialog.show(
      context: context,
      controller: _videoController,
      theme: theme,
      speedOptions: speedOptions,
      lastContextMenuPosition: _controlsState.lastContextMenuPosition,
      onDismiss: _resetHideTimer,
    );
  }

  @override
  void dispose() {
    _videoController.removeListener(_onPlayerValueChanged);
    _controlsState.dispose();
    _focusNode.dispose();
    _dragStartPosition.dispose();
    _gestureSeekPosition.dispose();
    super.dispose();
  }
}
