package dev.pro_video_player.android

import org.junit.Test
import org.junit.Assert.*

class BufferingConfigTest {

    @Test
    fun `getBufferParams returns min tier params`() {
        val params = BufferingConfig.getBufferParams("min")
        // minBufferMs must be >= bufferForPlaybackAfterRebufferMs (ExoPlayer constraint)
        assertEquals(1_000, params.minBufferMs)
        assertEquals(2_000, params.maxBufferMs)
        assertEquals(500, params.bufferForPlaybackMs)
        assertEquals(1_000, params.bufferForPlaybackAfterRebufferMs)
    }

    @Test
    fun `getBufferParams returns low tier params`() {
        val params = BufferingConfig.getBufferParams("low")
        // minBufferMs must be >= bufferForPlaybackAfterRebufferMs (ExoPlayer constraint)
        assertEquals(2_000, params.minBufferMs)
        assertEquals(5_000, params.maxBufferMs)
        assertEquals(1_000, params.bufferForPlaybackMs)
        assertEquals(2_000, params.bufferForPlaybackAfterRebufferMs)
    }

    @Test
    fun `getBufferParams returns medium tier params`() {
        val params = BufferingConfig.getBufferParams("medium")
        // minBufferMs must be >= bufferForPlaybackAfterRebufferMs (ExoPlayer constraint)
        assertEquals(5_000, params.minBufferMs)
        assertEquals(15_000, params.maxBufferMs)
        assertEquals(2_500, params.bufferForPlaybackMs)
        assertEquals(5_000, params.bufferForPlaybackAfterRebufferMs)
    }

    @Test
    fun `getBufferParams returns high tier params`() {
        // Values must match VideoPlayerConstants.getExoPlayerBufferConfig('high') in Dart
        val params = BufferingConfig.getBufferParams("high")
        assertEquals(5_000, params.minBufferMs)
        assertEquals(30_000, params.maxBufferMs)
        assertEquals(2_500, params.bufferForPlaybackMs)
        assertEquals(5_000, params.bufferForPlaybackAfterRebufferMs)
    }

    @Test
    fun `getBufferParams returns max tier params`() {
        // Values must match VideoPlayerConstants.getExoPlayerBufferConfig('max') in Dart
        val params = BufferingConfig.getBufferParams("max")
        assertEquals(10_000, params.minBufferMs)
        assertEquals(60_000, params.maxBufferMs)
        assertEquals(5_000, params.bufferForPlaybackMs)
        assertEquals(10_000, params.bufferForPlaybackAfterRebufferMs)
    }

    @Test
    fun `getBufferParams is case insensitive`() {
        val paramsLower = BufferingConfig.getBufferParams("high")
        val paramsUpper = BufferingConfig.getBufferParams("HIGH")
        val paramsMixed = BufferingConfig.getBufferParams("High")

        assertEquals(paramsLower, paramsUpper)
        assertEquals(paramsLower, paramsMixed)
    }

    @Test
    fun `getBufferParams returns medium for null`() {
        val params = BufferingConfig.getBufferParams(null)
        val mediumParams = BufferingConfig.getBufferParams("medium")
        assertEquals(mediumParams, params)
    }

    @Test
    fun `getBufferParams returns medium for unknown tier`() {
        val params = BufferingConfig.getBufferParams("unknown")
        val mediumParams = BufferingConfig.getBufferParams("medium")
        assertEquals(mediumParams, params)
    }

    @Test
    fun `getBufferParams returns medium for empty string`() {
        val params = BufferingConfig.getBufferParams("")
        val mediumParams = BufferingConfig.getBufferParams("medium")
        assertEquals(mediumParams, params)
    }

    // Note: createLoadControl requires Android runtime (DefaultLoadControl.Builder)
    // and is tested via integration tests instead of unit tests

    @Test
    fun `buffer params have increasing values from min to max`() {
        val minParams = BufferingConfig.getBufferParams("min")
        val lowParams = BufferingConfig.getBufferParams("low")
        val mediumParams = BufferingConfig.getBufferParams("medium")
        val highParams = BufferingConfig.getBufferParams("high")
        val maxParams = BufferingConfig.getBufferParams("max")

        // Verify minBufferMs is non-decreasing (some tiers have same value due to ExoPlayer constraint)
        assertTrue(minParams.minBufferMs <= lowParams.minBufferMs)
        assertTrue(lowParams.minBufferMs <= mediumParams.minBufferMs)
        assertTrue(mediumParams.minBufferMs <= highParams.minBufferMs)
        assertTrue(highParams.minBufferMs <= maxParams.minBufferMs)

        // Verify maxBufferMs strictly increases
        assertTrue(minParams.maxBufferMs < lowParams.maxBufferMs)
        assertTrue(lowParams.maxBufferMs < mediumParams.maxBufferMs)
        assertTrue(mediumParams.maxBufferMs < highParams.maxBufferMs)
        assertTrue(highParams.maxBufferMs < maxParams.maxBufferMs)
    }
}
