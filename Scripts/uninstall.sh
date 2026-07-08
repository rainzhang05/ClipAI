#!/bin/bash
set -euo pipefail

GLOBAL_INSTALL_PATH="/usr/local/bin/clip"
USER_INSTALL_PATH="${HOME}/.local/bin/clip"
removed=false

remove_if_present() {
    local path="$1"

    if [ ! -f "$path" ]; then
        return
    fi

    echo "Removing $path..."
    if [ -w "$(dirname "$path")" ]; then
        rm "$path"
    else
        sudo rm "$path"
    fi
    removed=true
}

remove_if_present "$GLOBAL_INSTALL_PATH"
remove_if_present "$USER_INSTALL_PATH"

if [ "$removed" = true ]; then
    echo ""
    echo "✓ ClipAI uninstalled successfully."
else
    echo "ClipAI is not installed at $GLOBAL_INSTALL_PATH or $USER_INSTALL_PATH."
fi
