#!/bin/bash
#
# Test combined organization for Sony cameras
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

# Verify Sony images combined organization
SONY_FILE=$(find "$OUTPUT_DIR" -name "sony_2020*.jpg" | head -n 1)
if [[ -z "$SONY_FILE" ]]; then
  echo "FAIL: Sony image (sony_2020.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi
echo "Found sony_2020.jpg at: $SONY_FILE"

CAMERA_ONLY_FILE=$(find "$OUTPUT_DIR" -name "camera_only*.jpg" | head -n 1)
if [[ -z "$CAMERA_ONLY_FILE" ]]; then
  echo "FAIL: Sony image (camera_only.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi
echo "Found camera_only.jpg at: $CAMERA_ONLY_FILE"

echo "SUCCESS: Sony images were correctly organized by camera and date"
exit 0