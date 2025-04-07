#!/bin/bash
#
# Test photo organization for images with complete EXIF data
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

# Run the photo organizer script with date organization
"$ORGANIZER_SCRIPT" -o "$OUTPUT_DIR" -b "date" -v "$INPUT_DIR"

# Check if the output directory was created
if [[ ! -d "$OUTPUT_DIR" ]]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# Verify that images with complete EXIF data were organized correctly
# Canon 2018 image should be in 2018/05
if [[ ! -f "$OUTPUT_DIR/2018/05/canon_2018.jpg" ]]; then
  echo "FAIL: Complete EXIF image (canon_2018.jpg) was not organized correctly"
  find "$OUTPUT_DIR" -type f -name "canon_2018.jpg"
  exit 1
fi

# Nikon 2019 image should be in 2019/07
if [[ ! -f "$OUTPUT_DIR/2019/07/nikon_2019.jpg" ]]; then
  echo "FAIL: Complete EXIF image (nikon_2019.jpg) was not organized correctly"
  find "$OUTPUT_DIR" -type f -name "nikon_2019.jpg"
  exit 1
fi

# Sony 2020 image should be in 2020/12
if [[ ! -f "$OUTPUT_DIR/2020/12/sony_2020.jpg" ]]; then
  echo "FAIL: Complete EXIF image (sony_2020.jpg) was not organized correctly"
  find "$OUTPUT_DIR" -type f -name "sony_2020.jpg"
  exit 1
fi

echo "SUCCESS: All images with complete EXIF data were correctly organized"
exit 0