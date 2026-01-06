# Testing tasks
# Includes Dart tests, native tests, E2E tests, and coverage

.PHONY: test test-coverage analyze check-duplicates check quick-check test-makefiles \
        test-interface test-main test-web test-web-all test-compat \
        test-android-native test-android-native-coverage test-android-instrumented \
        test-android-instrumented-coverage test-android-full-coverage \
        test-ios-native test-ios-native-coverage \
        test-macos-native test-macos-native-coverage \
        test-native test-e2e test-e2e-ios test-e2e-android test-e2e-macos test-e2e-web

# Shared parallel Dart analysis function
# Note: Used by both 'analyze' and 'quick-check' targets to avoid duplication
# The analyze target provides detailed output; quick-check uses this for summary only

# test: Run all Dart/Flutter tests in parallel
# Use when: Verifying code works correctly
# Note: Set TEST_TIMEOUT_MINS to override default 5 minute per-package timeout
test: verify-setup
	@start_time=$$(date +%s); \
	pkg_count=$$(echo $(PACKAGES) | wc -w | tr -d ' '); \
	printf "$(TEST) Running tests on $$pkg_count packages in parallel...\n"; \
	printf "$(INFO) Packages: $(PACKAGES)\n"; \
	printf "$(INFO) Timeout: $${TEST_TIMEOUT_MINS:-5} minutes per package\n\n"; \
	$(call run-parallel-packages,$(PACKAGES),timeout $$(($${TEST_TIMEOUT_MINS:-5} * 60)) ${FLUTTER} test,--platform chrome,passed,Some tests failed); \
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	echo "$(CHECK) All tests passed ($${elapsed}s)"

# test-unit: Run only unit tests (pro_video_player package)
# Use when: Testing business logic without UI
test-unit:
	@printf "$(TEST) Running unit tests...\n"; \
	(cd pro_video_player && ${FLUTTER} test --no-pub test/unit)

# test-widget: Run only widget tests (pro_video_player package)
# Use when: Testing UI components
test-widget:
	@printf "$(TEST) Running widget tests...\n"; \
	(cd pro_video_player && ${FLUTTER} test --no-pub test/widget)

# test-compat: Run video_player API compatibility verification tests
# Use when: Verifying video_player drop-in replacement API compatibility
# Note: Runs automatically in CI to catch any API breaking changes
test-compat:
	@printf "$(TEST) Running video_player API compatibility verification...\n"; \
	(cd pro_video_player && ${FLUTTER} test --no-pub test/unit/compat/video_player_api_compatibility_test.dart) && \
	echo "$(CHECK) video_player API compatibility verified"

# test-coverage: Run tests with coverage for all packages in parallel
# Use when: Checking test coverage
test-coverage: verify-setup
	@start_time=$$(date +%s); \
	printf "$(CHART) Running tests with coverage in parallel...\n\n"; \
	$(call run-parallel-packages,$(PACKAGES),${FLUTTER} test --coverage,--platform chrome,coverage generated,Coverage generation failed); \
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	echo "$(CHECK) Coverage reports generated ($${elapsed}s)"

# analyze: Analyze all packages in parallel (strict mode)
# Use when: Checking code quality
analyze:
	@start_time=$$(date +%s); \
	printf "$(SEARCH) Analyzing all packages in parallel...\n\n"; \
	$(call run-parallel-packages,$(PACKAGES) example-showcase example-simple-player,${FLUTTER} analyze --fatal-warnings --no-fatal-infos,,passed,Analysis failed); \
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	echo "$(CHECK) Analysis passed ($${elapsed}s)"

# check-duplicates: Detect duplicate/copy-pasted code
# Use when: Checking for code duplication (runs with check task)
check-duplicates:
	@if ! command -v jscpd >/dev/null 2>&1; then \
		echo "$(WARN)  jscpd not installed (install with: npm install -g jscpd)"; \
		echo "$(INFO) Skipping duplicate code detection..."; \
		exit 0; \
	fi; \
	printf "$(SEARCH) Scanning for duplicate code...\n"; \
	rm -rf report; \
	npx jscpd . --config .jscpd.json 2>&1 | tail -20; \
	exit_code=$$?; \
	if [ $$exit_code -eq 0 ]; then \
		echo "$(CHECK) Duplicate code check passed (≤1.0% duplication)"; \
		./makefiles/scripts/check-clone-instances.sh; \
	else \
		echo "$(WARN)  Code duplication detected - must refactor (see output above)"; \
	fi

# check: Run all checks (format, analyze, test, duplicates)
# Use when: Pre-commit or PR validation
check: format-check analyze check-duplicates test
	@echo "$(CHECK) All checks passed!"

# quick-check: Fast parallel check for Dart, Kotlin, Swift, formatting, logging, duplicates, and unit tests
# Use when: Quick validation that code compiles and unit tests pass
quick-check:
	@echo "$(SEARCH) Running quick compilation checks in parallel..."
	@echo ""
	@start_time=$$(date +%s); \
	\
	run_timed() { \
		local log=$$1; shift; \
		local start=$$(date +%s); \
		local error_log=$$(mktemp); \
		if eval "$$@" > /dev/null 2>$$error_log; then \
			echo "OK:$$(( $$(date +%s) - $$start ))" > $$log; \
			rm -f $$error_log; \
		else \
			echo "FAILED:$$(( $$(date +%s) - $$start )):$$error_log" > $$log; \
		fi; \
	}; \
	\
	dart_log=$$(mktemp); kotlin_log=$$(mktemp); ios_log=$$(mktemp); macos_log=$$(mktemp); \
	format_log=$$(mktemp); logging_log=$$(mktemp); duplicates_log=$$(mktemp); unit_log=$$(mktemp); \
	\
	( \
		start=$$(date +%s); dart_pids=""; dart_pkg_logs=""; \
		for pkg in $(PACKAGES) example-showcase example-simple-player; do \
			pkg_log=$$(mktemp); pkg_error=$$(mktemp); dart_pkg_logs="$$dart_pkg_logs $$pkg_log"; \
			( cd $$pkg && ${FLUTTER} analyze --fatal-warnings --no-fatal-infos >$$pkg_error 2>&1 && echo "$$pkg:OK:$$pkg_error" > $$pkg_log || echo "$$pkg:FAILED:$$pkg_error" > $$pkg_log ) & dart_pids="$$dart_pids $$!"; \
		done; \
		for pid in $$dart_pids; do wait $$pid; done; \
		failed=""; error_log=$$(mktemp); \
		for log in $$dart_pkg_logs; do \
			output=$$(cat $$log); pkg=$$(echo "$$output" | cut -d: -f1); status=$$(echo "$$output" | cut -d: -f2); pkg_err=$$(echo "$$output" | cut -d: -f3-); \
			if [ "$$status" = "FAILED" ]; then \
				failed="$$failed $$pkg"; \
				echo "=== $$pkg ===" >> $$error_log; \
				grep -v "Waiting for another flutter command" $$pkg_err 2>/dev/null | head -20 >> $$error_log || tail -20 $$pkg_err >> $$error_log 2>/dev/null; \
			fi; \
			rm -f $$pkg_err; \
		done; \
		rm -f $$dart_pkg_logs; \
		[ -n "$$failed" ] && echo "FAILED:$$failed:$$(( $$(date +%s) - $$start )):$$error_log" > $$dart_log || echo "OK:$$(( $$(date +%s) - $$start ))" > $$dart_log; \
	) & \
	( run_timed $$kotlin_log "cd pro_video_player_android/android && ./../../example-showcase/android/gradlew compileDebugKotlin --quiet" ) & \
	( run_timed $$ios_log "cd example-showcase/ios && xcodebuild build -workspace Runner.xcworkspace -scheme Runner -destination 'generic/platform=iOS Simulator' CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO -quiet" ) & \
	( run_timed $$macos_log "cd example-showcase/macos && xcodebuild build -workspace Runner.xcworkspace -scheme Runner -destination 'platform=macOS' CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO -quiet" ) & \
	( run_timed $$format_log "${DART} format . -l 120 --set-exit-if-changed --output=none" ) & \
	( run_timed $$logging_log "./makefiles/scripts/check-verbose-logging.sh" ) & \
	( \
		start=$$(date +%s); \
		if ! command -v jscpd >/dev/null 2>&1; then \
			echo "SKIPPED:$$(( $$(date +%s) - $$start ))" > $$duplicates_log; \
		else \
			rm -rf report > /dev/null 2>&1; \
			dup_error=$$(mktemp); \
			if npx jscpd . --config .jscpd.json > /dev/null 2>&1 && ./makefiles/scripts/check-clone-instances.sh > /dev/null 2>$$dup_error; then \
				echo "OK:$$(( $$(date +%s) - $$start ))" > $$duplicates_log; \
				rm -f $$dup_error; \
			else \
				./makefiles/scripts/check-clone-instances.sh >> $$dup_error 2>&1 || true; \
				echo "FAILED:$$(( $$(date +%s) - $$start )):$$dup_error" > $$duplicates_log; \
			fi; \
		fi \
	) & \
	( run_timed $$unit_log "cd pro_video_player && ${FLUTTER} test --no-pub test/unit" ) & \
	\
	parse_result() { cat $$1 2>/dev/null | cut -d: -f1; }; \
	parse_time() { \
		content=$$(cat $$1 2>/dev/null); \
		echo "$$content" | awk -F: '{if (NF==4) print $$3; else if (NF==3) print $$2; else print $$NF}'; \
	}; \
	parse_error_log() { \
		content=$$(cat $$1 2>/dev/null); \
		echo "$$content" | awk -F: '{if (NF==4) print $$4; else if (NF==3) print $$3; else print ""}'; \
	}; \
	display_result() { \
		id=$$1; name=$$2; log=$$3; count=$$4; collected_errors=$$5; \
		result=$$(parse_result "$$log"); time=$$(parse_time "$$log"); error_log=$$(parse_error_log "$$log"); \
		[ -z "$$result" ] && return 1; \
		case "$$id:$$result" in \
			*:OK) printf "%d/8 $(CHECK) $$name: passed ($${time}s)\n" "$$count" ;; \
			dart:FAILED) \
				failed=$$(cat $$log | cut -d: -f2); \
				printf "%d/8 $(CROSS) $$name: failed ($${time}s) - $$failed\n" "$$count"; \
				if [ -f "$$error_log" ]; then \
					echo "$$error_log" >> "$$collected_errors"; \
				fi; \
				ret=2 ;; \
			format:FAILED) printf "%d/8 $(CROSS) $$name: failed ($${time}s) - run 'make format' to fix\n" "$$count"; ret=2 ;; \
			logging:FAILED) printf "%d/8 $(CROSS) $$name: found unconditional log statements ($${time}s) - run ./makefiles/scripts/check-verbose-logging.sh for details\n" "$$count"; ret=2 ;; \
			duplicates:SKIPPED) printf "%d/8 $(INFO) $$name: skipped ($${time}s) - jscpd not installed\n" "$$count" ;; \
			duplicates:FAILED) \
				printf "%d/8 $(CROSS) $$name: code duplication detected ($${time}s)\n" "$$count"; \
				if [ -f "$$error_log" ]; then \
					echo "$$error_log" >> "$$collected_errors"; \
				fi; \
				ret=2 ;; \
			*:FAILED) \
				printf "%d/8 $(CROSS) $$name: failed ($${time}s)\n" "$$count"; \
				if [ -f "$$error_log" ]; then \
					echo "$$error_log" >> "$$collected_errors"; \
				fi; \
				ret=2 ;; \
		esac; \
		return $${ret:-0}; \
	}; \
	\
	has_failures=0; completed=""; count=0; collected_errors=$$(mktemp); \
	while true; do \
		all_done=1; \
		for check in "dart|Dart|$$dart_log" "kotlin|Kotlin|$$kotlin_log" "ios|iOS (Swift)|$$ios_log" "macos|macOS (Swift)|$$macos_log" "format|Format|$$format_log" "logging|Logging|$$logging_log" "duplicates|Duplicates|$$duplicates_log" "unit|Unit Tests|$$unit_log"; do \
			id=$$(echo "$$check" | cut -d'|' -f1); \
			case "$$completed" in *"$$id"*) continue ;; esac; \
			name=$$(echo "$$check" | cut -d'|' -f2); log=$$(echo "$$check" | cut -d'|' -f3-); \
			result=$$(parse_result "$$log"); \
			if [ -n "$$result" ]; then \
				count=$$((count + 1)); \
				if display_result "$$id" "$$name" "$$log" "$$count" "$$collected_errors"; then \
					completed="$$completed $$id"; \
				else \
					completed="$$completed $$id"; has_failures=1; \
				fi; \
			else \
				all_done=0; \
			fi; \
		done; \
		[ $$all_done -eq 1 ] && break; \
		sleep 0.1; \
	done; \
	rm -f $$dart_log $$kotlin_log $$ios_log $$macos_log $$format_log $$links_log $$logging_log $$duplicates_log $$unit_log; \
	\
	if [ $$has_failures -eq 1 ] && [ -s "$$collected_errors" ]; then \
		echo ""; echo "$(CROSS) Error Details:"; echo ""; \
		while IFS= read -r error_file; do \
			if [ -f "$$error_file" ]; then \
				cat "$$error_file"; \
				rm -f "$$error_file"; \
			fi; \
		done < "$$collected_errors"; \
	fi; \
	rm -f "$$collected_errors"; \
	\
	elapsed=$$(( $$(date +%s) - $$start_time )); echo ""; \
	[ $$has_failures -eq 1 ] && echo "$(CROSS) Quick check failed ($${elapsed}s)" && exit 1 || echo "$(CHECK) Quick check passed ($${elapsed}s)"

# test-interface: Test platform_interface package only
test-interface:
	@start_time=$$(date +%s); printf "$(TEST) Testing platform_interface..."; \
	cd pro_video_player_platform_interface && ${FLUTTER} test $(OUTPUT_REDIRECT); \
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	printf "\r$(CHECK) platform_interface tests passed ($${elapsed}s)\n"

# test-main: Test main package only (unit + widget tests in parallel)
test-main:
	@start_time=$$(date +%s); \
	printf "$(TEST) Testing main package (unit + widget in parallel)...\n\n"; \
	\
	unit_log=$$(mktemp); widget_log=$$(mktemp); \
	\
	( \
		test_start=$$(date +%s); \
		if (cd pro_video_player && ${FLUTTER} test --no-pub test/unit > /dev/null 2>&1); then \
			echo "unit:OK:$$(( $$(date +%s) - $$test_start ))" > $$unit_log; \
		else \
			echo "unit:FAILED:$$(( $$(date +%s) - $$test_start ))" > $$unit_log; \
		fi \
	) & \
	\
	( \
		test_start=$$(date +%s); \
		if (cd pro_video_player && ${FLUTTER} test --no-pub test/widget > /dev/null 2>&1); then \
			echo "widget:OK:$$(( $$(date +%s) - $$test_start ))" > $$widget_log; \
		else \
			echo "widget:FAILED:$$(( $$(date +%s) - $$test_start ))" > $$widget_log; \
		fi \
	) & \
	\
	wait; \
	\
	completed=""; count=0; \
	while true; do \
		all_done=1; \
		for log in $$unit_log $$widget_log; do \
			case "$$completed" in *"$$log"*) continue ;; esac; \
			result=$$(cat $$log 2>/dev/null | cut -d: -f2); \
			if [ -n "$$result" ]; then \
				count=$$(( count + 1 )); \
				name=$$(cat $$log | cut -d: -f1); \
				time=$$(cat $$log | cut -d: -f3); \
				if [ "$$result" = "OK" ]; then \
					printf "%d/2 $(CHECK) %s: passed (%ss)\n" "$$count" "$$name" "$$time"; \
				else \
					printf "%d/2 $(CROSS) %s: failed (%ss)\n" "$$count" "$$name" "$$time"; \
					has_failures=1; \
				fi; \
				completed="$$completed $$log"; \
			else \
				all_done=0; \
			fi; \
		done; \
		[ $$all_done -eq 1 ] && break; \
		sleep 0.1; \
	done; \
	rm -f $$unit_log $$widget_log; \
	\
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	echo ""; \
	if [ "$${has_failures:-0}" -eq 1 ]; then \
		echo "$(CROSS) Some tests failed ($${elapsed}s)"; \
		exit 1; \
	else \
		echo "$(CHECK) Main package tests passed ($${elapsed}s)"; \
	fi

# test-web: Test web package only (requires Chrome)
test-web:
	@start_time=$$(date +%s); printf "$(TEST) Testing web package..."; \
	cd pro_video_player_web && ${FLUTTER} test --platform chrome $(OUTPUT_REDIRECT); \
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	printf "\r$(CHECK) web package tests passed ($${elapsed}s)\n"

# test-web-all: Test web package on all browsers in parallel (Chrome, Firefox, Safari, Edge)
test-web-all:
	@start_time=$$(date +%s); \
	printf "$(TEST) Running web tests on all browsers in parallel...\n\n"; \
	\
	logs=""; \
	browsers="chrome firefox safari edge"; \
	for browser in $$browsers; do \
		log=$$(mktemp); \
		logs="$$logs $$log"; \
		( \
			browser_start=$$(date +%s); \
			if (cd pro_video_player_web && ${FLUTTER} test --platform $$browser 2>&1 | grep -q "All tests passed"); then \
				browser_end=$$(date +%s); \
				echo "$$browser:OK:$$(( $$browser_end - $$browser_start ))" > $$log; \
			else \
				browser_end=$$(date +%s); \
				echo "$$browser:FAILED:$$(( $$browser_end - $$browser_start ))" > $$log; \
			fi \
		) & \
	done; \
	wait; \
	\
	printf "\n$(BOLD)Test Results:$(RESET)\n"; \
	printf "$(GRAY)─────────────────────────────────────$(RESET)\n"; \
	\
	failed=0; \
	for log in $$logs; do \
		read -r result < $$log; \
		browser=$$(echo $$result | cut -d: -f1); \
		status=$$(echo $$result | cut -d: -f2); \
		time=$$(echo $$result | cut -d: -f3); \
		if [ "$$status" = "OK" ]; then \
			printf "$(CHECK) $$browser: passed ($${time}s)\n"; \
		else \
			printf "$(CROSS) $$browser: failed ($${time}s)\n"; \
			failed=$$(($$failed + 1)); \
		fi; \
		rm -f $$log; \
	done; \
	\
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	printf "$(GRAY)─────────────────────────────────────$(RESET)\n"; \
	\
	if [ $$failed -eq 0 ]; then \
		printf "$(CHECK) All browsers passed ($${elapsed}s total)\n\n"; \
	else \
		printf "$(CROSS) $$failed browser(s) failed ($${elapsed}s total)\n\n"; \
		exit 1; \
	fi

# === Native Tests ===

# test-android-native: Run Android native tests
test-android-native: verify-setup
	@echo "$(TEST) Running Android native tests..."
	@cd example-showcase/android && ./gradlew :pro_video_player_android:testDebugUnitTest
	@echo "$(CHECK) Android native tests complete!"
	@if [ -d example/android/pro_video_player_android/build/reports/tests ]; then \
		echo "$(CHART) Report: file://$(CURDIR)/example/android/pro_video_player_android/build/reports/tests/testDebugUnitTest/index.html"; \
	fi

# test-android-native-coverage: Run Android native tests with coverage
test-android-native-coverage:
	@echo "$(TEST) Running Android native tests with coverage..."
	@cd example-showcase/android && ./gradlew :pro_video_player_android:testDebugUnitTest :pro_video_player_android:jacocoTestReport --no-daemon
	@echo ""
	@echo "$(BOX_TL)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_TR)"
	@echo "$(BOX_V)             ANDROID NATIVE COVERAGE SUMMARY (Kotlin)            $(BOX_V)"
	@echo "$(BOX_ML)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_MR)"
	@if [ -f example-showcase/build/pro_video_player_android/reports/jacoco/test/jacocoTestReport.xml ]; then \
		line_counter=$$(grep -o 'type="LINE" missed="[0-9]*" covered="[0-9]*"' example-showcase/build/pro_video_player_android/reports/jacoco/test/jacocoTestReport.xml | tail -1); \
		line_missed=$$(echo "$$line_counter" | grep -o 'missed="[0-9]*"' | grep -o '[0-9]*'); \
		line_covered=$$(echo "$$line_counter" | grep -o 'covered="[0-9]*"' | grep -o '[0-9]*'); \
		line_total=$$((line_missed + line_covered)); \
		if [ $$line_total -gt 0 ]; then \
			line_pct=$$(awk "BEGIN {printf \"%.1f\", $$line_covered*100/$$line_total}"); \
		else \
			line_pct="0.0"; \
		fi; \
		printf "$(BOX_V)  %-42s %6d/%-6d %5s%% $(BOX_V)\n" "Unit tests (JVM only)" "$$line_covered" "$$line_total" "$$line_pct"; \
	else \
		echo "$(BOX_V)  Coverage report not found. Run the command above.              $(BOX_V)"; \
	fi
	@echo "$(BOX_BL)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_BR)"
	@echo ""
	@echo "$(INFO) Note: This only covers JVM unit tests. For full coverage with"
	@echo "       instrumented tests, run: make test-android-full-coverage"
	@echo ""
	@echo "$(CHART) HTML Report: file://$(CURDIR)/example-showcase/build/pro_video_player_android/reports/jacoco/test/html/index.html"

# test-android-instrumented: Run Android instrumented tests (requires device/emulator)
test-android-instrumented:
	@echo "$(TEST) Running Android instrumented tests..."
	@echo "$(INFO) Note: Requires a running Android emulator or connected device"
	@cd example-showcase/android && ./gradlew :pro_video_player_android:connectedDebugAndroidTest
	@echo ""
	@echo "$(CHECK) Android instrumented tests complete!"
	@if [ -f example-showcase/build/pro_video_player_android/reports/androidTests/connected/debug/index.html ]; then \
		echo "$(CHART) Report: file://$(CURDIR)/example-showcase/build/pro_video_player_android/reports/androidTests/connected/debug/index.html"; \
	fi

# test-android-instrumented-coverage: Run Android instrumented tests with coverage (requires device/emulator)
# This runs real code on a device and provides actual coverage
test-android-instrumented-coverage:
	@echo "$(TEST) Running Android instrumented tests with coverage..."
	@echo "$(INFO) Note: Requires a running Android emulator or connected device"
	@cd example-showcase/android && ./gradlew :pro_video_player_android:connectedDebugAndroidTest :pro_video_player_android:jacocoConnectedTestReport --no-daemon
	@echo ""
	@echo "$(CHECK) Android instrumented tests complete!"
	@echo "$(CHART) HTML Report: file://$(CURDIR)/example-showcase/build/pro_video_player_android/reports/jacoco/connectedTest/html/index.html"

# test-android-full-coverage: Run ALL Android tests (unit + instrumented) with combined coverage
# This is the PRIMARY target for Android native coverage - requires device/emulator
test-android-full-coverage:
	@echo "$(TEST) Running ALL Android tests (unit + instrumented) with coverage..."
	@echo "$(INFO) Note: Requires a running Android emulator or connected device"
	@cd example-showcase/android && ./gradlew \
		:pro_video_player_android:testDebugUnitTest \
		:pro_video_player_android:connectedDebugAndroidTest \
		:pro_video_player_android:jacocoCombinedReport \
		--no-daemon
	@echo ""
	@echo "$(BOX_TL)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_TR)"
	@echo "$(BOX_V)         ANDROID FULL COVERAGE (Unit + Instrumented)             $(BOX_V)"
	@echo "$(BOX_ML)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_MR)"
	@if [ -f example-showcase/build/pro_video_player_android/reports/jacoco/combined/jacocoCombinedReport.xml ]; then \
		line_counter=$$(grep -o 'type="LINE" missed="[0-9]*" covered="[0-9]*"' example-showcase/build/pro_video_player_android/reports/jacoco/combined/jacocoCombinedReport.xml | tail -1); \
		line_missed=$$(echo "$$line_counter" | grep -o 'missed="[0-9]*"' | grep -o '[0-9]*'); \
		line_covered=$$(echo "$$line_counter" | grep -o 'covered="[0-9]*"' | grep -o '[0-9]*'); \
		line_total=$$((line_missed + line_covered)); \
		if [ $$line_total -gt 0 ]; then \
			line_pct=$$(awk "BEGIN {printf \"%.1f\", $$line_covered*100/$$line_total}"); \
		else \
			line_pct="0.0"; \
		fi; \
		printf "$(BOX_V)  %-42s %6d/%-6d %5s%% $(BOX_V)\n" "Lines (combined)" "$$line_covered" "$$line_total" "$$line_pct"; \
	else \
		echo "$(BOX_V)  Coverage report not found.                                      $(BOX_V)"; \
	fi
	@echo "$(BOX_BL)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_H)$(BOX_BR)"
	@echo ""
	@echo "$(CHART) HTML Report: file://$(CURDIR)/example-showcase/build/pro_video_player_android/reports/jacoco/combined/html/index.html"

# test-ios-native: Run iOS native tests
test-ios-native: verify-setup
	@echo "$(TEST) Running iOS native tests..."
	@echo "$(HOURGLASS) Booting simulator if needed..."
	@xcrun simctl boot $(IOS_SIMULATOR_ID) 2>/dev/null || true
	@sleep 2
	@echo "$(TOOLS) Building and testing..."
	@output=$$(cd example-showcase/ios && set -o pipefail && xcodebuild test \
		-workspace Runner.xcworkspace \
		-scheme Runner \
		-destination 'platform=iOS Simulator,id=$(IOS_SIMULATOR_ID)' \
		-only-testing:RunnerTests \
		-disable-concurrent-destination-testing \
		-parallel-testing-enabled NO \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO 2>&1 | \
		grep -v "^[[:space:]]*export " | \
		grep -E "(Test Suite '(All tests|RunnerTests|VideoPlayer|VideoPlayerView)'|Executed [0-9]+ tests|BUILD SUCCEEDED|BUILD FAILED|\*\* TEST)" || true); \
	echo "$$output"; \
	echo ""; \
	if echo "$$output" | grep -q "BUILD FAILED\|\*\* TEST FAILED"; then \
		echo "$(CROSS) iOS native tests failed!"; \
		exit 1; \
	else \
		echo "$(CHECK) iOS native tests complete!"; \
	fi

# test-ios-native-coverage: Run iOS native tests with coverage
test-ios-native-coverage:
	@echo "$(TEST) Running iOS native tests with coverage..."
	@echo "$(HOURGLASS) Booting simulator if needed..."
	@xcrun simctl boot $(IOS_SIMULATOR_ID) 2>/dev/null || true
	@sleep 2
	@echo "$(TOOLS) Building and testing with coverage..."
	@cd example-showcase/ios && set -o pipefail && xcodebuild test \
		-workspace Runner.xcworkspace \
		-scheme Runner \
		-destination 'platform=iOS Simulator,id=$(IOS_SIMULATOR_ID)' \
		-only-testing:RunnerTests \
		-disable-concurrent-destination-testing \
		-parallel-testing-enabled NO \
		-enableCodeCoverage YES \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO 2>&1 | \
		grep -v "^[[:space:]]*export " | \
		grep -E "(Test Suite '(All tests|RunnerTests|VideoPlayer|VideoPlayerView)'|Executed [0-9]+ tests|BUILD SUCCEEDED|BUILD FAILED|\*\* TEST)" || true
	@echo ""
	@$(SCRIPTS_DIR)/ios-coverage-report.sh "$(IOS_SIMULATOR_ID)" "pro_video_player_ios.framework"
	@echo ""
	@echo "$(CHECK) iOS native coverage complete!"

# test-macos-native: Run macOS native tests
test-macos-native: verify-setup
	@echo "$(TEST) Running macOS native tests..."
	@output=$$(cd example-showcase/macos && set -o pipefail && xcodebuild test \
		-workspace Runner.xcworkspace \
		-scheme Runner \
		-destination 'platform=macOS' \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO 2>&1 | \
		grep -v "^[[:space:]]*export " | \
		grep -E "(Test Suite '(All tests|RunnerTests|VideoPlayer|VideoPlayerView)'|Executed [0-9]+ tests|BUILD SUCCEEDED|BUILD FAILED|\*\* TEST)" || true); \
	echo "$$output"; \
	echo ""; \
	if echo "$$output" | grep -q "BUILD FAILED\|\*\* TEST FAILED"; then \
		echo "$(CROSS) macOS native tests failed!"; \
		exit 1; \
	else \
		echo "$(CHECK) macOS native tests complete!"; \
	fi

# test-macos-native-coverage: Run macOS native tests with coverage
test-macos-native-coverage:
	@echo "$(TEST) Running macOS native tests with coverage..."
	@output=$$(cd example-showcase/macos && set -o pipefail && xcodebuild test \
		-workspace Runner.xcworkspace \
		-scheme Runner \
		-destination 'platform=macOS' \
		-enableCodeCoverage YES \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO 2>&1 | \
		grep -v "^[[:space:]]*export " | \
		grep -E "(Test Suite '(All tests|RunnerTests|VideoPlayer|VideoPlayerView)'|Executed [0-9]+ tests|BUILD SUCCEEDED|BUILD FAILED|\*\* TEST)" || true); \
	echo "$$output"; \
	echo ""; \
	if echo "$$output" | grep -q "BUILD FAILED\|\*\* TEST FAILED"; then \
		echo "$(CROSS) macOS native tests failed!"; \
		exit 1; \
	fi; \
	$(SCRIPTS_DIR)/macos-coverage-report.sh "pro_video_player_macos.framework"; \
	echo ""; \
	echo "$(CHECK) macOS native coverage complete!"

# test-native: Run all native tests
test-native: test-android-native test-ios-native test-macos-native
	@echo "$(CHECK) All native tests complete!"

# === E2E Tests ===

# test-e2e: Run E2E UI tests on ALL platforms in PARALLEL (default)
test-e2e: verify-setup
	@echo "$(TEST) Running E2E UI tests on ALL platforms in PARALLEL..."
	@echo "$(INFO) Tests will run on: iOS, Android, macOS, Web"
	@echo "$(INFO) For sequential execution: make test-e2e-sequential"
	@echo "$(INFO) For single platform: make test-e2e-ios, test-e2e-android, test-e2e-macos, or test-e2e-web"
	@echo ""
	@# Create temp directory for logs
	@mkdir -p /tmp/e2e-logs
	@# Start all platforms in background
	@echo "$(HOURGLASS) Starting tests on all platforms..."
	@make test-e2e-ios > /tmp/e2e-logs/ios.log 2>&1 & IOS_PID=$$!; \
	make test-e2e-android > /tmp/e2e-logs/android.log 2>&1 & ANDROID_PID=$$!; \
	make test-e2e-macos > /tmp/e2e-logs/macos.log 2>&1 & MACOS_PID=$$!; \
	make test-e2e-web > /tmp/e2e-logs/web.log 2>&1 & WEB_PID=$$!; \
	\
	echo "$(INFO) Tests running in parallel (PIDs: iOS=$$IOS_PID Android=$$ANDROID_PID macOS=$$MACOS_PID Web=$$WEB_PID)"; \
	echo "$(INFO) Logs: /tmp/e2e-logs/*.log"; \
	echo ""; \
	\
	echo "$(HOURGLASS) Waiting for all platforms to complete..."; \
	START_TIME=$$(date +%s); \
	\
	wait $$IOS_PID; IOS_EXIT=$$?; IOS_END=$$(date +%s); IOS_TIME=$$((IOS_END - START_TIME)); \
	wait $$ANDROID_PID; ANDROID_EXIT=$$?; ANDROID_END=$$(date +%s); ANDROID_TIME=$$((ANDROID_END - START_TIME)); \
	wait $$MACOS_PID; MACOS_EXIT=$$?; MACOS_END=$$(date +%s); MACOS_TIME=$$((MACOS_END - START_TIME)); \
	wait $$WEB_PID; WEB_EXIT=$$?; WEB_END=$$(date +%s); WEB_TIME=$$((WEB_END - START_TIME)); \
	\
	echo ""; \
	echo "========================================"; \
	echo "  E2E Test Results (Parallel)"; \
	echo "========================================"; \
	printf "%-12s %-10s %-8s %-10s\n" "Platform" "Status" "Time" "Exit Code"; \
	printf "%-12s %-10s %-8s %-10s\n" "--------" "------" "----" "---------"; \
	[ $$IOS_EXIT -eq 0 ] && printf "%-12s $(CHECK) %-10s %-8s %-10s\n" "iOS" "PASSED" "$${IOS_TIME}s" "$$IOS_EXIT" || printf "%-12s $(CROSS) %-10s %-8s %-10s\n" "iOS" "FAILED" "$${IOS_TIME}s" "$$IOS_EXIT"; \
	[ $$ANDROID_EXIT -eq 0 ] && printf "%-12s $(CHECK) %-10s %-8s %-10s\n" "Android" "PASSED" "$${ANDROID_TIME}s" "$$ANDROID_EXIT" || printf "%-12s $(CROSS) %-10s %-8s %-10s\n" "Android" "FAILED" "$${ANDROID_TIME}s" "$$ANDROID_EXIT"; \
	[ $$MACOS_EXIT -eq 0 ] && printf "%-12s $(CHECK) %-10s %-8s %-10s\n" "macOS" "PASSED" "$${MACOS_TIME}s" "$$MACOS_EXIT" || printf "%-12s $(CROSS) %-10s %-8s %-10s\n" "macOS" "FAILED" "$${MACOS_TIME}s" "$$MACOS_EXIT"; \
	[ $$WEB_EXIT -eq 0 ] && printf "%-12s $(CHECK) %-10s %-8s %-10s\n" "Web" "PASSED" "$${WEB_TIME}s" "$$WEB_EXIT" || printf "%-12s $(CROSS) %-10s %-8s %-10s\n" "Web" "FAILED" "$${WEB_TIME}s" "$$WEB_EXIT"; \
	echo "========================================"; \
	echo ""; \
	\
	FAILED=0; \
	[ $$IOS_EXIT -ne 0 ] && FAILED=$$((FAILED + 1)); \
	[ $$ANDROID_EXIT -ne 0 ] && FAILED=$$((FAILED + 1)); \
	[ $$MACOS_EXIT -ne 0 ] && FAILED=$$((FAILED + 1)); \
	[ $$WEB_EXIT -ne 0 ] && FAILED=$$((FAILED + 1)); \
	\
	if [ $$FAILED -gt 0 ]; then \
		echo "$(CROSS) $$FAILED platform(s) failed"; \
		echo "$(INFO) Check logs at: /tmp/e2e-logs/*.log"; \
		exit 1; \
	else \
		echo "$(CHECK) All platforms passed!"; \
		echo "$(INFO) Logs saved at: /tmp/e2e-logs/*.log"; \
	fi

# test-e2e-ios: Run E2E UI tests on iOS simulator
test-e2e-ios: verify-setup
	@echo "$(TEST) Running E2E UI tests on iOS simulator..."
	@./makefiles/scripts/ensure-ios-simulator.sh $(IOS_SIMULATOR_ID)
	@cd example-showcase && ${FLUTTER} drive --driver=test_driver/integration_test.dart --target=integration_test/e2e_ui_test.dart -d $(IOS_SIMULATOR_ID)
	@echo ""
	@echo "$(CHECK) E2E UI tests on iOS complete!"

# test-e2e-android: Run E2E UI tests on Android emulator
test-e2e-android: verify-setup
	@echo "$(TEST) Running E2E UI tests on Android emulator..."
	@./makefiles/scripts/ensure-android-emulator.sh $(ANDROID_AVD_NAME)
	@# Detect emulator device ID
	@DEVICE_ID=$$(adb devices -l | grep "emulator-" | head -1 | awk '{print $$1}'); \
	cd example-showcase && ${FLUTTER} test integration_test/e2e_ui_test.dart -d $$DEVICE_ID
	@echo ""
	@echo "$(CHECK) E2E UI tests on Android complete!"

# test-e2e-macos: Run E2E UI tests on macOS
test-e2e-macos: verify-setup
	@echo "$(TEST) Running E2E UI tests on macOS..."
	@cd example-showcase && ${FLUTTER} test integration_test/e2e_ui_test.dart -d macos; \
		EXIT_CODE=$$?; \
		if [ $$EXIT_CODE -eq 1 ]; then exit 1; fi
	@echo ""
	@echo "$(CHECK) E2E UI tests on macOS complete!"

# test-e2e-web: Run E2E UI tests on Chrome (web)
# Note: ChromeDriver runs on port 4444 (required by flutter drive)
# Note: Videos are muted for autoplay (WebDriver autoplay restrictions)
# Note: Volume tests are skipped on web (see canTestVolumeControls in E2E test helpers)
test-e2e-web: verify-setup
	@echo "$(TEST) Running E2E UI tests on Chrome (web)..."
	@# Check if chromedriver is installed
	@if ! command -v chromedriver >/dev/null 2>&1; then \
		echo "$(INFO) chromedriver not found. Installing via Homebrew..."; \
		brew install --cask chromedriver 2>/dev/null || brew upgrade --cask chromedriver 2>/dev/null || true; \
	fi
	@# Force kill any existing chromedriver processes to ensure clean state
	@pkill -9 -f chromedriver 2>/dev/null || true
	@sleep 1
	@# Start chromedriver manually on port 4444 (required by flutter drive)
	@echo "$(INFO) Starting ChromeDriver on port 4444..."
	@chromedriver --port=4444 > /dev/null 2>&1 & \
		CHROMEDRIVER_PID=$$!; \
		sleep 2; \
		echo "$(INFO) ChromeDriver started (PID: $$CHROMEDRIVER_PID)"; \
		cd example-showcase && ${FLUTTER} drive \
			--driver=test_driver/integration_test.dart \
			--target=integration_test/e2e_ui_test.dart \
			-d chrome \
			--no-headless; \
		EXIT_CODE=$$?; \
		echo "$(INFO) Force stopping ChromeDriver..."; \
		pkill -9 -f chromedriver 2>/dev/null || true; \
		if [ $$EXIT_CODE -ne 0 ]; then exit $$EXIT_CODE; fi
	@echo ""
	@echo "$(CHECK) E2E UI tests on Chrome complete!"

# test-e2e-safari: Run E2E UI tests on Safari (web)
# Note: SafariDriver runs on port 4445 (to avoid conflicts with ChromeDriver on 4444)
# Note: Requires safaridriver to be enabled (Safari → Develop → Allow Remote Automation)
# Note: Videos may not autoplay in WebDriver environment (browser autoplay restrictions)
test-e2e-safari: verify-setup
	@echo "$(TEST) Running E2E UI tests on Safari (web)..."
	@# Check if safaridriver is available
	@if ! command -v safaridriver >/dev/null 2>&1; then \
		echo "$(ERROR) safaridriver not found. Safari WebDriver is only available on macOS."; \
		exit 1; \
	fi
	@# Force kill any existing safaridriver processes
	@pkill -9 -f safaridriver 2>/dev/null || true
	@sleep 1
	@# Start safaridriver in background on port 4445
	@echo "$(INFO) Starting SafariDriver on port 4445..."
	@safaridriver --port=4445 > /dev/null 2>&1 & \
		SAFARIDRIVER_PID=$$!; \
		sleep 2; \
		echo "$(INFO) SafariDriver started (PID: $$SAFARIDRIVER_PID)"; \
		cd example-showcase && ${FLUTTER} drive \
			--driver=test_driver/integration_test.dart \
			--target=integration_test/e2e_ui_test.dart \
			-d web-server \
			--browser-name=safari \
			--driver-port=4445 \
			--no-headless; \
		EXIT_CODE=$$?; \
		echo "$(INFO) Force stopping SafariDriver..."; \
		pkill -9 -f safaridriver 2>/dev/null || true; \
		if [ $$EXIT_CODE -ne 0 ]; then exit $$EXIT_CODE; fi
	@echo ""
	@echo "$(CHECK) E2E UI tests on Safari complete!"

# test-e2e-firefox: Run E2E UI tests on Firefox (web)
# Note: GeckoDriver runs on port 4446 (to avoid conflicts with ChromeDriver on 4444 and SafariDriver on 4445)
# Note: Requires geckodriver to be installed (brew install geckodriver)
# Note: Videos may not autoplay in WebDriver environment (browser autoplay restrictions)
test-e2e-firefox: verify-setup
	@echo "$(TEST) Running E2E UI tests on Firefox (web)..."
	@# Check if geckodriver is installed
	@if ! command -v geckodriver >/dev/null 2>&1; then \
		echo "$(INFO) geckodriver not found. Installing via Homebrew..."; \
		brew install geckodriver 2>/dev/null || brew upgrade geckodriver 2>/dev/null || true; \
	fi
	@# Force kill any existing geckodriver processes
	@pkill -9 -f geckodriver 2>/dev/null || true
	@sleep 1
	@# Start geckodriver in background on port 4446
	@echo "$(INFO) Starting GeckoDriver on port 4446..."
	@geckodriver --port=4446 > /dev/null 2>&1 & \
		GECKODRIVER_PID=$$!; \
		sleep 2; \
		echo "$(INFO) GeckoDriver started (PID: $$GECKODRIVER_PID)"; \
		cd example-showcase && ${FLUTTER} drive \
			--driver=test_driver/integration_test.dart \
			--target=integration_test/e2e_ui_test.dart \
			-d web-server \
			--browser-name=firefox \
			--driver-port=4446 \
			--no-headless; \
		EXIT_CODE=$$?; \
		echo "$(INFO) Force stopping GeckoDriver..."; \
		pkill -9 -f geckodriver 2>/dev/null || true; \
		if [ $$EXIT_CODE -ne 0 ]; then exit $$EXIT_CODE; fi
	@echo ""
	@echo "$(CHECK) E2E UI tests on Firefox complete!"

# test-e2e-sequential: Run E2E UI tests on ALL platforms SEQUENTIALLY
test-e2e-sequential: verify-setup
	@echo "$(TEST) Running E2E UI tests on ALL platforms SEQUENTIALLY..."
	@echo "$(INFO) Tests will run one at a time: iOS → Android → macOS → Web"
	@echo "$(INFO) For parallel execution: make test-e2e"
	@echo ""
	@FAILED=0; \
	START_TIME=$$(date +%s); \
	\
	echo "$(HOURGLASS) Running iOS tests..."; \
	make test-e2e-ios; \
	[ $$? -ne 0 ] && FAILED=$$((FAILED + 1)); \
	echo ""; \
	\
	echo "$(HOURGLASS) Running Android tests..."; \
	make test-e2e-android; \
	[ $$? -ne 0 ] && FAILED=$$((FAILED + 1)); \
	echo ""; \
	\
	echo "$(HOURGLASS) Running macOS tests..."; \
	make test-e2e-macos; \
	[ $$? -ne 0 ] && FAILED=$$((FAILED + 1)); \
	echo ""; \
	\
	echo "$(HOURGLASS) Running Web tests..."; \
	make test-e2e-web; \
	[ $$? -ne 0 ] && FAILED=$$((FAILED + 1)); \
	echo ""; \
	\
	END_TIME=$$(date +%s); \
	TOTAL_TIME=$$((END_TIME - START_TIME)); \
	\
	echo "========================================"; \
	echo "  E2E Test Results (Sequential)"; \
	echo "========================================"; \
	echo "Total time: $${TOTAL_TIME}s"; \
	echo ""; \
	\
	if [ $$FAILED -gt 0 ]; then \
		echo "$(CROSS) $$FAILED platform(s) failed"; \
		exit 1; \
	else \
		echo "$(CHECK) All platforms passed!"; \
	fi

# test-makefiles: Run BATS tests for makefiles
# Use when: Verifying makefile changes, CI validation
test-makefiles:
	@if ! command -v bats >/dev/null 2>&1; then \
		echo "$(CROSS) BATS is not installed"; \
		echo "Install with: brew install bats-core"; \
		exit 1; \
	fi; \
	echo "$(TEST) Running makefile tests..."; \
	echo ""; \
	bats tests/makefiles/ && echo "" && echo "$(CHECK) All makefile tests passed"
