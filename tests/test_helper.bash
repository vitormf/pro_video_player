#!/usr/bin/env bash
# Test helper functions for BATS tests

# Project root directory
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Setup function - runs before each test
setup() {
  # Save original directory
  export ORIGINAL_DIR="$(pwd)"

  # Change to project root
  cd "$PROJECT_ROOT"

  # Create temp directory for test artifacts
  export TEST_TEMP_DIR="$(mktemp -d)"
}

# Teardown function - runs after each test
teardown() {
  # Clean up temp directory
  if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
    rm -rf "$TEST_TEMP_DIR"
  fi

  # Restore original directory
  cd "$ORIGINAL_DIR"
}

# Helper: Run make command with error handling
run_make() {
  run make "$@"
}

# Helper: Check if a makefile target exists
target_exists() {
  local target="$1"
  make -n "$target" >/dev/null 2>&1
}

# Helper: Get package list from config.mk
get_packages() {
  grep "^PACKAGES :=" makefiles/config.mk | sed 's/PACKAGES := //'
}

# Helper: Count lines in makefile
count_makefile_lines() {
  local makefile="$1"
  wc -l < "$makefile" | tr -d ' '
}

# Helper: Check if FVM is being used
using_fvm() {
  grep -q "FVM := 1" makefiles/config.mk
}

# Helper: Skip test if command not available
require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    skip "$cmd is not installed"
  fi
}
