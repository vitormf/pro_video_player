#!/bin/bash
# Ensures iOS simulator is booted and ready for E2E tests
# Usage: ./ensure-ios-simulator.sh [simulator_id]

set -e

SIMULATOR_ID="${1:-029E85C7-1570-45A5-B798-14DE432CD3E3}"

# Check if simulator exists
if ! xcrun simctl list devices | grep -q "$SIMULATOR_ID"; then
    echo "❌ Simulator $SIMULATOR_ID not found"
    echo "ℹ️  Available simulators:"
    xcrun simctl list devices | grep -E "iPhone|iPad" | grep -v "unavailable" | head -10
    exit 1
fi

# Get simulator name and state
SIMULATOR_INFO=$(xcrun simctl list devices | grep "$SIMULATOR_ID")
SIMULATOR_NAME=$(echo "$SIMULATOR_INFO" | sed -E 's/^[[:space:]]*([^(]+).*/\1/' | xargs)
CURRENT_STATE=$(echo "$SIMULATOR_INFO" | sed -E 's/.*\(([^)]+)\)[^)]*$/\1/')

echo "📱 iOS Simulator: $SIMULATOR_NAME"
echo "   State: $CURRENT_STATE"

# Boot simulator if needed
if [[ "$CURRENT_STATE" == "Shutdown" ]]; then
    echo "🚀 Booting simulator..."
    xcrun simctl boot "$SIMULATOR_ID"

    # Wait for simulator to boot (max 60 seconds)
    echo "⏳ Waiting for simulator to boot..."
    for i in {1..60}; do
        STATE=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | sed -E 's/.*\(([^)]+)\)[^)]*$/\1/')
        if [[ "$STATE" == "Booted" ]]; then
            echo "✅ Simulator booted successfully"
            break
        fi
        sleep 1
        if [ $i -eq 60 ]; then
            echo "❌ Timeout waiting for simulator to boot"
            exit 1
        fi
    done
elif [[ "$CURRENT_STATE" == "Booted" ]]; then
    echo "✅ Simulator already booted"
else
    echo "⏳ Simulator is in state: $CURRENT_STATE, waiting..."
    # Wait for it to finish booting
    for i in {1..30}; do
        STATE=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | sed -E 's/.*\(([^)]+)\)[^)]*$/\1/')
        if [[ "$STATE" == "Booted" ]]; then
            echo "✅ Simulator ready"
            break
        fi
        sleep 1
    done
fi

# Give it a moment to fully initialize
sleep 2

echo "✅ iOS Simulator ready for E2E tests"
