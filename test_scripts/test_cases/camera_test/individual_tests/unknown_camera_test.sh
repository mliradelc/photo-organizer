#!/bin/bash
#
# Test photo organization for images with no camera data
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

# Run the photo organizer script with camera organization
"$ORGANIZER_SCRIPT" -o "$OUTPUT_DIR" -b "camera" -v "$INPUT_DIR"

# Check if the output directory was created
if [[ ! -d "$OUTPUT_DIR" ]]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# Verify images with no camera data
if [[ ! -f "$OUTPUT_DIR/Unknown_Camera/old_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (old_jpeg.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "$OUTPUT_DIR/Unknown_Camera/recent_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (recent_jpeg.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "$OUTPUT_DIR/Unknown_Camera/image.png" ]]; then
  echo "FAIL: PNG image (image.png) was not organized correctly"
  exit 1
fi

echo "SUCCESS: Images with no camera data were correctly organized into Unknown_Camera folder"
exit 0