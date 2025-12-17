#!/bin/bash
# Setup hard links for shared Swift sources
#
# Swift sources: shared_apple_sources/ → iOS/macOS
#
# Hard links ensure that editing any linked file updates all copies,
# eliminating code duplication while maintaining package compatibility.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# === Swift Sources ===

SHARED_SWIFT="$PROJECT_ROOT/shared_apple_sources"
IOS_SHARED="$PROJECT_ROOT/pro_video_player_ios/ios/Classes/Shared"
MACOS_SHARED="$PROJECT_ROOT/pro_video_player_macos/macos/Classes/Shared"

echo "Setting up shared Swift source hard links..."

# Verify source directory exists
if [ ! -d "$SHARED_SWIFT" ]; then
    echo "Error: shared_apple_sources directory not found at $SHARED_SWIFT"
    exit 1
fi

# Create target directories if they don't exist
mkdir -p "$IOS_SHARED"
mkdir -p "$MACOS_SHARED"

# Count files for progress
swift_count=$(find "$SHARED_SWIFT" -name "*.swift" | wc -l | tr -d ' ')
echo "Found $swift_count Swift files to link"

# Create hard links for each Swift file
for source_file in "$SHARED_SWIFT"/*.swift; do
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

echo ""
echo "Done! Hard links created successfully."
echo ""
echo "Verification (link count should be 3 for Swift):"
ls -la "$SHARED_SWIFT"/*.swift 2>/dev/null | awk '{print $2, $NF}' | while read count file; do
    basename "$file"
done | head -3
echo "..."
