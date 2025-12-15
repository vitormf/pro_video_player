#!/bin/bash
# Analyze all packages

set -e

echo "Analyzing all packages..."

echo ""
echo "=== pro_video_player_platform_interface ==="
cd "$(dirname "$0")/../pro_video_player_platform_interface"
fvm flutter analyze

echo ""
echo "=== pro_video_player ==="
cd "$(dirname "$0")/../pro_video_player"
fvm flutter analyze

echo ""
echo "=== pro_video_player_ios ==="
cd "$(dirname "$0")/../pro_video_player_ios"
fvm flutter analyze

echo ""
echo "=== pro_video_player_android ==="
cd "$(dirname "$0")/../pro_video_player_android"
fvm flutter analyze

echo ""
echo "=== example ==="
cd "$(dirname "$0")/../example"
fvm flutter analyze

echo ""
echo "Analysis complete!"
