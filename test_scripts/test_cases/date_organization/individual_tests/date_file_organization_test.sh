#!/bin/bash
#
# Test files are organized into correct date directories
#

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

# Get the current year and date info (these files will be created with current timestamp)
CURRENT_YEAR=$(date +"%Y")
CURRENT_MONTH=$(date +"%m")

# Convert current month to zero-padded format if needed
CURRENT_MONTH_PADDED=$(printf "%02d" "$CURRENT_MONTH")

# Check for at least one file in the output directory
if ! ls "output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/"* &> /dev/null; then
  echo "FAIL: No files found in date directory output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/"
  echo "Files were not organized by date correctly"
  exit 1
fi

echo "SUCCESS: Files were organized by date correctly"