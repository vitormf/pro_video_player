# Package-specific target generation
# This file uses makefile functions to generate per-package targets and reduce duplication

# Package name mapping: short name -> full package directory name
# Used for target names like 'test-interface' -> 'pro_video_player_platform_interface'
PKG_interface := pro_video_player_platform_interface
PKG_main := pro_video_player
PKG_web := pro_video_player_web
PKG_android := pro_video_player_android
PKG_ios := pro_video_player_ios
PKG_macos := pro_video_player_macos
PKG_windows := pro_video_player_windows
PKG_linux := pro_video_player_linux

# List of short package names
# Note: interface, main, and web have custom test targets in test.mk, so we only generate
# test targets for android, ios, macos, windows, linux
PKG_NAMES := interface main web android ios macos windows linux
PKG_NAMES_TEST_ONLY := android ios macos windows linux

# Define function to create a test target for a package
# Usage: $(call define-test-target,short_name,full_package_name)
define define-test-target
.PHONY: test-$(1)
test-$(1):
	@start_time=$$$$(date +%s); printf "$$(TEST) Testing $(1) package..."; \
	cd $(2) && $${FLUTTER} test $$(if $$(filter $(1),web),--platform chrome) $$(OUTPUT_REDIRECT); \
	elapsed=$$$$(( $$$$(date +%s) - $$$$start_time )); \
	printf "\r$$(CHECK) $(1) package tests passed ($$$${elapsed}s)\n"
endef

# Define function to create a coverage target for a package
# Usage: $(call define-coverage-target,short_name,full_package_name)
define define-coverage-target
.PHONY: coverage-$(1)
coverage-$(1):
	@printf "$$(CHART) Running $(1) package tests with coverage..."; \
	cd $(2) && $${FLUTTER} test --coverage $$(if $$(filter $(1),web),--platform chrome) $$(OUTPUT_REDIRECT); \
	printf "\r$$(CHECK) $(1) package coverage generated\n"
endef

# Define function to create an analyze target for a package
# Usage: $(call define-analyze-target,short_name,full_package_name)
define define-analyze-target
.PHONY: analyze-$(1)
analyze-$(1):
	@printf "$$(SEARCH) Analyzing $(1) package..."; \
	cd $(2) && $${FLUTTER} analyze --fatal-warnings --no-fatal-infos; \
	printf "\r$$(CHECK) $(1) package analysis passed\n"
endef

# Define function to create an install target for a package
# Usage: $(call define-install-target,short_name,full_package_name)
define define-install-target
.PHONY: install-$(1)
install-$(1):
	@printf "$$(PKG) Installing dependencies for $(1) package..."; \
	cd $(2) && $${FLUTTER} pub get $$(OUTPUT_REDIRECT); \
	printf "\r$$(CHECK) $(1) package dependencies installed\n"
endef

# Define function to create a clean target for a package
# Usage: $(call define-clean-target,short_name,full_package_name)
define define-clean-target
.PHONY: clean-$(1)
clean-$(1):
	@printf "$$(BROOM) Cleaning $(1) package..."; \
	cd $(2) && $${FLUTTER} clean $$(OUTPUT_REDIRECT); \
	printf "\r$$(CHECK) $(1) package cleaned\n"
endef

# Define function to create a fix target for a package
# Usage: $(call define-fix-target,short_name,full_package_name)
define define-fix-target
.PHONY: fix-$(1)
fix-$(1):
	@printf "$$(WRENCH) Applying fixes to $(1) package..."; \
	cd $(2) && $${DART} fix --apply $$(OUTPUT_REDIRECT); \
	printf "\r$$(CHECK) $(1) package fixes applied\n"
endef

# Generate all per-package targets for each package
# This uses eval to evaluate the function definitions as makefile rules
# Test targets only for android/ios/macos/windows/linux (interface/main/web have custom implementations)
$(foreach pkg,$(PKG_NAMES_TEST_ONLY),\
	$(eval $(call define-test-target,$(pkg),$(PKG_$(pkg)))) \
)
# All other targets for all packages
$(foreach pkg,$(PKG_NAMES),\
	$(eval $(call define-coverage-target,$(pkg),$(PKG_$(pkg)))) \
	$(eval $(call define-analyze-target,$(pkg),$(PKG_$(pkg)))) \
	$(eval $(call define-install-target,$(pkg),$(PKG_$(pkg)))) \
	$(eval $(call define-clean-target,$(pkg),$(PKG_$(pkg)))) \
	$(eval $(call define-fix-target,$(pkg),$(PKG_$(pkg)))) \
)
