package com.example.pro_video_player_android

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger

/**
 * Test Activity for testing PiP and fullscreen functionality.
 * This activity can host a VideoPlayer and provides methods to test
 * Activity-dependent features like PiP and fullscreen.
 */
class TestActivity : Activity() {

    var videoPlayer: VideoPlayer? = null
        private set

    private var container: FrameLayout? = null
    private var playerView: PlayerView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Create a container for the player view
        container = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        setContentView(container)
    }

    /**
     * Initialize a VideoPlayer with the given source and options.
     */
    fun initializePlayer(
        playerId: Int,
        messenger: BinaryMessenger,
        source: Map<String, Any>,
        options: Map<String, Any>
    ) {
        videoPlayer = VideoPlayer(playerId, this, messenger, source, options)

        // Create and attach PlayerView
        playerView = PlayerView(this).apply {
            useController = false
            videoPlayer?.setPlayerView(this)
        }
        container?.addView(playerView)
    }

    /**
     * Test entering PiP mode.
     */
    fun testEnterPip(): Boolean {
        return videoPlayer?.enterPip(this) ?: false
    }

    /**
     * Test exiting PiP mode.
     */
    fun testExitPip() {
        videoPlayer?.exitPip()
    }

    /**
     * Test entering fullscreen mode.
     */
    fun testEnterFullscreen(): Boolean {
        return videoPlayer?.enterFullscreen(this) ?: false
    }

    /**
     * Test exiting fullscreen mode.
     */
    fun testExitFullscreen() {
        videoPlayer?.exitFullscreen(this)
    }

    /**
     * Check if player is in fullscreen mode.
     */
    fun isFullscreen(): Boolean {
        return videoPlayer?.getIsFullscreen() ?: false
    }

    /**
     * Check if PiP is allowed for this player.
     */
    fun isPipAllowed(): Boolean {
        return videoPlayer?.isPipAllowed() ?: false
    }

    /**
     * Test onEnterBackground callback.
     */
    fun testOnEnterBackground() {
        videoPlayer?.onEnterBackground(this)
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        // PiP state change is handled internally by the VideoPlayer
        // through its own lifecycle callbacks
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // Auto-enter PiP if configured
        videoPlayer?.onEnterBackground(this)
    }

    override fun onDestroy() {
        videoPlayer?.dispose()
        videoPlayer = null
        super.onDestroy()
    }
}
