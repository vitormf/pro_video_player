#!/bin/bash
# Verify that shared Swift sources are identical across iOS and macOS
#
# This script checks that files in shared_apple_sources/,
# pro_video_player_ios/ios/Classes/Shared/, and
# pro_video_player_macos/macos/Classes/Shared/ are identical.
#
# Use this in CI or as a pre-commit hook to catch accidental divergence.
# Exit code 0 = all files match, 1 = files differ or missing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SHARED_SOURCE="$PROJECT_ROOT/shared_apple_sources"
IOS_SHARED="$PROJECT_ROOT/pro_video_player_ios/ios/Classes/Shared"
MACOS_SHARED="$PROJECT_ROOT/pro_video_player_macos/macos/Classes/Shared"

errors=0

echo "Verifying shared Swift sources..."

# Check each file in shared_apple_sources
for source_file in "$SHARED_SOURCE"/*.swift; do
    if [ -f "$source_file" ]; then
        filename=$(basename "$source_file")
        ios_file="$IOS_SHARED/$filename"
        macos_file="$MACOS_SHARED/$filename"

        # Check iOS file exists and matches
        if [ ! -f "$ios_file" ]; then
            echo "ERROR: Missing iOS file: $ios_file"
            echo "  Run 'make setup-shared-links' to fix"
            errors=$((errors + 1))
        elif ! diff -q "$source_file" "$ios_file" > /dev/null 2>&1; then
            echo "ERROR: iOS file differs: $filename"
            echo "  shared_apple_sources vs pro_video_player_ios"
            echo "  Run 'make setup-shared-links' to fix"
            errors=$((errors + 1))
        fi

        # Check macOS file exists and matches
        if [ ! -f "$macos_file" ]; then
            echo "ERROR: Missing macOS file: $macos_file"
            echo "  Run 'make setup-shared-links' to fix"
            errors=$((errors + 1))
        elif ! diff -q "$source_file" "$macos_file" > /dev/null 2>&1; then
            echo "ERROR: macOS file differs: $filename"
            echo "  shared_apple_sources vs pro_video_player_macos"
            echo "  Run 'make setup-shared-links' to fix"
            errors=$((errors + 1))
        fi
    fi
done

if [ $errors -eq 0 ]; then
    echo "All shared Swift sources are in sync."
    exit 0
else
    echo ""
    echo "Found $errors error(s). Shared sources are out of sync!"
    echo ""
    echo "This usually happens after cloning or when hard links break."
    echo "Fix by running: make setup-shared-links"
    exit 1
fi
