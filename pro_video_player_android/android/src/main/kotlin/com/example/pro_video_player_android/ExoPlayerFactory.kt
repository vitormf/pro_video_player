package com.example.pro_video_player_android

import android.content.Context
import androidx.media3.exoplayer.ExoPlayer

/**
 * Factory for creating ExoPlayer instances.
 * This allows for easier testing by providing a way to inject mock players.
 * Returns a builder so the caller can configure it before building.
 */
interface IExoPlayerFactory {
    fun createBuilder(context: Context): ExoPlayer.Builder
}

/**
 * Default implementation that creates real ExoPlayer builders.
 */
class DefaultExoPlayerFactory : IExoPlayerFactory {
    override fun createBuilder(context: Context): ExoPlayer.Builder {
        return ExoPlayer.Builder(context)
    }
}
