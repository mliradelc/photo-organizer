#!/bin/bash
#
# Script to populate test directories with the test images
#

set -e

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Find the repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && cd .. && pwd)"
TEST_IMAGES_DIR="$REPO_ROOT/test_images"
CREATE_IMAGES_SCRIPT="$TEST_IMAGES_DIR/create_test_images.sh"

log "Repository root: $REPO_ROOT"
log "Test images directory: $TEST_IMAGES_DIR"

# Check if the script exists
if [[ ! -f "$CREATE_IMAGES_SCRIPT" ]]; then
  log "Error: Test image creation script not found at $CREATE_IMAGES_SCRIPT"
  exit 1
fi

# Create temporary directory for images
TMP_DIR="$(mktemp -d)"
log "Created temporary directory: $TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

# Change to the temporary directory
cd "$TMP_DIR"

# Run the script to create test images
log "Creating test images..."
bash "$CREATE_IMAGES_SCRIPT"

# Check if test image creation was successful
if [[ ! -d "complete_exif" || ! -d "partial_exif" || ! -d "no_exif" ]]; then
  log "Error: Test images were not created properly"
  ls -la
  exit 1
fi

# Create test case directories if they don't exist
mkdir -p "$SCRIPT_DIR/test_cases/exif_test/input"
mkdir -p "$SCRIPT_DIR/test_cases/camera_test/input"
mkdir -p "$SCRIPT_DIR/test_cases/combined_test/input"

# Copy images to test case input directories
log "Copying images to test directories..."

# Test case: exif_test
log "Setting up images for exif_test..."
cp -r complete_exif/* "$SCRIPT_DIR/test_cases/exif_test/input/"
cp -r partial_exif/* "$SCRIPT_DIR/test_cases/exif_test/input/"
cp -r no_exif/* "$SCRIPT_DIR/test_cases/exif_test/input/"

# Test case: camera_test
log "Setting up images for camera_test..."
cp -r complete_exif/* "$SCRIPT_DIR/test_cases/camera_test/input/"
cp -r partial_exif/* "$SCRIPT_DIR/test_cases/camera_test/input/"
cp -r no_exif/* "$SCRIPT_DIR/test_cases/camera_test/input/"

# Test case: combined_test
log "Setting up images for combined_test..."
cp -r complete_exif/* "$SCRIPT_DIR/test_cases/combined_test/input/"
cp -r partial_exif/* "$SCRIPT_DIR/test_cases/combined_test/input/"
cp -r no_exif/* "$SCRIPT_DIR/test_cases/combined_test/input/"

# Create a symbolic link from test_images directory to temp dir for easy access
ln -sf "$TMP_DIR/complete_exif" "$TEST_IMAGES_DIR/"
ln -sf "$TMP_DIR/partial_exif" "$TEST_IMAGES_DIR/"
ln -sf "$TMP_DIR/no_exif" "$TEST_IMAGES_DIR/"

log "All test images have been set up successfully!"
log "Test images copied to:"
log "  - $SCRIPT_DIR/test_cases/exif_test/input/"
log "  - $SCRIPT_DIR/test_cases/camera_test/input/"
log "  - $SCRIPT_DIR/test_cases/combined_test/input/"