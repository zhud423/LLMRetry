.PHONY: all build clean run test install daemon daemon-stop

all: build

build:
	@chmod +x build.sh
	@./build.sh

run: build
	@./antigravity-retry

test: build
	@./antigravity-retry --test-scan

install: build
	@chmod +x scripts/install.sh
	@./scripts/install.sh

daemon: build
	@chmod +x scripts/install-daemon.sh
	@./scripts/install-daemon.sh

daemon-stop:
	@launchctl unload ~/Library/LaunchAgents/com.antigravity.autoretry.plist 2>/dev/null || true
	@echo "Background daemon service stopped."

clean:
	@rm -rf build swift_cache antigravity-retry AntigravityRetry.app live_ocr_test test_scan_window
	@echo "Cleaned build artifacts."
