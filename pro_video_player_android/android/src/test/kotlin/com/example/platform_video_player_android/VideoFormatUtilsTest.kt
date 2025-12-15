package com.example.pro_video_player_android

import org.junit.Assert.*
import org.junit.Test

/**
 * Unit tests for VideoFormatUtils.
 *
 * These tests cover all pure functions in VideoFormatUtils and run on the JVM
 * without requiring Android dependencies.
 */
class VideoFormatUtilsTest {

    // ==================== getMimeTypeCodec Tests ====================

    @Test
    fun `getMimeTypeCodec returns h264 for video avc`() {
        assertEquals("h264", VideoFormatUtils.getMimeTypeCodec("video/avc"))
    }

    @Test
    fun `getMimeTypeCodec returns hevc for video hevc`() {
        assertEquals("hevc", VideoFormatUtils.getMimeTypeCodec("video/hevc"))
    }

    @Test
    fun `getMimeTypeCodec returns mpeg4 for video mp4v-es`() {
        assertEquals("mpeg4", VideoFormatUtils.getMimeTypeCodec("video/mp4v-es"))
    }

    @Test
    fun `getMimeTypeCodec returns h263 for video 3gpp`() {
        assertEquals("h263", VideoFormatUtils.getMimeTypeCodec("video/3gpp"))
    }

    @Test
    fun `getMimeTypeCodec returns vp8 for video x-vnd on2 vp8`() {
        assertEquals("vp8", VideoFormatUtils.getMimeTypeCodec("video/x-vnd.on2.vp8"))
    }

    @Test
    fun `getMimeTypeCodec returns vp9 for video x-vnd on2 vp9`() {
        assertEquals("vp9", VideoFormatUtils.getMimeTypeCodec("video/x-vnd.on2.vp9"))
    }

    @Test
    fun `getMimeTypeCodec returns av1 for video av01`() {
        assertEquals("av1", VideoFormatUtils.getMimeTypeCodec("video/av01"))
    }

    @Test
    fun `getMimeTypeCodec returns aac for audio mp4a-latm`() {
        assertEquals("aac", VideoFormatUtils.getMimeTypeCodec("audio/mp4a-latm"))
    }

    @Test
    fun `getMimeTypeCodec returns mp3 for audio mpeg`() {
        assertEquals("mp3", VideoFormatUtils.getMimeTypeCodec("audio/mpeg"))
    }

    @Test
    fun `getMimeTypeCodec returns vorbis for audio vorbis`() {
        assertEquals("vorbis", VideoFormatUtils.getMimeTypeCodec("audio/vorbis"))
    }

    @Test
    fun `getMimeTypeCodec returns opus for audio opus`() {
        assertEquals("opus", VideoFormatUtils.getMimeTypeCodec("audio/opus"))
    }

    @Test
    fun `getMimeTypeCodec returns ac3 for audio ac-3`() {
        assertEquals("ac3", VideoFormatUtils.getMimeTypeCodec("audio/ac-3"))
    }

    @Test
    fun `getMimeTypeCodec returns eac3 for audio eac3`() {
        assertEquals("eac3", VideoFormatUtils.getMimeTypeCodec("audio/eac3"))
    }

    @Test
    fun `getMimeTypeCodec returns flac for audio flac`() {
        assertEquals("flac", VideoFormatUtils.getMimeTypeCodec("audio/flac"))
    }

    @Test
    fun `getMimeTypeCodec returns fallback for unknown mime type`() {
        assertEquals("unknown", VideoFormatUtils.getMimeTypeCodec("video/unknown"))
        assertEquals("x-custom", VideoFormatUtils.getMimeTypeCodec("audio/x-custom"))
    }

    @Test
    fun `getMimeTypeCodec returns null for null input`() {
        assertNull(VideoFormatUtils.getMimeTypeCodec(null))
    }

    // ==================== getContainerFormat Tests ====================

    @Test
    fun `getContainerFormat returns mp4 for mp4 extension`() {
        assertEquals("mp4", VideoFormatUtils.getContainerFormat("https://example.com/video.mp4"))
        assertEquals("mp4", VideoFormatUtils.getContainerFormat("file:///path/to/video.MP4"))
    }

    @Test
    fun `getContainerFormat returns matroska for mkv extension`() {
        assertEquals("matroska", VideoFormatUtils.getContainerFormat("https://example.com/video.mkv"))
        assertEquals("matroska", VideoFormatUtils.getContainerFormat("/path/to/video.MKV"))
    }

    @Test
    fun `getContainerFormat returns webm for webm extension`() {
        assertEquals("webm", VideoFormatUtils.getContainerFormat("https://example.com/video.webm"))
    }

    @Test
    fun `getContainerFormat returns hls for m3u8 extension`() {
        assertEquals("hls", VideoFormatUtils.getContainerFormat("https://example.com/stream.m3u8"))
        assertEquals("hls", VideoFormatUtils.getContainerFormat("https://cdn.example.com/live/playlist.M3U8"))
    }

    @Test
    fun `getContainerFormat returns dash for mpd extension`() {
        assertEquals("dash", VideoFormatUtils.getContainerFormat("https://example.com/manifest.mpd"))
    }

    @Test
    fun `getContainerFormat returns 3gp for 3gp extension`() {
        assertEquals("3gp", VideoFormatUtils.getContainerFormat("/path/to/video.3gp"))
    }

    @Test
    fun `getContainerFormat returns avi for avi extension`() {
        assertEquals("avi", VideoFormatUtils.getContainerFormat("https://example.com/video.avi"))
    }

    @Test
    fun `getContainerFormat returns quicktime for mov extension`() {
        assertEquals("quicktime", VideoFormatUtils.getContainerFormat("https://example.com/video.mov"))
    }

    @Test
    fun `getContainerFormat returns flash for flv extension`() {
        assertEquals("flash", VideoFormatUtils.getContainerFormat("https://example.com/video.flv"))
    }

    @Test
    fun `getContainerFormat returns mpegts for ts extension`() {
        assertEquals("mpegts", VideoFormatUtils.getContainerFormat("https://example.com/segment.ts"))
    }

    @Test
    fun `getContainerFormat returns mp4 for m4v extension`() {
        assertEquals("mp4", VideoFormatUtils.getContainerFormat("https://example.com/video.m4v"))
    }

    @Test
    fun `getContainerFormat returns mp4 for m4a extension`() {
        assertEquals("mp4", VideoFormatUtils.getContainerFormat("https://example.com/audio.m4a"))
    }

    @Test
    fun `getContainerFormat returns mp3 for mp3 extension`() {
        assertEquals("mp3", VideoFormatUtils.getContainerFormat("https://example.com/audio.mp3"))
    }

    @Test
    fun `getContainerFormat returns ogg for ogg extension`() {
        assertEquals("ogg", VideoFormatUtils.getContainerFormat("https://example.com/audio.ogg"))
        assertEquals("ogg", VideoFormatUtils.getContainerFormat("https://example.com/video.ogv"))
    }

    @Test
    fun `getContainerFormat returns wav for wav extension`() {
        assertEquals("wav", VideoFormatUtils.getContainerFormat("https://example.com/audio.wav"))
    }

    @Test
    fun `getContainerFormat handles query parameters`() {
        assertEquals("mp4", VideoFormatUtils.getContainerFormat("https://example.com/video.mp4?token=abc123"))
        assertEquals("hls", VideoFormatUtils.getContainerFormat("https://example.com/stream.m3u8?quality=hd"))
    }

    @Test
    fun `getContainerFormat handles fragments`() {
        assertEquals("mp4", VideoFormatUtils.getContainerFormat("https://example.com/video.mp4#t=10"))
    }

    @Test
    fun `getContainerFormat handles query parameters and fragments`() {
        assertEquals("mp4", VideoFormatUtils.getContainerFormat("https://example.com/video.mp4?token=abc#t=10"))
    }

    @Test
    fun `getContainerFormat returns null for unknown extension`() {
        assertNull(VideoFormatUtils.getContainerFormat("https://example.com/video.xyz"))
        assertNull(VideoFormatUtils.getContainerFormat("https://example.com/video"))
    }

    @Test
    fun `getContainerFormat returns null for null input`() {
        assertNull(VideoFormatUtils.getContainerFormat(null))
    }

    @Test
    fun `getContainerFormat is case insensitive`() {
        assertEquals("mp4", VideoFormatUtils.getContainerFormat("https://example.com/video.MP4"))
        assertEquals("hls", VideoFormatUtils.getContainerFormat("https://example.com/stream.M3U8"))
        assertEquals("matroska", VideoFormatUtils.getContainerFormat("https://example.com/video.MkV"))
    }

    // ==================== parseTrackId Tests ====================

    @Test
    fun `parseTrackId returns correct values for valid input`() {
        val result = VideoFormatUtils.parseTrackId("0:1")
        assertNotNull(result)
        assertEquals(0, result?.first)
        assertEquals(1, result?.second)
    }

    @Test
    fun `parseTrackId handles larger indices`() {
        val result = VideoFormatUtils.parseTrackId("10:25")
        assertNotNull(result)
        assertEquals(10, result?.first)
        assertEquals(25, result?.second)
    }

    @Test
    fun `parseTrackId returns null for invalid format`() {
        assertNull(VideoFormatUtils.parseTrackId("invalid"))
        assertNull(VideoFormatUtils.parseTrackId("0"))
        assertNull(VideoFormatUtils.parseTrackId("0:1:2"))
        assertNull(VideoFormatUtils.parseTrackId(":1"))
        assertNull(VideoFormatUtils.parseTrackId("0:"))
    }

    @Test
    fun `parseTrackId returns null for non-numeric values`() {
        assertNull(VideoFormatUtils.parseTrackId("a:b"))
        assertNull(VideoFormatUtils.parseTrackId("0:b"))
        assertNull(VideoFormatUtils.parseTrackId("a:1"))
    }

    @Test
    fun `parseTrackId returns null for null input`() {
        assertNull(VideoFormatUtils.parseTrackId(null))
    }

    @Test
    fun `parseTrackId returns null for empty string`() {
        assertNull(VideoFormatUtils.parseTrackId(""))
    }

    // ==================== createTrackId Tests ====================

    @Test
    fun `createTrackId returns correct format`() {
        assertEquals("0:0", VideoFormatUtils.createTrackId(0, 0))
        assertEquals("0:1", VideoFormatUtils.createTrackId(0, 1))
        assertEquals("1:0", VideoFormatUtils.createTrackId(1, 0))
        assertEquals("10:25", VideoFormatUtils.createTrackId(10, 25))
    }

    @Test
    fun `createTrackId roundtrips with parseTrackId`() {
        val trackId = VideoFormatUtils.createTrackId(5, 3)
        val parsed = VideoFormatUtils.parseTrackId(trackId)
        assertNotNull(parsed)
        assertEquals(5, parsed?.first)
        assertEquals(3, parsed?.second)
    }

    // ==================== isValidPlaybackSpeed Tests ====================

    @Test
    fun `isValidPlaybackSpeed returns true for valid speeds`() {
        assertTrue(VideoFormatUtils.isValidPlaybackSpeed(0.25f))
        assertTrue(VideoFormatUtils.isValidPlaybackSpeed(0.5f))
        assertTrue(VideoFormatUtils.isValidPlaybackSpeed(1.0f))
        assertTrue(VideoFormatUtils.isValidPlaybackSpeed(1.5f))
        assertTrue(VideoFormatUtils.isValidPlaybackSpeed(2.0f))
        assertTrue(VideoFormatUtils.isValidPlaybackSpeed(4.0f))
    }

    @Test
    fun `isValidPlaybackSpeed returns false for too slow speeds`() {
        assertFalse(VideoFormatUtils.isValidPlaybackSpeed(0.0f))
        assertFalse(VideoFormatUtils.isValidPlaybackSpeed(0.1f))
        assertFalse(VideoFormatUtils.isValidPlaybackSpeed(0.24f))
        assertFalse(VideoFormatUtils.isValidPlaybackSpeed(-1.0f))
    }

    @Test
    fun `isValidPlaybackSpeed returns false for too fast speeds`() {
        assertFalse(VideoFormatUtils.isValidPlaybackSpeed(4.1f))
        assertFalse(VideoFormatUtils.isValidPlaybackSpeed(5.0f))
        assertFalse(VideoFormatUtils.isValidPlaybackSpeed(10.0f))
    }

    // ==================== isValidVolume Tests ====================

    @Test
    fun `isValidVolume returns true for valid volumes`() {
        assertTrue(VideoFormatUtils.isValidVolume(0.0f))
        assertTrue(VideoFormatUtils.isValidVolume(0.5f))
        assertTrue(VideoFormatUtils.isValidVolume(1.0f))
    }

    @Test
    fun `isValidVolume returns false for negative volumes`() {
        assertFalse(VideoFormatUtils.isValidVolume(-0.1f))
        assertFalse(VideoFormatUtils.isValidVolume(-1.0f))
    }

    @Test
    fun `isValidVolume returns false for volumes over 1`() {
        assertFalse(VideoFormatUtils.isValidVolume(1.1f))
        assertFalse(VideoFormatUtils.isValidVolume(2.0f))
    }

    // ==================== isValidSeekPosition Tests ====================

    @Test
    fun `isValidSeekPosition returns true for valid positions`() {
        assertTrue(VideoFormatUtils.isValidSeekPosition(0))
        assertTrue(VideoFormatUtils.isValidSeekPosition(1000))
        assertTrue(VideoFormatUtils.isValidSeekPosition(Long.MAX_VALUE))
    }

    @Test
    fun `isValidSeekPosition returns false for negative positions`() {
        assertFalse(VideoFormatUtils.isValidSeekPosition(-1))
        assertFalse(VideoFormatUtils.isValidSeekPosition(-1000))
    }

    @Test
    fun `isValidSeekPosition respects duration when provided`() {
        assertTrue(VideoFormatUtils.isValidSeekPosition(0, 10000))
        assertTrue(VideoFormatUtils.isValidSeekPosition(5000, 10000))
        assertTrue(VideoFormatUtils.isValidSeekPosition(10000, 10000))
        assertFalse(VideoFormatUtils.isValidSeekPosition(10001, 10000))
    }

    // ==================== getQualityLabel Tests ====================

    @Test
    fun `getQualityLabel returns 4K for 2160p and above`() {
        assertEquals("4K", VideoFormatUtils.getQualityLabel(2160))
        assertEquals("4K", VideoFormatUtils.getQualityLabel(2880))
    }

    @Test
    fun `getQualityLabel returns 1440p for 1440p`() {
        assertEquals("1440p", VideoFormatUtils.getQualityLabel(1440))
    }

    @Test
    fun `getQualityLabel returns 1080p for 1080p`() {
        assertEquals("1080p", VideoFormatUtils.getQualityLabel(1080))
    }

    @Test
    fun `getQualityLabel returns 720p for 720p`() {
        assertEquals("720p", VideoFormatUtils.getQualityLabel(720))
    }

    @Test
    fun `getQualityLabel returns 480p for 480p`() {
        assertEquals("480p", VideoFormatUtils.getQualityLabel(480))
    }

    @Test
    fun `getQualityLabel returns 360p for 360p`() {
        assertEquals("360p", VideoFormatUtils.getQualityLabel(360))
    }

    @Test
    fun `getQualityLabel returns 240p for 240p`() {
        assertEquals("240p", VideoFormatUtils.getQualityLabel(240))
    }

    @Test
    fun `getQualityLabel returns 144p for 144p`() {
        assertEquals("144p", VideoFormatUtils.getQualityLabel(144))
    }

    @Test
    fun `getQualityLabel returns custom height for non-standard resolutions`() {
        assertEquals("100p", VideoFormatUtils.getQualityLabel(100))
    }

    @Test
    fun `getQualityLabel includes frame rate for high frame rate content`() {
        assertEquals("1080p60", VideoFormatUtils.getQualityLabel(1080, 60f))
        assertEquals("720p50", VideoFormatUtils.getQualityLabel(720, 50f))
        assertEquals("4K60", VideoFormatUtils.getQualityLabel(2160, 60f))
    }

    @Test
    fun `getQualityLabel omits frame rate for standard frame rates`() {
        assertEquals("1080p", VideoFormatUtils.getQualityLabel(1080, 24f))
        assertEquals("1080p", VideoFormatUtils.getQualityLabel(1080, 25f))
        assertEquals("1080p", VideoFormatUtils.getQualityLabel(1080, 30f))
    }

    @Test
    fun `getQualityLabel omits frame rate when null`() {
        assertEquals("1080p", VideoFormatUtils.getQualityLabel(1080, null))
    }

    // ==================== formatBitrate Tests ====================

    @Test
    fun `formatBitrate returns Mbps for large bitrates`() {
        assertEquals("5.0 Mbps", VideoFormatUtils.formatBitrate(5_000_000))
        assertEquals("10.5 Mbps", VideoFormatUtils.formatBitrate(10_500_000))
        assertEquals("1.0 Mbps", VideoFormatUtils.formatBitrate(1_000_000))
    }

    @Test
    fun `formatBitrate returns Kbps for medium bitrates`() {
        assertEquals("800 Kbps", VideoFormatUtils.formatBitrate(800_000))
        assertEquals("128 Kbps", VideoFormatUtils.formatBitrate(128_000))
        assertEquals("1 Kbps", VideoFormatUtils.formatBitrate(1_000))
    }

    @Test
    fun `formatBitrate returns bps for small bitrates`() {
        assertEquals("500 bps", VideoFormatUtils.formatBitrate(500))
        assertEquals("0 bps", VideoFormatUtils.formatBitrate(0))
    }

    // ==================== formatDuration Tests ====================

    @Test
    fun `formatDuration formats short durations correctly`() {
        assertEquals("0:00", VideoFormatUtils.formatDuration(0))
        assertEquals("0:01", VideoFormatUtils.formatDuration(1000))
        assertEquals("0:59", VideoFormatUtils.formatDuration(59_000))
    }

    @Test
    fun `formatDuration formats minutes correctly`() {
        assertEquals("1:00", VideoFormatUtils.formatDuration(60_000))
        assertEquals("5:30", VideoFormatUtils.formatDuration(330_000))
        assertEquals("59:59", VideoFormatUtils.formatDuration(3599_000))
    }

    @Test
    fun `formatDuration formats hours correctly`() {
        assertEquals("1:00:00", VideoFormatUtils.formatDuration(3600_000))
        assertEquals("1:23:45", VideoFormatUtils.formatDuration(5025_000))
        assertEquals("10:00:00", VideoFormatUtils.formatDuration(36000_000))
    }

    @Test
    fun `formatDuration handles negative values`() {
        assertEquals("0:00", VideoFormatUtils.formatDuration(-1000))
    }

    @Test
    fun `formatDuration pads minutes and seconds with zeros`() {
        assertEquals("1:01:01", VideoFormatUtils.formatDuration(3661_000))
        assertEquals("1:05", VideoFormatUtils.formatDuration(65_000))
    }

    // ==================== calculateExponentialBackoff Tests ====================

    @Test
    fun `calculateExponentialBackoff returns base delay for retry 0`() {
        assertEquals(1000L, VideoFormatUtils.calculateExponentialBackoff(0))
        assertEquals(500L, VideoFormatUtils.calculateExponentialBackoff(0, baseDelayMs = 500L))
    }

    @Test
    fun `calculateExponentialBackoff doubles delay with each retry`() {
        assertEquals(1000L, VideoFormatUtils.calculateExponentialBackoff(0))  // 2^0 * 1000 = 1000
        assertEquals(2000L, VideoFormatUtils.calculateExponentialBackoff(1))  // 2^1 * 1000 = 2000
        assertEquals(4000L, VideoFormatUtils.calculateExponentialBackoff(2))  // 2^2 * 1000 = 4000
        assertEquals(8000L, VideoFormatUtils.calculateExponentialBackoff(3))  // 2^3 * 1000 = 8000
        assertEquals(16000L, VideoFormatUtils.calculateExponentialBackoff(4)) // 2^4 * 1000 = 16000
    }

    @Test
    fun `calculateExponentialBackoff caps at max delay`() {
        assertEquals(30000L, VideoFormatUtils.calculateExponentialBackoff(5))  // 32000 -> capped at 30000
        assertEquals(30000L, VideoFormatUtils.calculateExponentialBackoff(10)) // way over -> capped
    }

    @Test
    fun `calculateExponentialBackoff respects custom max delay`() {
        assertEquals(10000L, VideoFormatUtils.calculateExponentialBackoff(4, maxDelayMs = 10000L))
        assertEquals(5000L, VideoFormatUtils.calculateExponentialBackoff(10, maxDelayMs = 5000L))
    }

    @Test
    fun `calculateExponentialBackoff handles negative retry count`() {
        assertEquals(1000L, VideoFormatUtils.calculateExponentialBackoff(-1))
        assertEquals(500L, VideoFormatUtils.calculateExponentialBackoff(-5, baseDelayMs = 500L))
    }

    @Test
    fun `calculateExponentialBackoff with custom base delay`() {
        assertEquals(2000L, VideoFormatUtils.calculateExponentialBackoff(0, baseDelayMs = 2000L))
        assertEquals(4000L, VideoFormatUtils.calculateExponentialBackoff(1, baseDelayMs = 2000L))
    }

    // ==================== calculateAspectRatio Tests ====================

    @Test
    fun `calculateAspectRatio returns 16 9 for 1920x1080`() {
        val result = VideoFormatUtils.calculateAspectRatio(1920, 1080)
        assertEquals(16, result.first)
        assertEquals(9, result.second)
    }

    @Test
    fun `calculateAspectRatio returns 16 9 for 1280x720`() {
        val result = VideoFormatUtils.calculateAspectRatio(1280, 720)
        assertEquals(16, result.first)
        assertEquals(9, result.second)
    }

    @Test
    fun `calculateAspectRatio returns 4 3 for 640x480`() {
        val result = VideoFormatUtils.calculateAspectRatio(640, 480)
        assertEquals(4, result.first)
        assertEquals(3, result.second)
    }

    @Test
    fun `calculateAspectRatio returns 1 1 for square video`() {
        val result = VideoFormatUtils.calculateAspectRatio(1080, 1080)
        assertEquals(1, result.first)
        assertEquals(1, result.second)
    }

    @Test
    fun `calculateAspectRatio returns default for zero dimensions`() {
        val result = VideoFormatUtils.calculateAspectRatio(0, 0)
        assertEquals(16, result.first)
        assertEquals(9, result.second)
    }

    @Test
    fun `calculateAspectRatio returns default for zero width`() {
        val result = VideoFormatUtils.calculateAspectRatio(0, 1080)
        assertEquals(16, result.first)
        assertEquals(9, result.second)
    }

    @Test
    fun `calculateAspectRatio returns default for zero height`() {
        val result = VideoFormatUtils.calculateAspectRatio(1920, 0)
        assertEquals(16, result.first)
        assertEquals(9, result.second)
    }

    @Test
    fun `calculateAspectRatio returns default for negative dimensions`() {
        val result = VideoFormatUtils.calculateAspectRatio(-1920, -1080)
        assertEquals(16, result.first)
        assertEquals(9, result.second)
    }

    @Test
    fun `calculateAspectRatio reduces non-standard ratios`() {
        // 2560x1600 should reduce to 8:5
        val result = VideoFormatUtils.calculateAspectRatio(2560, 1600)
        assertEquals(8, result.first)
        assertEquals(5, result.second)
    }

    // ==================== shouldUpdatePosition Tests ====================

    @Test
    fun `shouldUpdatePosition returns true when change exceeds threshold`() {
        assertTrue(VideoFormatUtils.shouldUpdatePosition(1000, 0))        // 1000ms change
        assertTrue(VideoFormatUtils.shouldUpdatePosition(200, 0))         // 200ms change
        assertTrue(VideoFormatUtils.shouldUpdatePosition(100, 0))         // exactly at threshold
    }

    @Test
    fun `shouldUpdatePosition returns false when change below threshold`() {
        assertFalse(VideoFormatUtils.shouldUpdatePosition(50, 0))        // 50ms change
        assertFalse(VideoFormatUtils.shouldUpdatePosition(99, 0))        // 99ms change
        assertFalse(VideoFormatUtils.shouldUpdatePosition(1000, 1000))   // no change
    }

    @Test
    fun `shouldUpdatePosition works with negative differences`() {
        assertTrue(VideoFormatUtils.shouldUpdatePosition(0, 1000))        // -1000ms change
        assertFalse(VideoFormatUtils.shouldUpdatePosition(950, 1000))     // -50ms change
    }

    @Test
    fun `shouldUpdatePosition respects custom threshold`() {
        assertTrue(VideoFormatUtils.shouldUpdatePosition(500, 0, thresholdMs = 500))
        assertFalse(VideoFormatUtils.shouldUpdatePosition(499, 0, thresholdMs = 500))
    }

    // ==================== shouldUpdateBandwidth Tests ====================

    @Test
    fun `shouldUpdateBandwidth returns true for first update`() {
        assertTrue(VideoFormatUtils.shouldUpdateBandwidth(5_000_000, 0))
        assertTrue(VideoFormatUtils.shouldUpdateBandwidth(5_000_000, -1))
    }

    @Test
    fun `shouldUpdateBandwidth returns false for zero current bandwidth`() {
        assertFalse(VideoFormatUtils.shouldUpdateBandwidth(0, 5_000_000))
        assertFalse(VideoFormatUtils.shouldUpdateBandwidth(-1, 5_000_000))
    }

    @Test
    fun `shouldUpdateBandwidth returns true when change exceeds 10 percent`() {
        // 10% of 10_000_000 = 1_000_000
        assertTrue(VideoFormatUtils.shouldUpdateBandwidth(11_500_000, 10_000_000))  // 15% increase
        assertTrue(VideoFormatUtils.shouldUpdateBandwidth(8_500_000, 10_000_000))   // 15% decrease
    }

    @Test
    fun `shouldUpdateBandwidth returns false when change below 10 percent`() {
        // 10% of 10_000_000 = 1_000_000
        assertFalse(VideoFormatUtils.shouldUpdateBandwidth(10_500_000, 10_000_000)) // 5% increase
        assertFalse(VideoFormatUtils.shouldUpdateBandwidth(9_500_000, 10_000_000))  // 5% decrease
    }

    @Test
    fun `shouldUpdateBandwidth respects custom threshold`() {
        // With 20% threshold, 10% change should return false
        assertFalse(VideoFormatUtils.shouldUpdateBandwidth(11_000_000, 10_000_000, changeThreshold = 0.2))
        // With 5% threshold, 10% change should return true
        assertTrue(VideoFormatUtils.shouldUpdateBandwidth(11_000_000, 10_000_000, changeThreshold = 0.05))
    }

    // ==================== isNetworkErrorCode Tests ====================

    @Test
    fun `isNetworkErrorCode returns true for network connection failed`() {
        assertTrue(VideoFormatUtils.isNetworkErrorCode(2001))
    }

    @Test
    fun `isNetworkErrorCode returns true for network connection timeout`() {
        assertTrue(VideoFormatUtils.isNetworkErrorCode(2002))
    }

    @Test
    fun `isNetworkErrorCode returns true for IO unspecified`() {
        assertTrue(VideoFormatUtils.isNetworkErrorCode(2000))
    }

    @Test
    fun `isNetworkErrorCode returns false for non-network errors`() {
        assertFalse(VideoFormatUtils.isNetworkErrorCode(1000))   // ERROR_CODE_UNSPECIFIED
        assertFalse(VideoFormatUtils.isNetworkErrorCode(1001))   // ERROR_CODE_REMOTE_ERROR
        assertFalse(VideoFormatUtils.isNetworkErrorCode(3000))   // ERROR_CODE_PARSING_CONTAINER
        assertFalse(VideoFormatUtils.isNetworkErrorCode(4000))   // ERROR_CODE_DECODER
        assertFalse(VideoFormatUtils.isNetworkErrorCode(0))
        assertFalse(VideoFormatUtils.isNetworkErrorCode(-1))
    }

    // ==================== getPollingInterval Tests ====================

    @Test
    fun `getPollingInterval returns playing interval when playing`() {
        assertEquals(500L, VideoFormatUtils.getPollingInterval(true))
    }

    @Test
    fun `getPollingInterval returns paused interval when not playing`() {
        assertEquals(1000L, VideoFormatUtils.getPollingInterval(false))
    }

    @Test
    fun `getPollingInterval respects custom intervals`() {
        assertEquals(250L, VideoFormatUtils.getPollingInterval(true, playingIntervalMs = 250L))
        assertEquals(2000L, VideoFormatUtils.getPollingInterval(false, pausedIntervalMs = 2000L))
    }

    // ==================== calculateSkipPosition Tests ====================

    @Test
    fun `calculateSkipPosition moves forward correctly`() {
        assertEquals(15000L, VideoFormatUtils.calculateSkipPosition(5000L, 10000L, 60000L))
    }

    @Test
    fun `calculateSkipPosition moves backward correctly`() {
        assertEquals(5000L, VideoFormatUtils.calculateSkipPosition(15000L, -10000L, 60000L))
    }

    @Test
    fun `calculateSkipPosition clamps to zero when skipping before start`() {
        assertEquals(0L, VideoFormatUtils.calculateSkipPosition(5000L, -10000L, 60000L))
    }

    @Test
    fun `calculateSkipPosition clamps to duration when skipping past end`() {
        assertEquals(60000L, VideoFormatUtils.calculateSkipPosition(55000L, 10000L, 60000L))
    }

    @Test
    fun `calculateSkipPosition handles zero duration`() {
        // When duration is 0 or negative, don't clamp to it
        assertEquals(15000L, VideoFormatUtils.calculateSkipPosition(5000L, 10000L, 0L))
    }

    @Test
    fun `calculateSkipPosition handles negative duration gracefully`() {
        assertEquals(15000L, VideoFormatUtils.calculateSkipPosition(5000L, 10000L, -1L))
    }

    // ==================== getBufferingReason Tests ====================

    @Test
    fun `getBufferingReason returns initial for idle state`() {
        assertEquals("initial", VideoFormatUtils.getBufferingReason(1))  // STATE_IDLE
    }

    @Test
    fun `getBufferingReason returns initial when isIdle true`() {
        assertEquals("initial", VideoFormatUtils.getBufferingReason(3, isIdle = true))
    }

    @Test
    fun `getBufferingReason returns networkUnstable for non-idle states`() {
        assertEquals("networkUnstable", VideoFormatUtils.getBufferingReason(2))  // STATE_BUFFERING
        assertEquals("networkUnstable", VideoFormatUtils.getBufferingReason(3))  // STATE_READY
        assertEquals("networkUnstable", VideoFormatUtils.getBufferingReason(4))  // STATE_ENDED
    }

    // ==================== detectSubtitleFormat Tests ====================

    @Test
    fun `detectSubtitleFormat returns srt for srt extension`() {
        assertEquals("srt", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.srt"))
        assertEquals("srt", VideoFormatUtils.detectSubtitleFormat("file:///path/to/subtitles.SRT"))
    }

    @Test
    fun `detectSubtitleFormat returns vtt for vtt extension`() {
        assertEquals("vtt", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.vtt"))
        assertEquals("vtt", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.VTT"))
    }

    @Test
    fun `detectSubtitleFormat returns ssa for ssa extension`() {
        assertEquals("ssa", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.ssa"))
        assertEquals("ssa", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.SSA"))
    }

    @Test
    fun `detectSubtitleFormat returns ass for ass extension`() {
        assertEquals("ass", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.ass"))
        assertEquals("ass", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.ASS"))
    }

    @Test
    fun `detectSubtitleFormat returns ttml for ttml extension`() {
        assertEquals("ttml", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.ttml"))
        assertEquals("ttml", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.TTML"))
    }

    @Test
    fun `detectSubtitleFormat returns ttml for xml extension`() {
        assertEquals("ttml", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.xml"))
        assertEquals("ttml", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.XML"))
    }

    @Test
    fun `detectSubtitleFormat returns srt as default for unknown extensions`() {
        assertEquals("srt", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.txt"))
        assertEquals("srt", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.sub"))
        assertEquals("srt", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles"))
    }

    @Test
    fun `detectSubtitleFormat returns srt for null input`() {
        assertEquals("srt", VideoFormatUtils.detectSubtitleFormat(null))
    }

    @Test
    fun `detectSubtitleFormat handles URLs with query parameters`() {
        assertEquals("srt", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.srt?token=abc"))
        assertEquals("vtt", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.vtt?token=xyz"))
    }

    @Test
    fun `detectSubtitleFormat is case insensitive`() {
        assertEquals("srt", VideoFormatUtils.detectSubtitleFormat("https://example.com/SUBTITLES.SRT"))
        assertEquals("vtt", VideoFormatUtils.detectSubtitleFormat("https://example.com/Subtitles.Vtt"))
        assertEquals("ass", VideoFormatUtils.detectSubtitleFormat("https://example.com/subtitles.AsS"))
    }

    // ==================== getCastStateString Tests ====================

    @Test
    fun `getCastStateString returns noDevices for NO_DEVICES_AVAILABLE`() {
        assertEquals("noDevices", VideoFormatUtils.getCastStateString(VideoFormatUtils.CAST_STATE_NO_DEVICES_AVAILABLE))
    }

    @Test
    fun `getCastStateString returns notConnected for NOT_CONNECTED`() {
        assertEquals("notConnected", VideoFormatUtils.getCastStateString(VideoFormatUtils.CAST_STATE_NOT_CONNECTED))
    }

    @Test
    fun `getCastStateString returns connecting for CONNECTING`() {
        assertEquals("connecting", VideoFormatUtils.getCastStateString(VideoFormatUtils.CAST_STATE_CONNECTING))
    }

    @Test
    fun `getCastStateString returns connected for CONNECTED`() {
        assertEquals("connected", VideoFormatUtils.getCastStateString(VideoFormatUtils.CAST_STATE_CONNECTED))
    }

    @Test
    fun `getCastStateString returns notConnected for unknown states`() {
        assertEquals("notConnected", VideoFormatUtils.getCastStateString(0))
        assertEquals("notConnected", VideoFormatUtils.getCastStateString(5))
        assertEquals("notConnected", VideoFormatUtils.getCastStateString(-1))
        assertEquals("notConnected", VideoFormatUtils.getCastStateString(100))
    }

    @Test
    fun `cast state constants have correct values`() {
        assertEquals(1, VideoFormatUtils.CAST_STATE_NO_DEVICES_AVAILABLE)
        assertEquals(2, VideoFormatUtils.CAST_STATE_NOT_CONNECTED)
        assertEquals(3, VideoFormatUtils.CAST_STATE_CONNECTING)
        assertEquals(4, VideoFormatUtils.CAST_STATE_CONNECTED)
    }

    // ==================== isValidScalingMode Tests ====================

    @Test
    fun `isValidScalingMode returns true for fit mode`() {
        assertTrue(VideoFormatUtils.isValidScalingMode("fit"))
    }

    @Test
    fun `isValidScalingMode returns true for fill mode`() {
        assertTrue(VideoFormatUtils.isValidScalingMode("fill"))
    }

    @Test
    fun `isValidScalingMode returns true for stretch mode`() {
        assertTrue(VideoFormatUtils.isValidScalingMode("stretch"))
    }

    @Test
    fun `isValidScalingMode returns false for invalid modes`() {
        assertFalse(VideoFormatUtils.isValidScalingMode("zoom"))
        assertFalse(VideoFormatUtils.isValidScalingMode("crop"))
        assertFalse(VideoFormatUtils.isValidScalingMode(""))
        assertFalse(VideoFormatUtils.isValidScalingMode("FIT"))  // Case-sensitive
    }

    @Test
    fun `isValidScalingMode returns false for null`() {
        assertFalse(VideoFormatUtils.isValidScalingMode(null))
    }

    // ==================== isValidBufferingTier Tests ====================

    @Test
    fun `isValidBufferingTier returns true for min tier`() {
        assertTrue(VideoFormatUtils.isValidBufferingTier("min"))
        assertTrue(VideoFormatUtils.isValidBufferingTier("MIN"))
        assertTrue(VideoFormatUtils.isValidBufferingTier("Min"))
    }

    @Test
    fun `isValidBufferingTier returns true for low tier`() {
        assertTrue(VideoFormatUtils.isValidBufferingTier("low"))
        assertTrue(VideoFormatUtils.isValidBufferingTier("LOW"))
    }

    @Test
    fun `isValidBufferingTier returns true for medium tier`() {
        assertTrue(VideoFormatUtils.isValidBufferingTier("medium"))
        assertTrue(VideoFormatUtils.isValidBufferingTier("MEDIUM"))
    }

    @Test
    fun `isValidBufferingTier returns true for high tier`() {
        assertTrue(VideoFormatUtils.isValidBufferingTier("high"))
        assertTrue(VideoFormatUtils.isValidBufferingTier("HIGH"))
    }

    @Test
    fun `isValidBufferingTier returns true for max tier`() {
        assertTrue(VideoFormatUtils.isValidBufferingTier("max"))
        assertTrue(VideoFormatUtils.isValidBufferingTier("MAX"))
    }

    @Test
    fun `isValidBufferingTier returns true for null (defaults to medium)`() {
        assertTrue(VideoFormatUtils.isValidBufferingTier(null))
    }

    @Test
    fun `isValidBufferingTier returns false for invalid tiers`() {
        assertFalse(VideoFormatUtils.isValidBufferingTier("ultra"))
        assertFalse(VideoFormatUtils.isValidBufferingTier(""))
        assertFalse(VideoFormatUtils.isValidBufferingTier("large"))
        assertFalse(VideoFormatUtils.isValidBufferingTier("default"))
    }

    // ==================== isValidVideoSourceType Tests ====================

    @Test
    fun `isValidVideoSourceType returns true for network`() {
        assertTrue(VideoFormatUtils.isValidVideoSourceType("network"))
    }

    @Test
    fun `isValidVideoSourceType returns true for file`() {
        assertTrue(VideoFormatUtils.isValidVideoSourceType("file"))
    }

    @Test
    fun `isValidVideoSourceType returns true for asset`() {
        assertTrue(VideoFormatUtils.isValidVideoSourceType("asset"))
    }

    @Test
    fun `isValidVideoSourceType returns false for invalid types`() {
        assertFalse(VideoFormatUtils.isValidVideoSourceType("stream"))
        assertFalse(VideoFormatUtils.isValidVideoSourceType("url"))
        assertFalse(VideoFormatUtils.isValidVideoSourceType(""))
        assertFalse(VideoFormatUtils.isValidVideoSourceType("Network"))  // Case-sensitive
    }

    @Test
    fun `isValidVideoSourceType returns false for null`() {
        assertFalse(VideoFormatUtils.isValidVideoSourceType(null))
    }

    // ==================== isValidPipActionType Tests ====================

    @Test
    fun `isValidPipActionType returns true for playPause`() {
        assertTrue(VideoFormatUtils.isValidPipActionType("playPause"))
    }

    @Test
    fun `isValidPipActionType returns true for skipPrevious`() {
        assertTrue(VideoFormatUtils.isValidPipActionType("skipPrevious"))
    }

    @Test
    fun `isValidPipActionType returns true for skipNext`() {
        assertTrue(VideoFormatUtils.isValidPipActionType("skipNext"))
    }

    @Test
    fun `isValidPipActionType returns true for skipBackward`() {
        assertTrue(VideoFormatUtils.isValidPipActionType("skipBackward"))
    }

    @Test
    fun `isValidPipActionType returns true for skipForward`() {
        assertTrue(VideoFormatUtils.isValidPipActionType("skipForward"))
    }

    @Test
    fun `isValidPipActionType returns false for invalid types`() {
        assertFalse(VideoFormatUtils.isValidPipActionType("play"))
        assertFalse(VideoFormatUtils.isValidPipActionType("pause"))
        assertFalse(VideoFormatUtils.isValidPipActionType("stop"))
        assertFalse(VideoFormatUtils.isValidPipActionType(""))
        assertFalse(VideoFormatUtils.isValidPipActionType("PlayPause"))  // Case-sensitive
    }

    @Test
    fun `isValidPipActionType returns false for null`() {
        assertFalse(VideoFormatUtils.isValidPipActionType(null))
    }

    // ==================== getPipActionIconName Tests ====================

    @Test
    fun `getPipActionIconName returns play icon for playPause`() {
        assertEquals("ic_media_play", VideoFormatUtils.getPipActionIconName("playPause"))
    }

    @Test
    fun `getPipActionIconName returns previous icon for skipPrevious`() {
        assertEquals("ic_media_previous", VideoFormatUtils.getPipActionIconName("skipPrevious"))
    }

    @Test
    fun `getPipActionIconName returns next icon for skipNext`() {
        assertEquals("ic_media_next", VideoFormatUtils.getPipActionIconName("skipNext"))
    }

    @Test
    fun `getPipActionIconName returns rewind icon for skipBackward`() {
        assertEquals("ic_media_rew", VideoFormatUtils.getPipActionIconName("skipBackward"))
    }

    @Test
    fun `getPipActionIconName returns forward icon for skipForward`() {
        assertEquals("ic_media_ff", VideoFormatUtils.getPipActionIconName("skipForward"))
    }

    @Test
    fun `getPipActionIconName returns default for unknown action`() {
        assertEquals("ic_media_play", VideoFormatUtils.getPipActionIconName("unknown"))
        assertEquals("ic_media_play", VideoFormatUtils.getPipActionIconName(""))
    }

    // ==================== External Subtitle ID Tests ====================

    @Test
    fun `isExternalSubtitleId returns true for ext prefix`() {
        assertTrue(VideoFormatUtils.isExternalSubtitleId("ext-0"))
        assertTrue(VideoFormatUtils.isExternalSubtitleId("ext-1"))
        assertTrue(VideoFormatUtils.isExternalSubtitleId("ext-99"))
        assertTrue(VideoFormatUtils.isExternalSubtitleId("ext-"))
    }

    @Test
    fun `isExternalSubtitleId returns false for non-ext prefix`() {
        assertFalse(VideoFormatUtils.isExternalSubtitleId("0:0"))
        assertFalse(VideoFormatUtils.isExternalSubtitleId("0:1"))
        assertFalse(VideoFormatUtils.isExternalSubtitleId("external-0"))
        assertFalse(VideoFormatUtils.isExternalSubtitleId(""))
    }

    @Test
    fun `isExternalSubtitleId returns false for null`() {
        assertFalse(VideoFormatUtils.isExternalSubtitleId(null))
    }

    @Test
    fun `parseExternalSubtitleIndex returns index for valid ext ID`() {
        assertEquals(0, VideoFormatUtils.parseExternalSubtitleIndex("ext-0"))
        assertEquals(1, VideoFormatUtils.parseExternalSubtitleIndex("ext-1"))
        assertEquals(99, VideoFormatUtils.parseExternalSubtitleIndex("ext-99"))
    }

    @Test
    fun `parseExternalSubtitleIndex returns null for invalid ext ID`() {
        assertNull(VideoFormatUtils.parseExternalSubtitleIndex("ext-"))
        assertNull(VideoFormatUtils.parseExternalSubtitleIndex("ext-abc"))
        assertNull(VideoFormatUtils.parseExternalSubtitleIndex("0:0"))
        assertNull(VideoFormatUtils.parseExternalSubtitleIndex(""))
    }

    @Test
    fun `parseExternalSubtitleIndex returns null for null input`() {
        assertNull(VideoFormatUtils.parseExternalSubtitleIndex(null))
    }

    @Test
    fun `createExternalSubtitleId creates correct format`() {
        assertEquals("ext-0", VideoFormatUtils.createExternalSubtitleId(0))
        assertEquals("ext-1", VideoFormatUtils.createExternalSubtitleId(1))
        assertEquals("ext-99", VideoFormatUtils.createExternalSubtitleId(99))
    }

    @Test
    fun `external subtitle ID roundtrips correctly`() {
        val id = VideoFormatUtils.createExternalSubtitleId(42)
        val parsed = VideoFormatUtils.parseExternalSubtitleIndex(id)
        assertEquals(42, parsed)
        assertTrue(VideoFormatUtils.isExternalSubtitleId(id))
    }

    // ==================== clampVolume Tests ====================

    @Test
    fun `clampVolume returns same value for valid range`() {
        assertEquals(0.0f, VideoFormatUtils.clampVolume(0.0f), 0.001f)
        assertEquals(0.5f, VideoFormatUtils.clampVolume(0.5f), 0.001f)
        assertEquals(1.0f, VideoFormatUtils.clampVolume(1.0f), 0.001f)
    }

    @Test
    fun `clampVolume clamps negative values to 0`() {
        assertEquals(0.0f, VideoFormatUtils.clampVolume(-0.5f), 0.001f)
        assertEquals(0.0f, VideoFormatUtils.clampVolume(-1.0f), 0.001f)
    }

    @Test
    fun `clampVolume clamps values over 1 to 1`() {
        assertEquals(1.0f, VideoFormatUtils.clampVolume(1.5f), 0.001f)
        assertEquals(1.0f, VideoFormatUtils.clampVolume(2.0f), 0.001f)
    }

    // ==================== clampPlaybackSpeed Tests ====================

    @Test
    fun `clampPlaybackSpeed returns same value for valid range`() {
        assertEquals(0.25f, VideoFormatUtils.clampPlaybackSpeed(0.25f), 0.001f)
        assertEquals(1.0f, VideoFormatUtils.clampPlaybackSpeed(1.0f), 0.001f)
        assertEquals(2.0f, VideoFormatUtils.clampPlaybackSpeed(2.0f), 0.001f)
        assertEquals(4.0f, VideoFormatUtils.clampPlaybackSpeed(4.0f), 0.001f)
    }

    @Test
    fun `clampPlaybackSpeed clamps values below 0_25 to 0_25`() {
        assertEquals(0.25f, VideoFormatUtils.clampPlaybackSpeed(0.1f), 0.001f)
        assertEquals(0.25f, VideoFormatUtils.clampPlaybackSpeed(0.0f), 0.001f)
        assertEquals(0.25f, VideoFormatUtils.clampPlaybackSpeed(-1.0f), 0.001f)
    }

    @Test
    fun `clampPlaybackSpeed clamps values over 4 to 4`() {
        assertEquals(4.0f, VideoFormatUtils.clampPlaybackSpeed(4.5f), 0.001f)
        assertEquals(4.0f, VideoFormatUtils.clampPlaybackSpeed(10.0f), 0.001f)
    }
}

/**
 * Unit tests for VideoPlayerOptionsParser.
 * Tests the options parsing logic that was previously only testable via instrumented tests.
 */
class VideoPlayerOptionsParserTest {

    // ==================== Default Values Tests ====================

    @Test
    fun `constants have correct default values`() {
        assertTrue(VideoPlayerOptionsParser.DEFAULT_ALLOW_PIP)
        assertFalse(VideoPlayerOptionsParser.DEFAULT_AUTO_ENTER_PIP)
        assertTrue(VideoPlayerOptionsParser.DEFAULT_SUBTITLES_ENABLED)
        assertFalse(VideoPlayerOptionsParser.DEFAULT_SHOW_SUBTITLES_BY_DEFAULT)
        assertFalse(VideoPlayerOptionsParser.DEFAULT_ALLOW_BACKGROUND_PLAYBACK)
        assertFalse(VideoPlayerOptionsParser.DEFAULT_AUTO_PLAY)
        assertFalse(VideoPlayerOptionsParser.DEFAULT_LOOPING)
        assertEquals(1.0f, VideoPlayerOptionsParser.DEFAULT_VOLUME, 0.001f)
        assertEquals(1.0f, VideoPlayerOptionsParser.DEFAULT_PLAYBACK_SPEED, 0.001f)
        assertEquals("fit", VideoPlayerOptionsParser.DEFAULT_SCALING_MODE)
        assertEquals("medium", VideoPlayerOptionsParser.DEFAULT_BUFFERING_TIER)
    }

    // ==================== getAllowPip Tests ====================

    @Test
    fun `getAllowPip returns true for null options`() {
        assertTrue(VideoPlayerOptionsParser.getAllowPip(null))
    }

    @Test
    fun `getAllowPip returns true for empty options`() {
        assertTrue(VideoPlayerOptionsParser.getAllowPip(emptyMap()))
    }

    @Test
    fun `getAllowPip returns false when explicitly set`() {
        val options = mapOf("allowPip" to false)
        assertFalse(VideoPlayerOptionsParser.getAllowPip(options))
    }

    @Test
    fun `getAllowPip returns true when explicitly set`() {
        val options = mapOf("allowPip" to true)
        assertTrue(VideoPlayerOptionsParser.getAllowPip(options))
    }

    // ==================== getAutoEnterPipOnBackground Tests ====================

    @Test
    fun `getAutoEnterPipOnBackground returns false by default`() {
        assertFalse(VideoPlayerOptionsParser.getAutoEnterPipOnBackground(null))
        assertFalse(VideoPlayerOptionsParser.getAutoEnterPipOnBackground(emptyMap()))
    }

    @Test
    fun `getAutoEnterPipOnBackground returns true when set`() {
        val options = mapOf("autoEnterPipOnBackground" to true)
        assertTrue(VideoPlayerOptionsParser.getAutoEnterPipOnBackground(options))
    }

    // ==================== getSubtitlesEnabled Tests ====================

    @Test
    fun `getSubtitlesEnabled returns true by default`() {
        assertTrue(VideoPlayerOptionsParser.getSubtitlesEnabled(null))
        assertTrue(VideoPlayerOptionsParser.getSubtitlesEnabled(emptyMap()))
    }

    @Test
    fun `getSubtitlesEnabled returns false when explicitly disabled`() {
        val options = mapOf("subtitlesEnabled" to false)
        assertFalse(VideoPlayerOptionsParser.getSubtitlesEnabled(options))
    }

    // ==================== getShowSubtitlesByDefault Tests ====================

    @Test
    fun `getShowSubtitlesByDefault returns false by default`() {
        assertFalse(VideoPlayerOptionsParser.getShowSubtitlesByDefault(null))
        assertFalse(VideoPlayerOptionsParser.getShowSubtitlesByDefault(emptyMap()))
    }

    @Test
    fun `getShowSubtitlesByDefault returns true when set`() {
        val options = mapOf("showSubtitlesByDefault" to true)
        assertTrue(VideoPlayerOptionsParser.getShowSubtitlesByDefault(options))
    }

    // ==================== getPreferredSubtitleLanguage Tests ====================

    @Test
    fun `getPreferredSubtitleLanguage returns null by default`() {
        assertNull(VideoPlayerOptionsParser.getPreferredSubtitleLanguage(null))
        assertNull(VideoPlayerOptionsParser.getPreferredSubtitleLanguage(emptyMap()))
    }

    @Test
    fun `getPreferredSubtitleLanguage returns language when set`() {
        val options = mapOf("preferredSubtitleLanguage" to "en")
        assertEquals("en", VideoPlayerOptionsParser.getPreferredSubtitleLanguage(options))
    }

    @Test
    fun `getPreferredSubtitleLanguage returns various language codes`() {
        assertEquals("es", VideoPlayerOptionsParser.getPreferredSubtitleLanguage(mapOf("preferredSubtitleLanguage" to "es")))
        assertEquals("fr", VideoPlayerOptionsParser.getPreferredSubtitleLanguage(mapOf("preferredSubtitleLanguage" to "fr")))
        assertEquals("zh", VideoPlayerOptionsParser.getPreferredSubtitleLanguage(mapOf("preferredSubtitleLanguage" to "zh")))
    }

    // ==================== getAllowBackgroundPlayback Tests ====================

    @Test
    fun `getAllowBackgroundPlayback returns false by default`() {
        assertFalse(VideoPlayerOptionsParser.getAllowBackgroundPlayback(null))
        assertFalse(VideoPlayerOptionsParser.getAllowBackgroundPlayback(emptyMap()))
    }

    @Test
    fun `getAllowBackgroundPlayback returns true when enabled`() {
        val options = mapOf("allowBackgroundPlayback" to true)
        assertTrue(VideoPlayerOptionsParser.getAllowBackgroundPlayback(options))
    }

    // ==================== getAutoPlay Tests ====================

    @Test
    fun `getAutoPlay returns false by default`() {
        assertFalse(VideoPlayerOptionsParser.getAutoPlay(null))
        assertFalse(VideoPlayerOptionsParser.getAutoPlay(emptyMap()))
    }

    @Test
    fun `getAutoPlay returns true when enabled`() {
        val options = mapOf("autoPlay" to true)
        assertTrue(VideoPlayerOptionsParser.getAutoPlay(options))
    }

    // ==================== getLooping Tests ====================

    @Test
    fun `getLooping returns false by default`() {
        assertFalse(VideoPlayerOptionsParser.getLooping(null))
        assertFalse(VideoPlayerOptionsParser.getLooping(emptyMap()))
    }

    @Test
    fun `getLooping returns true when enabled`() {
        val options = mapOf("looping" to true)
        assertTrue(VideoPlayerOptionsParser.getLooping(options))
    }

    // ==================== getVolume Tests ====================

    @Test
    fun `getVolume returns 1_0 by default`() {
        assertEquals(1.0f, VideoPlayerOptionsParser.getVolume(null), 0.001f)
        assertEquals(1.0f, VideoPlayerOptionsParser.getVolume(emptyMap()), 0.001f)
    }

    @Test
    fun `getVolume returns specified value`() {
        val options = mapOf("volume" to 0.5)
        assertEquals(0.5f, VideoPlayerOptionsParser.getVolume(options), 0.001f)
    }

    @Test
    fun `getVolume clamps values outside valid range`() {
        assertEquals(0.0f, VideoPlayerOptionsParser.getVolume(mapOf("volume" to -0.5)), 0.001f)
        assertEquals(1.0f, VideoPlayerOptionsParser.getVolume(mapOf("volume" to 1.5)), 0.001f)
    }

    // ==================== getPlaybackSpeed Tests ====================

    @Test
    fun `getPlaybackSpeed returns 1_0 by default`() {
        assertEquals(1.0f, VideoPlayerOptionsParser.getPlaybackSpeed(null), 0.001f)
        assertEquals(1.0f, VideoPlayerOptionsParser.getPlaybackSpeed(emptyMap()), 0.001f)
    }

    @Test
    fun `getPlaybackSpeed returns specified value`() {
        val options = mapOf("playbackSpeed" to 1.5)
        assertEquals(1.5f, VideoPlayerOptionsParser.getPlaybackSpeed(options), 0.001f)
    }

    @Test
    fun `getPlaybackSpeed clamps values outside valid range`() {
        assertEquals(0.25f, VideoPlayerOptionsParser.getPlaybackSpeed(mapOf("playbackSpeed" to 0.1)), 0.001f)
        assertEquals(4.0f, VideoPlayerOptionsParser.getPlaybackSpeed(mapOf("playbackSpeed" to 10.0)), 0.001f)
    }

    // ==================== getScalingMode Tests ====================

    @Test
    fun `getScalingMode returns fit by default`() {
        assertEquals("fit", VideoPlayerOptionsParser.getScalingMode(null))
        assertEquals("fit", VideoPlayerOptionsParser.getScalingMode(emptyMap()))
    }

    @Test
    fun `getScalingMode returns valid modes`() {
        assertEquals("fit", VideoPlayerOptionsParser.getScalingMode(mapOf("scalingMode" to "fit")))
        assertEquals("fill", VideoPlayerOptionsParser.getScalingMode(mapOf("scalingMode" to "fill")))
        assertEquals("stretch", VideoPlayerOptionsParser.getScalingMode(mapOf("scalingMode" to "stretch")))
    }

    @Test
    fun `getScalingMode returns default for invalid modes`() {
        assertEquals("fit", VideoPlayerOptionsParser.getScalingMode(mapOf("scalingMode" to "invalid")))
        assertEquals("fit", VideoPlayerOptionsParser.getScalingMode(mapOf("scalingMode" to "")))
        assertEquals("fit", VideoPlayerOptionsParser.getScalingMode(mapOf("scalingMode" to "zoom")))
    }

    // ==================== getBufferingTier Tests ====================

    @Test
    fun `getBufferingTier returns medium by default`() {
        assertEquals("medium", VideoPlayerOptionsParser.getBufferingTier(null))
        assertEquals("medium", VideoPlayerOptionsParser.getBufferingTier(emptyMap()))
    }

    @Test
    fun `getBufferingTier returns valid tiers`() {
        assertEquals("min", VideoPlayerOptionsParser.getBufferingTier(mapOf("bufferingTier" to "min")))
        assertEquals("low", VideoPlayerOptionsParser.getBufferingTier(mapOf("bufferingTier" to "low")))
        assertEquals("medium", VideoPlayerOptionsParser.getBufferingTier(mapOf("bufferingTier" to "medium")))
        assertEquals("high", VideoPlayerOptionsParser.getBufferingTier(mapOf("bufferingTier" to "high")))
        assertEquals("max", VideoPlayerOptionsParser.getBufferingTier(mapOf("bufferingTier" to "max")))
    }

    @Test
    fun `getBufferingTier returns default for invalid tiers`() {
        assertEquals("medium", VideoPlayerOptionsParser.getBufferingTier(mapOf("bufferingTier" to "invalid")))
        assertEquals("medium", VideoPlayerOptionsParser.getBufferingTier(mapOf("bufferingTier" to "")))
        assertEquals("medium", VideoPlayerOptionsParser.getBufferingTier(mapOf("bufferingTier" to "ultra")))
    }

    // ==================== Combined Options Tests ====================

    @Test
    fun `parses complete options map correctly`() {
        val options = mapOf(
            "allowPip" to false,
            "autoEnterPipOnBackground" to true,
            "subtitlesEnabled" to false,
            "showSubtitlesByDefault" to true,
            "preferredSubtitleLanguage" to "es",
            "allowBackgroundPlayback" to true,
            "autoPlay" to true,
            "looping" to true,
            "volume" to 0.75,
            "playbackSpeed" to 2.0,
            "scalingMode" to "fill",
            "bufferingTier" to "high"
        )

        assertFalse(VideoPlayerOptionsParser.getAllowPip(options))
        assertTrue(VideoPlayerOptionsParser.getAutoEnterPipOnBackground(options))
        assertFalse(VideoPlayerOptionsParser.getSubtitlesEnabled(options))
        assertTrue(VideoPlayerOptionsParser.getShowSubtitlesByDefault(options))
        assertEquals("es", VideoPlayerOptionsParser.getPreferredSubtitleLanguage(options))
        assertTrue(VideoPlayerOptionsParser.getAllowBackgroundPlayback(options))
        assertTrue(VideoPlayerOptionsParser.getAutoPlay(options))
        assertTrue(VideoPlayerOptionsParser.getLooping(options))
        assertEquals(0.75f, VideoPlayerOptionsParser.getVolume(options), 0.001f)
        assertEquals(2.0f, VideoPlayerOptionsParser.getPlaybackSpeed(options), 0.001f)
        assertEquals("fill", VideoPlayerOptionsParser.getScalingMode(options))
        assertEquals("high", VideoPlayerOptionsParser.getBufferingTier(options))
    }

    @Test
    fun `ignores unknown options`() {
        val options = mapOf(
            "unknownOption" to "value",
            "anotherUnknown" to 123,
            "allowPip" to false
        )

        assertFalse(VideoPlayerOptionsParser.getAllowPip(options))
        // Other options should still use defaults
        assertTrue(VideoPlayerOptionsParser.getSubtitlesEnabled(options))
    }

    @Test
    fun `handles wrong type values gracefully`() {
        val options = mapOf(
            "allowPip" to "not a boolean",  // String instead of Boolean
            "volume" to "not a number",      // String instead of Double
            "scalingMode" to 123             // Int instead of String
        )

        // Should return defaults when types don't match
        assertTrue(VideoPlayerOptionsParser.getAllowPip(options))
        assertEquals(1.0f, VideoPlayerOptionsParser.getVolume(options), 0.001f)
        assertEquals("fit", VideoPlayerOptionsParser.getScalingMode(options))
    }
}
