#!/bin/bash
# Clean all packages

set -e

echo "Cleaning all packages..."

echo ""
echo "=== pro_video_player_platform_interface ==="
cd "$(dirname "$0")/../pro_video_player_platform_interface"
fvm flutter clean

echo ""
echo "=== pro_video_player ==="
cd "$(dirname "$0")/../pro_video_player"
fvm flutter clean

echo ""
echo "=== pro_video_player_ios ==="
cd "$(dirname "$0")/../pro_video_player_ios"
fvm flutter clean

echo ""
echo "=== pro_video_player_android ==="
cd "$(dirname "$0")/../pro_video_player_android"
fvm flutter clean

echo ""
echo "=== example ==="
cd "$(dirname "$0")/../example"
fvm flutter clean

echo ""
echo "Clean complete!"
