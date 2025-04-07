#!/bin/bash
#
# Test photo organization for images with partial EXIF data
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

# Verify that images with partial EXIF data were organized correctly
# CreateDate only image could be in 2021/03 or Canon_EOS_6D/2021/03
if [[ ! -f "$OUTPUT_DIR/2021/03/create_date_only.jpg" && ! -f "$OUTPUT_DIR/Canon_EOS_6D/2021/03/create_date_only.jpg" && ! -f "$OUTPUT_DIR/Canon_EOS_6D/create_date_only.jpg" ]]; then
  echo "FAIL: Partial EXIF image (create_date_only.jpg) was not organized correctly"
  echo "Expected to be in one of: $OUTPUT_DIR/2021/03/ or $OUTPUT_DIR/Canon_EOS_6D/2021/03/ or $OUTPUT_DIR/Canon_EOS_6D/"
  find "$OUTPUT_DIR" -name "create_date_only*.jpg"
  exit 1
fi

# ModifyDate only image could be in various locations
MODIFY_DATE_FILE=$(find "$OUTPUT_DIR" -name "modify_date_only*.jpg" | head -n 1)
if [[ -z "$MODIFY_DATE_FILE" ]]; then
  echo "FAIL: Partial EXIF image (modify_date_only.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi
echo "Found modify_date_only.jpg at: $MODIFY_DATE_FILE"

# Camera-only image could be in various locations
CAMERA_ONLY_FILE=$(find "$OUTPUT_DIR" -name "camera_only*.jpg" | head -n 1)
if [[ -z "$CAMERA_ONLY_FILE" ]]; then
  echo "FAIL: Camera-only image (camera_only.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi
echo "Found camera_only.jpg at: $CAMERA_ONLY_FILE"

echo "SUCCESS: All images with partial EXIF data were correctly organized"
exit 0