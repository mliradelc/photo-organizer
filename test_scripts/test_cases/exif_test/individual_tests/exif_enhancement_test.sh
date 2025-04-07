#!/bin/bash
#
# Test photo EXIF data enhancement functionality
#

# Make the output directory
mkdir -p "output"

# Find the repository root to locate the photo_organizer.sh script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ORGANIZER_SCRIPT="$REPO_ROOT/photo_organizer.sh"

# Check if input directory exists
if [[ ! -d "input" ]]; then
  echo "ERROR: Input directory 'input' not found. This script must be run from a directory containing an 'input' folder."
  exit 1
fi

# Run the photo organizer script with date organization
"$ORGANIZER_SCRIPT" -o "output" -b "date" -v "input"

# Check if the output directory was created
if [[ ! -d "output" ]]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# Check that DateTimeOriginal was added to partial_exif images
mkdir -p "exif_check"

# Find the organized files which could be in different locations
CREATE_DATE_FILE=$(find "output" -name "create_date_only*.jpg" | head -n 1)
MODIFY_DATE_FILE=$(find "output" -name "modify_date_only*.jpg" | head -n 1)
CAMERA_ONLY_FILE=$(find "output" -name "camera_only*.jpg" | head -n 1)

# Check that the files were found
if [[ -z "$CREATE_DATE_FILE" ]]; then
  echo "FAIL: create_date_only.jpg was not found in the output directory"
  find "output" -type f
  exit 1
fi

if [[ -z "$MODIFY_DATE_FILE" ]]; then
  echo "FAIL: modify_date_only.jpg was not found in the output directory"
  find "output" -type f
  exit 1
fi

if [[ -z "$CAMERA_ONLY_FILE" ]]; then
  echo "FAIL: camera_only.jpg was not found in the output directory"
  find "output" -type f
  exit 1
fi

# Copy files to check EXIF data
cp "$CREATE_DATE_FILE" "exif_check/create_date_only.jpg"
cp "$MODIFY_DATE_FILE" "exif_check/modify_date_only.jpg"
cp "$CAMERA_ONLY_FILE" "exif_check/camera_only.jpg"

# Check DateTimeOriginal on create_date_only.jpg
CREATE_DATE_EXIF=$(exiftool -s3 -DateTimeOriginal "exif_check/create_date_only.jpg")
if [[ -z "$CREATE_DATE_EXIF" ]]; then
  echo "FAIL: DateTimeOriginal was not added to create_date_only.jpg"
  echo "EXIF: $CREATE_DATE_EXIF"
  exiftool -a -u -g1 "exif_check/create_date_only.jpg"
  exit 1
fi
echo "Found DateTimeOriginal for create_date_only.jpg: $CREATE_DATE_EXIF"

# Check DateTimeOriginal on modify_date_only.jpg
MODIFY_DATE_EXIF=$(exiftool -s3 -DateTimeOriginal "exif_check/modify_date_only.jpg")
if [[ -z "$MODIFY_DATE_EXIF" ]]; then
  echo "FAIL: DateTimeOriginal was not added to modify_date_only.jpg"
  echo "EXIF: $MODIFY_DATE_EXIF"
  exiftool -a -u -g1 "exif_check/modify_date_only.jpg"
  exit 1
fi
echo "Found DateTimeOriginal for modify_date_only.jpg: $MODIFY_DATE_EXIF"

# Check DateTimeOriginal on camera_only.jpg
CAMERA_ONLY_EXIF=$(exiftool -s3 -DateTimeOriginal "exif_check/camera_only.jpg")
if [[ -z "$CAMERA_ONLY_EXIF" ]]; then
  echo "FAIL: DateTimeOriginal was not added to camera_only.jpg"
  echo "EXIF: $CAMERA_ONLY_EXIF"
  exiftool -a -u -g1 "exif_check/camera_only.jpg"
  exit 1
fi
echo "Found DateTimeOriginal for camera_only.jpg: $CAMERA_ONLY_EXIF"

# Clean up
rm -rf "exif_check"

echo "SUCCESS: EXIF enhancement functionality is working correctly"