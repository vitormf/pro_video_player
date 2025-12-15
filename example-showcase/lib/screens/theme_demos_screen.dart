import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';
import '../widgets/responsive_video_layout.dart';

/// Screen demonstrating different video player themes.
class ThemeDemosScreen extends StatefulWidget {
  const ThemeDemosScreen({super.key});

  @override
  State<ThemeDemosScreen> createState() => _ThemeDemosScreenState();
}

class _ThemeDemosScreenState extends State<ThemeDemosScreen> {
  late ProVideoPlayerController _controller;
  String _selectedTheme = 'Dark (Default)';

  final Map<String, VideoPlayerTheme> _themes = {
    'Dark (Default)': const VideoPlayerTheme(),
    'Light': VideoPlayerTheme.light(),
    'Christmas': VideoPlayerTheme.christmas(),
    'Halloween': VideoPlayerTheme.halloween(),
    'Custom Purple': const VideoPlayerTheme().copyWith(
      primaryColor: Colors.purple,
      progressBarActiveColor: Colors.purpleAccent,
      backgroundColor: const Color(0xCC1A0033),
    ),
  };

  @override
  void initState() {
    super.initState();
    _controller = ProVideoPlayerController();
    unawaited(_initializePlayer());
  }

  Future<void> _initializePlayer() async {
    await _controller.initialize(
      source: const VideoSource.network(VideoUrls.bigBuckBunny),
      options: const VideoPlayerOptions(autoPlay: true, looping: true),
    );
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Theme Demos')),
    body: ResponsiveVideoLayout(
      videoPlayer: VideoPlayerThemeData(
        theme: _themes[_selectedTheme]!,
        child: ProVideoPlayer(
          controller: _controller,
          controlsBuilder: (context, controller) => VideoPlayerControls(controller: controller),
        ),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Theme selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Theme:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _themes.keys.map((themeName) {
                    final isSelected = themeName == _selectedTheme;
                    return ChoiceChip(
                      label: Text(themeName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedTheme = themeName);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Feature info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gesture Controls:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildGestureInfo('Single tap', 'Show/hide controls'),
                _buildGestureInfo('Double tap left', 'Seek backward 10s'),
                _buildGestureInfo('Double tap center', 'Play/pause'),
                _buildGestureInfo('Double tap right', 'Seek forward 10s'),
                _buildGestureInfo('Swipe left (vertical)', 'Adjust brightness'),
                _buildGestureInfo('Swipe right (vertical)', 'Adjust volume'),
                _buildGestureInfo('Swipe horizontal', 'Seek through video'),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildGestureInfo(String gesture, String action) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        const Icon(Icons.touch_app, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$gesture:', style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        Text(action, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );
}
