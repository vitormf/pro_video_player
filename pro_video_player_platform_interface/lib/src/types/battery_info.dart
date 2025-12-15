/// Battery information including charge level and charging state.
///
/// This class provides battery status information for displaying in the
/// fullscreen status bar. Battery information may not be available on all
/// platforms or devices:
///
/// - **iOS**: Full support via UIDevice battery APIs
/// - **Android**: Full support via BatteryManager
/// - **macOS**: Supported on MacBooks with battery, null on desktops
/// - **Web**: Supported in browsers with Battery Status API (Chrome, Edge)
/// - **Windows/Linux**: Not currently implemented, returns null
///
/// When battery information is unavailable, the status bar gracefully
/// degrades by hiding the battery section.
class BatteryInfo {
  /// Creates battery information with the given percentage and charging state.
  ///
  /// The [percentage] should be between 0 and 100 inclusive.
  /// The [isCharging] indicates whether the device is currently charging.
  const BatteryInfo({required this.percentage, required this.isCharging})
    : assert(percentage >= 0 && percentage <= 100, 'Battery percentage must be between 0 and 100');

  /// Creates a [BatteryInfo] from a map received from platform channel.
  factory BatteryInfo.fromJson(Map<String, dynamic> json) =>
      BatteryInfo(percentage: (json['percentage'] as num).toInt(), isCharging: json['isCharging'] as bool);

  /// Battery charge percentage (0-100).
  ///
  /// - 0: Battery empty
  /// - 100: Battery full
  final int percentage;

  /// Whether the device is currently charging.
  ///
  /// `true` when connected to power and actively charging.
  /// `false` when running on battery or fully charged while plugged in.
  final bool isCharging;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatteryInfo &&
          runtimeType == other.runtimeType &&
          percentage == other.percentage &&
          isCharging == other.isCharging;

  @override
  int get hashCode => Object.hash(percentage, isCharging);

  @override
  String toString() => 'BatteryInfo(percentage: $percentage%, isCharging: $isCharging)';

  /// Converts this battery info to a map for platform channel communication.
  Map<String, dynamic> toJson() => {'percentage': percentage, 'isCharging': isCharging};
}
