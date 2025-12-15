import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../utils/responsive_utils.dart';

/// Demonstrates video scaling modes (fit, fill, stretch).
///
/// Shows how video content is displayed when the video's aspect ratio
/// doesn't match the player's aspect ratio.
class ScalingModesScreen extends StatefulWidget {
  const ScalingModesScreen({super.key});

  @override
  State<ScalingModesScreen> createState() => _ScalingModesScreenState();
}

class _ScalingModesScreenState extends State<ScalingModesScreen> {
  late ProVideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  VideoScalingMode _currentMode = VideoScalingMode.fit;

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    try {
      await _controller.initialize(
        source: const VideoSource.network(VideoUrls.bigBuckBunny),
        options: const VideoPlayerOptions(autoPlay: true),
      );
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _setScalingMode(VideoScalingMode mode) async {
    await _controller.setScalingMode(mode);
    setState(() => _currentMode = mode);
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scaling Modes')),
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

  Widget _buildContent() {
    final useSideBySide = ResponsiveUtils.shouldUseSideBySideLayout(context);

    if (useSideBySide) {
      return _buildSideBySideLayout();
    } else {
      return _buildStackedLayout();
    }
  }

  Widget _buildStackedLayout() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Video player in a fixed aspect ratio container
        _buildVideoContainer(),
        const SizedBox(height: 16),
        _buildScalingModeSelector(),
        const SizedBox(height: 16),
        _buildPlaybackControls(),
        const SizedBox(height: 16),
        _buildModeExplanations(),
      ],
    ),
  );

  Widget _buildSideBySideLayout() => LayoutBuilder(
    builder: (context, constraints) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls on the left (40%)
        SizedBox(
          width: constraints.maxWidth * 0.4,
          height: constraints.maxHeight,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildScalingModeSelector(),
                const SizedBox(height: 16),
                _buildPlaybackControls(),
                const SizedBox(height: 16),
                _buildModeExplanations(),
              ],
            ),
          ),
        ),
        // Video player on the right (60%)
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildVideoContainer(maxWidth: constraints.maxWidth * 0.55),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildVideoContainer({double? maxWidth}) {
    final container = Container(
      margin: const EdgeInsets.all(16),
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Force a non-standard aspect ratio to demonstrate scaling
          AspectRatio(
            aspectRatio: 4 / 3, // Different from video's 16:9
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              child: ColoredBox(
                color: Colors.black,
                child: ProVideoPlayer(
                  controller: _controller,
                  placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
            ),
            child: Text(
              'Container: 4:3 | Video: 16:9',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );

    return container;
  }

  Widget _buildScalingModeSelector() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scaling Mode', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<VideoScalingMode>(
          segments: const [
            ButtonSegment(value: VideoScalingMode.fit, label: Text('Fit'), icon: Icon(Icons.fit_screen)),
            ButtonSegment(value: VideoScalingMode.fill, label: Text('Fill'), icon: Icon(Icons.crop)),
            ButtonSegment(value: VideoScalingMode.stretch, label: Text('Stretch'), icon: Icon(Icons.aspect_ratio)),
          ],
          selected: {_currentMode},
          onSelectionChanged: (modes) => _setScalingMode(modes.first),
        ),
      ],
    ),
  );

  Widget _buildPlaybackControls() => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: _controller,
    builder: (context, value, child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Slider(
            value: value.position.inMilliseconds.toDouble(),
            max: value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
            onChanged: (v) => unawaited(_controller.seekTo(Duration(milliseconds: v.toInt()))),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () => unawaited(_controller.seekBackward(const Duration(seconds: 10))),
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 48,
                icon: Icon(value.isPlaying ? Icons.pause_circle : Icons.play_circle),
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

  Widget _buildModeExplanations() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How Scaling Modes Work', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        _ScalingModeCard(
          mode: VideoScalingMode.fit,
          isSelected: _currentMode == VideoScalingMode.fit,
          title: 'Fit (Letterbox)',
          description:
              "Shows the entire video with black bars (letterboxing or pillarboxing) when aspect ratios don't match. No content is cropped.",
          icon: Icons.fit_screen,
          platformNotes: 'iOS: resizeAspect | Android: RESIZE_MODE_FIT | Web: contain',
        ),
        const SizedBox(height: 12),
        _ScalingModeCard(
          mode: VideoScalingMode.fill,
          isSelected: _currentMode == VideoScalingMode.fill,
          title: 'Fill (Crop)',
          description:
              'Fills the entire viewport while maintaining aspect ratio. '
              'Parts of the video may be cropped to fill the space.',
          icon: Icons.crop,
          platformNotes: 'iOS: resizeAspectFill | Android: RESIZE_MODE_ZOOM | Web: cover',
        ),
        const SizedBox(height: 12),
        _ScalingModeCard(
          mode: VideoScalingMode.stretch,
          isSelected: _currentMode == VideoScalingMode.stretch,
          title: 'Stretch',
          description:
              "Stretches the video to completely fill the viewport, potentially distorting the image if aspect ratios don't match.",
          icon: Icons.aspect_ratio,
          platformNotes: 'iOS: resize | Android: RESIZE_MODE_FILL | Web: fill',
        ),
      ],
    ),
  );
}

class _ScalingModeCard extends StatelessWidget {
  const _ScalingModeCard({
    required this.mode,
    required this.isSelected,
    required this.title,
    required this.description,
    required this.icon,
    required this.platformNotes,
  });

  final VideoScalingMode mode;
  final bool isSelected;
  final String title;
  final String description;
  final IconData icon;
  final String platformNotes;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
        width: isSelected ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          platformNotes,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}
