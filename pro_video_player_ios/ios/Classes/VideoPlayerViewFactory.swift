import Flutter
import UIKit
import AVFoundation
import AVKit

/// Minimal iOS VideoPlayerViewFactory - delegates to SharediOSVideoPlayerViewFactory
class VideoPlayerViewFactory: SharediOSVideoPlayerViewFactory {
    init(plugin: SharedPluginBase) {
        super.init(pluginBase: plugin, config: .ios)
    }
}
