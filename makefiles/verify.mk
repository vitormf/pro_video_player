# Development environment verification tasks
# Ensures all required tools are installed with correct versions

.PHONY: verify-tools verify-setup _check-fvm _check-flutter _check-fzf _check-lcov

# Recommended tool versions
RECOMMENDED_FVM_VERSION := 4.0.1

# Source Homebrew helper functions from external script
# Functions: prompt_user, version_less_than, check_brew, brew_install, brew_upgrade
BREW_HELPERS := . $(MAKEFILES_DIR)scripts/brew-helpers.sh && export OUTPUT_REDIRECT="$(OUTPUT_REDIRECT)"

# verify-tools: Verify all required development tools
# Use when: First run or debugging environment issues
verify-tools: _check-fvm _check-flutter
	@echo "$(CHECK) All development tools verified"

# verify-setup: Verify project setup has been completed
# Use when: Before build/test/coverage - ensures hard links and git hooks are configured
# This target is called automatically by test/build/coverage targets
verify-setup:
	@if [ ! -f "pro_video_player_ios/ios/Classes/Shared/SharedVideoPlayer.swift" ]; then \
		echo "$(CROSS) Setup incomplete: shared source links not found"; \
		echo ""; \
		echo "Run 'make setup' to complete project setup."; \
		exit 1; \
	fi
	@if ! ./makefiles/scripts/verify-shared-links.sh >/dev/null 2>&1; then \
		echo "$(CROSS) Setup incomplete: shared sources are out of sync"; \
		echo ""; \
		echo "Run 'make setup-shared-links' to fix."; \
		exit 1; \
	fi
	@if [ "$$(git config --get core.hooksPath 2>/dev/null)" != ".githooks" ]; then \
		echo "$(WARN)  Git hooks not configured (run 'make setup-git-hooks')"; \
	fi

_check-fvm:
	@$(BREW_HELPERS); \
	if command -v fvm >/dev/null 2>&1; then \
		fvm_version=$$(fvm --version 2>/dev/null); \
		if version_less_than "$$fvm_version" "$(RECOMMENDED_FVM_VERSION)"; then \
			echo "$(WARN)  FVM $$fvm_version (recommended minimum: $(RECOMMENDED_FVM_VERSION))"; \
			brew_upgrade fvm 0; \
		fi; \
	else \
		echo "$(CROSS) FVM not found (required)"; \
		brew_install fvm 1 || exit 1; \
	fi

_check-flutter:
	@get_versions() { \
		flutter_version=$$(${FLUTTER} --version 2>&1 | grep -m 1 "^Flutter" | awk '{print $$2}' || echo "unknown"); \
		dart_version=$$(${DART} --version 2>&1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n 1 || echo "unknown"); \
	}; \
	\
	if [ -f .fvmrc ]; then \
		expected_flutter=$$(grep -o '"flutter"[[:space:]]*:[[:space:]]*"[^"]*"' .fvmrc | cut -d'"' -f4); \
		if command -v fvm >/dev/null 2>&1; then \
			if ! fvm list 2>/dev/null | grep -q "$$expected_flutter"; then \
				echo "$(HOURGLASS) Installing Flutter $$expected_flutter via FVM..."; \
				fvm install $$expected_flutter $(OUTPUT_REDIRECT) && fvm use $$expected_flutter $(OUTPUT_REDIRECT); \
			fi; \
		fi; \
		get_versions; \
		if [ "$$flutter_version" != "$$expected_flutter" ]; then \
			echo "$(CROSS) Flutter $$flutter_version (required: $$expected_flutter)"; \
			if command -v fvm >/dev/null 2>&1; then \
				echo "Reinstalling Flutter $$expected_flutter via FVM..."; \
				fvm install $$expected_flutter $(OUTPUT_REDIRECT) && fvm use $$expected_flutter $(OUTPUT_REDIRECT); \
			else \
				echo "$(CROSS) FVM not installed. Please run 'make verify-tools' to install required tools."; \
				exit 1; \
			fi; \
		fi; \
	fi

_check-fzf:
	@$(BREW_HELPERS); \
	if ! command -v fzf >/dev/null 2>&1; then \
		echo "$(WARN)  fzf not installed (optional but recommended for interactive task selector)"; \
		brew_install fzf 0; \
	fi

_check-lcov:
	@$(BREW_HELPERS); \
	if ! command -v lcov >/dev/null 2>&1; then \
		echo "$(WARN)  lcov not installed (required for HTML coverage reports)"; \
		brew_install lcov 1 || exit 1; \
	fi
