package dev.pro_video_player.android

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.*
import org.mockito.kotlin.any
import org.mockito.kotlin.whenever
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Test Activity for MediaRouteButton tests.
 * Required because MediaRouteButton needs an Activity context with proper theme.
 */
class MediaRouteButtonTestActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}

/**
 * Integration tests for MediaRouteButton platform view.
 *
 * These tests verify that MediaRouteButton can be created without crashing,
 * specifically testing the fix for the "background can not be translucent: #0" error
 * that occurs when Flutter platform view contexts have transparent backgrounds.
 *
 * Issue: MediaRouterThemeHelper.createThemedButtonContext() requires a context with
 * an opaque colorBackground attribute. Flutter platform view contexts often have
 * transparent backgrounds, causing IllegalArgumentException.
 *
 * Fix: Use ContextThemeWrapper with Activity context and custom theme that
 * explicitly sets colorBackground to opaque white.
 */
@RunWith(AndroidJUnit4::class)
class MediaRouteButtonIntegrationTest {

    @get:Rule
    val activityRule = ActivityScenarioRule(MediaRouteButtonTestActivity::class.java)

    private val mainHandler = Handler(Looper.getMainLooper())

    private fun runOnMainThread(action: () -> Unit) {
        val latch = CountDownLatch(1)
        mainHandler.post {
            try {
                action()
            } finally {
                latch.countDown()
            }
        }
        assertTrue("Timeout waiting for main thread", latch.await(10, TimeUnit.SECONDS))
    }

    /**
     * Test that MediaRouteButtonPlatformView can be created without throwing
     * "background can not be translucent: #0" exception.
     *
     * This was a regression where Flutter's platform view context has a transparent
     * background, causing MediaRouterThemeHelper.createThemedButtonContext() to throw.
     */
    @Test
    fun mediaRouteButtonPlatformView_createsSuccessfully_withActivityContext() {
        activityRule.scenario.onActivity { activity ->
            val mockMessenger = mock(BinaryMessenger::class.java)

            // Set up mock to handle method channel messages
            doAnswer { invocation ->
                null
            }.whenever(mockMessenger).setMessageHandler(any(), any())

            var platformView: MediaRouteButtonPlatformView? = null
            var exception: Exception? = null

            runOnMainThread {
                try {
                    // Create the platform view - this should NOT throw
                    // "background can not be translucent: #0"
                    platformView = MediaRouteButtonPlatformView(
                        context = activity,
                        viewId = 1,
                        arguments = mapOf(
                            "alwaysVisible" to true,
                            "tintColor" to 0xFFFFFFFF.toInt()
                        ),
                        messenger = mockMessenger
                    )
                } catch (e: Exception) {
                    exception = e
                }
            }

            // Verify no exception was thrown
            if (exception != null) {
                fail("MediaRouteButtonPlatformView creation threw exception: ${exception!!.message}\n" +
                    "Stack trace: ${exception!!.stackTraceToString()}")
            }

            // Verify the view was created
            assertNotNull("Platform view should be created", platformView)

            // Verify getView() returns a valid view
            var view: View? = null
            runOnMainThread {
                view = platformView?.getView()
            }
            assertNotNull("getView() should return a view", view)

            // Clean up
            runOnMainThread {
                platformView?.dispose()
            }
        }
    }

    /**
     * Test that MediaRouteButtonViewFactory can create platform views.
     */
    @Test
    fun mediaRouteButtonViewFactory_createsPlatformView_withActivityContext() {
        activityRule.scenario.onActivity { activity ->
            val mockMessenger = mock(BinaryMessenger::class.java)

            doAnswer { invocation ->
                null
            }.whenever(mockMessenger).setMessageHandler(any(), any())

            var platformView: MediaRouteButtonPlatformView? = null
            var exception: Exception? = null

            runOnMainThread {
                try {
                    val factory = MediaRouteButtonViewFactory(mockMessenger)
                    platformView = factory.create(
                        activity,
                        2,
                        mapOf("alwaysVisible" to true)
                    ) as MediaRouteButtonPlatformView
                } catch (e: Exception) {
                    exception = e
                }
            }

            // Verify no exception was thrown
            if (exception != null) {
                fail("Factory.create() threw exception: ${exception!!.message}")
            }

            assertNotNull("Factory should create platform view", platformView)

            // Clean up
            runOnMainThread {
                platformView?.dispose()
            }
        }
    }

    /**
     * Test that MediaRouteButtonPlatformView handles method calls without crashing.
     */
    @Test
    fun mediaRouteButtonPlatformView_handlesMethodCalls() {
        activityRule.scenario.onActivity { activity ->
            val mockMessenger = mock(BinaryMessenger::class.java)

            doAnswer { invocation ->
                null
            }.whenever(mockMessenger).setMessageHandler(any(), any())

            var platformView: MediaRouteButtonPlatformView? = null

            runOnMainThread {
                platformView = MediaRouteButtonPlatformView(
                    context = activity,
                    viewId = 3,
                    arguments = null,
                    messenger = mockMessenger
                )
            }

            assertNotNull("Platform view should be created", platformView)

            // Test setTintColor method call
            runOnMainThread {
                val mockResult = mock(MethodChannel.Result::class.java)
                platformView?.onMethodCall(
                    MethodCall("setTintColor", mapOf("color" to 0xFF0000FF.toInt())),
                    mockResult
                )
                verify(mockResult).success(null)
            }

            // Test setAlwaysVisible method call
            runOnMainThread {
                val mockResult = mock(MethodChannel.Result::class.java)
                platformView?.onMethodCall(
                    MethodCall("setAlwaysVisible", mapOf("alwaysVisible" to true)),
                    mockResult
                )
                verify(mockResult).success(null)
            }

            // Test unknown method returns notImplemented
            runOnMainThread {
                val mockResult = mock(MethodChannel.Result::class.java)
                platformView?.onMethodCall(
                    MethodCall("unknownMethod", null),
                    mockResult
                )
                verify(mockResult).notImplemented()
            }

            // Clean up
            runOnMainThread {
                platformView?.dispose()
            }
        }
    }

    /**
     * Test that tint color configuration works.
     */
    @Test
    fun mediaRouteButtonPlatformView_appliesTintColor() {
        activityRule.scenario.onActivity { activity ->
            val mockMessenger = mock(BinaryMessenger::class.java)

            doAnswer { invocation ->
                null
            }.whenever(mockMessenger).setMessageHandler(any(), any())

            var platformView: MediaRouteButtonPlatformView? = null
            var exception: Exception? = null

            runOnMainThread {
                try {
                    // Create with tint color
                    platformView = MediaRouteButtonPlatformView(
                        context = activity,
                        viewId = 4,
                        arguments = mapOf(
                            "tintColor" to 0xFFFF0000.toInt() // Red
                        ),
                        messenger = mockMessenger
                    )
                } catch (e: Exception) {
                    exception = e
                }
            }

            assertNull("Should not throw exception", exception)
            assertNotNull("Platform view should be created", platformView)

            // Clean up
            runOnMainThread {
                platformView?.dispose()
            }
        }
    }
}
