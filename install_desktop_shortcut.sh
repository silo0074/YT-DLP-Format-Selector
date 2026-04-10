#!/bin/bash

# Configuration
DESKTOP_FILE="yt-dlp-format-selector.desktop"

# Standard path for the Desktop folder
TARGET_PATH="$HOME/Desktop/$DESKTOP_FILE"

# Get the absolute path of the directory where THIS script is located
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
FULL_SCRIPT_PATH="$CURRENT_DIR/yt-dlp-format-selector.sh"

echo "Creating desktop shortcut..."
echo "Script path: $FULL_SCRIPT_PATH"

# Copy the template to the Desktop
cp "$DESKTOP_FILE" "$TARGET_PATH"

# Replace the placeholder inside the desktop file
# We use | as a delimiter because the script path contains many / characters
sed -i "s|SCRIPT_PATH_PLACEHOLDER|$FULL_SCRIPT_PATH|g" "$TARGET_PATH"

# Ensure the desktop file is executable
chmod +x "$TARGET_PATH"

echo "Success! Desktop shortcut installed to $TARGET_PATH"