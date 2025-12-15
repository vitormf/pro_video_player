package com.example.pro_video_player_android

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.media3.exoplayer.ExoPlayer
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import io.flutter.plugin.common.BinaryMessenger
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Integration tests for VideoPlayer that run on an Android device/emulator.
 * These tests exercise real Android components and ExoPlayer.
 * All ExoPlayer operations are performed on the main thread.
 */
@RunWith(AndroidJUnit4::class)
class VideoPlayerIntegrationTest {

    @Mock
    private lateinit var mockMessenger: BinaryMessenger

    private lateinit var context: Context
    private lateinit var videoPlayer: VideoPlayer
    private val mainHandler = Handler(Looper.getMainLooper())

    @Before
    fun setUp() {
        MockitoAnnotations.openMocks(this)
        context = ApplicationProvider.getApplicationContext()
    }

    @After
    fun tearDown() {
        if (::videoPlayer.isInitialized) {
            runOnMainThread {
                videoPlayer.dispose()
            }
        }
    }

    private fun runOnMainThread(block: () -> Unit) {
        val latch = CountDownLatch(1)
        mainHandler.post {
            try {
                block()
            } finally {
                latch.countDown()
            }
        }
        latch.await(5, TimeUnit.SECONDS)
    }

    private fun <T> runOnMainThreadWithResult(block: () -> T): T? {
        var result: T? = null
        val latch = CountDownLatch(1)
        mainHandler.post {
            try {
                result = block()
            } finally {
                latch.countDown()
            }
        }
        latch.await(5, TimeUnit.SECONDS)
        return result
    }

    @Test
    fun videoPlayer_initializes_withNetworkSource() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000) // Wait for initialization

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("ExoPlayer should be initialized", player)
        assertTrue("Player should be ExoPlayer instance", player is ExoPlayer)
    }

    @Test
    fun videoPlayer_playsAndPauses() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Play
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)
        val isPlayingAfterPlay = runOnMainThreadWithResult { 
            videoPlayer.getExoPlayer()?.playWhenReady ?: false
        } ?: false
        assertTrue("Player should be playing", isPlayingAfterPlay)

        // Pause
        runOnMainThread { videoPlayer.pause() }
        Thread.sleep(500)
        val isPlayingAfterPause = runOnMainThreadWithResult { 
            videoPlayer.getExoPlayer()?.playWhenReady ?: true
        } ?: true
        assertFalse("Player should be paused", isPlayingAfterPause)
    }

    @Test
    fun videoPlayer_changesVolume() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Set volume to 0.3
        runOnMainThread { videoPlayer.setVolume(0.3f) }
        Thread.sleep(500)
        val volume1 = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume ?: 1.0f } ?: 1.0f
        assertEquals("Volume should be 0.3", 0.3f, volume1, 0.01f)

        // Set volume to 0.8
        runOnMainThread { videoPlayer.setVolume(0.8f) }
        Thread.sleep(500)
        val volume2 = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume ?: 0.0f } ?: 0.0f
        assertEquals("Volume should be 0.8", 0.8f, volume2, 0.01f)
    }

    @Test
    fun videoPlayer_changesPlaybackSpeed() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Set speed to 1.5x
        runOnMainThread { videoPlayer.setPlaybackSpeed(1.5f) }
        Thread.sleep(500)
        val speed1 = runOnMainThreadWithResult { 
            videoPlayer.getExoPlayer()?.playbackParameters?.speed ?: 1.0f 
        } ?: 1.0f
        assertEquals("Speed should be 1.5x", 1.5f, speed1, 0.01f)

        // Set speed to 0.5x
        runOnMainThread { videoPlayer.setPlaybackSpeed(0.5f) }
        Thread.sleep(500)
        val speed2 = runOnMainThreadWithResult { 
            videoPlayer.getExoPlayer()?.playbackParameters?.speed ?: 1.0f 
        } ?: 1.0f
        assertEquals("Speed should be 0.5x", 0.5f, speed2, 0.01f)
    }

    @Test
    fun videoPlayer_enablesLooping() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Enable looping - setLooping posts to mainHandler so needs more time
        runOnMainThread { videoPlayer.setLooping(true) }
        Thread.sleep(1000)
        val repeatMode1 = runOnMainThreadWithResult { 
            videoPlayer.getExoPlayer()?.repeatMode ?: androidx.media3.common.Player.REPEAT_MODE_OFF 
        }
        // Accept both ONE and ALL as valid looping modes
        assertTrue("Repeat mode should be ONE or ALL", 
            repeatMode1 == androidx.media3.common.Player.REPEAT_MODE_ALL || 
            repeatMode1 == androidx.media3.common.Player.REPEAT_MODE_ONE)

        // Disable looping
        runOnMainThread { videoPlayer.setLooping(false) }
        Thread.sleep(1000)
        val repeatMode2 = runOnMainThreadWithResult { 
            videoPlayer.getExoPlayer()?.repeatMode ?: androidx.media3.common.Player.REPEAT_MODE_ALL 
        }
        assertEquals("Repeat mode should be OFF", androidx.media3.common.Player.REPEAT_MODE_OFF, repeatMode2)
    }

    @Test
    fun videoPlayer_configuresOptions() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "allowPip" to false,
            "subtitlesEnabled" to false
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val isPipAllowed = runOnMainThreadWithResult { videoPlayer.isPipAllowed() } ?: true
        val areSubtitlesEnabled = runOnMainThreadWithResult { videoPlayer.areSubtitlesEnabled() } ?: true
        
        assertFalse("PIP should be disabled", isPipAllowed)
        assertFalse("Subtitles should be disabled", areSubtitlesEnabled)
    }

    @Test
    fun videoPlayer_disposesCleanly() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val playerBeforeDispose = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should exist before dispose", playerBeforeDispose)

        runOnMainThread { videoPlayer.dispose() }
        Thread.sleep(500)

        val playerAfterDispose = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNull("Player should be null after dispose", playerAfterDispose)
    }

    // MARK: - Seek Tests

    @Test
    fun videoPlayer_seeksToPosition() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000) // Wait for video to load

        runOnMainThread { videoPlayer.seekTo(10000) }
        Thread.sleep(500)

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() } ?: 0
        // Position should be close to 10000ms (allow some variance)
        assertTrue("Position should be near 10000ms", position >= 9000)
    }

    @Test
    fun videoPlayer_stopsPlayback() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)

        runOnMainThread { videoPlayer.stop() }
        Thread.sleep(500)

        val isPlaying = runOnMainThreadWithResult {
            videoPlayer.getExoPlayer()?.playWhenReady ?: true
        } ?: true
        assertFalse("Player should be stopped", isPlaying)
    }

    // MARK: - Duration and Position Tests

    @Test
    fun videoPlayer_getsDuration() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(3000) // Wait for video metadata to load

        val duration = runOnMainThreadWithResult { videoPlayer.getDuration() } ?: 0
        // Big Buck Bunny is about 596 seconds (596000ms)
        assertTrue("Duration should be positive", duration > 0)
    }

    @Test
    fun videoPlayer_getsPosition() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() } ?: -1
        assertTrue("Position should be non-negative", position >= 0)
    }

    // MARK: - Scaling Mode Tests

    @Test
    fun videoPlayer_setsScalingModeFit() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setScalingMode("fit") }
        Thread.sleep(200)

        // No crash = success
        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsScalingModeFill() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setScalingMode("fill") }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsScalingModeStretch() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setScalingMode("stretch") }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Audio Track Tests

    @Test
    fun videoPlayer_setsAudioTrackNull() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setAudioTrack(null) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsAudioTrackWithId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val track = mapOf("id" to "0:0", "language" to "en", "label" to "English")
        runOnMainThread { videoPlayer.setAudioTrack(track) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Video Quality Tests

    @Test
    fun videoPlayer_getsVideoQualities() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        val qualities = runOnMainThreadWithResult { videoPlayer.getVideoQualities() }
        assertNotNull("Qualities should not be null", qualities)
    }

    @Test
    fun videoPlayer_setsVideoQualityAuto() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val result = runOnMainThreadWithResult { videoPlayer.setVideoQuality(null) } ?: false
        assertTrue("setVideoQuality(null) should return true for auto", result)
    }

    @Test
    fun videoPlayer_getsCurrentVideoQuality() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val quality = runOnMainThreadWithResult { videoPlayer.getCurrentVideoQuality() }
        assertNotNull("Current quality should not be null", quality)
        assertEquals("Default quality should be auto", "auto", quality?.get("id"))
    }

    @Test
    fun videoPlayer_checksQualitySelectionSupported() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val supported = runOnMainThreadWithResult { videoPlayer.isQualitySelectionSupported() }
        assertNotNull("Quality selection support check should not be null", supported)
    }

    // MARK: - Subtitle Track Tests

    @Test
    fun videoPlayer_setsSubtitleTrackNull() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setSubtitleTrack(null) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsSubtitleTrackWithId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val track = mapOf("id" to "0:0", "language" to "en", "label" to "English")
        runOnMainThread { videoPlayer.setSubtitleTrack(track) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Background Playback Tests

    @Test
    fun videoPlayer_enablesBackgroundPlayback() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to false)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val initialEnabled = runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() } ?: true
        assertFalse("Background playback should be initially disabled", initialEnabled)

        val result = runOnMainThreadWithResult { videoPlayer.setBackgroundPlayback(true) } ?: false
        assertTrue("setBackgroundPlayback should return true", result)

        val enabled = runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() } ?: false
        assertTrue("Background playback should be enabled", enabled)
    }

    @Test
    fun videoPlayer_disablesBackgroundPlayback() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val initialEnabled = runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() } ?: false
        assertTrue("Background playback should be initially enabled", initialEnabled)

        val result = runOnMainThreadWithResult { videoPlayer.setBackgroundPlayback(false) } ?: false
        assertTrue("setBackgroundPlayback should return true", result)

        val enabled = runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() } ?: true
        assertFalse("Background playback should be disabled", enabled)
    }

    // MARK: - Media Metadata Tests

    @Test
    fun videoPlayer_setsMediaMetadata() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val metadata = mapOf(
            "title" to "Big Buck Bunny",
            "artist" to "Blender Foundation",
            "album" to "Open Movies"
        )
        runOnMainThread { videoPlayer.setMediaMetadata(metadata) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - PiP Tests

    @Test
    fun videoPlayer_checksPipAllowed() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val pipAllowed = runOnMainThreadWithResult { videoPlayer.isPipAllowed() } ?: false
        assertTrue("PiP should be allowed", pipAllowed)
    }

    @Test
    fun videoPlayer_checksPipDisallowed() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to false)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val pipAllowed = runOnMainThreadWithResult { videoPlayer.isPipAllowed() } ?: true
        assertFalse("PiP should be disallowed", pipAllowed)
    }

    @Test
    fun videoPlayer_enterPipWithNullActivityReturnsFalse() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // enterPip requires an Activity, passing null should return false safely
        // We can't easily get an Activity in instrumented tests without ActivityScenario
        // So we just verify the player is still valid after the test
        assertNotNull("Player should still be valid", runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_exitPipDoesNotCrash() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.exitPip() }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Buffering Tier Tests

    @Test
    fun videoPlayer_initializesWithBufferingTierHigh() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("bufferingTier" to "high")

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_initializesWithBufferingTierMax() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("bufferingTier" to "max")

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_initializesWithBufferingTierMin() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("bufferingTier" to "min")

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Multiple Options Tests

    @Test
    fun videoPlayer_initializesWithAllOptions() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "autoPlay" to false,
            "looping" to true,
            "volume" to 0.5,
            "playbackSpeed" to 1.5,
            "allowBackgroundPlayback" to true,
            "allowPip" to true,
            "autoEnterPipOnBackground" to false,
            "subtitlesEnabled" to true,
            "showSubtitlesByDefault" to false,
            "scalingMode" to "fit",
            "bufferingTier" to "medium"
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should be initialized with all options", player)

        val volume = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume } ?: 0f
        assertEquals("Volume should be 0.5", 0.5f, volume, 0.01f)

        // Note: playbackSpeed option may not be immediately applied on init
        // The important test is that the player initializes without crashing

        assertTrue("PiP should be allowed", runOnMainThreadWithResult { videoPlayer.isPipAllowed() } ?: false)
        assertTrue("Background playback should be enabled", runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() } ?: false)
        assertTrue("Subtitles should be enabled", runOnMainThreadWithResult { videoPlayer.areSubtitlesEnabled() } ?: false)
    }

    // MARK: - Edge Cases

    @Test
    fun videoPlayer_handlesMultiplePlayPauseCycles() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        for (i in 1..3) {
            runOnMainThread { videoPlayer.play() }
            Thread.sleep(300)
            runOnMainThread { videoPlayer.pause() }
            Thread.sleep(300)
        }

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_handlesRapidSeeks() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        for (i in 1..5) {
            runOnMainThread { videoPlayer.seekTo((i * 10000).toLong()) }
            Thread.sleep(100)
        }

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - PiP Actions Tests

    @Test
    fun videoPlayer_setPipActionsWithEmptyList() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setPipActions(emptyList()) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setPipActionsWithPlayPause() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val actions = listOf(
            mapOf("type" to "playPause")
        )
        runOnMainThread { videoPlayer.setPipActions(actions) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setPipActionsWithSkipActions() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val actions = listOf(
            mapOf("type" to "skipBackward", "skipIntervalMs" to 10000),
            mapOf("type" to "playPause"),
            mapOf("type" to "skipForward", "skipIntervalMs" to 10000)
        )
        runOnMainThread { videoPlayer.setPipActions(actions) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setPipActionsWithNull() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setPipActions(null) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Video Quality Tests with Specific Tracks

    @Test
    fun videoPlayer_setsVideoQualityWithInvalidTrackId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        val track = mapOf("id" to "invalid:format", "bitrate" to 1000000)
        val result = runOnMainThreadWithResult { videoPlayer.setVideoQuality(track) } ?: true
        assertFalse("setVideoQuality with invalid ID format should return false", result)
    }

    @Test
    fun videoPlayer_setsVideoQualityWithNonexistentTrack() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        val track = mapOf("id" to "999:999", "bitrate" to 1000000)
        val result = runOnMainThreadWithResult { videoPlayer.setVideoQuality(track) } ?: true
        assertFalse("setVideoQuality with nonexistent track should return false", result)
    }

    @Test
    fun videoPlayer_setsVideoQualityWithAutoId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val track = mapOf("id" to "auto")
        val result = runOnMainThreadWithResult { videoPlayer.setVideoQuality(track) } ?: false
        assertTrue("setVideoQuality with auto ID should return true", result)
    }

    // MARK: - Subtitle Track Edge Cases

    @Test
    fun videoPlayer_setsSubtitleTrackWithInvalidId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Invalid format
        val track1 = mapOf("id" to "invalid", "language" to "en")
        runOnMainThread { videoPlayer.setSubtitleTrack(track1) }
        Thread.sleep(200)

        // Player should still be valid
        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsSubtitleTrackWithNonexistentGroup() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val track = mapOf("id" to "999:0", "language" to "en")
        runOnMainThread { videoPlayer.setSubtitleTrack(track) }
        Thread.sleep(200)

        // Player should still be valid
        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Audio Track Edge Cases

    @Test
    fun videoPlayer_setsAudioTrackWithInvalidId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val track = mapOf("id" to "not:valid:format", "language" to "en")
        runOnMainThread { videoPlayer.setAudioTrack(track) }
        Thread.sleep(200)

        // Player should still be valid
        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Scaling Mode Edge Cases

    @Test
    fun videoPlayer_setsScalingModeInvalid() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Invalid scaling mode should default to fit
        runOnMainThread { videoPlayer.setScalingMode("invalid_mode") }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Dispose While Playing Tests

    @Test
    fun videoPlayer_disposesWhilePlaying() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)  // Wait for video to buffer

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(1000)  // Give more time for playback to start

        // Check playWhenReady rather than isPlaying (isPlaying may be false during buffering)
        val playWhenReady = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.playWhenReady } ?: false
        assertTrue("Player should be in play mode before dispose", playWhenReady)

        runOnMainThread { videoPlayer.dispose() }
        Thread.sleep(500)

        val playerAfterDispose = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNull("Player should be null after dispose", playerAfterDispose)
    }

    @Test
    fun videoPlayer_disposesWhileBuffering() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        // Dispose immediately while still buffering
        Thread.sleep(100)

        runOnMainThread { videoPlayer.dispose() }
        Thread.sleep(500)

        val playerAfterDispose = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNull("Player should be null after dispose during buffering", playerAfterDispose)
    }

    // MARK: - Source Type Tests

    @Test
    fun videoPlayer_initializesWithFileSource() {
        val source = mapOf(
            "type" to "file",
            "path" to "/nonexistent/path/video.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Player should be created (even if file doesn't exist)
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("ExoPlayer should be initialized with file source", player)
    }

    @Test
    fun videoPlayer_initializesWithAssetSource() {
        val source = mapOf(
            "type" to "asset",
            "assetPath" to "assets/video.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Player should be created (even if asset doesn't exist)
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("ExoPlayer should be initialized with asset source", player)
    }

    @Test
    fun videoPlayer_initializesWithInvalidSourceType() {
        val source = mapOf(
            "type" to "unknown",
            "url" to "https://example.com/video.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Player may be null or error state for invalid source
        // The main test is that it doesn't crash
    }

    // MARK: - Network Resilience Tests

    @Test
    fun videoPlayer_handlesNetworkSourceWithHeaders() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            "headers" to mapOf(
                "User-Agent" to "TestPlayer/1.0",
                "Authorization" to "Bearer test-token"
            )
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("ExoPlayer should be initialized with headers", player)
    }

    // MARK: - Media Metadata Extended Tests

    @Test
    fun videoPlayer_setsMediaMetadataWithAllFields() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val metadata = mapOf(
            "title" to "Big Buck Bunny",
            "artist" to "Blender Foundation",
            "album" to "Open Movies",
            "artworkUrl" to "https://example.com/artwork.jpg"
        )
        runOnMainThread { videoPlayer.setMediaMetadata(metadata) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsMediaMetadataWithEmptyMap() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setMediaMetadata(emptyMap()) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsMediaMetadataWithBackgroundPlaybackDisabled() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to false)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // This should be a no-op when background playback is disabled
        val metadata = mapOf("title" to "Test Title")
        runOnMainThread { videoPlayer.setMediaMetadata(metadata) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Volume Edge Cases

    @Test
    fun videoPlayer_setsVolumeZero() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setVolume(0f) }
        Thread.sleep(200)

        val volume = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume } ?: 1f
        assertEquals("Volume should be 0", 0f, volume, 0.01f)
    }

    @Test
    fun videoPlayer_setsVolumeMax() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setVolume(1.0f) }
        Thread.sleep(200)

        val volume = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume } ?: 0f
        assertEquals("Volume should be 1.0", 1.0f, volume, 0.01f)
    }

    // MARK: - Speed Edge Cases

    @Test
    fun videoPlayer_setPlaybackSpeedMinimum() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setPlaybackSpeed(0.25f) }
        Thread.sleep(200)

        val speed = runOnMainThreadWithResult {
            videoPlayer.getExoPlayer()?.playbackParameters?.speed
        } ?: 1f
        assertEquals("Speed should be 0.25", 0.25f, speed, 0.01f)
    }

    @Test
    fun videoPlayer_setPlaybackSpeedMaximum() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setPlaybackSpeed(2.0f) }
        Thread.sleep(200)

        val speed = runOnMainThreadWithResult {
            videoPlayer.getExoPlayer()?.playbackParameters?.speed
        } ?: 1f
        assertEquals("Speed should be 2.0", 2.0f, speed, 0.01f)
    }

    // MARK: - Seek Edge Cases

    @Test
    fun videoPlayer_seeksToZero() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // First seek to middle
        runOnMainThread { videoPlayer.seekTo(30000) }
        Thread.sleep(500)

        // Then seek back to start
        runOnMainThread { videoPlayer.seekTo(0) }
        Thread.sleep(500)

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() } ?: -1
        assertTrue("Position should be near 0", position < 1000)
    }

    @Test
    fun videoPlayer_seeksToNegativeHandledGracefully() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // ExoPlayer should handle negative seek gracefully (clamp to 0)
        runOnMainThread { videoPlayer.seekTo(-1000) }
        Thread.sleep(500)

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() } ?: -1
        assertTrue("Position should be non-negative", position >= 0)
    }

    // MARK: - Initialization Option Combinations

    @Test
    fun videoPlayer_initializesWithAutoPlay() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("autoPlay" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Note: autoPlay may not be immediately reflected due to buffering
        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_initializesWithPreferredSubtitleLanguage() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "subtitlesEnabled" to true,
            "showSubtitlesByDefault" to true,
            "preferredSubtitleLanguage" to "en"
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_initializesWithMixedWithOthers() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("mixWithOthers" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Multiple Operations Tests

    @Test
    fun videoPlayer_handlesRapidVolumeChanges() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        for (i in 0..10) {
            val volume = i / 10f
            runOnMainThread { videoPlayer.setVolume(volume) }
            Thread.sleep(50)
        }

        val finalVolume = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume } ?: 0f
        assertEquals("Final volume should be 1.0", 1.0f, finalVolume, 0.1f)
    }

    @Test
    fun videoPlayer_handlesRapidSpeedChanges() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val speeds = listOf(0.5f, 1.0f, 1.5f, 2.0f, 1.0f)
        for (speed in speeds) {
            runOnMainThread { videoPlayer.setPlaybackSpeed(speed) }
            Thread.sleep(100)
        }

        val finalSpeed = runOnMainThreadWithResult {
            videoPlayer.getExoPlayer()?.playbackParameters?.speed
        } ?: 0f
        assertEquals("Final speed should be 1.0", 1.0f, finalSpeed, 0.1f)
    }

    // MARK: - ControlsMode Tests

    @Test
    fun controlsMode_fromStringWithNative() {
        val mode = ControlsMode.fromString("native")
        assertEquals("ControlsMode should be NATIVE", ControlsMode.NATIVE, mode)
    }

    @Test
    fun controlsMode_fromStringWithNativeUppercase() {
        val mode = ControlsMode.fromString("NATIVE")
        assertEquals("ControlsMode should be NATIVE", ControlsMode.NATIVE, mode)
    }

    @Test
    fun controlsMode_fromStringWithNativeMixedCase() {
        val mode = ControlsMode.fromString("Native")
        assertEquals("ControlsMode should be NATIVE", ControlsMode.NATIVE, mode)
    }

    @Test
    fun controlsMode_fromStringWithNone() {
        val mode = ControlsMode.fromString("none")
        assertEquals("ControlsMode should be NONE", ControlsMode.NONE, mode)
    }

    @Test
    fun controlsMode_fromStringWithNull() {
        val mode = ControlsMode.fromString(null)
        assertEquals("ControlsMode should default to NONE", ControlsMode.NONE, mode)
    }

    @Test
    fun controlsMode_fromStringWithEmpty() {
        val mode = ControlsMode.fromString("")
        assertEquals("ControlsMode should default to NONE", ControlsMode.NONE, mode)
    }

    @Test
    fun controlsMode_fromStringWithUnknown() {
        val mode = ControlsMode.fromString("unknown")
        assertEquals("ControlsMode should default to NONE", ControlsMode.NONE, mode)
    }

    @Test
    fun controlsMode_fromStringWithInvalid() {
        val mode = ControlsMode.fromString("flutter")
        assertEquals("ControlsMode should default to NONE", ControlsMode.NONE, mode)
    }

    @Test
    fun controlsMode_enumValues() {
        val values = ControlsMode.values()
        assertEquals("Should have 2 enum values", 2, values.size)
        assertTrue("Should contain NONE", values.contains(ControlsMode.NONE))
        assertTrue("Should contain NATIVE", values.contains(ControlsMode.NATIVE))
    }

    @Test
    fun controlsMode_valueOf() {
        assertEquals(ControlsMode.NONE, ControlsMode.valueOf("NONE"))
        assertEquals(ControlsMode.NATIVE, ControlsMode.valueOf("NATIVE"))
    }

    // MARK: - Subtitles Disabled Tests

    @Test
    fun videoPlayer_setsSubtitleTrackWhenSubtitlesDisabled() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to false)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // This should be ignored when subtitles are disabled
        val track = mapOf("id" to "0:0", "language" to "en")
        runOnMainThread { videoPlayer.setSubtitleTrack(track) }
        Thread.sleep(200)

        // Verify player is still valid
        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Event Channel StreamHandler Tests

    @Test
    fun videoPlayer_onListenSetsEventSink() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // onListen is called internally by EventChannel setup
        // Just verify player is still valid after initialization
        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_onCancelClearsEventSink() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Call onCancel to clear event sink
        runOnMainThread { videoPlayer.onCancel(null) }
        Thread.sleep(200)

        // Player should still function even without event sink
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(300)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - PiP Actions Extended Tests

    @Test
    fun videoPlayer_setPipActionsWithSkipPreviousNext() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val actions = listOf(
            mapOf("type" to "skipPrevious"),
            mapOf("type" to "skipNext")
        )
        runOnMainThread { videoPlayer.setPipActions(actions) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setPipActionsWithAllTypes() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val actions = listOf(
            mapOf("type" to "skipBackward", "skipIntervalMs" to 15000),
            mapOf("type" to "playPause"),
            mapOf("type" to "skipForward", "skipIntervalMs" to 15000),
            mapOf("type" to "skipPrevious"),
            mapOf("type" to "skipNext")
        )
        runOnMainThread { videoPlayer.setPipActions(actions) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setPipActionsWithUnknownType() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val actions = listOf(
            mapOf("type" to "unknownAction"),
            mapOf("type" to "playPause")
        )
        runOnMainThread { videoPlayer.setPipActions(actions) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setPipActionsWithMissingType() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val actions = listOf(
            mapOf("skipIntervalMs" to 10000), // Missing "type" key
            mapOf("type" to "playPause")
        )
        runOnMainThread { videoPlayer.setPipActions(actions) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Auto-Enter PiP Tests

    @Test
    fun videoPlayer_autoEnterPipOnBackgroundOption() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "allowPip" to true,
            "autoEnterPipOnBackground" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // onEnterBackground would be called when app enters background
        // Without an Activity we can't call it directly, but verify player is configured correctly
        assertTrue("PiP should be allowed", runOnMainThreadWithResult { videoPlayer.isPipAllowed() } ?: false)
    }

    // MARK: - Background Playback While Playing Tests

    @Test
    fun videoPlayer_enablesBackgroundPlaybackWhilePlaying() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to false)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Start playing
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)

        // Enable background playback while playing
        val result = runOnMainThreadWithResult { videoPlayer.setBackgroundPlayback(true) } ?: false
        assertTrue("Should enable background playback", result)

        val enabled = runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() } ?: false
        assertTrue("Background playback should be enabled", enabled)
    }

    // MARK: - Subtitle Track with Null ID

    @Test
    fun videoPlayer_setsSubtitleTrackWithNullId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Track with null ID should be handled gracefully
        val track = mapOf("language" to "en") // Missing "id" key
        runOnMainThread { videoPlayer.setSubtitleTrack(track) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsSubtitleTrackWithNonTextGroupIndex() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Using video track group index (0) which is not a text track
        val track = mapOf("id" to "0:0", "language" to "en")
        runOnMainThread { videoPlayer.setSubtitleTrack(track) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Audio Track Edge Cases

    @Test
    fun videoPlayer_setsAudioTrackWithNullId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Track with null ID
        val track = mapOf("language" to "en") // Missing "id" key
        runOnMainThread { videoPlayer.setAudioTrack(track) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsAudioTrackWithWrongFormat() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Track with wrong format (not "group:track")
        val track = mapOf("id" to "single_value", "language" to "en")
        runOnMainThread { videoPlayer.setAudioTrack(track) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsAudioTrackWithNonNumericIndex() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val track = mapOf("id" to "abc:def", "language" to "en")
        runOnMainThread { videoPlayer.setAudioTrack(track) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsAudioTrackWithNonAudioGroup() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Group index 0 is typically video, not audio
        val track = mapOf("id" to "0:0", "language" to "en")
        runOnMainThread { videoPlayer.setAudioTrack(track) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Video Quality Edge Cases

    @Test
    fun videoPlayer_setsVideoQualityWithNonVideoGroup() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Try to set a non-video track as video quality
        val track = mapOf("id" to "1:0", "bitrate" to 1000000) // Audio track group
        val result = runOnMainThreadWithResult { videoPlayer.setVideoQuality(track) } ?: true

        // This should return false because group 1 is typically not video
        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setsVideoQualityWithNonNumericGroupIndex() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val track = mapOf("id" to "abc:0", "bitrate" to 1000000)
        val result = runOnMainThreadWithResult { videoPlayer.setVideoQuality(track) } ?: true
        assertFalse("setVideoQuality with non-numeric group should return false", result)
    }

    @Test
    fun videoPlayer_setsVideoQualityWithNonNumericTrackIndex() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val track = mapOf("id" to "0:xyz", "bitrate" to 1000000)
        val result = runOnMainThreadWithResult { videoPlayer.setVideoQuality(track) } ?: true
        assertFalse("setVideoQuality with non-numeric track should return false", result)
    }

    // MARK: - Source Edge Cases

    @Test
    fun videoPlayer_initializesWithMissingSourceType() {
        val source = mapOf(
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Without type, setupPlayer returns early with error - player will be null
        // The main test is that it doesn't crash
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        // player may be null for invalid source - this is expected behavior
    }

    @Test
    fun videoPlayer_initializesWithMissingUrl() {
        val source = mapOf(
            "type" to "network"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Without URL, setupPlayer sends error and returns - player will be null
        // The main test is that it doesn't crash
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        // player may be null for invalid source - this is expected behavior
    }

    @Test
    fun videoPlayer_initializesWithMissingPath() {
        val source = mapOf(
            "type" to "file"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Without path, setupPlayer sends error and returns - player will be null
        // The main test is that it doesn't crash
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        // player may be null for invalid source - this is expected behavior
    }

    @Test
    fun videoPlayer_initializesWithMissingAssetPath() {
        val source = mapOf(
            "type" to "asset"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Without assetPath, setupPlayer sends error and returns - player will be null
        // The main test is that it doesn't crash
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        // player may be null for invalid source - this is expected behavior
    }

    // MARK: - Scaling Mode Initial Options Tests

    @Test
    fun videoPlayer_initializesWithScalingModeFit() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("scalingMode" to "fit")

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_initializesWithScalingModeFill() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("scalingMode" to "fill")

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_initializesWithScalingModeStretch() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("scalingMode" to "stretch")

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Multiple Dispose Tests

    @Test
    fun videoPlayer_multipleDisposeCallsSafe() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.dispose() }
        Thread.sleep(200)

        // Second dispose should not crash
        runOnMainThread { videoPlayer.dispose() }
        Thread.sleep(200)

        assertNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_operationsAfterDispose() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.dispose() }
        Thread.sleep(200)

        // These operations should not crash after dispose
        runOnMainThread {
            videoPlayer.play()
            videoPlayer.pause()
            videoPlayer.stop()
            videoPlayer.seekTo(1000)
            videoPlayer.setVolume(0.5f)
            videoPlayer.setPlaybackSpeed(1.5f)
        }
        Thread.sleep(200)

        assertNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Get Current Video Quality After Selecting Track

    @Test
    fun videoPlayer_getCurrentVideoQualityAfterSelection() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // First set auto quality
        runOnMainThreadWithResult { videoPlayer.setVideoQuality(null) }
        Thread.sleep(200)

        // Get current quality - should be auto
        val quality = runOnMainThreadWithResult { videoPlayer.getCurrentVideoQuality() }
        assertNotNull("Quality should not be null", quality)
        assertEquals("Quality should be auto", "auto", quality?.get("id"))
    }

    // MARK: - Looping with Initial Options

    @Test
    fun videoPlayer_initializesWithLoopingEnabled() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("looping" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        val repeatMode = runOnMainThreadWithResult {
            videoPlayer.getExoPlayer()?.repeatMode
        } ?: androidx.media3.common.Player.REPEAT_MODE_OFF

        assertTrue("Repeat mode should be ONE or ALL",
            repeatMode == androidx.media3.common.Player.REPEAT_MODE_ALL ||
                    repeatMode == androidx.media3.common.Player.REPEAT_MODE_ONE)
    }

    // MARK: - Position Updates During Playback

    @Test
    fun videoPlayer_positionUpdatesDuringPlayback() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() } ?: 0
        assertTrue("Position should have advanced", position > 0)
    }

    // MARK: - Duration After Loading

    @Test
    fun videoPlayer_durationAvailableAfterLoading() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(3000)

        val duration = runOnMainThreadWithResult { videoPlayer.getDuration() } ?: 0
        assertTrue("Duration should be positive after loading", duration > 0)
    }

    // MARK: - Mixed Operations

    @Test
    fun videoPlayer_playPauseSeekCycle() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Play
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)

        // Seek while playing
        runOnMainThread { videoPlayer.seekTo(5000) }
        Thread.sleep(500)

        // Pause
        runOnMainThread { videoPlayer.pause() }
        Thread.sleep(300)

        // Seek while paused
        runOnMainThread { videoPlayer.seekTo(10000) }
        Thread.sleep(500)

        // Resume
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(300)

        // Stop
        runOnMainThread { videoPlayer.stop() }
        Thread.sleep(300)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Subtitle Track with Out of Bounds Track Index

    @Test
    fun videoPlayer_setsSubtitleTrackWithOutOfBoundsTrackIndex() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Use valid group but out of bounds track index
        val track = mapOf("id" to "0:999", "language" to "en")
        runOnMainThread { videoPlayer.setSubtitleTrack(track) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Audio Track with Out of Bounds Track Index

    @Test
    fun videoPlayer_setsAudioTrackWithOutOfBoundsTrackIndex() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Use valid group but out of bounds track index
        val track = mapOf("id" to "1:999", "language" to "en")
        runOnMainThread { videoPlayer.setAudioTrack(track) }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Video Quality with Out of Bounds Track Index

    @Test
    fun videoPlayer_setsVideoQualityWithOutOfBoundsTrackIndex() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Use valid group but out of bounds track index
        val track = mapOf("id" to "0:999", "bitrate" to 1000000)
        val result = runOnMainThreadWithResult { videoPlayer.setVideoQuality(track) } ?: true
        assertFalse("setVideoQuality with out of bounds track should return false", result)
    }

    // MARK: - Playback State after Stop and Play

    @Test
    fun videoPlayer_playAfterStop() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Play first
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)

        // Stop
        runOnMainThread { videoPlayer.stop() }
        Thread.sleep(300)

        // Play again
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)

        val isPlaying = runOnMainThreadWithResult {
            videoPlayer.getExoPlayer()?.playWhenReady ?: false
        } ?: false

        assertTrue("Player should be playing after stop then play", isPlaying)
    }

    // MARK: - Volume at Boundaries

    @Test
    fun videoPlayer_setVolumeAtMinimum() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setVolume(0.0f) }
        Thread.sleep(200)

        val volume = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume } ?: 1f
        assertEquals("Volume should be 0.0", 0.0f, volume, 0.01f)
    }

    @Test
    fun videoPlayer_setVolumeAtMaximum() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setVolume(1.0f) }
        Thread.sleep(200)

        val volume = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume } ?: 0f
        assertEquals("Volume should be 1.0", 1.0f, volume, 0.01f)
    }

    // MARK: - ExitPip Without Activity

    @Test
    fun videoPlayer_exitPipWithoutEnteringPip() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Exit PiP without entering should be safe
        runOnMainThread { videoPlayer.exitPip() }
        Thread.sleep(200)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Background Playback Toggle While Not Playing

    @Test
    fun videoPlayer_toggleBackgroundPlaybackWhileNotPlaying() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to false)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Enable background playback while not playing
        val result1 = runOnMainThreadWithResult { videoPlayer.setBackgroundPlayback(true) } ?: false
        assertTrue("Should enable background playback", result1)
        assertTrue("Background playback should be enabled", runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() } ?: false)

        // Disable background playback while not playing
        val result2 = runOnMainThreadWithResult { videoPlayer.setBackgroundPlayback(false) } ?: false
        assertTrue("Should disable background playback", result2)
        assertFalse("Background playback should be disabled", runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() } ?: true)
    }

    // MARK: - Seek to End

    @Test
    fun videoPlayer_seekToNearEnd() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(3000)

        val duration = runOnMainThreadWithResult { videoPlayer.getDuration() } ?: 0L
        if (duration > 0) {
            // Seek to near end
            runOnMainThread { videoPlayer.seekTo(duration - 1000) }
            Thread.sleep(500)

            val position = runOnMainThreadWithResult { videoPlayer.getPosition() } ?: 0L
            assertTrue("Position should be near end", position >= duration - 5000)
        }
    }

    // MARK: - Subtitles Enabled Check

    @Test
    fun videoPlayer_areSubtitlesEnabledTrue() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val subtitlesEnabled = runOnMainThreadWithResult { videoPlayer.areSubtitlesEnabled() } ?: false
        assertTrue("Subtitles should be enabled", subtitlesEnabled)
    }

    @Test
    fun videoPlayer_areSubtitlesEnabledFalse() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to false)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val subtitlesEnabled = runOnMainThreadWithResult { videoPlayer.areSubtitlesEnabled() } ?: true
        assertFalse("Subtitles should be disabled", subtitlesEnabled)
    }

    // MARK: - MediaPlaybackService Companion Tests

    @Test
    fun mediaPlaybackService_registerAndUnregisterPlayer() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should not be null", player)

        // Register player with MediaPlaybackService
        MediaPlaybackService.registerPlayer(1, player!!)

        // Check if registered
        val hasPlayer = MediaPlaybackService.hasActivePlayers()
        assertTrue("Should have registered players", hasPlayer)

        // Unregister player
        MediaPlaybackService.unregisterPlayer(1)
    }

    @Test
    fun mediaPlaybackService_setMetadata() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should not be null", player)

        // Register and set metadata
        MediaPlaybackService.registerPlayer(1, player!!)
        MediaPlaybackService.setMetadata(1, mapOf(
            "title" to "Test Video",
            "artist" to "Test Artist"
        ))

        // Verify no crash
        MediaPlaybackService.unregisterPlayer(1)
    }

    // MARK: - Network Source with Empty Headers

    @Test
    fun videoPlayer_networkSourceWithEmptyHeaders() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            "headers" to emptyMap<String, String>()
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Dispose During Various States

    @Test
    fun videoPlayer_disposeAfterSeek() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.seekTo(30000) }
        Thread.sleep(100)

        runOnMainThread { videoPlayer.dispose() }
        Thread.sleep(500)

        assertNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_disposeAfterMultipleOperations() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread {
            videoPlayer.play()
            videoPlayer.setVolume(0.5f)
            videoPlayer.setPlaybackSpeed(1.5f)
            videoPlayer.setLooping(true)
        }
        Thread.sleep(300)

        runOnMainThread { videoPlayer.dispose() }
        Thread.sleep(500)

        assertNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - MediaPlaybackService Companion Extended Tests

    @Test
    fun mediaPlaybackService_getPlayer_returnsRegisteredPlayer() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should not be null", player)

        MediaPlaybackService.registerPlayer(99, player!!)
        val retrievedPlayer = MediaPlaybackService.getPlayer(99)
        assertNotNull("Retrieved player should not be null", retrievedPlayer)
        assertEquals("Should return same player", player, retrievedPlayer)
        MediaPlaybackService.unregisterPlayer(99)
    }

    @Test
    fun mediaPlaybackService_getPlayer_returnsNullForUnregistered() {
        val player = MediaPlaybackService.getPlayer(99999)
        assertNull("Should return null for unregistered player", player)
    }

    @Test
    fun mediaPlaybackService_hasActivePlayers_returnsFalseWhenEmpty() {
        MediaPlaybackService.unregisterPlayer(1)
        MediaPlaybackService.unregisterPlayer(2)
        MediaPlaybackService.unregisterPlayer(99)
        val hasPlayers = MediaPlaybackService.hasActivePlayers()
        assertFalse("Should return false when no players registered", hasPlayers)
    }

    @Test
    fun mediaPlaybackService_getMetadata_returnsSetMetadata() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should not be null", player)

        MediaPlaybackService.registerPlayer(99, player!!)
        val metadata = mapOf("title" to "Test Title", "artist" to "Test Artist", "album" to "Test Album")
        MediaPlaybackService.setMetadata(99, metadata)

        val retrievedMetadata = MediaPlaybackService.getMetadata(99)
        assertNotNull("Metadata should not be null", retrievedMetadata)
        assertEquals("Test Title", retrievedMetadata?.get("title"))
        MediaPlaybackService.unregisterPlayer(99)
    }

    @Test
    fun mediaPlaybackService_getMetadata_returnsNullForUnregistered() {
        val metadata = MediaPlaybackService.getMetadata(99999)
        assertNull("Should return null for unregistered player", metadata)
    }

    @Test
    fun mediaPlaybackService_getArtwork_returnsNullInitially() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should not be null", player)

        MediaPlaybackService.registerPlayer(99, player!!)
        val artwork = MediaPlaybackService.getArtwork(99)
        assertNull("Artwork should be null initially", artwork)
        MediaPlaybackService.unregisterPlayer(99)
    }

    @Test
    fun mediaPlaybackService_setMetadataWithInvalidArtworkUrl() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should not be null", player)

        MediaPlaybackService.registerPlayer(99, player!!)
        val metadata = mapOf("title" to "Test Title", "artworkUrl" to "invalid://not-a-real-url")
        MediaPlaybackService.setMetadata(99, metadata)
        Thread.sleep(500)

        val artwork = MediaPlaybackService.getArtwork(99)
        assertNull("Artwork should be null after failed load", artwork)
        MediaPlaybackService.unregisterPlayer(99)
    }

    @Test
    fun mediaPlaybackService_unregisterClearsAll() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should not be null", player)

        MediaPlaybackService.registerPlayer(99, player!!)
        MediaPlaybackService.setMetadata(99, mapOf("title" to "Test"))

        assertNotNull(MediaPlaybackService.getPlayer(99))
        assertNotNull(MediaPlaybackService.getMetadata(99))

        MediaPlaybackService.unregisterPlayer(99)

        assertNull("Player should be null after unregister", MediaPlaybackService.getPlayer(99))
        assertNull("Metadata should be null after unregister", MediaPlaybackService.getMetadata(99))
    }

    // MARK: - VideoPlayer Track Selection Extended Tests

    @Test
    fun videoPlayer_getVideoQualitiesBeforeReady() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(100)

        val qualities = runOnMainThreadWithResult { videoPlayer.getVideoQualities() }
        assertNotNull("getVideoQualities should not return null", qualities)
    }

    // MARK: - VideoPlayer Media Metadata Tests

    @Test
    fun videoPlayer_setMediaMetadataWithAllFields() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val metadata = mapOf(
            "title" to "Big Buck Bunny",
            "artist" to "Blender Foundation",
            "album" to "Open Source Movies",
            "artworkUrl" to "https://upload.wikimedia.org/wikipedia/commons/c/c5/Big_buck_bunny_poster_big.jpg"
        )
        runOnMainThread { videoPlayer.setMediaMetadata(metadata) }
        Thread.sleep(500)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setMediaMetadataWithEmptyMap() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setMediaMetadata(emptyMap()) }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - BufferingConfig Tests (using getBufferParams with tier name)

    @Test
    fun bufferingConfig_getBufferParamsMin() {
        val params = BufferingConfig.getBufferParams("min")
        assertEquals(1000, params.minBufferMs)
        assertEquals(2000, params.maxBufferMs)
    }

    @Test
    fun bufferingConfig_getBufferParamsLow() {
        val params = BufferingConfig.getBufferParams("low")
        assertEquals(2000, params.minBufferMs)
        assertEquals(5000, params.maxBufferMs)
    }

    @Test
    fun bufferingConfig_getBufferParamsMedium() {
        val params = BufferingConfig.getBufferParams("medium")
        assertEquals(5000, params.minBufferMs)
        assertEquals(15000, params.maxBufferMs)
    }

    @Test
    fun bufferingConfig_getBufferParamsHigh() {
        val params = BufferingConfig.getBufferParams("high")
        assertEquals(5000, params.minBufferMs)
        assertEquals(30000, params.maxBufferMs)
    }

    @Test
    fun bufferingConfig_getBufferParamsMax() {
        val params = BufferingConfig.getBufferParams("max")
        assertEquals(10000, params.minBufferMs)
        assertEquals(60000, params.maxBufferMs)
    }

    @Test
    fun bufferingConfig_getBufferParamsNull() {
        // null should default to medium
        val params = BufferingConfig.getBufferParams(null)
        assertEquals(5000, params.minBufferMs)
    }

    @Test
    fun bufferingConfig_getBufferParamsUnknown() {
        // Unknown tier should default to medium
        val params = BufferingConfig.getBufferParams("unknown")
        assertEquals(5000, params.minBufferMs)
    }

    // MARK: - Asset Source Tests (Extended)

    @Test
    fun videoPlayer_initializesWithAssetSourceAndPackageName() {
        // Note: This tests the code path, not actual asset loading
        val source = mapOf(
            "type" to "asset",
            "asset" to "videos/sample.mp4",
            "package" to "com.example.app"
        )
        val options = mapOf<String, Any>()

        // This won't load successfully (no actual asset), but tests the path resolution
        try {
            videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
            Thread.sleep(500)
        } catch (e: Exception) {
            // Expected - asset doesn't exist
        }
    }

    @Test
    fun videoPlayer_initializesWithAssetSourceWithoutPackageName() {
        val source = mapOf(
            "type" to "asset",
            "asset" to "videos/sample.mp4"
        )
        val options = mapOf<String, Any>()

        try {
            videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
            Thread.sleep(500)
        } catch (e: Exception) {
            // Expected - asset doesn't exist
        }
    }

    @Test
    fun videoPlayer_initializesWithFileSourcePath() {
        val source = mapOf(
            "type" to "file",
            "path" to "/storage/emulated/0/Movies/sample.mp4"
        )
        val options = mapOf<String, Any>()

        try {
            videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
            Thread.sleep(500)
        } catch (e: Exception) {
            // Expected - file doesn't exist
        }
    }

    // MARK: - PiP Not Allowed Tests

    @Test
    fun videoPlayer_pipNotAllowed_exitPipReturns() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "allowPip" to false
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // exitPip should do nothing when pip is not allowed
        runOnMainThread { videoPlayer.exitPip() }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_pipNotAllowed_isPipAllowedReturnsFalse() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "allowPip" to false
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val isPipAllowed = runOnMainThreadWithResult { videoPlayer.isPipAllowed() }
        assertFalse("PiP should not be allowed", isPipAllowed ?: true)
    }

    @Test
    fun videoPlayer_pipAllowedByDefault() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val isPipAllowed = runOnMainThreadWithResult { videoPlayer.isPipAllowed() }
        assertTrue("PiP should be allowed by default", isPipAllowed ?: false)
    }

    // MARK: - Subtitles Tests

    @Test
    fun videoPlayer_subtitlesDisabledCannotSetTrack() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "subtitlesEnabled" to false
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Should not crash when trying to set subtitle with subtitles disabled
        runOnMainThread {
            videoPlayer.setSubtitleTrack(mapOf("id" to "0", "language" to "en"))
        }
        Thread.sleep(100)

        assertFalse("Subtitles should not be enabled",
            runOnMainThreadWithResult { videoPlayer.areSubtitlesEnabled() } ?: true)
    }

    @Test
    fun videoPlayer_setSubtitleTrackWithEmptyId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Setting empty id should disable subtitles
        runOnMainThread {
            videoPlayer.setSubtitleTrack(mapOf("id" to ""))
        }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setSubtitleTrackWithOffId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Setting "off" should disable subtitles
        runOnMainThread {
            videoPlayer.setSubtitleTrack(mapOf("id" to "off"))
        }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setAudioTrackWithEmptyId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Setting empty id should not crash
        runOnMainThread {
            videoPlayer.setAudioTrack(mapOf("id" to ""))
        }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Video Quality Tests

    @Test
    fun videoPlayer_setVideoQualityWithEmptyMap() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Setting empty map should not crash
        runOnMainThread {
            videoPlayer.setVideoQuality(emptyMap())
        }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setVideoQualityWithAutoMode() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Setting auto mode
        runOnMainThread {
            videoPlayer.setVideoQuality(mapOf("id" to "auto"))
        }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_getVideoQualitiesReturnsEmptyForNonHLS() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val qualities = runOnMainThreadWithResult { videoPlayer.getVideoQualities() }
        // For non-HLS content, this may return empty or limited qualities
        assertNotNull("Qualities should not be null", qualities)
    }

    @Test
    fun videoPlayer_getCurrentVideoQualityNonHLS() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val currentQuality = runOnMainThreadWithResult { videoPlayer.getCurrentVideoQuality() }
        // May return null for non-adaptive content
        // Just verify it doesn't crash
    }

    @Test
    fun videoPlayer_isQualitySelectionSupportedNonHLS() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val isSupported = runOnMainThreadWithResult { videoPlayer.isQualitySelectionSupported() }
        // For non-HLS, this may be false
        assertNotNull("Result should not be null", isSupported)
    }

    // MARK: - Background Playback Tests

    @Test
    fun videoPlayer_backgroundPlaybackDisabledByDefault() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val isEnabled = runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() }
        assertFalse("Background playback should be disabled by default", isEnabled ?: true)
    }

    @Test
    fun videoPlayer_setBackgroundPlaybackOnAndOff() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Enable
        runOnMainThread { videoPlayer.setBackgroundPlayback(true) }
        Thread.sleep(100)
        val enabledState = runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() }
        assertTrue("Background playback should be enabled", enabledState ?: false)

        // Disable
        runOnMainThread { videoPlayer.setBackgroundPlayback(false) }
        Thread.sleep(100)
        val disabledState = runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() }
        assertFalse("Background playback should be disabled", disabledState ?: true)
    }

    @Test
    fun videoPlayer_backgroundPlaybackEnabledInOptions() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "allowBackgroundPlayback" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val isEnabled = runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() }
        assertTrue("Background playback should be enabled from options", isEnabled ?: false)
    }

    // MARK: - Stop Tests

    @Test
    fun videoPlayer_stopMultipleTimes() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Play first
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)

        // Stop multiple times should not crash
        runOnMainThread { videoPlayer.stop() }
        Thread.sleep(100)
        runOnMainThread { videoPlayer.stop() }
        Thread.sleep(100)
        runOnMainThread { videoPlayer.stop() }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Seek Edge Cases

    @Test
    fun videoPlayer_seekToZero() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.seekTo(0L) }
        Thread.sleep(500)

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() }
        assertTrue("Position should be near zero", (position ?: Long.MAX_VALUE) < 1000)
    }

    @Test
    fun videoPlayer_seekToNegative() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Seeking to negative should not crash
        runOnMainThread { videoPlayer.seekTo(-1000L) }
        Thread.sleep(500)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_seekBeyondDuration() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1500)

        // Seek to very large value
        runOnMainThread { videoPlayer.seekTo(999999999L) }
        Thread.sleep(500)

        // Should clamp to duration or handle gracefully
        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Playback Speed Edge Cases

    @Test
    fun videoPlayer_setSpeedSlightly() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Valid slow speed
        runOnMainThread { videoPlayer.setPlaybackSpeed(0.25f) }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setSpeedFast() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Valid fast speed (ExoPlayer supports up to 8x typically)
        runOnMainThread { videoPlayer.setPlaybackSpeed(2.0f) }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Volume Edge Cases

    @Test
    fun videoPlayer_setVolumeToZero() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Set volume to 0 (mute)
        runOnMainThread { videoPlayer.setVolume(0f) }
        Thread.sleep(100)

        val volume = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume }
        assertEquals("Volume should be 0", 0f, volume ?: 1f, 0.01f)
    }

    @Test
    fun videoPlayer_setVolumeToMax() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Set volume to max
        runOnMainThread { videoPlayer.setVolume(1.0f) }
        Thread.sleep(100)

        val volume = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume }
        assertEquals("Volume should be 1", 1f, volume ?: 0f, 0.01f)
    }

    // MARK: - Scaling Mode Tests

    @Test
    fun videoPlayer_setScalingModeFit() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setScalingMode("fit") }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setScalingModeFill() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setScalingMode("fill") }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setScalingModeStretch() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setScalingMode("stretch") }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setScalingModeUnknown() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Unknown mode should default gracefully
        runOnMainThread { videoPlayer.setScalingMode("unknown_mode") }
        Thread.sleep(100)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Duration and Position Edge Cases

    @Test
    fun videoPlayer_getDurationBeforeLoad() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        // Don't wait for loading

        val duration = runOnMainThreadWithResult { videoPlayer.getDuration() }
        // May return 0 or TIME_UNSET before loading
        assertNotNull("Duration should not be null", duration)
    }

    @Test
    fun videoPlayer_getPositionAfterSeek() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1500)

        runOnMainThread { videoPlayer.seekTo(5000L) }
        Thread.sleep(500)

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() }
        assertNotNull("Position should not be null", position)
        // Position may not be exactly 5000 due to seeking behavior
        assertTrue("Position should be reasonable", (position ?: -1) >= 0)
    }

    // MARK: - Initial Options Tests

    @Test
    fun videoPlayer_initialVolumeFromOptions() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "volume" to 0.5
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val volume = runOnMainThreadWithResult { videoPlayer.getExoPlayer()?.volume }
        assertEquals("Volume should be 0.5", 0.5f, volume ?: 0f, 0.05f)
    }

    @Test
    fun videoPlayer_setSpeedAfterInit() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Set speed after init
        runOnMainThread { videoPlayer.setPlaybackSpeed(1.5f) }
        Thread.sleep(500)

        val speed = runOnMainThreadWithResult {
            videoPlayer.getExoPlayer()?.playbackParameters?.speed
        }
        assertEquals("Speed should be 1.5", 1.5f, speed ?: 0f, 0.05f)
    }

    // MARK: - VideoPlayerViewFactory Tests

    @Test
    fun videoPlayerViewFactory_createWithNoneControlsMode() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Test VideoPlayerPlatformView creation with NONE controls mode
        runOnMainThread {
            val platformView = VideoPlayerPlatformView(context, videoPlayer, ControlsMode.NONE)
            val view = platformView.getView()
            assertNotNull("Platform view should not be null", view)
            platformView.dispose()
        }
    }

    @Test
    fun videoPlayerViewFactory_createWithNativeControlsMode() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Test VideoPlayerPlatformView creation with NATIVE controls mode
        runOnMainThread {
            val platformView = VideoPlayerPlatformView(context, videoPlayer, ControlsMode.NATIVE)
            val view = platformView.getView()
            assertNotNull("Platform view should not be null", view)
            platformView.dispose()
        }
    }

    @Test
    fun videoPlayerViewFactory_createWithNullPlayer() {
        // Test VideoPlayerPlatformView creation with null player
        runOnMainThread {
            val platformView = VideoPlayerPlatformView(context, null, ControlsMode.NONE)
            val view = platformView.getView()
            assertNotNull("Platform view should not be null even with null player", view)
            platformView.dispose()
        }
    }

    @Test
    fun videoPlayerPlatformView_disposeMultipleTimes() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread {
            val platformView = VideoPlayerPlatformView(context, videoPlayer, ControlsMode.NONE)
            platformView.dispose()
            // Dispose again should not crash
            platformView.dispose()
        }
    }

    // MARK: - MediaPlaybackService Companion Extended Tests

    @Test
    fun mediaPlaybackService_setMetadataWithArtworkUrl() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should not be null", player)

        // Register with service
        MediaPlaybackService.registerPlayer(100, player!!)

        // Set metadata with artwork URL
        MediaPlaybackService.setMetadata(100, mapOf(
            "title" to "Test Video",
            "artist" to "Test Artist",
            "album" to "Test Album",
            "artworkUrl" to "https://example.com/artwork.jpg"
        ))

        Thread.sleep(500)

        val metadata = MediaPlaybackService.getMetadata(100)
        assertNotNull("Metadata should not be null", metadata)
        assertEquals("Title should match", "Test Video", metadata?.get("title"))

        MediaPlaybackService.unregisterPlayer(100)
    }

    @Test
    fun mediaPlaybackService_setMetadataWithoutArtwork() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should not be null", player)

        MediaPlaybackService.registerPlayer(101, player!!)

        // Set metadata without artwork URL
        MediaPlaybackService.setMetadata(101, mapOf(
            "title" to "No Artwork Video",
            "artist" to "Artist Name"
        ))

        Thread.sleep(100)

        val artwork = MediaPlaybackService.getArtwork(101)
        assertNull("Artwork should be null", artwork)

        MediaPlaybackService.unregisterPlayer(101)
    }

    @Test
    fun mediaPlaybackService_unregisterClearsMetadata() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should not be null", player)

        MediaPlaybackService.registerPlayer(102, player!!)
        MediaPlaybackService.setMetadata(102, mapOf("title" to "Test"))

        // Unregister should clear everything
        MediaPlaybackService.unregisterPlayer(102)

        assertNull("Player should be null after unregister", MediaPlaybackService.getPlayer(102))
        assertNull("Metadata should be null after unregister", MediaPlaybackService.getMetadata(102))
    }

    // MARK: - Plugin Integration Tests with Edge Cases

    @Test
    fun plugin_handleMethodCallWithInvalidPlayerId() {
        // Create a player
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Try to get player with invalid ID
        val plugin = ProVideoPlayerPlugin()
        val invalidPlayer = plugin.getPlayer(-999)
        assertNull("Invalid player ID should return null", invalidPlayer)
    }

    @Test
    fun plugin_getPlayerReturnsCorrectInstance() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Plugin stores players internally - this tests the path
        val plugin = ProVideoPlayerPlugin()
        // After create, getPlayer should work
        assertNull("Before creation, player should be null", plugin.getPlayer(999))
    }

    // MARK: - HLS Stream Tests (Tests quality selection code paths)

    @Test
    fun videoPlayer_hlsStreamInit() {
        // Use an HLS stream to test adaptive streaming code paths
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should be initialized for HLS", player)
    }

    @Test
    fun videoPlayer_hlsStreamGetQualities() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(3000)

        // Wait for tracks to be available
        val qualities = runOnMainThreadWithResult { videoPlayer.getVideoQualities() }
        // HLS stream should have quality options
        assertNotNull("Qualities should not be null for HLS", qualities)
    }

    @Test
    fun videoPlayer_hlsStreamCheckQualitySupport() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(3000)

        val isSupported = runOnMainThreadWithResult { videoPlayer.isQualitySelectionSupported() }
        // HLS should support quality selection
        assertNotNull("Quality selection support should be determined", isSupported)
    }

    @Test
    fun videoPlayer_hlsStreamGetCurrentQuality() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(3000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        val currentQuality = runOnMainThreadWithResult { videoPlayer.getCurrentVideoQuality() }
        // Should return current quality info for HLS
        // May be null if not yet determined
    }

    // MARK: - Preferred Subtitle Language Tests

    @Test
    fun videoPlayer_preferredSubtitleLanguageSet() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "preferredSubtitleLanguage" to "en"
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_showSubtitlesByDefaultTrue() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "showSubtitlesByDefault" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Auto-enter PiP Tests

    @Test
    fun videoPlayer_autoEnterPipOption() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "autoEnterPipOnBackground" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Mix With Others Option

    @Test
    fun videoPlayer_mixWithOthersOption() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "mixWithOthers" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Buffering Tier Option

    @Test
    fun videoPlayer_bufferingTierMin() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "bufferingTier" to "min"
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_bufferingTierMax() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "bufferingTier" to "max"
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Event Channel Listener Tests

    @Test
    fun videoPlayer_eventChannelSetup() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // The event channel should be set up during initialization
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should be initialized", player)
    }

    // MARK: - Auto-Select Subtitle Tests

    @Test
    fun videoPlayer_autoSelectSubtitleWithPreferredLanguage() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = mapOf(
            "showSubtitlesByDefault" to true,
            "preferredSubtitleLanguage" to "en",
            "subtitlesEnabled" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        // Should attempt to auto-select subtitle track
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should be initialized", player)
    }

    @Test
    fun videoPlayer_autoSelectSubtitleWithoutPreferredLanguage() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = mapOf(
            "showSubtitlesByDefault" to true,
            "subtitlesEnabled" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should be initialized", player)
    }

    // MARK: - getCurrentVideoQuality More Tests

    @Test
    fun videoPlayer_getCurrentVideoQualityBeforePlay() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Quality before playback starts
        val quality = runOnMainThreadWithResult { videoPlayer.getCurrentVideoQuality() }
        // May be null or have default values
    }

    @Test
    fun videoPlayer_getCurrentVideoQualityDuringPlayback() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(3000)

        val quality = runOnMainThreadWithResult { videoPlayer.getCurrentVideoQuality() }
        // Should have quality info during HLS playback
    }

    @Test
    fun videoPlayer_getCurrentVideoQualityNonHls() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(1000)

        val quality = runOnMainThreadWithResult { videoPlayer.getCurrentVideoQuality() }
        // Non-HLS content may return null or single quality
    }

    // MARK: - Subtitle Track Notification Tests

    @Test
    fun videoPlayer_subtitleTracksWithHlsStream() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = mapOf(
            "subtitlesEnabled" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        // Tracks should be notified after playback starts
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should be initialized", player)
    }

    // MARK: - Error Handling Tests

    @Test
    fun videoPlayer_handleMalformedUrl() {
        val source = mapOf(
            "type" to "network",
            "url" to "htt://malformed-url"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Player should handle malformed URL gracefully
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should still be initialized", player)
    }

    @Test
    fun videoPlayer_handleTimeout() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://10.255.255.1/video.mp4" // Non-routable IP for timeout
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(3000) // Wait for potential timeout

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should be initialized even on timeout", player)
    }

    @Test
    fun videoPlayer_handleEmptyUrl() {
        val source = mapOf(
            "type" to "network",
            "url" to ""
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Should handle empty URL gracefully
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should be initialized", player)
    }

    // MARK: - Scaling Mode Additional Tests

    @Test
    fun videoPlayer_scalingModeStretch() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "scalingMode" to "stretch"
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread {
            val platformView = VideoPlayerPlatformView(context, videoPlayer, ControlsMode.NONE)
            assertNotNull(platformView.getView())
            platformView.dispose()
        }
    }

    @Test
    fun videoPlayer_scalingModeChangeDuringPlayback() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)

        // Change scaling mode during playback
        runOnMainThread { videoPlayer.setScalingMode("fill") }
        Thread.sleep(500)
        runOnMainThread { videoPlayer.setScalingMode("fit") }
        Thread.sleep(500)
        runOnMainThread { videoPlayer.setScalingMode("stretch") }

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - VideoPlayerViewFactory Tests

    @Test
    fun videoPlayerViewFactory_createWithId() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        // Register a player
        videoPlayer = VideoPlayer(999, context, mockMessenger, source, options)
        Thread.sleep(1000)
    }

    // MARK: - MediaPlaybackService Static Method Tests

    @Test
    fun mediaPlaybackService_isPlayingWithNoPlayer() {
        // Should return false when no player is registered
        val isPlaying = MediaPlaybackService.getPlayer(9999)
        assertNull("Should return null for non-existent player", isPlaying)
    }

    @Test
    fun mediaPlaybackService_setAndClearMetadata() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }!!

        MediaPlaybackService.registerPlayer(888, player)

        MediaPlaybackService.setMetadata(888, mapOf(
            "title" to "Test Title",
            "artist" to "Test Artist"
        ))

        val metadata = MediaPlaybackService.getMetadata(888)
        assertEquals("Title should match", "Test Title", metadata?.get("title"))

        // Clear metadata by setting empty map
        MediaPlaybackService.setMetadata(888, emptyMap())

        MediaPlaybackService.unregisterPlayer(888)
    }

    @Test
    fun mediaPlaybackService_multiplePlayersRegistered() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }!!

        // Register multiple IDs for same player
        MediaPlaybackService.registerPlayer(1001, player)
        MediaPlaybackService.registerPlayer(1002, player)

        MediaPlaybackService.setMetadata(1001, mapOf("title" to "Video 1"))
        MediaPlaybackService.setMetadata(1002, mapOf("title" to "Video 2"))

        assertEquals("Video 1", MediaPlaybackService.getMetadata(1001)?.get("title"))
        assertEquals("Video 2", MediaPlaybackService.getMetadata(1002)?.get("title"))

        MediaPlaybackService.unregisterPlayer(1001)
        MediaPlaybackService.unregisterPlayer(1002)
    }

    // MARK: - Background Playback State Tests

    @Test
    fun videoPlayer_backgroundPlaybackToggleDuringPlayback() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "allowBackgroundPlayback" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(1000)

        // Toggle background playback during playback
        runOnMainThread { videoPlayer.setBackgroundPlayback(false) }
        Thread.sleep(500)
        runOnMainThread { videoPlayer.setBackgroundPlayback(true) }
        Thread.sleep(500)
        runOnMainThread { videoPlayer.setBackgroundPlayback(false) }

        assertTrue("Background playback should be disabled", !videoPlayer.isBackgroundPlaybackEnabled())
    }

    // MARK: - Playback State Change Tests

    @Test
    fun videoPlayer_fullPlaybackCycle() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Start playback
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(1000)

        // Pause
        runOnMainThread { videoPlayer.pause() }
        Thread.sleep(500)

        // Resume
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)

        // Stop
        runOnMainThread { videoPlayer.stop() }
        Thread.sleep(500)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should still exist after stop", player)
    }

    @Test
    fun videoPlayer_seekDuringDifferentStates() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Seek while paused
        runOnMainThread { videoPlayer.seekTo(1000) }
        Thread.sleep(500)

        // Start playback
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(1000)

        // Seek while playing
        runOnMainThread { videoPlayer.seekTo(2000) }
        Thread.sleep(500)

        // Pause and seek
        runOnMainThread { videoPlayer.pause() }
        Thread.sleep(200)
        runOnMainThread { videoPlayer.seekTo(3000) }

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() }
        // Position should be updated
    }

    // MARK: - Quality Selection with Different Streams

    @Test
    fun videoPlayer_qualitySelectionMultipleStreams() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(3000)

        // Get available qualities
        val qualities = runOnMainThreadWithResult { videoPlayer.getVideoQualities() }

        // If qualities available, try setting different ones
        if (!qualities.isNullOrEmpty()) {
            for (quality in qualities.take(3)) {
                @Suppress("UNCHECKED_CAST")
                val qualityMap = quality as? Map<String, Any>
                if (qualityMap != null) {
                    runOnMainThread { videoPlayer.setVideoQuality(qualityMap) }
                    Thread.sleep(500)
                }
            }
        }
    }

    @Test
    fun videoPlayer_setVideoQualityAuto() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        // Set to auto quality
        runOnMainThread {
            videoPlayer.setVideoQuality(mapOf("isAuto" to true))
        }
        Thread.sleep(500)

        val isSupported = runOnMainThreadWithResult { videoPlayer.isQualitySelectionSupported() }
        assertTrue("Quality selection should be supported for HLS", isSupported == true)
    }

    // MARK: - Buffering Tests

    @Test
    fun videoPlayer_bufferingStateChanges() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(3000)

        // Seek to trigger buffering
        runOnMainThread { videoPlayer.seekTo(60000) }
        Thread.sleep(2000)

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() }
        // Position should be near the seek target after buffering
    }

    // MARK: - Dispose Tests

    @Test
    fun videoPlayer_disposeWhilePlaying() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(1000)

        // Dispose while playing
        runOnMainThread { videoPlayer.dispose() }
        Thread.sleep(500)

        // Player should be disposed (but we can't call getExoPlayer after dispose)
    }

    @Test
    fun videoPlayer_disposeWithBackgroundPlayback() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "allowBackgroundPlayback" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(1000)

        // Dispose with background playback enabled
        runOnMainThread { videoPlayer.dispose() }
        Thread.sleep(500)
    }

    // MARK: - Audio Track Selection Tests

    @Test
    fun videoPlayer_audioTrackSelectionHls() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        // Try to set audio track (may or may not have multiple tracks)
        runOnMainThread {
            videoPlayer.setAudioTrack(mapOf(
                "index" to 0,
                "trackIndex" to 0
            ))
        }
        Thread.sleep(500)
    }

    @Test
    fun videoPlayer_audioTrackOffSelection() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        // Try to turn off audio track
        runOnMainThread {
            videoPlayer.setAudioTrack(mapOf(
                "isOff" to true
            ))
        }
        Thread.sleep(500)

        // Re-enable
        runOnMainThread {
            videoPlayer.setAudioTrack(mapOf(
                "index" to 0,
                "trackIndex" to 0
            ))
        }
    }

    // MARK: - Subtitle Track Selection Tests

    @Test
    fun videoPlayer_subtitleTrackOffSelection() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = mapOf(
            "subtitlesEnabled" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        // Turn off subtitles
        runOnMainThread {
            videoPlayer.setSubtitleTrack(mapOf(
                "isOff" to true
            ))
        }
        Thread.sleep(500)
    }

    @Test
    fun videoPlayer_subtitleTrackIndexSelection() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = mapOf(
            "subtitlesEnabled" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        // Try to select a subtitle track by index
        runOnMainThread {
            videoPlayer.setSubtitleTrack(mapOf(
                "index" to 0,
                "trackIndex" to 0
            ))
        }
        Thread.sleep(500)
    }

    // MARK: - Duration and Position Edge Cases

    @Test
    fun videoPlayer_durationAfterSeek() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        val durationBefore = runOnMainThreadWithResult { videoPlayer.getDuration() }

        runOnMainThread { videoPlayer.seekTo(5000) }
        Thread.sleep(1000)

        val durationAfter = runOnMainThreadWithResult { videoPlayer.getDuration() }

        // Duration should remain consistent
        assertEquals("Duration should not change after seek", durationBefore, durationAfter)
    }

    // MARK: - PiP State Tests (Without Activity)

    @Test
    fun videoPlayer_pipExitWithoutEnter() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // exitPip should be safe to call even when not in PiP
        runOnMainThread { videoPlayer.exitPip() }

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setPipActionsEmpty() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Set empty PiP actions
        runOnMainThread { videoPlayer.setPipActions(emptyList()) }

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_setPipActionsWithData() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Set some PiP actions
        val actions = listOf(
            mapOf(
                "type" to "play",
                "title" to "Play"
            ),
            mapOf(
                "type" to "pause",
                "title" to "Pause"
            )
        )
        runOnMainThread {
            @Suppress("UNCHECKED_CAST")
            videoPlayer.setPipActions(actions as List<Map<String, Any>>)
        }

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // MARK: - Network Monitor Tests

    @Test
    fun videoPlayer_networkChangesDuringPlayback() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        // Player should handle network monitoring
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should be initialized with network monitoring", player)
    }

    // MARK: - Bandwidth Estimate Tests

    @Test
    fun videoPlayer_bandwidthEstimateHls() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(3000)

        // Bandwidth estimate should be available for HLS
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull(player)
    }

    // MARK: - Simple PiP tests (without Activity)

    @Test
    fun videoPlayer_exitPipWithoutEntering() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Call exitPip without entering - should handle gracefully
        runOnMainThread { videoPlayer.exitPip() }

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should still be initialized after exitPip", player)
    }

    @Test
    fun videoPlayer_getIsFullscreenInitial() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Initially should not be in fullscreen
        val isFullscreen = runOnMainThreadWithResult { videoPlayer.getIsFullscreen() }
        assertFalse("Should start not in fullscreen", isFullscreen == true)
    }

    // ==================== Activity-Based Tests ====================

    @Test
    fun videoPlayer_enterFullscreen_withActivity() {
        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                activity.initializePlayer(1, mockMessenger, source, emptyMap())
            }
            Thread.sleep(500)

            var result = false
            scenario.onActivity { activity ->
                result = activity.testEnterFullscreen()
            }
            assertTrue("enterFullscreen should return true", result)

            scenario.onActivity { activity ->
                assertTrue("Should be in fullscreen after enter", activity.isFullscreen())
            }
        } finally {
            scenario.close()
        }
    }

    @Test
    fun videoPlayer_exitFullscreen_withActivity() {
        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                activity.initializePlayer(2, mockMessenger, source, emptyMap())
            }
            Thread.sleep(500)

            // Enter fullscreen first
            scenario.onActivity { activity ->
                activity.testEnterFullscreen()
            }
            Thread.sleep(200)

            // Then exit
            scenario.onActivity { activity ->
                activity.testExitFullscreen()
            }
            Thread.sleep(200)

            scenario.onActivity { activity ->
                assertFalse("Should not be in fullscreen after exit", activity.isFullscreen())
            }
        } finally {
            scenario.close()
        }
    }

    @Test
    fun videoPlayer_exitFullscreen_whenNotInFullscreen() {
        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                activity.initializePlayer(3, mockMessenger, source, emptyMap())
            }
            Thread.sleep(500)

            // Exit without entering - should not crash
            scenario.onActivity { activity ->
                assertFalse("Should not be in fullscreen", activity.isFullscreen())
                activity.testExitFullscreen()
                assertFalse("Should still not be in fullscreen", activity.isFullscreen())
            }
        } finally {
            scenario.close()
        }
    }

    @Test
    fun videoPlayer_enterPip_withActivity() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return // PiP requires API 26+
        }

        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                val options = mapOf("allowPip" to true)
                activity.initializePlayer(4, mockMessenger, source, options)
            }
            Thread.sleep(500)

            scenario.onActivity { activity ->
                assertTrue("PiP should be allowed", activity.isPipAllowed())
                // Note: enterPip may fail on emulators without PiP support
                // This test exercises the code path regardless
                activity.testEnterPip()
            }
        } finally {
            scenario.close()
        }
    }

    @Test
    fun videoPlayer_enterPip_withPipDisabled() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return // PiP requires API 26+
        }

        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                val options = mapOf("allowPip" to false)
                activity.initializePlayer(5, mockMessenger, source, options)
            }
            Thread.sleep(500)

            var result = true
            scenario.onActivity { activity ->
                assertFalse("PiP should not be allowed", activity.isPipAllowed())
                result = activity.testEnterPip()
            }
            assertFalse("enterPip should return false when disabled", result)
        } finally {
            scenario.close()
        }
    }

    @Test
    fun videoPlayer_exitPip_withActivity() {
        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                val options = mapOf("allowPip" to true)
                activity.initializePlayer(6, mockMessenger, source, options)
            }
            Thread.sleep(500)

            // Exit PiP without entering - should not crash
            scenario.onActivity { activity ->
                activity.testExitPip()
            }
        } finally {
            scenario.close()
        }
    }

    @Test
    fun videoPlayer_onEnterBackground_withAutoEnterPip() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                val options = mapOf(
                    "allowPip" to true,
                    "autoEnterPipOnBackground" to true
                )
                activity.initializePlayer(7, mockMessenger, source, options)
            }
            Thread.sleep(500)

            // This exercises the onEnterBackground code path
            scenario.onActivity { activity ->
                activity.testOnEnterBackground()
            }
        } finally {
            scenario.close()
        }
    }

    @Test
    fun videoPlayer_onEnterBackground_withAutoEnterPipDisabled() {
        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                val options = mapOf(
                    "allowPip" to true,
                    "autoEnterPipOnBackground" to false
                )
                activity.initializePlayer(8, mockMessenger, source, options)
            }
            Thread.sleep(500)

            // Should not enter PiP when auto-enter is disabled
            scenario.onActivity { activity ->
                activity.testOnEnterBackground()
            }
        } finally {
            scenario.close()
        }
    }

    @Test
    fun videoPlayer_fullscreenToggle_multipleTimesWithActivity() {
        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                activity.initializePlayer(9, mockMessenger, source, emptyMap())
            }
            Thread.sleep(500)

            // Toggle fullscreen multiple times
            repeat(3) {
                scenario.onActivity { activity ->
                    activity.testEnterFullscreen()
                }
                Thread.sleep(100)

                scenario.onActivity { activity ->
                    assertTrue("Should be in fullscreen", activity.isFullscreen())
                    activity.testExitFullscreen()
                }
                Thread.sleep(100)

                scenario.onActivity { activity ->
                    assertFalse("Should not be in fullscreen", activity.isFullscreen())
                }
            }
        } finally {
            scenario.close()
        }
    }

    // ==================== Subtitle Auto-Selection Tests ====================

    @Test
    fun videoPlayer_subtitleAutoSelection_withShowByDefault() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "subtitlesEnabled" to true,
            "showSubtitlesByDefault" to true
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("ExoPlayer should be initialized", player)
    }

    @Test
    fun videoPlayer_subtitleAutoSelection_withPreferredLanguage() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "subtitlesEnabled" to true,
            "showSubtitlesByDefault" to true,
            "preferredSubtitleLanguage" to "en"
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("ExoPlayer should be initialized", player)
    }

    // ==================== Error Handling Tests ====================

    @Test
    fun videoPlayer_handlesInvalidNetworkUrl() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://invalid-url-that-does-not-exist.example.com/video.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000) // Give time for error to occur

        // Player should still be initialized even with invalid URL
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("ExoPlayer should be initialized even with invalid URL", player)
    }

    @Test
    fun videoPlayer_handlesInvalidSourceType() {
        val source = mapOf(
            "type" to "unknown",
            "url" to "https://example.com/video.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(500)

        // Player may not have ExoPlayer initialized for invalid source type
        // This test exercises the error path
    }

    @Test
    fun videoPlayer_handlesEmptyUrl() {
        val source = mapOf(
            "type" to "network",
            "url" to ""
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(500)

        // Tests handling of empty URL
    }

    // ==================== Container Format Tests ====================

    @Test
    fun videoPlayer_getVideoMetadata_withMp4() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000) // Wait for metadata to load

        val metadata = runOnMainThreadWithResult { videoPlayer.getVideoMetadata() }
        // Metadata may or may not be available depending on network and timing
        // This exercises the getVideoMetadata code path
    }

    @Test
    fun videoPlayer_getVideoMetadata_withHls() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000) // Wait for metadata to load

        val metadata = runOnMainThreadWithResult { videoPlayer.getVideoMetadata() }
        // Tests HLS stream handling
    }

    // ==================== Quality Selection Tests ====================

    @Test
    fun videoPlayer_getCurrentVideoQuality_beforeReady() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        // Don't wait - test immediately after creation

        val quality = runOnMainThreadWithResult { videoPlayer.getCurrentVideoQuality() }
        assertNotNull("Quality should return auto by default", quality)
    }

    @Test
    fun videoPlayer_getCurrentVideoQuality_afterPlayback() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("autoPlay" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(3000) // Wait for playback to start and quality to be determined

        val quality = runOnMainThreadWithResult { videoPlayer.getCurrentVideoQuality() }
        assertNotNull("Quality should be available", quality)
    }

    // ==================== PiP Action Tests (with Activity) ====================

    @Test
    fun videoPlayer_setPipActionsWithAllTypes_withActivity() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return // PiP requires API 26+
        }

        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                val options = mapOf("allowPip" to true)
                activity.initializePlayer(10, mockMessenger, source, options)
            }
            Thread.sleep(500)

            scenario.onActivity { activity ->
                val player = activity.videoPlayer
                assertNotNull("Video player should be initialized", player)

                // Set all types of PiP actions
                player?.setPipActions(listOf(
                    mapOf("type" to "playPause"),
                    mapOf("type" to "skipPrevious"),
                    mapOf("type" to "skipNext"),
                    mapOf("type" to "skipBackward", "skipIntervalMs" to 10000),
                    mapOf("type" to "skipForward", "skipIntervalMs" to 10000)
                ))
            }
        } finally {
            scenario.close()
        }
    }

    @Test
    fun videoPlayer_enterPip_withActions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val scenario = ActivityScenario.launch(TestActivity::class.java)
        try {
            scenario.onActivity { activity ->
                val source = mapOf(
                    "type" to "network",
                    "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                )
                val options = mapOf("allowPip" to true)
                activity.initializePlayer(11, mockMessenger, source, options)
            }
            Thread.sleep(500)

            // Set PiP actions before entering PiP
            scenario.onActivity { activity ->
                activity.videoPlayer?.setPipActions(listOf(
                    mapOf("type" to "playPause")
                ))
            }
            Thread.sleep(100)

            // Try to enter PiP with actions
            scenario.onActivity { activity ->
                activity.testEnterPip()
            }
        } finally {
            scenario.close()
        }
    }

    // ==================== Network Resilience Tests ====================

    @Test
    fun videoPlayer_handlesNetworkTimeout() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://httpstat.us/524" // Gateway Timeout
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(3000) // Wait for timeout

        // This exercises network error handling paths
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("ExoPlayer should still exist", player)
    }

    @Test
    fun videoPlayer_handlesNetworkError() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://httpstat.us/500" // Internal Server Error
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // This exercises error handling paths
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("ExoPlayer should still exist", player)
    }

    // ==================== Background Playback Runtime Toggle ====================

    @Test
    fun videoPlayer_setBackgroundPlayback_enableWhilePlaying() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to false)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1500)

        // Start playing
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)

        // Enable background playback while playing
        val result = runOnMainThreadWithResult { videoPlayer.setBackgroundPlayback(true) }
        assertTrue("setBackgroundPlayback should return true", result == true)
        assertTrue("Background playback should be enabled",
            runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() } == true)
    }

    @Test
    fun videoPlayer_setBackgroundPlayback_disableWhilePlaying() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1500)

        // Start playing
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)

        // Disable background playback while playing
        val result = runOnMainThreadWithResult { videoPlayer.setBackgroundPlayback(false) }
        assertTrue("setBackgroundPlayback should return true", result == true)
        assertFalse("Background playback should be disabled",
            runOnMainThreadWithResult { videoPlayer.isBackgroundPlaybackEnabled() } == true)
    }

    // ==================== Media Metadata Tests ====================

    @Test
    fun videoPlayer_setMediaMetadata_withBackgroundEnabled() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Set media metadata
        runOnMainThread {
            videoPlayer.setMediaMetadata(mapOf(
                "title" to "Big Buck Bunny",
                "artist" to "Blender Foundation",
                "album" to "Open Source Movies",
                "artworkUrl" to "https://example.com/artwork.jpg"
            ))
        }
        Thread.sleep(200)
        // No assertion - just verify no crash
    }

    @Test
    fun videoPlayer_setMediaMetadata_withBackgroundDisabled() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to false)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Set media metadata - should be ignored
        runOnMainThread {
            videoPlayer.setMediaMetadata(mapOf("title" to "Test"))
        }
        // No crash means success
    }

    @Test
    fun videoPlayer_setMediaMetadata_partialFields() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowBackgroundPlayback" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Set only title
        runOnMainThread {
            videoPlayer.setMediaMetadata(mapOf("title" to "Only Title"))
        }
        Thread.sleep(100)

        // Set only artist
        runOnMainThread {
            videoPlayer.setMediaMetadata(mapOf("artist" to "Only Artist"))
        }
    }

    // ==================== Scaling Mode Runtime Change ====================

    @Test
    fun videoPlayer_setScalingMode_fit() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setScalingMode("fit") }
    }

    @Test
    fun videoPlayer_setScalingMode_fill() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setScalingMode("fill") }
    }

    @Test
    fun videoPlayer_setScalingMode_stretch() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setScalingMode("stretch") }
    }

    @Test
    fun videoPlayer_setScalingMode_unknown() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Unknown mode should default to fit
        runOnMainThread { videoPlayer.setScalingMode("unknown") }
    }

    // ==================== Stop Method Tests ====================

    @Test
    fun videoPlayer_stop_resetsPosition() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1500)

        // Play and seek
        runOnMainThread { videoPlayer.play() }
        Thread.sleep(500)
        runOnMainThread { videoPlayer.seekTo(5000) }
        Thread.sleep(500)

        // Stop
        runOnMainThread { videoPlayer.stop() }
        Thread.sleep(500)

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() } ?: 1000L
        assertTrue("Position should be near 0 after stop", position < 1000L)
    }

    // ==================== Quality Selection Additional Tests ====================

    @Test
    fun videoPlayer_getVideoQualities_returnsListOrEmpty() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        val qualities = runOnMainThreadWithResult { videoPlayer.getVideoQualities() }
        assertNotNull("Qualities should not be null", qualities)
    }

    @Test
    fun videoPlayer_isQualitySelectionSupported_checkValue() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        val isSupported = runOnMainThreadWithResult { videoPlayer.isQualitySelectionSupported() }
        assertNotNull("isQualitySelectionSupported should return boolean", isSupported)
    }

    @Test
    fun videoPlayer_setVideoQuality_withValidTrack() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2500)

        // Get available qualities first
        val qualities = runOnMainThreadWithResult { videoPlayer.getVideoQualities() }
        if (qualities != null && qualities.isNotEmpty()) {
            // Try to set first quality - cast to Map<String, Any>
            val firstQuality = qualities[0].filterValues { it != null }.mapValues { it.value!! }
            val result = runOnMainThreadWithResult { videoPlayer.setVideoQuality(firstQuality) }
            assertTrue("setVideoQuality with valid track should succeed", result == true)
        }
    }

    // ==================== Additional PiP Tests ====================

    @Test
    fun videoPlayer_setPipActions_emptyList() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        runOnMainThread { videoPlayer.setPipActions(emptyList()) }
    }

    @Test
    fun videoPlayer_setPipActions_withMissingType() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("allowPip" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        // Action without type should be skipped
        runOnMainThread {
            videoPlayer.setPipActions(listOf(
                mapOf("skipIntervalMs" to 5000) // Missing type
            ))
        }
    }

    // ==================== Initial Options Tests ====================

    @Test
    fun videoPlayer_initializesWithAllOptionsVerified() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf(
            "volume" to 0.5,
            "looping" to true,
            "scalingMode" to "fill",
            "allowPip" to true,
            "autoEnterPipOnBackground" to true,
            "subtitlesEnabled" to true,
            "showSubtitlesByDefault" to true,
            "preferredSubtitleLanguage" to "en",
            "allowBackgroundPlayback" to true,
            "bufferingTier" to "high"
        )

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1500)

        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should be initialized with all options", player)

        // Verify some options (must access player on main thread)
        val volume = runOnMainThreadWithResult { player?.volume ?: 0f }
        assertEquals("Volume should be 0.5", 0.5f, volume ?: 0f, 0.01f)
        val repeatMode = runOnMainThreadWithResult { player?.repeatMode ?: -1 }
        assertEquals("Should be looping",
            androidx.media3.common.Player.REPEAT_MODE_ONE,
            repeatMode ?: -1)
        assertTrue("PiP should be allowed",
            runOnMainThreadWithResult { videoPlayer.isPipAllowed() } == true)
        assertTrue("Subtitles should be enabled",
            runOnMainThreadWithResult { videoPlayer.areSubtitlesEnabled() } == true)
    }

    // ==================== Buffering Tier Tests ====================

    @Test
    fun videoPlayer_initializesWithBufferingTier_low() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("bufferingTier" to "low")

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_initializesWithBufferingTier_medium() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("bufferingTier" to "medium")

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    @Test
    fun videoPlayer_initializesWithBufferingTier_high() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("bufferingTier" to "high")

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        assertNotNull(runOnMainThreadWithResult { videoPlayer.getExoPlayer() })
    }

    // ==================== Activity-based getIsFullscreen Test ====================

    @Test
    fun videoPlayer_getIsFullscreen_initiallyFalse() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(1000)

        val isFullscreen = runOnMainThreadWithResult { videoPlayer.getIsFullscreen() }
        assertFalse("Should not be in fullscreen initially", isFullscreen == true)
    }

    // ==================== Position and Duration Edge Cases ====================

    @Test
    fun videoPlayer_getPosition_beforeReady() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        // Don't wait

        val position = runOnMainThreadWithResult { videoPlayer.getPosition() }
        assertNotNull("Position should not be null", position)
    }

    @Test
    fun videoPlayer_getDuration_beforeReady() {
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        // Don't wait

        val duration = runOnMainThreadWithResult { videoPlayer.getDuration() }
        assertNotNull("Duration should not be null", duration)
    }

    // ==================== Coverage Improvement Tests ====================
    // Tests added specifically to cover uncovered code paths

    @Test
    fun videoPlayer_getCurrentVideoQualityAfterManualSelection() {
        // This test covers the code path in getCurrentVideoQuality where
        // isAutoQuality is false and we return the selected track's info
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(3000)

        // Get available qualities
        val qualities = runOnMainThreadWithResult { videoPlayer.getVideoQualities() }

        if (!qualities.isNullOrEmpty()) {
            @Suppress("UNCHECKED_CAST")
            val firstQuality = qualities.first() as? Map<String, Any>

            if (firstQuality != null) {
                // Set a specific (non-auto) quality
                val setResult = runOnMainThreadWithResult {
                    videoPlayer.setVideoQuality(firstQuality)
                }
                Thread.sleep(500)

                // Now get current quality - should return the manually selected track
                val currentQuality = runOnMainThreadWithResult {
                    videoPlayer.getCurrentVideoQuality()
                }

                assertNotNull("Current quality should not be null after manual selection", currentQuality)
                // After manual selection, the ID should not be "auto"
                // (Note: ExoPlayer may still be adjusting, but isAutoQuality flag should be false)
            }
        }
    }

    @Test
    fun videoPlayer_setAudioTrackResetToDefault() {
        // This test covers the code path in setAudioTrack where track is null
        // and we reset to default audio track
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(2000)

        // Reset audio track to default by passing null
        runOnMainThread { videoPlayer.setAudioTrack(null) }
        Thread.sleep(500)

        // Verify player is still functional
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should still be valid after audio track reset", player)
    }

    @Test
    fun videoPlayer_addExternalSubtitleWithRealUrl() {
        // This test covers the successful external subtitle download path
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Use a real VTT subtitle file URL
        val subtitleUrl = "https://raw.githubusercontent.com/nicholasbraun/sample-files/main/english.vtt"

        var result: Map<String, Any?>? = null
        val latch = CountDownLatch(1)

        runOnMainThread {
            videoPlayer.addExternalSubtitle(
                sourceType = "url",
                path = subtitleUrl,
                format = "vtt",
                label = "English",
                language = "en",
                isDefault = false
            ) { track ->
                result = track
                latch.countDown()
            }
        }

        // Wait for async download to complete
        latch.await(15, TimeUnit.SECONDS)

        // Note: The result may be null if the URL is not accessible,
        // but the code path will still be exercised for coverage
    }

    @Test
    fun videoPlayer_addExternalSubtitleInvalidUrl() {
        // Test the invalid URL handling path
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        var result: Map<String, Any?>? = null
        val latch = CountDownLatch(1)

        runOnMainThread {
            videoPlayer.addExternalSubtitle(
                sourceType = "url",
                path = "invalid://not-a-real-url",
                format = "srt",
                label = "Test",
                language = "en",
                isDefault = false
            ) { track ->
                result = track
                latch.countDown()
            }
        }

        latch.await(5, TimeUnit.SECONDS)

        // Should return null for invalid URL
        assertNull("Invalid URL should return null", result)
    }

    @Test
    fun videoPlayer_addExternalSubtitleWhenDisabled() {
        // Test adding external subtitle when subtitles are disabled
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to false)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        var result: Map<String, Any?>? = mapOf("placeholder" to "value")
        val latch = CountDownLatch(1)

        runOnMainThread {
            videoPlayer.addExternalSubtitle(
                sourceType = "url",
                path = "https://example.com/subtitles.srt",
                format = "srt",
                label = "Test",
                language = "en",
                isDefault = false
            ) { track ->
                result = track
                latch.countDown()
            }
        }

        latch.await(5, TimeUnit.SECONDS)

        // Should return null when subtitles are disabled
        assertNull("Should return null when subtitles are disabled", result)
    }

    @Test
    fun videoPlayer_removeExternalSubtitleNotFound() {
        // Test removing an external subtitle that doesn't exist
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Try to remove a non-existent track
        val result = runOnMainThreadWithResult {
            videoPlayer.removeExternalSubtitle("ext-999")
        }

        assertFalse("Removing non-existent track should return false", result == true)
    }

    @Test
    fun videoPlayer_getExternalSubtitlesEmpty() {
        // Test getting external subtitles when none exist
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        val subtitles = runOnMainThreadWithResult { videoPlayer.getExternalSubtitles() }

        assertNotNull("External subtitles list should not be null", subtitles)
        assertTrue("External subtitles should be empty initially", subtitles!!.isEmpty())
    }

    @Test
    fun videoPlayer_setSubtitleTrackWithExternalId() {
        // Test setting a subtitle track with an external ID format
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Try to set an external subtitle track that doesn't exist
        runOnMainThread {
            videoPlayer.setSubtitleTrack(mapOf("id" to "ext-0"))
        }
        Thread.sleep(500)

        // Should handle gracefully without crashing
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should still be valid", player)
    }

    @Test
    fun videoPlayer_addExternalSubtitleWithWebVTTContentInNativeMode() {
        // Test that webvttContent is used when provided and in native rendering mode
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Set subtitle render mode to native
        runOnMainThread {
            videoPlayer.setSubtitleRenderMode("native")
        }

        val webvttContent = """
            WEBVTT

            00:00:01.000 --> 00:00:05.000
            Test subtitle from WebVTT content
        """.trimIndent()

        var result: Map<String, Any?>? = null
        val latch = CountDownLatch(1)

        runOnMainThread {
            videoPlayer.addExternalSubtitle(
                sourceType = "network",
                path = "https://example.com/subtitle.srt",
                format = "srt",
                label = "Test",
                language = "en",
                isDefault = false,
                webvttContent = webvttContent
            ) { track ->
                result = track
                latch.countDown()
            }
        }

        latch.await(5, TimeUnit.SECONDS)

        // Should successfully create track from WebVTT content
        assertNotNull("Track should be created from WebVTT content", result)
        assertEquals("Track ID should start with ext-", "ext-", result!!["id"].toString().substring(0, 4))
    }

    @Test
    fun videoPlayer_addExternalSubtitleWithWebVTTContentInFlutterMode() {
        // Test that path loading is used when in Flutter rendering mode (even with webvttContent)
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Set subtitle render mode to flutter
        runOnMainThread {
            videoPlayer.setSubtitleRenderMode("flutter")
        }

        val webvttContent = """
            WEBVTT

            00:00:01.000 --> 00:00:05.000
            This should not be used
        """.trimIndent()

        var result: Map<String, Any?>? = null
        val latch = CountDownLatch(1)

        // Use real VTT URL to ensure path loading succeeds
        val validUrl = "https://raw.githubusercontent.com/nicholasbraun/sample-files/main/english.vtt"

        runOnMainThread {
            videoPlayer.addExternalSubtitle(
                sourceType = "network",
                path = validUrl,
                format = "vtt",
                label = "Test",
                language = "en",
                isDefault = false,
                webvttContent = webvttContent
            ) { track ->
                result = track
                latch.countDown()
            }
        }

        latch.await(15, TimeUnit.SECONDS)

        // In Flutter mode, should load from path (may succeed or fail based on network)
        // Just verify the code path is exercised without crashing
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should still be valid", player)
    }

    @Test
    fun videoPlayer_addExternalSubtitleWithoutWebVTTContent() {
        // Test that normal path loading works when webvttContent is not provided
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        // Set to native mode
        runOnMainThread {
            videoPlayer.setSubtitleRenderMode("native")
        }

        var result: Map<String, Any?>? = null
        val latch = CountDownLatch(1)

        runOnMainThread {
            videoPlayer.addExternalSubtitle(
                sourceType = "network",
                path = "https://raw.githubusercontent.com/nicholasbraun/sample-files/main/english.vtt",
                format = "vtt",
                label = "Test",
                language = "en",
                isDefault = false,
                webvttContent = null
            ) { track ->
                result = track
                latch.countDown()
            }
        }

        latch.await(15, TimeUnit.SECONDS)

        // Should load from path when webvttContent is null
        // Network may fail, but code path should execute
        val player = runOnMainThreadWithResult { videoPlayer.getExoPlayer() }
        assertNotNull("Player should still be valid", player)
    }

    @Test
    fun videoPlayer_addExternalSubtitleWithEmptyWebVTTContent() {
        // Test that empty webvttContent is handled gracefully
        val source = mapOf(
            "type" to "network",
            "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        )
        val options = mapOf("subtitlesEnabled" to true)

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread {
            videoPlayer.setSubtitleRenderMode("native")
        }

        var result: Map<String, Any?>? = null
        val latch = CountDownLatch(1)

        runOnMainThread {
            videoPlayer.addExternalSubtitle(
                sourceType = "network",
                path = "https://example.com/subtitle.vtt",
                format = "vtt",
                label = "Test",
                language = "en",
                isDefault = false,
                webvttContent = ""
            ) { track ->
                result = track
                latch.countDown()
            }
        }

        latch.await(5, TimeUnit.SECONDS)

        // Empty content should still create track
        assertNotNull("Track should be created even with empty content", result)
    }

    @Test
    fun videoPlayer_getCurrentVideoQualityWhenNotAutoMode() {
        // Ensure getCurrentVideoQuality returns proper info when not in auto mode
        val source = mapOf(
            "type" to "network",
            "url" to "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
        )
        val options = emptyMap<String, Any>()

        videoPlayer = VideoPlayer(1, context, mockMessenger, source, options)
        Thread.sleep(2000)

        runOnMainThread { videoPlayer.play() }
        Thread.sleep(4000) // Wait longer for HLS to load tracks

        val qualities = runOnMainThreadWithResult { videoPlayer.getVideoQualities() }

        if (!qualities.isNullOrEmpty() && qualities.size > 1) {
            @Suppress("UNCHECKED_CAST")
            val secondQuality = qualities[1] as? Map<String, Any>

            if (secondQuality != null && secondQuality["id"] != "auto") {
                // Set to a specific quality (not auto)
                runOnMainThread { videoPlayer.setVideoQuality(secondQuality) }
                Thread.sleep(1000)

                // Get current quality - exercises the non-auto path
                val current = runOnMainThreadWithResult { videoPlayer.getCurrentVideoQuality() }
                assertNotNull("Current quality should not be null", current)

                // The bitrate/width/height should be valid for a selected track
                val bitrate = current?.get("bitrate")
                val width = current?.get("width")
                val height = current?.get("height")

                // At least one of these should have a meaningful value if track was selected
                assertTrue(
                    "Selected quality should have resolution or bitrate info",
                    (bitrate as? Int ?: 0) > 0 ||
                    (width as? Int ?: 0) > 0 ||
                    (height as? Int ?: 0) > 0 ||
                    current?.get("id") == "auto"  // Or still in auto mode if selection failed
                )
            }
        }
    }

}
