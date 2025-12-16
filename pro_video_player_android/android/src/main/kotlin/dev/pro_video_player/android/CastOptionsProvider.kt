package dev.pro_video_player.android

import android.content.Context
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.CastMediaOptions
import com.google.android.gms.cast.framework.media.MediaIntentReceiver
import com.google.android.gms.cast.framework.media.NotificationOptions

/**
 * CastOptionsProvider for Google Cast SDK initialization.
 *
 * This class is automatically discovered and instantiated by the Cast SDK.
 * It provides the configuration for Cast functionality.
 */
class CastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions {
        // Use the default receiver app ID for now
        // Developers can customize this in their app's strings.xml with:
        //   <string name="cast_receiver_app_id">YOUR_APP_ID</string>
        val receiverAppId = try {
            val resId = context.resources.getIdentifier(
                "cast_receiver_app_id",
                "string",
                context.packageName
            )
            if (resId != 0) context.getString(resId).takeIf { it.isNotEmpty() } else null
        } catch (e: Exception) {
            null
        } ?: "CC1AD845" // Default Media Receiver application ID

        // Configure notification options for Cast
        val notificationOptions = NotificationOptions.Builder()
            .setActions(
                listOf(
                    MediaIntentReceiver.ACTION_TOGGLE_PLAYBACK,
                    MediaIntentReceiver.ACTION_STOP_CASTING
                ),
                intArrayOf(0, 1)
            )
            .build()

        val mediaOptions = CastMediaOptions.Builder()
            .setNotificationOptions(notificationOptions)
            .setExpandedControllerActivityClassName("com.google.android.gms.cast.framework.media.widget.ExpandedControllerActivity")
            .build()

        return CastOptions.Builder()
            .setReceiverApplicationId(receiverAppId)
            .setCastMediaOptions(mediaOptions)
            .build()
    }

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
        return null
    }
}
