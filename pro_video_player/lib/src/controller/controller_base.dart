import 'package:flutter/foundation.dart';
import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import 'controller_services.dart';

/// Base class for ProVideoPlayerController that exposes protected members
/// to domain-specific mixins.
///
/// This class provides the foundation for the controller, exposing internal
/// state and services that mixins need to implement their functionality.
/// Users should only interact with `ProVideoPlayerController`, not this base.
abstract class ProVideoPlayerControllerBase extends ValueNotifier<VideoPlayerValue> {
  /// Creates a new base controller with default value.
  ProVideoPlayerControllerBase() : super(const VideoPlayerValue());

  /// The service container providing access to all managers.
  @protected
  ControllerServices get services;

  /// The platform interface for native calls.
  @protected
  ProVideoPlayerPlatform get platform => ProVideoPlayerPlatform.instance;

  /// The current video source.
  @protected
  VideoSource? get sourceInternal;

  /// The unique ID of this player instance.
  @protected
  int? get playerId;

  /// The current player options.
  @protected
  VideoPlayerOptions get options;

  /// Whether the controller has been disposed.
  @protected
  bool get isDisposed;

  /// Whether an automatic retry is currently in progress.
  @protected
  bool get isRetryingInternal;

  /// Sets the retrying state.
  @protected
  set isRetryingInternal(bool value);

  /// Throws if the controller is not initialized or is disposed.
  @protected
  void ensureInitializedInternal();
}
