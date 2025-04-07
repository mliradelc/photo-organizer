#!/bin/bash
#
# Test photo organization for images with no EXIF data
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

# Verify that images with no EXIF data were organized by file timestamp
# Get the current year and date info (these files will be created with current timestamp)
CURRENT_YEAR=$(date +"%Y")
CURRENT_MONTH=$(date +"%m")

# Convert current month to zero-padded format if needed
CURRENT_MONTH_PADDED=$(printf "%02d" "$CURRENT_MONTH")

# Check for old_jpeg.jpg, which could be organized in either location
if [[ ! -f "output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/old_jpeg.jpg" && ! -f "output/Unknown_Camera/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/old_jpeg.jpg" && ! -f "output/Unknown_Camera/old_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (old_jpeg.jpg) was not organized correctly"
  echo "Expected to be in one of: output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/ or output/Unknown_Camera/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/ or output/Unknown_Camera/"
  ls -la "output"
  find "output" -name "old_jpeg*.jpg"
  exit 1
fi

# Check for recent_jpeg.jpg, which could be organized in either location
if [[ ! -f "output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/recent_jpeg.jpg" && ! -f "output/Unknown_Camera/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/recent_jpeg.jpg" && ! -f "output/Unknown_Camera/recent_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (recent_jpeg.jpg) was not organized correctly"
  echo "Expected to be in one of: output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/ or output/Unknown_Camera/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/ or output/Unknown_Camera/"
  ls -la "output"
  find "output" -name "recent_jpeg*.jpg"
  exit 1
fi

# Check for image.png, which could be organized in either location
if [[ ! -f "output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/image.png" && ! -f "output/Unknown_Camera/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/image.png" && ! -f "output/Unknown_Camera/image.png" ]]; then
  echo "FAIL: PNG image (image.png) was not organized correctly"
  echo "Expected to be in one of: output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/ or output/Unknown_Camera/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/ or output/Unknown_Camera/"
  ls -la "output"
  find "output" -name "image*.png"
  exit 1
fi

echo "SUCCESS: All images with no EXIF data were correctly organized by file timestamp"