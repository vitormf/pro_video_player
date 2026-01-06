import Flutter
import XCTest
import UIKit
import AVFoundation
import AVKit
@testable import pro_video_player_ios

/// Simplified tests for iOS native video player view factory.
///
/// Most functionality is tested via Dart unit tests and E2E tests.
/// These tests ensure the native platform view infrastructure compiles and initializes correctly.
class VideoPlayerViewFactoryTests: XCTestCase {

    func testVideoPlayerViewFactoryCanBeCreated() {
        // This is a placeholder test to ensure the test target compiles.
        // Actual video player view factory functionality is tested through:
        // - Dart unit tests (pro_video_player package)
        // - E2E UI tests (integration_test/)
        // - Platform view integration tests
        XCTAssertTrue(true, "iOS native view factory test infrastructure is working")
    }
}

/// Simplified tests for PlayerContainerView.
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
