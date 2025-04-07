#!/bin/bash
#
# Test combined organization for Sony cameras
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

# Verify Sony images combined organization
SONY_FILE=$(find "output" -name "sony_2020*.jpg" | head -n 1)
if [[ -z "$SONY_FILE" ]]; then
  echo "FAIL: Sony image (sony_2020.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "output" -type f
  exit 1
fi
echo "Found sony_2020.jpg at: $SONY_FILE"

CAMERA_ONLY_FILE=$(find "output" -name "camera_only*.jpg" | head -n 1)
if [[ -z "$CAMERA_ONLY_FILE" ]]; then
  echo "FAIL: Sony image (camera_only.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "output" -type f
  exit 1
fi
echo "Found camera_only.jpg at: $CAMERA_ONLY_FILE"

echo "SUCCESS: Sony images were correctly organized by camera and date"