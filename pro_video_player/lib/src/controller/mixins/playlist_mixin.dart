import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

import '../controller_base.dart';

/// Mixin providing playlist management functionality.
mixin PlaylistMixin on ProVideoPlayerControllerBase {
  /// Moves to the next track in the playlist.
  ///
  /// Returns `true` if moved to next track, `false` if at end of playlist
  /// (and repeat mode is [PlaylistRepeatMode.none]).
  Future<bool> playlistNext() async {
    ensureInitializedInternal();
    return services.playlistManager.playlistNext();
  }

  /// Moves to the previous track in the playlist.
  ///
  /// Returns `true` if moved to previous track, `false` if already at
  /// beginning of playlist.
  Future<bool> playlistPrevious() async {
    ensureInitializedInternal();
    return services.playlistManager.playlistPrevious();
  }

  /// Jumps to a specific track in the playlist by index.
  Future<void> playlistJumpTo(int index) async {
    ensureInitializedInternal();
    return services.playlistManager.playlistJumpTo(index);
  }

  /// Sets the playlist repeat mode.
  void setPlaylistRepeatMode(PlaylistRepeatMode mode) {
    ensureInitializedInternal();
    services.playlistManager.setPlaylistRepeatMode(mode);
  }

  /// Toggles playlist shuffle mode.
  ///
  /// When shuffle is enabled, tracks play in random order.
  /// When disabled, tracks play in original order.
  void setPlaylistShuffle({required bool enabled}) {
    ensureInitializedInternal();
    services.playlistManager.setPlaylistShuffle(enabled: enabled);
  }
}
