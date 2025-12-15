#!/usr/bin/env bash
# Coverage summary script
# Displays comprehensive coverage report for Dart and native code

set -e

CURDIR="${1:-.}"
PACKAGES="${2:-pro_video_player_platform_interface pro_video_player pro_video_player_ios pro_video_player_android pro_video_player_web pro_video_player_macos pro_video_player_windows pro_video_player_linux}"

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              COMPREHENSIVE COVERAGE REPORT SUMMARY               ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                  DART/FLUTTER COVERAGE SUMMARY                   ║"
echo "╠══════════════════════════════════════════════════════════════════╣"

total_lh=0
total_lf=0

for pkg in $PACKAGES; do
	if [ -f "$CURDIR/$pkg/coverage/lcov.info" ]; then
		lh=0
		lf=0
		while read -r line; do
			case "$line" in
				LH:*) lh=$((lh + ${line#LH:})) ;;
				LF:*) lf=$((lf + ${line#LF:})) ;;
			esac
		done < "$CURDIR/$pkg/coverage/lcov.info"
		if [ "$lf" -gt 0 ]; then
			pct=$(awk "BEGIN {printf \"%.1f\", $lh*100/$lf}")
			printf "║  %-42s %6d/%-6d %5s%% ║\n" "$pkg" "$lh" "$lf" "$pct"
			total_lh=$((total_lh + lh))
			total_lf=$((total_lf + lf))
		fi
	fi
done

echo "╠══════════════════════════════════════════════════════════════════╣"
if [ "$total_lf" -gt 0 ]; then
	total_pct=$(awk "BEGIN {printf \"%.1f\", $total_lh*100/$total_lf}")
	printf "║  %-42s %6d/%-6d %5s%% ║\n" "TOTAL (Dart/Flutter)" "$total_lh" "$total_lf" "$total_pct"
else
	echo "║  No Dart coverage data available                                 ║"
fi
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Dart/Flutter HTML Report:"
echo "   file://$CURDIR/coverage/html/index.html"

# Android coverage
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║             ANDROID NATIVE COVERAGE SUMMARY (Kotlin)            ║"
echo "╠══════════════════════════════════════════════════════════════════╣"

if [ -f "$CURDIR/example-showcase/build/pro_video_player_android/reports/jacoco/test/jacocoTestReport.xml" ]; then
	line_counter=$(grep -o 'type="LINE" missed="[0-9]*" covered="[0-9]*"' "$CURDIR/example-showcase/build/pro_video_player_android/reports/jacoco/test/jacocoTestReport.xml" | tail -1)
	line_missed=$(echo "$line_counter" | grep -o 'missed="[0-9]*"' | grep -o '[0-9]*')
	line_covered=$(echo "$line_counter" | grep -o 'covered="[0-9]*"' | grep -o '[0-9]*')
	line_total=$((line_missed + line_covered))
	if [ "$line_total" -gt 0 ]; then
		line_pct=$(awk "BEGIN {printf \"%.1f\", $line_covered*100/$line_total}")
	else
		line_pct="0.0"
	fi
	printf "║  %-42s %6d/%-6d %5s%% ║\n" "Android Native (Kotlin)" "$line_covered" "$line_total" "$line_pct"
else
	echo "║  Android coverage data not available                            ║"
fi
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Android Native HTML Report:"
echo "   file://$CURDIR/example-showcase/build/pro_video_player_android/reports/jacoco/test/html/index.html"

# iOS coverage
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║             iOS NATIVE COVERAGE SUMMARY (Swift)                 ║"
echo "╠══════════════════════════════════════════════════════════════════╣"

XCRESULT=$(find ~/Library/Developer/Xcode/DerivedData -name "*.xcresult" -path "*Runner*" -path "*Test*" -type d 2>/dev/null | sort -r | head -1)
if [ -n "$XCRESULT" ]; then
	COVERAGE_OUTPUT=$(xcrun xccov view --report --files-for-target pro_video_player_ios.framework "$XCRESULT" 2>/dev/null || echo "")
	if [ -n "$COVERAGE_OUTPUT" ]; then
		SWIFT_LINES=$(echo "$COVERAGE_OUTPUT" | grep "\.swift")
		TOTAL_COVERED=$(echo "$SWIFT_LINES" | grep -oE "\([0-9]+/[0-9]+\)" | sed "s/[()]//g" | cut -d"/" -f1 | awk "{sum+=\$1} END {print sum}")
		TOTAL_LINES=$(echo "$SWIFT_LINES" | grep -oE "\([0-9]+/[0-9]+\)" | sed "s/[()]//g" | cut -d"/" -f2 | awk "{sum+=\$1} END {print sum}")
		if [ -n "$TOTAL_LINES" ] && [ "$TOTAL_LINES" -gt 0 ]; then
			TOTAL_PCT=$(echo "scale=1; $TOTAL_COVERED * 100 / $TOTAL_LINES" | bc)
			printf "║  %-42s %6d/%-6d %5s%% ║\n" "iOS Native (Swift)" "$TOTAL_COVERED" "$TOTAL_LINES" "$TOTAL_PCT"
		else
			echo "║  Coverage data available in HTML report                         ║"
		fi
	else
		echo "║  Could not parse coverage data                                  ║"
	fi
else
	echo "║  iOS coverage data not available                                ║"
fi
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 iOS Native HTML Report:"
echo "   file://$CURDIR/example-showcase/build/ios_coverage/index.html"

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "✅ Coverage generation complete for all platforms!"
echo "════════════════════════════════════════════════════════════════════"
echo ""
