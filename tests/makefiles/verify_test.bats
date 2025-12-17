#!/usr/bin/env bats
# Tests for makefiles/verify.mk

load ../test_helper

@test "verify.mk: verify-tools target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n verify-tools 2>&1"
  assert_success
}

@test "verify.mk: verify-setup target exists" {
  run bash -c "cd '$PROJECT_ROOT' && make -n verify-setup 2>&1"
  assert_success
}

@test "verify.mk: _check-fvm internal target exists" {
  run grep -q "^_check-fvm:" "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
}

@test "verify.mk: _check-flutter internal target exists" {
  run grep -q "^_check-flutter:" "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
}

@test "verify.mk: _check-fzf internal target exists" {
  run grep -q "^_check-fzf:" "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
}

@test "verify.mk: _check-lcov internal target exists" {
  run grep -q "^_check-lcov:" "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
}

@test "verify.mk: verify-tools calls _check-fvm" {
  run grep "^verify-tools:" -A3 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  assert_output --regexp "_check-fvm"
}

@test "verify.mk: verify-tools calls _check-flutter" {
  run grep "^verify-tools:" -A3 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  assert_output --regexp "_check-flutter"
}

@test "verify.mk: RECOMMENDED_FVM_VERSION is defined" {
  run grep "^RECOMMENDED_FVM_VERSION" "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  # Should have a version number
  assert_output --regexp "[0-9]+\.[0-9]+\.[0-9]+"
}

@test "verify.mk: BREW_HELPERS is defined and sources script" {
  run grep "^BREW_HELPERS" "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  assert_output --regexp "brew-helpers.sh"
}

@test "verify.mk: verify-setup checks for shared links" {
  run grep "^verify-setup:" -A15 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  # Should check for SharedVideoPlayer.swift
  assert_output --regexp "SharedVideoPlayer.swift"
}

@test "verify.mk: verify-setup calls verify-shared-links.sh script" {
  run grep "^verify-setup:" -A15 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  assert_output --regexp "verify-shared-links.sh"
}

@test "verify.mk: verify-setup checks git hooks configuration" {
  run grep "^verify-setup:" -A20 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  # Should check for core.hooksPath
  assert_output --regexp "core.hooksPath"
  assert_output --regexp ".githooks"
}

@test "verify.mk: _check-fvm checks for fvm command" {
  run grep "_check-fvm:" -A10 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  assert_output --regexp "command -v fvm"
}

@test "verify.mk: _check-fvm checks version" {
  run grep "_check-fvm:" -A10 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  # Should get fvm version
  assert_output --regexp "fvm --version"
  # Should compare with recommended version
  assert_output --regexp "version_less_than"
}

@test "verify.mk: _check-flutter reads .fvmrc" {
  run grep "_check-flutter:" -A30 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  assert_output --regexp ".fvmrc"
  assert_output --regexp "expected_flutter"
}

@test "verify.mk: _check-flutter validates Flutter version" {
  run grep "_check-flutter:" -A30 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  # Should check flutter version
  assert_output --regexp "flutter_version"
  # Should compare with expected
  assert_output --regexp "expected_flutter"
}

@test "verify.mk: _check-flutter can install missing Flutter version" {
  run grep "_check-flutter:" -A30 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  # Should be able to install via FVM
  assert_output --regexp "fvm install"
}

@test "verify.mk: _check-fzf checks for fzf command" {
  run grep "_check-fzf:" -A5 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  assert_output --regexp "command -v fzf"
}

@test "verify.mk: _check-lcov checks for lcov command" {
  run grep "_check-lcov:" -A5 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  assert_output --regexp "command -v lcov"
}

@test "verify.mk: all check targets use BREW_HELPERS" {
  # All internal check targets should source brew helpers
  for target in _check-fvm _check-fzf _check-lcov; do
    run grep "^$target:" -A5 "$PROJECT_ROOT/makefiles/verify.mk"
    assert_success
    assert_output --regexp "BREW_HELPERS"
  done
}

@test "verify.mk: verify-setup exits on missing shared links" {
  run grep "^verify-setup:" -A10 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  # Should exit with error if links missing
  assert_output --regexp "exit 1"
}

@test "verify.mk: verify-setup exits on out-of-sync shared links" {
  run grep "^verify-setup:" -A15 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  # Should check sync and exit if failed
  assert_output --regexp "verify-shared-links.sh"
  assert_output --regexp "exit 1"
}

@test "verify.mk: verify-setup provides helpful error messages" {
  run grep "^verify-setup:" -A20 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  # Should tell user how to fix issues
  assert_output --regexp "make setup"
  assert_output --regexp "make setup-shared-links"
  assert_output --regexp "make setup-git-hooks"
}

@test "verify.mk: PHONY targets are declared" {
  run grep "\.PHONY:" "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  assert_output --regexp "verify-tools"
  assert_output --regexp "verify-setup"
}

@test "verify.mk: verify-setup is called by test targets" {
  # verify-setup should be a dependency of test targets
  run grep "^test:" "$PROJECT_ROOT/makefiles/test.mk"
  assert_success
  assert_output --regexp "verify-setup"
}

@test "verify.mk: file structure is correct" {
  # Should have appropriate comments
  run head -5 "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  assert_output --regexp "verification"
}

@test "verify.mk: uses OUTPUT_REDIRECT for quiet mode" {
  run grep "OUTPUT_REDIRECT" "$PROJECT_ROOT/makefiles/verify.mk"
  assert_success
  # Should be used in install/upgrade commands
}

# Integration test - verify-setup should pass in current project state
@test "verify.mk: verify-setup passes in current environment" {
  # This tests the actual state of the project
  # Skip if shared links aren't set up
  if [ ! -f "$PROJECT_ROOT/pro_video_player_ios/ios/Classes/Shared/SharedVideoPlayer.swift" ]; then
    skip "Shared links not set up (run make setup)"
  fi

  run bash -c "cd '$PROJECT_ROOT' && make verify-setup 2>&1"
  # Should succeed or warn about git hooks
  [ "$status" -eq 0 ] || assert_output --regexp "Git hooks"
}

# Integration test - verify that brew-helpers.sh exists
@test "verify.mk: brew-helpers.sh script exists" {
  [ -f "$PROJECT_ROOT/makefiles/scripts/brew-helpers.sh" ]
}

# Integration test - verify that verify-shared-links.sh exists
@test "verify.mk: verify-shared-links.sh script exists" {
  [ -f "$PROJECT_ROOT/makefiles/scripts/verify-shared-links.sh" ]
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
