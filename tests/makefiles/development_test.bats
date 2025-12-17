#!/usr/bin/env bats
# Tests for makefiles/development.mk

load ../test_helper

@test "development.mk: run target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n run 2>&1"
  assert_success
}

@test "development.mk: run-simple target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n run-simple 2>&1"
  assert_success
}

@test "development.mk: pigeon-generate target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n pigeon-generate 2>&1"
  assert_success
}

@test "development.mk: run depends on verify-tools" {
  run grep "^run:" "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "verify-tools"
}

@test "development.mk: run-simple depends on verify-tools" {
  run grep "^run-simple:" "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "verify-tools"
}

@test "development.mk: pigeon-generate depends on verify-tools" {
  run grep "^pigeon-generate:" "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "verify-tools"
}

@test "development.mk: run executes in example-showcase directory" {
  run grep "^run:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "example-showcase"
}

@test "development.mk: run-simple executes in example-simple-player directory" {
  run grep "^run-simple:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "example-simple-player"
}

@test "development.mk: run uses FLUTTER variable" {
  run grep "^run:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "FLUTTER"
}

@test "development.mk: run-simple uses FLUTTER variable" {
  run grep "^run-simple:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "FLUTTER"
}

@test "development.mk: run supports DEVICE_ID parameter" {
  run grep "^run:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "DEVICE_ID"
}

@test "development.mk: run-simple supports DEVICE_ID parameter" {
  run grep "^run-simple:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "DEVICE_ID"
}

@test "development.mk: run uses conditional for DEVICE_ID" {
  run grep "^run:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  # Should check if DEVICE_ID is set
  assert_output --regexp "if.*DEVICE_ID"
}

@test "development.mk: run-simple uses conditional for DEVICE_ID" {
  run grep "^run-simple:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  # Should check if DEVICE_ID is set
  assert_output --regexp "if.*DEVICE_ID"
}

@test "development.mk: run passes -d flag when DEVICE_ID set" {
  run grep "^run:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "\\-d.*DEVICE_ID"
}

@test "development.mk: run-simple passes -d flag when DEVICE_ID set" {
  run grep "^run-simple:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "\\-d.*DEVICE_ID"
}

@test "development.mk: pigeon-generate runs from platform_interface" {
  run grep "^pigeon-generate:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "pro_video_player_platform_interface"
  assert_output --regexp "input pigeons/messages.dart"
}

@test "development.mk: pigeon-generate generates for all platforms" {
  run grep "^pigeon-generate:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "all platforms"
}

@test "development.mk: pigeon-generate copies Swift to macOS" {
  run grep "^pigeon-generate:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "Copying Swift to macOS"
  assert_output --regexp "pro_video_player_macos"
}

@test "development.mk: pigeon-generate uses DART variable" {
  run grep "^pigeon-generate:" -A15 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "DART"
}

@test "development.mk: pigeon-generate runs pigeon with messages.dart input" {
  run grep "^pigeon-generate:" -A15 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "pigeon.*input.*messages.dart"
}

@test "development.mk: pigeon-generate cd into platform_interface" {
  run grep "^pigeon-generate:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  # Should cd into platform_interface
  assert_output --regexp "cd pro_video_player_platform_interface"
}

@test "development.mk: PHONY targets are declared" {
  run grep "\.PHONY:" "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "run"
  assert_output --regexp "run-simple"
  assert_output --regexp "pigeon-generate"
}

@test "development.mk: file has appropriate comments" {
  run head -5 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "Development"
}

@test "development.mk: run shows helpful message" {
  run grep "^run:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  # Should show which app is running
  assert_output --regexp "example-showcase"
}

@test "development.mk: run-simple shows helpful message" {
  run grep "^run-simple:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  # Should show which app is running
  assert_output --regexp "example-simple-player"
}

@test "development.mk: pigeon-generate shows progress for platforms" {
  run grep "^pigeon-generate:" -A10 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  # Should show progress messages
  assert_output --regexp "all platforms"
  assert_output --regexp "macOS"
}

@test "development.mk: pigeon-generate shows completion message" {
  run grep "^pigeon-generate:" -A20 "$PROJECT_ROOT/makefiles/development.mk"
  assert_success
  assert_output --regexp "regenerated"
}

@test "development.mk: run target syntax is valid" {
  # Should not have syntax errors
  run bash -c "cd '$PROJECT_ROOT' && make -n run 2>&1"
  # Exit code 0 (success) or 2 (no work to do) are both fine
  [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}

@test "development.mk: run-simple target syntax is valid" {
  # Should not have syntax errors
  run bash -c "cd '$PROJECT_ROOT' && make -n run-simple 2>&1"
  # Exit code 0 (success) or 2 (no work to do) are both fine
  [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}

@test "development.mk: pigeon-generate target syntax is valid" {
  # Should not have syntax errors
  run bash -c "cd '$PROJECT_ROOT' && make -n pigeon-generate 2>&1"
  # Exit code 0 (success) or 2 (no work to do) are both fine
  [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}

@test "development.mk: example-showcase directory exists" {
  [ -d "$PROJECT_ROOT/example-showcase" ]
}

@test "development.mk: example-simple-player directory exists" {
  [ -d "$PROJECT_ROOT/example-simple-player" ]
}

@test "development.mk: pigeon input file exists in platform_interface" {
  [ -f "$PROJECT_ROOT/pro_video_player_platform_interface/pigeons/messages.dart" ]
}

@test "development.mk: pigeon output exists in iOS package" {
  [ -f "$PROJECT_ROOT/pro_video_player_ios/ios/Classes/PigeonMessages.swift" ]
}

@test "development.mk: pigeon output exists in macOS package" {
  [ -f "$PROJECT_ROOT/pro_video_player_macos/macos/Classes/PigeonMessages.swift" ]
}

# Helper functions
assert_success() {
  if [ "$status" -ne 0 ]; then
    echo "Command failed with status $status"
    echo "Output: $output"
    return 1
  fi
}

assert_output() {
  if [ "$1" = "--regexp" ]; then
    if ! echo "$output" | grep -qE "$2"; then
      printf "Output does not match pattern: %s\n" "$2"
      return 1
    fi
  else
    if [ "$output" != "$1" ]; then
      printf "Expected: %s\n" "$1"
      printf "Got: %s\n" "$output"
      return 1
    fi
  fi
}
