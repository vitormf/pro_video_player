/// Defines how a playlist should repeat.
enum PlaylistRepeatMode {
  /// No repeat - playlist plays once and stops.
  none,

  /// Repeat all - playlist loops back to the first item after the last.
  all,

  /// Repeat one - current item loops indefinitely.
  one;

  /// Converts the enum to a string representation.
  String toJson() => name;

  /// Creates a [PlaylistRepeatMode] from a string representation.
  static PlaylistRepeatMode fromJson(String json) =>
      PlaylistRepeatMode.values.firstWhere((mode) => mode.name == json, orElse: () => PlaylistRepeatMode.none);
}
