import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import '../constants/video_constants.dart';

/// Example demonstrating how developers can create custom themes for the video player.
///
/// This example shows various ways to customize the video player appearance.
class CustomThemeExamplesScreen extends StatefulWidget {
  const CustomThemeExamplesScreen({super.key});

  @override
  State<CustomThemeExamplesScreen> createState() => _CustomThemeExamplesScreenState();
}

class _CustomThemeExamplesScreenState extends State<CustomThemeExamplesScreen> {
  late ProVideoPlayerController _controller;

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
    appBar: AppBar(title: const Text('Custom Theme Examples')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildThemeExample('Brand Colors Theme', 'Customize with your app brand colors', _buildBrandColorTheme()),
        const SizedBox(height: 16),
        _buildThemeExample('Minimalist Theme', 'Clean and simple design', _buildMinimalistTheme()),
        const SizedBox(height: 16),
        _buildThemeExample('Gaming Theme', 'Vibrant colors for gaming apps', _buildGamingTheme()),
        const SizedBox(height: 16),
        _buildCodeExample(),
      ],
    ),
  );

  Widget _buildThemeExample(String title, String description, VideoPlayerTheme theme) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: VideoPlayerThemeData(
              theme: theme,
              child: ProVideoPlayer(
                controller: _controller,
                controlsBuilder: (context, controller) => VideoPlayerControls(controller: controller),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildCodeExample() => Card(
    color: Colors.grey[900],
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to Create Custom Themes',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCodeBlock('''
// 1. Create a completely custom theme
final myTheme = VideoPlayerTheme(
  primaryColor: Colors.purple,
  secondaryColor: Colors.purple[300]!,
  backgroundColor: Color(0xCC1A0033),
  progressBarActiveColor: Colors.purpleAccent,
  progressBarInactiveColor: Colors.purple[100]!,
  progressBarBufferedColor: Colors.purple[200]!,
  iconSize: 36.0,
  seekIconSize: 52.0,
  borderRadius: 12.0,
  controlsPadding: EdgeInsets.all(20.0),
);

// 2. Modify an existing theme
final customLight = VideoPlayerTheme.light().copyWith(
  primaryColor: Colors.blue[900],
  progressBarActiveColor: Colors.blueAccent,
);

// 3. Use the theme with your player
VideoPlayerThemeData(
  theme: myTheme,
  child: ProVideoPlayer(
    controller: controller,
    controlsBuilder: (context, controller) => 
      VideoPlayerControls(controller: controller),
  ),
)'''),
        ],
      ),
    ),
  );

  Widget _buildCodeBlock(String code) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
    child: SelectableText(
      code,
      style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12),
    ),
  );

  // Example custom themes that developers can use as reference

  VideoPlayerTheme _buildBrandColorTheme() => const VideoPlayerTheme(
    primaryColor: Color(0xFF0066CC), // Brand blue
    secondaryColor: Color(0xFF6699CC),
    backgroundColor: Color(0xCC001A33),
    progressBarActiveColor: Color(0xFFFF6600), // Brand orange
    progressBarInactiveColor: Color(0x33FFFFFF),
    progressBarBufferedColor: Color(0x66FF6600),
    borderRadius: 10,
  );

  VideoPlayerTheme _buildMinimalistTheme() => const VideoPlayerTheme(
    primaryColor: Color(0xFFEEEEEE),
    secondaryColor: Color(0xFFAAAAAA),
    backgroundColor: Color(0xDD000000),
    progressBarActiveColor: Color(0xFFEEEEEE),
    progressBarInactiveColor: Color(0x33EEEEEE),
    progressBarBufferedColor: Color(0x66EEEEEE),
    iconSize: 28,
    seekIconSize: 42,
    borderRadius: 4,
    controlsPadding: EdgeInsets.all(12),
  );

  VideoPlayerTheme _buildGamingTheme() => VideoPlayerTheme(
    primaryColor: const Color(0xFF00FF00), // Neon green
    secondaryColor: Colors.cyan[300]!,
    backgroundColor: const Color(0xCC0A0A0A),
    progressBarActiveColor: const Color(0xFF00FF00),
    progressBarInactiveColor: const Color(0x33FFFFFF),
    progressBarBufferedColor: Colors.cyan.shade700,
    iconSize: 36,
    seekIconSize: 56,
    borderRadius: 16,
    controlsPadding: const EdgeInsets.all(18),
  );
}
