# YT-DLP Format Selector

A Linux Bash wrapper script for `yt-dlp`, allowing the user to download a media file by manually selecting a format or by letting yt-dlp select the best audio/video format. It was inspired by [https://github.com/edinsuta/yt-dlp-batch](https://github.com/edinsuta/yt-dlp-batch) which is made for Windows.

## Features
- Automatically prioritizes VP9 video and English Opus audio.
- Fetches and displays title, duration, and estimated file size before you commit to the download.
- Manually checks for existing files on disk. If a conflict is found, it allows you to rename the file within the terminal before starting.
- Forces .mkv remuxing in order to embed metadata such as uploader ID and video URL.
- Pre-configured to use Deno for solving YouTube JavaScript challenges.
- Automatically extracts cookies from Chromium to bypass age restrictions or bot detection.

## Prerequisites

1.  **[yt-dlp](https://github.com/yt-dlp/yt-dlp/releases):** Place the `yt-dlp_linux` binary in the script directory. For Linux yt-dlp_linux works better.
2.  **[Deno](https://github.com/denoland/deno):** Using the command `curl -fsSL https://deno.land/install.sh | sh` will install deno in `~/.deno/bin`.
3.  **FFmpeg:** Required for remuxing and metadata embedding.

## Installation

1. Clone the repository or download the files.
```bash
git clone https://github.com/silo0074/YT-DLP-Format-Selector.git
cd yt-dlp-format-selector
```

2. Ensure the binaries have execution permissions:
```bash
chmod +x yt-dlp-format-selector.sh install_desktop_shortcut.sh yt-dlp_linux
```
Modify the variables in the script if you want a different folder structure.

3. Create a desktop icon.
```bash
./install_desktop_shortcut.sh
```

## Configuration

At the beginning of the script there are these variables that can be changed:

**SKIP_CONFIRMATION**: Set to true to skip metadata fetching and confirmation.

**YTP_PATH**: yt-dlp path.

**DENO_PATH**: Path to deno binary.

**DOWNLOAD_DIR**: Creates a folder for each file. This specifies the name format for the folder.

**FILE_NAME**: Format for file name. Default format: `%(uploader)s - %(upload_date>%Y-%m-%d)s - %(title)s [%(id)s].%(ext)s`
Video ID is included to avoid name collision.

## Usage

Run the script in a terminal:
```bash
./yt-dlp-format-selector.sh
```
Script asks for URL then lists the available audio/video formats and their IDs, and presents the user with 4 choices:
1) Video + Audio (Manual Selection)
2) Single format (Audio only / Video only / Specific ID)
3) Auto-select BEST format (VP9 Preferred)
4) Exit

## Technical details

Explanation of used yt-dlp arguments.

### Format & Quality Control

`--format-sort "res,vcodec:vp9,br"`: This tells yt-dlp how to decide what "best" means. It prioritizes higher resolution first, then specifically looks for the VP9 codec, and finally uses bitrate as the tie-breaker.

`--remux-video mkv`: If the downloaded video and audio aren't already in an MKV container, this forces them to be wrapped into one without re-encoding the actual video/audio data. This is needed to embed custom metadata since mkv is more flexible in this regard.

`--fixup detect_or_warn`: Automatically attempts to fix known issues with the downloaded file (like broken headers) but only warns you if a critical fix fails.

### Metadata & Post-Processing

`--embed-metadata`: Takes the information about the video (description, upload date, etc.) and writes it directly into the video file's metadata tags.

`--parse-metadata "%(uploader_id)s:%(meta_uploader_id)s"`: This is a custom mapping that takes the internal *uploader_id* and saves it into a specific metadata field called *meta_uploader_id* for better organization in media players.

`--postprocessor-args "VideoRemuxer+ffmpeg:-bsf:v setts=pts=DTS"`: This is a technical fix for MKV files. It uses an ffmpeg bitstream filter (-bsf:v) to synchronize the "Presentation Time Stamps" (PTS) with the "Decoding Time Stamps" (DTS), which prevents stuttering or "jitter" in some video players.

### Compatibility & Authentication

`--js-runtimes "deno:$DENO_PATH"`: YouTube uses complex JavaScript to "scramble" signatures or player logic. This tells yt-dlp to use the Deno engine to execute that JavaScript and get the download links.

`--cookies-from-browser chromium`: Reads the cookies from your Chromium browser. This allows you to download age-restricted content or videos that require you to be "logged in" without manually providing a text file of cookies.

### Output & Behavior

`-o "$DOWNLOAD_DIR/$FILE_NAME"`: Sets the final path and filename using the templates defined at the top of the script.

`--no-overwrites`: A safety measure that tells yt-dlp to stop immediately if it detects a file with the same name already exists in the folder.

`--ignore-errors`: If a video in a playlist fails or a non-critical error occurs, the script will continue to the next task instead of crashing.

`--ignore-config`: Prevents yt-dlp from loading any settings from global config files (like /etc/yt-dlp.conf), ensuring your script behaves exactly the same on every computer.

`--console-title`: Updates the title of your Konsole terminal window with the current download progress and video title.

## Notes
* Higher size or bitrate doesn't necessarily means higher quality. Usually VP9 is a better choice.
* m3u8 protocol usually reports wrong size. I recommend using the https protocol.
* Use [MediaInfo](https://github.com/MediaArea/MediaInfo) to see file metadata. On CachyOS, Arch Linux it can be installed using `pacman -S mediainfo-gui`.