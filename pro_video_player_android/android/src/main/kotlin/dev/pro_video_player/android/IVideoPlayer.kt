package dev.pro_video_player.android

/**
 * Interface for video player operations.
 * This abstraction makes the code more testable by allowing mock implementations.
 */
interface IVideoPlayer {
    fun play()
    fun pause()
    fun stop()
    fun seekTo(position: Long)
    fun setPlaybackSpeed(speed: Float)
    fun setVolume(volume: Float)
    fun setLooping(looping: Boolean)
    fun setScalingMode(mode: String)
    fun setSubtitleTrack(track: Map<String, Any>?)
    fun getPosition(): Long
    fun getDuration(): Long
    fun dispose()
    fun isPipAllowed(): Boolean
    fun areSubtitlesEnabled(): Boolean
    fun getVideoMetadata(): Map<String, Any?>?
    fun isPlaying(): Boolean
    fun allowsBackgroundPlayback(): Boolean

    // Casting methods
    fun isCastingSupported(): Boolean
    fun getAvailableCastDevices(): List<Map<String, Any>>
    fun startCasting(device: Map<String, Any>): Boolean
    fun stopCasting(): Boolean
    fun getCastState(): String
    fun getCurrentCastDevice(): Map<String, Any>?
}
