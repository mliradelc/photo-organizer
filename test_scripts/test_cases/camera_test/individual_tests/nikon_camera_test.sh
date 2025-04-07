#!/bin/bash
#
# Test photo organization for Nikon cameras
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

# Verify Nikon images
if [[ ! -f "output/Nikon_D850/nikon_2019.jpg" ]]; then
  echo "FAIL: Nikon image (nikon_2019.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Nikon_D750/modify_date_only.jpg" ]]; then
  echo "FAIL: Nikon image (modify_date_only.jpg) was not organized correctly"
  exit 1
fi

echo "SUCCESS: Nikon images were correctly organized by camera model"