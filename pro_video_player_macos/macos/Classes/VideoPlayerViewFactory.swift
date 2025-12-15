import AVFoundation
import AVKit
import FlutterMacOS
import Foundation

/// Minimal macOS VideoPlayerViewFactory - delegates to SharedmacOSVideoPlayerViewFactory
class VideoPlayerViewFactory: SharedmacOSVideoPlayerViewFactory {
    init(plugin: SharedPluginBase) {
        super.init(pluginBase: plugin, config: .macOS)
    }
}
