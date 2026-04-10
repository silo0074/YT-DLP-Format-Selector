#!/bin/bash

cd "$(dirname "$0")"

# Configuration - Using absolute paths based on the script location
SKIP_CONFIRMATION=false  # Set to true to skip metadata fetching and confirmation
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
YTP_PATH="$SCRIPT_DIR/yt-dlp_linux"
DENO_PATH="$HOME/.deno/bin/deno"
DOWNLOAD_DIR="/home/me/Downloads/%(uploader)s - %(upload_date>%Y-%m-%d)s - %(title)s [%(id)s]"
FILE_NAME="%(uploader)s - %(upload_date>%Y-%m-%d)s - %(title)s [%(id)s].%(ext)s"

# Function to print separators
divider() {
    echo "======================================================================================================================"
}

# --- Executable Check ---
if ! command -v "$YTP_PATH" &> /dev/null; then
    divider
    echo " ERROR: yt-dlp binary was not found at: $YTP_PATH"
    echo " Please install yt-dlp or update the YTP_PATH variable in this script."
    divider
    exit 1
fi
# ------------------------

# Global arguments used for ALL downloads
# Bash array COMMON_ARGS=( ... ) to store custom settings.
# This is much cleaner than long strings and prevents issues with spaces or special characters.
# Removed --newline from the execution call to keep progress on one line
COMMON_ARGS=(
    --format-sort "res,vcodec:vp9,br"
    --fixup detect_or_warn
    --remux-video mkv
    --embed-metadata
    --parse-metadata "%(uploader_id)s:%(meta_uploader_id)s"
    --postprocessor-args "VideoRemuxer+ffmpeg:-bsf:v setts=pts=DTS"
    --js-runtimes "deno:$DENO_PATH"
    --cookies-from-browser chromium
    -o "$DOWNLOAD_DIR/$FILE_NAME"
    --ignore-errors
    --ignore-config
    --console-title
    --no-overwrites # Explicitly tell yt-dlp not to overwrite existing files
)

divider
echo ""
read -p "[Enter video URL] " URL
echo ""
divider

# 2) Error detection for format listing
echo -e "\nFetching available formats...\n"
if ! "$YTP_PATH" -F "$URL" --list-formats --cookies-from-browser chromium --js-runtimes "deno:$DENO_PATH"; then
    echo -e "\nERROR: Failed to retrieve formats. Please check the URL or your connection."
    divider
    read -n 1 -s -r -p "Press any key to exit..."
    exit 1
fi
echo ""
divider

while true; do
    echo ""
    echo "1) Video + Audio (Manual Selection)"
    echo "2) Single format (Audio only / Video only / Specific ID)"
    echo "3) Auto-select BEST format (VP9 Preferred)"
    echo "4) Exit"
    echo ""
    read -p "Select option: " option

    if [ "$option" == "1" ]; then
        echo -e "\nAudio format is in auto-selection mode"
        read -p "Select video ID (e.g. 137): " video
        # read -p "Select audio ID (e.g. 251-8): " audio
        # This tells yt-dlp: Use the video ID I typed, and find the best audio that is English
        # PREFERENCE ORDER:
        # 1. English + Opus
        # 2. English + Any codec
        # 3. Best audio available + Opus
        # 4. Best audio available
        SELECTED_FORMAT="$video+bestaudio[language^=en][acodec^=opus]/$video+bestaudio[language^=en]/$video+bestaudio[acodec^=opus]/$video+bestaudio"
        break

    elif [ "$option" == "2" ]; then
        read -p "Select format ID: " format
        SELECTED_FORMAT="$format"
        break

    elif [ "$option" == "3" ]; then
        # Mode for best format with VP9 preference
        SELECTED_FORMAT="bestvideo+bestaudio[language^=en][acodec^=opus]/bestvideo+bestaudio[language^=en]/bestvideo+bestaudio[acodec^=opus]/bestvideo+bestaudio"
        break

    elif [ "$option" == "4" ]; then
        echo -e "\nExiting...\n"
        exit 0

    else
        echo -e "\nUnknown value\n"
        divider
    fi
done

# --- Download Confirmation Logic ---
if [ "$SKIP_CONFIRMATION" = false ]; then
    echo -e "\nFetching metadata for confirmation...\n"

    # We fetch Title, Duration, Size, Resolved IDs, and separate the Directory and Filename (no extension)
    # Fetch metadata - rely on %(filename)s for the path
    # RAW_META=$("$YTP_PATH" --print "%(title)s##%(duration_string)s##%(filesize,filesize_approx)s##%(format_id)s##$DOWNLOAD_DIR##$FILE_NAME##%(filename)s" -f "$SELECTED_FORMAT" "${COMMON_ARGS[@]}" "$URL")
    RAW_META=$("$YTP_PATH" --print "%(title)s##%(duration_string)s##%(filesize,filesize_approx)s##%(format_id)s##%(filename)s" -f "$SELECTED_FORMAT" "${COMMON_ARGS[@]}" "$URL")

    # Split metadata using awk
    V_TITLE=$(echo "$RAW_META" | awk -F'##' '{print $1}')
    V_DURATION=$(echo "$RAW_META" | awk -F'##' '{print $2}')
    V_SIZE_BYTES=$(echo "$RAW_META" | awk -F'##' '{print $3}')
    V_RESOLVED_ID=$(echo "$RAW_META" | awk -F'##' '{print $4}')
    V_FILENAME_RAW=$(echo "$RAW_META" | awk -F'##' '{print $5}')

    # Clean up the Filename (yt-dlp will replace .%(ext)s with .mkv)
    # We replace the template extension with .mkv for the existence check
    # Strip the existing extension (everything after the last dot) and force .mkv
    V_FULL_PATH="${V_FILENAME_RAW%.*}.mkv"

    # Helper variables for UI
    V_DIR=$(dirname "$V_FULL_PATH")
    V_NAME_ONLY=$(basename "$V_FULL_PATH" .mkv)

    # Convert bytes to MB using awk
    if [[ "$V_SIZE_BYTES" =~ ^[0-9]+$ ]]; then
        V_SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $V_SIZE_BYTES / 1048576}")
        DISPLAY_SIZE="${V_SIZE_MB} MB"
    else
        DISPLAY_SIZE="Unknown"
    fi

    divider
    echo "PENDING DOWNLOAD:"
    echo "Title:     $V_TITLE"
    echo "Duration:  $V_DURATION"
    echo "Est. Size: $DISPLAY_SIZE"
    echo "Selected:  $V_RESOLVED_ID"
    echo "Folder:    $V_DIR"
    echo "Filename:  $V_NAME_ONLY"
    divider
    echo ""

    # --- File Existence Check ---
    while [ -f "$V_FULL_PATH" ]; do
        divider
        echo "WARNING: File already exists!"
        echo "Path: $V_FULL_PATH"
        echo ""
        echo "1) Skip/Cancel"
        echo "2) Rename and Check again"
        read -p "Select action: " file_action

        if [ "$file_action" == "1" ]; then
            echo -e "\nDownload cancelled."
            exit 0
        elif [ "$file_action" == "2" ]; then
            # -e allows editing, -i provides the default text
            # We use V_NAME_ONLY so they don't have to re-type .mkv
            read -e -i "$V_NAME_ONLY" -p "Edit filename (no extension): " NEW_NAME

            # Update our check variables
            V_NAME_ONLY="$NEW_NAME"
            V_FULL_PATH="$V_DIR/$NEW_NAME.mkv"

            # Update the yt-dlp argument for the final command
            # COMMON_ARGS+=(-o "$V_FULL_PATH")
            FINAL_OUT="$V_FULL_PATH"
        else
            echo "Invalid option."
        fi
    done

    read -p "Proceed with download? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "\nDownload cancelled by user."
        exit 0
    fi
fi

echo -e "\nStarting Download...\n"
divider

# Fallback for FINAL_OUT if no renaming happened
FINAL_OUT="${FINAL_OUT:-$V_FULL_PATH}"

# Execute the global command with the selected format
"$YTP_PATH" -f "$SELECTED_FORMAT" "${COMMON_ARGS[@]}" -o "$FINAL_OUT" "$URL"

echo ""
divider
echo ""
echo "Done!"

read -n 1 -s -r -p "Press any key to close this window..."

# Final cleanup to ensure the terminal is "clean" for the next prompt
stty echo
# Optional: clear any remaining characters in the stdin buffer
read -r -t 0.1 -n 10000
echo ""
exit 0
