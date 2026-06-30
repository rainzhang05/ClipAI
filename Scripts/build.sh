#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building qhelp (release)..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

BIN_PATH="$(swift build -c release --show-bin-path)/qhelp"

echo ""
echo "✓ Build successful!"
echo "Binary: $BIN_PATH"
echo ""
echo "To install globally, run:"
echo "  ./Scripts/install.sh"
