#!/bin/bash
#
# Test photo organization for images with no camera data
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

# Run the photo organizer script with camera organization
"$ORGANIZER_SCRIPT" -o "output" -b "camera" -v "input"

# Check if the output directory was created
if [[ ! -d "output" ]]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# Verify images with no camera data
if [[ ! -f "output/Unknown_Camera/old_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (old_jpeg.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Unknown_Camera/recent_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (recent_jpeg.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Unknown_Camera/image.png" ]]; then
  echo "FAIL: PNG image (image.png) was not organized correctly"
  exit 1
fi

echo "SUCCESS: Images with no camera data were correctly organized into Unknown_Camera folder"