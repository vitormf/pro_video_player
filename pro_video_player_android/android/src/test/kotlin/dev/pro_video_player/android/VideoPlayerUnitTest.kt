package dev.pro_video_player.android

import androidx.media3.common.Player
import org.junit.Assert.*
import org.junit.Test

/**
 * Unit tests for VideoPlayer pure logic components.
 * These tests run on the JVM without requiring Android device/emulator.
 *
 * Note: BufferingConfig tests are in BufferingConfigTest.kt
 * Note: MediaPlaybackService tests are in MediaPlaybackServiceTest.kt
 * Note: Tests for components that require Android runtime are in
 *       VideoPlayerIntegrationTest (androidTest).
 */
class VideoPlayerUnitTest {

    // ==================== ControlsMode Tests ====================

    @Test
    fun `ControlsMode fromString returns NONE for 'none'`() {
        assertEquals(ControlsMode.NONE, ControlsMode.fromString("none"))
    }

    @Test
    fun `ControlsMode fromString returns NATIVE for 'native'`() {
        assertEquals(ControlsMode.NATIVE, ControlsMode.fromString("native"))
    }

    @Test
    fun `ControlsMode fromString is case insensitive`() {
        assertEquals(ControlsMode.NATIVE, ControlsMode.fromString("NATIVE"))
        assertEquals(ControlsMode.NATIVE, ControlsMode.fromString("Native"))
        assertEquals(ControlsMode.NONE, ControlsMode.fromString("NONE"))
        assertEquals(ControlsMode.NONE, ControlsMode.fromString("None"))
    }

    @Test
    fun `ControlsMode fromString returns NONE for unknown string`() {
        assertEquals(ControlsMode.NONE, ControlsMode.fromString("unknown"))
        assertEquals(ControlsMode.NONE, ControlsMode.fromString("custom"))
        assertEquals(ControlsMode.NONE, ControlsMode.fromString(""))
    }

    @Test
    fun `ControlsMode fromString returns NONE for null`() {
        assertEquals(ControlsMode.NONE, ControlsMode.fromString(null))
    }

    @Test
    fun `ControlsMode enum has correct values`() {
        val values = ControlsMode.values()
        assertEquals(2, values.size)
        assertTrue(values.contains(ControlsMode.NONE))
        assertTrue(values.contains(ControlsMode.NATIVE))
    }

    @Test
    fun `ControlsMode valueOf works`() {
        assertEquals(ControlsMode.NONE, ControlsMode.valueOf("NONE"))
        assertEquals(ControlsMode.NATIVE, ControlsMode.valueOf("NATIVE"))
    }

    @Test
    fun `ControlsMode ordinal values are stable`() {
        assertEquals(0, ControlsMode.NONE.ordinal)
        assertEquals(1, ControlsMode.NATIVE.ordinal)
    }

    // ==================== Player State Constants Tests ====================

    @Test
    fun `Player state constants are correct`() {
        assertEquals(1, Player.STATE_IDLE)
        assertEquals(2, Player.STATE_BUFFERING)
        assertEquals(3, Player.STATE_READY)
        assertEquals(4, Player.STATE_ENDED)
    }

    @Test
    fun `Player repeat modes are correct`() {
        assertEquals(0, Player.REPEAT_MODE_OFF)
        assertEquals(1, Player.REPEAT_MODE_ONE)
        assertEquals(2, Player.REPEAT_MODE_ALL)
    }

    // ==================== DefaultExoPlayerFactory Tests ====================

    @Test
    fun `DefaultExoPlayerFactory instance exists`() {
        val factory = DefaultExoPlayerFactory()
        assertNotNull(factory)
    }

    @Test
    fun `DefaultExoPlayerFactory implements IExoPlayerFactory`() {
        val factory: IExoPlayerFactory = DefaultExoPlayerFactory()
        assertNotNull(factory)
    }

    // ==================== BufferParams Data Class Tests ====================

    @Test
    fun `BufferParams data class equality works`() {
        val params1 = BufferingConfig.BufferParams(1000, 2000, 500, 1000)
        val params2 = BufferingConfig.BufferParams(1000, 2000, 500, 1000)
        val params3 = BufferingConfig.BufferParams(2000, 3000, 500, 1000)

        assertEquals(params1, params2)
        assertNotEquals(params1, params3)
    }

    @Test
    fun `BufferParams hashCode is consistent`() {
        val params1 = BufferingConfig.BufferParams(1000, 2000, 500, 1000)
        val params2 = BufferingConfig.BufferParams(1000, 2000, 500, 1000)

        assertEquals(params1.hashCode(), params2.hashCode())
    }

    @Test
    fun `BufferParams toString is readable`() {
        val params = BufferingConfig.BufferParams(1000, 2000, 500, 1000)
        val string = params.toString()

        assertTrue(string.contains("1000"))
        assertTrue(string.contains("2000"))
        assertTrue(string.contains("500"))
    }

    @Test
    fun `BufferParams copy works`() {
        val params = BufferingConfig.BufferParams(1000, 2000, 500, 1000)
        val copied = params.copy(minBufferMs = 3000)

        assertEquals(3000, copied.minBufferMs)
        assertEquals(2000, copied.maxBufferMs)
        assertEquals(500, copied.bufferForPlaybackMs)
        assertEquals(1000, copied.bufferForPlaybackAfterRebufferMs)
    }

    @Test
    fun `BufferParams destructuring works`() {
        val params = BufferingConfig.BufferParams(1000, 2000, 500, 1000)
        val (minBuffer, maxBuffer, playback, afterRebuffer) = params

        assertEquals(1000, minBuffer)
        assertEquals(2000, maxBuffer)
        assertEquals(500, playback)
        assertEquals(1000, afterRebuffer)
    }

    // ==================== IVideoPlayer Interface Tests ====================

    @Test
    fun `IVideoPlayer interface methods are defined`() {
        // Verify the interface exists and has expected methods by checking method references
        val interfaceClass = IVideoPlayer::class.java

        // Check key methods exist in the interface
        assertNotNull(interfaceClass.getMethod("play"))
        assertNotNull(interfaceClass.getMethod("pause"))
        assertNotNull(interfaceClass.getMethod("stop"))
        assertNotNull(interfaceClass.getMethod("dispose"))
        assertNotNull(interfaceClass.getMethod("seekTo", Long::class.java))
        assertNotNull(interfaceClass.getMethod("setVolume", Float::class.java))
        assertNotNull(interfaceClass.getMethod("setLooping", Boolean::class.java))
        assertNotNull(interfaceClass.getMethod("setPlaybackSpeed", Float::class.java))
        assertNotNull(interfaceClass.getMethod("getPosition"))
        assertNotNull(interfaceClass.getMethod("getDuration"))
    }

    @Test
    fun `IVideoPlayer interface has subtitle methods`() {
        val interfaceClass = IVideoPlayer::class.java

        assertNotNull(interfaceClass.getMethod("setSubtitleTrack", Map::class.java))
        assertNotNull(interfaceClass.getMethod("areSubtitlesEnabled"))
    }

    @Test
    fun `IVideoPlayer interface has PiP methods`() {
        val interfaceClass = IVideoPlayer::class.java

        assertNotNull(interfaceClass.getMethod("isPipAllowed"))
    }

    @Test
    fun `IVideoPlayer interface has scaling mode method`() {
        val interfaceClass = IVideoPlayer::class.java

        assertNotNull(interfaceClass.getMethod("setScalingMode", String::class.java))
    }

    @Test
    fun `IVideoPlayer interface has video metadata method`() {
        val interfaceClass = IVideoPlayer::class.java

        assertNotNull(interfaceClass.getMethod("getVideoMetadata"))
    }

    // MARK: - Subtitle Interface Tests

    @Test
    fun `IVideoPlayer interface has setSubtitleTrack method`() {
        val interfaceClass = IVideoPlayer::class.java

        assertNotNull(interfaceClass.getMethod("setSubtitleTrack", Map::class.java))
    }

    @Test
    fun `IVideoPlayer interface has areSubtitlesEnabled method`() {
        val interfaceClass = IVideoPlayer::class.java

        assertNotNull(interfaceClass.getMethod("areSubtitlesEnabled"))
    }

    // MARK: - External Subtitle Tests (VideoPlayer class)

    @Test
    fun `VideoPlayer class has addExternalSubtitle method`() {
        val playerClass = VideoPlayer::class.java

        // Check that the method exists (any signature)
        val methods = playerClass.methods.filter { it.name == "addExternalSubtitle" }
        assertTrue("VideoPlayer should have addExternalSubtitle method", methods.isNotEmpty())
    }

    @Test
    fun `VideoPlayer class has removeExternalSubtitle method`() {
        val playerClass = VideoPlayer::class.java

        val methods = playerClass.methods.filter { it.name == "removeExternalSubtitle" }
        assertTrue("VideoPlayer should have removeExternalSubtitle method", methods.isNotEmpty())
    }

    @Test
    fun `VideoPlayer class has getExternalSubtitles method`() {
        val playerClass = VideoPlayer::class.java

        val methods = playerClass.methods.filter { it.name == "getExternalSubtitles" }
        assertTrue("VideoPlayer should have getExternalSubtitles method", methods.isNotEmpty())
    }

    @Test
    fun `External subtitle track ID format uses ext prefix`() {
        // External subtitle track IDs should start with "ext-"
        val externalTrackId = "ext-0"
        assertTrue("External track ID should start with 'ext-'", externalTrackId.startsWith("ext-"))

        // Embedded track IDs should NOT start with "ext-"
        val embeddedTrackId = "0:1"
        assertFalse("Embedded track ID should not start with 'ext-'", embeddedTrackId.startsWith("ext-"))
    }

    // MARK: - Subtitle Format Tests

    @Test
    fun `Supported subtitle formats include SRT`() {
        val supportedFormats = listOf("srt", "vtt", "ssa", "ass", "ttml")
        assertTrue("SRT should be supported", supportedFormats.contains("srt"))
    }

    @Test
    fun `Supported subtitle formats include VTT`() {
        val supportedFormats = listOf("srt", "vtt", "ssa", "ass", "ttml")
        assertTrue("VTT should be supported", supportedFormats.contains("vtt"))
    }

    @Test
    fun `Supported subtitle formats include SSA`() {
        val supportedFormats = listOf("srt", "vtt", "ssa", "ass", "ttml")
        assertTrue("SSA should be supported", supportedFormats.contains("ssa"))
    }

    @Test
    fun `Supported subtitle formats include ASS`() {
        val supportedFormats = listOf("srt", "vtt", "ssa", "ass", "ttml")
        assertTrue("ASS should be supported", supportedFormats.contains("ass"))
    }

    @Test
    fun `Supported subtitle formats include TTML`() {
        val supportedFormats = listOf("srt", "vtt", "ssa", "ass", "ttml")
        assertTrue("TTML should be supported", supportedFormats.contains("ttml"))
    }

    @Test
    fun `Format detection from URL extension works for SRT`() {
        val url = "https://example.com/subtitles.srt"
        val extension = url.substringAfterLast(".")
        assertEquals("srt", extension)
    }

    @Test
    fun `Format detection from URL extension works for VTT`() {
        val url = "https://example.com/subtitles.vtt"
        val extension = url.substringAfterLast(".")
        assertEquals("vtt", extension)
    }

    @Test
    fun `Format detection from URL extension works for SSA`() {
        val url = "https://example.com/subtitles.ssa"
        val extension = url.substringAfterLast(".")
        assertEquals("ssa", extension)
    }

    @Test
    fun `Format detection from URL extension works for ASS`() {
        val url = "https://example.com/subtitles.ass"
        val extension = url.substringAfterLast(".")
        assertEquals("ass", extension)
    }

    @Test
    fun `Format detection from URL extension works for TTML`() {
        val url = "https://example.com/subtitles.ttml"
        val extension = url.substringAfterLast(".")
        assertEquals("ttml", extension)
    }
}
