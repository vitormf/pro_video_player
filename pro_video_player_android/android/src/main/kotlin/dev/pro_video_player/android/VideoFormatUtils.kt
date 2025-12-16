package dev.pro_video_player.android

/**
 * Utility class for video format parsing and conversion.
 *
 * Contains pure functions that can be tested without Android dependencies.
 */
object VideoFormatUtils {

    /**
     * Extracts codec name from MIME type string.
     *
     * @param mimeType The MIME type string (e.g., "video/avc", "audio/mp4a-latm")
     * @return The codec name (e.g., "h264", "aac") or null if not recognized
     *
     * Examples:
     * - "video/avc" -> "h264"
     * - "video/hevc" -> "hevc"
     * - "audio/mp4a-latm" -> "aac"
     * - "audio/mpeg" -> "mp3"
     */
    fun getMimeTypeCodec(mimeType: String?): String? {
        if (mimeType == null) return null

        return when (mimeType) {
            // Video codecs
            "video/avc" -> "h264"
            "video/hevc" -> "hevc"
            "video/mp4v-es" -> "mpeg4"
            "video/3gpp" -> "h263"
            "video/x-vnd.on2.vp8" -> "vp8"
            "video/x-vnd.on2.vp9" -> "vp9"
            "video/av01" -> "av1"

            // Audio codecs
            "audio/mp4a-latm" -> "aac"
            "audio/mpeg" -> "mp3"
            "audio/vorbis" -> "vorbis"
            "audio/opus" -> "opus"
            "audio/ac-3" -> "ac3"
            "audio/eac3" -> "eac3"
            "audio/flac" -> "flac"

            // Fallback: extract the part after the last slash
            else -> mimeType.substringAfterLast("/")
        }
    }

    /**
     * Infers container format from URI file extension.
     *
     * @param uriString The URI string (e.g., "https://example.com/video.mp4")
     * @return The container format (e.g., "mp4", "hls") or null if not recognized
     *
     * Examples:
     * - "https://example.com/video.mp4" -> "mp4"
     * - "https://example.com/stream.m3u8" -> "hls"
     * - "https://example.com/video.mkv" -> "matroska"
     */
    fun getContainerFormat(uriString: String?): String? {
        if (uriString == null) return null

        // Remove query parameters and fragments before checking extension
        val pathOnly = uriString.substringBefore("?").substringBefore("#")

        return when {
            pathOnly.endsWith(".mp4", ignoreCase = true) -> "mp4"
            pathOnly.endsWith(".mkv", ignoreCase = true) -> "matroska"
            pathOnly.endsWith(".webm", ignoreCase = true) -> "webm"
            pathOnly.endsWith(".m3u8", ignoreCase = true) -> "hls"
            pathOnly.endsWith(".mpd", ignoreCase = true) -> "dash"
            pathOnly.endsWith(".3gp", ignoreCase = true) -> "3gp"
            pathOnly.endsWith(".avi", ignoreCase = true) -> "avi"
            pathOnly.endsWith(".mov", ignoreCase = true) -> "quicktime"
            pathOnly.endsWith(".flv", ignoreCase = true) -> "flash"
            pathOnly.endsWith(".ts", ignoreCase = true) -> "mpegts"
            pathOnly.endsWith(".m4v", ignoreCase = true) -> "mp4"
            pathOnly.endsWith(".m4a", ignoreCase = true) -> "mp4"
            pathOnly.endsWith(".mp3", ignoreCase = true) -> "mp3"
            pathOnly.endsWith(".ogg", ignoreCase = true) -> "ogg"
            pathOnly.endsWith(".ogv", ignoreCase = true) -> "ogg"
            pathOnly.endsWith(".wav", ignoreCase = true) -> "wav"
            else -> null
        }
    }

    /**
     * Parses a track ID string in the format "groupIndex:trackIndex".
     *
     * @param trackId The track ID string (e.g., "0:1")
     * @return A Pair of (groupIndex, trackIndex) or null if parsing fails
     */
    fun parseTrackId(trackId: String?): Pair<Int, Int>? {
        if (trackId == null) return null

        val parts = trackId.split(":")
        if (parts.size != 2) return null

        val groupIndex = parts[0].toIntOrNull() ?: return null
        val trackIndex = parts[1].toIntOrNull() ?: return null

        return Pair(groupIndex, trackIndex)
    }

    /**
     * Creates a track ID string from group and track indices.
     *
     * @param groupIndex The track group index
     * @param trackIndex The track index within the group
     * @return The track ID string (e.g., "0:1")
     */
    fun createTrackId(groupIndex: Int, trackIndex: Int): String {
        return "$groupIndex:$trackIndex"
    }

    /**
     * Validates a playback speed value.
     *
     * @param speed The playback speed to validate
     * @return true if the speed is valid (between 0.25 and 4.0), false otherwise
     */
    fun isValidPlaybackSpeed(speed: Float): Boolean {
        return speed in 0.25f..4.0f
    }

    /**
     * Validates a volume value.
     *
     * @param volume The volume to validate
     * @return true if the volume is valid (between 0.0 and 1.0), false otherwise
     */
    fun isValidVolume(volume: Float): Boolean {
        return volume in 0.0f..1.0f
    }

    /**
     * Validates a seek position.
     *
     * @param position The position in milliseconds
     * @param duration The total duration in milliseconds (optional)
     * @return true if the position is valid, false otherwise
     */
    fun isValidSeekPosition(position: Long, duration: Long? = null): Boolean {
        if (position < 0) return false
        if (duration != null && position > duration) return false
        return true
    }

    /**
     * Gets a human-readable label for a video quality track.
     *
     * @param height The video height in pixels
     * @param frameRate The frame rate (optional)
     * @return A quality label (e.g., "1080p", "720p60")
     */
    fun getQualityLabel(height: Int, frameRate: Float? = null): String {
        val heightLabel = when {
            height >= 2160 -> "4K"
            height >= 1440 -> "1440p"
            height >= 1080 -> "1080p"
            height >= 720 -> "720p"
            height >= 480 -> "480p"
            height >= 360 -> "360p"
            height >= 240 -> "240p"
            height >= 144 -> "144p"
            else -> "${height}p"
        }

        // Add frame rate suffix for high frame rate content
        return if (frameRate != null && frameRate > 30) {
            "$heightLabel${frameRate.toInt()}"
        } else {
            heightLabel
        }
    }

    /**
     * Formats a bitrate value for display.
     *
     * @param bitrate The bitrate in bits per second
     * @return A formatted string (e.g., "5.2 Mbps", "800 Kbps")
     */
    fun formatBitrate(bitrate: Int): String {
        return when {
            bitrate >= 1_000_000 -> String.format("%.1f Mbps", bitrate / 1_000_000.0)
            bitrate >= 1_000 -> String.format("%d Kbps", bitrate / 1_000)
            else -> String.format("%d bps", bitrate)
        }
    }

    /**
     * Formats a duration in milliseconds to a human-readable string.
     *
     * @param durationMs The duration in milliseconds
     * @return A formatted string (e.g., "1:23:45", "5:30")
     */
    fun formatDuration(durationMs: Long): String {
        if (durationMs < 0) return "0:00"

        val totalSeconds = durationMs / 1000
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60

        return if (hours > 0) {
            String.format("%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format("%d:%02d", minutes, seconds)
        }
    }

    /**
     * Calculates exponential backoff delay for retry attempts.
     *
     * @param retryCount The current retry attempt number (0-based)
     * @param baseDelayMs The base delay in milliseconds (default: 1000ms)
     * @param maxDelayMs The maximum delay in milliseconds (default: 30000ms)
     * @return The calculated delay in milliseconds
     *
     * Formula: min(2^retryCount * baseDelayMs, maxDelayMs)
     *
     * Examples:
     * - retryCount=0, baseDelay=1000 -> 1000ms (1 second)
     * - retryCount=1, baseDelay=1000 -> 2000ms (2 seconds)
     * - retryCount=2, baseDelay=1000 -> 4000ms (4 seconds)
     * - retryCount=5, baseDelay=1000 -> 30000ms (capped at max)
     */
    fun calculateExponentialBackoff(
        retryCount: Int,
        baseDelayMs: Long = 1000L,
        maxDelayMs: Long = 30000L
    ): Long {
        if (retryCount < 0) return baseDelayMs
        val delay = Math.pow(2.0, retryCount.toDouble()).toLong() * baseDelayMs
        return minOf(delay, maxDelayMs)
    }

    /**
     * Calculates aspect ratio as a reduced fraction.
     *
     * @param width The width in pixels
     * @param height The height in pixels
     * @return A Pair of (numerator, denominator) representing the aspect ratio,
     *         or Pair(16, 9) as default if dimensions are invalid
     *
     * Examples:
     * - (1920, 1080) -> (16, 9)
     * - (1280, 720) -> (16, 9)
     * - (640, 480) -> (4, 3)
     * - (0, 0) -> (16, 9) default
     */
    fun calculateAspectRatio(width: Int, height: Int): Pair<Int, Int> {
        if (width <= 0 || height <= 0) {
            return Pair(16, 9) // Default aspect ratio
        }

        // Find GCD to reduce the fraction
        val gcd = gcd(width, height)
        return Pair(width / gcd, height / gcd)
    }

    /**
     * Calculates the greatest common divisor using Euclidean algorithm.
     */
    private fun gcd(a: Int, b: Int): Int {
        return if (b == 0) a else gcd(b, a % b)
    }

    /**
     * Determines if a position update should be sent based on change threshold.
     *
     * @param currentPosition The current position in milliseconds
     * @param lastSentPosition The last sent position in milliseconds
     * @param thresholdMs The minimum change threshold in milliseconds (default: 100ms)
     * @return true if the position change exceeds the threshold
     */
    fun shouldUpdatePosition(
        currentPosition: Int,
        lastSentPosition: Int,
        thresholdMs: Int = 100
    ): Boolean {
        return kotlin.math.abs(currentPosition - lastSentPosition) >= thresholdMs
    }

    /**
     * Determines if a bandwidth update should be sent based on percentage change.
     *
     * @param currentBandwidth The current bandwidth estimate in bps
     * @param lastSentBandwidth The last sent bandwidth in bps
     * @param changeThreshold The minimum percentage change to trigger update (default: 0.1 = 10%)
     * @return true if the bandwidth change exceeds the threshold
     */
    fun shouldUpdateBandwidth(
        currentBandwidth: Long,
        lastSentBandwidth: Long,
        changeThreshold: Double = 0.1
    ): Boolean {
        if (currentBandwidth <= 0) return false
        if (lastSentBandwidth <= 0) return true // First update

        val threshold = lastSentBandwidth * changeThreshold
        return kotlin.math.abs(currentBandwidth - lastSentBandwidth) >= threshold
    }

    /**
     * Determines if an error code represents a network-related error.
     *
     * Uses ExoPlayer/Media3 PlaybackException error codes:
     * - ERROR_CODE_IO_NETWORK_CONNECTION_FAILED (2001)
     * - ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT (2002)
     * - ERROR_CODE_IO_UNSPECIFIED (2000)
     *
     * @param errorCode The PlaybackException error code
     * @return true if the error is network-related
     */
    fun isNetworkErrorCode(errorCode: Int): Boolean {
        return when (errorCode) {
            ERROR_CODE_IO_NETWORK_CONNECTION_FAILED,
            ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT,
            ERROR_CODE_IO_UNSPECIFIED -> true
            else -> false
        }
    }

    // PlaybackException error code constants (from Media3)
    // These match androidx.media3.common.PlaybackException values
    private const val ERROR_CODE_IO_UNSPECIFIED = 2000
    private const val ERROR_CODE_IO_NETWORK_CONNECTION_FAILED = 2001
    private const val ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT = 2002

    /**
     * Calculates adaptive polling interval based on playback state.
     *
     * @param isPlaying Whether the player is currently playing
     * @param playingIntervalMs Polling interval when playing (default: 500ms)
     * @param pausedIntervalMs Polling interval when paused (default: 1000ms)
     * @return The appropriate polling interval in milliseconds
     */
    fun getPollingInterval(
        isPlaying: Boolean,
        playingIntervalMs: Long = 500L,
        pausedIntervalMs: Long = 1000L
    ): Long {
        return if (isPlaying) playingIntervalMs else pausedIntervalMs
    }

    /**
     * Calculates a new seek position for skip operations, clamped to valid range.
     *
     * @param currentPosition The current position in milliseconds
     * @param skipAmountMs The amount to skip (positive for forward, negative for backward)
     * @param duration The total duration in milliseconds
     * @return The new position clamped between 0 and duration
     */
    fun calculateSkipPosition(currentPosition: Long, skipAmountMs: Long, duration: Long): Long {
        val newPosition = currentPosition + skipAmountMs
        return when {
            newPosition < 0 -> 0
            duration > 0 && newPosition > duration -> duration
            else -> newPosition
        }
    }

    /**
     * Determines buffering reason based on playback state transition.
     *
     * @param previousState The previous playback state
     * @param isIdle Whether the player was idle
     * @return The buffering reason string ("initial" or "networkUnstable")
     */
    fun getBufferingReason(previousState: Int, isIdle: Boolean = false): String {
        // Player.STATE_IDLE = 1
        return if (previousState == 1 || isIdle) "initial" else "networkUnstable"
    }

    /**
     * Detects the subtitle format from a URL based on its file extension.
     *
     * @param url The URL of the subtitle file
     * @return The detected format ("srt", "vtt", "ssa", "ass", "ttml") or "srt" as default
     *
     * Examples:
     * - "https://example.com/subtitles.srt" -> "srt"
     * - "https://example.com/subtitles.vtt" -> "vtt"
     * - "https://example.com/subtitles.ssa" -> "ssa"
     * - "https://example.com/subtitles.ass" -> "ass"
     * - "https://example.com/subtitles.ttml" -> "ttml"
     * - "https://example.com/subtitles.xml" -> "ttml"
     * - "https://example.com/subtitles.txt" -> "srt" (default)
     * - "https://example.com/subtitles.srt?token=abc" -> "srt" (handles query params)
     */
    fun detectSubtitleFormat(url: String?): String {
        if (url == null) return "srt"

        // Remove query parameters and fragments before checking extension
        val pathOnly = url.substringBefore("?").substringBefore("#").lowercase()
        return when {
            pathOnly.endsWith(".srt") -> "srt"
            pathOnly.endsWith(".vtt") -> "vtt"
            pathOnly.endsWith(".ssa") -> "ssa"
            pathOnly.endsWith(".ass") -> "ass"
            pathOnly.endsWith(".ttml") || pathOnly.endsWith(".xml") -> "ttml"
            else -> "srt" // Default to SRT
        }
    }

    /**
     * Maps a Cast SDK state integer to a human-readable string.
     *
     * @param castState The CastState integer value
     * @return The state string ("noDevices", "notConnected", "connecting", "connected")
     *
     * Cast state constants (from Google Cast SDK):
     * - NO_DEVICES_AVAILABLE = 1
     * - NOT_CONNECTED = 2
     * - CONNECTING = 3
     * - CONNECTED = 4
     */
    fun getCastStateString(castState: Int): String {
        return when (castState) {
            CAST_STATE_NO_DEVICES_AVAILABLE -> "noDevices"
            CAST_STATE_NOT_CONNECTED -> "notConnected"
            CAST_STATE_CONNECTING -> "connecting"
            CAST_STATE_CONNECTED -> "connected"
            else -> "notConnected"
        }
    }

    // CastState constants (matching Google Cast SDK values)
    const val CAST_STATE_NO_DEVICES_AVAILABLE = 1
    const val CAST_STATE_NOT_CONNECTED = 2
    const val CAST_STATE_CONNECTING = 3
    const val CAST_STATE_CONNECTED = 4

    /**
     * Maps a scaling mode string to its display name.
     *
     * @param mode The scaling mode string ("fit", "fill", "stretch")
     * @return true if the mode is valid, false otherwise
     */
    fun isValidScalingMode(mode: String?): Boolean {
        return mode in listOf("fit", "fill", "stretch")
    }

    /**
     * Validates a buffering tier name.
     *
     * @param tier The buffering tier name
     * @return true if the tier is valid, false otherwise
     */
    fun isValidBufferingTier(tier: String?): Boolean {
        if (tier == null) return true // null defaults to medium
        return tier.lowercase() in listOf("min", "low", "medium", "high", "max")
    }

    /**
     * Validates a video source type.
     *
     * @param type The video source type string
     * @return true if the type is valid, false otherwise
     */
    fun isValidVideoSourceType(type: String?): Boolean {
        return type in listOf("network", "file", "asset")
    }

    /**
     * Validates PiP action type.
     *
     * @param actionType The PiP action type string
     * @return true if the action type is valid, false otherwise
     */
    fun isValidPipActionType(actionType: String?): Boolean {
        return actionType in listOf("playPause", "skipPrevious", "skipNext", "skipBackward", "skipForward")
    }

    /**
     * Returns the default PiP action icon resource name for an action type.
     *
     * @param actionType The PiP action type
     * @return The icon resource name (without android:drawable/ prefix)
     */
    fun getPipActionIconName(actionType: String): String {
        return when (actionType) {
            "playPause" -> "ic_media_play"  // Note: actual icon depends on playing state
            "skipPrevious" -> "ic_media_previous"
            "skipNext" -> "ic_media_next"
            "skipBackward" -> "ic_media_rew"
            "skipForward" -> "ic_media_ff"
            else -> "ic_media_play"
        }
    }

    /**
     * Checks if an external subtitle track ID has the correct format.
     * External subtitle IDs should start with "ext-".
     *
     * @param trackId The track ID to check
     * @return true if the track ID is an external subtitle ID, false otherwise
     */
    fun isExternalSubtitleId(trackId: String?): Boolean {
        return trackId?.startsWith("ext-") == true
    }

    /**
     * Extracts the numeric index from an external subtitle track ID.
     *
     * @param trackId The external subtitle track ID (e.g., "ext-0", "ext-1")
     * @return The numeric index, or null if the ID is invalid
     */
    fun parseExternalSubtitleIndex(trackId: String?): Int? {
        if (trackId == null || !trackId.startsWith("ext-")) return null
        return trackId.removePrefix("ext-").toIntOrNull()
    }

    /**
     * Creates an external subtitle track ID from an index.
     *
     * @param index The numeric index
     * @return The track ID string (e.g., "ext-0")
     */
    fun createExternalSubtitleId(index: Int): String {
        return "ext-$index"
    }

    /**
     * Clamps a volume value to the valid range [0.0, 1.0].
     *
     * @param volume The volume value to clamp
     * @return The clamped volume value
     */
    fun clampVolume(volume: Float): Float {
        return volume.coerceIn(0.0f, 1.0f)
    }

    /**
     * Clamps a playback speed to the valid range [0.25, 4.0].
     *
     * @param speed The playback speed to clamp
     * @return The clamped playback speed
     */
    fun clampPlaybackSpeed(speed: Float): Float {
        return speed.coerceIn(0.25f, 4.0f)
    }
}

/**
 * Utility object for parsing VideoPlayer options from a Map.
 * Provides type-safe extraction with default values.
 */
object VideoPlayerOptionsParser {

    // Default values
    const val DEFAULT_ALLOW_PIP = true
    const val DEFAULT_AUTO_ENTER_PIP = false
    const val DEFAULT_SUBTITLES_ENABLED = true
    const val DEFAULT_SHOW_SUBTITLES_BY_DEFAULT = false
    const val DEFAULT_ALLOW_BACKGROUND_PLAYBACK = false
    const val DEFAULT_AUTO_PLAY = false
    const val DEFAULT_LOOPING = false
    const val DEFAULT_VOLUME = 1.0f
    const val DEFAULT_PLAYBACK_SPEED = 1.0f
    const val DEFAULT_SCALING_MODE = "fit"
    const val DEFAULT_BUFFERING_TIER = "medium"

    /**
     * Extracts allowPip option from map with default.
     */
    fun getAllowPip(options: Map<String, Any>?): Boolean {
        return options?.get("allowPip") as? Boolean ?: DEFAULT_ALLOW_PIP
    }

    /**
     * Extracts autoEnterPipOnBackground option from map with default.
     */
    fun getAutoEnterPipOnBackground(options: Map<String, Any>?): Boolean {
        return options?.get("autoEnterPipOnBackground") as? Boolean ?: DEFAULT_AUTO_ENTER_PIP
    }

    /**
     * Extracts subtitlesEnabled option from map with default.
     */
    fun getSubtitlesEnabled(options: Map<String, Any>?): Boolean {
        return options?.get("subtitlesEnabled") as? Boolean ?: DEFAULT_SUBTITLES_ENABLED
    }

    /**
     * Extracts showSubtitlesByDefault option from map with default.
     */
    fun getShowSubtitlesByDefault(options: Map<String, Any>?): Boolean {
        return options?.get("showSubtitlesByDefault") as? Boolean ?: DEFAULT_SHOW_SUBTITLES_BY_DEFAULT
    }

    /**
     * Extracts preferredSubtitleLanguage option from map (nullable).
     */
    fun getPreferredSubtitleLanguage(options: Map<String, Any>?): String? {
        return options?.get("preferredSubtitleLanguage") as? String
    }

    /**
     * Extracts allowBackgroundPlayback option from map with default.
     */
    fun getAllowBackgroundPlayback(options: Map<String, Any>?): Boolean {
        return options?.get("allowBackgroundPlayback") as? Boolean ?: DEFAULT_ALLOW_BACKGROUND_PLAYBACK
    }

    /**
     * Extracts autoPlay option from map with default.
     */
    fun getAutoPlay(options: Map<String, Any>?): Boolean {
        return options?.get("autoPlay") as? Boolean ?: DEFAULT_AUTO_PLAY
    }

    /**
     * Extracts looping option from map with default.
     */
    fun getLooping(options: Map<String, Any>?): Boolean {
        return options?.get("looping") as? Boolean ?: DEFAULT_LOOPING
    }

    /**
     * Extracts volume option from map with default (clamped to valid range).
     */
    fun getVolume(options: Map<String, Any>?): Float {
        val volume = (options?.get("volume") as? Double)?.toFloat() ?: DEFAULT_VOLUME
        return VideoFormatUtils.clampVolume(volume)
    }

    /**
     * Extracts playbackSpeed option from map with default (clamped to valid range).
     */
    fun getPlaybackSpeed(options: Map<String, Any>?): Float {
        val speed = (options?.get("playbackSpeed") as? Double)?.toFloat() ?: DEFAULT_PLAYBACK_SPEED
        return VideoFormatUtils.clampPlaybackSpeed(speed)
    }

    /**
     * Extracts scalingMode option from map with default and validation.
     */
    fun getScalingMode(options: Map<String, Any>?): String {
        val mode = options?.get("scalingMode") as? String ?: DEFAULT_SCALING_MODE
        return if (VideoFormatUtils.isValidScalingMode(mode)) mode else DEFAULT_SCALING_MODE
    }

    /**
     * Extracts bufferingTier option from map with default and validation.
     */
    fun getBufferingTier(options: Map<String, Any>?): String {
        val tier = options?.get("bufferingTier") as? String ?: DEFAULT_BUFFERING_TIER
        return if (VideoFormatUtils.isValidBufferingTier(tier)) tier else DEFAULT_BUFFERING_TIER
    }
}
