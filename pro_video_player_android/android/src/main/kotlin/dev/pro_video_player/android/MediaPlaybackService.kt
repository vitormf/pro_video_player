package dev.pro_video_player.android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.core.app.NotificationCompat
import androidx.media3.common.MediaMetadata
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.CommandButton
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import androidx.media3.session.MediaStyleNotificationHelper
import com.google.common.collect.ImmutableList
import java.net.URL
import java.util.concurrent.Executors

/**
 * A foreground service that manages media playback in the background.
 *
 * This service uses Media3's MediaSessionService to:
 * - Keep audio playing when the app is in the background
 * - Show media controls in the notification shade
 * - Integrate with lock screen controls
 * - Support external controllers (Bluetooth, Android Auto, etc.)
 */
@OptIn(UnstableApi::class)
class MediaPlaybackService : MediaSessionService() {

    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "pro_video_player_playback"
        private const val NOTIFICATION_ID = 1001

        // Static reference to players that need background playback
        private val backgroundPlayers = mutableMapOf<Int, ExoPlayer>()
        private val mediaSessions = mutableMapOf<Int, MediaSession>()

        // Media metadata for each player (title, artist, album, artwork)
        private val playerMetadata = mutableMapOf<Int, Map<String, String>>()
        private val playerArtwork = mutableMapOf<Int, Bitmap?>()
        private val executor = Executors.newSingleThreadExecutor()
        private val mainHandler = Handler(Looper.getMainLooper())

        // Callback for when metadata changes (to trigger notification refresh)
        private var metadataChangeCallback: (() -> Unit)? = null

        /**
         * Registers a player for background playback.
         */
        fun registerPlayer(playerId: Int, player: ExoPlayer) {
            backgroundPlayers[playerId] = player
        }

        /**
         * Unregisters a player from background playback.
         */
        fun unregisterPlayer(playerId: Int) {
            mediaSessions[playerId]?.release()
            mediaSessions.remove(playerId)
            backgroundPlayers.remove(playerId)
            playerMetadata.remove(playerId)
            playerArtwork.remove(playerId)
        }

        /**
         * Gets a registered player by ID.
         */
        fun getPlayer(playerId: Int): ExoPlayer? = backgroundPlayers[playerId]

        /**
         * Checks if any players are registered.
         */
        fun hasActivePlayers(): Boolean = backgroundPlayers.isNotEmpty()

        /**
         * Sets metadata for a player.
         */
        fun setMetadata(playerId: Int, metadata: Map<String, String>) {
            playerMetadata[playerId] = metadata

            // Load artwork if URL is provided
            val artworkUrl = metadata["artworkUrl"]
            if (artworkUrl != null) {
                loadArtwork(playerId, artworkUrl)
            } else {
                playerArtwork[playerId] = null
                updateMediaSessionMetadata(playerId)
                metadataChangeCallback?.invoke()
            }
        }

        /**
         * Gets metadata for a player.
         */
        fun getMetadata(playerId: Int): Map<String, String>? = playerMetadata[playerId]

        /**
         * Gets artwork bitmap for a player.
         */
        fun getArtwork(playerId: Int): Bitmap? = playerArtwork[playerId]

        private fun loadArtwork(playerId: Int, url: String) {
            executor.execute {
                try {
                    val inputStream = URL(url).openStream()
                    val bitmap = BitmapFactory.decodeStream(inputStream)
                    inputStream.close()

                    mainHandler.post {
                        playerArtwork[playerId] = bitmap
                        updateMediaSessionMetadata(playerId)
                        metadataChangeCallback?.invoke()
                    }
                } catch (e: Exception) {
                    mainHandler.post {
                        playerArtwork[playerId] = null
                        updateMediaSessionMetadata(playerId)
                        metadataChangeCallback?.invoke()
                    }
                }
            }
        }

        private fun updateMediaSessionMetadata(playerId: Int) {
            val session = mediaSessions[playerId] ?: return
            val metadata = playerMetadata[playerId] ?: return
            val player = backgroundPlayers[playerId] ?: return

            // Build new MediaMetadata
            val metadataBuilder = MediaMetadata.Builder()

            metadata["title"]?.let { metadataBuilder.setTitle(it) }
            metadata["artist"]?.let { metadataBuilder.setArtist(it) }
            metadata["album"]?.let { metadataBuilder.setAlbumTitle(it) }

            playerArtwork[playerId]?.let { bitmap ->
                metadataBuilder.setArtworkData(
                    bitmapToByteArray(bitmap),
                    MediaMetadata.PICTURE_TYPE_FRONT_COVER
                )
            }

            // Update the player's media item metadata
            val currentItem = player.currentMediaItem
            if (currentItem != null) {
                val newItem = currentItem.buildUpon()
                    .setMediaMetadata(metadataBuilder.build())
                    .build()
                player.setMediaItem(newItem, player.currentPosition)
            }
        }

        private fun bitmapToByteArray(bitmap: Bitmap): ByteArray {
            val stream = java.io.ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            return stream.toByteArray()
        }
    }

    private var notificationManager: NotificationManager? = null

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(NotificationManager::class.java)
        createNotificationChannel()

        // Set up callback to refresh notification when metadata changes
        metadataChangeCallback = {
            if (backgroundPlayers.isNotEmpty()) {
                val notification = createNotification()
                notificationManager?.notify(NOTIFICATION_ID, notification)
            }
        }
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? {
        // Return the first available session for external controllers
        return mediaSessions.values.firstOrNull()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val result = super.onStartCommand(intent, flags, startId)

        // Create sessions for any registered players that don't have one yet
        backgroundPlayers.forEach { (playerId, player) ->
            if (!mediaSessions.containsKey(playerId)) {
                val session = MediaSession.Builder(this, player)
                    .setId("pro_video_player_$playerId")
                    .build()
                mediaSessions[playerId] = session
                addSession(session)
            }
        }

        // ALWAYS call startForeground when started as a foreground service.
        // On Android O+, startForegroundService() requires startForeground() to be called
        // within 5 seconds, regardless of whether there are active players.
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // If no active players, stop ourselves to clean up
        if (backgroundPlayers.isEmpty()) {
            stopSelf()
        }

        return result
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Stop playback and service when app is swiped away
        mediaSessions.values.forEach { session ->
            session.player.stop()
        }
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Video Playback",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows playback controls for video"
                setShowBadge(false)
            }
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val session = mediaSessions.values.firstOrNull()

        // Get the first player's metadata and artwork
        val firstPlayerId = backgroundPlayers.keys.firstOrNull()
        val metadata = firstPlayerId?.let { playerMetadata[it] }
        val artwork = firstPlayerId?.let { playerArtwork[it] }

        // Create an intent to open the app when notification is tapped
        val contentIntent = packageManager.getLaunchIntentForPackage(packageName)?.let { intent ->
            PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        // Get title and subtitle from metadata or use defaults
        val title = metadata?.get("title") ?: "Video Playing"
        val subtitle = metadata?.get("artist") ?: metadata?.get("album") ?: "Tap to return to app"

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)

        // Add artwork if available
        if (artwork != null) {
            builder.setLargeIcon(artwork)
        }

        // Add media style if we have a session
        if (session != null) {
            builder.setStyle(
                MediaStyleNotificationHelper.MediaStyle(session)
                    .setShowActionsInCompactView(0, 1, 2)
            )
        }

        return builder.build()
    }

    override fun onDestroy() {
        metadataChangeCallback = null
        // Release all sessions
        mediaSessions.values.forEach { session ->
            session.release()
        }
        mediaSessions.clear()
        backgroundPlayers.clear()
        playerMetadata.clear()
        playerArtwork.clear()
        super.onDestroy()
    }
}
