#!/usr/bin/env bats
# Tests for makefiles/selector.mk

load ../test_helper

@test "selector.mk: select target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n select 2>&1"
  assert_success
}

@test "selector.mk: select depends on _check-fzf" {
  run grep "^select:" "$PROJECT_ROOT/makefiles/selector.mk"
  assert_success
  assert_output --regexp "_check-fzf"
}

@test "selector.mk: select calls task-selector.sh script" {
  run grep "^select:" -A3 "$PROJECT_ROOT/makefiles/selector.mk"
  assert_success
  assert_output --regexp "task-selector.sh"
}

@test "selector.mk: select uses SCRIPTS_DIR variable" {
  run grep "^select:" -A3 "$PROJECT_ROOT/makefiles/selector.mk"
  assert_success
  assert_output --regexp "SCRIPTS_DIR"
}

@test "selector.mk: select passes FLUTTER variable to script" {
  run grep "^select:" -A3 "$PROJECT_ROOT/makefiles/selector.mk"
  assert_success
  assert_output --regexp "FLUTTER"
}

@test "selector.mk: select passes IOS_SIMULATOR_ID variable to script" {
  run grep "^select:" -A3 "$PROJECT_ROOT/makefiles/selector.mk"
  assert_success
  assert_output --regexp "IOS_SIMULATOR_ID"
}

@test "selector.mk: PHONY target is declared" {
  run grep "\.PHONY:" "$PROJECT_ROOT/makefiles/selector.mk"
  assert_success
  assert_output --regexp "select"
}

@test "selector.mk: file has appropriate comments" {
  run head -5 "$PROJECT_ROOT/makefiles/selector.mk"
  assert_success
  # Should mention interactive or fzf
  assert_output --regexp "(Interactive|interactive|fzf)"
}

@test "selector.mk: comments mention fzf" {
  run head -10 "$PROJECT_ROOT/makefiles/selector.mk"
  assert_success
  assert_output --regexp "fzf"
}

@test "selector.mk: comments mention categories" {
  run head -10 "$PROJECT_ROOT/makefiles/selector.mk"
  assert_success
  # Should describe category navigation
  assert_output --regexp "[Cc]ategor"
}

@test "selector.mk: is included in main Makefile" {
  run grep "selector.mk" "$PROJECT_ROOT/Makefile"
  assert_success
}

@test "selector.mk: select is the default goal" {
  run grep "\.DEFAULT_GOAL" "$PROJECT_ROOT/Makefile"
  assert_success
  assert_output --regexp "select"
}

@test "selector.mk: task-selector.sh script exists" {
  [ -f "$PROJECT_ROOT/makefiles/scripts/task-selector.sh" ]
}

@test "selector.mk: task-selector.sh is executable" {
  [ -x "$PROJECT_ROOT/makefiles/scripts/task-selector.sh" ]
}

@test "selector.mk: select target syntax is valid" {
  # Should not have syntax errors
  run bash -c "cd '$PROJECT_ROOT' && make -n select 2>&1"
  # Exit code 0 (success) or 2 (no work to do) are both fine
  [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}

@test "selector.mk: _check-fzf is defined in verify.mk" {
  run grep "^_check-fzf:" "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
}

@test "selector.mk: IOS_SIMULATOR_ID is defined in config.mk" {
  run grep "IOS_SIMULATOR_ID" "$PROJECT_ROOT/makefiles/config.mk"
  assert_success
}

@test "selector.mk: SCRIPTS_DIR is defined in config.mk" {
  run grep "SCRIPTS_DIR" "$PROJECT_ROOT/makefiles/config.mk"
  assert_success
}

@test "selector.mk: FLUTTER variable comes from config.mk" {
  run grep "^FLUTTER" "$PROJECT_ROOT/makefiles/config.mk"
  assert_success
}

@test "selector.mk: file is concise" {
  # selector.mk should be very small (just one target + comments)
  local lines=$(wc -l < "$PROJECT_ROOT/makefiles/selector.mk" | tr -d ' ')

  # Should be less than 20 lines
  if [ "$lines" -gt 20 ]; then
    echo "selector.mk has $lines lines (expected < 20 for such a simple file)"
    return 1
  fi
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
