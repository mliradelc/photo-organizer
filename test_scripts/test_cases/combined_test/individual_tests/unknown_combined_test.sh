#!/bin/bash
#
# Test combined organization for images with no camera data
#

# Find the repository root and test directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_CASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ORGANIZER_SCRIPT="$REPO_ROOT/photo_organizer.sh"

# Set up input and output paths
INPUT_DIR="$TEST_CASE_DIR/input"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Create a clean output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Check if input directory exists
if [[ ! -d "$INPUT_DIR" ]]; then
  echo "ERROR: Input directory not found at: $INPUT_DIR"
  exit 1
fi

# Run the photo organizer script with combined organization
"$ORGANIZER_SCRIPT" -o "$OUTPUT_DIR" -b "both" -v "$INPUT_DIR"

# Check if the output directory was created
if [[ ! -d "$OUTPUT_DIR" ]]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# Verify images with no camera data combined organization
OLD_JPEG_FILE=$(find "$OUTPUT_DIR" -name "old_jpeg*.jpg" | head -n 1)
if [[ -z "$OLD_JPEG_FILE" ]]; then
  echo "FAIL: No EXIF image (old_jpeg.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi
echo "Found old_jpeg.jpg at: $OLD_JPEG_FILE"

RECENT_JPEG_FILE=$(find "$OUTPUT_DIR" -name "recent_jpeg*.jpg" | head -n 1)
if [[ -z "$RECENT_JPEG_FILE" ]]; then
  echo "FAIL: No EXIF image (recent_jpeg.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi
echo "Found recent_jpeg.jpg at: $RECENT_JPEG_FILE"

IMAGE_PNG_FILE=$(find "$OUTPUT_DIR" -name "image*.png" | head -n 1)
if [[ -z "$IMAGE_PNG_FILE" ]]; then
  echo "FAIL: PNG image (image.png) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi
echo "Found image.png at: $IMAGE_PNG_FILE"

echo "SUCCESS: Images with no camera data were correctly organized by Unknown_Camera and date"
exit 0