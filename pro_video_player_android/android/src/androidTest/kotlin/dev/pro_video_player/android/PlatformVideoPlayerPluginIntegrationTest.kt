package dev.pro_video_player.android

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformViewRegistry
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.*
import org.mockito.kotlin.any
import org.mockito.kotlin.anyOrNull
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.eq
import org.mockito.kotlin.whenever
import android.os.Handler
import android.os.Looper
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Instrumentation tests for ProVideoPlayerPlugin.
 * These tests run on the actual device/emulator and exercise the plugin
 * through method channel calls to achieve proper code coverage.
 */
@RunWith(AndroidJUnit4::class)
class ProVideoPlayerPluginIntegrationTest {

    private lateinit var context: Context
    private lateinit var plugin: ProVideoPlayerPlugin
    private lateinit var mockBinding: FlutterPlugin.FlutterPluginBinding
    private lateinit var mockMessenger: BinaryMessenger
    private lateinit var mockPlatformViewRegistry: PlatformViewRegistry
    private val mainHandler = Handler(Looper.getMainLooper())

    @Before
    fun setUp() {
        context = InstrumentationRegistry.getInstrumentation().targetContext
        mockMessenger = mock(BinaryMessenger::class.java)
        mockPlatformViewRegistry = mock(PlatformViewRegistry::class.java)
        mockBinding = mock(FlutterPlugin.FlutterPluginBinding::class.java)

        whenever(mockBinding.applicationContext).thenReturn(context)
        whenever(mockBinding.binaryMessenger).thenReturn(mockMessenger)
        whenever(mockBinding.platformViewRegistry).thenReturn(mockPlatformViewRegistry)

        plugin = ProVideoPlayerPlugin()

        // Attach on main thread
        val latch = CountDownLatch(1)
        mainHandler.post {
            plugin.onAttachedToEngine(mockBinding)
            latch.countDown()
        }
        latch.await(5, TimeUnit.SECONDS)
    }

    @After
    fun tearDown() {
        val latch = CountDownLatch(1)
        mainHandler.post {
            plugin.onDetachedFromEngine(mockBinding)
            latch.countDown()
        }
        latch.await(5, TimeUnit.SECONDS)
    }

    // Helper to run on main thread and wait
    private fun runOnMainThread(action: () -> Unit) {
        val latch = CountDownLatch(1)
        mainHandler.post {
            action()
            latch.countDown()
        }
        latch.await(10, TimeUnit.SECONDS)
    }

    // Helper to capture result
    private fun createMockResult(): Pair<MethodChannel.Result, ResultCapture> {
        val capture = ResultCapture()
        val result = mock(MethodChannel.Result::class.java)
        doAnswer { invocation ->
            capture.successValue = invocation.arguments[0]
            capture.successCalled = true
            null
        }.whenever(result).success(anyOrNull())
        doAnswer { invocation ->
            capture.errorCode = invocation.arguments[0] as String
            capture.errorMessage = invocation.arguments[1] as? String
            capture.errorCalled = true
            null
        }.whenever(result).error(any(), anyOrNull(), anyOrNull())
        doAnswer {
            capture.notImplementedCalled = true
            null
        }.whenever(result).notImplemented()
        return Pair(result, capture)
    }

    data class ResultCapture(
        var successCalled: Boolean = false,
        var successValue: Any? = null,
        var errorCalled: Boolean = false,
        var errorCode: String? = null,
        var errorMessage: String? = null,
        var notImplementedCalled: Boolean = false
    )

    // MARK: - Unknown Method Tests

    @Test
    fun onMethodCall_unknownMethod_returnsNotImplemented() {
        val (result, capture) = createMockResult()
        val call = MethodCall("unknownMethod", null)

        runOnMainThread {
            plugin.onMethodCall(call, result)
        }

        assertTrue("notImplemented should be called", capture.notImplementedCalled)
    }

    // MARK: - Create Tests

    @Test
    fun create_withValidArgs_returnsPlayerId() {
        val (result, capture) = createMockResult()
        val call = MethodCall("create", mapOf(
            "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
            "options" to mapOf<String, Any>()
        ))

        runOnMainThread {
            plugin.onMethodCall(call, result)
        }
        Thread.sleep(500)

        assertTrue("success should be called", capture.successCalled)
        assertEquals("First player ID should be 0", 0, capture.successValue)
    }

    @Test
    fun create_withNullSource_returnsError() {
        val (result, capture) = createMockResult()
        val call = MethodCall("create", mapOf("options" to mapOf<String, Any>()))

        runOnMainThread {
            plugin.onMethodCall(call, result)
        }

        assertTrue("error should be called", capture.errorCalled)
        assertEquals("INVALID_ARGS", capture.errorCode)
    }

    @Test
    fun create_withNullOptions_returnsError() {
        val (result, capture) = createMockResult()
        val call = MethodCall("create", mapOf(
            "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4")
        ))

        runOnMainThread {
            plugin.onMethodCall(call, result)
        }

        assertTrue("error should be called", capture.errorCalled)
        assertEquals("INVALID_ARGS", capture.errorCode)
    }

    @Test
    fun create_multiplePlayersGetIncrementalIds() {
        val (result1, capture1) = createMockResult()
        val (result2, capture2) = createMockResult()

        val call1 = MethodCall("create", mapOf(
            "source" to mapOf("type" to "network", "url" to "https://example.com/video1.mp4"),
            "options" to mapOf<String, Any>()
        ))
        val call2 = MethodCall("create", mapOf(
            "source" to mapOf("type" to "network", "url" to "https://example.com/video2.mp4"),
            "options" to mapOf<String, Any>()
        ))

        runOnMainThread {
            plugin.onMethodCall(call1, result1)
        }
        Thread.sleep(200)
        runOnMainThread {
            plugin.onMethodCall(call2, result2)
        }
        Thread.sleep(200)

        assertEquals(0, capture1.successValue)
        assertEquals(1, capture2.successValue)
    }

    // Note: Asset source test removed because FlutterLoader isn't available in instrumentation tests
    // Asset path resolution is tested through Flutter integration tests instead

    // MARK: - Dispose Tests

    @Test
    fun dispose_withValidPlayerId_succeeds() {
        // First create a player
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        // Dispose it
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("dispose", mapOf("playerId" to playerId)), result)
        }
        Thread.sleep(200)

        assertTrue("success should be called", capture.successCalled)
        assertNull("getPlayer should return null after dispose", plugin.getPlayer(playerId))
    }

    @Test
    fun dispose_withNullPlayerId_returnsError() {
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("dispose", mapOf<String, Any>()), result)
        }

        assertTrue("error should be called", capture.errorCalled)
        assertEquals("INVALID_ARGS", capture.errorCode)
    }

    // MARK: - Play/Pause/Stop Tests

    @Test
    fun play_withValidPlayerId_succeeds() {
        // Create a player
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(1000)

        val playerId = createCapture.successValue as Int

        // Play
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("play", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun play_withInvalidPlayerId_returnsError() {
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("play", mapOf("playerId" to 999)), result)
        }

        assertTrue("error should be called", capture.errorCalled)
        assertEquals("INVALID_ARGS", capture.errorCode)
    }

    @Test
    fun pause_withValidPlayerId_succeeds() {
        // Create and play
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        // Pause
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("pause", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun stop_withValidPlayerId_succeeds() {
        // Create
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        // Stop
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("stop", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    // MARK: - SeekTo Tests

    @Test
    fun seekTo_withValidArgs_succeeds() {
        // Create
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        // Seek
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("seekTo", mapOf("playerId" to playerId, "position" to 5000)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun seekTo_withNegativePosition_returnsError() {
        // Create
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        // Seek with negative position
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("seekTo", mapOf("playerId" to playerId, "position" to -100)), result)
        }

        assertTrue("error should be called", capture.errorCalled)
        assertEquals("INVALID_ARGS", capture.errorCode)
    }

    @Test
    fun seekTo_withNullPosition_returnsError() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("seekTo", mapOf("playerId" to playerId)), result)
        }

        assertTrue("error should be called", capture.errorCalled)
    }

    // MARK: - SetPlaybackSpeed Tests

    @Test
    fun setPlaybackSpeed_withValidSpeed_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setPlaybackSpeed", mapOf("playerId" to playerId, "speed" to 1.5)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun setPlaybackSpeed_withZeroSpeed_returnsError() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setPlaybackSpeed", mapOf("playerId" to playerId, "speed" to 0.0)), result)
        }

        assertTrue("error should be called", capture.errorCalled)
        assertEquals("INVALID_ARGS", capture.errorCode)
    }

    @Test
    fun setPlaybackSpeed_withTooHighSpeed_returnsError() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setPlaybackSpeed", mapOf("playerId" to playerId, "speed" to 15.0)), result)
        }

        assertTrue("error should be called", capture.errorCalled)
    }

    // MARK: - SetVolume Tests

    @Test
    fun setVolume_withValidVolume_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setVolume", mapOf("playerId" to playerId, "volume" to 0.5)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun setVolume_withNegativeVolume_returnsError() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setVolume", mapOf("playerId" to playerId, "volume" to -0.5)), result)
        }

        assertTrue("error should be called", capture.errorCalled)
    }

    @Test
    fun setVolume_withTooHighVolume_returnsError() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setVolume", mapOf("playerId" to playerId, "volume" to 1.5)), result)
        }

        assertTrue("error should be called", capture.errorCalled)
    }

    // MARK: - SetLooping Tests

    @Test
    fun setLooping_withValidArgs_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setLooping", mapOf("playerId" to playerId, "looping" to true)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun setLooping_withNullLooping_returnsError() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setLooping", mapOf("playerId" to playerId)), result)
        }

        assertTrue("error should be called", capture.errorCalled)
    }

    // MARK: - SetScalingMode Tests

    @Test
    fun setScalingMode_withValidMode_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        for (mode in listOf("fit", "fill", "fitWidth", "fitHeight")) {
            val (result, capture) = createMockResult()
            runOnMainThread {
                plugin.onMethodCall(MethodCall("setScalingMode", mapOf("playerId" to playerId, "scalingMode" to mode)), result)
            }
            assertTrue("success should be called for mode $mode", capture.successCalled)
        }
    }

    @Test
    fun setScalingMode_withInvalidMode_returnsError() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setScalingMode", mapOf("playerId" to playerId, "scalingMode" to "invalid")), result)
        }

        assertTrue("error should be called", capture.errorCalled)
        assertEquals("INVALID_ARGS", capture.errorCode)
    }

    // MARK: - Track Selection Tests

    @Test
    fun setSubtitleTrack_withNull_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setSubtitleTrack", mapOf("playerId" to playerId, "track" to null)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun setAudioTrack_withNull_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setAudioTrack", mapOf("playerId" to playerId, "track" to null)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    // MARK: - Position/Duration Tests

    @Test
    fun getPosition_withValidPlayerId_returnsValue() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("getPosition", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
        assertTrue("position should be Int", capture.successValue is Int)
    }

    @Test
    fun getDuration_withValidPlayerId_returnsValue() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("getDuration", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
        assertTrue("duration should be Int", capture.successValue is Int)
    }

    // MARK: - PiP Tests

    @Test
    fun isPipSupported_returnsBoolean() {
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("isPipSupported", null), result)
        }

        assertTrue("success should be called", capture.successCalled)
        assertTrue("result should be Boolean", capture.successValue is Boolean)
    }

    @Test
    fun enterPip_withValidPlayerId_returnsBoolean() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf("allowPip" to true)
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("enterPip", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
        assertTrue("result should be Boolean", capture.successValue is Boolean)
    }

    @Test
    fun exitPip_withValidPlayerId_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("exitPip", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun setPipActions_withValidActions_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf("allowPip" to true)
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val actions = listOf(
            mapOf("type" to "skipBackward", "skipIntervalMs" to 10000),
            mapOf("type" to "playPause"),
            mapOf("type" to "skipForward", "skipIntervalMs" to 10000)
        )

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setPipActions", mapOf("playerId" to playerId, "actions" to actions)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    // MARK: - Fullscreen Tests

    @Test
    fun enterFullscreen_withValidPlayerId_returnsBoolean() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("enterFullscreen", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
        assertTrue("result should be Boolean", capture.successValue is Boolean)
    }

    @Test
    fun exitFullscreen_withValidPlayerId_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("exitFullscreen", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    // MARK: - Verbose Logging Tests

    @Test
    fun setVerboseLogging_enable_succeeds() {
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setVerboseLogging", mapOf("enabled" to true)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun setVerboseLogging_disable_succeeds() {
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setVerboseLogging", mapOf("enabled" to false)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun setVerboseLogging_withNullEnabled_returnsError() {
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setVerboseLogging", mapOf<String, Any>()), result)
        }

        assertTrue("error should be called", capture.errorCalled)
        assertEquals("INVALID_ARGS", capture.errorCode)
    }

    // MARK: - Media Metadata Tests

    @Test
    fun setMediaMetadata_withValidMetadata_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf("allowBackgroundPlayback" to true)
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val metadata = mapOf(
            "title" to "Test Video",
            "artist" to "Test Artist",
            "album" to "Test Album"
        )

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setMediaMetadata", mapOf("playerId" to playerId, "metadata" to metadata)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    // MARK: - Video Quality Tests

    @Test
    fun getVideoQualities_withValidPlayerId_returnsList() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("getVideoQualities", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
        assertTrue("result should be List", capture.successValue is List<*>)
    }

    @Test
    fun setVideoQuality_withNull_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setVideoQuality", mapOf("playerId" to playerId, "track" to null)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun getCurrentVideoQuality_withValidPlayerId_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("getCurrentVideoQuality", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun isQualitySelectionSupported_withValidPlayerId_returnsBoolean() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("isQualitySelectionSupported", mapOf("playerId" to playerId)), result)
        }

        assertTrue("success should be called", capture.successCalled)
        assertTrue("result should be Boolean", capture.successValue is Boolean)
    }

    // MARK: - Background Playback Tests

    @Test
    fun setBackgroundPlayback_withValidArgs_succeeds() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf("allowBackgroundPlayback" to true)
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setBackgroundPlayback", mapOf("playerId" to playerId, "enabled" to true)), result)
        }

        assertTrue("success should be called", capture.successCalled)
    }

    @Test
    fun setBackgroundPlayback_withNullEnabled_returnsError() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int

        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("setBackgroundPlayback", mapOf("playerId" to playerId)), result)
        }

        assertTrue("error should be called", capture.errorCalled)
    }

    @Test
    fun isBackgroundPlaybackSupported_returnsBoolean() {
        val (result, capture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("isBackgroundPlaybackSupported", null), result)
        }

        assertTrue("success should be called", capture.successCalled)
        assertTrue("result should be Boolean", capture.successValue is Boolean)
    }

    // MARK: - getPlayer Tests

    @Test
    fun getPlayer_afterCreate_returnsPlayer() {
        val (createResult, createCapture) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        val playerId = createCapture.successValue as Int
        val player = plugin.getPlayer(playerId)

        assertNotNull("getPlayer should return player", player)
    }

    @Test
    fun getPlayer_withInvalidId_returnsNull() {
        val player = plugin.getPlayer(999)
        assertNull("getPlayer should return null for invalid ID", player)
    }

    // MARK: - Lifecycle Tests

    @Test
    fun onDetachedFromEngine_clearsPlayers() {
        // Create a player
        val (createResult, _) = createMockResult()
        runOnMainThread {
            plugin.onMethodCall(MethodCall("create", mapOf(
                "source" to mapOf("type" to "network", "url" to "https://example.com/video.mp4"),
                "options" to mapOf<String, Any>()
            )), createResult)
        }
        Thread.sleep(500)

        // Detach
        runOnMainThread {
            plugin.onDetachedFromEngine(mockBinding)
        }

        // Player should be null
        assertNull("Player should be null after detach", plugin.getPlayer(0))

        // Re-attach for tearDown
        runOnMainThread {
            plugin.onAttachedToEngine(mockBinding)
        }
    }
}
