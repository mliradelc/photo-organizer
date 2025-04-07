#!/bin/bash
#
# Script to populate test directories with the test images
#

set -e

# The path to create_test_images.sh
CREATE_IMAGES_SCRIPT="../test_images/create_test_images.sh"

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if the script exists
if [[ ! -f "$CREATE_IMAGES_SCRIPT" ]]; then
  log "Error: Test image creation script not found at $CREATE_IMAGES_SCRIPT"
  exit 1
fi

# Create temporary directory for images
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Change to the temporary directory
cd "$TMP_DIR"

# Run the script to create test images
log "Creating test images..."
bash "$CREATE_IMAGES_SCRIPT"

# Copy images to test case input directories
log "Copying images to test directories..."

# Test case: exif_test
log "Setting up images for exif_test..."
mkdir -p "../test_cases/exif_test/input"
cp -r complete_exif/* "../test_cases/exif_test/input/"
cp -r partial_exif/* "../test_cases/exif_test/input/"
cp -r no_exif/* "../test_cases/exif_test/input/"

# Test case: camera_test
log "Setting up images for camera_test..."
mkdir -p "../test_cases/camera_test/input"
cp -r complete_exif/* "../test_cases/camera_test/input/"
cp -r partial_exif/* "../test_cases/camera_test/input/"
cp -r no_exif/* "../test_cases/camera_test/input/"

# Test case: combined_test
log "Setting up images for combined_test..."
mkdir -p "../test_cases/combined_test/input"
cp -r complete_exif/* "../test_cases/combined_test/input/"
cp -r partial_exif/* "../test_cases/combined_test/input/"
cp -r no_exif/* "../test_cases/combined_test/input/"

log "All test images have been set up successfully!"