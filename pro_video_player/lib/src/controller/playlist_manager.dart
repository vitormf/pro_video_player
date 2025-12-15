import 'package:pro_video_player_platform_interface/pro_video_player_platform_interface.dart';

// Alias for cleaner code
typedef _Logger = ProVideoPlayerLogger;

/// Manages playlist playback for the video player.
///
/// This manager handles:
/// - Playlist initialization
/// - Track navigation (next, previous, jump to index)
/// - Repeat modes (none, one, all)
/// - Shuffle mode
class PlaylistManager {
  /// Creates a playlist manager with dependency injection via callbacks.
  PlaylistManager({
    required this.getValue,
    required this.setValue,
    required this.getOptions,
    required this.getPlayerId,
    required this.setPlayerId,
    required this.setSource,
    required this.platform,
    required this.onPlay,
  });

  /// Gets the current video player value.
  final VideoPlayerValue Function() getValue;

  /// Updates the video player value.
  final void Function(VideoPlayerValue) setValue;

  /// Gets the video player options.
  final VideoPlayerOptions Function() getOptions;

  /// Gets the player ID (null if not initialized).
  final int? Function() getPlayerId;

  /// Sets the player ID.
  final void Function(int?) setPlayerId;

  /// Sets the video source.
  final void Function(VideoSource) setSource;

  /// Platform implementation for playlist operations.
  final ProVideoPlayerPlatform platform;

  /// Callback to play the current video.
  final Future<void> Function() onPlay;

  /// Callback to subscribe to platform events.
  /// This is set after construction to break circular dependency with EventCoordinator.
  late void Function() onSubscribeToEvents;

  /// Gets the callback for subscribing to events.
  void Function() get eventSubscriptionCallback => onSubscribeToEvents;

  /// Sets the callback for subscribing to events.
  /// This must be called after the EventCoordinator is created.
  set eventSubscriptionCallback(void Function() callback) {
    onSubscribeToEvents = callback;
  }

  /// Shuffled order of playlist indices (null when shuffle is off).
  List<int>? _shuffledIndices;

  /// Initializes the player with a playlist.
  ///
  /// The playlist will start playing from [Playlist.initialIndex].
  Future<void> initializeWithPlaylist({required Playlist playlist, required VideoPlayerOptions options}) async {
    if (playlist.items.isEmpty) {
      throw ArgumentError('Playlist must contain at least one item');
    }

    final initialIndex = playlist.initialIndex.clamp(0, playlist.items.length - 1);

    // Store playlist state
    setValue(
      getValue().copyWith(
        playlist: playlist,
        playlistIndex: initialIndex,
        playlistRepeatMode: PlaylistRepeatMode.none,
        isShuffled: false,
      ),
    );

    await loadPlaylistTrack(initialIndex, playlist, options);
  }

  /// Moves to the next track in the playlist.
  ///
  /// Returns `true` if moved to next track, `false` if at end of playlist
  /// (and repeat mode is [PlaylistRepeatMode.none]).
  Future<bool> playlistNext() async {
    final value = getValue();
    final playlist = value.playlist;
    if (playlist == null) {
      throw StateError('No playlist is loaded');
    }

    final currentIndex = value.playlistIndex ?? 0;
    final nextIndex = _getNextPlaylistIndex(currentIndex, playlist.length);

    if (nextIndex == null) {
      // End of playlist with no repeat
      setValue(getValue().copyWith(playbackState: PlaybackState.completed));
      return false;
    }

    await loadPlaylistTrack(nextIndex, playlist, getOptions());
    return true;
  }

  /// Moves to the previous track in the playlist.
  ///
  /// Returns `true` if moved to previous track, `false` if at beginning
  /// of playlist (and repeat mode is [PlaylistRepeatMode.none]).
  Future<bool> playlistPrevious() async {
    final value = getValue();
    final playlist = value.playlist;
    if (playlist == null) {
      throw StateError('No playlist is loaded');
    }

    final currentIndex = value.playlistIndex ?? 0;
    final previousIndex = _getPreviousPlaylistIndex(currentIndex, playlist.length);

    if (previousIndex == null) {
      return false;
    }

    await loadPlaylistTrack(previousIndex, playlist, getOptions());
    return true;
  }

  /// Jumps to a specific track in the playlist by index.
  Future<void> playlistJumpTo(int index) async {
    final value = getValue();
    final playlist = value.playlist;
    if (playlist == null) {
      throw StateError('No playlist is loaded');
    }

    if (index < 0 || index >= playlist.length) {
      throw RangeError.index(index, playlist.items, 'index', 'Invalid playlist index', playlist.length);
    }

    await loadPlaylistTrack(index, playlist, getOptions());
  }

  /// Sets the playlist repeat mode.
  void setPlaylistRepeatMode(PlaylistRepeatMode mode) {
    final value = getValue();
    setValue(value.copyWith(playlistRepeatMode: mode));
  }

  /// Toggles playlist shuffle mode.
  ///
  /// When enabling shuffle, generates a random order preserving the current track.
  /// When disabling shuffle, returns to sequential order.
  void setPlaylistShuffle({required bool enabled}) {
    final value = getValue();
    setValue(value.copyWith(isShuffled: enabled));

    if (enabled) {
      // Create shuffled order
      final playlist = value.playlist;
      if (playlist != null) {
        final indices = List<int>.generate(playlist.length, (i) => i);
        final currentIndex = value.playlistIndex ?? 0;

        // Remove current index, shuffle the rest, insert current at start
        indices
          ..removeAt(currentIndex)
          ..shuffle()
          ..insert(0, currentIndex);

        _shuffledIndices = indices;
      }
    } else {
      _shuffledIndices = null;
    }
  }

  /// Handles playlist progression when a track completes.
  ///
  /// Called automatically when [PlaybackCompletedEvent] is received.
  /// Returns `true` if moved to next track, `false` if playlist ended.
  Future<bool> handlePlaybackCompleted() async {
    final value = getValue();

    // Handle playlist progression
    if (value.playlist != null && value.playlistRepeatMode == PlaylistRepeatMode.one) {
      // Repeat current track
      return false; // Don't advance
    } else if (value.playlist != null) {
      // Move to next track
      return playlistNext();
    }

    return false;
  }

  /// Gets the next playlist index based on current mode and shuffle state.
  int? _getNextPlaylistIndex(int currentIndex, int playlistLength) {
    final value = getValue();

    if (value.playlistRepeatMode == PlaylistRepeatMode.one) {
      return currentIndex;
    }

    int? nextIndex;
    if (value.isShuffled && _shuffledIndices != null) {
      // In shuffle mode
      final currentPos = _shuffledIndices!.indexOf(currentIndex);
      if (currentPos < _shuffledIndices!.length - 1) {
        nextIndex = _shuffledIndices![currentPos + 1];
      } else {
        // End of shuffled list
        if (value.playlistRepeatMode == PlaylistRepeatMode.all) {
          nextIndex = _shuffledIndices![0];
        } else {
          return null; // End of playlist
        }
      }
    } else {
      // Sequential mode
      nextIndex = currentIndex + 1;
      if (nextIndex >= playlistLength) {
        if (value.playlistRepeatMode == PlaylistRepeatMode.all) {
          nextIndex = 0;
        } else {
          return null; // End of playlist
        }
      }
    }

    return nextIndex;
  }

  /// Gets the previous playlist index.
  int? _getPreviousPlaylistIndex(int currentIndex, int playlistLength) {
    final value = getValue();

    if (value.playlistRepeatMode == PlaylistRepeatMode.one) {
      return currentIndex;
    }

    int? previousIndex;
    if (value.isShuffled && _shuffledIndices != null) {
      // In shuffle mode
      final currentPos = _shuffledIndices!.indexOf(currentIndex);
      if (currentPos > 0) {
        previousIndex = _shuffledIndices![currentPos - 1];
      } else {
        // Beginning of shuffled list
        if (value.playlistRepeatMode == PlaylistRepeatMode.all) {
          previousIndex = _shuffledIndices![_shuffledIndices!.length - 1];
        } else {
          return null; // Beginning of playlist
        }
      }
    } else {
      // Sequential mode
      previousIndex = currentIndex - 1;
      if (previousIndex < 0) {
        if (value.playlistRepeatMode == PlaylistRepeatMode.all) {
          previousIndex = playlistLength - 1;
        } else {
          return null; // Beginning of playlist
        }
      }
    }

    return previousIndex;
  }

  /// Loads and plays a specific playlist track.
  Future<void> loadPlaylistTrack(int index, Playlist playlist, VideoPlayerOptions options) async {
    _Logger.log('Loading playlist track $index', tag: 'Controller');

    // Update playlist index
    final value = getValue();
    setValue(value.copyWith(playlistIndex: index));

    // Dispose current player
    final currentPlayerId = getPlayerId();
    if (currentPlayerId != null) {
      await platform.dispose(currentPlayerId);
      setPlayerId(null);
    }

    // Initialize with new source
    setSource(playlist[index]);
    setValue(getValue().copyWith(playbackState: PlaybackState.initializing, clearError: true));

    try {
      final newPlayerId = await platform.create(source: playlist[index], options: options);
      _Logger.log('Player created with ID: $newPlayerId for playlist track $index', tag: 'Controller');

      setPlayerId(newPlayerId);
      onSubscribeToEvents();

      setValue(
        getValue().copyWith(
          playbackState: PlaybackState.ready,
          position: Duration.zero,
          duration: Duration.zero,
          bufferedPosition: Duration.zero,
        ),
      );

      // Auto-play if was playing
      if (options.autoPlay) {
        await onPlay();
      }
    } catch (e, stackTrace) {
      _Logger.error('Failed to load playlist track $index', error: e, stackTrace: stackTrace, tag: 'Controller');
      setValue(
        getValue().copyWith(playbackState: PlaybackState.error, errorMessage: 'Failed to load playlist track: $e'),
      );
    }
  }

  /// Disposes resources used by the playlist manager.
  void dispose() {
    _shuffledIndices = null;
  }
}
