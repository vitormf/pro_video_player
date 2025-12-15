# Setup and initialization tasks
# Includes development environment setup and project initialization

.PHONY: setup install clean format format-check fix setup-shared-links verify-shared-links setup-git-hooks

# Helper function to signal completion with audible alert
# Usage: $(call done_signal,message,emoji,suffix)
# Parameters:
#   message: The spoken message and base text
#   emoji: Optional emoji (default: CHECK), can be overridden (e.g., CROSS for failures)
#   suffix: Optional text to append to printed message but not spoken (e.g., timing info)
# Note: Audio is skipped in CI environment
define done_signal
	echo "$(if $(2),$(2),$(CHECK)) $(1)$(if $(3), $(3))" && ([ -z "$$CI" ] && say "$(1)" || true)
endef

# setup: Complete project setup (FVM + dependencies + shared links + git hooks)
# Use when: First setup or after cloning the repository
setup: verify-tools
	@echo "$(TOOLS) Setting up FVM..."
	@fvm install $(OUTPUT_REDIRECT)
	@echo "$(CHECK) FVM setup complete"
	@$(MAKE) setup-shared-links
	@$(MAKE) setup-git-hooks
	@$(MAKE) install
	@$(call done_signal,Setup complete)

# install: Install dependencies for all packages
# Use when: After pulling changes or adding new packages
install:
	@start_time=$$(date +%s); printf "$(PKG) Installing dependencies for all packages..."; \
	for pkg in $(PACKAGES) example-showcase; do \
		(cd $$pkg && ${FLUTTER} pub get $(OUTPUT_REDIRECT)) || (printf "\r$(CROSS) Failed to install dependencies for $$pkg\n" && exit 1); \
	done; \
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	printf "\r$(CHECK) Dependencies installed for all packages ($${elapsed}s)\n"

# clean: Clean all packages
# Use when: Build issues or corrupted state
clean:
	@start_time=$$(date +%s); printf "$(BROOM) Cleaning all packages..."; \
	for pkg in $(PACKAGES) example-showcase; do \
		(cd $$pkg && ${FLUTTER} clean $(OUTPUT_REDIRECT)) || true; \
	done; \
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	printf "\r$(CHECK) All packages cleaned ($${elapsed}s)\n"

# format: Format all Dart code (120 char line length)
# Use when: Before committing or after large refactors
format:
	@start_time=$$(date +%s); printf "$(PAINT) Formatting Dart code..."; \
	${DART} format . -l 120 $(OUTPUT_REDIRECT); \
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	printf "\r$(CHECK) Code formatted successfully ($${elapsed}s)\n"

# format-check: Check formatting without changes
# Use when: CI validation or pre-commit check
format-check:
	@start_time=$$(date +%s); printf "$(SEARCH) Checking code format..."; \
	if ${DART} format . -l 120 --set-exit-if-changed --output=none; then \
		elapsed=$$(( $$(date +%s) - $$start_time )); \
		printf "\r$(CHECK) Format check passed ($${elapsed}s)\n"; \
	else \
		printf "\r$(CROSS) Format check failed - run 'make format'\n"; \
		exit 1; \
	fi

# fix: Apply automatic Dart fixes
# Use when: After analyzer warnings that can be auto-fixed
fix:
	@start_time=$$(date +%s); printf "$(WRENCH) Applying automatic fixes..."; \
	for pkg in $(PACKAGES) example-showcase; do \
		(cd $$pkg && ${DART} fix --apply $(OUTPUT_REDIRECT)) || true; \
	done; \
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	printf "\r$(CHECK) Fixes applied ($${elapsed}s)\n"

# setup-shared-links: Create hard links for shared iOS/macOS Swift sources
# Use when: After cloning, or if shared files become out of sync
# Note: Hard links ensure editing any copy updates all - single source of truth
setup-shared-links:
	@./makefiles/scripts/setup-shared-links.sh

# verify-shared-links: Verify shared iOS/macOS Swift sources are in sync
# Use when: CI validation, pre-commit check, or debugging sync issues
verify-shared-links:
	@./makefiles/scripts/verify-shared-links.sh

# setup-git-hooks: Configure git to use project hooks
# Use when: After cloning, ensures pre-commit hook runs automatically
setup-git-hooks:
	@git config core.hooksPath .githooks
	@echo "$(CHECK) Git hooks configured (.githooks/)"
