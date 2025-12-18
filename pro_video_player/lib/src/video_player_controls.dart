import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'controls/compact_layout.dart';
import 'controls/controls_enums.dart';
import 'controls/desktop_video_controls.dart';
import 'controls/dialogs/keyboard_shortcuts_dialog.dart';
import 'controls/fullscreen_page.dart';
import 'controls/mobile_video_controls.dart';
import 'controls/seek_preview.dart';
import 'controls/wrappers/desktop_controls_wrapper.dart';
import 'controls/wrappers/gesture_controls_wrapper.dart';
import 'controls/wrappers/simple_tap_wrapper.dart';
import 'pro_video_player_controller.dart';
import 'subtitle_overlay.dart';
import 'video_controls_controller.dart';
import 'video_player_theme.dart';

export 'controls/controls_enums.dart';

/// A cross-platform Flutter widget that provides intuitive video controls.
///
/// This widget provides a feature-rich video player interface with:
/// - Gesture controls (double-tap to seek, swipe for volume/brightness)
/// - Auto-hiding overlay controls
/// - Play/pause, seek slider, and time display
/// - Fullscreen toggle (optional)
/// - Volume and brightness controls
/// - Buffering indicator
/// - Themeable appearance
///
/// ## Example
///
/// Basic usage with default theme:
///
/// ```dart
/// ProVideoPlayer(
///   controller: _controller,
///   controlsBuilder: (context, controller) => VideoPlayerControls(
///     controller: controller,
///   ),
/// )
/// ```
///
/// With custom theme:
///
/// ```dart
/// VideoPlayerThemeData(
///   theme: VideoPlayerTheme.light(),
///   child: ProVideoPlayer(
///     controller: _controller,
///     controlsBuilder: (context, controller) => VideoPlayerControls(
///       controller: controller,
///     ),
///   ),
/// )
/// ```
class VideoPlayerControls extends StatefulWidget {
  /// Creates video player controls with an intuitive interface.
  ///
  /// The [controller] must be initialized before the widget is built.
  ///
  /// The [theme] parameter allows customization of colors and styles. If not
  /// provided, uses the theme from [VideoPlayerThemeData] or a default theme.
  const VideoPlayerControls({
    required this.controller,
    super.key,
    this.theme,
    this.subtitleStyle,
    this.renderSubtitlesInternally = true,
    this.showFullscreenButton = true,
    this.showOrientationLockButton = true,
    this.showSkipButtons = true,
    this.skipDuration = const Duration(seconds: 10),
    this.seekSecondsPerInch = 20.0,
    this.showSpeedButton = true,
    this.speedOptions = const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
    this.showSubtitleButton = true,
    this.showAudioButton = true,
    this.showPipButton = true,
    this.showScalingModeButton = true,
    this.scalingModeOptions = const [VideoScalingMode.fit, VideoScalingMode.fill, VideoScalingMode.stretch],
    this.showQualityButton = true,
    this.showBackgroundPlaybackButton = true,
    this.enableGestures = true,
    this.enableDoubleTapSeek = true,
    this.enableVolumeGesture = true,
    this.enableBrightnessGesture = true,
    this.enableSeekGesture = true,
    this.enablePlaybackSpeedGesture = true,
    this.autoHide = true,
    this.autoHideDuration = const Duration(seconds: 2),
    this.liveScrubbingMode = LiveScrubbingMode.adaptive,
    this.onBrightnessChanged,
    this.compactMode = CompactMode.auto,
    // 250x180 threshold accommodates narrow screens like Z Fold 3 front display (~260dp)
    this.compactThreshold = const Size(250, 180),
    this.playerToolbarActions,
    this.maxPlayerToolbarActions,
    this.autoOverflowActions = true,
    this.onEnterFullscreen,
    this.onExitFullscreen,
    this.fullscreenOrientation = FullscreenOrientation.landscapeBoth,
    this.enableKeyboardShortcuts = true,
    this.keyboardSeekDuration = const Duration(seconds: 5),
    this.enableSeekBarHoverPreview = true,
    this.enableContextMenu = true,
    this.minimalToolbarOnDesktop = true,
    this.onDismiss,
    this.forceMobileLayout = false, // Test-only: force mobile layout even on desktop
    this.testIsPipAvailable,
    this.testIsBackgroundPlaybackSupported,
    this.testIsCastingSupported,
  });

  /// The video player controller.
  final ProVideoPlayerController controller;

  /// Optional theme override. If null, uses theme from [VideoPlayerThemeData].
  final VideoPlayerTheme? theme;

  /// Optional subtitle style configuration.
  ///
  /// Controls the appearance of subtitles rendered by [SubtitleOverlay],
  /// including text color, font size, background color, stroke/outline,
  /// position (top/middle/bottom), and text alignment (left/center/right).
  ///
  /// If null, uses default subtitle styling from [SubtitleStyle].
  ///
  /// See [SubtitleStyle] for available customization options.
  final SubtitleStyle? subtitleStyle;

  /// Whether to render subtitles within this controls widget.
  ///
  /// When `false`, subtitles are rendered at the parent widget level
  /// (ProVideoPlayer), allowing them to appear independently of controls.
  /// This is used internally to support subtitle rendering across all layout modes.
  ///
  /// When `true`, subtitles are rendered as part of the controls overlay stack.
  ///
  /// Defaults to `true` for backwards compatibility.
  final bool renderSubtitlesInternally;

  /// Whether to show the fullscreen button.
  ///
  /// Defaults to `true`.
  final bool showFullscreenButton;

  /// Whether to show the orientation lock button in fullscreen mode.
  ///
  /// When enabled, a button appears in the fullscreen toolbar that opens
  /// a bottom sheet allowing users to lock the screen orientation
  /// (Auto-rotate, Landscape, Landscape Left, or Landscape Right).
  ///
  /// Defaults to `true`.
  final bool showOrientationLockButton;

  /// Whether to show skip forward/backward buttons.
  ///
  /// Defaults to `true`.
  final bool showSkipButtons;

  /// Duration to skip when skip buttons are tapped.
  ///
  /// Defaults to 10 seconds. Common values are 5, 10, or 30 seconds.
  /// The button icons will change based on this value (e.g., replay_5,
  /// replay_10, replay_30).
  final Duration skipDuration;

  /// How many seconds to seek per inch of horizontal swipe gesture.
  ///
  /// This controls the sensitivity of the horizontal swipe seek gesture
  /// based on physical distance, ensuring consistent behavior across
  /// devices with different screen densities.
  ///
  /// For example, with the default of 20 seconds per inch, swiping
  /// 0.5 inches will seek 10 seconds, regardless of video duration.
  ///
  /// Defaults to 20 seconds per inch.
  final double seekSecondsPerInch;

  /// Whether to show the playback speed button.
  ///
  /// Defaults to `true`.
  final bool showSpeedButton;

  /// Available playback speed options.
  ///
  /// Defaults to `[0.5, 0.75, 1.0, 1.25, 1.5, 2.0]`.
  final List<double> speedOptions;

  /// Whether to show the subtitle selection button.
  ///
  /// The button only appears when subtitle tracks are available.
  /// Defaults to `true`.
  final bool showSubtitleButton;

  /// Whether to show the audio track selection button.
  ///
  /// The button only appears when multiple audio tracks are available.
  /// Defaults to `true`.
  final bool showAudioButton;

  /// Whether to show the Picture-in-Picture button.
  ///
  /// The button only appears when PiP is supported on the device and
  /// [VideoPlayerOptions.allowPip] is `true`.
  /// Defaults to `true`.
  final bool showPipButton;

  /// Whether to show the scaling mode button.
  ///
  /// Allows users to change how the video fills the viewport (fit, fill, stretch).
  /// Defaults to `true`.
  final bool showScalingModeButton;

  /// Available scaling mode options.
  ///
  /// Defaults to `[VideoScalingMode.fit, VideoScalingMode.fill, VideoScalingMode.stretch]`.
  final List<VideoScalingMode> scalingModeOptions;

  /// Whether to show the video quality selection button.
  ///
  /// The button only appears when quality tracks are available (for adaptive streams).
  /// Defaults to `true`.
  final bool showQualityButton;

  /// Whether to show the background playback toggle button.
  ///
  /// The button only appears when background playback is configured in [VideoPlayerOptions]
  /// and the platform supports it (iOS, Android).
  ///
  /// **Note:** This button is always hidden on:
  /// - **macOS**: Background playback is enabled by default and cannot be toggled.
  /// - **Web**: Background playback is not supported.
  ///
  /// Defaults to `true`.
  final bool showBackgroundPlaybackButton;

  /// Whether to enable gesture controls.
  ///
  /// Defaults to `true`.
  final bool enableGestures;

  /// Whether to enable double-tap to seek gestures.
  ///
  /// Defaults to `true`.
  final bool enableDoubleTapSeek;

  /// Whether to enable volume control gestures (vertical swipe on right).
  ///
  /// Defaults to `true`.
  final bool enableVolumeGesture;

  /// Whether to enable brightness control gestures (vertical swipe on left).
  ///
  /// Defaults to `true`.
  final bool enableBrightnessGesture;

  /// Whether to enable seek gestures (horizontal swipe).
  ///
  /// Defaults to `true`.
  final bool enableSeekGesture;

  /// Whether to enable playback speed gestures (two-finger vertical swipe).
  ///
  /// Defaults to `true`.
  final bool enablePlaybackSpeedGesture;

  /// Whether to automatically hide controls when playing.
  ///
  /// Defaults to `true`.
  final bool autoHide;

  /// Duration before controls are hidden when [autoHide] is enabled.
  ///
  /// Defaults to 3 seconds.
  final Duration autoHideDuration;

  /// Controls when live scrubbing is enabled for the seek bar.
  ///
  /// Live scrubbing updates the video position immediately as the user drags
  /// the progress bar, providing real-time feedback. Different modes optimize
  /// performance based on the video source type and buffering state.
  ///
  /// See [LiveScrubbingMode] for available modes and their behavior.
  ///
  /// Defaults to [LiveScrubbingMode.adaptive] (recommended for most apps).
  final LiveScrubbingMode liveScrubbingMode;

  /// Callback when brightness is changed via gesture.
  final ValueChanged<double>? onBrightnessChanged;

  /// Controls when compact mode is enabled.
  ///
  /// Compact mode shows a simplified UI with only essential controls:
  /// - Center play/pause button
  /// - Simple progress bar (no time display)
  /// - No player toolbar buttons
  /// - Gestures are disabled (except tap to play/pause)
  ///
  /// Defaults to [CompactMode.auto], which enables compact mode when
  /// the player size falls below [compactThreshold].
  final CompactMode compactMode;

  /// Size threshold for automatic compact mode.
  ///
  /// When [compactMode] is [CompactMode.auto], compact mode is enabled
  /// if either the width or height falls below this threshold.
  ///
  /// Defaults to 250x180 pixels, which accommodates narrow screens like
  /// the Samsung Z Fold front display (~260dp wide).
  final Size compactThreshold;

  /// Specifies which actions to show in the player toolbar and their order.
  ///
  /// When provided, only the specified actions will be shown, in the order
  /// they appear in this list. Actions that don't meet their visibility
  /// conditions (e.g., subtitles without tracks) are automatically hidden.
  ///
  /// When `null` (default), all applicable actions are shown in the default
  /// order based on the `show*` properties (e.g., [showSpeedButton]).
  ///
  /// Example:
  /// ```dart
  /// VideoPlayerControls(
  ///   controller: controller,
  ///   playerToolbarActions: [
  ///     PlayerToolbarAction.subtitles,
  ///     PlayerToolbarAction.speed,
  ///     PlayerToolbarAction.fullscreen,
  ///   ],
  /// )
  /// ```
  final List<PlayerToolbarAction>? playerToolbarActions;

  /// Maximum number of actions to show directly in the player toolbar.
  ///
  /// When the number of visible actions exceeds this limit, the remaining
  /// actions are moved to an overflow menu (⋮ button).
  ///
  /// When `null` (default), the toolbar uses [autoOverflowActions] to determine
  /// whether to automatically calculate the maximum based on available width.
  ///
  /// Example:
  /// ```dart
  /// VideoPlayerControls(
  ///   controller: controller,
  ///   playerToolbarActions: [
  ///     PlayerToolbarAction.subtitles,
  ///     PlayerToolbarAction.audio,
  ///     PlayerToolbarAction.quality,
  ///     PlayerToolbarAction.speed,
  ///     PlayerToolbarAction.fullscreen,
  ///   ],
  ///   maxPlayerToolbarActions: 3, // First 3 visible, rest in overflow
  /// )
  /// ```
  final int? maxPlayerToolbarActions;

  /// Whether to automatically move toolbar actions to overflow when they don't fit.
  ///
  /// When `true` (default), the toolbar measures available width and automatically
  /// moves actions that don't fit into an overflow menu (⋮ button).
  ///
  /// When `false`, all actions are shown directly (may cause overflow on narrow screens).
  ///
  /// This is ignored when [maxPlayerToolbarActions] is explicitly set.
  final bool autoOverflowActions;

  /// Callback invoked when fullscreen mode is entered.
  ///
  /// If provided, this callback is responsible for showing the fullscreen UI.
  /// If not provided, the controls will automatically push a fullscreen route.
  ///
  /// Example for custom fullscreen handling:
  /// ```dart
  /// VideoPlayerControls(
  ///   controller: controller,
  ///   onEnterFullscreen: () {
  ///     Navigator.of(context).push(
  ///       MaterialPageRoute(
  ///         builder: (_) => MyFullscreenPlayer(controller: controller),
  ///       ),
  ///     );
  ///   },
  /// )
  /// ```
  final VoidCallback? onEnterFullscreen;

  /// Callback invoked when fullscreen mode is exited.
  ///
  /// If provided, this callback is responsible for closing the fullscreen UI.
  /// If not provided, the controls will automatically pop the fullscreen route.
  final VoidCallback? onExitFullscreen;

  /// Callback invoked when the dismiss button is tapped in fullscreen-only mode.
  ///
  /// When [VideoPlayerOptions.fullscreenOnly] is `true` and this callback is
  /// provided, a close button (X) appears in the top-left corner of the player.
  /// Tapping this button invokes the callback, allowing the app to navigate
  /// away from the player screen.
  ///
  /// This is useful for dedicated video player apps that need a way to dismiss
  /// the player while keeping the fullscreen-only behavior (no exit-to-windowed).
  final VoidCallback? onDismiss;

  /// Force mobile layout even on desktop platforms.
  ///
  /// This is primarily for testing to avoid desktop-specific gesture wrappers.
  /// Defaults to `false`.
  final bool forceMobileLayout;

  /// Test-only: Directly inject PiP availability instead of checking asynchronously.
  ///
  /// When provided, bypasses async PiP check for testing.
  /// This is not @visibleForTesting because it's passed to VideoControlsController.
  final bool? testIsPipAvailable;

  /// Test-only: Directly inject background playback support instead of checking asynchronously.
  ///
  /// When provided, bypasses async background check for testing.
  /// This is not @visibleForTesting because it's passed to VideoControlsController.
  final bool? testIsBackgroundPlaybackSupported;

  /// Test-only: Directly inject casting support instead of checking asynchronously.
  ///
  /// When provided, bypasses async casting check for testing.
  /// This is not @visibleForTesting because it's passed to VideoControlsController.
  final bool? testIsCastingSupported;

  /// Preferred screen orientation when entering fullscreen.
  ///
  /// Defaults to [FullscreenOrientation.landscapeBoth].
  final FullscreenOrientation fullscreenOrientation;

  /// Whether to enable keyboard shortcuts on desktop and web platforms.
  ///
  /// When enabled, the following shortcuts are available:
  /// - **Space**: Toggle play/pause
  /// - **Left Arrow**: Seek backward by [keyboardSeekDuration]
  /// - **Right Arrow**: Seek forward by [keyboardSeekDuration]
  /// - **Up Arrow**: Increase volume by 10%
  /// - **Down Arrow**: Decrease volume by 10%
  /// - **M**: Toggle mute
  /// - **F**: Toggle fullscreen
  ///
  /// Defaults to `true`.
  final bool enableKeyboardShortcuts;

  /// Duration to seek when using keyboard arrow keys.
  ///
  /// Defaults to 5 seconds.
  final Duration keyboardSeekDuration;

  /// Whether to show time preview on seek bar hover (desktop/web only).
  ///
  /// When enabled, hovering over the seek bar shows a tooltip with the
  /// time at that position. This only applies to desktop and web platforms
  /// where mouse hover is available.
  ///
  /// Defaults to `true`.
  final bool enableSeekBarHoverPreview;

  /// Whether to enable right-click context menu on desktop and web platforms.
  ///
  /// When enabled, right-clicking on the video shows a context menu with
  /// quick actions like play/pause, mute, fullscreen, and playback speed.
  ///
  /// Defaults to `true`.
  final bool enableContextMenu;

  /// Whether to use minimal toolbar on desktop and web platforms.
  ///
  /// When enabled, the toolbar shows only essential controls:
  /// - Play/pause button
  /// - Progress bar with time display
  /// - Volume slider (on the right)
  ///
  /// All other options (subtitles, audio, quality, speed, PiP, fullscreen,
  /// etc.) are available via right-click context menu.
  ///
  /// This provides a cleaner interface common in desktop video players.
  /// Mobile platforms are not affected by this setting.
  ///
  /// Defaults to `true`.
  final bool minimalToolbarOnDesktop;

  @override
  State<VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<VideoPlayerControls> {
  late final VideoControlsController _controlsController;

  @override
  void initState() {
    super.initState();

    // Create the controller with all configuration
    _controlsController = VideoControlsController(
      videoController: widget.controller,
      autoHide: widget.autoHide,
      autoHideDuration: widget.autoHideDuration,
      enableKeyboardShortcuts: widget.enableKeyboardShortcuts,
      keyboardSeekDuration: widget.keyboardSeekDuration,
      enableContextMenu: widget.enableContextMenu,
      minimalToolbarOnDesktop: widget.minimalToolbarOnDesktop,
      showFullscreenButton: widget.showFullscreenButton,
      showPipButton: widget.showPipButton,
      showBackgroundPlaybackButton: widget.showBackgroundPlaybackButton,
      showSubtitleButton: widget.showSubtitleButton,
      showAudioButton: widget.showAudioButton,
      showQualityButton: widget.showQualityButton,
      showSpeedButton: widget.showSpeedButton,
      speedOptions: widget.speedOptions,
      scalingModeOptions: widget.scalingModeOptions,
      onEnterFullscreen: widget.onEnterFullscreen,
      onExitFullscreen: widget.onExitFullscreen,
      fullscreenOrientation: widget.fullscreenOrientation,
      testIsPipAvailable: widget.testIsPipAvailable,
      testIsBackgroundPlaybackSupported: widget.testIsBackgroundPlaybackSupported,
      testIsCastingSupported: widget.testIsCastingSupported,
      onShowKeyboardShortcuts: () {
        if (mounted) {
          KeyboardShortcutsDialog.show(context: context, theme: widget.theme ?? const VideoPlayerTheme());
        }
      },
    );

    // Listen to controller changes to trigger rebuilds
    _controlsController.addListener(_onControllerChanged);

    // Auto-enter fullscreen if fullscreenOnly mode is enabled
    if (widget.controller.options.fullscreenOnly && !widget.controller.value.isFullscreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enterFullscreen();
      });
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        // Controller state changed, rebuild UI
      });
    }
  }

  @override
  void dispose() {
    _controlsController
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoPlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If controller changed, we would need to recreate _controlsController
    // For now, we assume controller doesn't change during widget lifetime
  }

  /// Returns true if running on a desktop platform.
  bool get _isDesktopPlatform => _controlsController.isDesktopPlatform;

  /// Determines if compact mode should be active based on the given constraints.
  bool _isCompactMode(BoxConstraints constraints) {
    switch (widget.compactMode) {
      case CompactMode.never:
        return false;
      case CompactMode.always:
        return true;
      case CompactMode.auto:
        // Check if player is in PiP mode
        if (widget.controller.value.isPipActive) {
          return true;
        }
        // Check if size is below threshold
        return constraints.maxWidth < widget.compactThreshold.width ||
            constraints.maxHeight < widget.compactThreshold.height;
    }
  }

  void _enterFullscreen() {
    if (widget.onEnterFullscreen != null) {
      // Use custom fullscreen handler
      widget.onEnterFullscreen!();
    } else {
      // Default: push fullscreen route
      _pushFullscreenRoute();
    }
  }

  void _exitFullscreen() {
    // Block exit if fullscreenOnly mode is enabled
    if (widget.controller.options.fullscreenOnly) return;

    if (widget.onExitFullscreen != null) {
      // Use custom fullscreen exit handler
      widget.onExitFullscreen!();
    } else {
      // Default: pop fullscreen route and exit fullscreen
      if (_isDesktopPlatform) {
        widget.controller.setFlutterFullscreenState(isFullscreen: false);
        unawaited(ProVideoPlayerPlatform.instance.setWindowFullscreen(fullscreen: false));
      } else {
        unawaited(widget.controller.exitFullscreen());
      }
      unawaited(Navigator.of(context).maybePop());
    }
  }

  void _pushFullscreenRoute() {
    unawaited(
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          barrierColor: Colors.black,
          pageBuilder: (context, animation, secondaryAnimation) => FullscreenVideoPage(
            controller: widget.controller,
            theme: widget.theme,
            subtitleStyle: widget.subtitleStyle,
            onDismiss: widget.onDismiss,
            onExitFullscreen: () {
              if (_isDesktopPlatform) {
                widget.controller.setFlutterFullscreenState(isFullscreen: false);
                unawaited(ProVideoPlayerPlatform.instance.setWindowFullscreen(fullscreen: false));
              } else {
                unawaited(widget.controller.exitFullscreen());
              }
              unawaited(Navigator.of(context).maybePop());
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
    );

    // Enter fullscreen
    if (_isDesktopPlatform) {
      widget.controller.setFlutterFullscreenState(isFullscreen: true);
      unawaited(ProVideoPlayerPlatform.instance.setWindowFullscreen(fullscreen: true));
    } else {
      unawaited(widget.controller.enterFullscreen(orientation: widget.fullscreenOrientation));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? VideoPlayerThemeData.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // In PiP mode, hide all Flutter controls
        final isPipActive = widget.controller.value.isPipActive;
        if (isPipActive) {
          if (widget.renderSubtitlesInternally) {
            return SubtitleOverlay(controller: widget.controller, style: widget.subtitleStyle);
          }
          return const SizedBox.shrink();
        }

        // In fullscreenOnly mode, hide controls until fullscreen is active
        final isFullscreenOnly = widget.controller.options.fullscreenOnly;
        final isFullscreen = widget.controller.value.isFullscreen;
        if (isFullscreenOnly && !isFullscreen) {
          return const ColoredBox(
            color: Colors.black,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final isCompact = _isCompactMode(constraints);

        // Build controls content
        final controlsContent = isCompact
            ? CompactLayout(controller: widget.controller, theme: theme)
            : _buildFullControls(theme);

        // Wrap controls in animated opacity overlay
        final controlsOverlay = Positioned.fill(
          child: AnimatedOpacity(
            opacity: _controlsController.controlsState.visible ? 1.0 : 0.0,
            // Hide instantly (no animation) during gestures, normal animation otherwise
            duration: _controlsController.controlsState.hideInstantly
                ? Duration.zero
                : const Duration(milliseconds: 100),
            onEnd: () {
              if (mounted) {
                setState(() {
                  _controlsController.controlsState.setFullyVisible(
                    fullyVisible: _controlsController.controlsState.visible,
                  );
                });
                // Sync system UI visibility
                unawaited(_controlsController.updateSystemUiForFullscreen());
              }
            },
            child: IgnorePointer(ignoring: !_controlsController.controlsState.isFullyVisible, child: controlsContent),
          ),
        );

        // Build stack with subtitles and controls
        final stackContent = Stack(
          children: [
            const SizedBox.expand(),
            if (widget.renderSubtitlesInternally)
              SubtitleOverlay(controller: widget.controller, style: widget.subtitleStyle),
            controlsOverlay,
          ],
        );

        // Wrap with appropriate gesture handler based on platform and settings
        if (_isDesktopPlatform && !widget.forceMobileLayout) {
          return DesktopControlsWrapper(
            controller: widget.controller,
            controlsController: _controlsController,
            theme: theme,
            showFullscreenButton: widget.showFullscreenButton,
            onEnterFullscreen: _enterFullscreen,
            onExitFullscreen: _exitFullscreen,
            child: stackContent,
          );
        }

        if (widget.enableGestures && !isCompact) {
          return GestureControlsWrapper(
            controller: widget.controller,
            controlsController: _controlsController,
            skipDuration: widget.skipDuration,
            seekSecondsPerInch: widget.seekSecondsPerInch,
            enableDoubleTapSeek: widget.enableDoubleTapSeek,
            enableVolumeGesture: widget.enableVolumeGesture,
            enableBrightnessGesture: widget.enableBrightnessGesture,
            enableSeekGesture: widget.enableSeekGesture,
            enablePlaybackSpeedGesture: widget.enablePlaybackSpeedGesture,
            autoHide: widget.autoHide,
            autoHideDuration: widget.autoHideDuration,
            onBrightnessChanged: widget.onBrightnessChanged,
            child: stackContent,
          );
        }

        return SimpleTapWrapper(
          controller: widget.controller,
          controlsController: _controlsController,
          child: stackContent,
        );
      },
    );
  }

  /// Builds the full controls layout.
  Widget _buildFullControls(VideoPlayerTheme theme) {
    if (_isDesktopPlatform && !widget.forceMobileLayout) {
      return DesktopVideoControls(
        controller: widget.controller,
        theme: theme,
        controlsState: _controlsController.controlsState,
        gestureSeekPosition: _controlsController.gestureSeekPosition.value,
        dragStartPosition: _controlsController.dragStartPosition.value,
        minimalToolbarOnDesktop: widget.minimalToolbarOnDesktop,
        shouldShowVolumeButton: _controlsController.shouldShowVolumeButton,
        liveScrubbingMode: widget.liveScrubbingMode,
        enableSeekBarHoverPreview: widget.enableSeekBarHoverPreview,
        showFullscreenButton: widget.showFullscreenButton,
        onDragStart: () => setState(_controlsController.startDragging),
        onDragEnd: () => setState(_controlsController.endDragging),
        onToggleTimeDisplay: () => setState(_controlsController.toggleTimeDisplay),
        onMouseEnter: () => setState(() => _controlsController.setMouseOverControls(isOver: true)),
        onMouseExit: () => setState(() => _controlsController.setMouseOverControls(isOver: false)),
        onResetHideTimer: _controlsController.resetHideTimer,
        onFullscreenEnter: _enterFullscreen,
        onFullscreenExit: _exitFullscreen,
      );
    }

    // Mobile layout
    return MobileVideoControls(
      controller: widget.controller,
      theme: theme,
      controlsState: _controlsController.controlsState,
      gestureSeekPosition: _controlsController.gestureSeekPosition.value,
      showSkipButtons: widget.showSkipButtons,
      skipDuration: widget.skipDuration,
      liveScrubbingMode: widget.liveScrubbingMode,
      showSeekBarHoverPreview: widget.enableSeekBarHoverPreview,
      showSubtitleButton: widget.showSubtitleButton,
      showAudioButton: widget.showAudioButton,
      showQualityButton: widget.showQualityButton,
      showSpeedButton: widget.showSpeedButton,
      showScalingModeButton: widget.showScalingModeButton,
      showBackgroundPlaybackButton: widget.showBackgroundPlaybackButton,
      showPipButton: widget.showPipButton,
      showOrientationLockButton: widget.showOrientationLockButton,
      showFullscreenButton: widget.showFullscreenButton,
      playerToolbarActions: widget.playerToolbarActions,
      maxPlayerToolbarActions: widget.maxPlayerToolbarActions,
      autoOverflowActions: widget.autoOverflowActions,
      onDismiss: widget.onDismiss,
      isDesktopPlatform: _isDesktopPlatform,
      onDragStart: () => setState(_controlsController.startDragging),
      onDragEnd: () => setState(_controlsController.endDragging),
      onToggleTimeDisplay: () => setState(_controlsController.toggleTimeDisplay),
      onShowQualityPicker: (context, theme) => _controlsController.showQualityPicker(context: context, theme: theme),
      onShowSubtitlePicker: (context, theme) => _controlsController.showSubtitlePicker(context: context, theme: theme),
      onShowAudioPicker: (context, theme) => _controlsController.showAudioPicker(context: context, theme: theme),
      onShowChaptersPicker: (context, theme) => _controlsController.showChaptersPicker(context: context, theme: theme),
      onShowSpeedPicker: (context, theme) => _controlsController.showSpeedPicker(context: context, theme: theme),
      onShowScalingModePicker: (theme) => _controlsController.showScalingModePicker(context: context, theme: theme),
      onShowOrientationLockPicker: (theme) =>
          _controlsController.showOrientationLockPicker(context: context, theme: theme),
      onFullscreenEnter: _enterFullscreen,
      onFullscreenExit: _exitFullscreen,
      centerControls: _buildCenterControls(theme),
    );
  }

  Widget _buildCenterControls(VideoPlayerTheme theme) => Expanded(
    child: Center(
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: widget.controller,
        builder: (context, value, child) {
          if (_controlsController.controlsState.isDragging &&
              _controlsController.controlsState.dragProgress != null &&
              _controlsController.dragStartPosition.value != null) {
            return SeekPreview(
              dragProgress: _controlsController.controlsState.dragProgress!,
              dragStartPosition: _controlsController.dragStartPosition.value!,
              duration: value.duration,
              theme: theme,
            );
          }
          if (value.playbackState == PlaybackState.buffering) {
            return CircularProgressIndicator(color: theme.primaryColor);
          }
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}
