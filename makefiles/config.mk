# Configuration and tool detection for the Flutter plugin project
#
# CI Support:
# When the CI environment variable is set, the makefiles will:
# - Auto-confirm all prompts (assume 'y' for yes/no questions)
# - Skip audio notifications (no 'say' commands)
# - Use the same OUTPUT_REDIRECT behavior (controlled by VERBOSE)

# Directories
MAKEFILES_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SCRIPTS_DIR := $(MAKEFILES_DIR)scripts

# All packages in the project
PACKAGES := pro_video_player_platform_interface pro_video_player pro_video_player_ios pro_video_player_android pro_video_player_web pro_video_player_macos pro_video_player_windows pro_video_player_linux

# Flutter Version Manager (FVM) detection and setup
ifeq ("no", "$(shell command -v fvm >/dev/null 2>&1 && echo yes || echo no)")
FVM :=
FLUTTER := flutter
DART := dart
else
FVM := 1
FLUTTER := fvm flutter
DART := fvm dart
endif

# HTML code coverage report generator detection
ifeq ("no", "$(shell command -v genhtml >/dev/null 2>&1 && echo yes || echo no)")
GENHTML :=
else
GENHTML := 1
endif

# Verbose/Silent mode detection based on VERBOSE environment variable
# When VERBOSE=1 is set, we want verbose output during actual execution
# Otherwise, we want silent output for clean user experience
ifeq ($(VERBOSE),1)
OUTPUT_REDIRECT :=
POD_SILENT :=
else
OUTPUT_REDIRECT := > /dev/null 2>&1
POD_SILENT := --silent
endif

# iOS simulator ID (default)
IOS_SIMULATOR_ID ?= 029E85C7-1570-45A5-B798-14DE432CD3E3

# Helper target for testing - print any variable value
# Usage: make print-VARIABLE_NAME
.PHONY: print-%
print-%:
	@echo $($*)
