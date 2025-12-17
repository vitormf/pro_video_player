#!/usr/bin/env bats
# Tests for makefiles/config.mk

load ../test_helper

@test "config.mk: PACKAGES variable is defined" {
  run bash -c "cd '$PROJECT_ROOT' && make print-PACKAGES"
  assert_success
  assert_output --regexp "pro_video_player"
}

@test "config.mk: FVM detection works" {
  run bash -c "cd '$PROJECT_ROOT' && make print-FVM"
  assert_success
}

@test "config.mk: FLUTTER variable is set" {
  run bash -c "cd '$PROJECT_ROOT' && make print-FLUTTER"
  assert_success
  assert_output --regexp "(flutter|fvm flutter)"
}

@test "config.mk: DART variable is set" {
  run bash -c "cd '$PROJECT_ROOT' && make print-DART"
  assert_success
  assert_output --regexp "(dart|fvm dart)"
}

@test "config.mk: OUTPUT_REDIRECT is set based on VERBOSE" {
  # Default (not verbose) should redirect
  run bash -c "cd '$PROJECT_ROOT' && make print-OUTPUT_REDIRECT 2>/dev/null"
  assert_success
  # The output should contain redirection
  [[ "$output" == *"/dev/null"* ]]

  # With VERBOSE=1 should not redirect (empty)
  run bash -c "cd '$PROJECT_ROOT' && VERBOSE=1 make print-OUTPUT_REDIRECT 2>/dev/null"
  assert_success
  # Should be empty or not contain /dev/null
  [[ "$output" != *"/dev/null"* ]] || [ -z "$output" ]
}

@test "config.mk: All packages are listed in PACKAGES" {
  run bash -c "cd '$PROJECT_ROOT' && make print-PACKAGES"
  assert_success

  # Check for expected packages
  assert_output --regexp "pro_video_player_platform_interface"
  assert_output --regexp "pro_video_player"
  assert_output --regexp "pro_video_player_ios"
  assert_output --regexp "pro_video_player_android"
  assert_output --regexp "pro_video_player_web"
  assert_output --regexp "pro_video_player_macos"
}

@test "config.mk: run-parallel-packages function exists" {
  # Check if function is defined in config.mk
  run grep -q "define run-parallel-packages" "$PROJECT_ROOT/makefiles/config.mk"
  assert_success
}

@test "config.mk: print-% helper works for any variable" {
  run bash -c "cd '$PROJECT_ROOT' && make print-PROJECT_ROOT 2>/dev/null || make print-MAKEFILES_DIR"
  assert_success
}

# Helper function for assertions
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
      echo "Output '$output' does not match pattern '$2'"
      return 1
    fi
  else
    if [ "$output" != "$1" ]; then
      echo "Expected: $1"
      echo "Got: $output"
      return 1
    fi
  fi
}

refute_output() {
  if [ "$output" = "$1" ]; then
    echo "Output should not be: $1"
    return 1
  fi
}
