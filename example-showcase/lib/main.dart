import 'package:flutter/material.dart';
import 'package:pro_video_player/pro_video_player.dart';

import 'screens/advanced_features_screen.dart';
import 'screens/background_playback_screen.dart';
import 'screens/casting_screen.dart';
import 'screens/chapters_screen.dart';
import 'screens/custom_theme_examples_screen.dart';
import 'screens/events_log_screen.dart';
import 'screens/home_screen.dart';
import 'screens/layout_modes_screen.dart';
import 'screens/media_controls_screen.dart';
import 'screens/network_resilience_screen.dart';
import 'screens/pip_actions_screen.dart';
import 'screens/platform_demo_screen.dart';
import 'screens/player_features_screen.dart';
import 'screens/player_toolbar_config_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/quality_selection_screen.dart';
import 'screens/scaling_modes_screen.dart';
import 'screens/stream_selection_screen.dart';
import 'screens/subtitle_config_screen.dart';
import 'screens/theme_demos_screen.dart';
import 'screens/video_metadata_screen.dart';
import 'screens/video_sources_screen.dart';

void main() async {
  // Enable verbose logging for debugging
  WidgetsFlutterBinding.ensureInitialized();
  await ProVideoPlayerLogger.setVerboseLogging(enabled: true);
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pro Video Player Example',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
    initialRoute: '/',
    routes: {
      '/': (context) => const HomeScreen(),
      '/platform-demo': (context) => const PlatformDemoScreen(),
      '/layout-modes': (context) => const LayoutModesScreen(),
      '/player-features': (context) => const PlayerFeaturesScreen(),
      '/video-sources': (context) => const VideoSourcesScreen(),
      '/playlist': (context) => const PlaylistScreen(),
      '/quality-selection': (context) => const QualitySelectionScreen(),
      '/subtitle-config': (context) => const SubtitleConfigScreen(),
      '/theme-demos': (context) => const ThemeDemosScreen(),
      '/custom-theme-examples': (context) => const CustomThemeExamplesScreen(),
      '/advanced-features': (context) => const AdvancedFeaturesScreen(),
      '/stream-selection': (context) => const StreamSelectionScreen(),
      '/events-log': (context) => const EventsLogScreen(),
      '/background-playback': (context) => const BackgroundPlaybackScreen(),
      '/scaling-modes': (context) => const ScalingModesScreen(),
      '/media-controls': (context) => const MediaControlsScreen(),
      '/pip-actions': (context) => const PipActionsScreen(),
      '/network-resilience': (context) => const NetworkResilienceScreen(),
      '/player-toolbar-config': (context) => const PlayerToolbarConfigScreen(),
      '/video-metadata': (context) => const VideoMetadataScreen(),
      '/casting': (context) => const CastingScreen(),
      '/chapters': (context) => const ChaptersScreen(),
    },
  );
}
