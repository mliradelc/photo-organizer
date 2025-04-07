#!/bin/bash
#
# Test photo EXIF data enhancement functionality
#

# Find the repository root and test directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_CASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ORGANIZER_SCRIPT="$REPO_ROOT/photo_organizer.sh"

# Set up input and output paths
INPUT_DIR="$TEST_CASE_DIR/input"
OUTPUT_DIR="$SCRIPT_DIR/output"
EXIF_CHECK_DIR="$SCRIPT_DIR/exif_check"

# Create clean output directories
rm -rf "$OUTPUT_DIR" "$EXIF_CHECK_DIR"
mkdir -p "$OUTPUT_DIR" "$EXIF_CHECK_DIR"

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

# Find the organized files which could be in different locations
CREATE_DATE_FILE=$(find "$OUTPUT_DIR" -name "create_date_only*.jpg" | head -n 1)
MODIFY_DATE_FILE=$(find "$OUTPUT_DIR" -name "modify_date_only*.jpg" | head -n 1)
CAMERA_ONLY_FILE=$(find "$OUTPUT_DIR" -name "camera_only*.jpg" | head -n 1)

# Check that the files were found
if [[ -z "$CREATE_DATE_FILE" ]]; then
  echo "FAIL: create_date_only.jpg was not found in the output directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi

if [[ -z "$MODIFY_DATE_FILE" ]]; then
  echo "FAIL: modify_date_only.jpg was not found in the output directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi

if [[ -z "$CAMERA_ONLY_FILE" ]]; then
  echo "FAIL: camera_only.jpg was not found in the output directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi

# Copy files to check EXIF data
cp "$CREATE_DATE_FILE" "$EXIF_CHECK_DIR/create_date_only.jpg"
cp "$MODIFY_DATE_FILE" "$EXIF_CHECK_DIR/modify_date_only.jpg"
cp "$CAMERA_ONLY_FILE" "$EXIF_CHECK_DIR/camera_only.jpg"

# Check DateTimeOriginal on create_date_only.jpg
CREATE_DATE_EXIF=$(exiftool -s3 -DateTimeOriginal "$EXIF_CHECK_DIR/create_date_only.jpg")
if [[ -z "$CREATE_DATE_EXIF" ]]; then
  echo "FAIL: DateTimeOriginal was not added to create_date_only.jpg"
  echo "EXIF: $CREATE_DATE_EXIF"
  exiftool -a -u -g1 "$EXIF_CHECK_DIR/create_date_only.jpg"
  exit 1
fi
echo "Found DateTimeOriginal for create_date_only.jpg: $CREATE_DATE_EXIF"

# Check DateTimeOriginal on modify_date_only.jpg
MODIFY_DATE_EXIF=$(exiftool -s3 -DateTimeOriginal "$EXIF_CHECK_DIR/modify_date_only.jpg")
if [[ -z "$MODIFY_DATE_EXIF" ]]; then
  echo "FAIL: DateTimeOriginal was not added to modify_date_only.jpg"
  echo "EXIF: $MODIFY_DATE_EXIF"
  exiftool -a -u -g1 "$EXIF_CHECK_DIR/modify_date_only.jpg"
  exit 1
fi
echo "Found DateTimeOriginal for modify_date_only.jpg: $MODIFY_DATE_EXIF"

# Check DateTimeOriginal on camera_only.jpg
CAMERA_ONLY_EXIF=$(exiftool -s3 -DateTimeOriginal "$EXIF_CHECK_DIR/camera_only.jpg")
if [[ -z "$CAMERA_ONLY_EXIF" ]]; then
  echo "FAIL: DateTimeOriginal was not added to camera_only.jpg"
  echo "EXIF: $CAMERA_ONLY_EXIF"
  exiftool -a -u -g1 "$EXIF_CHECK_DIR/camera_only.jpg"
  exit 1
fi
echo "Found DateTimeOriginal for camera_only.jpg: $CAMERA_ONLY_EXIF"

# Clean up
rm -rf "$EXIF_CHECK_DIR"

echo "SUCCESS: EXIF enhancement functionality is working correctly"
exit 0