# Development tasks
# Running example apps

.PHONY: run run-simple

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
