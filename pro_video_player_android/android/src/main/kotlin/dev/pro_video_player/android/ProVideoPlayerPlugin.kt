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
    private lateinit var channel: MethodChannel
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
        channel = MethodChannel(binding.binaryMessenger, "dev.pro_video_player.android/methods")
        channel.setMethodCallHandler(this)

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

        // Register Pigeon API
        pigeonHandler = PigeonHostApiHandler(this, context)
        ProVideoPlayerHostApi.setUp(binding.binaryMessenger, pigeonHandler)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        verboseLog("Method called: ${call.method}")

        when (call.method) {
            "create" -> handleCreate(call, result)
            "dispose" -> handleDispose(call, result)
            "play" -> handlePlay(call, result)
            "pause" -> handlePause(call, result)
            "stop" -> handleStop(call, result)
            "seekTo" -> handleSeekTo(call, result)
            "setPlaybackSpeed" -> handleSetPlaybackSpeed(call, result)
            "setVolume" -> handleSetVolume(call, result)
            "getDeviceVolume" -> handleGetDeviceVolume(result)
            "setDeviceVolume" -> handleSetDeviceVolume(call, result)
            "getScreenBrightness" -> handleGetScreenBrightness(result)
            "setScreenBrightness" -> handleSetScreenBrightness(call, result)
            "getBatteryInfo" -> handleGetBatteryInfo(result)
            "setLooping" -> handleSetLooping(call, result)
            "setScalingMode" -> handleSetScalingMode(call, result)
            "setSubtitleRenderMode" -> handleSetSubtitleRenderMode(call, result)
            "setSubtitleTrack" -> handleSetSubtitleTrack(call, result)
            "setAudioTrack" -> handleSetAudioTrack(call, result)
            "addExternalSubtitle" -> handleAddExternalSubtitle(call, result)
            "removeExternalSubtitle" -> handleRemoveExternalSubtitle(call, result)
            "getExternalSubtitles" -> handleGetExternalSubtitles(call, result)
            "getPosition" -> handleGetPosition(call, result)
            "getDuration" -> handleGetDuration(call, result)
            "enterPip" -> handleEnterPip(call, result)
            "exitPip" -> handleExitPip(call, result)
            "isPipSupported" -> handleIsPipSupported(result)
            "setPipActions" -> handleSetPipActions(call, result)
            "enterFullscreen" -> handleEnterFullscreen(call, result)
            "exitFullscreen" -> handleExitFullscreen(call, result)
            "setVerboseLogging" -> handleSetVerboseLogging(call, result)
            "setMediaMetadata" -> handleSetMediaMetadata(call, result)
            "getVideoQualities" -> handleGetVideoQualities(call, result)
            "setVideoQuality" -> handleSetVideoQuality(call, result)
            "getCurrentVideoQuality" -> handleGetCurrentVideoQuality(call, result)
            "isQualitySelectionSupported" -> handleIsQualitySelectionSupported(call, result)
            "setBackgroundPlayback" -> handleSetBackgroundPlayback(call, result)
            "isBackgroundPlaybackSupported" -> handleIsBackgroundPlaybackSupported(result)
            "getVideoMetadata" -> handleGetVideoMetadata(call, result)
            "isCastingSupported" -> handleIsCastingSupported(result)
            "getAvailableCastDevices" -> handleGetAvailableCastDevices(call, result)
            "startCasting" -> handleStartCasting(call, result)
            "stopCasting" -> handleStopCasting(call, result)
            "getCastState" -> handleGetCastState(call, result)
            "getCurrentCastDevice" -> handleGetCurrentCastDevice(call, result)
            "setControlsMode" -> handleSetControlsMode(call, result)
            "getPlatformCapabilities" -> handleGetPlatformCapabilities(result)
            else -> result.notImplemented()
        }
    }

    private fun handleGetPlatformCapabilities(result: Result) {
        verboseLog("Getting platform capabilities")
        
        val capabilities = mapOf(
            "supportsPictureInPicture" to (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O),  // PiP requires Android 8.0+
            "supportsFullscreen" to true,  // Android always supports fullscreen via immersive mode
            "supportsBackgroundPlayback" to true,  // Android supports background playback via MediaSession
            "supportsCasting" to true,  // Android supports Chromecast (if Cast SDK integrated)
            "supportsAirPlay" to false,  // AirPlay is iOS/macOS only
            "supportsChromecast" to true,  // Chromecast support via Google Cast SDK
            "supportsRemotePlayback" to false,  // Remote Playback API is Web-only
            "supportsQualitySelection" to true,  // ExoPlayer supports quality selection for HLS/DASH
            "supportsPlaybackSpeedControl" to true,  // ExoPlayer supports playback speed
            "supportsSubtitles" to true,  // ExoPlayer supports subtitles via TextRenderer
            "supportsExternalSubtitles" to true,  // ExoPlayer supports external subtitle loading
            "supportsAudioTrackSelection" to true,  // ExoPlayer supports audio track selection
            "supportsChapters" to true,  // ExoPlayer supports chapters via Timeline
            "supportsVideoMetadataExtraction" to true,  // ExoPlayer provides metadata via Format
            "supportsNetworkMonitoring" to true,  // Android has ConnectivityManager
            "supportsBandwidthEstimation" to true,  // ExoPlayer provides bandwidth via BandwidthMeter
            "supportsAdaptiveBitrate" to true,  // ExoPlayer supports full ABR configuration
            "supportsHLS" to true,  // ExoPlayer has HlsMediaSource
            "supportsDASH" to true,  // ExoPlayer has DashMediaSource
            "supportsDeviceVolumeControl" to true,  // Android supports volume control via AudioManager
            "supportsScreenBrightnessControl" to true,  // Android supports brightness control
            "platformName" to "Android",
            "nativePlayerType" to "ExoPlayer",
            "additionalInfo" to mapOf(
                "osVersion" to android.os.Build.VERSION.RELEASE,
                "sdkVersion" to android.os.Build.VERSION.SDK_INT,
                "pipAvailable" to (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O),
                "chromecastAvailable" to isChromecastAvailable()
            )
        )
        
        result.success(capabilities)
    }

    private fun isChromecastAvailable(): Boolean {
        return try {
            // Check if Cast SDK classes are available
            Class.forName("com.google.android.gms.cast.framework.CastContext")
            true
        } catch (e: ClassNotFoundException) {
            false
        }
    }

    private fun handleSetVerboseLogging(call: MethodCall, result: Result) {
        val enabled = call.argument<Boolean>("enabled")
        if (enabled == null) {
            result.error("INVALID_ARGS", "Invalid arguments for setVerboseLogging", null)
            return
        }

        isVerboseLoggingEnabled = enabled
        verboseLog("Verbose logging ${if (enabled) "enabled" else "disabled"}")
        result.success(null)
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

    private fun handleCreate(call: MethodCall, result: Result) {
        val source = call.argument<Map<String, Any>>("source")
        val options = call.argument<Map<String, Any>>("options")

        if (source == null || options == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        // Resolve Flutter asset path if needed
        val resolvedSource = resolveAssetPath(source)

        val playerId = nextPlayerId++
        val player = VideoPlayer(
            playerId = playerId,
            context = context,
            messenger = flutterPluginBinding.binaryMessenger,
            source = resolvedSource,
            options = options
        )

        players[playerId] = player
        result.success(playerId)
    }

    private fun resolveAssetPath(source: Map<String, Any>): Map<String, Any> {
        val type = source["type"] as? String
        if (type != "asset") {
            return source
        }

        val assetPath = source["assetPath"] as? String ?: return source

        // Use FlutterLoader to get the correct asset path
        val flutterLoader = FlutterInjector.instance().flutterLoader()
        val resolvedPath = flutterLoader.getLookupKeyForAsset(assetPath)

        return source.toMutableMap().apply {
            put("assetPath", resolvedPath)
        }
    }

    private fun handleDispose(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        if (playerId == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        players[playerId]?.dispose()
        players.remove(playerId)
        result.success(null)
    }

    private fun handlePlay(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        player.play()
        result.success(null)
    }

    private fun handlePause(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        player.pause()
        result.success(null)
    }

    private fun handleStop(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        player.stop()
        result.success(null)
    }

    private fun handleSeekTo(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val position = call.argument<Int>("position")
        val player = playerId?.let { players[it] }

        if (player == null || position == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        if (position < 0) {
            result.error("INVALID_ARGS", "Position must be non-negative", null)
            return
        }

        player.seekTo(position.toLong())
        result.success(null)
    }

    private fun handleSetPlaybackSpeed(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val speed = call.argument<Double>("speed")
        val player = playerId?.let { players[it] }

        if (player == null || speed == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        if (speed <= 0.0 || speed > 10.0) {
            result.error("INVALID_ARGS", "Playback speed must be between 0.0 (exclusive) and 10.0", null)
            return
        }

        player.setPlaybackSpeed(speed.toFloat())
        result.success(null)
    }

    private fun handleSetVolume(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val volume = call.argument<Double>("volume")
        val player = playerId?.let { players[it] }

        if (player == null || volume == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        if (volume < 0.0 || volume > 1.0) {
            result.error("INVALID_ARGS", "Volume must be between 0.0 and 1.0", null)
            return
        }

        player.setVolume(volume.toFloat())
        result.success(null)
    }

    private fun handleGetDeviceVolume(result: Result) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val normalizedVolume = if (maxVolume > 0) currentVolume.toDouble() / maxVolume else 1.0
            result.success(normalizedVolume)
        } catch (e: Exception) {
            result.error("VOLUME_ERROR", "Failed to get device volume: ${e.message}", null)
        }
    }

    private fun handleSetDeviceVolume(call: MethodCall, result: Result) {
        val volume = call.argument<Double>("volume")
        if (volume == null || volume < 0.0 || volume > 1.0) {
            result.error("INVALID_ARGS", "Volume must be between 0.0 and 1.0", null)
            return
        }

        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val targetVolume = (volume * maxVolume).toInt()
            // Use 0 for flags to avoid showing system volume UI (our app shows its own feedback)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVolume, 0)
            result.success(null)
        } catch (e: Exception) {
            result.error("VOLUME_ERROR", "Failed to set device volume: ${e.message}", null)
        }
    }

    private fun handleGetScreenBrightness(result: Result) {
        try {
            val currentActivity = activity
            if (currentActivity == null) {
                result.error("NO_ACTIVITY", "No activity available", null)
                return
            }
            // Get the current window brightness
            val layoutParams = currentActivity.window.attributes
            val brightness = if (layoutParams.screenBrightness < 0) {
                // -1 means system default, get system brightness
                val contentResolver = context.contentResolver
                val systemBrightness = android.provider.Settings.System.getInt(
                    contentResolver,
                    android.provider.Settings.System.SCREEN_BRIGHTNESS,
                    255
                )
                systemBrightness / 255.0
            } else {
                layoutParams.screenBrightness.toDouble()
            }
            result.success(brightness)
        } catch (e: Exception) {
            result.error("BRIGHTNESS_ERROR", "Failed to get screen brightness: ${e.message}", null)
        }
    }

    private fun handleSetScreenBrightness(call: MethodCall, result: Result) {
        val brightness = call.argument<Double>("brightness")
        if (brightness == null || brightness < 0.0 || brightness > 1.0) {
            result.error("INVALID_ARGS", "Brightness must be between 0.0 and 1.0", null)
            return
        }

        try {
            val currentActivity = activity
            if (currentActivity == null) {
                result.error("NO_ACTIVITY", "No activity available", null)
                return
            }
            // Set window brightness (only affects this app's window)
            val layoutParams = currentActivity.window.attributes
            layoutParams.screenBrightness = brightness.toFloat()
            currentActivity.window.attributes = layoutParams
            result.success(null)
        } catch (e: Exception) {
            result.error("BRIGHTNESS_ERROR", "Failed to set screen brightness: ${e.message}", null)
        }
    }

    private fun handleGetBatteryInfo(result: Result) {
        try {
            val currentActivity = activity
            if (currentActivity == null) {
                result.success(null)
                return
            }

            val batteryManager = currentActivity.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            if (batteryManager == null) {
                result.success(null)
                return
            }

            // Get battery percentage
            val percentage = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            if (percentage < 0 || percentage > 100) {
                result.success(null)
                return
            }

            // Get charging state from battery status intent
            val batteryStatus = currentActivity.registerReceiver(
                null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            )

            val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                           status == BatteryManager.BATTERY_STATUS_FULL

            val batteryInfo = hashMapOf(
                "percentage" to percentage,
                "isCharging" to isCharging
            )
            result.success(batteryInfo)
        } catch (e: Exception) {
            // Battery info not available - return null
            result.success(null)
        }
    }

    private fun handleSetLooping(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val looping = call.argument<Boolean>("looping")
        val player = playerId?.let { players[it] }

        if (player == null || looping == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        player.setLooping(looping)
        result.success(null)
    }

    private fun handleSetScalingMode(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val scalingMode = call.argument<String>("scalingMode")
        val player = playerId?.let { players[it] }

        if (player == null || scalingMode == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        val validModes = setOf("fit", "fill", "fitWidth", "fitHeight")
        if (scalingMode !in validModes) {
            result.error("INVALID_ARGS", "Invalid scaling mode. Must be one of: fit, fill, fitWidth, fitHeight", null)
            return
        }

        player.setScalingMode(scalingMode)
        result.success(null)
    }

    private fun handleSetSubtitleRenderMode(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val renderMode = call.argument<String>("renderMode")
        val player = playerId?.let { players[it] }

        if (player == null || renderMode == null) {
            result.error("INVALID_ARGS", "Invalid player ID or render mode", null)
            return
        }

        player.setSubtitleRenderMode(renderMode)
        result.success(null)
    }

    private fun handleSetSubtitleTrack(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val track = call.argument<Map<String, Any>?>("track")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        player.setSubtitleTrack(track)
        result.success(null)
    }

    private fun handleSetAudioTrack(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val track = call.argument<Map<String, Any>?>("track")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        player.setAudioTrack(track)
        result.success(null)
    }

    // External Subtitles

    private fun handleAddExternalSubtitle(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val sourceType = call.argument<String>("sourceType")
        val path = call.argument<String>("path")
        val player = playerId?.let { players[it] }

        if (player == null || sourceType == null || path == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        val format = call.argument<String?>("format")
        val label = call.argument<String?>("label")
        val language = call.argument<String?>("language")
        val isDefault = call.argument<Boolean>("isDefault") ?: false
        val webvttContent = call.argument<String?>("webvttContent")

        player.addExternalSubtitle(sourceType, path, format, label, language, isDefault, webvttContent) { track ->
            result.success(track)
        }
    }

    private fun handleRemoveExternalSubtitle(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val trackId = call.argument<String>("trackId")
        val player = playerId?.let { players[it] }

        if (player == null || trackId == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        val success = player.removeExternalSubtitle(trackId)
        result.success(success)
    }

    private fun handleGetExternalSubtitles(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.getExternalSubtitles())
    }

    private fun handleGetPosition(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.getPosition().toInt())
    }

    private fun handleGetDuration(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.getDuration().toInt())
    }

    private fun handleEnterPip(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        val success = activity?.let { player.enterPip(it) } ?: false
        result.success(success)
    }

    private fun handleExitPip(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        player.exitPip()
        result.success(null)
    }

    private fun handleIsPipSupported(result: Result) {
        // Check Android version (PiP requires Android O+)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(false)
            return
        }

        // Check if the device supports PiP feature
        val hasSystemFeature = context.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
        if (!hasSystemFeature) {
            result.success(false)
            return
        }

        // Check if activity has android:supportsPictureInPicture="true" in manifest
        // We use the FLAG value directly since ActivityInfo.FLAG_SUPPORTS_PICTURE_IN_PICTURE is hidden
        val currentActivity = activity
        if (currentActivity == null) {
            result.success(false)
            return
        }

        val supported = try {
            val activityInfo = currentActivity.packageManager.getActivityInfo(
                currentActivity.componentName,
                PackageManager.GET_META_DATA
            )
            // FLAG_SUPPORTS_PICTURE_IN_PICTURE = 0x400000 (added in API 24)
            val FLAG_SUPPORTS_PICTURE_IN_PICTURE = 0x400000
            (activityInfo.flags and FLAG_SUPPORTS_PICTURE_IN_PICTURE) != 0
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }

        result.success(supported)
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleSetPipActions(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        val actions = call.argument<List<Map<String, Any>>>("actions")
        player.setPipActions(actions)
        result.success(null)
    }

    private fun handleEnterFullscreen(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        val success = activity?.let { player.enterFullscreen(it) } ?: false
        result.success(success)
    }

    private fun handleExitFullscreen(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        activity?.let { player.exitFullscreen(it) }
        result.success(null)
    }

    private fun handleSetMediaMetadata(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val metadata = call.argument<Map<String, Any>>("metadata")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        player.setMediaMetadata(metadata ?: emptyMap())
        result.success(null)
    }

    private fun handleGetVideoQualities(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.getVideoQualities())
    }

    private fun handleSetVideoQuality(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val track = call.argument<Map<String, Any>?>("track")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.setVideoQuality(track))
    }

    private fun handleGetCurrentVideoQuality(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.getCurrentVideoQuality())
    }

    private fun handleIsQualitySelectionSupported(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.isQualitySelectionSupported())
    }

    private fun handleSetBackgroundPlayback(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val enabled = call.argument<Boolean>("enabled")
        val player = playerId?.let { players[it] }

        if (player == null || enabled == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        result.success(player.setBackgroundPlayback(enabled))
    }

    private fun handleIsBackgroundPlaybackSupported(result: Result) {
        // Background playback is supported on Android if:
        // 1. The MediaPlaybackService is declared in AndroidManifest.xml
        // 2. The FOREGROUND_SERVICE permission is granted (for Android 9+)
        // We check by trying to resolve the service
        try {
            val serviceIntent = android.content.Intent(context, MediaPlaybackService::class.java)
            val resolveInfo = context.packageManager.resolveService(serviceIntent, 0)
            result.success(resolveInfo != null)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun handleGetVideoMetadata(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.getVideoMetadata())
    }

    // MARK: - Casting Handlers

    private fun handleIsCastingSupported(result: Result) {
        result.success(true)
    }

    private fun handleGetAvailableCastDevices(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.getAvailableCastDevices())
    }

    private fun handleStartCasting(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val device = call.argument<Map<String, Any>>("device")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        // Device is optional - if null, the player will show the cast picker
        // or use the current active session
        result.success(player.startCasting(device ?: emptyMap()))
    }

    private fun handleStopCasting(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        player.stopCasting()
        result.success(null)
    }

    private fun handleGetCastState(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.getCastState())
    }

    private fun handleGetCurrentCastDevice(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        result.success(player.getCurrentCastDevice())
    }

    private fun handleSetControlsMode(call: MethodCall, result: Result) {
        val playerId = call.argument<Int>("playerId")
        val controlsModeString = call.argument<String>("controlsMode")
        val player = playerId?.let { players[it] }

        if (player == null) {
            result.error("INVALID_ARGS", "Invalid player ID", null)
            return
        }

        val useNativeControls = controlsModeString?.lowercase() == "native"
        player.setControlsMode(useNativeControls)
        result.success(null)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
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
