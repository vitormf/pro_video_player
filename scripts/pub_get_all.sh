#!/bin/bash
# Get dependencies for all packages

set -e

echo "Getting dependencies for all packages..."

echo ""
echo "=== pro_video_player_platform_interface ==="
cd "$(dirname "$0")/../pro_video_player_platform_interface"
fvm flutter pub get

echo ""
echo "=== pro_video_player ==="
cd "$(dirname "$0")/../pro_video_player"
fvm flutter pub get

echo ""
echo "=== pro_video_player_ios ==="
cd "$(dirname "$0")/../pro_video_player_ios"
fvm flutter pub get

echo ""
echo "=== pro_video_player_android ==="
cd "$(dirname "$0")/../pro_video_player_android"
fvm flutter pub get

echo ""
echo "=== example ==="
cd "$(dirname "$0")/../example"
fvm flutter pub get

echo ""
echo "Dependencies installed!"
