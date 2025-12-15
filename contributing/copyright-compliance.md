# Copyright and Legal Compliance

Requirements and current status for copyright compliance in test fixtures and example assets.

## Attribution Requirements

When using open source or Creative Commons content:
1. **Include attribution** in test comments or README
2. **Link to source** repository or specification
3. **Specify license** when applicable
4. **Verify license permits** redistribution and modification

### Example Attribution in Tests

```dart
// Source: https://github.com/andreyvit/subtitle-tools
// License: MIT
test('parses real-world SRT file', () {
  final srt = loadFixture('srt/sample_andreyvit.srt');
  // ...
});
```

---

## Current Compliance Status

All test fixture files are legally compliant for open source distribution.

### Subtitle Test Fixtures (80 files)

All subtitle test fixtures are from permissively licensed sources:

**Sources:**
- **Apache 2.0 licensed** — EBU-TT-D sample
- **MIT licensed** — andreyvit/subtitle-tools, chireiden/python-ass
- **W3C specification examples** — MDN, WebVTT spec
- **Public domain** — "Alice's Adventures in Wonderland" by Lewis Carroll (1865)
- **Simple technical test data** — Non-creative content

See `pro_video_player_platform_interface/test/fixtures/subtitles/ATTRIBUTION.md` for detailed source documentation.

### Playlist Test Fixtures (70 files)

All playlist test fixtures are from open source projects:

**Sources:**
- **MIT licensed** — javascript-playlist-parser, PlaylistsNET, sethdeckard/m3u8
- **Apache 2.0** — JavaPlaylistParser, Shaka Player
- **BSD-3-Clause** — grafov/m3u8
- **LGPL-2.1+** — GNOME/totem-pl-parser
- **GPLv2** — lipnitsk/libcue
- **W3C specification** — XSPF.org official examples

See `pro_video_player_platform_interface/test/fixtures/playlists/ATTRIBUTION.md` for detailed source documentation.

### Example App Assets

Example apps contain only:
- Standard Flutter/platform app assets (icons, launch screens, favicons)
- User-provided content via file picker or URL input
- No embedded media files

---

## Verification Checklist

Before adding test fixtures or media, verify:

1. ✅ Is the content public domain, permissively licensed, or self-created?
2. ✅ Have you verified the license permits open source redistribution?
3. ✅ Have you included proper attribution in comments?
4. ✅ Does the content contain no copyrighted characters, logos, or trademarks?
5. ✅ Would you be comfortable defending this in court?

**If you answer "no" to ANY question above, DO NOT add the file.**

---

## Last Verified

**Date:** 2025-12-13

**Total test fixtures:** 150 files (80 subtitles + 70 playlists)
**All compliant:** ✅ Yes
**Attribution documented:** ✅ Yes
