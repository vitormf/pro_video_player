#!/usr/bin/env bats
# Tests for makefiles/test.mk

load ../test_helper

@test "test.mk: test target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n test 2>&1"
  assert_success
}

@test "test.mk: test target uses run-parallel-packages function" {
  # Check that test target calls the parallel function
  run grep -A5 "^test:" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
  assert_output --regexp "run-parallel-packages"
}

@test "test.mk: test-coverage target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n test-coverage 2>&1"
  assert_success
}

@test "test.mk: test-coverage target uses run-parallel-packages function" {
  # Check that test-coverage target calls the parallel function
  run grep -A5 "^test-coverage:" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
  assert_output --regexp "run-parallel-packages"
}

@test "test.mk: analyze target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n analyze 2>&1"
  assert_success
}

@test "test.mk: analyze target uses run-parallel-packages function" {
  # Check that analyze target calls the parallel function
  run grep -A5 "^analyze:" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
  assert_output --regexp "run-parallel-packages"
}

@test "test.mk: quick-check target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n quick-check 2>&1"
  assert_success
}

@test "test.mk: quick-check includes Dart analysis" {
  run grep "analyze" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
}

@test "test.mk: quick-check includes Kotlin compilation" {
  run grep "compileDebug" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
}

@test "test.mk: quick-check includes Swift/iOS compilation" {
  run grep "xcodebuild" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
}

@test "test.mk: quick-check includes Swift/macOS compilation" {
  run grep "xcodebuild" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
}

@test "test.mk: quick-check includes format check" {
  run grep -q "format.*--set-exit-if-changed" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
}

@test "test.mk: quick-check includes shared links verification" {
  run grep -q "verify-shared-links" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
}

@test "test.mk: quick-check includes logging verification" {
  run grep -q "check-verbose-logging" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
}

@test "test.mk: quick-check includes code duplication check" {
  run grep -q "jscpd" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
}

@test "test.mk: test-interface target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n test-interface 2>&1"
  assert_success
}

@test "test.mk: test-main target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n test-main 2>&1"
  assert_success
}

@test "test.mk: test-web target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n test-web 2>&1"
  assert_success
}

@test "test.mk: test-web uses --platform chrome" {
  run bash -c "cd '$PROJECT_ROOT' && make -n test-web 2>&1"
  assert_success
  assert_output --regexp "platform chrome"
}

@test "test.mk: test target has DRY implementation (not duplicated code)" {
  # Count the lines for test target - should be short (around 5-10 lines)
  local test_target_lines=$(sed -n '/^test:/,/^$/p' "$PROJECT_ROOT/makefiles/test.mk" | wc -l | tr -d ' ')

  # Should be less than 15 lines (was ~68 lines before refactoring)
  if [ "$test_target_lines" -gt 15 ]; then
    echo "test target has $test_target_lines lines (expected < 15)"
    return 1
  fi
}

@test "test.mk: test-coverage target has DRY implementation" {
  # Count the lines for test-coverage target - should be short
  local coverage_target_lines=$(sed -n '/^test-coverage:/,/^$/p' "$PROJECT_ROOT/makefiles/test.mk" | wc -l | tr -d ' ')

  # Should be less than 15 lines (was ~68 lines before refactoring)
  if [ "$coverage_target_lines" -gt 15 ]; then
    echo "test-coverage target has $coverage_target_lines lines (expected < 15)"
    return 1
  fi
}

@test "test.mk: analyze target has DRY implementation" {
  # Count the lines for analyze target - should be short
  local analyze_target_lines=$(sed -n '/^analyze:/,/^$/p' "$PROJECT_ROOT/makefiles/test.mk" | wc -l | tr -d ' ')

  # Should be less than 15 lines (was ~56 lines before refactoring)
  if [ "$analyze_target_lines" -gt 15 ]; then
    echo "analyze target has $analyze_target_lines lines (expected < 15)"
    return 1
  fi
}

@test "test.mk: verify-setup target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n verify-setup 2>&1"
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
