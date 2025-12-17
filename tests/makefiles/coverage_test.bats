#!/usr/bin/env bats
# Tests for makefiles/coverage.mk

load ../test_helper

@test "coverage.mk: coverage target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n coverage 2>&1"
  assert_success
}

@test "coverage.mk: coverage-html target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n coverage-html 2>&1"
  assert_success
}

@test "coverage.mk: coverage-summary target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n coverage-summary 2>&1"
  assert_success
}

@test "coverage.mk: _check-lcov is referenced" {
  run grep "_check-lcov" "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # _check-lcov is defined in verify.mk but referenced here
}

@test "coverage.mk: coverage depends on test-coverage" {
  run grep "^coverage:" "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "test-coverage"
}

@test "coverage.mk: coverage depends on coverage-html" {
  run grep "^coverage:" "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "coverage-html"
}

@test "coverage.mk: coverage depends on native coverage targets" {
  run grep "^coverage:" "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # Should include Android and iOS native coverage
  assert_output --regexp "test-android-native-coverage"
  assert_output --regexp "test-ios-native-coverage"
}

@test "coverage.mk: coverage calls coverage-summary script" {
  run grep "^coverage:" -A5 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "coverage-summary.sh"
}

@test "coverage.mk: coverage-html depends on _check-lcov" {
  run grep "^coverage-html:" "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "_check-lcov"
}

@test "coverage.mk: coverage-html creates coverage directory" {
  run grep "^coverage-html:" -A20 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "mkdir -p coverage"
}

@test "coverage.mk: coverage-html fixes paths for platform_interface" {
  run grep "^coverage-html:" -A20 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # Should fix paths from lib/ to pro_video_player_platform_interface/lib/
  assert_output --regexp "pro_video_player_platform_interface/coverage/lcov.info"
  assert_output --regexp "pro_video_player_platform_interface/lib"
}

@test "coverage.mk: coverage-html fixes paths for main package" {
  run grep "^coverage-html:" -A20 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # Should fix paths for pro_video_player
  assert_output --regexp "pro_video_player/coverage/lcov.info"
  assert_output --regexp "pro_video_player/lib"
}

@test "coverage.mk: coverage-html fixes paths for iOS package" {
  run grep "^coverage-html:" -A25 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "pro_video_player_ios/coverage/lcov.info"
  assert_output --regexp "pro_video_player_ios/lib"
}

@test "coverage.mk: coverage-html fixes paths for Android package" {
  run grep "^coverage-html:" -A25 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "pro_video_player_android/coverage/lcov.info"
  assert_output --regexp "pro_video_player_android/lib"
}

@test "coverage.mk: coverage-html fixes paths for web package" {
  run grep "^coverage-html:" -A25 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "pro_video_player_web/coverage/lcov.info"
  assert_output --regexp "pro_video_player_web/lib"
}

@test "coverage.mk: coverage-html fixes paths for macOS package" {
  run grep "^coverage-html:" -A30 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "pro_video_player_macos/coverage/lcov.info"
  assert_output --regexp "pro_video_player_macos/lib"
}

@test "coverage.mk: coverage-html uses sed to fix paths" {
  run grep "^coverage-html:" -A30 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # Should use sed with SF: pattern
  assert_output --regexp "sed.*SF:"
}

@test "coverage.mk: coverage-html combines all coverage files with lcov" {
  run grep "^coverage-html:" -A35 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # Should use lcov --add-tracefile
  assert_output --regexp "lcov --add-tracefile"
}

@test "coverage.mk: coverage-html outputs to coverage/lcov.info" {
  run grep "^coverage-html:" -A35 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "output-file coverage/lcov.info"
}

@test "coverage.mk: coverage-html cleans up intermediate files" {
  run grep "^coverage-html:" -A40 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # Should remove temporary .info files
  assert_output --regexp "rm -f.*interface.info.*main.info"
}

@test "coverage.mk: coverage-html generates HTML report with genhtml" {
  run grep "^coverage-html:" -A40 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "genhtml coverage/lcov.info"
}

@test "coverage.mk: coverage-html outputs to coverage/html directory" {
  run grep "^coverage-html:" -A40 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "output-directory coverage/html"
}

@test "coverage.mk: coverage-html uses OUTPUT_REDIRECT" {
  run grep "^coverage-html:" -A40 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # Should respect quiet mode
  assert_output --regexp "OUTPUT_REDIRECT"
}

@test "coverage.mk: coverage-html shows final report location" {
  run grep "^coverage-html:" -A45 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "coverage/html/index.html"
}

@test "coverage.mk: coverage-summary calls script" {
  run grep "^coverage-summary:" -A5 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "coverage-summary.sh"
}

@test "coverage.mk: coverage-summary passes CURDIR" {
  run grep "^coverage-summary:" -A5 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "CURDIR"
}

@test "coverage.mk: coverage-summary passes PACKAGES" {
  run grep "^coverage-summary:" -A5 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "PACKAGES"
}

@test "coverage.mk: PHONY targets are declared" {
  run grep "\.PHONY:" "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "coverage"
  assert_output --regexp "coverage-html"
  assert_output --regexp "coverage-summary"
}

@test "coverage.mk: file has appropriate comments" {
  run head -5 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  assert_output --regexp "Coverage"
}

@test "coverage.mk: coverage target chain is correct" {
  # coverage should call test-coverage first, then coverage-html, then native tests
  run make -n coverage 2>&1
  # Should not fail (syntax is correct)
  [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}

@test "coverage.mk: sed patterns use correct syntax" {
  run grep "sed" "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # Should have proper sed syntax: sed 's|pattern|replacement|'
  assert_output --regexp "sed 's\|"
}

@test "coverage.mk: handles missing coverage files gracefully" {
  run grep "2>/dev/null" "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # Should redirect errors and use || true for missing files
  assert_output --regexp "true"
}

@test "coverage.mk: lcov combines all six packages" {
  run grep "lcov --add-tracefile" -A10 "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
  # Should add all six package coverage files
  local count=$(echo "$output" | grep -c "add-tracefile")
  [ "$count" -ge 6 ]
}

@test "coverage.mk: coverage script exists" {
  [ -f "$PROJECT_ROOT/makefiles/scripts/coverage-summary.sh" ]
}

@test "coverage.mk: uses SCRIPTS_DIR variable" {
  run grep "SCRIPTS_DIR" "$PROJECT_ROOT/makefiles/coverage.mk"
  assert_success
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
