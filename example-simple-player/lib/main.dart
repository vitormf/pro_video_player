import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_video_player/pro_video_player.dart';

void main() {
  runApp(const SimplePlayerApp());
}

/// Simple video player app that opens files from the system or URLs.
class SimplePlayerApp extends StatefulWidget {
  const SimplePlayerApp({super.key});

  @override
  State<SimplePlayerApp> createState() => _SimplePlayerAppState();
}

class _SimplePlayerAppState extends State<SimplePlayerApp> {
  static const _fileChannel = MethodChannel('simple_player/file');

  final _navigatorKey = GlobalKey<NavigatorState>();
  String? _pendingVideoPath;

  @override
  void initState() {
    super.initState();
    unawaited(_setupFileChannel());
  }

  Future<void> _setupFileChannel() async {
    _fileChannel.setMethodCallHandler((call) async {
      if (call.method == 'openFile') {
        final path = call.arguments as String;
        _playVideo(path);
      }
    });

    // Check for initial file on cold start
    await _checkInitialFile();
  }

  Future<void> _checkInitialFile() async {
    try {
      final initialFile = await _fileChannel.invokeMethod<String>('getInitialFile');
      if (initialFile != null && initialFile.isNotEmpty) {
        _playVideo(initialFile);
      }
    } on PlatformException {
      // No initial file - that's fine
    }
  }

  void _playVideo(String path) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      // Navigator not ready yet, store for later
      setState(() {
        _pendingVideoPath = path;
      });
      return;
    }

    // Navigator is ready - push replacement to replace current video
    // Use pushAndRemoveUntil to clear the stack and show only the new video
    unawaited(
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => PlayerScreen(videoPath: path, openedExternally: true)),
        (route) => false, // Remove all previous routes
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Simple Player',
    debugShowCheckedModeBanner: false,
    navigatorKey: _navigatorKey,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: _pendingVideoPath != null
        ? PlayerScreen(videoPath: _pendingVideoPath!, openedExternally: true)
        : const HomeScreen(),
  );
}

/// Home screen with options to open a file or URL.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final path = file.path;
      if (path != null && context.mounted) {
        unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerScreen(videoPath: path))));
      }
    }
  }

  Future<void> _openUrl(BuildContext context) async {
    final controller = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Video URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://example.com/video.mp4', border: OutlineInputBorder()),
          keyboardType: TextInputType.url,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Open')),
        ],
      ),
    );

    if (url != null && url.isNotEmpty && context.mounted) {
      unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlayerScreen(videoPath: url))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Simple Player'), centerTitle: true),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.play_circle_outline, size: 120, color: Colors.deepPurple),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => _openFile(context),
                icon: const Icon(Icons.folder_open),
                label: const Text('Open File'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _openUrl(context),
                icon: const Icon(Icons.link),
                label: const Text('Open URL'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
              ),
              const SizedBox(height: 48),
              Text(
                'You can also open videos by:\n'
                '- Selecting "Open With" from other apps\n'
                '- Sharing video files to this app\n'
                '- Double-clicking video files (macOS)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

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
              fullscreenOrientation: FullscreenOrientation.all,
            )
          : null,
    );
  }
}
