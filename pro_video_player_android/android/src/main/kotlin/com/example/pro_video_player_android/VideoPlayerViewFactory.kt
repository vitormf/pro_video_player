package com.example.pro_video_player_android

import android.content.Context
import android.view.View
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Controls mode for the video player view.
 */
enum class ControlsMode {
    /** No controls shown - video only. Use external widgets to control playback. */
    NONE,

    /** Native platform controls (ExoPlayer PlayerView default controls). */
    NATIVE;

    companion object {
        fun fromString(value: String?): ControlsMode = when (value?.lowercase()) {
            "native" -> NATIVE
            else -> NONE
        }
    }
}

class VideoPlayerViewFactory(
    private val plugin: ProVideoPlayerPlugin
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<*, *>
        val playerId = (creationParams?.get("playerId") as? Int) ?: -1
        val controlsModeString = creationParams?.get("controlsMode") as? String
        val controlsMode = ControlsMode.fromString(controlsModeString)
        val player = plugin.getPlayer(playerId)

        return VideoPlayerPlatformView(context, player, controlsMode)
    }
}

class VideoPlayerPlatformView(
    context: Context,
    private val videoPlayer: VideoPlayer?,
    private val controlsMode: ControlsMode
) : PlatformView {

    private val playerView: PlayerView = PlayerView(context).apply {
        // Show native ExoPlayer controls only when controlsMode is NATIVE
        useController = controlsMode == ControlsMode.NATIVE
        videoPlayer?.setPlayerView(this)
    }

    override fun getView(): View = playerView

    override fun dispose() {
        playerView.player = null
    }
}
