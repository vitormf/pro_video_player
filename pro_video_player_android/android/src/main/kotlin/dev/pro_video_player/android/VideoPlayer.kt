package dev.pro_video_player.android

import android.app.Activity
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import dev.pro_video_player.android.ProVideoPlayerPlugin.Companion.verboseLog
import android.util.Rational
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Timeline
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.upstream.DefaultBandwidthMeter
import androidx.media3.session.MediaSession
import androidx.media3.ui.PlayerView
import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastState
import com.google.android.gms.cast.framework.CastStateListener
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

@OptIn(UnstableApi::class)
class VideoPlayer(
    private val playerId: Int,
    private val context: Context,
    messenger: BinaryMessenger,
    source: Map<String, Any>,
    options: Map<String, Any>,
    private val exoPlayerFactory: IExoPlayerFactory = DefaultExoPlayerFactory()
) : EventChannel.StreamHandler, IVideoPlayer {

    private var exoPlayer: ExoPlayer? = null
    private var eventSink: EventChannel.EventSink? = null
    private val eventChannel: EventChannel
    private val mainHandler = Handler(Looper.getMainLooper())
    private var playerView: PlayerView? = null
    private var mediaSession: MediaSession? = null

    // Configuration options
    private var allowPip: Boolean = true
    private var autoEnterPipOnBackground: Boolean = false
    private var subtitlesEnabled: Boolean = true
    private var showSubtitlesByDefault: Boolean = false
    private var preferredSubtitleLanguage: String? = null
    private var allowBackgroundPlayback: Boolean = false
    private var preventScreenSleep: Boolean = true
    private var isFullscreen: Boolean = false
    private var renderEmbeddedSubtitlesInFlutter: Boolean = false
    private var subtitleRenderMode: String = "auto"

    // Store initial options for later use (e.g., scaling mode)
    private var initialOptions: Map<String, Any> = options

    // PiP state tracking
    private var isPipModeActive: Boolean = false
    private var pipActivity: Activity? = null

    // Playback and background state for wake lock management
    private var isPlaying: Boolean = false
    private var isInBackground: Boolean = false

    // Track selection state
    private var hasManuallySelectedSubtitle: Boolean = false
    private var isInitialSubtitleSelection: Boolean = true

    // Video quality selection state
    private var isAutoQuality: Boolean = true
    private var currentQualityTrackId: String = "auto"

    // Position update runnable reference for cleanup
    private var positionUpdateRunnable: Runnable? = null

    // Network resilience state
    private var isBufferingDueToNetwork: Boolean = false
    private var wasPlayingBeforeStall: Boolean = false
    private var networkRetryCount: Int = 0
    private var maxNetworkRetries: Int = 3
    private var retryRunnable: Runnable? = null
    private var lastBufferingReason: String = "unknown"
    private var lastPlaybackState: Int = Player.STATE_IDLE

    // Network reachability monitoring
    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var isNetworkAvailable: Boolean = true
    private var hadNetworkError: Boolean = false

    // Cast state tracking
    private var castContext: CastContext? = null
    private var castStateListener: CastStateListener? = null
    private var sessionManagerListener: SessionManagerListener<com.google.android.gms.cast.framework.CastSession>? = null
    private var isCastingActive: Boolean = false
    private var lastCastPosition: Long = 0
    private var remoteMediaClientCallback: RemoteMediaClient.Callback? = null

    // Performance optimization: track last sent values to avoid redundant events
    private var lastSentPosition: Int = -1
    private var lastSentBufferedPosition: Int = -1

    // PiP remote actions
    private var pipActions: List<Map<String, Any>>? = null
    private var pipActionReceiver: BroadcastReceiver? = null
    private var isReceiverRegistered: Boolean = false

    // Bandwidth estimation
    private var bandwidthMeter: DefaultBandwidthMeter? = null
    private var lastSentBandwidth: Long = -1
    private var bandwidthUpdateIntervalMs: Long = 3000 // Throttle bandwidth updates to every 3 seconds
    private var lastBandwidthUpdateTime: Long = 0

    // External subtitles
    private val externalSubtitles = mutableMapOf<String, Map<String, Any?>>()
    private var nextExternalSubtitleId: Int = 0
    private var selectedExternalSubtitleId: String? = null

    init {
        eventChannel = EventChannel(
            messenger,
            "dev.pro_video_player.pro_video_player_android/events/$playerId"
        )
        eventChannel.setStreamHandler(this)

        setupNetworkMonitor()
        setupCastContext()

        mainHandler.post {
            setupPlayer(source, options)
        }
    }

    /**
     * Sets up CastContext for Chromecast integration.
     * Registers listeners for cast state changes and session events.
     */
    private fun setupCastContext() {
        try {
            castContext = CastContext.getSharedInstance(context)

            // Set up cast state listener
            castStateListener = CastStateListener { state ->
                mainHandler.post {
                    val stateString = when (state) {
                        CastState.NO_DEVICES_AVAILABLE -> "noDevices"
                        CastState.NOT_CONNECTED -> "notConnected"
                        CastState.CONNECTING -> "connecting"
                        CastState.CONNECTED -> "connected"
                        else -> "notConnected"
                    }

                    val device = getCurrentCastDeviceInternal()
                    val eventData = mutableMapOf<String, Any?>(
                        "type" to "castStateChanged",
                        "state" to stateString
                    )
                    if (device != null) {
                        eventData["device"] = device
                    }
                    sendEvent(eventData)
                }
            }
            castContext?.addCastStateListener(castStateListener!!)

            // Set up session manager listener for more detailed session events
            sessionManagerListener = object : SessionManagerListener<com.google.android.gms.cast.framework.CastSession> {
                override fun onSessionStarting(session: com.google.android.gms.cast.framework.CastSession) {
                    sendCastStateEvent("connecting", session.castDevice)
                }

                override fun onSessionStarted(session: com.google.android.gms.cast.framework.CastSession, sessionId: String) {
                    verboseLog("onSessionStarted: sessionId=$sessionId, device=${session.castDevice?.friendlyName}", TAG)
                    sendCastStateEvent("connected", session.castDevice)
                    // Auto-load current media to the cast device
                    loadMediaToCastSession(session)
                }

                override fun onSessionStartFailed(session: com.google.android.gms.cast.framework.CastSession, error: Int) {
                    val errorMessage = when (error) {
                        com.google.android.gms.common.api.CommonStatusCodes.TIMEOUT -> "Connection timeout"
                        com.google.android.gms.common.api.CommonStatusCodes.NETWORK_ERROR -> "Network error"
                        com.google.android.gms.common.api.CommonStatusCodes.INTERNAL_ERROR -> "Internal error"
                        2100 -> "Application not found on device"
                        2151 -> "No answer from device"
                        2152 -> "Invalid request"
                        2154 -> "Session error"
                        2200 -> "Session already started"
                        2252 -> "Session start failed (device may be busy, network issue, or receiver app unavailable)"
                        else -> "Unknown error"
                    }
                    verboseLog("onSessionStartFailed: error=$error ($errorMessage), device=${session.castDevice?.friendlyName}", TAG)
                    sendCastStateEvent("notConnected", null)
                    sendEvent(mapOf(
                        "type" to "error",
                        "message" to "Cast session failed: $errorMessage (code: $error)",
                        "code" to "cast_session_failed"
                    ))
                }

                override fun onSessionEnding(session: com.google.android.gms.cast.framework.CastSession) {
                    // Get the current position from the cast device before session ends
                    session.remoteMediaClient?.let { client ->
                        lastCastPosition = client.approximateStreamPosition
                        verboseLog("onSessionEnding: Captured cast position: $lastCastPosition", TAG)
                    }
                    sendCastStateEvent("disconnecting", session.castDevice)
                }

                override fun onSessionEnded(session: com.google.android.gms.cast.framework.CastSession, error: Int) {
                    verboseLog("onSessionEnded: error=$error, lastCastPosition=$lastCastPosition", TAG)

                    // Unregister remote media client callback
                    unregisterRemoteMediaClientCallback(session)

                    // Restore local playback at the cast position
                    mainHandler.post {
                        if (isCastingActive && lastCastPosition > 0) {
                            verboseLog("onSessionEnded: Restoring local playback at position $lastCastPosition", TAG)
                            exoPlayer?.seekTo(lastCastPosition)
                            // Show the player view
                            playerView?.visibility = View.VISIBLE
                        }
                        isCastingActive = false
                        lastCastPosition = 0
                    }
                    sendCastStateEvent("notConnected", null)
                }

                override fun onSessionResuming(session: com.google.android.gms.cast.framework.CastSession, sessionId: String) {
                    sendCastStateEvent("connecting", session.castDevice)
                }

                override fun onSessionResumed(session: com.google.android.gms.cast.framework.CastSession, wasSuspended: Boolean) {
                    sendCastStateEvent("connected", session.castDevice)
                    // Auto-load current media to the cast device when resuming
                    if (!wasSuspended) {
                        loadMediaToCastSession(session)
                    }
                }

                override fun onSessionResumeFailed(session: com.google.android.gms.cast.framework.CastSession, error: Int) {
                    sendCastStateEvent("notConnected", null)
                }

                override fun onSessionSuspended(session: com.google.android.gms.cast.framework.CastSession, reason: Int) {
                    // Session is suspended but not ended
                }
            }
            castContext?.sessionManager?.addSessionManagerListener(
                sessionManagerListener!!,
                com.google.android.gms.cast.framework.CastSession::class.java
            )

        } catch (e: Exception) {
            // Cast SDK may not be available on all devices
            verboseLog("Failed to initialize CastContext: ${e.message}", TAG)
            castContext = null
        }
    }

    /**
     * Sends a cast state changed event to Flutter.
     */
    private fun sendCastStateEvent(state: String, device: CastDevice?) {
        mainHandler.post {
            val eventData = mutableMapOf<String, Any?>(
                "type" to "castStateChanged",
                "state" to state
            )
            if (device != null) {
                eventData["device"] = mapOf(
                    "id" to device.deviceId,
                    "name" to device.friendlyName,
                    "type" to "chromecast"
                )
            }
            sendEvent(eventData)
        }
    }

    /**
     * Gets the current cast device info if connected.
     */
    private fun getCurrentCastDeviceInternal(): Map<String, Any>? {
        val session = castContext?.sessionManager?.currentCastSession ?: return null
        val device = session.castDevice ?: return null
        return mapOf(
            "id" to device.deviceId,
            "name" to device.friendlyName,
            "type" to "chromecast"
        )
    }

    /**
     * Sets up network connectivity monitoring using ConnectivityManager.
     */
    private fun setupNetworkMonitor() {
        connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager

        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                val wasAvailable = isNetworkAvailable
                isNetworkAvailable = true

                mainHandler.post {
                    sendEvent(mapOf("type" to "networkStateChanged", "isConnected" to true))

                    // If network was restored and we had a network error, trigger recovery
                    if (!wasAvailable && hadNetworkError) {
                        attemptNetworkRecovery()
                    }
                }
            }

            override fun onLost(network: Network) {
                isNetworkAvailable = false
                mainHandler.post {
                    sendEvent(mapOf("type" to "networkStateChanged", "isConnected" to false))
                }
            }

            override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
                val hasInternet = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                val wasAvailable = isNetworkAvailable
                isNetworkAvailable = hasInternet

                mainHandler.post {
                    sendEvent(mapOf("type" to "networkStateChanged", "isConnected" to hasInternet))

                    // If network was restored and we had a network error, trigger recovery
                    if (!wasAvailable && hasInternet && hadNetworkError) {
                        attemptNetworkRecovery()
                    }
                }
            }
        }

        val networkRequest = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        try {
            connectivityManager?.registerNetworkCallback(networkRequest, networkCallback!!)
        } catch (e: Exception) {
            verboseLog("Failed to register network callback: ${e.message}", TAG)
        }
    }

    private fun setupPlayer(source: Map<String, Any>, options: Map<String, Any>) {
        val type = source["type"] as? String ?: return
        val headers = source["headers"] as? Map<*, *>

        // Store configuration options
        allowPip = options["allowPip"] as? Boolean ?: true
        autoEnterPipOnBackground = options["autoEnterPipOnBackground"] as? Boolean ?: false
        subtitlesEnabled = options["subtitlesEnabled"] as? Boolean ?: true
        showSubtitlesByDefault = options["showSubtitlesByDefault"] as? Boolean ?: false
        preferredSubtitleLanguage = options["preferredSubtitleLanguage"] as? String
        allowBackgroundPlayback = options["allowBackgroundPlayback"] as? Boolean ?: false
        preventScreenSleep = options["preventScreenSleep"] as? Boolean ?: true
        renderEmbeddedSubtitlesInFlutter = options["renderEmbeddedSubtitlesInFlutter"] as? Boolean ?: false

        // Support backward compatibility: if deprecated flag is true, override subtitle render mode
        if (renderEmbeddedSubtitlesInFlutter) {
            subtitleRenderMode = "flutter"
        }

        val uri: Uri? = when (type) {
            "network" -> {
                val url = source["url"] as? String
                url?.let { Uri.parse(it) }
            }
            "file" -> {
                val path = source["path"] as? String
                path?.let { Uri.parse(it) }
            }
            "asset" -> {
                val assetPath = source["assetPath"] as? String
                assetPath?.let { Uri.parse("asset:///$it") }
            }
            else -> null
        }

        if (uri == null) {
            sendError("Invalid video source", "INVALID_SOURCE")
            return
        }

        // Build data source factory with headers if needed
        val dataSourceFactory = if (headers != null && headers.isNotEmpty()) {
            val httpDataSourceFactory = DefaultHttpDataSource.Factory()
            val headerMap = headers.mapKeys { it.key.toString() }
                .mapValues { it.value.toString() }
            httpDataSourceFactory.setDefaultRequestProperties(headerMap)
            DefaultDataSource.Factory(context, httpDataSourceFactory)
        } else {
            DefaultDataSource.Factory(context)
        }

        val mediaSourceFactory = DefaultMediaSourceFactory(dataSourceFactory)

        // Create load control based on buffering tier
        val bufferingTier = options["bufferingTier"] as? String
        val loadControl = BufferingConfig.createLoadControl(bufferingTier)

        // Create bandwidth meter for bandwidth estimation
        bandwidthMeter = DefaultBandwidthMeter.Builder(context)
            .setResetOnNetworkTypeChange(true)
            .build()

        exoPlayer = exoPlayerFactory.createBuilder(context)
            .setBandwidthMeter(bandwidthMeter!!)
            .setMediaSourceFactory(mediaSourceFactory)
            .setLoadControl(loadControl)
            .build()
            .apply {
                // Apply options
                val volume = (options["volume"] as? Double)?.toFloat() ?: 1f
                this.volume = volume

                val looping = options["looping"] as? Boolean ?: false
                repeatMode = if (looping) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF

                // Apply ABR (Adaptive Bitrate) configuration
                val abrMode = options["abrMode"] as? String ?: "auto"
                val minBitrate = (options["minBitrate"] as? Number)?.toInt()
                val maxBitrate = (options["maxBitrate"] as? Number)?.toInt()

                // Configure track selection parameters for ABR
                if (abrMode == "manual" || minBitrate != null || maxBitrate != null) {
                    val paramsBuilder = trackSelectionParameters.buildUpon()

                    // Apply bitrate constraints
                    if (minBitrate != null && minBitrate > 0) {
                        paramsBuilder.setMinVideoBitrate(minBitrate)
                        verboseLog("setupPlayer: Set min video bitrate to $minBitrate bps", TAG)
                    }
                    if (maxBitrate != null && maxBitrate > 0) {
                        paramsBuilder.setMaxVideoBitrate(maxBitrate)
                        verboseLog("setupPlayer: Set max video bitrate to $maxBitrate bps", TAG)
                    }

                    // In manual mode, we don't auto-switch (handled by isAutoQuality flag)
                    // The actual quality lock happens when user calls setVideoQuality()
                    if (abrMode == "manual") {
                        isAutoQuality = false
                        verboseLog("setupPlayer: ABR mode set to manual", TAG)
                    }

                    trackSelectionParameters = paramsBuilder.build()
                }

                // Add listener
                addListener(object : Player.Listener {
                    override fun onPlaybackStateChanged(playbackState: Int) {
                        handlePlaybackStateChanged(playbackState)
                    }

                    override fun onIsPlayingChanged(isPlaying: Boolean) {
                        handleIsPlayingChanged(isPlaying)
                    }

                    override fun onVideoSizeChanged(videoSize: VideoSize) {
                        sendEvent(mapOf(
                            "type" to "videoSizeChanged",
                            "width" to videoSize.width,
                            "height" to videoSize.height
                        ))
                    }

                    override fun onTracksChanged(tracks: Tracks) {
                        // Notify about subtitle tracks if subtitles are enabled
                        if (subtitlesEnabled) {
                            notifySubtitleTracks(tracks)
                        }
                        // Notify about audio tracks
                        notifyAudioTracks(tracks)
                        // Notify about video quality tracks
                        notifyVideoQualityTracks(tracks)
                        // Notify about chapters (if available)
                        notifyChapters()
                    }

                    override fun onMediaMetadataChanged(mediaMetadata: MediaMetadata) {
                        // Extract and send metadata (title) to match iOS behavior
                        val title = mediaMetadata.title?.toString()
                            ?: mediaMetadata.displayTitle?.toString()
                        if (title != null) {
                            sendEvent(mapOf("type" to "metadataChanged", "title" to title))
                        }
                    }

                    override fun onPlayerError(error: PlaybackException) {
                        handlePlayerError(error)
                    }

                    override fun onCues(cueGroup: androidx.media3.common.text.CueGroup) {
                        // Only send embedded subtitle cues if Flutter rendering is enabled
                        if (subtitleRenderMode != "flutter") return

                        // Extract text from all cues
                        val combinedText = cueGroup.cues.mapNotNull { cue ->
                            cue.text?.toString()
                        }.joinToString("\n")

                        // Calculate timing
                        val startMs = cueGroup.presentationTimeUs / 1000
                        // ExoPlayer doesn't provide end time directly, estimate 5 seconds
                        // This will be updated when the next cue arrives or cleared when empty
                        val endMs = startMs + 5000

                        // Send the cue event (empty text = no subtitle at current position)
                        sendEvent(mapOf(
                            "type" to "embeddedSubtitleCue",
                            "text" to combinedText.ifEmpty { null },
                            "startMs" to startMs,
                            "endMs" to endMs,
                            "trackId" to null
                        ))
                    }
                })

                // Prepare the media
                val mediaItem = MediaItem.fromUri(uri)
                setMediaItem(mediaItem)
                prepare()

                // Start position updates
                startPositionUpdates()
            }

        // Set up MediaSession for Bluetooth/external controls
        // This works even when background playback is disabled
        exoPlayer?.let { player ->
            mediaSession = MediaSession.Builder(context, player)
                .setId("pro_video_player_$playerId")
                .build()
            verboseLog("MediaSession created for Bluetooth controls", TAG)
        }

        // Register for background playback if enabled
        if (allowBackgroundPlayback) {
            exoPlayer?.let { player ->
                MediaPlaybackService.registerPlayer(playerId, player)
            }
        }

        sendEvent(mapOf("type" to "playbackStateChanged", "state" to "ready"))
    }

    private fun notifySubtitleTracks(tracks: Tracks) {
        val subtitleTracks = mutableListOf<Map<String, Any?>>()
        var trackCounter = 0

        verboseLog("notifySubtitleTracks: Processing ${tracks.groups.size} track groups", TAG)
        for ((groupIndex, group) in tracks.groups.withIndex()) {
            if (group.type == C.TRACK_TYPE_TEXT) {
                verboseLog("notifySubtitleTracks: Found text track group $groupIndex with ${group.length} tracks", TAG)
                for (i in 0 until group.length) {
                    val format = group.getTrackFormat(i)
                    val language = format.language
                    // Send empty label - Dart will generate display name from language code
                    // using VideoPlayerConstants.getLanguageDisplayName()
                    val track = mapOf(
                        "id" to "$groupIndex:$i",
                        "label" to "",  // Let Dart generate label from language
                        "language" to language,
                        "isDefault" to (trackCounter == 0)
                    )
                    verboseLog("notifySubtitleTracks: Track $groupIndex:$i (language: $language)", TAG)
                    subtitleTracks.add(track)
                    trackCounter++
                }
            }
        }

        if (subtitleTracks.isNotEmpty()) {
            verboseLog("notifySubtitleTracks: Sending ${subtitleTracks.size} subtitle tracks to Flutter", TAG)
            sendEvent(mapOf("type" to "subtitleTracksChanged", "tracks" to subtitleTracks))

            // Auto-select subtitle only on initial load if configured, and user hasn't manually selected one
            if (showSubtitlesByDefault && isInitialSubtitleSelection && !hasManuallySelectedSubtitle) {
                verboseLog("notifySubtitleTracks: Auto-selecting subtitle (initial load)", TAG)
                autoSelectSubtitle(tracks)
                isInitialSubtitleSelection = false
            } else {
                verboseLog("notifySubtitleTracks: Skipping auto-selection (manualSelection=$hasManuallySelectedSubtitle, isInitial=$isInitialSubtitleSelection)", TAG)
                // Mark initial selection as complete after first notification
                isInitialSubtitleSelection = false
            }
        } else {
            verboseLog("notifySubtitleTracks: No subtitle tracks found", TAG)
        }
    }

    private fun notifyAudioTracks(tracks: Tracks) {
        val audioTracks = mutableListOf<Map<String, Any?>>()
        var trackCounter = 0

        for ((groupIndex, group) in tracks.groups.withIndex()) {
            if (group.type == C.TRACK_TYPE_AUDIO) {
                for (i in 0 until group.length) {
                    val format = group.getTrackFormat(i)
                    val language = format.language
                    // Send empty label - Dart will generate display name from language code
                    // using VideoPlayerConstants.getLanguageDisplayName()
                    val track = mapOf(
                        "id" to "$groupIndex:$i",
                        "label" to "",  // Let Dart generate label from language
                        "language" to language,
                        "isDefault" to (trackCounter == 0)
                    )
                    audioTracks.add(track)
                    trackCounter++
                }
            }
        }

        if (audioTracks.isNotEmpty()) {
            sendEvent(mapOf("type" to "audioTracksChanged", "tracks" to audioTracks))
        }
    }

    private fun notifyVideoQualityTracks(tracks: Tracks) {
        val qualityTracks = mutableListOf<Map<String, Any?>>()

        for ((groupIndex, group) in tracks.groups.withIndex()) {
            if (group.type == C.TRACK_TYPE_VIDEO) {
                for (i in 0 until group.length) {
                    val format = group.getTrackFormat(i)
                    // Only include tracks with valid dimensions and bitrate
                    if (format.width > 0 && format.height > 0 && format.bitrate > 0) {
                        val track = mapOf(
                            "id" to "$groupIndex:$i",
                            "bitrate" to format.bitrate,
                            "width" to format.width,
                            "height" to format.height,
                            "frameRate" to (format.frameRate.takeIf { it > 0 }),
                            "label" to "",  // Let Dart generate label
                            "isDefault" to (qualityTracks.isEmpty())
                        )
                        qualityTracks.add(track)
                    }
                }
            }
        }

        if (qualityTracks.isNotEmpty()) {
            verboseLog("notifyVideoQualityTracks: Sending ${qualityTracks.size} quality tracks to Flutter", TAG)
            sendEvent(mapOf("type" to "videoQualityTracksChanged", "tracks" to qualityTracks))
        }
    }

    /**
     * Extracts chapter information from the media and sends to Flutter.
     *
     * Chapters can be extracted from:
     * - MP4/MKV files with embedded chapter metadata
     * - HLS/DASH manifests with chapter information
     * - MediaMetadata with chapter entries (Media3)
     */
    private fun notifyChapters() {
        val player = exoPlayer ?: return

        // Try to get chapters from the media metadata
        val mediaMetadata = player.mediaMetadata
        val chapters = mutableListOf<Map<String, Any?>>()

        // ExoPlayer/Media3 doesn't have direct chapter API like AVFoundation
        // Chapters in MP4 files are typically stored in the 'chpl' or 'CHAP' atoms
        // For HLS, they might be in EXT-X-DATERANGE tags

        // For now, we check if the timeline has multiple windows (which could indicate chapters)
        // and extract chapter-like information from the timeline
        val timeline = player.currentTimeline
        if (!timeline.isEmpty) {
            val windowCount = timeline.windowCount

            // If there are multiple windows, treat each as a chapter
            // This is common in HLS with discontinuities or separate segments
            if (windowCount > 1) {
                val window = Timeline.Window()
                for (i in 0 until windowCount) {
                    timeline.getWindow(i, window)
                    val startTimeMs = window.positionInFirstPeriodUs / 1000
                    val durationMs = window.durationMs
                    val endTimeMs = if (durationMs != C.TIME_UNSET) startTimeMs + durationMs else null

                    val title = window.mediaItem?.mediaMetadata?.title?.toString()
                        ?: window.mediaItem?.mediaMetadata?.displayTitle?.toString()
                        ?: "Chapter ${i + 1}"

                    val chapter = mapOf(
                        "id" to "chap-$i",
                        "title" to title,
                        "startTimeMs" to startTimeMs.toInt(),
                        "endTimeMs" to endTimeMs?.toInt(),
                        "thumbnailUrl" to null
                    )
                    chapters.add(chapter)
                }
            }
        }

        if (chapters.isNotEmpty()) {
            verboseLog("notifyChapters: Sending ${chapters.size} chapters to Flutter", TAG)
            sendEvent(mapOf("type" to "chaptersExtracted", "chapters" to chapters))
        }
    }

    /**
     * Gets available video quality tracks.
     * Returns an empty list if quality selection is not available.
     */
    fun getVideoQualities(): List<Map<String, Any?>> {
        val player = exoPlayer ?: return emptyList()
        val qualityTracks = mutableListOf<Map<String, Any?>>()

        val tracks = player.currentTracks
        for ((groupIndex, group) in tracks.groups.withIndex()) {
            if (group.type == C.TRACK_TYPE_VIDEO) {
                for (i in 0 until group.length) {
                    val format = group.getTrackFormat(i)
                    if (format.width > 0 && format.height > 0 && format.bitrate > 0) {
                        val track = mapOf(
                            "id" to "$groupIndex:$i",
                            "bitrate" to format.bitrate,
                            "width" to format.width,
                            "height" to format.height,
                            "frameRate" to (format.frameRate.takeIf { it > 0 }),
                            "label" to "",
                            "isDefault" to (qualityTracks.isEmpty())
                        )
                        qualityTracks.add(track)
                    }
                }
            }
        }

        return qualityTracks
    }

    /**
     * Sets the video quality track.
     * Pass a track with id "auto" to enable automatic quality selection.
     */
    fun setVideoQuality(track: Map<String, Any>?): Boolean {
        val player = exoPlayer ?: return false

        // Check if auto quality is requested
        val trackId = track?.get("id") as? String
        if (trackId == null || trackId == "auto") {
            // Enable automatic quality selection by clearing video track overrides
            isAutoQuality = true
            currentQualityTrackId = "auto"
            player.trackSelectionParameters = player.trackSelectionParameters
                .buildUpon()
                .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                .build()

            verboseLog("setVideoQuality: Enabled automatic quality selection", TAG)
            sendEvent(mapOf(
                "type" to "selectedQualityChanged",
                "track" to mapOf(
                    "id" to "auto",
                    "bitrate" to 0,
                    "width" to 0,
                    "height" to 0,
                    "label" to "Auto"
                ),
                "isAutoSwitch" to false
            ))
            return true
        }

        // Parse track ID (format: "groupIndex:trackIndex")
        val parsed = VideoFormatUtils.parseTrackId(trackId)
        if (parsed == null) {
            verboseLog("setVideoQuality: Invalid track ID format: $trackId", TAG)
            return false
        }

        val groupIndex = parsed.first
        val trackIndex = parsed.second

        val tracks = player.currentTracks
        if (groupIndex < tracks.groups.size) {
            val group = tracks.groups[groupIndex]
            if (group.type == C.TRACK_TYPE_VIDEO && trackIndex < group.length) {
                val override = TrackSelectionOverride(group.mediaTrackGroup, trackIndex)
                player.trackSelectionParameters = player.trackSelectionParameters
                    .buildUpon()
                    .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                    .setOverrideForType(override)
                    .build()

                isAutoQuality = false
                currentQualityTrackId = trackId
                verboseLog("setVideoQuality: Selected quality track $trackId", TAG)
                sendEvent(mapOf(
                    "type" to "selectedQualityChanged",
                    "track" to track,
                    "isAutoSwitch" to false
                ))
                return true
            }
        }

        verboseLog("setVideoQuality: Track not found: $trackId", TAG)
        return false
    }

    /**
     * Gets the currently selected video quality track.
     */
    fun getCurrentVideoQuality(): Map<String, Any?> {
        if (isAutoQuality) {
            return mapOf(
                "id" to "auto",
                "bitrate" to 0,
                "width" to 0,
                "height" to 0,
                "label" to "Auto"
            )
        }

        val player = exoPlayer ?: return mapOf(
            "id" to "auto",
            "bitrate" to 0,
            "width" to 0,
            "height" to 0,
            "label" to "Auto"
        )

        // Find the currently selected video track
        val tracks = player.currentTracks
        for ((groupIndex, group) in tracks.groups.withIndex()) {
            if (group.type == C.TRACK_TYPE_VIDEO) {
                for (i in 0 until group.length) {
                    if (group.isTrackSelected(i)) {
                        val format = group.getTrackFormat(i)
                        return mapOf(
                            "id" to "$groupIndex:$i",
                            "bitrate" to format.bitrate,
                            "width" to format.width,
                            "height" to format.height,
                            "frameRate" to (format.frameRate.takeIf { it > 0 }),
                            "label" to "",
                            "isDefault" to false
                        )
                    }
                }
            }
        }

        return mapOf(
            "id" to "auto",
            "bitrate" to 0,
            "width" to 0,
            "height" to 0,
            "label" to "Auto"
        )
    }

    /**
     * Returns whether manual quality selection is supported for current content.
     */
    fun isQualitySelectionSupported(): Boolean {
        val qualities = getVideoQualities()
        return qualities.size > 1
    }

    private fun autoSelectSubtitle(tracks: Tracks) {
        val player = exoPlayer ?: return

        for (group in tracks.groups) {
            if (group.type == C.TRACK_TYPE_TEXT) {
                var selectedIndex = -1

                // Try to find track matching preferred language
                if (preferredSubtitleLanguage != null) {
                    for (i in 0 until group.length) {
                        val format = group.getTrackFormat(i)
                        if (format.language == preferredSubtitleLanguage) {
                            selectedIndex = i
                            break
                        }
                    }
                }

                // Fall back to first track
                if (selectedIndex == -1 && group.length > 0) {
                    selectedIndex = 0
                }

                if (selectedIndex >= 0) {
                    val override = TrackSelectionOverride(group.mediaTrackGroup, selectedIndex)
                    player.trackSelectionParameters = player.trackSelectionParameters
                        .buildUpon()
                        .setOverrideForType(override)
                        .build()
                }
                break
            }
        }
    }

    private fun startPositionUpdates() {
        positionUpdateRunnable = object : Runnable {
            override fun run() {
                exoPlayer?.let { player ->
                    if (player.isPlaying) {
                        val currentPosition = player.currentPosition.toInt()
                        val bufferedPosition = player.bufferedPosition.toInt()

                        // Only send position if changed by at least 100ms (deduplication)
                        if (VideoFormatUtils.shouldUpdatePosition(currentPosition, lastSentPosition)) {
                            lastSentPosition = currentPosition
                            sendEvent(mapOf(
                                "type" to "positionChanged",
                                "position" to currentPosition
                            ))
                        }

                        // Only send buffered position if increased (deduplication)
                        if (bufferedPosition > lastSentBufferedPosition) {
                            lastSentBufferedPosition = bufferedPosition
                            sendEvent(mapOf(
                                "type" to "bufferedPositionChanged",
                                "bufferedPosition" to bufferedPosition
                            ))
                        }
                    }

                    // Check if PiP mode has ended (user expanded or dismissed PiP window)
                    checkPipStateChanged()

                    // Check bandwidth estimate during playback
                    checkBandwidthEstimate()

                    // Adaptive polling: 500ms when playing, 1000ms when paused
                    val interval = VideoFormatUtils.getPollingInterval(player.isPlaying)
                    mainHandler.postDelayed(this, interval)
                }
            }
        }
        mainHandler.post(positionUpdateRunnable!!)
    }

    private fun stopPositionUpdates() {
        positionUpdateRunnable?.let { mainHandler.removeCallbacks(it) }
        positionUpdateRunnable = null
    }

    // ==================== Network Resilience Handlers ====================

    /**
     * Handles playback state changes with network resilience logic.
     */
    private fun handlePlaybackStateChanged(playbackState: Int) {
        val player = exoPlayer ?: return

        when (playbackState) {
            Player.STATE_BUFFERING -> {
                // Entering buffering state
                if (!isBufferingDueToNetwork && lastPlaybackState != Player.STATE_BUFFERING) {
                    // Track if we were playing before buffering
                    if (player.playWhenReady) {
                        wasPlayingBeforeStall = true
                    }
                    isBufferingDueToNetwork = true
                    lastBufferingReason = VideoFormatUtils.getBufferingReason(lastPlaybackState)
                    sendEvent(mapOf("type" to "bufferingStarted", "reason" to lastBufferingReason))
                }
                sendEvent(mapOf("type" to "playbackStateChanged", "state" to "buffering"))
            }
            Player.STATE_READY -> {
                // Exiting buffering state
                if (isBufferingDueToNetwork) {
                    handleBufferingEnded()
                }

                val state = if (player.isPlaying) "playing" else "paused"
                sendEvent(mapOf("type" to "playbackStateChanged", "state" to state))
                sendEvent(mapOf("type" to "durationChanged", "duration" to player.duration.toInt()))

                // Extract and send video metadata when player is ready
                extractAndSendVideoMetadata()
            }
            Player.STATE_ENDED -> {
                if (isBufferingDueToNetwork) {
                    isBufferingDueToNetwork = false
                    sendEvent(mapOf("type" to "bufferingEnded"))
                }
                sendEvent(mapOf("type" to "playbackStateChanged", "state" to "completed"))
                sendEvent(mapOf("type" to "playbackCompleted"))
            }
            Player.STATE_IDLE -> {
                sendEvent(mapOf("type" to "playbackStateChanged", "state" to "ready"))
            }
        }

        lastPlaybackState = playbackState
    }

    /**
     * Handles isPlaying state changes.
     */
    private fun handleIsPlayingChanged(isPlaying: Boolean) {
        // Only send state change if not currently buffering
        if (!isBufferingDueToNetwork) {
            val state = if (isPlaying) "playing" else "paused"
            sendEvent(mapOf("type" to "playbackStateChanged", "state" to state))
        }
    }

    /**
     * Handles player errors with network resilience logic.
     */
    private fun handlePlayerError(error: PlaybackException) {
        val isNetworkError = VideoFormatUtils.isNetworkErrorCode(error.errorCode)

        if (isNetworkError) {
            // Mark that we had a network error for network restoration recovery
            hadNetworkError = true

            // Don't retry from native - let Dart handle retry logic for consistency
            sendEvent(mapOf(
                "type" to "networkError",
                "message" to (error.message ?: "Network error"),
                "willRetry" to false,
                "retryAttempt" to 0,
                "maxRetries" to maxNetworkRetries
            ))
        } else {
            // Non-network error, report immediately
            sendError(error.message ?: "Playback error", "PLAYBACK_ERROR")
        }
    }

    /**
     * Handles buffering ended state.
     */
    private fun handleBufferingEnded() {
        if (!isBufferingDueToNetwork) return

        isBufferingDueToNetwork = false
        hadNetworkError = false  // Clear network error flag on recovery
        sendEvent(mapOf("type" to "bufferingEnded"))

        // Report recovery if we had retried
        if (networkRetryCount > 0) {
            sendEvent(mapOf("type" to "playbackRecovered", "retriesUsed" to networkRetryCount))
            networkRetryCount = 0
        }
    }

    /**
     * Schedules a network retry attempt with exponential backoff.
     */
    private fun scheduleNetworkRetry() {
        // Cancel any existing retry
        retryRunnable?.let { mainHandler.removeCallbacks(it) }

        // Calculate delay with exponential backoff using utility function
        val delay = VideoFormatUtils.calculateExponentialBackoff(networkRetryCount)
        networkRetryCount++

        retryRunnable = Runnable {
            attemptNetworkRecovery()
        }
        mainHandler.postDelayed(retryRunnable!!, delay)
    }

    /**
     * Attempts to recover from a network error.
     */
    private fun attemptNetworkRecovery() {
        val player = exoPlayer ?: return

        // Try to seek to current position to trigger a reload
        val currentPosition = player.currentPosition
        player.seekTo(currentPosition)

        // Resume playback if we were playing before
        if (wasPlayingBeforeStall) {
            player.play()
        }
    }

    /**
     * Checks the current bandwidth estimate and sends an event if it has changed significantly.
     * Bandwidth updates are throttled to reduce event frequency.
     */
    private fun checkBandwidthEstimate() {
        val meter = bandwidthMeter ?: return
        val currentTime = System.currentTimeMillis()

        // Throttle updates to avoid flooding events
        if (currentTime - lastBandwidthUpdateTime < bandwidthUpdateIntervalMs) {
            return
        }

        val bitrateEstimate = meter.bitrateEstimate

        // Use utility function to check if bandwidth update should be sent
        if (!VideoFormatUtils.shouldUpdateBandwidth(bitrateEstimate, lastSentBandwidth)) {
            return
        }

        lastSentBandwidth = bitrateEstimate
        lastBandwidthUpdateTime = currentTime
        sendEvent(mapOf(
            "type" to "bandwidthEstimateChanged",
            "bandwidth" to bitrateEstimate.toInt()
        ))
    }

    /**
     * Checks if PiP mode has changed and sends an event if it has ended.
     * This detects when the user expands or dismisses the PiP window.
     */
    private fun checkPipStateChanged() {
        if (!isPipModeActive) return

        val activity = pipActivity ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val isCurrentlyInPip = activity.isInPictureInPictureMode
            if (!isCurrentlyInPip) {
                // PiP mode has ended
                isPipModeActive = false
                pipActivity = null
                sendEvent(mapOf("type" to "pipStateChanged", "isActive" to false))
            }
        }
    }

    fun getExoPlayer(): ExoPlayer? = exoPlayer

    fun getIsFullscreen(): Boolean = isFullscreen

    fun getPlayerView(): PlayerView? = playerView

    fun setPlayerView(view: PlayerView) {
        playerView = view
        view.player = exoPlayer

        // Apply scaling mode from options
        applyScalingMode(view)
    }

    /**
     * Sets the controls mode for the player view.
     *
     * @param useNativeControls true to show native ExoPlayer controls, false to hide them
     */
    fun setControlsMode(useNativeControls: Boolean) {
        mainHandler.post {
            playerView?.useController = useNativeControls
        }
    }
    
    private fun applyScalingMode(view: PlayerView) {
        val scalingMode = initialOptions["scalingMode"] as? String ?: "fit"
        view.resizeMode = when (scalingMode) {
            "fit" -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIT
            "fill" -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            "stretch" -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FILL
            else -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIT
        }
    }

    override fun play() {
        mainHandler.post {
            // If casting, control the remote device instead
            if (isCastingActive) {
                getRemoteMediaClient()?.play()
                return@post
            }

            exoPlayer?.play()
            isPlaying = true
            updateScreenSleepPrevention()

            // Start background playback service if enabled
            if (allowBackgroundPlayback) {
                startBackgroundPlaybackService()
            }
        }
    }

    private fun startBackgroundPlaybackService() {
        try {
            val serviceIntent = Intent(context, MediaPlaybackService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            sendError("Failed to start background playback service: ${e.message}", "BACKGROUND_SERVICE_ERROR")
        }
    }

    override fun pause() {
        mainHandler.post {
            // If casting, control the remote device instead
            if (isCastingActive) {
                getRemoteMediaClient()?.pause()
                return@post
            }

            exoPlayer?.pause()
            isPlaying = false
            updateScreenSleepPrevention()
        }
    }

    /**
     * Gets the RemoteMediaClient for the current Cast session.
     */
    private fun getRemoteMediaClient(): RemoteMediaClient? {
        return castContext?.sessionManager?.currentCastSession?.remoteMediaClient
    }

    override fun stop() {
        mainHandler.post {
            exoPlayer?.apply {
                pause()
                seekTo(0)
            }
            isPlaying = false
            updateScreenSleepPrevention()
        }
    }

    // Screen Sleep Prevention

    private fun enableScreenSleepPrevention() {
        if (!preventScreenSleep) return

        mainHandler.post {
            playerView?.keepScreenOn = true
        }
    }

    private fun disableScreenSleepPrevention() {
        mainHandler.post {
            playerView?.keepScreenOn = false
        }
    }

    /**
     * Smart wake lock management based on playback, PiP, and background state.
     * Wake lock is enabled when: Video is playing AND (NOT in background OR in PiP mode)
     * Wake lock is disabled when: Video is paused OR (in background AND NOT in PiP)
     */
    private fun updateScreenSleepPrevention() {
        if (!preventScreenSleep) return

        // Keep wake lock if playing and (not in background OR in PiP)
        val shouldKeepAwake = isPlaying && (!isInBackground || isPipModeActive)

        if (shouldKeepAwake) {
            enableScreenSleepPrevention()
        } else {
            disableScreenSleepPrevention()
        }
    }

    /**
     * Called when app enters background.
     * Updates wake lock based on PiP state.
     */
    fun onAppBackground() {
        isInBackground = true
        updateScreenSleepPrevention()
    }

    /**
     * Called when app returns to foreground.
     * Restores wake lock if video is playing.
     */
    fun onAppForeground() {
        isInBackground = false
        updateScreenSleepPrevention()
    }

    override fun seekTo(position: Long) {
        // Reset last sent position to ensure new position is sent after seek
        lastSentPosition = -1
        mainHandler.post {
            // If casting, control the remote device instead
            if (isCastingActive) {
                getRemoteMediaClient()?.seek(position)
                return@post
            }

            exoPlayer?.seekTo(position)
        }
    }

    override fun setPlaybackSpeed(speed: Float) {
        mainHandler.post {
            exoPlayer?.setPlaybackSpeed(speed)
            sendEvent(mapOf("type" to "playbackSpeedChanged", "speed" to speed.toDouble()))
        }
    }

    override fun setVolume(volume: Float) {
        mainHandler.post {
            exoPlayer?.volume = volume
            sendEvent(mapOf("type" to "volumeChanged", "volume" to volume.toDouble()))
        }
    }

    override fun setLooping(looping: Boolean) {
        mainHandler.post {
            exoPlayer?.repeatMode = if (looping) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
        }
    }

    override fun setScalingMode(mode: String) {
        mainHandler.post {
            playerView?.let { view ->
                applyScalingMode(view)
            }
        }
    }

    override fun setSubtitleTrack(track: Map<String, Any>?) {
        verboseLog("setSubtitleTrack called with track: $track, subtitlesEnabled: $subtitlesEnabled", TAG)

        // Mark that user has manually selected a subtitle
        hasManuallySelectedSubtitle = true

        // Return early if subtitles are disabled
        if (!subtitlesEnabled) {
            verboseLog("setSubtitleTrack: Subtitles are disabled, returning early", TAG)
            return
        }

        mainHandler.post {
            try {
                val player = exoPlayer ?: run {
                    verboseLog("setSubtitleTrack: ExoPlayer is null", TAG)
                    return@post
                }

                if (track != null) {
                    val idString = track["id"] as? String ?: run {
                        verboseLog("setSubtitleTrack: Track ID is null", TAG)
                        return@post
                    }
                    verboseLog("setSubtitleTrack: Processing track ID: $idString", TAG)

                    // Check if this is an external subtitle track
                    if (idString.startsWith("ext-")) {
                        // Verify the external track exists
                        if (!externalSubtitles.containsKey(idString)) {
                            verboseLog("setSubtitleTrack: External subtitle track not found: $idString", TAG)
                            return@post
                        }

                        // Disable embedded subtitles
                        player.trackSelectionParameters = player.trackSelectionParameters
                            .buildUpon()
                            .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                            .build()

                        // Select the external subtitle
                        selectedExternalSubtitleId = idString
                        verboseLog("setSubtitleTrack: Selected external subtitle track: $idString", TAG)
                        sendEvent(mapOf("type" to "selectedSubtitleChanged", "track" to track))
                        return@post
                    }

                    // Handle embedded subtitle track (format: "groupIndex:trackIndex")
                    val parsed = VideoFormatUtils.parseTrackId(idString) ?: run {
                        verboseLog("setSubtitleTrack: Invalid track ID format: $idString", TAG)
                        return@post
                    }

                    val groupIndex = parsed.first
                    val trackIndex = parsed.second

                    verboseLog("setSubtitleTrack: Attempting to select group $groupIndex, track $trackIndex", TAG)

                    val tracks = player.currentTracks
                    verboseLog("setSubtitleTrack: Current tracks has ${tracks.groups.size} groups", TAG)

                    if (groupIndex < tracks.groups.size) {
                        val group = tracks.groups[groupIndex]
                        verboseLog("setSubtitleTrack: Group $groupIndex type: ${group.type}, length: ${group.length}", TAG)

                        if (group.type == C.TRACK_TYPE_TEXT && trackIndex < group.length) {
                            // Clear external subtitle selection when selecting embedded
                            selectedExternalSubtitleId = null

                            val override = TrackSelectionOverride(group.mediaTrackGroup, trackIndex)
                            verboseLog("setSubtitleTrack: Applying track selection override", TAG)

                            player.trackSelectionParameters = player.trackSelectionParameters
                                .buildUpon()
                                .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                                .setOverrideForType(override)
                                .build()

                            verboseLog("setSubtitleTrack: Successfully set subtitle track $groupIndex:$trackIndex", TAG)
                            sendEvent(mapOf("type" to "selectedSubtitleChanged", "track" to track))
                        } else {
                            verboseLog("setSubtitleTrack: Group type or track index invalid. Type=${group.type}, trackIndex=$trackIndex, length=${group.length}", TAG)
                        }
                    } else {
                        verboseLog("setSubtitleTrack: Group index $groupIndex out of bounds (size: ${tracks.groups.size})", TAG)
                    }
                } else {
                    verboseLog("setSubtitleTrack: Disabling subtitles", TAG)
                    // Clear external subtitle selection
                    selectedExternalSubtitleId = null
                    // Disable subtitles
                    player.trackSelectionParameters = player.trackSelectionParameters
                        .buildUpon()
                        .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                        .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                        .build()
                    verboseLog("setSubtitleTrack: Subtitles disabled", TAG)
                    sendEvent(mapOf("type" to "selectedSubtitleChanged", "track" to null))
                }
            } catch (e: Exception) {
                verboseLog("setSubtitleTrack: Exception occurred: ${e.message}", TAG)
                sendError("Failed to set subtitle track: ${e.message}", "SUBTITLE_ERROR")
            }
        }
    }

    /**
     * Sets the subtitle rendering mode (native or flutter).
     *
     * - native: ExoPlayer renders subtitles in SubtitleView
     * - flutter: Subtitle text is extracted and streamed to Flutter for rendering
     * - auto: Defaults to native rendering
     *
     * @param mode The render mode ("native", "flutter", or "auto")
     */
    fun setSubtitleRenderMode(mode: String) {
        subtitleRenderMode = mode
        verboseLog("Subtitle render mode set to: $mode", TAG)

        // Update subtitle view visibility
        val shouldUseFlutterRendering = (mode == "flutter")
        playerView?.subtitleView?.visibility = if (shouldUseFlutterRendering) View.GONE else View.VISIBLE

        verboseLog(
            "Subtitle view ${if (shouldUseFlutterRendering) "hidden" else "shown"} for ${if (shouldUseFlutterRendering) "Flutter" else "native"} rendering",
            TAG
        )
    }

    fun setAudioTrack(track: Map<String, Any>?) {
        mainHandler.post {
            try {
                val player = exoPlayer ?: return@post

                if (track != null) {
                    val idString = track["id"] as? String ?: return@post
                    val parsed = VideoFormatUtils.parseTrackId(idString) ?: return@post

                    val groupIndex = parsed.first
                    val trackIndex = parsed.second

                    val tracks = player.currentTracks
                    if (groupIndex < tracks.groups.size) {
                        val group = tracks.groups[groupIndex]
                        if (group.type == C.TRACK_TYPE_AUDIO && trackIndex < group.length) {
                            val override = TrackSelectionOverride(group.mediaTrackGroup, trackIndex)
                            player.trackSelectionParameters = player.trackSelectionParameters
                                .buildUpon()
                                .clearOverridesOfType(C.TRACK_TYPE_AUDIO)
                                .setOverrideForType(override)
                                .build()
                            sendEvent(mapOf("type" to "selectedAudioChanged", "track" to track))
                        }
                    }
                } else {
                    // Reset to default audio track by clearing overrides
                    // This allows ExoPlayer to select the default/preferred audio track
                    player.trackSelectionParameters = player.trackSelectionParameters
                        .buildUpon()
                        .clearOverridesOfType(C.TRACK_TYPE_AUDIO)
                        .build()
                    sendEvent(mapOf("type" to "selectedAudioChanged", "track" to null))
                }
            } catch (e: Exception) {
                sendError("Failed to set audio track: ${e.message}", "AUDIO_ERROR")
            }
        }
    }

    // External Subtitles

    /**
     * Adds an external subtitle track from various sources.
     *
     * @param sourceType The type of source ("network", "file", "asset").
     * @param path The path to the subtitle (URL, file path, or asset path).
     * @param format The subtitle format (srt, vtt, ssa, ass, ttml).
     * @param label Display label for the track.
     * @param language ISO 639-1 language code.
     * @param isDefault Whether this should be the default subtitle track.
     * @param webvttContent Pre-converted WebVTT content (for native rendering mode).
     * @param callback Callback with the track dictionary if successful, null otherwise.
     */
    fun addExternalSubtitle(
        sourceType: String,
        path: String,
        format: String?,
        label: String?,
        language: String?,
        isDefault: Boolean,
        webvttContent: String?,
        callback: (Map<String, Any?>?) -> Unit
    ) {
        if (!subtitlesEnabled) {
            ProVideoPlayerPlugin.verboseLog("Subtitles disabled, cannot add external subtitle", TAG)
            mainHandler.post { callback(null) }
            return
        }

        // If WebVTT content is provided and we're in native rendering mode, use it directly
        if (webvttContent != null && subtitleRenderMode == "native") {
            ProVideoPlayerPlugin.verboseLog("Using pre-converted WebVTT content (${webvttContent.length} chars) for native rendering", TAG)
            createSubtitleTrackFromContent(webvttContent, sourceType, path, format, label, language, isDefault, callback)
            return
        }

        // Otherwise, load the subtitle file (for Flutter rendering mode or when WebVTT conversion failed)
        when (sourceType) {
            "network" -> loadNetworkSubtitle(path, format, label, language, isDefault, callback)
            "file" -> loadFileSubtitle(path, format, label, language, isDefault, callback)
            "asset" -> loadAssetSubtitle(path, format, label, language, isDefault, callback)
            else -> {
                ProVideoPlayerPlugin.verboseLog("Unknown subtitle source type: $sourceType", TAG)
                mainHandler.post { callback(null) }
            }
        }
    }

    /**
     * Loads a subtitle from a network URL.
     */
    private fun loadNetworkSubtitle(
        url: String,
        format: String?,
        label: String?,
        language: String?,
        isDefault: Boolean,
        callback: (Map<String, Any?>?) -> Unit
    ) {
        try {
            Uri.parse(url)
        } catch (e: Exception) {
            ProVideoPlayerPlugin.verboseLog("Invalid subtitle URL: $url", TAG)
            mainHandler.post { callback(null) }
            return
        }

        Thread {
            try {
                val connection = java.net.URL(url).openConnection() as java.net.HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 10000
                connection.readTimeout = 10000

                if (connection.responseCode in 200..299) {
                    val content = connection.inputStream.bufferedReader().use { it.readText() }

                    if (content.isBlank()) {
                        ProVideoPlayerPlugin.verboseLog("Empty subtitle data from URL: $url", TAG)
                        mainHandler.post { callback(null) }
                        return@Thread
                    }

                    createSubtitleTrack("network", url, format, label, language, isDefault, callback)
                } else {
                    ProVideoPlayerPlugin.verboseLog("Failed to download subtitle: HTTP ${connection.responseCode}", TAG)
                    mainHandler.post { callback(null) }
                }
            } catch (e: Exception) {
                ProVideoPlayerPlugin.verboseLog("Failed to download subtitle: ${e.message}", TAG)
                mainHandler.post { callback(null) }
            }
        }.start()
    }

    /**
     * Loads a subtitle from a local file path.
     */
    private fun loadFileSubtitle(
        filePath: String,
        format: String?,
        label: String?,
        language: String?,
        isDefault: Boolean,
        callback: (Map<String, Any?>?) -> Unit
    ) {
        Thread {
            try {
                val file = java.io.File(filePath)
                if (!file.exists()) {
                    ProVideoPlayerPlugin.verboseLog("Subtitle file not found: $filePath", TAG)
                    mainHandler.post { callback(null) }
                    return@Thread
                }

                val content = file.readText()
                if (content.isBlank()) {
                    ProVideoPlayerPlugin.verboseLog("Empty subtitle file: $filePath", TAG)
                    mainHandler.post { callback(null) }
                    return@Thread
                }

                createSubtitleTrack("file", filePath, format, label, language, isDefault, callback)
            } catch (e: Exception) {
                ProVideoPlayerPlugin.verboseLog("Failed to read subtitle file: ${e.message}", TAG)
                mainHandler.post { callback(null) }
            }
        }.start()
    }

    /**
     * Loads a subtitle from a Flutter asset.
     */
    private fun loadAssetSubtitle(
        assetPath: String,
        format: String?,
        label: String?,
        language: String?,
        isDefault: Boolean,
        callback: (Map<String, Any?>?) -> Unit
    ) {
        Thread {
            try {
                // Use FlutterLoader to get the correct asset key
                val flutterLoader = io.flutter.FlutterInjector.instance().flutterLoader()
                val resolvedPath = flutterLoader.getLookupKeyForAsset(assetPath)

                val content = context.assets.open(resolvedPath).bufferedReader().use { it.readText() }

                if (content.isBlank()) {
                    ProVideoPlayerPlugin.verboseLog("Empty subtitle asset: $assetPath", TAG)
                    mainHandler.post { callback(null) }
                    return@Thread
                }

                createSubtitleTrack("asset", assetPath, format, label, language, isDefault, callback)
            } catch (e: Exception) {
                ProVideoPlayerPlugin.verboseLog("Failed to read subtitle asset: ${e.message}", TAG)
                mainHandler.post { callback(null) }
            }
        }.start()
    }

    /**
     * Creates and registers a subtitle track after validation.
     */
    private fun createSubtitleTrack(
        sourceType: String,
        path: String,
        format: String?,
        label: String?,
        language: String?,
        isDefault: Boolean,
        callback: (Map<String, Any?>?) -> Unit
    ) {
        val trackId = "ext-$nextExternalSubtitleId"
        nextExternalSubtitleId++

        val track = mapOf<String, Any?>(
            "id" to trackId,
            "sourceType" to sourceType,
            "path" to path,
            "format" to (format ?: detectSubtitleFormat(path)),
            "label" to (label ?: "External"),
            "language" to language,
            "isDefault" to isDefault
        )

        mainHandler.post {
            externalSubtitles[trackId] = track
            ProVideoPlayerPlugin.verboseLog("Added external subtitle track: $trackId ($sourceType) from $path", TAG)

            notifySubtitleTracksWithExternal()
            callback(track)
        }
    }

    /**
     * Creates and registers a subtitle track from pre-loaded WebVTT content.
     *
     * This is used when Dart provides pre-converted WebVTT content for native rendering mode,
     * avoiding the need to download/load the subtitle file again.
     */
    private fun createSubtitleTrackFromContent(
        webvttContent: String,
        sourceType: String,
        path: String,
        format: String?,
        label: String?,
        language: String?,
        isDefault: Boolean,
        callback: (Map<String, Any?>?) -> Unit
    ) {
        val trackId = "ext-$nextExternalSubtitleId"
        nextExternalSubtitleId++

        val track = mapOf<String, Any?>(
            "id" to trackId,
            "sourceType" to sourceType,
            "path" to path,
            "format" to (format ?: detectSubtitleFormat(path)),
            "label" to (label ?: "External"),
            "language" to language,
            "isDefault" to isDefault
        )

        mainHandler.post {
            externalSubtitles[trackId] = track
            ProVideoPlayerPlugin.verboseLog("Added external subtitle track from WebVTT content: $trackId ($sourceType)", TAG)

            notifySubtitleTracksWithExternal()
            callback(track)
        }
    }

    /**
     * Removes an external subtitle track.
     *
     * @param trackId The ID of the external subtitle track to remove.
     * @return true if the track was removed, false if not found.
     */
    fun removeExternalSubtitle(trackId: String): Boolean {
        val removed = externalSubtitles.remove(trackId) != null
        if (removed) {
            ProVideoPlayerPlugin.verboseLog("Removed external subtitle track: $trackId", TAG)
            notifySubtitleTracksWithExternal()
        } else {
            ProVideoPlayerPlugin.verboseLog("External subtitle track not found: $trackId", TAG)
        }
        return removed
    }

    /**
     * Gets all external subtitle tracks.
     *
     * @return List of external subtitle track dictionaries.
     */
    fun getExternalSubtitles(): List<Map<String, Any?>> {
        return externalSubtitles.values.toList()
    }

    /**
     * Detects the subtitle format from the URL extension.
     * Delegates to VideoFormatUtils for testability.
     */
    private fun detectSubtitleFormat(url: String): String {
        return VideoFormatUtils.detectSubtitleFormat(url)
    }

    /**
     * Notifies about available subtitle tracks including external ones.
     */
    private fun notifySubtitleTracksWithExternal() {
        val allTracks = mutableListOf<Map<String, Any?>>()

        // Add embedded tracks from ExoPlayer
        exoPlayer?.let { player ->
            val tracks = player.currentTracks
            for ((groupIndex, group) in tracks.groups.withIndex()) {
                if (group.type == C.TRACK_TYPE_TEXT) {
                    for (trackIndex in 0 until group.length) {
                        val format = group.getTrackFormat(trackIndex)
                        val id = "$groupIndex:$trackIndex"
                        val label = format.label ?: format.language ?: "Track ${trackIndex + 1}"
                        val language = format.language

                        allTracks.add(mapOf(
                            "id" to id,
                            "label" to label,
                            "language" to language,
                            "isDefault" to (trackIndex == 0)
                        ))
                    }
                }
            }
        }

        // Add external tracks
        allTracks.addAll(externalSubtitles.values)

        sendEvent(mapOf(
            "type" to "subtitleTracksChanged",
            "tracks" to allTracks
        ))
    }

    override fun getPosition(): Long = exoPlayer?.currentPosition ?: 0

    override fun getDuration(): Long = exoPlayer?.duration?.takeIf { it != C.TIME_UNSET } ?: 0

    override fun getVideoMetadata(): Map<String, Any?>? {
        val player = exoPlayer ?: return null

        // Ensure player is ready and has loaded metadata
        if (player.playbackState == Player.STATE_IDLE || player.duration == C.TIME_UNSET) {
            return null
        }

        val metadata = mutableMapOf<String, Any?>()

        // Add duration
        val duration = player.duration
        if (duration != C.TIME_UNSET) {
            metadata["durationMs"] = duration
        }

        // Extract video and audio codec information from tracks
        val tracks = player.currentTracks
        var videoCodec: String? = null
        var audioCodec: String? = null
        var videoBitrate: Int? = null
        var audioBitrate: Int? = null
        var frameRate: Float? = null
        var width: Int? = null
        var height: Int? = null
        var containerFormat: String? = null

        for (group in tracks.groups) {
            when (group.type) {
                C.TRACK_TYPE_VIDEO -> {
                    if (group.length > 0) {
                        val format = group.getTrackFormat(0)

                        // Extract video codec
                        videoCodec = format.codecs?.split(",")?.firstOrNull()
                            ?: getMimeTypeCodec(format.sampleMimeType)

                        // Extract video dimensions
                        if (format.width > 0) width = format.width
                        if (format.height > 0) height = format.height

                        // Extract video bitrate
                        if (format.bitrate > 0) videoBitrate = format.bitrate

                        // Extract frame rate
                        if (format.frameRate > 0) frameRate = format.frameRate
                    }
                }
                C.TRACK_TYPE_AUDIO -> {
                    if (group.length > 0) {
                        val format = group.getTrackFormat(0)

                        // Extract audio codec
                        audioCodec = format.codecs?.split(",")?.firstOrNull()
                            ?: getMimeTypeCodec(format.sampleMimeType)

                        // Extract audio bitrate
                        if (format.bitrate > 0) audioBitrate = format.bitrate
                    }
                }
            }
        }

        // Add codec information if available
        videoCodec?.let { metadata["videoCodec"] = it }
        audioCodec?.let { metadata["audioCodec"] = it }

        // Add dimension information if available
        width?.let { metadata["width"] = it }
        height?.let { metadata["height"] = it }

        // Add bitrate information if available
        videoBitrate?.let { metadata["videoBitrate"] = it }
        audioBitrate?.let { metadata["audioBitrate"] = it }

        // Add frame rate if available
        frameRate?.let { metadata["frameRate"] = it.toDouble() }

        // Infer container format from URI extension
        containerFormat = getContainerFormat(player.currentMediaItem?.localConfiguration?.uri?.toString())
        containerFormat?.let { metadata["containerFormat"] = it }

        return if (metadata.isEmpty()) null else metadata
    }

    /**
     * Extracts codec name from MIME type string.
     * Delegates to VideoFormatUtils for testability.
     */
    private fun getMimeTypeCodec(mimeType: String?): String? {
        return VideoFormatUtils.getMimeTypeCodec(mimeType)
    }

    /**
     * Infers container format from URI file extension.
     * Delegates to VideoFormatUtils for testability.
     */
    private fun getContainerFormat(uriString: String?): String? {
        return VideoFormatUtils.getContainerFormat(uriString)
    }

    /**
     * Extracts and sends video metadata as an event.
     */
    private fun extractAndSendVideoMetadata() {
        val metadata = getVideoMetadata()
        if (metadata != null && metadata.isNotEmpty()) {
            sendEvent(mapOf("type" to "videoMetadataExtracted", "metadata" to metadata))
        }
    }

    fun enterPip(activity: Activity): Boolean {
        // Return false if PiP is not allowed
        if (!allowPip) return false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val videoSize = exoPlayer?.videoSize
                val aspectRatio = if (videoSize != null && videoSize.height > 0) {
                    Rational(videoSize.width, videoSize.height)
                } else {
                    Rational(16, 9)
                }

                // Register broadcast receiver for PiP actions
                registerPipActionReceiver(activity)

                val paramsBuilder = PictureInPictureParams.Builder()
                    .setAspectRatio(aspectRatio)

                // Add remote actions if configured
                val remoteActions = buildPipRemoteActions(activity)
                if (remoteActions.isNotEmpty()) {
                    paramsBuilder.setActions(remoteActions)
                }

                activity.enterPictureInPictureMode(paramsBuilder.build())

                // Track PiP state so we can detect when it ends
                isPipModeActive = true
                pipActivity = activity

                sendEvent(mapOf("type" to "pipStateChanged", "isActive" to true))
                updateScreenSleepPrevention()
                return true
            } catch (e: IllegalStateException) {
                // Activity doesn't support PiP (missing android:supportsPictureInPicture="true" in manifest)
                sendError("PiP not supported: ${e.message}", "PIP_NOT_SUPPORTED")
                return false
            }
        }
        return false
    }

    fun exitPip() {
        isPipModeActive = false
        pipActivity = null
        unregisterPipActionReceiver()
        sendEvent(mapOf("type" to "pipStateChanged", "isActive" to false))
        updateScreenSleepPrevention()
    }

    /**
     * Sets the PiP remote action buttons.
     *
     * @param actions List of action configurations, each containing:
     *   - type: String (playPause, skipPrevious, skipNext, skipBackward, skipForward)
     *   - skipIntervalMs: Int (milliseconds to skip for skip actions)
     */
    fun setPipActions(actions: List<Map<String, Any>>?) {
        pipActions = actions

        // Update PiP params if already in PiP mode
        if (isPipModeActive && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            pipActivity?.let { activity ->
                try {
                    val videoSize = exoPlayer?.videoSize
                    val aspectRatio = if (videoSize != null && videoSize.height > 0) {
                        Rational(videoSize.width, videoSize.height)
                    } else {
                        Rational(16, 9)
                    }

                    val paramsBuilder = PictureInPictureParams.Builder()
                        .setAspectRatio(aspectRatio)

                    val remoteActions = buildPipRemoteActions(activity)
                    if (remoteActions.isNotEmpty()) {
                        paramsBuilder.setActions(remoteActions)
                    }

                    activity.setPictureInPictureParams(paramsBuilder.build())
                } catch (e: Exception) {
                    verboseLog("Failed to update PiP actions: ${e.message}", TAG)
                }
            }
        }
    }

    /**
     * Builds the list of RemoteAction objects for PiP mode.
     */
    private fun buildPipRemoteActions(activity: Activity): List<RemoteAction> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return emptyList()
        }

        val actions = pipActions ?: return emptyList()
        val remoteActions = mutableListOf<RemoteAction>()

        for ((index, action) in actions.withIndex()) {
            val type = action["type"] as? String ?: continue
            val skipIntervalMs = (action["skipIntervalMs"] as? Number)?.toLong() ?: 10000L

            val remoteAction = createRemoteAction(activity, type, skipIntervalMs, index)
            if (remoteAction != null) {
                remoteActions.add(remoteAction)
            }
        }

        return remoteActions
    }

    /**
     * Creates a RemoteAction for a specific action type.
     */
    private fun createRemoteAction(
        activity: Activity,
        type: String,
        skipIntervalMs: Long,
        requestCode: Int
    ): RemoteAction? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return null
        }

        val (iconRes, title, contentDescription) = when (type) {
            "playPause" -> {
                val isPlaying = exoPlayer?.isPlaying == true
                if (isPlaying) {
                    Triple(android.R.drawable.ic_media_pause, "Pause", "Pause playback")
                } else {
                    Triple(android.R.drawable.ic_media_play, "Play", "Resume playback")
                }
            }
            "skipPrevious" -> Triple(android.R.drawable.ic_media_previous, "Previous", "Skip to previous")
            "skipNext" -> Triple(android.R.drawable.ic_media_next, "Next", "Skip to next")
            "skipBackward" -> Triple(android.R.drawable.ic_media_rew, "Rewind", "Skip backward ${skipIntervalMs / 1000}s")
            "skipForward" -> Triple(android.R.drawable.ic_media_ff, "Forward", "Skip forward ${skipIntervalMs / 1000}s")
            else -> return null
        }

        val intent = Intent(PIP_ACTION_BROADCAST).apply {
            setPackage(activity.packageName)
            putExtra(PIP_ACTION_TYPE, type)
            putExtra(PIP_ACTION_SKIP_INTERVAL, skipIntervalMs)
            putExtra(PIP_ACTION_PLAYER_ID, playerId)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            activity,
            playerId * 100 + requestCode, // Unique request code per action
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return RemoteAction(
            Icon.createWithResource(activity, iconRes),
            title,
            contentDescription,
            pendingIntent
        )
    }

    /**
     * Registers the BroadcastReceiver for PiP action events.
     */
    private fun registerPipActionReceiver(activity: Activity) {
        if (isReceiverRegistered) return

        pipActionReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action != PIP_ACTION_BROADCAST) return

                val actionPlayerId = intent.getIntExtra(PIP_ACTION_PLAYER_ID, -1)
                if (actionPlayerId != playerId) return

                val actionType = intent.getStringExtra(PIP_ACTION_TYPE) ?: return
                val skipIntervalMs = intent.getLongExtra(PIP_ACTION_SKIP_INTERVAL, 10000L)

                handlePipAction(actionType, skipIntervalMs, activity)
            }
        }

        val filter = IntentFilter(PIP_ACTION_BROADCAST)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.registerReceiver(pipActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            activity.registerReceiver(pipActionReceiver, filter)
        }
        isReceiverRegistered = true
    }

    /**
     * Unregisters the BroadcastReceiver for PiP actions.
     */
    private fun unregisterPipActionReceiver() {
        if (!isReceiverRegistered) return

        try {
            pipActivity?.unregisterReceiver(pipActionReceiver)
        } catch (e: Exception) {
            verboseLog("Failed to unregister PiP action receiver: ${e.message}", TAG)
        }
        pipActionReceiver = null
        isReceiverRegistered = false
    }

    /**
     * Handles a PiP action button press.
     */
    private fun handlePipAction(type: String, skipIntervalMs: Long, activity: Activity) {
        when (type) {
            "playPause" -> {
                if (exoPlayer?.isPlaying == true) {
                    pause()
                } else {
                    play()
                }
                // Update PiP actions to reflect new play/pause state
                updatePipActionsForPlaybackState(activity)
            }
            "skipPrevious" -> {
                // Send event to Dart layer to handle (e.g., for playlist navigation)
                sendEvent(mapOf("type" to "pipActionTriggered", "action" to "skipPrevious"))
            }
            "skipNext" -> {
                // Send event to Dart layer to handle (e.g., for playlist navigation)
                sendEvent(mapOf("type" to "pipActionTriggered", "action" to "skipNext"))
            }
            "skipBackward" -> {
                val currentPos = exoPlayer?.currentPosition ?: 0
                val duration = exoPlayer?.duration ?: Long.MAX_VALUE
                val newPos = VideoFormatUtils.calculateSkipPosition(currentPos, -skipIntervalMs, duration)
                exoPlayer?.seekTo(newPos)
                sendEvent(mapOf("type" to "pipActionTriggered", "action" to "skipBackward"))
            }
            "skipForward" -> {
                val currentPos = exoPlayer?.currentPosition ?: 0
                val duration = exoPlayer?.duration ?: Long.MAX_VALUE
                val newPos = VideoFormatUtils.calculateSkipPosition(currentPos, skipIntervalMs, duration)
                exoPlayer?.seekTo(newPos)
                sendEvent(mapOf("type" to "pipActionTriggered", "action" to "skipForward"))
            }
        }
    }

    /**
     * Updates PiP remote actions to reflect current playback state (play/pause icon).
     */
    private fun updatePipActionsForPlaybackState(activity: Activity) {
        if (!isPipModeActive || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        try {
            val videoSize = exoPlayer?.videoSize
            val aspectRatio = if (videoSize != null && videoSize.height > 0) {
                Rational(videoSize.width, videoSize.height)
            } else {
                Rational(16, 9)
            }

            val paramsBuilder = PictureInPictureParams.Builder()
                .setAspectRatio(aspectRatio)

            val remoteActions = buildPipRemoteActions(activity)
            if (remoteActions.isNotEmpty()) {
                paramsBuilder.setActions(remoteActions)
            }

            activity.setPictureInPictureParams(paramsBuilder.build())
        } catch (e: Exception) {
            verboseLog("Failed to update PiP playback state: ${e.message}", TAG)
        }
    }

    companion object {
        private const val TAG = "VideoPlayer"
        private const val PIP_ACTION_BROADCAST = "dev.pro_video_player.PIP_ACTION"
        private const val PIP_ACTION_TYPE = "action_type"
        private const val PIP_ACTION_SKIP_INTERVAL = "skip_interval"
        private const val PIP_ACTION_PLAYER_ID = "player_id"
        // Delay before hiding/showing system bars to prevent Flutter platform view race condition
        private const val FULLSCREEN_TRANSITION_DELAY_MS = 100L
    }

    /**
     * Returns whether PiP is allowed for this player instance.
     */
    override fun isPipAllowed(): Boolean = allowPip

    /**
     * Returns whether subtitles are enabled for this player instance.
     */
    override fun areSubtitlesEnabled(): Boolean = subtitlesEnabled

    /**
     * Returns whether the player is currently playing.
     */
    override fun isPlaying(): Boolean = exoPlayer?.isPlaying == true

    /**
     * Returns whether background playback is allowed for this player instance.
     */
    override fun allowsBackgroundPlayback(): Boolean = allowBackgroundPlayback

    /**
     * Should be called when the app enters background to auto-enter PiP if configured.
     */
    fun onEnterBackground(activity: Activity) {
        if (autoEnterPipOnBackground && allowPip) {
            enterPip(activity)
        }
    }

    fun enterFullscreen(activity: Activity): Boolean {
        if (isFullscreen) return true

        try {
            isFullscreen = true

            // First, set layout flags to prepare for fullscreen mode.
            // This prevents Flutter's platform view from experiencing a sudden resize.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // On API 30+, set layout to extend behind system bars first
                activity.window.setDecorFitsSystemWindows(false)
            } else {
                @Suppress("DEPRECATION")
                activity.window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                )
            }

            // Delay hiding system bars to prevent race condition with Flutter's
            // platform view resize. This gives the layout time to stabilize.
            mainHandler.postDelayed({
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        activity.window.insetsController?.let { controller ->
                            controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                            controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                        }
                    } else {
                        @Suppress("DEPRECATION")
                        activity.window.decorView.systemUiVisibility = (
                            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                                or View.SYSTEM_UI_FLAG_FULLSCREEN
                                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        )
                    }
                } catch (e: Exception) {
                    verboseLog("Failed to hide system bars: ${e.message}", TAG)
                }
            }, FULLSCREEN_TRANSITION_DELAY_MS)

            sendEvent(mapOf("type" to "fullscreenStateChanged", "isFullscreen" to true))
            return true
        } catch (e: Exception) {
            isFullscreen = false
            sendError("Failed to enter fullscreen: ${e.message}", "FULLSCREEN_ERROR")
            return false
        }
    }

    fun exitFullscreen(activity: Activity) {
        if (!isFullscreen) return

        try {
            isFullscreen = false

            // Delay restoring system bars to prevent race condition with Flutter's
            // platform view resize. This gives the layout time to stabilize.
            mainHandler.postDelayed({
                try {
                    // Restore system bars
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        activity.window.setDecorFitsSystemWindows(true)
                        activity.window.insetsController?.let { controller ->
                            controller.show(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                        }
                    } else {
                        @Suppress("DEPRECATION")
                        activity.window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
                    }
                } catch (e: Exception) {
                    verboseLog("Failed to restore system bars: ${e.message}", TAG)
                }
            }, FULLSCREEN_TRANSITION_DELAY_MS)

            sendEvent(mapOf("type" to "fullscreenStateChanged", "isFullscreen" to false))
        } catch (e: Exception) {
            sendError("Failed to exit fullscreen: ${e.message}", "FULLSCREEN_ERROR")
        }
    }

    /**
     * Sets background playback enabled state at runtime.
     * @param enabled Whether to enable or disable background playback
     * @return True if background playback was successfully configured
     */
    fun setBackgroundPlayback(enabled: Boolean): Boolean {
        val wasEnabled = allowBackgroundPlayback
        allowBackgroundPlayback = enabled

        if (enabled && !wasEnabled) {
            // Enable background playback - register player with service
            exoPlayer?.let { player ->
                MediaPlaybackService.registerPlayer(playerId, player)
            }
            // Start service if currently playing
            if (exoPlayer?.isPlaying == true) {
                startBackgroundPlaybackService()
            }
        } else if (!enabled && wasEnabled) {
            // Disable background playback - unregister from service
            MediaPlaybackService.unregisterPlayer(playerId)
        }

        sendEvent(mapOf("type" to "backgroundPlaybackChanged", "isEnabled" to enabled))
        return true
    }

    /**
     * Returns whether background playback is currently enabled.
     */
    fun isBackgroundPlaybackEnabled(): Boolean = allowBackgroundPlayback

    /**
     * Sets media metadata for lock screen and notification display.
     * Only takes effect when background playback is enabled.
     */
    fun setMediaMetadata(metadata: Map<String, Any>) {
        if (!allowBackgroundPlayback) return

        // Extract metadata fields
        val stringMetadata = mutableMapOf<String, String>()
        (metadata["title"] as? String)?.let { stringMetadata["title"] = it }
        (metadata["artist"] as? String)?.let { stringMetadata["artist"] = it }
        (metadata["album"] as? String)?.let { stringMetadata["album"] = it }
        (metadata["artworkUrl"] as? String)?.let { stringMetadata["artworkUrl"] = it }

        // Update MediaPlaybackService metadata
        MediaPlaybackService.setMetadata(playerId, stringMetadata)
    }


    private fun sendEvent(event: Map<String, Any?>) {
        // Optimize: avoid handler post overhead when already on main thread
        if (Looper.myLooper() == Looper.getMainLooper()) {
            eventSink?.success(event)
        } else {
            mainHandler.post {
                eventSink?.success(event)
            }
        }
    }

    private fun sendError(message: String, code: String) {
        sendEvent(mapOf("type" to "error", "message" to message, "code" to code))
    }

    // MARK: - Casting Methods

    override fun isCastingSupported(): Boolean {
        // Chromecast is supported when CastContext is available
        return castContext != null
    }

    override fun getAvailableCastDevices(): List<Map<String, Any>> {
        // Note: Cast device discovery is handled by the Google Cast Framework
        // The actual device list is shown via MediaRouteButton UI
        // The Cast SDK doesn't expose a list of discovered devices programmatically
        // Apps should use MediaRouteButton for device selection
        return emptyList()
    }

    override fun startCasting(device: Map<String, Any>): Boolean {
        val ctx = castContext ?: return false

        // If already connected, just load media to the session
        val session = ctx.sessionManager?.currentCastSession
        if (session != null && session.isConnected) {
            loadMediaToCastSession(session)
            return true
        }

        // Show the MediaRouter device picker dialog programmatically
        try {
            val activity = context as? androidx.fragment.app.FragmentActivity
            if (activity == null) {
                verboseLog("startCasting: Context is not a FragmentActivity, cannot show dialog", TAG)
                return false
            }

            // Get the MediaRouter and set up the selector
            val selector = androidx.mediarouter.media.MediaRouteSelector.Builder()
                .addControlCategory(com.google.android.gms.cast.CastMediaControlIntent.categoryForCast(
                    ctx.castOptions?.receiverApplicationId ?: "CC1AD845"
                ))
                .build()

            // Create the chooser dialog fragment with the selector
            val dialog = androidx.mediarouter.app.MediaRouteChooserDialogFragment()
            dialog.routeSelector = selector

            // Show the dialog
            dialog.show(activity.supportFragmentManager, "MediaRouteChooserDialog")
            verboseLog("startCasting: Showing MediaRouteChooserDialog", TAG)
            return true
        } catch (e: Exception) {
            verboseLog("startCasting: Failed to show dialog: ${e.message}", TAG)
            return false
        }
    }

    /**
     * Loads the current media to an active cast session.
     */
    private fun loadMediaToCastSession(session: com.google.android.gms.cast.framework.CastSession) {
        verboseLog("loadMediaToCastSession: Starting to load media to cast device", TAG)

        val remoteMediaClient = session.remoteMediaClient
        if (remoteMediaClient == null) {
            verboseLog("loadMediaToCastSession: remoteMediaClient is null", TAG)
            return
        }

        val player = exoPlayer
        if (player == null) {
            verboseLog("loadMediaToCastSession: exoPlayer is null", TAG)
            return
        }

        // Get current media URL
        val currentMediaItem = player.currentMediaItem
        if (currentMediaItem == null) {
            verboseLog("loadMediaToCastSession: currentMediaItem is null", TAG)
            return
        }

        val uri = currentMediaItem.localConfiguration?.uri?.toString()
        if (uri == null) {
            verboseLog("loadMediaToCastSession: uri is null", TAG)
            return
        }

        verboseLog("loadMediaToCastSession: Loading URI: $uri", TAG)

        // Build Cast MediaInfo
        val mediaMetadata = com.google.android.gms.cast.MediaMetadata(
            com.google.android.gms.cast.MediaMetadata.MEDIA_TYPE_MOVIE
        )
        currentMediaItem.mediaMetadata.title?.let {
            mediaMetadata.putString(com.google.android.gms.cast.MediaMetadata.KEY_TITLE, it.toString())
        }

        val mediaInfo = com.google.android.gms.cast.MediaInfo.Builder(uri)
            .setStreamType(com.google.android.gms.cast.MediaInfo.STREAM_TYPE_BUFFERED)
            .setMetadata(mediaMetadata)
            .build()

        // Load media to cast device using MediaLoadOptions
        val loadOptions = com.google.android.gms.cast.MediaLoadOptions.Builder()
            .setAutoplay(true)
            .setPlayPosition(player.currentPosition)
            .build()

        verboseLog("loadMediaToCastSession: Calling remoteMediaClient.load()", TAG)
        val pendingResult = remoteMediaClient.load(mediaInfo, loadOptions)
        pendingResult.setResultCallback { result ->
            val status = result.status
            if (status.isSuccess) {
                verboseLog("loadMediaToCastSession: Media loaded successfully, hiding local player", TAG)
                mainHandler.post {
                    // Pause the local player and hide the view
                    exoPlayer?.pause()
                    playerView?.visibility = View.GONE
                    isCastingActive = true

                    // Register callback to track remote position
                    registerRemoteMediaClientCallback(session)
                }
            } else {
                verboseLog("loadMediaToCastSession: Failed to load media - status code: ${status.statusCode}, message: ${status.statusMessage}", TAG)
                sendEvent(mapOf(
                    "type" to "error",
                    "message" to "Failed to cast media: ${status.statusMessage ?: "Unknown error"}",
                    "code" to "cast_load_failed"
                ))
            }
        }
    }

    /**
     * Registers a callback to track position updates from the RemoteMediaClient.
     */
    private fun registerRemoteMediaClientCallback(session: com.google.android.gms.cast.framework.CastSession) {
        val client = session.remoteMediaClient ?: return

        remoteMediaClientCallback = object : RemoteMediaClient.Callback() {
            override fun onStatusUpdated() {
                // Update the last known cast position periodically
                lastCastPosition = client.approximateStreamPosition
            }
        }
        client.registerCallback(remoteMediaClientCallback!!)
        verboseLog("registerRemoteMediaClientCallback: Registered callback for position tracking", TAG)
    }

    /**
     * Unregisters the RemoteMediaClient callback.
     */
    private fun unregisterRemoteMediaClientCallback(session: com.google.android.gms.cast.framework.CastSession) {
        remoteMediaClientCallback?.let { callback ->
            session.remoteMediaClient?.unregisterCallback(callback)
            verboseLog("unregisterRemoteMediaClientCallback: Unregistered callback", TAG)
        }
        remoteMediaClientCallback = null
    }

    override fun stopCasting(): Boolean {
        val sessionManager = castContext?.sessionManager ?: return false
        val currentSession = sessionManager.currentCastSession
        if (currentSession != null && currentSession.isConnected) {
            sessionManager.endCurrentSession(true)
            return true
        }
        return false
    }

    override fun getCastState(): String {
        val state = castContext?.castState ?: return "notConnected"
        return VideoFormatUtils.getCastStateString(state)
    }

    override fun getCurrentCastDevice(): Map<String, Any>? {
        return getCurrentCastDeviceInternal()
    }

    override fun dispose() {
        // Stop position updates to prevent callbacks after dispose
        stopPositionUpdates()

        // Cancel any pending network retry
        retryRunnable?.let { mainHandler.removeCallbacks(it) }
        retryRunnable = null

        // Unregister network callback
        networkCallback?.let { callback ->
            try {
                connectivityManager?.unregisterNetworkCallback(callback)
            } catch (e: Exception) {
                verboseLog("Failed to unregister network callback: ${e.message}", TAG)
            }
        }
        networkCallback = null

        // Clean up cast listeners
        castStateListener?.let { listener ->
            castContext?.removeCastStateListener(listener)
        }
        castStateListener = null

        sessionManagerListener?.let { listener ->
            castContext?.sessionManager?.removeSessionManagerListener(
                listener,
                com.google.android.gms.cast.framework.CastSession::class.java
            )
        }
        sessionManagerListener = null
        castContext = null

        // Unregister from background playback service
        if (allowBackgroundPlayback) {
            MediaPlaybackService.unregisterPlayer(playerId)
        }

        // Clean up screen sleep prevention
        disableScreenSleepPrevention()

        // Clean up PiP state
        isPipModeActive = false
        pipActivity = null

        // Reset network resilience state
        isBufferingDueToNetwork = false
        wasPlayingBeforeStall = false
        networkRetryCount = 0
        hadNetworkError = false

        mainHandler.post {
            // Release MediaSession before releasing player
            mediaSession?.release()
            mediaSession = null

            exoPlayer?.release()
            exoPlayer = null
            playerView?.player = null
            playerView = null
        }
        eventChannel.setStreamHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
