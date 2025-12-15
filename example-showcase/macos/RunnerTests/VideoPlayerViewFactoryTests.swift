import FlutterMacOS
import XCTest
import AppKit
import AVFoundation
@testable import pro_video_player_macos

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
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
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
        let view = factory.create(withViewIdentifier: 0, arguments: arguments)

        // Then
        XCTAssertNotNil(view)
    }

    func testCreateViewWithInvalidPlayerId() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        let arguments: [String: Any] = ["playerId": 999]

        // When
        let view = factory.create(withViewIdentifier: 0, arguments: arguments)

        // Then
        XCTAssertNotNil(view)
    }

    func testCreateViewWithNilArguments() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)

        // When
        let view = factory.create(withViewIdentifier: 0, arguments: nil)

        // Then
        XCTAssertNotNil(view)
    }

    func testCreateViewWithInvalidArgumentsType() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        let arguments = "invalid"

        // When
        let view = factory.create(withViewIdentifier: 0, arguments: arguments)

        // Then
        XCTAssertNotNil(view)
    }

    func testCreateViewWithMissingPlayerId() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        let arguments: [String: Any] = ["someOtherKey": "value"]

        // When
        let view = factory.create(withViewIdentifier: 0, arguments: arguments)

        // Then
        XCTAssertNotNil(view)
    }

    func testCreateViewWithDifferentViewIdentifiers() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]

        // When
        let view1 = factory.create(withViewIdentifier: 0, arguments: arguments)
        let view2 = factory.create(withViewIdentifier: 1, arguments: arguments)

        // Then
        XCTAssertNotNil(view1)
        XCTAssertNotNil(view2)
    }

    func testCreateViewReturnsNSView() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]

        // When
        let view = factory.create(withViewIdentifier: 0, arguments: arguments)

        // Then
        XCTAssertNotNil(view)
        XCTAssertTrue(view is NSView)
    }

    // MARK: - View Properties Tests

    func testViewWantsLayer() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]

        // When
        let view = factory.create(withViewIdentifier: 0, arguments: arguments)

        // Then
        XCTAssertTrue(view.wantsLayer)
    }

    func testViewIsNSView() {
        // Given
        let factory = VideoPlayerViewFactory(plugin: plugin.sharedBase)
        guard let playerId = createPlayer() else {
            XCTFail("Failed to create player")
            return
        }
        let arguments: [String: Any] = ["playerId": playerId]

        // When
        let view = factory.create(withViewIdentifier: 0, arguments: arguments)

        // Then
        XCTAssertTrue(view is NSView)
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
        let view1 = factory.create(withViewIdentifier: 0, arguments: arguments)
        let view2 = factory.create(withViewIdentifier: 1, arguments: arguments)

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
        let view1 = factory.create(withViewIdentifier: 0, arguments: ["playerId": playerId1])
        let view2 = factory.create(withViewIdentifier: 1, arguments: ["playerId": playerId2])

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

        // When
        let view = factory.create(withViewIdentifier: 0, arguments: arguments)

        // Simulate layout change
        let newFrame = CGRect(x: 0, y: 0, width: 640, height: 480)
        view.frame = newFrame
        view.layout()

        // Then
        XCTAssertEqual(view.frame, newFrame)
    }
}
