import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pro_video_player/pro_video_player.dart';
import 'package:pro_video_player/src/controller/error_recovery_manager.dart';
import 'package:pro_video_player/src/controller/playback_manager.dart';
import 'package:pro_video_player/src/controller/playlist_manager.dart';
import 'package:pro_video_player/src/controller/track_manager.dart';
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

// Manager mocks

/// Mock implementation of [PlaybackManager] for testing.
///
/// Use when testing EventCoordinator or components that depend on PlaybackManager.
class MockPlaybackManager extends Mock implements PlaybackManager {}

/// Mock implementation of [TrackManager] for testing.
///
/// Use when testing EventCoordinator or components that depend on TrackManager.
class MockTrackManager extends Mock implements TrackManager {}

/// Mock implementation of [ErrorRecoveryManager] for testing.
///
/// Use when testing EventCoordinator or components that depend on ErrorRecoveryManager.
class MockErrorRecoveryManager extends Mock implements ErrorRecoveryManager {}

/// Mock implementation of [PlaylistManager] for testing.
///
/// Use when testing EventCoordinator or components that depend on PlaylistManager.
class MockPlaylistManager extends Mock implements PlaylistManager {}

// UI mocks

/// Mock implementation of [VideoControlsController] for testing.
///
/// Use when testing control wrapper widgets that depend on VideoControlsController.
class MockVideoControlsController extends Mock implements VideoControlsController {}
