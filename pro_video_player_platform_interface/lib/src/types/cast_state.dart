/// The state of the casting connection.
enum CastState {
  /// No cast device is connected.
  notConnected,

  /// Currently connecting to a cast device.
  connecting,

  /// Successfully connected to a cast device.
  connected,

  /// Currently disconnecting from the cast device.
  disconnecting,
}
