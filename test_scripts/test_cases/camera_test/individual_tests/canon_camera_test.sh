#!/bin/bash
#
# Test photo organization for Canon cameras
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

# Verify Canon images
if [[ ! -f "output/Canon_EOS_5D_Mark_IV/canon_2018.jpg" ]]; then
  echo "FAIL: Canon image (canon_2018.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Canon_EOS_6D/create_date_only.jpg" ]]; then
  echo "FAIL: Canon image (create_date_only.jpg) was not organized correctly"
  exit 1
fi

echo "SUCCESS: Canon images were correctly organized by camera model"