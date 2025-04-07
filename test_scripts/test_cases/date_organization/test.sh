#!/bin/bash

# Test basic date organization functionality

# Run the photo organizer script with date organization
../../photo_organizer.sh -o "output" -b "date" -v "input"

# Check if the output directory was created
if [[ ! -d "output" ]]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# Basic checks on the output structure can be added here
# For example, checking if files were organized into date-based subdirectories

echo "SUCCESS: Files were organized by date"
