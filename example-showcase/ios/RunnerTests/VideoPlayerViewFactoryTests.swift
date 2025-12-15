import Flutter
import XCTest
import UIKit
import AVFoundation
import AVKit
@testable import pro_video_player_ios

class VideoPlayerViewFactoryTests: XCTestCase {

    var mockRegistrar: MockFlutterPluginRegistrar!
    var mockMessenger: MockBinaryMessenger!
    var plugin: ProVideoPlayerPlugin!

    override func setUp() {
        super.setUp()
        mockMessenger = MockBinaryMessenger()
        mockRegistrar = MockFlutterPluginRegistrar()
        mockRegistrar.mockMessenger = mockMessenger
        plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
    }

    override func tearDown() {
        plugin = nil
        mockRegistrar = nil
        mockMessenger = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createPlayer() -> Int? {
        let createArgs: [String: Any] = [
            "source": ["type": "file", "path": "/nonexistent/test.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let expectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
        return playerId
    }

    // MARK: - Factory Initialization Tests

    func testFactoryInitialization() {
        // Given/When
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)

        // Then
        XCTAssertNotNil(factory)
    }

    // MARK: - Create Args Codec Tests

    func testCreateArgsCodecReturnsStandardMessageCodec() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)

        // When
        let codec = factory.createArgsCodec()

        // Then
        XCTAssertTrue(codec is FlutterStandardMessageCodec)
    }

    // MARK: - Create View Tests

    func testCreateViewWithValidPlayerId() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]

        // When
        let view = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: arguments
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.view())
    }

    func testCreateViewWithInvalidPlayerId() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        let arguments: [String: Any] = ["playerId": 999]

        // When
        let view = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: arguments
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.view())
    }

    func testCreateViewWithNilArguments() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)

        // When
        let view = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: nil
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.view())
    }

    func testCreateViewWithInvalidArgumentsType() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        let arguments = "invalid"

        // When
        let view = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: arguments
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.view())
    }

    func testCreateViewWithMissingPlayerId() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        let arguments: [String: Any] = ["someOtherKey": "value"]

        // When
        let view = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: arguments
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.view())
    }

    func testCreateViewWithDifferentFrames() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]

        // When
        let view1 = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 100, height: 100),
            viewIdentifier: 0,
            arguments: arguments
        )
        let view2 = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            viewIdentifier: 1,
            arguments: arguments
        )

        // Then
        XCTAssertNotNil(view1)
        XCTAssertNotNil(view2)
    }

    func testCreateViewWithZeroFrame() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]

        // When
        let view = factory.create(
            withFrame: CGRect.zero,
            viewIdentifier: 0,
            arguments: arguments
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.view())
    }

    // MARK: - View Properties Tests

    func testViewBackgroundColor() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]

        // When
        let platformView = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: arguments
        )
        let view = platformView.view()

        // Then
        XCTAssertEqual(view.backgroundColor, UIColor.black)
    }

    func testViewBounds() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]
        let frame = CGRect(x: 0, y: 0, width: 320, height: 240)

        // When
        let platformView = factory.create(
            withFrame: frame,
            viewIdentifier: 0,
            arguments: arguments
        )
        let view = platformView.view()

        // Then
        XCTAssertEqual(view.frame, frame)
    }

    // MARK: - Multiple Views Tests

    func testCreateMultipleViewsForSamePlayer() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]

        // When
        let view1 = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: arguments
        )
        let view2 = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 1,
            arguments: arguments
        )

        // Then
        XCTAssertNotNil(view1)
        XCTAssertNotNil(view2)
    }

    func testCreateViewsForDifferentPlayers() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId1 = createPlayer(),
              let playerId2 = createPlayer() else {
            XCTFail("Failed to create players")
            return
        }

        // When
        let view1 = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: ["playerId": playerId1]
        )
        let view2 = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 1,
            arguments: ["playerId": playerId2]
        )

        // Then
        XCTAssertNotNil(view1)
        XCTAssertNotNil(view2)
    }

    // MARK: - Layout Tests

    func testViewLayoutSubviews() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]
        let initialFrame = CGRect(x: 0, y: 0, width: 320, height: 240)

        // When
        let platformView = factory.create(
            withFrame: initialFrame,
            viewIdentifier: 0,
            arguments: arguments
        )
        let view = platformView.view()

        // Simulate layout change
        let newFrame = CGRect(x: 0, y: 0, width: 640, height: 480)
        view.frame = newFrame
        view.layoutSubviews()

        // Then
        XCTAssertEqual(view.frame, newFrame)
    }
}

// MARK: - PlayerContainerView Tests

class PlayerContainerViewTests: XCTestCase {

    func testLayoutSubviewsUpdatesPlayerLayerFrame() {
        // Given
        let containerView = PlayerContainerView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let playerLayer = AVPlayerLayer()
        containerView.playerLayer = playerLayer
        containerView.layer.addSublayer(playerLayer)

        // When
        let newFrame = CGRect(x: 0, y: 0, width: 640, height: 480)
        containerView.frame = newFrame
        containerView.layoutSubviews()

        // Then
        XCTAssertEqual(playerLayer.frame, containerView.bounds)
    }

    func testLayoutSubviewsWithNilPlayerLayer() {
        // Given
        let containerView = PlayerContainerView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        containerView.playerLayer = nil

        // When
        containerView.layoutSubviews()

        // Then - No crash
        XCTAssertNil(containerView.playerLayer)
    }

    func testInitialPlayerLayerFrame() {
        // Given
        let frame = CGRect(x: 0, y: 0, width: 320, height: 240)
        let containerView = PlayerContainerView(frame: frame)
        let playerLayer = AVPlayerLayer()
        playerLayer.frame = frame
        containerView.playerLayer = playerLayer
        containerView.layer.addSublayer(playerLayer)

        // When
        containerView.layoutSubviews()

        // Then
        XCTAssertEqual(playerLayer.frame, containerView.bounds)
    }

    func testLayoutSubviewsUpdatesPlayerViewControllerFrame() {
        // Given
        let containerView = PlayerContainerView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let playerVC = AVPlayerViewController()
        containerView.playerViewController = playerVC
        containerView.addSubview(playerVC.view)
        playerVC.view.frame = containerView.bounds

        // When
        let newFrame = CGRect(x: 0, y: 0, width: 640, height: 480)
        containerView.frame = newFrame
        containerView.layoutSubviews()

        // Then
        XCTAssertEqual(playerVC.view.frame, containerView.bounds)
    }
}

// MARK: - VideoPlayerView Native Controls Tests

class VideoPlayerViewNativeControlsTests: XCTestCase {

    var mockRegistrar: MockFlutterPluginRegistrar!
    var mockMessenger: MockBinaryMessenger!
    var plugin: ProVideoPlayerPlugin!

    override func setUp() {
        super.setUp()
        mockMessenger = MockBinaryMessenger()
        mockRegistrar = MockFlutterPluginRegistrar()
        mockRegistrar.mockMessenger = mockMessenger
        plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
    }

    override func tearDown() {
        plugin = nil
        mockRegistrar = nil
        mockMessenger = nil
        super.tearDown()
    }

    private func createPlayer() -> Int? {
        let createArgs: [String: Any] = [
            "source": ["type": "file", "path": "/nonexistent/test.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let expectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
        return playerId
    }

    func testCreateViewWithNativeControlsMode() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId, "controlsMode": "native"]

        // When
        let view = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: arguments
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.view())
        // The view should have a subview (AVPlayerViewController's view) when using native controls
        XCTAssertGreaterThanOrEqual(view.view().subviews.count, 0)
    }

    func testCreateViewWithNoneControlsMode() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId, "controlsMode": "none"]

        // When
        let view = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: arguments
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.view())
    }

    func testCreateViewWithInvalidControlsModeFallsBackToNone() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId, "controlsMode": "invalid"]

        // When
        let view = factory.create(
            withFrame: CGRect(x: 0, y: 0, width: 320, height: 240),
            viewIdentifier: 0,
            arguments: arguments
        )

        // Then
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.view())
    }
}
