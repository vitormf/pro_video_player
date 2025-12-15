import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

/// Mock implementation of [ProVideoPlayerPlatform] for testing.
///
/// Use with mocktail to stub platform method calls.
///
/// Example:
/// ```dart
/// final mockPlatform = MockProVideoPlayerPlatform();
/// when(() => mockPlatform.create(...)).thenAnswer((_) async => 1);
/// ```
class MockProVideoPlayerPlatform extends Mock with MockPlatformInterfaceMixin implements ProVideoPlayerPlatform {}

/// Mock implementation of [ProVideoPlayerController] for testing.
///
/// Use when testing widgets that depend on a controller without
/// needing to set up the full platform layer.
class MockProVideoPlayerController extends Mock implements ProVideoPlayerController {}
