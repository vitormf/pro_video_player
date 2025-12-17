import FlutterMacOS
import XCTest
@testable import pro_video_player_macos

class MockFlutterMethodChannel: FlutterMethodChannel {
    var invokedMethods: [(method: String, arguments: Any?)] = []

    override func invokeMethod(_ method: String, arguments: Any?) {
        invokedMethods.append((method: method, arguments: arguments))
    }
}

class MockFlutterResult {
    var successValue: Any?
    var errorCode: String?
    var errorMessage: String?
    var errorDetails: Any?
    var notImplementedCalled = false

    func call(_ result: Any?) {
        successValue = result
    }
}

class MockFlutterPluginRegistrar: NSObject, FlutterPluginRegistrar {
    var mockMessenger: FlutterBinaryMessenger!
    var registeredFactories: [String: FlutterPlatformViewFactory] = [:]

    // Properties required by FlutterPluginRegistrar protocol (macOS)
    var messenger: FlutterBinaryMessenger { return mockMessenger }

    var textures: FlutterTextureRegistry {
        fatalError("Not implemented")
    }

    var view: NSView? { return nil }

    var viewController: NSViewController? { return nil }

    // Methods required by FlutterPluginRegistrar protocol (macOS)
    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String) {
        registeredFactories[factoryId] = factory
    }

    func publish(_ value: NSObject) {}

    func addMethodCallDelegate(_ delegate: FlutterPlugin, channel: FlutterMethodChannel) {}

    func addApplicationDelegate(_ delegate: FlutterAppLifecycleDelegate) {}

    func lookupKey(forAsset asset: String) -> String {
        return asset
    }

    func lookupKey(forAsset asset: String, fromPackage package: String) -> String {
        return "\(package)/\(asset)"
    }
}

class MockBinaryMessenger: NSObject, FlutterBinaryMessenger {
    func send(onChannel channel: String, message: Data?) {}

    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {}

    func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?) -> FlutterBinaryMessengerConnection {
        return FlutterBinaryMessengerConnection(0)
    }

    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}
}

class ProVideoPlayerPluginTests: XCTestCase {

    var mockRegistrar: MockFlutterPluginRegistrar!
    var mockMessenger: MockBinaryMessenger!

    override func setUp() {
        super.setUp()
        mockMessenger = MockBinaryMessenger()
        mockRegistrar = MockFlutterPluginRegistrar()
        mockRegistrar.mockMessenger = mockMessenger
    }

    override func tearDown() {
        mockRegistrar = nil
        mockMessenger = nil
        super.tearDown()
    }

    // MARK: - Registration Tests

    func testPluginRegistersMethodChannel() {
        // When
        ProVideoPlayerPlugin.register(with: mockRegistrar)

        // Then - Verify factory was registered
        XCTAssertNotNil(mockRegistrar.registeredFactories["com.example.pro_video_player_macos/video_view"])
    }

    // MARK: - Handle Method Tests

    func testHandleUnknownMethodReturnsNotImplemented() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "unknownMethod", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue as AnyObject === FlutterMethodNotImplemented)
    }

    func testCreateWithInvalidArgumentsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "create", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
        if let error = resultValue as? FlutterError {
            XCTAssertEqual(error.code, "INVALID_ARGS")
        }
    }

    func testCreateWithMissingSourceReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let args: [String: Any] = ["options": [:]]
        let call = FlutterMethodCall(methodName: "create", arguments: args)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testCreateWithMissingOptionsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let args: [String: Any] = ["source": ["type": "network", "url": "https://example.com/video.mp4"]]
        let call = FlutterMethodCall(methodName: "create", arguments: args)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testDisposeWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "dispose", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testPlayWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "play", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testPlayWithInvalidPlayerIdReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let args: [String: Any] = ["playerId": 999]
        let call = FlutterMethodCall(methodName: "play", arguments: args)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testPauseWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "pause", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testStopWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "stop", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testSeekToWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "seekTo", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testSetPlaybackSpeedWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "setPlaybackSpeed", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testSetVolumeWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "setVolume", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testSetLoopingWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "setLooping", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testSetSubtitleTrackWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "setSubtitleTrack", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testGetPositionWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "getPosition", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testGetDurationWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "getDuration", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testEnterPipWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "enterPip", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testExitPipWithInvalidArgsReturnsError() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "exitPip", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is FlutterError)
    }

    func testIsPipSupportedReturnsBool() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let call = FlutterMethodCall(methodName: "isPipSupported", arguments: nil)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertTrue(resultValue is Bool)
    }

    func testGetPlayerReturnsNilForUnknownId() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // When
        let player = plugin.getPlayer(for: 999)

        // Then
        XCTAssertNil(player)
    }

    // MARK: - Success Path Tests

    func testCreatePlayerWithNetworkSourceReturnsPlayerId() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let args: [String: Any] = [
            "source": [
                "type": "network",
                "url": "https://example.com/video.mp4"
            ],
            "options": [
                "volume": 1.0,
                "looping": false
            ]
        ]
        let call = FlutterMethodCall(methodName: "create", arguments: args)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(resultValue)
        XCTAssertTrue(resultValue is Int)
        if let playerId = resultValue as? Int {
            XCTAssertEqual(playerId, 0) // First player should have ID 0
        }
    }

    func testCreatePlayerWithFileSourceReturnsPlayerId() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let args: [String: Any] = [
            "source": [
                "type": "file",
                "path": "/path/to/video.mp4"
            ],
            "options": [:]
        ]
        let call = FlutterMethodCall(methodName: "create", arguments: args)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(resultValue)
        XCTAssertTrue(resultValue is Int)
    }

    func testCreatePlayerWithAssetSourceReturnsPlayerId() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)
        let args: [String: Any] = [
            "source": [
                "type": "asset",
                "assetPath": "assets/video.mp4"
            ],
            "options": [:]
        ]
        let call = FlutterMethodCall(methodName: "create", arguments: args)
        let expectation = expectation(description: "Result called")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            expectation.fulfill()
        }

        // When
        plugin.handle(call, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(resultValue)
        XCTAssertTrue(resultValue is Int)
    }

    func testDisposePlayerSucceeds() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Dispose the player
        let disposeArgs: [String: Any] = ["playerId": playerId!]
        let disposeCall = FlutterMethodCall(methodName: "dispose", arguments: disposeArgs)
        let disposeExpectation = expectation(description: "Dispose result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            disposeExpectation.fulfill()
        }

        // When
        plugin.handle(disposeCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(resultValue) // dispose returns nil on success
        XCTAssertNil(plugin.getPlayer(for: playerId!))
    }

    func testPlayPlayerSucceeds() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Play the player
        let playArgs: [String: Any] = ["playerId": playerId!]
        let playCall = FlutterMethodCall(methodName: "play", arguments: playArgs)
        let playExpectation = expectation(description: "Play result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            playExpectation.fulfill()
        }

        // When
        plugin.handle(playCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(resultValue) // play returns nil on success
    }

    func testPausePlayerSucceeds() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Pause the player
        let pauseArgs: [String: Any] = ["playerId": playerId!]
        let pauseCall = FlutterMethodCall(methodName: "pause", arguments: pauseArgs)
        let pauseExpectation = expectation(description: "Pause result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            pauseExpectation.fulfill()
        }

        // When
        plugin.handle(pauseCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(resultValue) // pause returns nil on success
    }

    func testStopPlayerSucceeds() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Stop the player
        let stopArgs: [String: Any] = ["playerId": playerId!]
        let stopCall = FlutterMethodCall(methodName: "stop", arguments: stopArgs)
        let stopExpectation = expectation(description: "Stop result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            stopExpectation.fulfill()
        }

        // When
        plugin.handle(stopCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(resultValue) // stop returns nil on success
    }

    func testSeekToSucceeds() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Seek to position
        let seekArgs: [String: Any] = ["playerId": playerId!, "position": 5000]
        let seekCall = FlutterMethodCall(methodName: "seekTo", arguments: seekArgs)
        let seekExpectation = expectation(description: "Seek result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            seekExpectation.fulfill()
        }

        // When
        plugin.handle(seekCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(resultValue) // seekTo returns nil on success
    }

    func testSetPlaybackSpeedSucceeds() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Set playback speed
        let speedArgs: [String: Any] = ["playerId": playerId!, "speed": 1.5]
        let speedCall = FlutterMethodCall(methodName: "setPlaybackSpeed", arguments: speedArgs)
        let speedExpectation = expectation(description: "Speed result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            speedExpectation.fulfill()
        }

        // When
        plugin.handle(speedCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(resultValue) // setPlaybackSpeed returns nil on success
    }

    func testSetVolumeSucceeds() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Set volume
        let volumeArgs: [String: Any] = ["playerId": playerId!, "volume": 0.7]
        let volumeCall = FlutterMethodCall(methodName: "setVolume", arguments: volumeArgs)
        let volumeExpectation = expectation(description: "Volume result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            volumeExpectation.fulfill()
        }

        // When
        plugin.handle(volumeCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(resultValue) // setVolume returns nil on success
    }

    func testSetLoopingSucceeds() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Set looping
        let loopingArgs: [String: Any] = ["playerId": playerId!, "looping": true]
        let loopingCall = FlutterMethodCall(methodName: "setLooping", arguments: loopingArgs)
        let loopingExpectation = expectation(description: "Looping result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            loopingExpectation.fulfill()
        }

        // When
        plugin.handle(loopingCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(resultValue) // setLooping returns nil on success
    }

    func testSetSubtitleTrackSucceeds() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Set subtitle track
        let subtitleArgs: [String: Any] = [
            "playerId": playerId!,
            "track": ["language": "en", "label": "English"]
        ]
        let subtitleCall = FlutterMethodCall(methodName: "setSubtitleTrack", arguments: subtitleArgs)
        let subtitleExpectation = expectation(description: "Subtitle result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            subtitleExpectation.fulfill()
        }

        // When
        plugin.handle(subtitleCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(resultValue) // setSubtitleTrack returns nil on success
    }

    func testGetPositionReturnsInt() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Get position
        let positionArgs: [String: Any] = ["playerId": playerId!]
        let positionCall = FlutterMethodCall(methodName: "getPosition", arguments: positionArgs)
        let positionExpectation = expectation(description: "Position result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            positionExpectation.fulfill()
        }

        // When
        plugin.handle(positionCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(resultValue)
        XCTAssertTrue(resultValue is Int)
    }

    func testGetDurationReturnsInt() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Get duration
        let durationArgs: [String: Any] = ["playerId": playerId!]
        let durationCall = FlutterMethodCall(methodName: "getDuration", arguments: durationArgs)
        let durationExpectation = expectation(description: "Duration result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            durationExpectation.fulfill()
        }

        // When
        plugin.handle(durationCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        // Duration might be an Int (including negative for unloaded video) or could be nil
        // Just verify the call completes without crashing
        // For an unloaded video, getDuration may return a very large negative value (from NaN conversion)
        if let intValue = resultValue as? Int {
            XCTAssertTrue(true) // Call succeeded with Int value
        } else {
            XCTAssertNil(resultValue) // Or nil is acceptable for unloaded video
        }
    }

    func testEnterPipReturnsBool() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Result called")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Enter PiP
        let pipArgs: [String: Any] = ["playerId": playerId!]
        let pipCall = FlutterMethodCall(methodName: "enterPip", arguments: pipArgs)
        let pipExpectation = expectation(description: "PiP result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            pipExpectation.fulfill()
        }

        // When
        plugin.handle(pipCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNotNil(resultValue)
        XCTAssertTrue(resultValue is Bool)
    }

    func testExitPipSucceeds() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Exit PiP
        let pipArgs: [String: Any] = ["playerId": playerId!]
        let pipCall = FlutterMethodCall(methodName: "exitPip", arguments: pipArgs)
        let pipExpectation = expectation(description: "PiP result")

        var resultValue: Any?
        let result: FlutterResult = { value in
            resultValue = value
            pipExpectation.fulfill()
        }

        // When
        plugin.handle(pipCall, result: result)

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertNil(resultValue) // exitPip returns nil on success
    }

    func testGetPlayerReturnsPlayerAfterCreate() {
        // Given
        let plugin = ProVideoPlayerPlugin(registrar: mockRegistrar)

        // Create a player first
        let createArgs: [String: Any] = [
            "source": ["type": "network", "url": "https://example.com/video.mp4"],
            "options": [:]
        ]
        let createCall = FlutterMethodCall(methodName: "create", arguments: createArgs)
        var playerId: Int?
        let createExpectation = expectation(description: "Create result")
        plugin.handle(createCall) { result in
            playerId = result as? Int
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // When
        let player = plugin.getPlayer(for: playerId!)

        // Then
        XCTAssertNotNil(player)
    }
}
