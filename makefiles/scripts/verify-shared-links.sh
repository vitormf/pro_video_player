#!/bin/bash
# Verify that shared sources (Swift + Pigeon) are identical across packages
#
# Swift sources: shared_apple_sources/ → iOS/macOS
# Pigeon sources: shared_pigeon_sources/ → Android/iOS/macOS
#
# Use this in CI or as a pre-commit hook to catch accidental divergence.
# Exit code 0 = all files match, 1 = files differ or missing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

errors=0

# === Swift Sources ===

SHARED_SWIFT="$PROJECT_ROOT/shared_apple_sources"
IOS_SHARED="$PROJECT_ROOT/pro_video_player_ios/ios/Classes/Shared"
MACOS_SHARED="$PROJECT_ROOT/pro_video_player_macos/macos/Classes/Shared"

echo "Verifying shared Swift sources..."

# Check each file in shared_apple_sources
for source_file in "$SHARED_SWIFT"/*.swift; do
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

# === Pigeon Sources ===

SHARED_PIGEON="$PROJECT_ROOT/shared_pigeon_sources"
ANDROID_PIGEON="$PROJECT_ROOT/pro_video_player_android/pigeons"
IOS_PIGEON="$PROJECT_ROOT/pro_video_player_ios/pigeons"
MACOS_PIGEON="$PROJECT_ROOT/pro_video_player_macos/pigeons"

echo "Verifying shared Pigeon sources..."

# Check each file in shared_pigeon_sources
for source_file in "$SHARED_PIGEON"/*; do
    if [ -f "$source_file" ]; then
        filename=$(basename "$source_file")
        android_file="$ANDROID_PIGEON/$filename"
        ios_file="$IOS_PIGEON/$filename"
        macos_file="$MACOS_PIGEON/$filename"

        # Check Android file exists and matches
        if [ ! -f "$android_file" ]; then
            echo "ERROR: Missing Android file: $android_file"
            echo "  Run 'make setup-shared-links' to fix"
            errors=$((errors + 1))
        elif ! diff -q "$source_file" "$android_file" > /dev/null 2>&1; then
            echo "ERROR: Android file differs: $filename"
            echo "  shared_pigeon_sources vs pro_video_player_android"
            echo "  Run 'make setup-shared-links' to fix"
            errors=$((errors + 1))
        fi

        # Check iOS file exists and matches
        if [ ! -f "$ios_file" ]; then
            echo "ERROR: Missing iOS file: $ios_file"
            echo "  Run 'make setup-shared-links' to fix"
            errors=$((errors + 1))
        elif ! diff -q "$source_file" "$ios_file" > /dev/null 2>&1; then
            echo "ERROR: iOS file differs: $filename"
            echo "  shared_pigeon_sources vs pro_video_player_ios"
            echo "  Run 'make setup-shared-links' to fix"
            errors=$((errors + 1))
        fi

        # Check macOS file exists and matches
        if [ ! -f "$macos_file" ]; then
            echo "ERROR: Missing macOS file: $macos_file"
            echo "  Run 'make setup-shared-links' to fix"
            errors=$((errors + 1))
        elif [ "$filename" = "messages.dart" ]; then
            # For messages.dart, only compare message definitions (skip @ConfigurePigeon)
            # Extract lines after the @ConfigurePigeon block
            source_defs=$(sed -n '/^\/\/\/ Video source types/,$p' "$source_file")
            macos_defs=$(sed -n '/^\/\/\/ Video source types/,$p' "$macos_file")
            if [ "$source_defs" != "$macos_defs" ]; then
                echo "ERROR: macOS message definitions differ: $filename"
                echo "  shared_pigeon_sources vs pro_video_player_macos"
                echo "  (Pigeon configurations can differ, but message classes must match)"
                errors=$((errors + 1))
            fi
        elif ! diff -q "$source_file" "$macos_file" > /dev/null 2>&1; then
            echo "ERROR: macOS file differs: $filename"
            echo "  shared_pigeon_sources vs pro_video_player_macos"
            echo "  Run 'make setup-shared-links' to fix"
            errors=$((errors + 1))
        fi
    fi
done

if [ $errors -eq 0 ]; then
    echo "All shared sources are in sync."
    exit 0
else
    echo ""
    echo "Found $errors error(s). Shared sources are out of sync!"
    echo ""
    echo "This usually happens after cloning or when hard links break."
    echo "Fix by running: make setup-shared-links"
    exit 1
fi
