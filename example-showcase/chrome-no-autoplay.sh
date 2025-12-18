#!/bin/bash
# Wrapper script to launch Chrome with autoplay restrictions disabled
# Used for E2E web testing to allow video playback without user interaction
# Combines multiple flags to bypass all autoplay restrictions for integration tests

exec "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --autoplay-policy=no-user-gesture-required \
  --disable-web-security \
  --disable-features=AutoplayIgnoreWebAudio,MediaEngagementBypassAutoplayPolicies \
  --allow-file-access-from-files \
  --use-fake-ui-for-media-stream \
  "$@"
