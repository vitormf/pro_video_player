# Test Fixture Attribution

This directory contains subtitle test files from various open-source projects. All files are used under permissive licenses (MIT, BSD-2-Clause, Apache 2.0).

## Sources

### go-astisub (MIT License)
**Repository**: https://github.com/asticode/go-astisub
**License**: MIT
**Files**:
- `srt/sample_go_astisub.srt`
- `vtt/sample_go_astisub.vtt`
- `ssa/sample_go_astisub.ssa`
- `ttml/sample_go_astisub.ttml`

### ttconv (BSD-2-Clause License)
**Repository**: https://github.com/sandflow/ttconv
**License**: BSD-2-Clause
**Files**:
- `ttml/sample_ttconv_body_only.ttml`
- `ttml/sample_ttconv_lwsp_default.ttml`
- `ttml/sample_ttconv_lwsp_preserve.ttml`
- `ttml/sample_ttconv_referential_styling.ttml`
- `vtt/sample_ttconv_alignment.vtt`
- `vtt/sample_ttconv_font.vtt`
- `vtt/sample_ttconv_position.vtt`
- `vtt/sample_ttconv_style.vtt`

### pysubs2 (MIT License)
**Repository**: https://github.com/tkarabela/pysubs2
**License**: MIT
**Files**:
- `ttml/sample_pysubs2_example.ttml`
- `ttml/sample_pysubs2_example2.ttml`
- `ssa/sample_pysubs2_ttml_example.ass`
- `ssa/sample_pysubs2_ttml_example2.ass`

### subtitles (MIT License)
**Repository**: https://github.com/mantas-done/subtitles
**License**: MIT
**Files**:
- `srt/sample_mantas_done.srt`
- `srt/sample_mantas_done_public_interface.srt`
- `srt/sample_mantas_done_utf16.srt`
- `vtt/sample_mantas_done.vtt`
- `vtt/sample_mantas_done_with_html.vtt`
- `vtt/sample_mantas_done_missing_text.vtt`
- `vtt/sample_mantas_done_multiple_newlines.vtt`
- `vtt/sample_mantas_done_with_name.vtt`
- `vtt/sample_mantas_done_with_styles.vtt`
- `vtt/sample_mantas_done_without_hours.vtt`
- `ssa/sample_mantas_done.ass`
- `ssa/sample_mantas_done_different_format.ass`
- `ssa/sample_mantas_done_different_format2.ass`
- `ssa/sample_mantas_done_different_format3.ass`
- `ttml/sample_mantas_done.ttml`
- `ttml/sample_mantas_done2.ttml`
- `ttml/sample_mantas_done_duplicated_ids.ttml`
- `ttml/sample_mantas_done_fps_multiplier.ttml`
- `ttml/sample_mantas_done_multiple_divs.ttml`

### Aegisub (BSD-style License)
**Repository**: https://github.com/Aegisub/Aegisub
**License**: Various GPL-compatible BSD-style licenses
**Files**:
- `ssa/sample_aegisub_format_tests.ass`

### W3C IMSC Tests (W3C 3-clause BSD / W3C Test Suite License)
**Repository**: https://github.com/w3c/imsc-tests
**License**: Dual-licensed under W3C 3-clause BSD and W3C Test Suite License
**Files**:
- `ttml/sample_w3c_imsc_activeArea001.ttml`
- `ttml/sample_w3c_imsc_animation001.ttml`
- `ttml/sample_w3c_imsc_color001.ttml`
- `ttml/sample_w3c_imsc_display001.ttml`
- `ttml/sample_w3c_imsc_extent001.ttml`
- `ttml/sample_w3c_imsc_fontSize001.ttml`

### Mozilla vtt.js (Apache-2.0 License)
**Repository**: https://github.com/mozilla/vtt.js
**License**: Apache-2.0
**Files**:
- `vtt/sample_mozilla_bold_not_closed.vtt`
- `vtt/sample_mozilla_bold_with_annotation.vtt`

### Synthetic Test Files

The following files were created specifically for this project to test edge cases and parser robustness:

**SRT Files**:
- `srt/sample_empty_cues.srt`
- `srt/sample_long_text.srt`
- `srt/sample_overlapping_times.srt`
- `srt/sample_unicode_emoji.srt`
- `srt/sample_multiple_speakers.srt`
- `srt/sample_gap_indexing.srt`
- `srt/sample_same_timestamp.srt`
- `srt/sample_very_short_duration.srt`
- `srt/sample_very_long_duration.srt`
- `srt/sample_many_line_breaks.srt`
- `srt/sample_special_chars.srt`

**ASS Files**:
- `ssa/sample_minimal.ass`
- `ssa/sample_formatting_tags.ass`
- `ssa/sample_colors.ass`
- `ssa/sample_positioning.ass`
- `ssa/sample_rotation.ass`
- `ssa/sample_layers.ass`
- `ssa/sample_fade.ass`
- `ssa/sample_multiline.ass`

**TTML Files**:
- `ttml/sample_unicode_emoji.ttml`
- `ttml/sample_long_duration.ttml`

### Other Files

Files not listed above were created specifically for this project or sourced from public domain content.

## License Compatibility

All third-party test files are used under licenses compatible with this project:
- **MIT License**: Compatible (permissive)
- **BSD-2-Clause**: Compatible (permissive)
- **Apache 2.0**: Compatible (permissive)

## Full License Texts

### MIT License
```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### BSD-2-Clause License
```
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

### Apache-2.0 License
```
Copyright [yyyy] [name of copyright owner]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
