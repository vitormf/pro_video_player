#!/usr/bin/env bash
# Interactive task selector using fzf with category navigation
# Displays all available Make commands organized by category

set -e

RECENTS_FILE="$HOME/.platform-video-player-recents"
FLUTTER_CMD="${1:-flutter}"
IOS_SIMULATOR_ID="${2:-}"

# Sleep duration constants
readonly SLEEP_SHORT=1
readonly SLEEP_MEDIUM=2
readonly SLEEP_LONG=3
readonly SLEEP_EMULATOR=5

# Helper function to launch iOS simulator
launch_ios_simulator() {
	simulators=$(xcrun simctl list devices available 2>/dev/null | grep -E "^    " | grep -v "unavailable" | sed "s/^    //" || echo "")
	if [ -z "$simulators" ]; then
		echo ""
		echo "⚠️  No iOS simulators found"
		echo "💡 Make sure Xcode is installed with simulators"
		echo ""
		sleep "$SLEEP_MEDIUM"
		return 1
	else
		simulator=$(echo "$simulators" | fzf --height=100% --reverse \
			--header="🍏 iOS Simulators (select to launch)" \
			--prompt="❯ " \
			--pointer="▶" \
			--border=rounded \
			--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
		if [ -n "$simulator" ]; then
			sim_id=$(echo "$simulator" | sed -E "s/.*\(([A-Fa-f0-9-]+)\).*/\1/")
			if [ -n "$sim_id" ]; then
				echo ""
				echo "🚀 Launching simulator: $sim_id"
				xcrun simctl boot "$sim_id" 2>/dev/null || true
				open -a Simulator
				echo "✅ Simulator launched successfully"
				echo ""
				sleep "$SLEEP_SHORT"
				return 0
			fi
		fi
	fi
	return 1
}

# Helper function to launch Android emulator
launch_android_emulator() {
	emulators=$(emulator -list-avds 2>/dev/null || echo "")
	if [ -z "$emulators" ]; then
		echo ""
		echo "⚠️  No Android emulators found"
		echo "💡 Create emulators in Android Studio (AVD Manager)"
		echo ""
		sleep "$SLEEP_MEDIUM"
		return 1
	else
		emulator_name=$(echo "$emulators" | fzf --height=100% --reverse \
			--header="🤖 Android Emulators (select to launch)" \
			--prompt="❯ " \
			--pointer="▶" \
			--border=rounded \
			--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
		if [ -n "$emulator_name" ]; then
			echo ""
			echo "🚀 Launching emulator..."
			sh -c "emulator -avd \"$emulator_name\" > /dev/null 2>&1 &" &
			echo "✅ Emulator launched in background (detached from terminal)"
			echo ""
			sleep "$SLEEP_SHORT"
			return 0
		fi
	fi
	return 1
}

while true; do
	echo "📦 Pro Video Player - Task Selector"
	echo ""
	category=$(printf "%s\n" \
		"🕒 Recents" \
		"⚙️  Setup & Clean" \
		"🧪 Testing" \
		"📊 Coverage" \
		"📱 Devices" \
		"🏃 Run Example" \
		"📚 Help" \
		"❌ Exit" \
	| fzf --height=100% --reverse \
		--header="Select a task or category (ESC or select Exit to quit)" \
		--prompt="❯ " \
		--pointer="▶" \
		--border=rounded \
		--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")

	if [ -z "$category" ] || [ "$category" = "❌ Exit" ]; then
		echo ""
		echo "👋 Goodbye!"
		exit 0
	fi

	if echo "$category" | grep -q "^━"; then
		continue
	fi

	if echo "$category" | grep -q " | "; then
		task="$category"
	else
		task=""
	fi

	if [ -z "$task" ]; then
		case "$category" in
			"🕒 Recents")
				if [ ! -f "$RECENTS_FILE" ] || [ ! -s "$RECENTS_FILE" ]; then
					echo ""
					echo "⚠️  No recent commands yet"
					echo ""
					sleep 1
				else
					task=$(cat "$RECENTS_FILE" | fzf --height=100% --reverse \
						--header="🕒 Recent Commands (ESC to go back)" \
						--prompt="❯ " \
						--pointer="▶" \
						--border=rounded \
						--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
				fi ;;
			"⚙️  Setup & Clean")
				task=$(printf "%s\n" \
					"← Back to categories" \
					"setup | 🚀 Setup project (FVM + dependencies + shared links)" \
					"install | 📦 Install dependencies for all packages" \
					"setup-shared-links | 🔗 Create hard links for shared iOS/macOS sources" \
					"verify-shared-links | ✅ Verify shared sources are in sync" \
					"clean | 🧹 Clean all packages" \
					"format | 🎨 Format Dart code" \
					"format-check | 🔍 Check code format" \
					"fix | 🔧 Apply automatic Dart fixes" \
				| fzf --height=100% --reverse \
					--header="⚙️ Setup & Clean (ESC to go back)" \
					--prompt="❯ " \
					--pointer="▶" \
					--border=rounded \
					--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green") ;;
			"🧪 Testing")
				while true; do
					subcategory=$(printf "%s\n" \
						"← Back to categories" \
						"📦 Dart Tests" \
						"🔨 Native Tests" \
						"📱 E2E Tests" \
						"⚡ quick-check | Fast parallel compile check (Dart+Kotlin+Swift)" \
						"🔍 analyze | Analyze all packages" \
						"✅ check | Run all checks (format, analyze, test)" \
					| fzf --height=100% --reverse \
						--header="🧪 Testing (ESC to go back)" \
						--prompt="❯ " \
						--pointer="▶" \
						--border=rounded \
						--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
					if [ -z "$subcategory" ] || [ "$subcategory" = "← Back to categories" ]; then
						break
					fi
					if echo "$subcategory" | grep -q " | "; then
						task="$subcategory"
						break
					fi
					case "$subcategory" in
						"📦 Dart Tests")
							task=$(printf "%s\n" \
								"← Back" \
								"test | 🧪 Run all Dart tests" \
								"test-interface | 🧪 Test platform_interface" \
								"test-main | 🧪 Test main package" \
								"test-web | 🧪 Test web package (Chrome)" \
							| fzf --height=100% --reverse \
								--header="📦 Dart Tests (ESC to go back)" \
								--prompt="❯ " \
								--pointer="▶" \
								--border=rounded \
								--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
							if [ -n "$task" ] && [ "$task" != "← Back" ]; then
								break
							fi ;;
						"🔨 Native Tests")
							task=$(printf "%s\n" \
								"← Back" \
								"test-native | 🔨 Run all native tests" \
								"test-android-native | 🤖 Android native unit tests" \
								"test-android-instrumented | 📱 Android instrumented tests (device)" \
								"test-android-full-coverage | 🤖 Android FULL coverage (unit+device)" \
								"test-ios-native | 🍏 iOS native tests" \
								"test-macos-native | 💻 macOS native tests" \
							| fzf --height=100% --reverse \
								--header="🔨 Native Tests (ESC to go back)" \
								--prompt="❯ " \
								--pointer="▶" \
								--border=rounded \
								--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
							if [ -n "$task" ] && [ "$task" != "← Back" ]; then
								break
							fi ;;
						"📱 E2E Tests")
							echo "🔍 Detecting devices..."
							sleep "$SLEEP_SHORT"
							running_devices=$($FLUTTER_CMD devices 2>/dev/null | grep "•" | grep -v "No devices detected" | wc -l | xargs)
							if [ "$running_devices" = "0" ]; then
								echo ""
								echo "⚠️  No devices or emulators are running"
								echo ""
								launch_choice=$(printf "%s\n" \
									"🍏 Launch iOS Simulator" \
									"🤖 Launch Android Emulator" \
									"← Skip and continue" \
								| fzf --height=100% --reverse \
									--header="Select a device to launch (ESC to skip)" \
									--prompt="❯ " \
									--pointer="▶" \
									--border=rounded \
									--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
								case "$launch_choice" in
									"🍏 Launch iOS Simulator")
										if launch_ios_simulator; then
											echo "💡 Waiting 3 seconds for simulator to start..."
											sleep "$SLEEP_LONG"
										fi ;;
									"🤖 Launch Android Emulator")
										if launch_android_emulator; then
											echo "💡 Waiting 5 seconds for emulator to start..."
											sleep "$SLEEP_EMULATOR"
										fi ;;
								esac
							fi
							task=$(printf "%s\n" \
								"← Back" \
								"test-e2e | 🚀 E2E tests on ALL platforms (PARALLEL)" \
								"test-e2e-sequential | ⏭️  E2E tests on ALL platforms (Sequential)" \
								"test-e2e-ios | 🍏 E2E tests on iOS" \
								"test-e2e-android | 🤖 E2E tests on Android" \
								"test-e2e-macos | 💻 E2E tests on macOS" \
								"test-e2e-web | 🌐 E2E tests on Chrome (web)" \
							| fzf --height=100% --reverse \
								--header="📱 E2E Tests (ESC to go back)" \
								--prompt="❯ " \
								--pointer="▶" \
								--border=rounded \
								--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
							if [ -n "$task" ] && [ "$task" != "← Back" ]; then
								break
							fi ;;
					esac
				done ;;
			"📊 Coverage")
				task=$(printf "%s\n" \
					"← Back to categories" \
					"coverage | 📊 Full coverage report (Dart + Native)" \
					"test-coverage | 📊 Dart coverage only" \
					"coverage-html | 📄 Generate HTML report" \
					"coverage-summary | 📊 Show coverage summary" \
					"test-android-full-coverage | 🤖 Android FULL coverage (unit+device)" \
					"test-android-native-coverage | 🤖 Android unit tests coverage only" \
					"test-ios-native-coverage | 🍏 iOS native coverage" \
					"test-macos-native-coverage | 💻 macOS native coverage" \
				| fzf --height=100% --reverse \
					--header="📊 Coverage (ESC to go back)" \
					--prompt="❯ " \
					--pointer="▶" \
					--border=rounded \
					--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green") ;;
			"📱 Devices")
				while true; do
					platform=$(printf "%s\n" \
						"← Back to categories" \
						"🍏 iOS Simulators" \
						"🤖 Android Emulators" \
					| fzf --height=100% --reverse \
						--header="📱 Devices (ESC to go back)" \
						--prompt="❯ " \
						--pointer="▶" \
						--border=rounded \
						--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
					if [ -z "$platform" ] || [ "$platform" = "← Back to categories" ]; then
						break
					fi
					case "$platform" in
						"🍏 iOS Simulators")
							launch_ios_simulator ;;
						"🤖 Android Emulators")
							launch_android_emulator ;;
					esac
				done ;;
			"🏃 Run Example")
				echo "🔍 Detecting devices..."
				sleep "$SLEEP_SHORT"
				running_devices=$($FLUTTER_CMD devices 2>/dev/null | grep "•" | grep -v "No devices detected" | wc -l | xargs)
				if [ "$running_devices" = "0" ]; then
					echo ""
					echo "⚠️  No devices or emulators are running"
					echo ""
					launch_choice=$(printf "%s\n" \
						"🍏 Launch iOS Simulator" \
						"🤖 Launch Android Emulator" \
						"← Skip and continue" \
					| fzf --height=100% --reverse \
						--header="Select a device to launch (ESC to skip)" \
						--prompt="❯ " \
						--pointer="▶" \
						--border=rounded \
						--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
					case "$launch_choice" in
						"🍏 Launch iOS Simulator")
							if launch_ios_simulator; then
								echo "💡 Waiting 3 seconds for simulator to start..."
								sleep "$SLEEP_LONG"
							fi ;;
						"🤖 Launch Android Emulator")
							if launch_android_emulator; then
								echo "💡 Waiting 5 seconds for emulator to start..."
								sleep "$SLEEP_EMULATOR"
							fi ;;
					esac
				elif [ "$running_devices" -gt "1" ]; then
					echo ""
					echo "📱 Multiple devices detected ($running_devices devices)"
					echo ""
					devices_list=$($FLUTTER_CMD devices 2>/dev/null | grep "•" | grep -v "No devices detected")
					selected_device=$(printf "%s\n%s" "🌐 Run on first available" "$devices_list" | fzf --height=100% --reverse \
						--header="📱 Select target device" \
						--prompt="❯ " \
						--pointer="▶" \
						--border=rounded \
						--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green")
					if [ "$selected_device" != "🌐 Run on first available" ] && [ -n "$selected_device" ]; then
						device_id=$(echo "$selected_device" | cut -d'•' -f2 | xargs)
						echo ""
						echo "📱 Selected device: $device_id"
						echo ""
						sleep "$SLEEP_SHORT"
						export DEVICE_ID="$device_id"
					fi
				fi
				task=$(printf "%s\n" \
					"← Back to categories" \
					"run | 🏃 Run example-showcase app" \
					"run-simple | 🏃 Run example-simple-player app" \
				| fzf --height=100% --reverse \
					--header="🏃 Run Example App (ESC to go back)" \
					--prompt="❯ " \
					--pointer="▶" \
					--border=rounded \
					--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green") ;;
			"📚 Help")
				task=$(printf "%s\n" \
					"← Back to categories" \
					"help | 📚 Show available commands" \
					"verify-tools | 🔍 Verify development tools" \
				| fzf --height=100% --reverse \
					--header="📚 Help (ESC to go back)" \
					--prompt="❯ " \
					--pointer="▶" \
					--border=rounded \
					--color="header:italic:cyan,prompt:bold:blue,pointer:bold:green") ;;
		esac
	fi

	if [ -z "$task" ]; then
		continue
	fi

	if [ "$task" = "← Back to categories" ] || [ "$task" = "← Back" ]; then
		continue
	fi

	if echo "$task" | grep -q "^━"; then
		continue
	fi

	cmd=$(echo "$task" | cut -d"|" -f1 | sed "s/^[^a-z-]*//" | xargs)
	touch "$RECENTS_FILE"
	grep -v "^$cmd$" "$RECENTS_FILE" > "$RECENTS_FILE.tmp" 2>/dev/null || true
	echo "$cmd" | cat - "$RECENTS_FILE.tmp" > "$RECENTS_FILE.tmp2"
	head -10 "$RECENTS_FILE.tmp2" > "$RECENTS_FILE"
	rm -f "$RECENTS_FILE.tmp" "$RECENTS_FILE.tmp2"

	echo ""
	if [ -n "$DEVICE_ID" ]; then
		echo "▶️  Running: make $cmd DEVICE_ID=$DEVICE_ID"
	else
		echo "▶️  Running: make $cmd"
	fi
	echo ""

	if [ -n "$DEVICE_ID" ]; then
		make "$cmd" DEVICE_ID="$DEVICE_ID"
	else
		make "$cmd"
	fi
	exit $?
done
