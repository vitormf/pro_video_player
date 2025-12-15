/// Defines the available Picture-in-Picture action types.
///
/// These actions appear as buttons in the PiP window, allowing users to
/// control playback without leaving the PiP view.
///
/// ## Platform Support
///
/// - **Android:** Uses `RemoteAction` with `PictureInPictureParams`. Actions
///   appear as icon buttons in the PiP window overlay.
/// - **iOS:** Limited support. iOS PiP uses system-managed controls. The
///   play/pause action is handled automatically. Skip actions require
///   `canSkipToPreviousItem`/`canSkipToNextItem` on `AVPictureInPictureController`
///   which is available in iOS 14.2+.
/// - **macOS:** Similar to iOS, uses system-managed controls.
/// - **Web:** Not supported in PiP mode.
enum PipActionType {
  /// Play/pause toggle action.
  ///
  /// This is typically shown as a play or pause icon depending on the
  /// current playback state. On iOS, this is handled automatically by
  /// the system PiP controller.
  playPause,

  /// Skip to previous item action.
  ///
  /// For playlist playback, skips to the previous track.
  /// For single videos, this is typically a "skip backward" action.
  skipPrevious,

  /// Skip to next item action.
  ///
  /// For playlist playback, skips to the next track.
  /// For single videos, this is typically a "skip forward" action.
  skipNext,

  /// Skip backward by a fixed duration (e.g., 10 or 15 seconds).
  ///
  /// Android only. iOS uses `skipPrevious` for backward navigation.
  skipBackward,

  /// Skip forward by a fixed duration (e.g., 10 or 15 seconds).
  ///
  /// Android only. iOS uses `skipNext` for forward navigation.
  skipForward,
}

/// Represents a Picture-in-Picture action button.
///
/// Actions are displayed as buttons in the PiP window, allowing users to
/// control playback without leaving the PiP view.
///
/// ## Example
///
/// ```dart
/// final actions = [
///   PipAction(
///     type: PipActionType.skipBackward,
///     skipInterval: Duration(seconds: 10),
///   ),
///   PipAction(type: PipActionType.playPause),
///   PipAction(
///     type: PipActionType.skipForward,
///     skipInterval: Duration(seconds: 10),
///   ),
/// ];
///
/// await controller.setPipActions(actions);
/// ```
class PipAction {
  /// Creates a PiP action.
  ///
  /// The [type] determines which action this represents.
  /// The [skipInterval] is used for `skipBackward` and `skipForward` actions.
  const PipAction({required this.type, this.skipInterval = const Duration(seconds: 10)});

  /// Creates a PipAction from a map (from method channel).
  factory PipAction.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String;
    final actionType = PipActionType.values.firstWhere((e) => e.name == typeStr, orElse: () => PipActionType.playPause);
    final skipIntervalMs = map['skipIntervalMs'] as int? ?? 10000;
    return PipAction(
      type: actionType,
      skipInterval: Duration(milliseconds: skipIntervalMs),
    );
  }

  /// The type of action.
  final PipActionType type;

  /// The duration to skip for `skipBackward` and `skipForward` actions.
  ///
  /// Defaults to 10 seconds. Only used for skip actions.
  final Duration skipInterval;

  /// Converts this action to a map for method channel communication.
  Map<String, dynamic> toMap() => {'type': type.name, 'skipIntervalMs': skipInterval.inMilliseconds};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PipAction) return false;
    return type == other.type && skipInterval == other.skipInterval;
  }

  @override
  int get hashCode => Object.hash(type, skipInterval);

  @override
  String toString() => 'PipAction(type: $type, skipInterval: $skipInterval)';
}

/// Default PiP actions for video playback.
///
/// Provides common action configurations for different use cases.
class PipActions {
  PipActions._();

  /// Standard video player actions: skip backward, play/pause, skip forward.
  ///
  /// Uses 10-second skip intervals.
  static const List<PipAction> standard = [
    PipAction(type: PipActionType.skipBackward),
    PipAction(type: PipActionType.playPause),
    PipAction(type: PipActionType.skipForward),
  ];

  /// Playlist-focused actions: previous, play/pause, next.
  ///
  /// For playlist navigation rather than time-based skipping.
  static const List<PipAction> playlist = [
    PipAction(type: PipActionType.skipPrevious),
    PipAction(type: PipActionType.playPause),
    PipAction(type: PipActionType.skipNext),
  ];

  /// Minimal actions: play/pause only.
  static const List<PipAction> minimal = [PipAction(type: PipActionType.playPause)];
}
