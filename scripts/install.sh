#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${PROJECT_DIR}/antigravity-retry"

if [ ! -f "$BIN" ]; then
    echo "Executable not found, building..."
    "${PROJECT_DIR}/build.sh"
fi

# Try /usr/local/bin first if writable, else ~/.local/bin
if [ -w "/usr/local/bin" ]; then
    TARGET_DIR="/usr/local/bin"
else
    TARGET_DIR="${HOME}/.local/bin"
    mkdir -p "${TARGET_DIR}"
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":${TARGET_DIR}:"* ]]; then
        echo "Adding ${TARGET_DIR} to ~/.zshrc PATH..."
        if ! grep -q '\.local/bin' "${HOME}/.zshrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc"
        fi
    fi
fi

cp "${BIN}" "${TARGET_DIR}/antigravity-retry"
chmod +x "${TARGET_DIR}/antigravity-retry"

echo "=== Installed successfully ==="
echo "Binary placed at: ${TARGET_DIR}/antigravity-retry"
