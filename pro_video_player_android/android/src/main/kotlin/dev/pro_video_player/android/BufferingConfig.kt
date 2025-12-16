package dev.pro_video_player.android

import androidx.media3.exoplayer.DefaultLoadControl

/**
 * Buffering configuration for ExoPlayer based on tier selection.
 *
 * Maps buffering tiers to ExoPlayer's DefaultLoadControl parameters.
 * Each tier provides different trade-offs between memory usage,
 * startup time, and playback smoothness.
 */
object BufferingConfig {

    /**
     * Buffer configuration parameters for a specific tier.
     *
     * @property minBufferMs Minimum buffer before playback starts
     * @property maxBufferMs Maximum buffer to maintain
     * @property bufferForPlaybackMs Buffer needed to resume playback
     * @property bufferForPlaybackAfterRebufferMs Buffer after rebuffering
     */
    data class BufferParams(
        val minBufferMs: Int,
        val maxBufferMs: Int,
        val bufferForPlaybackMs: Int,
        val bufferForPlaybackAfterRebufferMs: Int
    )

    /**
     * Returns buffer parameters for the given tier name.
     *
     * @param tierName The buffering tier name (min, low, medium, high, max)
     * @return BufferParams for the tier, defaulting to medium if unknown
     */
    fun getBufferParams(tierName: String?): BufferParams {
        return when (tierName?.lowercase()) {
            "min" -> BufferParams(
                minBufferMs = 1_000,  // Must be >= bufferForPlaybackAfterRebufferMs
                maxBufferMs = 2_000,
                bufferForPlaybackMs = 500,
                bufferForPlaybackAfterRebufferMs = 1_000
            )
            "low" -> BufferParams(
                minBufferMs = 2_000,  // Must be >= bufferForPlaybackAfterRebufferMs
                maxBufferMs = 5_000,
                bufferForPlaybackMs = 1_000,
                bufferForPlaybackAfterRebufferMs = 2_000
            )
            "medium" -> BufferParams(
                minBufferMs = 5_000,  // Must be >= bufferForPlaybackAfterRebufferMs
                maxBufferMs = 15_000,
                bufferForPlaybackMs = 2_500,
                bufferForPlaybackAfterRebufferMs = 5_000
            )
            // Values must match VideoPlayerConstants.getExoPlayerBufferConfig() in Dart
            "high" -> BufferParams(
                minBufferMs = 5_000,
                maxBufferMs = 30_000,
                bufferForPlaybackMs = 2_500,
                bufferForPlaybackAfterRebufferMs = 5_000
            )
            // Values must match VideoPlayerConstants.getExoPlayerBufferConfig() in Dart
            "max" -> BufferParams(
                minBufferMs = 10_000,
                maxBufferMs = 60_000,
                bufferForPlaybackMs = 5_000,
                bufferForPlaybackAfterRebufferMs = 10_000
            )
            else -> getBufferParams("medium") // Default to medium
        }
    }

    /**
     * Creates a LoadControl configured for the given buffering tier.
     *
     * @param tierName The buffering tier name (min, low, medium, high, max)
     * @return A configured DefaultLoadControl instance
     */
    fun createLoadControl(tierName: String?): DefaultLoadControl {
        val params = getBufferParams(tierName)
        return DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                params.minBufferMs,
                params.maxBufferMs,
                params.bufferForPlaybackMs,
                params.bufferForPlaybackAfterRebufferMs
            )
            .build()
    }
}
