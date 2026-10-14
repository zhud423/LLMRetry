#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${PROJECT_DIR}/antigravity-retry"
PLIST_LABEL="com.antigravity.autoretry"
PLIST_PATH="${HOME}/Library/LaunchAgents/${PLIST_LABEL}.plist"

if [ ! -f "$BIN" ]; then
    echo "Building project binary..."
    "${PROJECT_DIR}/build.sh"
fi

mkdir -p "${HOME}/Library/LaunchAgents"

# Unload existing launch agent if running
launchctl unload "${PLIST_PATH}" 2>/dev/null || true

cat << EOF > "${PLIST_PATH}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${BIN}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${HOME}/Library/Logs/antigravity_retry.log</string>
    <key>StandardErrorPath</key>
    <string>${HOME}/Library/Logs/antigravity_retry_err.log</string>
</dict>
</plist>
EOF

launchctl load "${PLIST_PATH}"

echo "=== Daemon Service Installed Successfully ==="
echo "Service Label: ${PLIST_LABEL}"
echo "Plist Location: ${PLIST_PATH}"
echo "Log File: ${HOME}/Library/Logs/antigravity_retry.log"
echo "Status: Running in background (No Terminal window required!)"
