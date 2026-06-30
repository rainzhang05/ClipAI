#!/bin/bash
set -e

INSTALL_DIR="/usr/local/bin"

if [ -f "$INSTALL_DIR/qhelp" ]; then
    echo "Removing $INSTALL_DIR/qhelp..."
    sudo rm "$INSTALL_DIR/qhelp"
    echo ""
    echo "✓ qhelp uninstalled successfully."
else
    echo "qhelp is not installed at $INSTALL_DIR/qhelp."
fi
