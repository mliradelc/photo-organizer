#!/bin/bash
#
# Test photo organization for images with complete EXIF data
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

# Verify that images with complete EXIF data were organized correctly
# Canon 2018 image should be in 2018/05
if [[ ! -f "output/2018/05/canon_2018.jpg" ]]; then
  echo "FAIL: Complete EXIF image (canon_2018.jpg) was not organized correctly"
  exit 1
fi

# Nikon 2019 image should be in 2019/07
if [[ ! -f "output/2019/07/nikon_2019.jpg" ]]; then
  echo "FAIL: Complete EXIF image (nikon_2019.jpg) was not organized correctly"
  exit 1
fi

# Sony 2020 image should be in 2020/12
if [[ ! -f "output/2020/12/sony_2020.jpg" ]]; then
  echo "FAIL: Complete EXIF image (sony_2020.jpg) was not organized correctly"
  exit 1
fi

echo "SUCCESS: All images with complete EXIF data were correctly organized"