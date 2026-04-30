#!/bin/bash

# EasyTier Auto-update Script
# Designed to run inside Docker

INSTALL_PATH="/opt/easytier"
BIN_PATH="/usr/local/bin"
TEMP_DIR="/tmp/easytier_update"

# Colors for output
GREEN_COLOR='\e[1;32m'
RED_COLOR='\e[1;31m'
RES='\e[0m'

echo -e "${GREEN_COLOR}Starting EasyTier update check...${RES}"

# 1. Detect Architecture
platform=$(uname -m)
case "$platform" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    armv7*) ARCH="armv7" ;;
    *) echo -e "${RED_COLOR}Unsupported architecture: $platform${RES}"; exit 1 ;;
esac

# 2. Get Latest Tag
CURL_ARGS=("-s")
[ -n "$GH_TOKEN" ] && CURL_ARGS+=("-H" "Authorization: Bearer $GH_TOKEN")

LATEST_VERSION=$(curl "${CURL_ARGS[@]}" "https://api.github.com/repos/EasyTier/EasyTier/tags?per_page=1" | grep -m 1 '"name":' | sed -E 's/.*"name": *"([^"]+)".*/\1/')
LATEST_VERSION=$(echo -e "$LATEST_VERSION" | tr -d '[:space:]')

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED_COLOR}Failed to fetch latest version tag.${RES}"
    exit 1
fi

echo -e "Latest version: ${GREEN_COLOR}$LATEST_VERSION${RES}"

# Check current version (if exists)
if [ -f "$BIN_PATH/easytier-core" ]; then
    CURRENT_VERSION=$($BIN_PATH/easytier-core --version 2>&1 | awk '{print $2}')
    
    # Clean version strings for robust comparison
    # 1. Remove 'v' prefix
    # 2. Remove commit hash suffix (everything after the first hyphen)
    # 3. Remove whitespace
    CLEAN_CURRENT=$(echo "$CURRENT_VERSION" | sed 's/^v//' | cut -d'-' -f1 | tr -d '[:space:]')
    CLEAN_LATEST=$(echo "$LATEST_VERSION" | sed 's/^v//' | cut -d'-' -f1 | tr -d '[:space:]')
    
    if [ -n "$CLEAN_CURRENT" ] && [ "$CLEAN_CURRENT" == "$CLEAN_LATEST" ]; then
        echo -e "${GREEN_COLOR}Current version ($CURRENT_VERSION) matches latest base version ($CLEAN_LATEST). Skipping update.${RES}"
        exit 0
    fi
    echo -e "Current version: $CURRENT_VERSION, New version: $LATEST_VERSION. Proceeding with update..."
fi

# 3. Download and Extract
mkdir -p "$TEMP_DIR"
BASE_URL="https://github.com/EasyTier/EasyTier/releases/download/${LATEST_VERSION}/easytier-linux-${ARCH}-${LATEST_VERSION}.zip"

echo -e "Downloading: $BASE_URL"
curl -L "$BASE_URL" -o "$TEMP_DIR/easytier.zip"

if [ $? -ne 0 ]; then
    echo -e "${RED_COLOR}Download failed.${RES}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

unzip -o "$TEMP_DIR/easytier.zip" -d "$TEMP_DIR"

# 4. Install Binaries
echo -e "Installing new binaries..."

# The zip usually contains a subfolder easytier-linux-${ARCH}
EXTRACTED_DIR="$TEMP_DIR/easytier-linux-${ARCH}"
if [ ! -d "$EXTRACTED_DIR" ]; then
    # Fallback if no subfolder
    EXTRACTED_DIR="$TEMP_DIR"
fi

# Stop services if they are running (handled by entrypoint.sh usually, but we might need to kill them here)
# Since we are in Docker, we can just signal the entrypoint or use a process manager.
# For simplicity, we'll assume a simple process manager or just kill them.

pkill -f easytier-core
pkill -f easytier-web-embed

cp -f "$EXTRACTED_DIR/easytier-core" "$BIN_PATH/easytier-core"
cp -f "$EXTRACTED_DIR/easytier-cli" "$BIN_PATH/easytier-cli"
# Check if easytier-web-embed exists in the zip, otherwise try to find it
if [ -f "$EXTRACTED_DIR/easytier-web-embed" ]; then
    cp -f "$EXTRACTED_DIR/easytier-web-embed" "$BIN_PATH/easytier-web-embed"
else
    echo -e "${RED_COLOR}Warning: easytier-web-embed not found in release zip.${RES}"
fi

chmod +x "$BIN_PATH/easytier-core" "$BIN_PATH/easytier-cli"
[ -f "$BIN_PATH/easytier-web-embed" ] && chmod +x "$BIN_PATH/easytier-web-embed"

# 5. Cleanup
rm -rf "$TEMP_DIR"

echo -e "${GREEN_COLOR}Update completed successfully to $LATEST_VERSION!${RES}"

# Restart services will be handled by the entrypoint's loop or we can manually trigger it here
# But in a typical Docker setup, if the processes die, the container might exit unless we have a supervisor.
# We'll use a supervisor approach in entrypoint.sh.
