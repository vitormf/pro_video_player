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
import dev.pro_video_player.pro_video_player_android.*
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel

class ProVideoPlayerPlugin: FlutterPlugin, ActivityAware, Application.ActivityLifecycleCallbacks, ProVideoPlayerHostApi {
    private lateinit var context: Context
    private var activity: Activity? = null
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    private lateinit var flutterApi: ProVideoPlayerFlutterApi

    private val players = mutableMapOf<Int, VideoPlayer>()
    private var nextPlayerId = 0

    // Track players that were paused due to app going to background
    private val pausedForBackground = mutableSetOf<Int>()

    // Battery monitoring
    private var batteryReceiver: BroadcastReceiver? = null

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

        // Initialize FlutterApi for native → Dart callbacks
        flutterApi = ProVideoPlayerFlutterApi(binding.binaryMessenger)

        // Start battery monitoring
        startBatteryMonitoring()

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

        // Register Pigeon API - this plugin implements ProVideoPlayerHostApi directly
        ProVideoPlayerHostApi.setUp(binding.binaryMessenger, this)
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
        // Wire up FlutterApi for native → Dart callbacks
        player.flutterApi = flutterApi
        players[playerId] = player
        return playerId
    }

    fun removePlayer(playerId: Int) {
        players.remove(playerId)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        players.values.forEach { it.dispose() }
        players.clear()

        // Stop battery monitoring
        stopBatteryMonitoring()

        // Unregister Pigeon API
        ProVideoPlayerHostApi.setUp(binding.binaryMessenger, null)
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

    // MARK: - Battery Monitoring

    private fun startBatteryMonitoring() {
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

    private fun stopBatteryMonitoring() {
        // Unregister battery receiver
        batteryReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (e: Exception) {
                // Receiver not registered, ignore
            }
        }
        batteryReceiver = null
    }

    private fun sendBatteryUpdate() {
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

            val batteryInfo = BatteryInfoMessage(
                percentage = percentage.toLong(),
                isCharging = isCharging
            )
            flutterApi.onBatteryInfoChanged(batteryInfo) {}
        } catch (e: Exception) {
            // Battery info not available - ignore
        }
    }

    // MARK: - ProVideoPlayerHostApi Implementation

    // MARK: - Core Playback Methods

    override fun create(
        source: VideoSourceMessage,
        options: VideoPlayerOptionsMessage,
        callback: (Result<Long>) -> Unit
    ) {
        try {
            // Convert Pigeon messages to Map format expected by plugin
            val sourceMap = convertVideoSourceToMap(source)
            val optionsMap = convertPlayerOptionsToMap(options)

            // Resolve asset path if needed
            val resolvedSource = if (source.type == VideoSourceType.ASSET) {
                resolveAssetPath(sourceMap)
            } else {
                sourceMap
            }

            // Create player using plugin's existing create logic
            val playerId = createPlayer(resolvedSource, optionsMap)
            callback(Result.success(playerId.toLong()))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("CREATE_ERROR", e.message, null)))
        }
    }

    private fun resolveAssetPath(source: Map<String, Any>): Map<String, Any> {
        val assetPath = source["assetPath"] as? String ?: return source
        val flutterLoader = FlutterInjector.instance().flutterLoader()
        val resolvedPath = flutterLoader.getLookupKeyForAsset(assetPath)
        return source.toMutableMap().apply {
            put("assetPath", resolvedPath)
        }
    }

    override fun dispose(playerId: Long, callback: (Result<Unit>) -> Unit) {
        try {
            val player = getPlayer(playerId.toInt())
            if (player == null) {
                callback(Result.failure(FlutterError("INVALID_PLAYER", "Player not found", null)))
                return
            }
            player.dispose()
            removePlayer(playerId.toInt())
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("DISPOSE_ERROR", e.message, null)))
        }
    }

    override fun play(playerId: Long, callback: (Result<Unit>) -> Unit) {
        delegatePlayerMethod(playerId, { it.play() }, callback)
    }

    override fun pause(playerId: Long, callback: (Result<Unit>) -> Unit) {
        delegatePlayerMethod(playerId, { it.pause() }, callback)
    }

    override fun stop(playerId: Long, callback: (Result<Unit>) -> Unit) {
        delegatePlayerMethod(playerId, { it.stop() }, callback)
    }

    override fun seekTo(playerId: Long, positionMs: Long, callback: (Result<Unit>) -> Unit) {
        delegatePlayerMethod(playerId, { it.seekTo(positionMs) }, callback)
    }

    override fun setPlaybackSpeed(playerId: Long, speed: Double, callback: (Result<Unit>) -> Unit) {
        delegatePlayerMethod(playerId, { it.setPlaybackSpeed(speed.toFloat()) }, callback)
    }

    override fun setVolume(playerId: Long, volume: Double, callback: (Result<Unit>) -> Unit) {
        delegatePlayerMethod(playerId, { it.setVolume(volume.toFloat()) }, callback)
    }

    override fun getPosition(playerId: Long, callback: (Result<Long>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val position = player.getPosition()
            callback(Result.success(position))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("POSITION_ERROR", e.message, null)))
        }
    }

    override fun getDuration(playerId: Long, callback: (Result<Long>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val duration = player.getDuration()
            callback(Result.success(duration))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("DURATION_ERROR", e.message, null)))
        }
    }

    // MARK: - Configuration Methods

    override fun getPlatformInfo(callback: (Result<PlatformInfoMessage>) -> Unit) {
        try {
            val message = PlatformInfoMessage(
                platformName = "Android",
                nativePlayerType = "ExoPlayer",
                additionalInfo = mapOf(
                    "osVersion" to Build.VERSION.RELEASE,
                    "sdkVersion" to Build.VERSION.SDK_INT,
                    "pipAvailable" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                )
            )
            callback(Result.success(message))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("PLATFORM_INFO_ERROR", e.message, null)))
        }
    }

    override fun setVerboseLogging(enabled: Boolean, callback: (Result<Unit>) -> Unit) {
        try {
            ProVideoPlayerPlugin.setVerboseLogging(enabled)
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("LOGGING_ERROR", e.message, null)))
        }
    }

    // MARK: - Platform Capabilities

    override fun supportsPictureInPicture(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O))
    }

    override fun supportsFullscreen(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsBackgroundPlayback(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsCasting(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsAirPlay(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(false))
    }

    override fun supportsChromecast(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsRemotePlayback(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(false))
    }

    override fun supportsQualitySelection(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsPlaybackSpeedControl(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsSubtitles(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsExternalSubtitles(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsAudioTrackSelection(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsChapters(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsVideoMetadataExtraction(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsNetworkMonitoring(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsBandwidthEstimation(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsAdaptiveBitrate(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsHLS(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsDASH(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsDeviceVolumeControl(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun supportsScreenBrightnessControl(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun setLooping(playerId: Long, looping: Boolean, callback: (Result<Unit>) -> Unit) {
        delegatePlayerMethod(playerId, { it.setLooping(looping) }, callback)
    }

    override fun setScalingMode(playerId: Long, mode: VideoScalingModeEnum, callback: (Result<Unit>) -> Unit) {
        val modeString = when (mode) {
            VideoScalingModeEnum.FIT -> "fit"
            VideoScalingModeEnum.FILL -> "fill"
            VideoScalingModeEnum.STRETCH -> "stretch"
        }
        delegatePlayerMethod(playerId, { it.setScalingMode(modeString) }, callback)
    }

    override fun setControlsMode(playerId: Long, mode: ControlsModeEnum, callback: (Result<Unit>) -> Unit) {
        val useNativeControls = mode == ControlsModeEnum.NATIVE_CONTROLS
        delegatePlayerMethod(playerId, { it.setControlsMode(useNativeControls) }, callback)
    }

    // MARK: - Device Controls

    override fun getDeviceVolume(callback: (Result<Double>) -> Unit) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val normalizedVolume = if (maxVolume > 0) currentVolume.toDouble() / maxVolume else 1.0
            callback(Result.success(normalizedVolume))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("VOLUME_ERROR", e.message, null)))
        }
    }

    override fun setDeviceVolume(volume: Double, callback: (Result<Unit>) -> Unit) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val targetVolume = (volume * maxVolume).toInt()
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVolume, 0)
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("VOLUME_ERROR", e.message, null)))
        }
    }

    override fun getScreenBrightness(callback: (Result<Double>) -> Unit) {
        try {
            val activity = getActivity()
            if (activity == null) {
                callback(Result.failure(FlutterError("NO_ACTIVITY", "No activity available", null)))
                return
            }

            val layoutParams = activity.window.attributes
            val brightness = if (layoutParams.screenBrightness < 0) {
                val systemBrightness = android.provider.Settings.System.getInt(
                    context.contentResolver,
                    android.provider.Settings.System.SCREEN_BRIGHTNESS,
                    255
                )
                systemBrightness / 255.0
            } else {
                layoutParams.screenBrightness.toDouble()
            }
            callback(Result.success(brightness))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("BRIGHTNESS_ERROR", e.message, null)))
        }
    }

    override fun setScreenBrightness(brightness: Double, callback: (Result<Unit>) -> Unit) {
        try {
            val activity = getActivity()
            if (activity == null) {
                callback(Result.failure(FlutterError("NO_ACTIVITY", "No activity available", null)))
                return
            }

            val layoutParams = activity.window.attributes
            layoutParams.screenBrightness = brightness.toFloat()
            activity.window.attributes = layoutParams
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("BRIGHTNESS_ERROR", e.message, null)))
        }
    }

    override fun getBatteryInfo(callback: (Result<BatteryInfoMessage?>) -> Unit) {
        try {
            val activity = getActivity()
            if (activity == null) {
                callback(Result.success(null))
                return
            }

            val batteryManager = activity.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            if (batteryManager == null) {
                callback(Result.success(null))
                return
            }

            val percentage = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            if (percentage < 0 || percentage > 100) {
                callback(Result.success(null))
                return
            }

            val batteryStatus = activity.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                           status == BatteryManager.BATTERY_STATUS_FULL

            val message = BatteryInfoMessage(
                percentage = percentage.toLong(),
                isCharging = isCharging
            )
            callback(Result.success(message))
        } catch (e: Exception) {
            callback(Result.success(null))
        }
    }

    // MARK: - Subtitle Methods

    override fun setSubtitleTrack(playerId: Long, track: SubtitleTrackMessage?, callback: (Result<Unit>) -> Unit) {
        val trackMap = track?.let { convertSubtitleTrackToMap(it) }
        delegatePlayerMethod(playerId, { it.setSubtitleTrack(trackMap) }, callback)
    }

    override fun setSubtitleRenderMode(playerId: Long, mode: SubtitleRenderModeEnum, callback: (Result<Unit>) -> Unit) {
        val modeString = when (mode) {
            SubtitleRenderModeEnum.AUTO -> "auto"
            SubtitleRenderModeEnum.NATIVE -> "native"
            SubtitleRenderModeEnum.FLUTTER -> "flutter"
        }
        delegatePlayerMethod(playerId, { it.setSubtitleRenderMode(modeString) }, callback)
    }

    override fun addExternalSubtitle(
        playerId: Long,
        source: SubtitleSourceMessage,
        callback: (Result<ExternalSubtitleTrackMessage?>) -> Unit
    ) {
        try {
            val player = getPlayerOrFail(playerId)

            val sourceType = when (source.type) {
                VideoSourceType.NETWORK -> "network"
                VideoSourceType.FILE -> "file"
                VideoSourceType.ASSET -> "asset"
            }

            player.addExternalSubtitle(
                sourceType,
                source.path,
                source.format?.let { convertSubtitleFormatToString(it) },
                source.label,
                source.language,
                source.isDefault,
                source.webvttContent
            ) { trackMap ->
                val message = trackMap?.let { convertMapToExternalSubtitleTrack(it) }
                callback(Result.success(message))
            }
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("SUBTITLE_ERROR", e.message, null)))
        }
    }

    override fun removeExternalSubtitle(playerId: Long, trackId: String, callback: (Result<Boolean>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val success = player.removeExternalSubtitle(trackId)
            callback(Result.success(success))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("SUBTITLE_ERROR", e.message, null)))
        }
    }

    override fun getExternalSubtitles(playerId: Long, callback: (Result<List<ExternalSubtitleTrackMessage?>>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val tracks = player.getExternalSubtitles()
            val messages = tracks.map { convertMapToExternalSubtitleTrack(it) }
            callback(Result.success(messages))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("SUBTITLE_ERROR", e.message, null)))
        }
    }

    // MARK: - Audio Track Methods

    override fun setAudioTrack(playerId: Long, track: AudioTrackMessage?, callback: (Result<Unit>) -> Unit) {
        val trackMap = track?.let { convertAudioTrackToMap(it) }
        delegatePlayerMethod(playerId, { it.setAudioTrack(trackMap) }, callback)
    }

    // MARK: - PiP Methods

    override fun enterPip(playerId: Long, options: PipOptionsMessage, callback: (Result<Boolean>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val activity = getActivity()
            if (activity == null) {
                callback(Result.success(false))
                return
            }
            val success = player.enterPip(activity)
            callback(Result.success(success))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("PIP_ERROR", e.message, null)))
        }
    }

    override fun exitPip(playerId: Long, callback: (Result<Unit>) -> Unit) {
        delegatePlayerMethod(playerId, { it.exitPip() }, callback)
    }

    override fun isPipSupported(callback: (Result<Boolean>) -> Unit) {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                callback(Result.success(false))
                return
            }

            val hasSystemFeature = context.packageManager.hasSystemFeature(
                android.content.pm.PackageManager.FEATURE_PICTURE_IN_PICTURE
            )
            callback(Result.success(hasSystemFeature))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("PIP_ERROR", e.message, null)))
        }
    }

    override fun setPipActions(playerId: Long, actions: List<PipActionMessage?>, callback: (Result<Unit>) -> Unit) {
        val actionsList = actions.mapNotNull { it?.let { convertPipActionToMap(it) } }
        delegatePlayerMethod(playerId, { it.setPipActions(actionsList) }, callback)
    }

    // MARK: - Fullscreen Methods

    override fun enterFullscreen(playerId: Long, callback: (Result<Boolean>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val activity = getActivity()
            if (activity == null) {
                callback(Result.success(false))
                return
            }
            val success = player.enterFullscreen(activity)
            callback(Result.success(success))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("FULLSCREEN_ERROR", e.message, null)))
        }
    }

    override fun exitFullscreen(playerId: Long, callback: (Result<Unit>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val activity = getActivity()
            if (activity == null) {
                callback(Result.failure(FlutterError("NO_ACTIVITY", "No activity available", null)))
                return
            }
            player.exitFullscreen(activity)
            callback(Result.success(Unit))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("FULLSCREEN_ERROR", e.message, null)))
        }
    }

    override fun setWindowFullscreen(fullscreen: Boolean, callback: (Result<Unit>) -> Unit) {
        // Not applicable on Android (desktop-only feature)
        callback(Result.success(Unit))
    }

    // MARK: - Background Playback Methods

    override fun setBackgroundPlayback(playerId: Long, enabled: Boolean, callback: (Result<Boolean>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val success = player.setBackgroundPlayback(enabled)
            callback(Result.success(success))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("BACKGROUND_ERROR", e.message, null)))
        }
    }

    override fun isBackgroundPlaybackSupported(callback: (Result<Boolean>) -> Unit) {
        try {
            val serviceIntent = Intent(context, MediaPlaybackService::class.java)
            val resolveInfo = context.packageManager.resolveService(serviceIntent, 0)
            callback(Result.success(resolveInfo != null))
        } catch (e: Exception) {
            callback(Result.success(false))
        }
    }

    // MARK: - Quality/Track Methods

    override fun getVideoQualities(playerId: Long, callback: (Result<List<VideoQualityTrackMessage?>>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val qualities = player.getVideoQualities()
            val messages = qualities.map { convertMapToVideoQualityTrack(it) }
            callback(Result.success(messages))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("QUALITY_ERROR", e.message, null)))
        }
    }

    override fun setVideoQuality(playerId: Long, track: VideoQualityTrackMessage, callback: (Result<Boolean>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val trackMap = convertVideoQualityTrackToMap(track)
            val success = player.setVideoQuality(trackMap)
            callback(Result.success(success))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("QUALITY_ERROR", e.message, null)))
        }
    }

    override fun getCurrentVideoQuality(playerId: Long, callback: (Result<VideoQualityTrackMessage>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val qualityMap = player.getCurrentVideoQuality()
            val message = convertMapToVideoQualityTrack(qualityMap)
            callback(Result.success(message))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("QUALITY_ERROR", e.message, null)))
        }
    }

    override fun isQualitySelectionSupported(playerId: Long, callback: (Result<Boolean>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val supported = player.isQualitySelectionSupported()
            callback(Result.success(supported))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("QUALITY_ERROR", e.message, null)))
        }
    }

    // MARK: - Metadata Methods

    override fun getVideoMetadata(playerId: Long, callback: (Result<VideoMetadataMessage?>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val metadataMap = player.getVideoMetadata()
            val message = metadataMap?.let { convertMapToVideoMetadata(it) }
            callback(Result.success(message))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("METADATA_ERROR", e.message, null)))
        }
    }

    override fun setMediaMetadata(playerId: Long, metadata: MediaMetadataMessage, callback: (Result<Unit>) -> Unit) {
        val metadataMap = convertMediaMetadataToMap(metadata)
        delegatePlayerMethod(playerId, { it.setMediaMetadata(metadataMap) }, callback)
    }

    // MARK: - Casting Methods

    override fun isCastingSupported(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(true))
    }

    override fun getAvailableCastDevices(playerId: Long, callback: (Result<List<CastDeviceMessage?>>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val devices = player.getAvailableCastDevices()
            val messages = devices.map { convertMapToCastDevice(it) }
            callback(Result.success(messages))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("CAST_ERROR", e.message, null)))
        }
    }

    override fun startCasting(playerId: Long, device: CastDeviceMessage?, callback: (Result<Boolean>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val deviceMap = device?.let { convertCastDeviceToMap(it) } ?: emptyMap()
            val success = player.startCasting(deviceMap)
            callback(Result.success(success))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("CAST_ERROR", e.message, null)))
        }
    }

    override fun stopCasting(playerId: Long, callback: (Result<Boolean>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            player.stopCasting()
            callback(Result.success(true))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("CAST_ERROR", e.message, null)))
        }
    }

    override fun getCastState(playerId: Long, callback: (Result<CastStateEnum>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val stateString = player.getCastState()
            val state = when (stateString) {
                "notConnected" -> CastStateEnum.NOT_CONNECTED
                "connecting" -> CastStateEnum.CONNECTING
                "connected" -> CastStateEnum.CONNECTED
                "disconnecting" -> CastStateEnum.DISCONNECTING
                else -> CastStateEnum.NOT_CONNECTED
            }
            callback(Result.success(state))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("CAST_ERROR", e.message, null)))
        }
    }

    override fun getCurrentCastDevice(playerId: Long, callback: (Result<CastDeviceMessage?>) -> Unit) {
        try {
            val player = getPlayerOrFail(playerId)
            val deviceMap = player.getCurrentCastDevice()
            val message = deviceMap?.let { convertMapToCastDevice(it) }
            callback(Result.success(message))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("CAST_ERROR", e.message, null)))
        }
    }

    // MARK: - Helper Methods

    private fun getPlayerOrFail(playerId: Long): VideoPlayer {
        val player = getPlayer(playerId.toInt())
        if (player == null) {
            throw FlutterError("INVALID_PLAYER", "Player not found: $playerId", null)
        }
        return player
    }

    private fun delegatePlayerMethod(
        playerId: Long,
        action: (VideoPlayer) -> Unit,
        callback: (Result<Unit>) -> Unit
    ) {
        try {
            val player = getPlayerOrFail(playerId)
            action(player)
            callback(Result.success(Unit))
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("OPERATION_ERROR", e.message, null)))
        }
    }

    // MARK: - Conversion Methods (Pigeon Messages ↔ Maps)

    private fun convertVideoSourceToMap(source: VideoSourceMessage): Map<String, Any> {
        val map = mutableMapOf<String, Any>(
            "type" to when (source.type) {
                VideoSourceType.NETWORK -> "network"
                VideoSourceType.FILE -> "file"
                VideoSourceType.ASSET -> "asset"
            }
        )

        source.url?.let { map["url"] = it }
        source.path?.let { map["path"] = it }
        source.assetPath?.let { map["assetPath"] = it }
        source.headers?.let { map["headers"] = it }

        return map
    }

    private fun convertPlayerOptionsToMap(options: VideoPlayerOptionsMessage): Map<String, Any> {
        val map = mutableMapOf<String, Any>()

        options.autoPlay?.let { map["autoPlay"] = it }
        options.looping?.let { map["looping"] = it }
        options.volume?.let { map["volume"] = it }
        options.playbackSpeed?.let { map["playbackSpeed"] = it }
        options.startPosition?.let { map["startPosition"] = it.toInt() }
        options.enablePip?.let { map["enablePip"] = it }
        options.enableBackgroundPlayback?.let { map["enableBackgroundPlayback"] = it }
        options.preferredAudioLanguage?.let { map["preferredAudioLanguage"] = it }
        options.preferredSubtitleLanguage?.let { map["preferredSubtitleLanguage"] = it }
        options.maxBitrate?.let { map["maxBitrate"] = it.toInt() }
        options.minBitrate?.let { map["minBitrate"] = it.toInt() }
        options.preferredAudioRendition?.let { map["preferredAudioRendition"] = it }

        return map
    }

    private fun convertSubtitleTrackToMap(track: SubtitleTrackMessage): Map<String, Any> {
        val map = mutableMapOf<String, Any>("id" to track.id)
        track.label?.let { map["label"] = it }
        track.language?.let { map["language"] = it }
        track.format?.let { map["format"] = convertSubtitleFormatToString(it) }
        track.isDefault?.let { map["isDefault"] = it }
        return map
    }

    private fun convertSubtitleFormatToString(format: SubtitleFormatEnum): String {
        return when (format) {
            SubtitleFormatEnum.SRT -> "srt"
            SubtitleFormatEnum.VTT -> "vtt"
            SubtitleFormatEnum.SSA -> "ssa"
            SubtitleFormatEnum.ASS -> "ass"
            SubtitleFormatEnum.TTML -> "ttml"
        }
    }

    private fun convertMapToExternalSubtitleTrack(map: Map<String, Any?>): ExternalSubtitleTrackMessage {
        return ExternalSubtitleTrackMessage(
            id = map["id"] as String,
            label = (map["label"] as? String) ?: "",
            language = map["language"] as? String,
            isDefault = map["isDefault"] as? Boolean ?: false,
            path = (map["path"] as? String) ?: "",
            sourceType = (map["sourceType"] as? String) ?: "file",
            format = (map["format"] as? String)?.let { convertStringToSubtitleFormat(it) } ?: SubtitleFormatEnum.SRT
        )
    }

    private fun convertStringToSubtitleFormat(format: String): SubtitleFormatEnum {
        return when (format.lowercase()) {
            "srt" -> SubtitleFormatEnum.SRT
            "vtt", "webvtt" -> SubtitleFormatEnum.VTT
            "ssa" -> SubtitleFormatEnum.SSA
            "ass" -> SubtitleFormatEnum.ASS
            "ttml" -> SubtitleFormatEnum.TTML
            else -> SubtitleFormatEnum.VTT
        }
    }

    private fun convertAudioTrackToMap(track: AudioTrackMessage): Map<String, Any> {
        val map = mutableMapOf<String, Any>("id" to track.id)
        track.label?.let { map["label"] = it }
        track.language?.let { map["language"] = it }
        track.channelCount?.let { map["channelCount"] = it.toInt() }
        track.isDefault?.let { map["isDefault"] = it }
        return map
    }

    private fun convertPipActionToMap(action: PipActionMessage): Map<String, Any> {
        val map = mutableMapOf<String, Any>(
            "type" to when (action.type) {
                PipActionTypeEnum.PLAY_PAUSE -> "playPause"
                PipActionTypeEnum.SKIP_PREVIOUS -> "skipPrevious"
                PipActionTypeEnum.SKIP_NEXT -> "skipNext"
                PipActionTypeEnum.SKIP_BACKWARD -> "skipBackward"
                PipActionTypeEnum.SKIP_FORWARD -> "skipForward"
            }
        )
        action.title?.let { map["title"] = it }
        action.iconName?.let { map["iconName"] = it }
        return map
    }

    private fun convertMapToVideoQualityTrack(map: Map<String, Any?>): VideoQualityTrackMessage {
        return VideoQualityTrackMessage(
            id = map["id"] as String,
            label = map["label"] as? String,
            bitrate = (map["bitrate"] as? Number)?.toLong(),
            width = (map["width"] as? Number)?.toLong(),
            height = (map["height"] as? Number)?.toLong(),
            codec = map["codec"] as? String,
            isDefault = map["isDefault"] as? Boolean ?: false
        )
    }

    private fun convertVideoQualityTrackToMap(track: VideoQualityTrackMessage): Map<String, Any> {
        val map = mutableMapOf<String, Any>("id" to track.id)
        track.label?.let { map["label"] = it }
        track.bitrate?.let { map["bitrate"] = it.toInt() }
        track.width?.let { map["width"] = it.toInt() }
        track.height?.let { map["height"] = it.toInt() }
        track.codec?.let { map["codec"] = it }
        track.isDefault?.let { map["isDefault"] = it }
        return map
    }

    private fun convertMapToVideoMetadata(map: Map<String, Any?>): VideoMetadataMessage {
        return VideoMetadataMessage(
            duration = (map["duration"] as? Number)?.toLong(),
            width = (map["width"] as? Number)?.toLong(),
            height = (map["height"] as? Number)?.toLong(),
            videoCodec = map["videoCodec"] as? String,
            audioCodec = map["audioCodec"] as? String,
            bitrate = (map["bitrate"] as? Number)?.toLong(),
            frameRate = (map["frameRate"] as? Number)?.toDouble()
        )
    }

    private fun convertMediaMetadataToMap(metadata: MediaMetadataMessage): Map<String, Any> {
        val map = mutableMapOf<String, Any>()
        metadata.title?.let { map["title"] = it }
        metadata.artist?.let { map["artist"] = it }
        metadata.album?.let { map["album"] = it }
        metadata.artworkUrl?.let { map["artworkUrl"] = it }
        metadata.duration?.let { map["duration"] = it.toInt() }
        return map
    }

    private fun convertMapToCastDevice(map: Map<String, Any>): CastDeviceMessage {
        val typeString = map["type"] as? String ?: "unknown"
        val type = when (typeString.lowercase()) {
            "airplay" -> CastDeviceTypeEnum.AIR_PLAY
            "chromecast" -> CastDeviceTypeEnum.CHROMECAST
            "webremoteplayback" -> CastDeviceTypeEnum.WEB_REMOTE_PLAYBACK
            else -> CastDeviceTypeEnum.UNKNOWN
        }

        return CastDeviceMessage(
            id = map["id"] as String,
            name = map["name"] as String,
            type = type
        )
    }

    private fun convertCastDeviceToMap(device: CastDeviceMessage): Map<String, Any> {
        return mapOf(
            "id" to device.id,
            "name" to device.name,
            "type" to when (device.type) {
                CastDeviceTypeEnum.AIR_PLAY -> "airPlay"
                CastDeviceTypeEnum.CHROMECAST -> "chromecast"
                CastDeviceTypeEnum.WEB_REMOTE_PLAYBACK -> "webRemotePlayback"
                CastDeviceTypeEnum.UNKNOWN -> "unknown"
            }
        )
    }
}
