# Testing tasks
# Includes Dart tests, native tests, E2E tests, and coverage

.PHONY: test test-coverage analyze check-duplicates check quick-check test-interface test-main test-web \
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
test: verify-setup
	@start_time=$$(date +%s); \
	pkg_count=$$(echo $(PACKAGES) | wc -w | tr -d ' '); \
	printf "$(TEST) Running all tests in parallel...\n\n"; \
	\
	logs=""; \
	for pkg in $(PACKAGES); do \
		log=$$(mktemp); \
		logs="$$logs $$log"; \
		( \
			pkg_name="$$pkg"; \
			test_start=$$(date +%s); \
			if [ "$$pkg_name" = "pro_video_player_web" ]; then \
				if (cd $$pkg_name && ${FLUTTER} test --platform chrome $(OUTPUT_REDIRECT)); then \
					test_end=$$(date +%s); \
					echo "$$pkg_name:OK:$$(( $$test_end - $$test_start ))" > $$log; \
				else \
					test_end=$$(date +%s); \
					echo "$$pkg_name:FAILED:$$(( $$test_end - $$test_start ))" > $$log; \
				fi; \
			else \
				if (cd $$pkg_name && ${FLUTTER} test $(OUTPUT_REDIRECT)); then \
					test_end=$$(date +%s); \
					echo "$$pkg_name:OK:$$(( $$test_end - $$test_start ))" > $$log; \
				else \
					test_end=$$(date +%s); \
					echo "$$pkg_name:FAILED:$$(( $$test_end - $$test_start ))" > $$log; \
				fi; \
			fi \
		) & \
	done; \
	\
	parse_result() { cat $$1 2>/dev/null | cut -d: -f2; }; \
	has_failures=0; completed=""; count=0; \
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
					printf "%d/%d $(CHECK) $$pkg: passed ($${time}s)\n" "$$count" "$$pkg_count"; \
				else \
					printf "%d/%d $(CROSS) $$pkg: failed ($${time}s)\n" "$$count" "$$pkg_count"; \
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
	rm -f $$logs; \
	\
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	echo ""; \
	if [ $$has_failures -eq 1 ]; then \
		echo "$(CROSS) Some tests failed ($${elapsed}s)"; \
		exit 1; \
	else \
		echo "$(CHECK) All tests passed ($${elapsed}s)"; \
	fi

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

# test-coverage: Run tests with coverage for all packages in parallel
# Use when: Checking test coverage
test-coverage: verify-setup
	@start_time=$$(date +%s); \
	pkg_count=$$(echo $(PACKAGES) | wc -w | tr -d ' '); \
	printf "$(CHART) Running tests with coverage in parallel...\n\n"; \
	\
	logs=""; \
	for pkg in $(PACKAGES); do \
		log=$$(mktemp); \
		logs="$$logs $$log"; \
		( \
			pkg_name="$$pkg"; \
			test_start=$$(date +%s); \
			if [ "$$pkg_name" = "pro_video_player_web" ]; then \
				if (cd $$pkg_name && ${FLUTTER} test --coverage --platform chrome $(OUTPUT_REDIRECT)); then \
					test_end=$$(date +%s); \
					echo "$$pkg_name:OK:$$(( $$test_end - $$test_start ))" > $$log; \
				else \
					test_end=$$(date +%s); \
					echo "$$pkg_name:FAILED:$$(( $$test_end - $$test_start ))" > $$log; \
				fi; \
			else \
				if (cd $$pkg_name && ${FLUTTER} test --coverage $(OUTPUT_REDIRECT)); then \
					test_end=$$(date +%s); \
					echo "$$pkg_name:OK:$$(( $$test_end - $$test_start ))" > $$log; \
				else \
					test_end=$$(date +%s); \
					echo "$$pkg_name:FAILED:$$(( $$test_end - $$test_start ))" > $$log; \
				fi; \
			fi \
		) & \
	done; \
	\
	parse_result() { cat $$1 2>/dev/null | cut -d: -f2; }; \
	has_failures=0; completed=""; count=0; \
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
					printf "%d/%d $(CHECK) $$pkg: coverage generated ($${time}s)\n" "$$count" "$$pkg_count"; \
				else \
					printf "%d/%d $(CROSS) $$pkg: failed ($${time}s)\n" "$$count" "$$pkg_count"; \
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
	rm -f $$logs; \
	\
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	echo ""; \
	if [ $$has_failures -eq 1 ]; then \
		echo "$(CROSS) Coverage generation failed ($${elapsed}s)"; \
		exit 1; \
	else \
		echo "$(CHECK) Coverage reports generated ($${elapsed}s)"; \
	fi

# analyze: Analyze all packages in parallel (strict mode)
# Use when: Checking code quality
analyze:
	@start_time=$$(date +%s); \
	pkg_count=$$(echo $(PACKAGES) example-showcase example-simple-player | wc -w | tr -d ' '); \
	printf "$(SEARCH) Analyzing all packages in parallel...\n\n"; \
	\
	logs=""; \
	for pkg in $(PACKAGES) example-showcase example-simple-player; do \
		log=$$(mktemp); \
		logs="$$logs $$log"; \
		( \
			pkg_name="$$pkg"; \
			analyze_start=$$(date +%s); \
			if (cd $$pkg_name && ${FLUTTER} analyze --fatal-infos --fatal-warnings $(OUTPUT_REDIRECT)); then \
				analyze_end=$$(date +%s); \
				echo "$$pkg_name:OK:$$(( $$analyze_end - $$analyze_start ))" > $$log; \
			else \
				analyze_end=$$(date +%s); \
				echo "$$pkg_name:FAILED:$$(( $$analyze_end - $$analyze_start ))" > $$log; \
			fi \
		) & \
	done; \
	\
	parse_result() { cat $$1 2>/dev/null | cut -d: -f2; }; \
	has_failures=0; completed=""; count=0; \
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
					printf "%d/%d $(CHECK) $$pkg: passed ($${time}s)\n" "$$count" "$$pkg_count"; \
				else \
					printf "%d/%d $(CROSS) $$pkg: has issues ($${time}s)\n" "$$count" "$$pkg_count"; \
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
	rm -f $$logs; \
	\
	elapsed=$$(( $$(date +%s) - $$start_time )); \
	echo ""; \
	if [ $$has_failures -eq 1 ]; then \
		echo "$(CROSS) Analysis failed ($${elapsed}s)"; \
		exit 1; \
	else \
		echo "$(CHECK) Analysis passed ($${elapsed}s)"; \
	fi

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

# check: Run all checks (format, analyze, test, shared sources, duplicates)
# Use when: Pre-commit or PR validation
check: verify-shared-links format-check analyze check-duplicates test
	@echo "$(CHECK) All checks passed!"

# quick-check: Fast parallel compilation check for Dart, Kotlin, Swift, formatting, shared links, logging, and duplicates
# Use when: Quick validation that code compiles without full test run
quick-check:
	@echo "$(SEARCH) Running quick compilation checks in parallel..."
	@echo ""
	@start_time=$$(date +%s); \
	\
	run_timed() { \
		local log=$$1; shift; \
		local start=$$(date +%s); \
		if eval "$$@" > /dev/null 2>&1; then \
			echo "OK:$$(( $$(date +%s) - $$start ))" > $$log; \
		else \
			echo "FAILED:$$(( $$(date +%s) - $$start ))" > $$log; \
		fi; \
	}; \
	\
	dart_log=$$(mktemp); kotlin_log=$$(mktemp); ios_log=$$(mktemp); macos_log=$$(mktemp); \
	format_log=$$(mktemp); links_log=$$(mktemp); logging_log=$$(mktemp); duplicates_log=$$(mktemp); \
	\
	( \
		start=$$(date +%s); dart_pids=""; dart_pkg_logs=""; \
		for pkg in $(PACKAGES) example-showcase example-simple-player; do \
			pkg_log=$$(mktemp); dart_pkg_logs="$$dart_pkg_logs $$pkg_log"; \
			( cd $$pkg && ${FLUTTER} analyze --fatal-infos --fatal-warnings > /dev/null 2>&1 && echo "$$pkg:OK" > $$pkg_log || echo "$$pkg:FAILED" > $$pkg_log ) & dart_pids="$$dart_pids $$!"; \
		done; \
		for pid in $$dart_pids; do wait $$pid; done; \
		failed=""; \
		for log in $$dart_pkg_logs; do \
			output=$$(cat $$log); pkg=$$(echo "$$output" | cut -d: -f1); status=$$(echo "$$output" | cut -d: -f2); \
			[ "$$status" = "FAILED" ] && failed="$$failed $$pkg"; \
		done; \
		rm -f $$dart_pkg_logs; \
		[ -n "$$failed" ] && echo "FAILED:$$failed:$$(( $$(date +%s) - $$start ))" > $$dart_log || echo "OK:$$(( $$(date +%s) - $$start ))" > $$dart_log; \
	) & \
	( run_timed $$kotlin_log "cd example-showcase/android && ./gradlew :pro_video_player_android:compileDebugKotlin --quiet" ) & \
	( run_timed $$ios_log "cd example-showcase/ios && xcodebuild build -workspace Runner.xcworkspace -scheme Runner -destination 'generic/platform=iOS Simulator' CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO -quiet" ) & \
	( run_timed $$macos_log "cd example-showcase/macos && xcodebuild build -workspace Runner.xcworkspace -scheme Runner -destination 'platform=macOS' CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO -quiet" ) & \
	( run_timed $$format_log "${DART} format . -l 120 --set-exit-if-changed --output=none" ) & \
	( run_timed $$links_log "./makefiles/scripts/verify-shared-links.sh" ) & \
	( run_timed $$logging_log "./makefiles/scripts/check-verbose-logging.sh" ) & \
	( \
		start=$$(date +%s); \
		if ! command -v jscpd >/dev/null 2>&1; then \
			echo "SKIPPED:$$(( $$(date +%s) - $$start ))" > $$duplicates_log; \
		else \
			rm -rf report > /dev/null 2>&1; \
			if npx jscpd . --config .jscpd.json > /dev/null 2>&1 && ./makefiles/scripts/check-clone-instances.sh > /dev/null 2>&1; then \
				echo "OK:$$(( $$(date +%s) - $$start ))" > $$duplicates_log; \
			else \
				echo "FAILED:$$(( $$(date +%s) - $$start ))" > $$duplicates_log; \
			fi; \
		fi \
	) & \
	\
	parse_result() { cat $$1 2>/dev/null | cut -d: -f1; }; \
	parse_time() { cat $$1 2>/dev/null | rev | cut -d: -f1 | rev; }; \
	display_result() { \
		id=$$1; name=$$2; log=$$3; count=$$4; \
		result=$$(parse_result "$$log"); time=$$(parse_time "$$log"); \
		[ -z "$$result" ] && return 1; \
		case "$$id:$$result" in \
			*:OK) printf "%d/8 $(CHECK) $$name: passed ($${time}s)\n" "$$count" ;; \
			dart:FAILED) failed=$$(cat $$log | cut -d: -f2); printf "%d/8 $(CROSS) $$name: failed ($${time}s) - $$failed\n" "$$count"; ret=2 ;; \
			format:FAILED) printf "%d/8 $(CROSS) $$name: failed ($${time}s) - run 'make format' to fix\n" "$$count"; ret=2 ;; \
			links:FAILED) printf "%d/8 $(CROSS) $$name: iOS/macOS sources out of sync ($${time}s) - run 'make setup-shared-links'\n" "$$count"; ret=2 ;; \
			logging:FAILED) printf "%d/8 $(CROSS) $$name: found unconditional log statements ($${time}s) - run ./makefiles/scripts/check-verbose-logging.sh for details\n" "$$count"; ret=2 ;; \
			duplicates:SKIPPED) printf "%d/8 $(INFO) $$name: skipped ($${time}s) - jscpd not installed\n" "$$count" ;; \
			duplicates:FAILED) printf "%d/8 $(CROSS) $$name: code duplication detected ($${time}s) - run 'make check-duplicates' for details\n" "$$count"; ret=2 ;; \
			*:FAILED) printf "%d/8 $(CROSS) $$name: failed ($${time}s)\n" "$$count"; ret=2 ;; \
		esac; \
		return $${ret:-0}; \
	}; \
	\
	has_failures=0; completed=""; count=0; \
	while true; do \
		all_done=1; \
		for check in "dart|Dart|$$dart_log" "kotlin|Kotlin|$$kotlin_log" "ios|iOS (Swift)|$$ios_log" "macos|macOS (Swift)|$$macos_log" "format|Format|$$format_log" "links|Shared Links|$$links_log" "logging|Logging|$$logging_log" "duplicates|Duplicates|$$duplicates_log"; do \
			id=$$(echo "$$check" | cut -d'|' -f1); \
			case "$$completed" in *"$$id"*) continue ;; esac; \
			name=$$(echo "$$check" | cut -d'|' -f2); log=$$(echo "$$check" | cut -d'|' -f3-); \
			result=$$(parse_result "$$log"); \
			if [ -n "$$result" ]; then \
				count=$$((count + 1)); \
				if display_result "$$id" "$$name" "$$log" "$$count"; then \
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
	rm -f $$dart_log $$kotlin_log $$ios_log $$macos_log $$format_log $$links_log $$logging_log $$duplicates_log; \
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
	@cd example-showcase/ios && set -o pipefail && xcodebuild test \
		-workspace Runner.xcworkspace \
		-scheme Runner \
		-destination 'platform=iOS Simulator,id=$(IOS_SIMULATOR_ID)' \
		-only-testing:RunnerTests \
		-disable-concurrent-destination-testing \
		-parallel-testing-enabled NO \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO 2>&1 | \
		grep -v "^[[:space:]]*export " | \
		grep -E "(Test Suite '(All tests|RunnerTests|VideoPlayer|VideoPlayerView)'|Executed [0-9]+ tests|BUILD SUCCEEDED|BUILD FAILED|\*\* TEST)" || true
	@echo ""
	@echo "$(CHECK) iOS native tests complete!"

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
	@cd example-showcase/macos && set -o pipefail && xcodebuild test \
		-workspace Runner.xcworkspace \
		-scheme Runner \
		-destination 'platform=macOS' \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO 2>&1 | \
		grep -v "^[[:space:]]*export " | \
		grep -E "(Test Suite '(All tests|RunnerTests|VideoPlayer|VideoPlayerView)'|Executed [0-9]+ tests|BUILD SUCCEEDED|BUILD FAILED|\*\* TEST)" || true
	@echo ""
	@echo "$(CHECK) macOS native tests complete!"

# test-macos-native-coverage: Run macOS native tests with coverage
test-macos-native-coverage:
	@echo "$(TEST) Running macOS native tests with coverage..."
	@cd example-showcase/macos && set -o pipefail && xcodebuild test \
		-workspace Runner.xcworkspace \
		-scheme Runner \
		-destination 'platform=macOS' \
		-enableCodeCoverage YES \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO 2>&1 | \
		grep -v "^[[:space:]]*export " | \
		grep -E "(Test Suite '(All tests|RunnerTests|VideoPlayer|VideoPlayerView)'|Executed [0-9]+ tests|BUILD SUCCEEDED|BUILD FAILED|\*\* TEST)" || true
	@echo ""
	@$(SCRIPTS_DIR)/macos-coverage-report.sh "pro_video_player_macos.framework"
	@echo ""
	@echo "$(CHECK) macOS native coverage complete!"

# test-native: Run all native tests
test-native: test-android-native test-ios-native test-macos-native
	@echo "$(CHECK) All native tests complete!"

# === E2E Tests ===

# test-e2e: Run E2E UI tests (auto-detect device)
test-e2e: verify-setup
	@echo "$(TEST) Running E2E UI tests..."
	@echo "$(INFO) For specific platform use: make test-e2e-ios or test-e2e-android"
	@cd example-showcase && ${FLUTTER} test integration_test/e2e_ui_test.dart

# test-e2e-ios: Run E2E UI tests on iOS simulator
test-e2e-ios: verify-setup
	@echo "$(TEST) Running E2E UI tests on iOS simulator..."
	@echo "$(HOURGLASS) Booting simulator if needed..."
	@xcrun simctl boot $(IOS_SIMULATOR_ID) 2>/dev/null || true
	@sleep 2
	@cd example-showcase && ${FLUTTER} test integration_test/e2e_ui_test.dart -d $(IOS_SIMULATOR_ID)
	@echo ""
	@echo "$(CHECK) E2E UI tests on iOS complete!"

# test-e2e-android: Run E2E UI tests on Android emulator
test-e2e-android: verify-setup
	@echo "$(TEST) Running E2E UI tests on Android emulator..."
	@echo "$(INFO) Note: Requires a running Android emulator"
	@cd example-showcase && ${FLUTTER} test integration_test/e2e_ui_test.dart -d emulator-5554
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
# Note: --web-browser-flag disables autoplay restrictions for testing
test-e2e-web: verify-setup
	@echo "$(TEST) Running E2E UI tests on Chrome (web)..."
	@# Check if chromedriver is installed
	@if ! command -v chromedriver >/dev/null 2>&1; then \
		echo "$(INFO) chromedriver not found. Installing via Homebrew..."; \
		brew install --cask chromedriver 2>/dev/null || brew upgrade --cask chromedriver 2>/dev/null || true; \
	fi
	@# Kill any existing chromedriver processes
	@pkill -f chromedriver 2>/dev/null || true
	@# Start chromedriver in background
	@echo "$(INFO) Starting chromedriver on port 4444..."
	@chromedriver --port=4444 > /dev/null 2>&1 & \
		CHROMEDRIVER_PID=$$!; \
		sleep 2; \
		echo "$(INFO) chromedriver started (PID: $$CHROMEDRIVER_PID)"; \
		cd example-showcase && ${FLUTTER} drive \
			--driver=test_driver/integration_test.dart \
			--target=integration_test/e2e_ui_test.dart \
			-d web-server \
			--web-browser-flag=--autoplay-policy=no-user-gesture-required; \
		EXIT_CODE=$$?; \
		echo "$(INFO) Stopping chromedriver..."; \
		pkill -f chromedriver 2>/dev/null || true; \
		if [ $$EXIT_CODE -ne 0 ]; then exit $$EXIT_CODE; fi
	@echo ""
	@echo "$(CHECK) E2E UI tests on Chrome complete!"
