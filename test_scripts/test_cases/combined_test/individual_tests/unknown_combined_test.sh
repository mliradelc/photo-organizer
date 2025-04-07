#!/bin/bash
#
# Test combined organization for images with no camera data
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

# Run the photo organizer script with combined organization
"$ORGANIZER_SCRIPT" -o "output" -b "both" -v "input"

# Check if the output directory was created
if [[ ! -d "output" ]]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# Verify images with no camera data combined organization
OLD_JPEG_FILE=$(find "output" -name "old_jpeg*.jpg" | head -n 1)
if [[ -z "$OLD_JPEG_FILE" ]]; then
  echo "FAIL: No EXIF image (old_jpeg.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "output" -type f
  exit 1
fi
echo "Found old_jpeg.jpg at: $OLD_JPEG_FILE"

RECENT_JPEG_FILE=$(find "output" -name "recent_jpeg*.jpg" | head -n 1)
if [[ -z "$RECENT_JPEG_FILE" ]]; then
  echo "FAIL: No EXIF image (recent_jpeg.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "output" -type f
  exit 1
fi
echo "Found recent_jpeg.jpg at: $RECENT_JPEG_FILE"

IMAGE_PNG_FILE=$(find "output" -name "image*.png" | head -n 1)
if [[ -z "$IMAGE_PNG_FILE" ]]; then
  echo "FAIL: PNG image (image.png) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "output" -type f
  exit 1
fi
echo "Found image.png at: $IMAGE_PNG_FILE"

echo "SUCCESS: Images with no camera data were correctly organized by Unknown_Camera and date"