# Playlist Test Fixture Attribution

This directory contains **70 playlist test fixture files** from various open-source projects and specifications. All files are used for testing purposes only under their respective licenses.

---

## M3U/M3U8 Playlist Files (13 files)

### Source: [sethdeckard/m3u8](https://github.com/sethdeckard/m3u8) (MIT License)
Ruby library for reading and writing M3U8 files used by HTTP Live Streaming.

**Files:**
- `sethdeckard_master.m3u8` - HLS master playlist with 6 quality variants
- `sethdeckard_with_codecs.m3u8` - Playlist with codec specifications
- `sethdeckard_iframes.m3u8` - I-frame only playlist
- `sethdeckard_session_data.m3u8` - Playlist with session data
- `sethdeckard_variant_codecs.m3u8` - Multiple codec variants

**License:** MIT

### Source: [grafov/m3u8](https://github.com/grafov/m3u8) (BSD-3-Clause License)
Go library for parsing and generating Apple HLS M3U8 playlists.

**Files:**
- `grafov_master.m3u8` - HLS master playlist example
- `grafov_media.m3u8` - Media playlist example
- `grafov_widevine.m3u8` - Widevine DRM example

**License:** BSD-3-Clause

### Source: [wseemann/JavaPlaylistParser](https://github.com/wseemann/JavaPlaylistParser) (Apache 2.0)
Java-based playlist parser supporting multiple formats.

**Files:**
- `javaplaylistparser_test.m3u`

**License:** Apache 2.0

### Source: [tmk907/PlaylistsNET](https://github.com/tmk907/PlaylistsNET) (MIT License)
.NET library for reading and writing playlist files.

**Files:**
- `playlistsnet_ext.m3u` - Extended M3U format
- `playlistsnet_ext_hls.m3u8` - HLS playlist
- `playlistsnet_ext_hls_master.m3u8` - HLS master playlist
- `playlistsnet_not_ext.m3u` - Basic M3U format

**License:** MIT

---

## PLS Playlist Files (5 files)

### Source: [nickdesaulniers/javascript-playlist-parser](https://github.com/nickdesaulniers/javascript-playlist-parser) (MIT & Beerware License)
JavaScript parser for M3U, PLS, and ASX playlists.

**Files:**
- `nickdesaulniers_example.pls`

**License:** MIT & Beerware (Dual licensed)

### Source: [wseemann/JavaPlaylistParser](https://github.com/wseemann/JavaPlaylistParser) (Apache 2.0)

**Files:**
- `javaplaylistparser_test.pls`
- `javaplaylistparser_test2.pls`

**License:** Apache 2.0

### Source: [tmk907/PlaylistsNET](https://github.com/tmk907/PlaylistsNET) (MIT License)

**Files:**
- `playlistsnet_playlist.pls`
- `playlistsnet_playlist2.pls`

**License:** MIT

---

## XSPF Playlist Files (8 files)

### Source: [GNOME/totem-pl-parser](https://github.com/GNOME/totem-pl-parser) (LGPL-2.1-or-later)
GNOME playlist parser library for various audio/video playlist formats.

**Files:**
- `totem_decrypted_amazon_track.xspf` - Amazon Music track example
- `totem_new_lastfm_output.xspf` - Last.fm new format
- `totem_old_lastfm_output.xspf` - Last.fm legacy format
- `totem_playlist.xspf` - Generic playlist
- `totem_xml_base.xspf` - XML base URL example

**License:** LGPL-2.1-or-later

### Source: [DenisVS/radio_playlist_parser](https://github.com/DenisVS/radio_playlist_parser)

**Files:**
- `radio_playlist_parser_template.xspf`

**License:** (License from repository)

### Source: [wseemann/JavaPlaylistParser](https://github.com/wseemann/JavaPlaylistParser) (Apache 2.0)

**Files:**
- `javaplaylistparser_test.xspf`
- `javaplaylistparser_test2.xspf`

**License:** Apache 2.0

---

## JSPF (JSON Playlist) Files (12 files)

### Source: [XSPF.org Official Specification](https://www.xspf.org/jspf)
Created based on examples from the official JSPF specification.

**Files:**
- `xspf_spec_minimal.jspf` - Minimal single-track playlist
- `xspf_spec_basic.jspf` - Basic playlist with essential fields
- `xspf_spec_comprehensive.jspf` - Full feature demonstration
- `xspf_spec_empty.jspf` - Empty playlist
- `xspf_spec_multiple_locations.jspf` - Multiple CDN locations
- `xspf_spec_with_images.jspf` - Playlist with artwork
- `xspf_spec_podcast.jspf` - Podcast episode playlist
- `xspf_spec_radio.jspf` - Internet radio stations
- `xspf_spec_album.jspf` - Album track listing
- `xspf_spec_identifiers.jspf` - Playlist with MusicBrainz IDs
- `xspf_spec_long_playlist.jspf` - Long playlist (12 tracks)
- `xspf_spec_license.jspf` - Creative Commons licensed content

**License:** Public documentation examples

---

## ASX Playlist Files (5 files)

### Source: [nickdesaulniers/javascript-playlist-parser](https://github.com/nickdesaulniers/javascript-playlist-parser) (MIT & Beerware)

**Files:**
- `nickdesaulniers_example.asx`
- `nickdesaulniers_malformed.asx` - Malformed playlist test case
- `nickdesaulniers_malformed_no_attributes.asx` - Missing attributes test
- `nickdesaulniers_malformed_wrong_case.asx` - Case sensitivity test

**License:** MIT & Beerware

### Source: [wseemann/JavaPlaylistParser](https://github.com/wseemann/JavaPlaylistParser) (Apache 2.0)

**Files:**
- `javaplaylistparser_test.asx`

**License:** Apache 2.0

---

## WPL (Windows Media Player Playlist) Files (10 files)

### Source: [tmk907/PlaylistsNET](https://github.com/tmk907/PlaylistsNET) (MIT License)

**Files:**
- `playlistsnet_2seq.wpl` - Two sequence playlist
- `playlistsnet_2seqoutput.wpl` - Sequence output format
- `playlistsnet_2seqoutputTest.wpl` - Test variant
- `playlistsnet_empty.wpl` - Empty playlist
- `playlistsnet_playlist.wpl` - Basic playlist
- `playlistsnet_playlist2.wpl` - Second example
- `playlistsnet_playlist3.wpl` - Third example
- `playlistsnet_smart.wpl` - Smart playlist
- `playlistsnet_playlist3b.wpl` - Variant format

**License:** MIT

### Source: [wseemann/JavaPlaylistParser](https://github.com/wseemann/JavaPlaylistParser) (Apache 2.0)

**Files:**
- `javaplaylistparser_test.wpl`

**License:** Apache 2.0

---

## CUE Sheet Files (7 files)

### Source: [lipnitsk/libcue](https://github.com/lipnitsk/libcue) (GPLv2)
CUE Sheet Parser Library with comprehensive test cases.

**Files:**
- `libcue_99_tracks.cue` - Large multi-track CUE sheet
- `libcue_issue10.cue` - Bug regression test case
- `libcue_standard.cue` - Standard CUE format (My Bloody Valentine - Loveless)
- `libcue_multiple_files.cue` - Multiple file references (The Specials)
- `libcue_multiple_files_pregap.cue` - PREGAP command usage
- `libcue_noncompliant.cue` - Non-compliant format with FLAC
- `libcue_single_idx_00.cue` - INDEX 00 test case (Bloc Party)

**License:** GPLv2

---

## DASH/MPD (Dynamic Adaptive Streaming) Files (10 files)

### Source: [Shaka Player](https://github.com/shaka-project/shaka-player) (Apache 2.0)
Google's JavaScript library for adaptive media.

**Files:**
- `shaka_angel_one.mpd` - Angel One (Star Trek) demo
- `shaka_angel_one_clearkey.mpd` - ClearKey encryption example
- `shaka_sintel.mpd` - Sintel open movie
- `shaka_sintel_basic.mpd` - Basic Sintel variant
- `shaka_sintel_trickplay.mpd` - Trick play mode
- `shaka_sintel_webm_only.mpd` - WebM codec only
- `shaka_sintel_mp4_only.mpd` - MP4 codec only
- `shaka_sintel_widevine.mpd` - Widevine DRM
- `shaka_sintel_mp4_wvtt.mpd` - MP4 with WebVTT subtitles
- `shaka_heliocentrism.mpd` - Heliocentrism demo

**License:** Apache 2.0

---

## License Summary

| License | File Count | Projects |
|---------|------------|----------|
| MIT | 24 | sethdeckard/m3u8, tmk907/PlaylistsNET, nickdesaulniers/javascript-playlist-parser |
| Apache 2.0 | 17 | JavaPlaylistParser, Shaka Player |
| BSD-3-Clause | 3 | grafov/m3u8 |
| GPLv2 | 7 | lipnitsk/libcue |
| LGPL-2.1+ | 5 | GNOME/totem-pl-parser |
| Public Docs | 12 | XSPF.org specification |
| Mixed/Other | 2 | radio_playlist_parser |

**Total: 70 test fixture files**

---

## Usage

These files are included solely for testing the playlist parsing functionality of this library. They are not redistributed in any binary distribution and are only used during development and testing.

### Test Fixture Categories:
- **Real-world examples**: Actual test files from parser libraries
- **Edge cases**: Malformed, empty, and non-compliant formats
- **Specification examples**: Official format specification samples
- **Comprehensive coverage**: Multiple variants per format

All files comply with the respective open-source licenses for test data usage.

---

## Notes

- CUE sheet files use example artist/album data from libcue test suite
- JSPF files use generic placeholder data based on official specification
- DASH manifests reference Shaka Player's publicly available demo assets
- Test fixtures cover both compliant and edge-case scenarios for robust parser testing

Last updated: 2025-12-13
