#!/usr/bin/env bash
# iOS native coverage report script
# Extracts and displays coverage data from xcresult

set -e

IOS_SIMULATOR_ID="${1:-}"
FRAMEWORK_NAME="${2:-pro_video_player_ios.framework}"

echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║              iOS NATIVE COVERAGE SUMMARY (Plugin Swift)                  ║"
echo "╠══════════════════════════════════════════════════════════════════════════╣"

XCRESULT=$(find ~/Library/Developer/Xcode/DerivedData -name "*.xcresult" -path "*Runner*" -path "*Test*" -type d 2>/dev/null | sort -r | head -1)

if [ -n "$XCRESULT" ]; then
	echo "║  File                                               Lines     Coverage  ║"
	echo "║  ─────────────────────────────────────────────────  ────────  ───────── ║"

	COVERAGE_OUTPUT=$(xcrun xccov view --report --files-for-target "$FRAMEWORK_NAME" "$XCRESULT" 2>/dev/null)

	echo "$COVERAGE_OUTPUT" | grep "\.swift" | while read -r line; do
		FILENAME=$(echo "$line" | grep -oE "/[^[:space:]]+\.swift" | sed "s|.*/||")
		COVERAGE=$(echo "$line" | grep -oE "[0-9]+\.[0-9]+%" | head -1)
		LINES_INFO=$(echo "$line" | grep -oE "\([0-9]+/[0-9]+\)" | head -1)
		if [ -n "$FILENAME" ] && [ -n "$COVERAGE" ] && [ -n "$LINES_INFO" ]; then
			printf "║  %-51s %-8s  %9s ║\n" "$FILENAME" "$LINES_INFO" "$COVERAGE"
		fi
	done

	echo "║  ─────────────────────────────────────────────────  ────────  ───────── ║"

	SWIFT_LINES=$(echo "$COVERAGE_OUTPUT" | grep "\.swift")
	TOTAL_COVERED=$(echo "$SWIFT_LINES" | grep -oE "\([0-9]+/[0-9]+\)" | sed "s/[()]//g" | cut -d"/" -f1 | awk "{sum+=\$1} END {print sum}")
	TOTAL_LINES=$(echo "$SWIFT_LINES" | grep -oE "\([0-9]+/[0-9]+\)" | sed "s/[()]//g" | cut -d"/" -f2 | awk "{sum+=\$1} END {print sum}")

	if [ -n "$TOTAL_LINES" ] && [ "$TOTAL_LINES" -gt 0 ]; then
		TOTAL_PCT=$(echo "scale=2; $TOTAL_COVERED * 100 / $TOTAL_LINES" | bc)
		printf "║  %-51s %-8s  %8s%% ║\n" "TOTAL" "($TOTAL_COVERED/$TOTAL_LINES)" "$TOTAL_PCT"
		echo "╚══════════════════════════════════════════════════════════════════════════╝"
		echo ""
		if [ "$(echo "$TOTAL_PCT < 80" | bc)" -eq 1 ]; then
			echo "⚠️  Coverage is below 80% target ($TOTAL_PCT%)"
		else
			echo "✅ Coverage meets 80% target ($TOTAL_PCT%)"
		fi
	fi
else
	echo "║  No .xcresult file found. Run tests first.                               ║"
	echo "╚══════════════════════════════════════════════════════════════════════════╝"
fi
