#!/bin/bash
set -e

echo "=== Building Antigravity Hybrid Auto-Retry for macOS ==="

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
CACHE_DIR="${PROJECT_DIR}/swift_cache"
OUTPUT_BIN="${PROJECT_DIR}/antigravity-retry"
APP_BUNDLE="${PROJECT_DIR}/AntigravityRetry.app"

mkdir -p "${BUILD_DIR}"
mkdir -p "${CACHE_DIR}"

SWIFT_FILES=(
    "${PROJECT_DIR}/src/Config.swift"
    "${PROJECT_DIR}/src/Clicker.swift"
    "${PROJECT_DIR}/src/VisionOCR.swift"
    "${PROJECT_DIR}/src/AntigravityMonitor.swift"
    "${PROJECT_DIR}/src/StatusBarController.swift"
    "${PROJECT_DIR}/src/main.swift"
)

echo "Compiling Hybrid Swift source files..."
swiftc -O \
    -suppress-warnings \
    -Xfrontend -suppress-warnings \
    -module-cache-path "${CACHE_DIR}" \
    -framework AppKit \
    -framework Vision \
    -framework CoreGraphics \
    -framework ApplicationServices \
    "${SWIFT_FILES[@]}" \
    -o "${OUTPUT_BIN}"

# Create native macOS .app Bundle
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${OUTPUT_BIN}" "${APP_BUNDLE}/Contents/MacOS/AntigravityRetry"

cat << 'EOF' > "${APP_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AntigravityRetry</string>
    <key>CFBundleIdentifier</key>
    <string>com.antigravity.autoretry</string>
    <key>CFBundleName</key>
    <string>Antigravity Retry</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Apply Ad-Hoc Code Signature
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Build successful!"
echo "1. Binary created at: ${OUTPUT_BIN}"
echo "2. App Bundle created at: ${APP_BUNDLE}"
