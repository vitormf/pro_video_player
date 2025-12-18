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

# iOS simulator ID (default: iPhone 16)
# Override with: make test-e2e-ios IOS_SIMULATOR_ID=your-simulator-id
IOS_SIMULATOR_ID ?= 029E85C7-1570-45A5-B798-14DE432CD3E3

# Android AVD name (default: auto-detect best available)
# Override with: make test-e2e-android ANDROID_AVD_NAME=your-avd-name
ANDROID_AVD_NAME ?=

# Helper target for testing - print any variable value
# Usage: make print-VARIABLE_NAME
.PHONY: print-%
print-%:
	@echo $($*)

# Helper function: Run command on multiple packages in parallel
# Usage: $(call run-parallel-packages,package_list,command,web_extra_flags,success_msg_singular,fail_msg)
# Parameters:
#   1: package_list - Space-separated list of packages (e.g., $(PACKAGES))
#   2: command - Command to run in each package (e.g., ${FLUTTER} test)
#   3: web_extra_flags - Extra flags for pro_video_player_web (e.g., --platform chrome)
#   4: success_msg_singular - Success message for one package (e.g., "passed", "coverage generated")
#   5: fail_msg - Failure message (e.g., "Some tests failed", "Coverage generation failed")
define run-parallel-packages
	pkg_count=$$(echo $(1) | wc -w | tr -d ' '); \
	logs=""; \
	for pkg in $(1); do \
		log=$$(mktemp); \
		logs="$$logs $$log"; \
		( \
			pkg_name="$$pkg"; \
			test_start=$$(date +%s); \
			if [ "$$pkg_name" = "pro_video_player_web" ] && [ -n "$(3)" ]; then \
				(cd $$pkg_name && $(2) $(3) $(OUTPUT_REDIRECT)); exit_code=$$?; \
			else \
				(cd $$pkg_name && $(2) $(OUTPUT_REDIRECT)); exit_code=$$?; \
			fi; \
			test_end=$$(date +%s); \
			if [ $$exit_code -eq 0 ]; then \
				echo "$$pkg_name:OK:$$(( $$test_end - $$test_start ))" > $$log; \
			elif [ $$exit_code -eq 124 ]; then \
				echo "$$pkg_name:TIMEOUT:$$(( $$test_end - $$test_start ))" > $$log; \
			else \
				echo "$$pkg_name:FAILED:$$(( $$test_end - $$test_start ))" > $$log; \
			fi \
		) & \
	done; \
	\
	parse_result() { cat $$$$1 2>/dev/null | cut -d: -f2; }; \
	has_failures=0; completed=""; count=0; wait_count=0; loop_start=$$(date +%s); \
	while true; do \
		all_done=1; \
		for log in $$logs; do \
			case "$$completed" in *"$$log"*) continue ;; esac; \
			result=$$(parse_result "$$log"); \
			if [ -n "$$result" ]; then \
				output=$$(cat $$log); \
				pkg=$$(echo "$$output" | cut -d: -f1); \
				time=$$(echo "$$output" | cut -d: -f3); \
				count=$$((count + 1)); \
				if [ "$$result" = "OK" ]; then \
					printf "%d/%d $(CHECK) $$pkg: $(4) ($$$${time}s)\n" "$$count" "$$pkg_count"; \
				elif [ "$$result" = "TIMEOUT" ]; then \
					printf "%d/%d $(WARN) $$pkg: timeout ($$$${time}s)\n" "$$count" "$$pkg_count"; \
					has_failures=1; \
				else \
					printf "%d/%d $(CROSS) $$pkg: failed ($$$${time}s)\n" "$$count" "$$pkg_count"; \
					has_failures=1; \
				fi; \
				completed="$$completed $$log"; \
				wait_count=0; \
			else \
				all_done=0; \
			fi; \
		done; \
		[ $$all_done -eq 1 ] && break; \
		wait_count=$$((wait_count + 1)); \
		if [ $$((wait_count % 50)) -eq 0 ]; then \
			elapsed_now=$$(($$( date +%s) - loop_start)); \
			printf "\r$(HOURGLASS) Running tests... %d/%d complete (%ds elapsed)" "$$count" "$$pkg_count" "$$elapsed_now"; \
		fi; \
		sleep 0.1; \
	done; \
	if [ $$wait_count -gt 0 ]; then printf "\r%80s\r" " "; fi; \
	rm -f $$logs; \
	\
	echo ""; \
	if [ $$has_failures -eq 1 ]; then \
		echo "$(CROSS) $(5) ($$$${elapsed}s)"; \
		exit 1; \
	fi
endef
