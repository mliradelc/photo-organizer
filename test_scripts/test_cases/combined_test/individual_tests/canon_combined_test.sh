#!/bin/bash
#
# Test combined organization for Canon cameras
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

# Run the photo organizer script with combined organization
"$ORGANIZER_SCRIPT" -o "$OUTPUT_DIR" -b "both" -v "$INPUT_DIR"

# Check if the output directory was created
if [[ ! -d "$OUTPUT_DIR" ]]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# Verify Canon images combined organization
if [[ ! -f "$OUTPUT_DIR/Canon_EOS_5D_Mark_IV/2018/05/canon_2018.jpg" ]]; then
  echo "FAIL: Canon image (canon_2018.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "$OUTPUT_DIR/Canon_EOS_6D/2021/03/create_date_only.jpg" ]]; then
  echo "FAIL: Canon image (create_date_only.jpg) was not organized correctly"
  exit 1
fi

echo "SUCCESS: Canon images were correctly organized by camera and date"
exit 0