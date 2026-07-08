#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building ClipAI (release)..."
cd "$PROJECT_DIR"
swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="$BIN_DIR/clip"

echo ""
echo "✓ Build successful!"
echo "Binary: $BIN_PATH"
echo ""
echo "To install globally, run:"
echo "  ./Scripts/install.sh"
