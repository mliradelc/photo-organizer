#!/bin/bash
#
# Test files are organized into correct date directories
#

# Find the repository root and test directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_CASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ORGANIZER_SCRIPT="$REPO_ROOT/photo_organizer.sh"

# Set up input and output paths
INPUT_DIR="$TEST_CASE_DIR/input"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Create a clean output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Check if input directory exists
if [[ ! -d "$INPUT_DIR" ]]; then
  echo "ERROR: Input directory not found at: $INPUT_DIR"
  exit 1
fi

# Run the photo organizer script with date organization
"$ORGANIZER_SCRIPT" -o "$OUTPUT_DIR" -b "date" -v "$INPUT_DIR"

# We should have specific test files with known dates: 2018, 2019, 2020, 2021
# as well as files that will be organized with current timestamp

# Check for files with known dates first
if [[ ! -f "$OUTPUT_DIR/2018/05/canon_2018.jpg" ]]; then
  echo "FAIL: Canon 2018 image was not organized to correct date directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi

if [[ ! -f "$OUTPUT_DIR/2019/07/nikon_2019.jpg" ]]; then
  echo "FAIL: Nikon 2019 image was not organized to correct date directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi

if [[ ! -f "$OUTPUT_DIR/2020/12/sony_2020.jpg" ]]; then
  echo "FAIL: Sony 2020 image was not organized to correct date directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi

if [[ ! -f "$OUTPUT_DIR/2021/03/create_date_only.jpg" ]]; then
  echo "FAIL: CreateDate only image was not organized to correct date directory"
  find "$OUTPUT_DIR" -type f
  exit 1
fi

# Now check for files without EXIF dates (should use file timestamp)
CURRENT_YEAR=$(date +"%Y")
CURRENT_MONTH=$(printf "%02d" "$(date +"%m")")

# There should be at least one file in the current year/month folder (files without EXIF)
# Use find instead of ls to be more flexible
if [[ -z "$(find "$OUTPUT_DIR/$CURRENT_YEAR/$CURRENT_MONTH" -type f -name "*.jpg" 2>/dev/null)" ]]; then
  echo "FAIL: No files found in date directory $OUTPUT_DIR/$CURRENT_YEAR/$CURRENT_MONTH/"
  echo "Files without EXIF were not organized by date correctly"
  find "$OUTPUT_DIR" -type f
  exit 1
fi

echo "SUCCESS: Files were correctly organized by date"
exit 0