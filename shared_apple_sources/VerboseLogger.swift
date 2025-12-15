import Foundation

/// Shared verbose logging utility for pro video player.
///
/// This provides a centralized logging mechanism that can be enabled/disabled
/// at runtime via the setVerboseLogging method channel call.
public final class VerboseLogger {
    /// Shared singleton instance.
    public static let shared = VerboseLogger()

    /// Whether verbose logging is enabled.
    private var isEnabled = false

    private init() {}

    /// Enables or disables verbose logging.
    ///
    /// - Parameter enabled: Whether to enable verbose logging.
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    /// Returns whether verbose logging is currently enabled.
    public var isVerboseLoggingEnabled: Bool {
        return isEnabled
    }

    /// Logs a message if verbose logging is enabled.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - tag: An optional tag to prefix the log message. Defaults to "VideoPlayer".
    public func log(_ message: String, tag: String = "VideoPlayer") {
        if isEnabled {
            NSLog("[\(tag)] \(message)")
        }
    }

    /// Logs a message with automatic function name tag if verbose logging is enabled.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - function: The function name (auto-filled by default).
    public func log(_ message: String, function: String = #function) {
        if isEnabled {
            NSLog("[VideoPlayer] \(function): \(message)")
        }
    }
}

/// Convenience function for verbose logging.
///
/// - Parameters:
///   - message: The message to log.
///   - tag: An optional tag to prefix the log message. Defaults to "VideoPlayer".
public func verboseLog(_ message: String, tag: String = "VideoPlayer") {
    VerboseLogger.shared.log(message, tag: tag)
}

/// Sets whether verbose logging is enabled.
///
/// - Parameter enabled: Whether to enable verbose logging.
public func setVideoPlayerVerboseLogging(_ enabled: Bool) {
    VerboseLogger.shared.setEnabled(enabled)
}
