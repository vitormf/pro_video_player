import AVKit
import Foundation

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import AppKit
#endif

// MARK: - iOS Implementation

#if os(iOS)

/// Factory for creating AirPlay route picker views on iOS.
public class AirPlayRoutePickerViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    public init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    public func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let arguments = args as? [String: Any]
        return AirPlayRoutePickerPlatformView(
            frame: frame,
            viewId: viewId,
            arguments: arguments,
            messenger: messenger
        )
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// iOS platform view wrapping AVRoutePickerView for AirPlay device selection.
class AirPlayRoutePickerPlatformView: NSObject, FlutterPlatformView {
    private let containerView: UIView
    private var routePickerView: AVRoutePickerView?
    private let channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewId: Int64,
        arguments: [String: Any]?,
        messenger: FlutterBinaryMessenger
    ) {
        self.containerView = UIView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "com.example.pro_video_player/airplay_picker_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        setupRoutePickerView(arguments: arguments)
        setupMethodChannel()
    }

    private func setupRoutePickerView(arguments: [String: Any]?) {
        let picker = AVRoutePickerView(frame: containerView.bounds)
        picker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        picker.delegate = self

        // Configure tint color if provided
        if let tintColorValue = arguments?["tintColor"] as? Int {
            picker.tintColor = UIColor(
                red: CGFloat((tintColorValue >> 16) & 0xFF) / 255.0,
                green: CGFloat((tintColorValue >> 8) & 0xFF) / 255.0,
                blue: CGFloat(tintColorValue & 0xFF) / 255.0,
                alpha: CGFloat((tintColorValue >> 24) & 0xFF) / 255.0
            )
        }

        // Configure active tint color if provided
        if let activeTintColorValue = arguments?["activeTintColor"] as? Int {
            picker.activeTintColor = UIColor(
                red: CGFloat((activeTintColorValue >> 16) & 0xFF) / 255.0,
                green: CGFloat((activeTintColorValue >> 8) & 0xFF) / 255.0,
                blue: CGFloat(activeTintColorValue & 0xFF) / 255.0,
                alpha: CGFloat((activeTintColorValue >> 24) & 0xFF) / 255.0
            )
        }

        // Configure prioritizes video devices (iOS 13+)
        if #available(iOS 13.0, *) {
            let prioritizesVideo = arguments?["prioritizesVideoDevices"] as? Bool ?? true
            picker.prioritizesVideoDevices = prioritizesVideo
        }

        containerView.addSubview(picker)
        self.routePickerView = picker
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "setTintColor":
                if let colorValue = (call.arguments as? [String: Any])?["color"] as? Int {
                    self?.routePickerView?.tintColor = UIColor(
                        red: CGFloat((colorValue >> 16) & 0xFF) / 255.0,
                        green: CGFloat((colorValue >> 8) & 0xFF) / 255.0,
                        blue: CGFloat(colorValue & 0xFF) / 255.0,
                        alpha: CGFloat((colorValue >> 24) & 0xFF) / 255.0
                    )
                }
                result(nil)
            case "setActiveTintColor":
                if let colorValue = (call.arguments as? [String: Any])?["color"] as? Int {
                    self?.routePickerView?.activeTintColor = UIColor(
                        red: CGFloat((colorValue >> 16) & 0xFF) / 255.0,
                        green: CGFloat((colorValue >> 8) & 0xFF) / 255.0,
                        blue: CGFloat(colorValue & 0xFF) / 255.0,
                        alpha: CGFloat((colorValue >> 24) & 0xFF) / 255.0
                    )
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func view() -> UIView {
        return containerView
    }
}

extension AirPlayRoutePickerPlatformView: AVRoutePickerViewDelegate {
    func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        channel.invokeMethod("onWillBeginPresentingRoutes", arguments: nil)
    }

    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        channel.invokeMethod("onDidEndPresentingRoutes", arguments: nil)
    }
}

#elseif os(macOS)

/// Factory for creating AirPlay route picker views on macOS.
public class AirPlayRoutePickerViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    public init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    public func create(
        withViewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> NSView {
        let arguments = args as? [String: Any]
        return AirPlayRoutePickerPlatformView(
            viewId: viewId,
            arguments: arguments,
            messenger: messenger
        )
    }

    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// macOS platform view wrapping AVRoutePickerView for AirPlay device selection.
class AirPlayRoutePickerPlatformView: NSView {
    private var routePickerView: AVRoutePickerView?
    private let channel: FlutterMethodChannel

    init(
        viewId: Int64,
        arguments: [String: Any]?,
        messenger: FlutterBinaryMessenger
    ) {
        self.channel = FlutterMethodChannel(
            name: "com.example.pro_video_player/airplay_picker_\(viewId)",
            binaryMessenger: messenger
        )
        super.init(frame: .zero)

        setupRoutePickerView(arguments: arguments)
        setupMethodChannel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupRoutePickerView(arguments: [String: Any]?) {
        let picker = AVRoutePickerView(frame: bounds)
        picker.autoresizingMask = [.width, .height]
        picker.delegate = self

        // Configure if it's a router discoverer (macOS specific)
        picker.isRoutePickerButtonBordered = arguments?["showBorder"] as? Bool ?? false

        // Apply tint color if provided
        // On macOS, we need to find the button inside the picker and set its contentTintColor
        if let tintColorValue = arguments?["tintColor"] as? Int {
            let color = NSColor(
                red: CGFloat((tintColorValue >> 16) & 0xFF) / 255.0,
                green: CGFloat((tintColorValue >> 8) & 0xFF) / 255.0,
                blue: CGFloat(tintColorValue & 0xFF) / 255.0,
                alpha: CGFloat((tintColorValue >> 24) & 0xFF) / 255.0
            )
            applyTintColor(to: picker, color: color)
        }

        addSubview(picker)
        self.routePickerView = picker
    }

    /// Applies tint color to the AVRoutePickerView's internal button on macOS.
    private func applyTintColor(to picker: AVRoutePickerView, color: NSColor) {
        // AVRoutePickerView contains an NSButton internally
        // We need to find it and set the contentTintColor
        DispatchQueue.main.async {
            for subview in picker.subviews {
                if let button = subview as? NSButton {
                    button.contentTintColor = color
                    break
                }
            }
        }
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "setRoutePickerButtonBordered":
                if let bordered = (call.arguments as? [String: Any])?["bordered"] as? Bool {
                    self?.routePickerView?.isRoutePickerButtonBordered = bordered
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    override func layout() {
        super.layout()
        routePickerView?.frame = bounds
    }
}

extension AirPlayRoutePickerPlatformView: AVRoutePickerViewDelegate {
    func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        channel.invokeMethod("onWillBeginPresentingRoutes", arguments: nil)
    }

    func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        channel.invokeMethod("onDidEndPresentingRoutes", arguments: nil)
    }
}

#endif
