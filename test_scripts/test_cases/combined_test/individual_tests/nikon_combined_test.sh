#!/bin/bash
#
# Test combined organization for Nikon cameras
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

# Verify Nikon images combined organization
NIKON_FILE=$(find "output" -name "nikon_2019*.jpg" | head -n 1)
if [[ -z "$NIKON_FILE" ]]; then
  echo "FAIL: Nikon image (nikon_2019.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "output" -type f
  exit 1
fi
echo "Found nikon_2019.jpg at: $NIKON_FILE"

MODIFY_DATE_FILE=$(find "output" -name "modify_date_only*.jpg" | head -n 1)
if [[ -z "$MODIFY_DATE_FILE" ]]; then
  echo "FAIL: Nikon image (modify_date_only.jpg) was not organized correctly"
  echo "Could not find the file anywhere in the output directory"
  find "output" -type f
  exit 1
fi
echo "Found modify_date_only.jpg at: $MODIFY_DATE_FILE"

echo "SUCCESS: Nikon images were correctly organized by camera and date"