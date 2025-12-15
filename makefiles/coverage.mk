# Coverage tasks
# Comprehensive coverage reporting for Dart and native code

.PHONY: coverage coverage-html coverage-summary

# coverage: Generate comprehensive coverage report for all platforms
# Use when: Pre-PR validation or coverage check
coverage: test-coverage coverage-html test-android-native-coverage test-ios-native-coverage
	@echo ""
	@$(SCRIPTS_DIR)/coverage-summary.sh "$(CURDIR)" "$(PACKAGES)"

# coverage-html: Generate HTML coverage reports from lcov data
# Use when: After running test-coverage
coverage-html: _check-lcov
	@echo "$(CHART) Generating HTML coverage reports..."
	@mkdir -p coverage
	@echo "$(TOOLS) Fixing paths and combining coverage data..."
	@sed 's|^SF:lib/|SF:pro_video_player_platform_interface/lib/|' \
		pro_video_player_platform_interface/coverage/lcov.info > coverage/interface.info 2>/dev/null || true
	@sed 's|^SF:lib/|SF:pro_video_player/lib/|' \
		pro_video_player/coverage/lcov.info > coverage/main.info 2>/dev/null || true
	@sed 's|^SF:lib/|SF:pro_video_player_ios/lib/|' \
		pro_video_player_ios/coverage/lcov.info > coverage/ios.info 2>/dev/null || true
	@sed 's|^SF:lib/|SF:pro_video_player_android/lib/|' \
		pro_video_player_android/coverage/lcov.info > coverage/android.info 2>/dev/null || true
	@sed 's|^SF:lib/|SF:pro_video_player_web/lib/|' \
		pro_video_player_web/coverage/lcov.info > coverage/web.info 2>/dev/null || true
	@sed 's|^SF:lib/|SF:pro_video_player_macos/lib/|' \
		pro_video_player_macos/coverage/lcov.info > coverage/macos.info 2>/dev/null || true
	@lcov --add-tracefile coverage/interface.info \
	      --add-tracefile coverage/main.info \
	      --add-tracefile coverage/ios.info \
	      --add-tracefile coverage/android.info \
	      --add-tracefile coverage/web.info \
	      --add-tracefile coverage/macos.info \
	      --output-file coverage/lcov.info 2>/dev/null || true
	@rm -f coverage/interface.info coverage/main.info coverage/ios.info coverage/android.info coverage/web.info coverage/macos.info
	@echo "$(TOOLS) Generating HTML report..."
	@genhtml coverage/lcov.info --output-directory coverage/html $(OUTPUT_REDIRECT)
	@echo "$(CHECK) Coverage HTML report: coverage/html/index.html"

# coverage-summary: Show coverage summary for all packages
# Use when: Quick coverage check without HTML generation
coverage-summary:
	@$(SCRIPTS_DIR)/coverage-summary.sh "$(CURDIR)" "$(PACKAGES)"
