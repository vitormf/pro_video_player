#!/bin/bash
# Setup hard links for shared Swift sources between iOS and macOS
#
# This script creates hard links from shared_apple_sources/ to both
# pro_video_player_ios/ios/Classes/Shared/ and
# pro_video_player_macos/macos/Classes/Shared/
#
# Hard links ensure that editing any linked file updates all copies,
# eliminating code duplication while maintaining CocoaPods compatibility.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SHARED_SOURCE="$PROJECT_ROOT/shared_apple_sources"
IOS_SHARED="$PROJECT_ROOT/pro_video_player_ios/ios/Classes/Shared"
MACOS_SHARED="$PROJECT_ROOT/pro_video_player_macos/macos/Classes/Shared"

echo "Setting up shared Swift source hard links..."

# Verify source directory exists
if [ ! -d "$SHARED_SOURCE" ]; then
    echo "Error: shared_apple_sources directory not found at $SHARED_SOURCE"
    exit 1
fi

# Create target directories if they don't exist
mkdir -p "$IOS_SHARED"
mkdir -p "$MACOS_SHARED"

# Count files for progress
file_count=$(find "$SHARED_SOURCE" -name "*.swift" | wc -l | tr -d ' ')
echo "Found $file_count Swift files to link"

# Create hard links for each Swift file
for source_file in "$SHARED_SOURCE"/*.swift; do
    if [ -f "$source_file" ]; then
        filename=$(basename "$source_file")

        # Remove existing files (they might be copies, not links)
        rm -f "$IOS_SHARED/$filename"
        rm -f "$MACOS_SHARED/$filename"

        # Create hard links
        ln "$source_file" "$IOS_SHARED/$filename"
        ln "$source_file" "$MACOS_SHARED/$filename"

        echo "  Linked: $filename"
    fi
done

echo "Done! Hard links created successfully."
echo ""
echo "Verification (link count should be 3 for each file):"
ls -la "$SHARED_SOURCE"/*.swift | awk '{print $2, $NF}' | while read count file; do
    basename "$file"
done | head -3
echo "..."
