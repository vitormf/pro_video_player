# Development tasks
# Running example apps and code generation

.PHONY: run run-simple pigeon-generate

# run: Run the example-showcase app
# Use when: Testing all library features in the showcase app
run: verify-tools
	@echo "$(ROCKET) Running example-showcase app..."
	@if [ -n "$(DEVICE_ID)" ]; then \
		cd example-showcase && ${FLUTTER} run -d $(DEVICE_ID); \
	else \
		cd example-showcase && ${FLUTTER} run; \
	fi

# run-simple: Run the example-simple-player app
# Use when: Testing simple file/URL video player
run-simple: verify-tools
	@echo "$(ROCKET) Running example-simple-player app..."
	@if [ -n "$(DEVICE_ID)" ]; then \
		cd example-simple-player && ${FLUTTER} run -d $(DEVICE_ID); \
	else \
		cd example-simple-player && ${FLUTTER} run; \
	fi

# pigeon-generate: Regenerate Pigeon code for all platforms
# Use when: After editing pro_video_player_platform_interface/pigeons/messages.dart
pigeon-generate: verify-tools
	@echo "$(WRENCH) Regenerating Pigeon code for all platforms from platform_interface..."
	@cd pro_video_player_platform_interface && ${DART} run pigeon --input pigeons/messages.dart
	@echo "$(INFO) Copying Swift to macOS..."
	@cp pro_video_player_ios/ios/Classes/PigeonMessages.swift pro_video_player_macos/macos/Classes/PigeonMessages.swift
	@echo "$(CHECK) Pigeon code regenerated for all platforms"
