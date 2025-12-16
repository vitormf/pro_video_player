package dev.pro_video_player.android

import androidx.media3.exoplayer.ExoPlayer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.mockito.Mockito.mock

/**
 * Unit tests for MediaPlaybackService static methods.
 *
 * Note: These tests cover the player registration/unregistration logic.
 * Testing the actual foreground service behavior requires instrumented tests
 * on a real device or emulator.
 */
class MediaPlaybackServiceTest {

    private lateinit var mockPlayer1: ExoPlayer
    private lateinit var mockPlayer2: ExoPlayer

    @Before
    fun setUp() {
        mockPlayer1 = mock(ExoPlayer::class.java)
        mockPlayer2 = mock(ExoPlayer::class.java)
        // Clear any existing registrations
        clearAllPlayers()
    }

    @After
    fun tearDown() {
        clearAllPlayers()
    }

    private fun clearAllPlayers() {
        // Unregister all players to ensure clean state
        for (i in 0..10) {
            MediaPlaybackService.unregisterPlayer(i)
        }
    }

    @Test
    fun `hasActivePlayers returns false when no players registered`() {
        assertFalse(MediaPlaybackService.hasActivePlayers())
    }

    @Test
    fun `registerPlayer adds player to registry`() {
        MediaPlaybackService.registerPlayer(1, mockPlayer1)

        assertTrue(MediaPlaybackService.hasActivePlayers())
        assertSame(mockPlayer1, MediaPlaybackService.getPlayer(1))
    }

    @Test
    fun `registerPlayer can register multiple players`() {
        MediaPlaybackService.registerPlayer(1, mockPlayer1)
        MediaPlaybackService.registerPlayer(2, mockPlayer2)

        assertTrue(MediaPlaybackService.hasActivePlayers())
        assertSame(mockPlayer1, MediaPlaybackService.getPlayer(1))
        assertSame(mockPlayer2, MediaPlaybackService.getPlayer(2))
    }

    @Test
    fun `unregisterPlayer removes player from registry`() {
        MediaPlaybackService.registerPlayer(1, mockPlayer1)
        assertTrue(MediaPlaybackService.hasActivePlayers())

        MediaPlaybackService.unregisterPlayer(1)

        assertFalse(MediaPlaybackService.hasActivePlayers())
        assertNull(MediaPlaybackService.getPlayer(1))
    }

    @Test
    fun `unregisterPlayer only removes specified player`() {
        MediaPlaybackService.registerPlayer(1, mockPlayer1)
        MediaPlaybackService.registerPlayer(2, mockPlayer2)

        MediaPlaybackService.unregisterPlayer(1)

        assertTrue(MediaPlaybackService.hasActivePlayers())
        assertNull(MediaPlaybackService.getPlayer(1))
        assertSame(mockPlayer2, MediaPlaybackService.getPlayer(2))
    }

    @Test
    fun `getPlayer returns null for unregistered player ID`() {
        assertNull(MediaPlaybackService.getPlayer(999))
    }

    @Test
    fun `unregisterPlayer is safe to call with non-existent player ID`() {
        // Should not throw
        MediaPlaybackService.unregisterPlayer(999)
        assertFalse(MediaPlaybackService.hasActivePlayers())
    }

    @Test
    fun `registerPlayer overwrites existing registration for same ID`() {
        MediaPlaybackService.registerPlayer(1, mockPlayer1)
        MediaPlaybackService.registerPlayer(1, mockPlayer2)

        assertSame(mockPlayer2, MediaPlaybackService.getPlayer(1))
    }
}
