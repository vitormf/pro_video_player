/// Type of cast device.
enum CastDeviceType {
  /// AirPlay device (iOS/macOS).
  airPlay,

  /// Chromecast device (Android/Web).
  chromecast,

  /// Web Remote Playback API device.
  webRemotePlayback,

  /// Unknown or unsupported device type.
  unknown,
}

/// Represents a cast-capable device.
///
/// This class contains information about a device that can receive video
/// casting, such as an AirPlay-enabled TV, Chromecast, or web-based remote
/// playback target.
class CastDevice {
  /// Creates a cast device.
  const CastDevice({required this.id, required this.name, required this.type});

  /// A unique identifier for this device.
  ///
  /// The format of this ID is platform-specific:
  /// - **iOS/macOS (AirPlay)**: Route identifier from AVRoutePickerView
  /// - **Android (Chromecast)**: Device ID from Cast SDK
  /// - **Web**: Device ID from Remote Playback API
  final String id;

  /// The human-readable name of the device.
  ///
  /// Examples: "Living Room TV", "John's Chromecast", "Bedroom Speaker"
  final String name;

  /// The type of cast device.
  final CastDeviceType type;

  /// Creates a copy of this device with the given fields replaced.
  CastDevice copyWith({String? id, String? name, CastDeviceType? type}) =>
      CastDevice(id: id ?? this.id, name: name ?? this.name, type: type ?? this.type);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CastDevice) return false;
    return id == other.id && name == other.name && type == other.type;
  }

  @override
  int get hashCode => Object.hash(id, name, type);

  @override
  String toString() => 'CastDevice(id: $id, name: $name, type: $type)';
}
