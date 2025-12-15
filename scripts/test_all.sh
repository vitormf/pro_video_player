#!/bin/bash
# Run tests for all packages

set -e

echo "Running tests for all packages..."

echo ""
echo "=== pro_video_player_platform_interface ==="
cd "$(dirname "$0")/../pro_video_player_platform_interface"
fvm flutter test

echo ""
echo "=== pro_video_player ==="
cd "$(dirname "$0")/../pro_video_player"
fvm flutter test

echo ""
echo "=== pro_video_player_ios ==="
cd "$(dirname "$0")/../pro_video_player_ios"
fvm flutter test

echo ""
echo "=== pro_video_player_android ==="
cd "$(dirname "$0")/../pro_video_player_android"
fvm flutter test

echo ""
echo "All tests passed!"
