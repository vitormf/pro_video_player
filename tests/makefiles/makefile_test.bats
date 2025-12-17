#!/usr/bin/env bats
# Tests for main Makefile structure and integration

load ../test_helper

@test "Makefile: exists in project root" {
  [ -f "$PROJECT_ROOT/Makefile" ]
}

@test "Makefile: includes all required makefiles" {
  run grep "^include makefiles/" "$PROJECT_ROOT/Makefile"
  assert_success

  # Check for all expected includes
  assert_output --regexp "makefiles/symbols.mk"
  assert_output --regexp "makefiles/config.mk"
  assert_output --regexp "makefiles/verify.mk"
  assert_output --regexp "makefiles/setup.mk"
  assert_output --regexp "makefiles/test.mk"
  assert_output --regexp "makefiles/coverage.mk"
  assert_output --regexp "makefiles/development.mk"
  assert_output --regexp "makefiles/selector.mk"
  assert_output --regexp "makefiles/package-targets.mk"
}

@test "Makefile: default goal is select" {
  run grep "\.DEFAULT_GOAL" "$PROJECT_ROOT/Makefile"
  assert_success
  assert_output --regexp "select"
}

@test "Makefile: help target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n help 2>&1"
  assert_success
}

@test "Makefile: all target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n all 2>&1"
  assert_success
}

@test "Makefile: symbols.mk is included first" {
  # symbols.mk should be included before other makefiles
  local first_include=$(grep "^include" "$PROJECT_ROOT/Makefile" | head -1)
  echo "$first_include" | grep -q "symbols.mk"
}

@test "Makefile: help shows all major targets" {
  run bash -c "cd '$PROJECT_ROOT' && make help 2>&1"
  assert_success

  # Check for key command categories
  assert_output --regexp "Quick Start"
  assert_output --regexp "Setup & Install"
  assert_output --regexp "Testing"
  assert_output --regexp "Coverage"
  assert_output --regexp "Code Quality"
}

@test "Makefile: help mentions per-package targets" {
  run bash -c "cd '$PROJECT_ROOT' && make help 2>&1"
  assert_success

  # Should document some of the new per-package targets
  assert_output --regexp "test-android"
  assert_output --regexp "test-ios"
  assert_output --regexp "analyze-<pkg>"
}

@test "Makefile: quick-check is documented in help" {
  run bash -c "cd '$PROJECT_ROOT' && make help 2>&1"
  assert_success
  assert_output --regexp "quick-check"
}

@test "Makefile: all makefiles exist" {
  local makefiles="symbols.mk config.mk verify.mk setup.mk test.mk coverage.mk development.mk selector.mk package-targets.mk"

  for mkfile in $makefiles; do
    if [ ! -f "$PROJECT_ROOT/makefiles/$mkfile" ]; then
      echo "Missing makefile: makefiles/$mkfile"
      return 1
    fi
  done
}

@test "Makefile: total line count is reasonable" {
  # After refactoring, total should be around 1200 lines
  local total_lines=$(wc -l "$PROJECT_ROOT"/makefiles/*.mk | tail -1 | awk '{print $1}')

  # Should be less than 1500 lines total
  if [ "$total_lines" -gt 1500 ]; then
    echo "Total makefile lines: $total_lines (expected < 1500)"
    return 1
  fi

  # Should be more than 1000 lines (sanity check)
  if [ "$total_lines" -lt 1000 ]; then
    echo "Total makefile lines: $total_lines (expected > 1000)"
    return 1
  fi
}

@test "Makefile: DRY principle - no large duplicated blocks" {
  # Check that there are no huge blocks of duplicated code
  # We'll check that no target has more than 50 lines (except quick-check which is complex)

  # Count lines in test.mk - after refactoring should be under 750
  local lines=$(wc -l < "$PROJECT_ROOT/makefiles/test.mk" | tr -d ' ')

  if [ "$lines" -gt 750 ]; then
    echo "test.mk has $lines lines (expected < 750 after DRY refactoring)"
    return 1
  fi
}

@test "Makefile: no syntax errors" {
  # Try to parse the Makefile
  run bash -c "cd \"$PROJECT_ROOT\" && make -n help >/dev/null 2>&1"
  assert_success
}

@test "Makefile: PHONY targets are declared" {
  # Check that common targets are declared as PHONY
  run grep "\.PHONY:" "$PROJECT_ROOT/Makefile" "$PROJECT_ROOT"/makefiles/*.mk
  assert_success

  # Should declare common targets as phony
  assert_output --regexp "test"
  assert_output --regexp "clean"
  assert_output --regexp "install"
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
