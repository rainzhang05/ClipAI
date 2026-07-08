#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
GLOBAL_INSTALL_DIR="/usr/local/bin"
USER_INSTALL_DIR="${HOME}/.local/bin"

echo "Building ClipAI (release)..."
cd "$PROJECT_DIR"
swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="$BIN_DIR/clip"

install_to() {
    local target_dir="$1"
    local label="$2"

    mkdir -p "$target_dir"
    install -m 755 "$BIN_PATH" "$target_dir/clip"

    echo ""
    echo "✓ ClipAI installed to $target_dir/clip ($label)"
}

can_use_sudo() {
    sudo -n true 2>/dev/null
}

echo ""
if [ -w "$GLOBAL_INSTALL_DIR" ] 2>/dev/null; then
    install_to "$GLOBAL_INSTALL_DIR" "global"
elif can_use_sudo; then
    echo "Installing to $GLOBAL_INSTALL_DIR/clip (requires sudo)..."
    sudo mkdir -p "$GLOBAL_INSTALL_DIR"
    sudo install -m 755 "$BIN_PATH" "$GLOBAL_INSTALL_DIR/clip"
    echo ""
    echo "✓ ClipAI installed to $GLOBAL_INSTALL_DIR/clip (global)"
else
    echo "Cannot write to $GLOBAL_INSTALL_DIR without sudo."
    echo "Installing to $USER_INSTALL_DIR instead (no password required)..."
    install_to "$USER_INSTALL_DIR" "user-local"
    echo ""
    echo "Ensure this directory is on your PATH:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
echo "Usage:"
echo "  export ANTHROPIC_API_KEY=\"sk-ant-...\""
echo "  clip claude-sonnet-4-6"
echo ""
echo "Verify installation:"
echo "  which clip"
echo "  clip --help"
