package dev.pro_video_player.android

import android.app.Activity
import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import dev.pro_video_player.pro_video_player_android.ProVideoPlayerHostApi
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class ProVideoPlayerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, Application.ActivityLifecycleCallbacks, EventChannel.StreamHandler {
    // Note: MethodCallHandler interface kept for test compatibility, but onMethodCall() is a no-op
    private lateinit var context: Context
    private var activity: Activity? = null
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    private val players = mutableMapOf<Int, VideoPlayer>()
    private var nextPlayerId = 0

    // Track players that were paused due to app going to background
    private val pausedForBackground = mutableSetOf<Int>()

    // Battery event channel
    private lateinit var batteryEventChannel: EventChannel
    private var batteryEventSink: EventChannel.EventSink? = null
    private var batteryReceiver: BroadcastReceiver? = null

    // Pigeon API handler
    private var pigeonHandler: PigeonHostApiHandler? = null

    companion object {
        private const val TAG = "ProVideoPlayerPlugin"

        /// Global verbose logging flag for Android video player
        @Volatile
        var isVerboseLoggingEnabled: Boolean = false
            private set

        /// Helper function for verbose logging
        fun verboseLog(message: String, tag: String = TAG) {
            if (isVerboseLoggingEnabled) {
                android.util.Log.d(tag, message)
            }
        }

        /// Set verbose logging (public for Pigeon handler)
        fun setVerboseLogging(enabled: Boolean) {
            isVerboseLoggingEnabled = enabled
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding
        context = binding.applicationContext

        // Set up battery event channel
        batteryEventChannel = EventChannel(binding.binaryMessenger, "dev.pro_video_player.android/batteryUpdates")
        batteryEventChannel.setStreamHandler(this)

        // Register the platform view factory
        binding.platformViewRegistry.registerViewFactory(
            "dev.pro_video_player.android/video_view",
            VideoPlayerViewFactory(this)
        )

        // Register the MediaRouteButton platform view factory for Chromecast
        // Note: Uses AppCompat theme overlay to fix "background can not be translucent" error
        binding.platformViewRegistry.registerViewFactory(
            "dev.pro_video_player.android/cast_button",
            MediaRouteButtonViewFactory(binding.binaryMessenger)
        )

        // Register Pigeon API for all method calls
        pigeonHandler = PigeonHostApiHandler(this, context)
        ProVideoPlayerHostApi.setUp(binding.binaryMessenger, pigeonHandler)
    }

    // Note: This onMethodCall() method is no longer used since we migrated to Pigeon.
    // It's kept only because tests might still reference it.
    // All method calls now go through PigeonHostApiHandler instead.
    override fun onMethodCall(call: MethodCall, result: Result) {
        // No-op: All calls should go through Pigeon API now
        result.notImplemented()
    }

    fun getPlayer(playerId: Int): VideoPlayer? = players[playerId]

    fun getActivity(): Activity? = activity

    fun createPlayer(source: Map<String, Any>, options: Map<String, Any>): Int {
        val playerId = nextPlayerId++
        val player = VideoPlayer(
            playerId = playerId,
            context = context,
            messenger = flutterPluginBinding.binaryMessenger,
            source = source,
            options = options
        )
        players[playerId] = player
        return playerId
    }

    fun removePlayer(playerId: Int) {
        players.remove(playerId)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        players.values.forEach { it.dispose() }
        players.clear()

        // Unregister Pigeon API
        ProVideoPlayerHostApi.setUp(binding.binaryMessenger, null)
        pigeonHandler = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.activity.application.registerActivityLifecycleCallbacks(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity?.application?.unregisterActivityLifecycleCallbacks(this)
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.activity.application.registerActivityLifecycleCallbacks(this)
    }

    override fun onDetachedFromActivity() {
        activity?.application?.unregisterActivityLifecycleCallbacks(this)
        activity = null
    }

    // MARK: - Application.ActivityLifecycleCallbacks

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

    override fun onActivityStarted(activity: Activity) {}

    override fun onActivityResumed(activity: Activity) {
        // Notify all players that app is in foreground (for wake lock management)
        if (activity == this.activity) {
            players.forEach { (_, player) ->
                player.onAppForeground()
            }

            // Resume players that were paused when app went to background
            pausedForBackground.forEach { playerId ->
                players[playerId]?.play()
            }
            pausedForBackground.clear()
        }
    }

    override fun onActivityPaused(activity: Activity) {
        if (activity == this.activity) {
            // Notify all players that app is in background (for wake lock management)
            players.forEach { (_, player) ->
                player.onAppBackground()
            }

            // Pause players that don't allow background playback when app goes to background
            players.forEach { (playerId, player) ->
                if (!player.allowsBackgroundPlayback() && player.isPlaying()) {
                    player.pause()
                    pausedForBackground.add(playerId)
                }
            }
        }
    }

    override fun onActivityStopped(activity: Activity) {}

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

    override fun onActivityDestroyed(activity: Activity) {}

    // MARK: - EventChannel.StreamHandler (Battery Updates)

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        batteryEventSink = events

        // Register broadcast receiver for battery changes
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_BATTERY_CHANGED)
        }

        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                sendBatteryUpdate()
            }
        }

        context.registerReceiver(batteryReceiver, filter)

        // Send initial battery state
        sendBatteryUpdate()
    }

    override fun onCancel(arguments: Any?) {
        // Unregister battery receiver
        batteryReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (e: Exception) {
                // Receiver not registered, ignore
            }
        }
        batteryReceiver = null
        batteryEventSink = null
    }

    private fun sendBatteryUpdate() {
        val eventSink = batteryEventSink ?: return

        try {
            val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            if (batteryManager == null) {
                return
            }

            val percentage = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            if (percentage < 0 || percentage > 100) {
                return
            }

            val batteryStatus = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                           status == BatteryManager.BATTERY_STATUS_FULL

            val batteryInfo = hashMapOf(
                "percentage" to percentage,
                "isCharging" to isCharging
            )
            eventSink.success(batteryInfo)
        } catch (e: Exception) {
            // Battery info not available - ignore
        }
    }
}
