#!/usr/bin/env bats
# Tests for makefiles/setup.mk

load ../test_helper

@test "setup.mk: setup target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n setup 2>&1"
  assert_success
}

@test "setup.mk: install target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n install 2>&1"
  assert_success
}

@test "setup.mk: clean target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n clean 2>&1"
  assert_success
}

@test "setup.mk: format target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n format 2>&1"
  assert_success
}

@test "setup.mk: format-check target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n format-check 2>&1"
  assert_success
}

@test "setup.mk: fix target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n fix 2>&1"
  assert_success
}

@test "setup.mk: setup-shared-links target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n setup-shared-links 2>&1"
  assert_success
}

@test "setup.mk: verify-shared-links target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n verify-shared-links 2>&1"
  assert_success
}

@test "setup.mk: setup-git-hooks target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n setup-git-hooks 2>&1"
  assert_success
}

@test "setup.mk: done_signal function is defined" {
  run grep -q "define done_signal" "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
}

@test "setup.mk: done_signal handles CI environment" {
  # Should check for CI variable
  run grep -A5 "define done_signal" "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
  assert_output --regexp "CI"
}

@test "setup.mk: format excludes generated files" {
  # Should exclude *.g.dart, *.freezed.dart, etc.
  run grep -A10 "^format:" "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
  assert_output --regexp "\.g\.dart"
  assert_output --regexp "\.freezed\.dart"
  assert_output --regexp "pigeon_generated"
}

@test "setup.mk: format-check uses --set-exit-if-changed" {
  run grep "format-check:" -A10 "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
  assert_output --regexp "set-exit-if-changed"
}

@test "setup.mk: format uses 120 character line length" {
  run grep "format:" -A10 "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
  assert_output --regexp "l 120"
}

@test "setup.mk: install target iterates over all packages" {
  run grep "install:" -A10 "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
  assert_output --regexp "PACKAGES"
}

@test "setup.mk: install includes example-showcase" {
  run grep "install:" -A10 "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
  assert_output --regexp "example-showcase"
}

@test "setup.mk: clean target iterates over all packages" {
  run grep "clean:" -A10 "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
  assert_output --regexp "PACKAGES"
}

@test "setup.mk: setup calls verify-tools" {
  run grep "^setup:" -A5 "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
  assert_output --regexp "verify-tools"
}

@test "setup.mk: setup calls setup-shared-links" {
  run grep "^setup:" -A10 "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
  assert_output --regexp "setup-shared-links"
}

@test "setup.mk: setup calls setup-git-hooks" {
  run grep "^setup:" -A10 "$PROJECT_ROOT/makefiles/setup.mk"
  assert_success
  assert_output --regexp "setup-git-hooks"
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
