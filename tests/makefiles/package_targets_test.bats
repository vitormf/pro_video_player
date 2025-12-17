#!/usr/bin/env bats
# Tests for makefiles/package-targets.mk

load ../test_helper

# List of short package names
PACKAGE_NAMES="interface main web android ios macos windows linux"

# Test that targets exist for each package
@test "package-targets.mk: test-* targets exist for platform packages" {
  # Only android, ios, macos, windows, linux should have test targets
  # (interface, main, web have custom implementations)
  for pkg in android ios macos windows linux; do
    run bash -c "cd '$PROJECT_ROOT' && make -n test-$pkg 2>&1"
    assert_success
  done
}

@test "package-targets.mk: coverage-* targets exist for all packages" {
  for pkg in $PACKAGE_NAMES; do
    run bash -c "cd '$PROJECT_ROOT' && make -n coverage-$pkg 2>&1"
    assert_success
  done
}

@test "package-targets.mk: analyze-* targets exist for all packages" {
  for pkg in $PACKAGE_NAMES; do
    run bash -c "cd '$PROJECT_ROOT' && make -n analyze-$pkg 2>&1"
    assert_success
  done
}

@test "package-targets.mk: install-* targets exist for all packages" {
  for pkg in $PACKAGE_NAMES; do
    run bash -c "cd '$PROJECT_ROOT' && make -n install-$pkg 2>&1"
    assert_success
  done
}

@test "package-targets.mk: clean-* targets exist for all packages" {
  for pkg in $PACKAGE_NAMES; do
    run bash -c "cd '$PROJECT_ROOT' && make -n clean-$pkg 2>&1"
    assert_success
  done
}

@test "package-targets.mk: fix-* targets exist for all packages" {
  for pkg in $PACKAGE_NAMES; do
    run bash -c "cd '$PROJECT_ROOT' && make -n fix-$pkg 2>&1"
    assert_success
  done
}

@test "package-targets.mk: PKG_* mapping variables are defined" {
  # Check that package mapping variables exist
  for var in PKG_interface PKG_main PKG_web PKG_android PKG_ios PKG_macos PKG_windows PKG_linux; do
    run grep -q "$var :=" "$PROJECT_ROOT/makefiles/package-targets.mk"
    assert_success
  done
}

@test "package-targets.mk: define-test-target function exists" {
  run grep -q "define define-test-target" "$PROJECT_ROOT/makefiles/package-targets.mk"
  assert_success
}

@test "package-targets.mk: define-coverage-target function exists" {
  run grep -q "define define-coverage-target" "$PROJECT_ROOT/makefiles/package-targets.mk"
  assert_success
}

@test "package-targets.mk: define-analyze-target function exists" {
  run grep -q "define define-analyze-target" "$PROJECT_ROOT/makefiles/package-targets.mk"
  assert_success
}

@test "package-targets.mk: define-install-target function exists" {
  run grep -q "define define-install-target" "$PROJECT_ROOT/makefiles/package-targets.mk"
  assert_success
}

@test "package-targets.mk: define-clean-target function exists" {
  run grep -q "define define-clean-target" "$PROJECT_ROOT/makefiles/package-targets.mk"
  assert_success
}

@test "package-targets.mk: define-fix-target function exists" {
  run grep -q "define define-fix-target" "$PROJECT_ROOT/makefiles/package-targets.mk"
  assert_success
}

@test "package-targets.mk: targets use correct package directory names" {
  # test-android should cd to pro_video_player_android
  run bash -c "cd '$PROJECT_ROOT' && make -n test-android 2>&1"
  assert_success
  assert_output --regexp "pro_video_player_android"
}

@test "package-targets.mk: web targets include --platform chrome flag" {
  # coverage-web should include --platform chrome
  run bash -c "cd '$PROJECT_ROOT' && make -n coverage-web 2>&1"
  assert_success
  assert_output --regexp "platform chrome"
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
