# Pro Video Player - Flutter Plugin Makefile
# This file orchestrates all build, development, and testing tasks
# Individual task groups are organized in the makefiles/ directory

# Include symbol definitions first (used by other makefiles)
include makefiles/symbols.mk

# Include all modular makefiles
include makefiles/config.mk
include makefiles/verify.mk
include makefiles/setup.mk
include makefiles/test.mk
include makefiles/coverage.mk
include makefiles/development.mk
include makefiles/selector.mk

# Default target - interactive task selector
.DEFAULT_GOAL := select

# Declare all phony targets for shell autocompletion discovery
.PHONY: help all

# help: Show available commands
# Use when: Need a quick reference of available commands
help:
	@echo "$(PKG) Pro Video Player - Available Commands"
	@echo ""
	@echo "$(ROCKET) Quick Start:"
	@echo "  make               - Interactive task selector (fzf)"
	@echo "  make setup         - Setup FVM and install dependencies"
	@echo "  make check         - Run all checks (format, analyze, test)"
	@echo ""
	@echo "$(TOOLS) Setup & Install:"
	@echo "  make setup         - Setup FVM and install dependencies"
	@echo "  make install       - Install dependencies for all packages"
	@echo "  make clean         - Clean all packages"
	@echo "  make verify-tools  - Verify development tools"
	@echo ""
	@echo "$(TEST) Testing:"
	@echo "  make test            - Run all Dart/Flutter tests"
	@echo "  make test-unit       - Run unit tests only (pro_video_player)"
	@echo "  make test-widget     - Run widget tests only (pro_video_player)"
	@echo "  make test-interface  - Run platform_interface tests only"
	@echo "  make test-main       - Run main package tests only"
	@echo "  make test-web        - Run web package tests (Chrome)"
	@echo "  make analyze         - Analyze all packages (strict mode)"
	@echo "  make check-duplicates - Detect duplicate/copy-pasted code"
	@echo "  make quick-check     - Fast parallel compile check (Dart+Kotlin+Swift)"
	@echo "  make check           - Run format-check, analyze, duplicates, and test"
	@echo ""
	@echo "$(CHART) Coverage:"
	@echo "  make coverage      - Full coverage report (Dart + Native)"
	@echo "  make test-coverage - Run tests with coverage (Dart only)"
	@echo "  make coverage-html - Generate HTML coverage report"
	@echo "  make coverage-summary - Show coverage summary"
	@echo ""
	@echo "$(WRENCH) Native Tests:"
	@echo "  make test-native              - Run all native tests"
	@echo "  make test-android-native      - Run Android native unit tests"
	@echo "  make test-android-instrumented - Run Android instrumented tests (device)"
	@echo "  make test-ios-native          - Run iOS native tests"
	@echo "  make test-macos-native        - Run macOS native tests"
	@echo "  make test-android-native-coverage - Android unit tests with coverage"
	@echo "  make test-android-full-coverage   - Android FULL coverage (unit+device)"
	@echo "  make test-ios-native-coverage     - iOS native with coverage"
	@echo "  make test-macos-native-coverage   - macOS native with coverage"
	@echo ""
	@echo "$(ROCKET) E2E Tests:"
	@echo "  make test-e2e         - Run E2E tests (auto-detect device)"
	@echo "  make test-e2e-ios     - Run E2E tests on iOS simulator"
	@echo "  make test-e2e-android - Run E2E tests on Android emulator"
	@echo "  make test-e2e-macos   - Run E2E tests on macOS"
	@echo "  make test-e2e-web     - Run E2E tests on Chrome (web)"
	@echo ""
	@echo "$(PAINT) Code Quality:"
	@echo "  make format        - Format all Dart code"
	@echo "  make format-check  - Check code format (no changes)"
	@echo "  make fix           - Apply automatic Dart fixes"
	@echo ""
	@echo "$(ROCKET) Development:"
	@echo "  make run              - Run the example-showcase app"
	@echo "  make run-simple       - Run the example-simple-player app"
	@echo "  make pigeon-generate  - Regenerate Pigeon code (Android/iOS/macOS)"
	@echo ""
	@echo "$(INFO) Use 'make' for interactive mode or 'make <command>' directly"

# all: Run all checks and tests
# Use when: Full validation before PR
all: clean install check
	@$(call done_signal,All checks passed!)
