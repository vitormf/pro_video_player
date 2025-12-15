import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../widgets/responsive_video_layout.dart';

/// Demonstrates the different layout modes for video player controls.
///
/// This screen showcases:
/// - Video only (no controls)
/// - Native platform controls
/// - Flutter controls widget
/// - Custom user-provided controls
class LayoutModesScreen extends StatefulWidget {
  const LayoutModesScreen({super.key});

  @override
  State<LayoutModesScreen> createState() => _LayoutModesScreenState();
}

class _LayoutModesScreenState extends State<LayoutModesScreen> {
  late ProVideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  _LayoutMode _selectedMode = _LayoutMode.none;

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    try {
      await _controller.initialize(source: const VideoSource.network(VideoUrls.bigBuckBunny));
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Layout Modes')),
    body: _error != null
        ? _buildErrorState()
        : !_isInitialized
        ? const Center(child: CircularProgressIndicator())
        : _buildContent(),
  );

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isInitialized = false;
              });
              unawaited(_initializePlayer());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _buildContent() => ResponsiveVideoLayout(
    videoPlayer: ColoredBox(color: Colors.black, child: _buildPlayerForMode()),
    controls: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // External controls for "none" mode demonstration (right below video)
        if (_selectedMode == _LayoutMode.none) ...[_buildExternalControls(), const Divider(height: 32)],

        // Layout mode selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Layout Mode', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              RadioGroup<_LayoutMode>(
                groupValue: _selectedMode,
                onChanged: (value) {
                  if (value != null) setState(() => _selectedMode = value);
                },
                child: Column(children: _LayoutMode.values.map(_buildModeOption).toList()),
              ),
            ],
          ),
        ),

        const Divider(height: 32),

        // Mode description
        _buildModeDescription(),
      ],
    ),
  );

  Widget _buildPlayerForMode() {
    switch (_selectedMode) {
      case _LayoutMode.none:
        // Video only - no controls overlay
        return ProVideoPlayer(
          controller: _controller,
          controlsMode: ControlsMode.none,
          placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
        );

      case _LayoutMode.native:
        // Native platform controls (AVPlayerViewController on iOS, PlayerView on Android)
        return ProVideoPlayer(
          controller: _controller,
          controlsMode: ControlsMode.native,
          placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
        );

      case _LayoutMode.flutter:
        // Cross-platform Flutter controls widget (this is the default mode)
        return ProVideoPlayer(
          controller: _controller,
          placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
        );

      case _LayoutMode.compact:
        // Compact controls mode - minimal UI for small players
        return ProVideoPlayer(
          controller: _controller,
          controlsBuilder: (context, controller) =>
              VideoPlayerControls(controller: controller, compactMode: CompactMode.always),
          placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
        );

      case _LayoutMode.custom:
        // Custom user-provided controls
        return ProVideoPlayer(
          controller: _controller,
          controlsBuilder: (context, controller) => _CustomControls(controller: controller),
          placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
        );
    }
  }

  Widget _buildModeOption(_LayoutMode mode) => ListTile(
    leading: Radio<_LayoutMode>(value: mode),
    title: Text(mode.title),
    subtitle: Text(mode.subtitle),
    onTap: () => setState(() => _selectedMode = mode),
  );

  Widget _buildModeDescription() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About This Mode', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(_selectedMode.description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _selectedMode.codeExample,
            style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    ),
  );

  Widget _buildExternalControls() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('External Controls', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'When using "Video Only" mode, you can provide your own external controls:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () => unawaited(_controller.seekBackward(const Duration(seconds: 10))),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(value.isPlaying ? 'Pause' : 'Play'),
                onPressed: () => unawaited(_controller.togglePlayPause()),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () => unawaited(_controller.seekForward(const Duration(seconds: 10))),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A custom controls widget demonstrating user-provided controls.
class _CustomControls extends StatelessWidget {
  const _CustomControls({required this.controller});

  final ProVideoPlayerController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: controller,
    builder: (context, value, child) => DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Custom styled progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.amber,
                inactiveTrackColor: Colors.amber.withValues(alpha: 0.3),
                thumbColor: Colors.amber,
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: value.position.inMilliseconds.toDouble(),
                max: value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                onChanged: (newValue) {
                  unawaited(controller.seekTo(Duration(milliseconds: newValue.toInt())));
                },
              ),
            ),
          ),

          // Custom styled controls
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                // Play/Pause with custom styling
                DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
                    onPressed: () => unawaited(controller.togglePlayPause()),
                  ),
                ),

                const SizedBox(width: 12),

                // Time display with custom styling
                Text(
                  '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                ),

                const Spacer(),

                // Custom mute button
                IconButton(
                  icon: Icon(value.volume == 0 ? Icons.volume_off : Icons.volume_up, color: Colors.amber),
                  onPressed: () {
                    unawaited(controller.setVolume(value.volume == 0 ? 1.0 : 0.0));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

enum _LayoutMode {
  none(
    title: 'Video Only',
    subtitle: 'No controls overlay (ControlsMode.none)',
    description:
        'Shows only the video without any controls overlay. Ideal when you want to provide your own external controls or need a clean video display.',
    codeExample: '''
ProVideoPlayer(
  controller: controller,
  controlsMode: ControlsMode.none,
)''',
  ),
  native(
    title: 'Native Controls',
    subtitle: 'Platform-specific controls (ControlsMode.native)',
    description:
        "Uses native platform controls. On iOS, this uses AVPlayerViewController with its native controls. On Android, this uses ExoPlayer's PlayerView with built-in controls. These controls follow platform conventions and feel native to each platform.",
    codeExample: '''
ProVideoPlayer(
  controller: controller,
  controlsMode: ControlsMode.native,
)''',
  ),
  flutter(
    title: 'Flutter Controls',
    subtitle: 'Cross-platform VideoPlayerControls (default)',
    description:
        'Uses the built-in VideoPlayerControls widget that provides a consistent look and feel across all platforms. This is the default mode. Includes play/pause, seek, progress bar, volume, speed, subtitles, and fullscreen controls.',
    codeExample: '''
ProVideoPlayer(
  controller: controller,
  controlsMode: ControlsMode.flutter, // default
)''',
  ),
  compact(
    title: 'Compact Controls',
    subtitle: 'Simplified controls for small players',
    description:
        'A minimal UI optimized for small player sizes and PiP mode. Shows only a centered play/pause button and a simple progress bar. Gestures are disabled. Use CompactMode.auto (default) to automatically switch based on player size, or CompactMode.always to force compact mode.',
    codeExample: '''
VideoPlayerControls(
  controller: controller,
  compactMode: CompactMode.always,
  // Or use auto with threshold:
  // compactMode: CompactMode.auto,
  // compactThreshold: Size(300, 200),
)''',
  ),
  custom(
    title: 'Custom Controls',
    subtitle: 'User-provided controls via controlsBuilder',
    description:
        'Allows you to provide your own custom controls widget using the controlsBuilder parameter. This gives you complete control over the controls UI while the library handles the video rendering.',
    codeExample: '''
ProVideoPlayer(
  controller: controller,
  controlsBuilder: (context, controller) =>
    MyCustomControls(controller: controller),
)''',
  );

  const _LayoutMode({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.codeExample,
  });

  final String title;
  final String subtitle;
  final String description;
  final String codeExample;
}
