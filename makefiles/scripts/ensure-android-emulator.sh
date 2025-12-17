#!/bin/bash
# Ensures Android emulator is running and ready for E2E tests
# Usage: ./ensure-android-emulator.sh [avd_name]

set -e

# Default to first available AVD if not specified
if [ -n "$1" ]; then
    AVD_NAME="$1"
else
    # Try to find a suitable emulator (prefer higher API levels)
    AVAILABLE_AVDS=$(emulator -list-avds 2>/dev/null)

    if [ -z "$AVAILABLE_AVDS" ]; then
        echo "❌ No Android AVDs found"
        echo "ℹ️  Create one with: Android Studio > Tools > Device Manager"
        exit 1
    fi

    # Prefer Pixel devices with API 33+
    AVD_NAME=$(echo "$AVAILABLE_AVDS" | grep -E "Pixel.*API_3[3-9]|Pixel.*API_[4-9][0-9]" | head -1)

    # Fallback to any available AVD
    if [ -z "$AVD_NAME" ]; then
        AVD_NAME=$(echo "$AVAILABLE_AVDS" | head -1)
    fi
fi

echo "🤖 Android Emulator: $AVD_NAME"

# Check if an emulator is already running
RUNNING_DEVICES=$(adb devices -l | grep "emulator-" | wc -l | tr -d ' ')

if [ "$RUNNING_DEVICES" -gt 0 ]; then
    DEVICE_ID=$(adb devices -l | grep "emulator-" | head -1 | awk '{print $1}')
    echo "✅ Emulator already running: $DEVICE_ID"

    # Verify it's ready
    echo "⏳ Verifying emulator is ready..."
    adb -s "$DEVICE_ID" wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done'
    echo "✅ Emulator ready for E2E tests"
    exit 0
fi

# Launch emulator in background
echo "🚀 Launching emulator..."
emulator -avd "$AVD_NAME" -no-audio -no-boot-anim -no-snapshot-save -gpu swiftshader_indirect > /dev/null 2>&1 &
EMULATOR_PID=$!

echo "   PID: $EMULATOR_PID"
echo "⏳ Waiting for emulator to start..."

# Wait for device to appear (max 120 seconds)
for i in {1..120}; do
    RUNNING=$(adb devices -l | grep "emulator-" | wc -l | tr -d ' ')
    if [ "$RUNNING" -gt 0 ]; then
        DEVICE_ID=$(adb devices -l | grep "emulator-" | head -1 | awk '{print $1}')
        echo "✅ Emulator device detected: $DEVICE_ID"
        break
    fi
    sleep 1
    if [ $i -eq 120 ]; then
        echo "❌ Timeout waiting for emulator to start"
        kill $EMULATOR_PID 2>/dev/null || true
        exit 1
    fi
done

# Wait for boot to complete
echo "⏳ Waiting for emulator to boot..."
adb -s "$DEVICE_ID" wait-for-device

# Wait for boot animation to finish
for i in {1..120}; do
    BOOT_COMPLETED=$(adb -s "$DEVICE_ID" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
    if [ "$BOOT_COMPLETED" = "1" ]; then
        echo "✅ Emulator booted successfully"
        break
    fi
    sleep 1
    if [ $i -eq 120 ]; then
        echo "❌ Timeout waiting for boot to complete"
        exit 1
    fi
done

# Give it a moment to fully initialize
echo "⏳ Finalizing initialization..."
sleep 5

echo "✅ Android Emulator ready for E2E tests"
