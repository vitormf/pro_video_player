import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_video_player/pro_video_player.dart';

import 'home_screen.dart';

/// Player screen with full video controls.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({required this.videoPath, this.openedExternally = false, super.key});

  final String videoPath;

  /// Whether the video was opened from outside the app (via intent/file association).
  /// When true, dismiss will exit the app. When false, dismiss returns to home screen.
  final bool openedExternally;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late ProVideoPlayerController _controller;
  bool _initialized = false;
  bool _disposed = false;
  bool _playbackStarted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    _controller.addListener(_onPlayerValueChanged);
    unawaited(_initializePlayer());
  }

  void _onPlayerValueChanged() {
    // Show player as soon as player ID is assigned (player view can render)
    if (!_initialized && _controller.playerId != null) {
      setState(() => _initialized = true);
      // Start playback after the platform view has had time to render
      _startPlaybackAfterRender();
    }
  }

  void _startPlaybackAfterRender() {
    if (_playbackStarted || _disposed) return;
    _playbackStarted = true;

    // Wait for the next frame to ensure the platform view is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_disposed) {
        unawaited(_controller.play());
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      final source = _isUrl(widget.videoPath)
          ? VideoSource.network(widget.videoPath)
          : VideoSource.file(widget.videoPath);

      // Only use fullscreenOnly on mobile (iOS/Android), not on macOS
      final isMobile = Platform.isIOS || Platform.isAndroid;

      // Initialize WITHOUT autoPlay - we'll start playback after the platform view renders
      await _controller.initialize(
        source: source,
        options: VideoPlayerOptions(fullscreenOnly: isMobile, fullscreenOrientation: FullscreenOrientation.all),
      );

      // Also set initialized here in case the listener didn't catch it
      if (mounted && !_initialized) {
        setState(() => _initialized = true);
        _startPlaybackAfterRender();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  bool _isUrl(String path) =>
      path.startsWith('http://') || path.startsWith('https://') || path.startsWith('content://');

  Future<void> _handleDismiss() async {
    // Stop and dispose the controller before exiting
    if (!_disposed) {
      _disposed = true;
      await _controller.pause();
      await _controller.dispose();
    }

    if (!mounted) return;

    // On iOS, always go to home screen since iOS apps can't close themselves.
    // On Android/macOS, exit the app if opened externally.
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (widget.openedExternally && !isIOS) {
      // Video was opened from outside the app - exit the app
      await SystemNavigator.pop();
    } else {
      // Video was opened from home screen (or iOS) - go back to home
      await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeScreen()));
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerValueChanged);
    if (!_disposed) {
      _disposed = true;
      unawaited(_controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, body: _buildBody());

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load video', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _initialized = false;
                  });
                  unawaited(_initializePlayer());
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Only show dismiss button on mobile (where fullscreenOnly is enabled)
    final isMobile = Platform.isIOS || Platform.isAndroid;

    // Show loading until player ID is assigned
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show player - VideoPlayerControls handles buffering indicator
    return ProVideoPlayer(
      controller: _controller,
      controlsBuilder: isMobile
          ? (context, controller) => VideoPlayerControls(
              controller: controller,
              onDismiss: _handleDismiss,
              fullscreenConfig: const FullscreenConfig(orientation: FullscreenOrientation.all),
            )
          : null,
    );
  }
}
