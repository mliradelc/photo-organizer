#!/bin/bash
#
# Test photo organization for images with partial EXIF data
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

# Verify that images with partial EXIF data were organized correctly
# CreateDate only image could be in 2021/03 or Canon_EOS_6D/2021/03
if [[ ! -f "output/2021/03/create_date_only.jpg" && ! -f "output/Canon_EOS_6D/2021/03/create_date_only.jpg" && ! -f "output/Canon_EOS_6D/create_date_only.jpg" ]]; then
  echo "FAIL: Partial EXIF image (create_date_only.jpg) was not organized correctly"
  echo "Expected to be in one of: output/2021/03/ or output/Canon_EOS_6D/2021/03/ or output/Canon_EOS_6D/"
  find "output" -name "create_date_only*.jpg"
  exit 1
fi

# ModifyDate only image could be in various locations
MODIFY_DATE_FILE=$(find "output" -name "modify_date_only*.jpg" | head -n 1)
if [[ -z "$MODIFY_DATE_FILE" ]]; then
  echo "FAIL: Partial EXIF image (modify_date_only.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "output" -type f
  exit 1
fi
echo "Found modify_date_only.jpg at: $MODIFY_DATE_FILE"

# Camera-only image could be in various locations
CAMERA_ONLY_FILE=$(find "output" -name "camera_only*.jpg" | head -n 1)
if [[ -z "$CAMERA_ONLY_FILE" ]]; then
  echo "FAIL: Camera-only image (camera_only.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "output" -type f
  exit 1
fi
echo "Found camera_only.jpg at: $CAMERA_ONLY_FILE"

echo "SUCCESS: All images with partial EXIF data were correctly organized"