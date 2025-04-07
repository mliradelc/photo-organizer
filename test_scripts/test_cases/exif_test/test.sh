#!/bin/bash
#
# Test photo organization with various EXIF data scenarios
#

# Make the output directory
mkdir -p "output"

# Find the repository root to locate the photo_organizer.sh script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ORGANIZER_SCRIPT="$REPO_ROOT/photo_organizer.sh"

# Debug paths
echo "Debug: SCRIPT_DIR=$SCRIPT_DIR"
echo "Debug: REPO_ROOT=$REPO_ROOT"
echo "Debug: ORGANIZER_SCRIPT=$ORGANIZER_SCRIPT"

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

# Verify that images with partial EXIF data were organized correctly
# CreateDate only image should be in 2021/03
if [[ ! -f "output/2021/03/create_date_only.jpg" ]]; then
  echo "FAIL: Partial EXIF image (create_date_only.jpg) was not organized correctly"
  exit 1
fi

# ModifyDate only image should be in 2021/04
if [[ ! -f "output/2021/04/modify_date_only.jpg" ]]; then
  echo "FAIL: Partial EXIF image (modify_date_only.jpg) was not organized correctly"
  exit 1
fi

# Camera-only image should be organized by file date (2021/05)
if [[ ! -f "output/2021/05/camera_only.jpg" ]]; then
  echo "FAIL: Camera-only image (camera_only.jpg) was not organized correctly"
  echo "Should be in output/2021/05 based on file timestamp"
  exit 1
fi

# Verify that images with no EXIF data were organized by file timestamp
# The test will use the current date based on when the test images are created

# Get the current year and date info (these files will be created with current timestamp)
CURRENT_YEAR=$(date +"%Y")
CURRENT_MONTH=$(date +"%m")

# Convert current month to zero-padded format if needed
CURRENT_MONTH_PADDED=$(printf "%02d" "$CURRENT_MONTH")

# Old JPEG - would be organized with current date from file timestamp
if [[ ! -f "output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/old_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (old_jpeg.jpg) was not organized correctly"
  echo "Expected to be in output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/ based on file timestamp"
  exit 1
fi

# Recent JPEG - would be organized with current date from file timestamp
if [[ ! -f "output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/recent_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (recent_jpeg.jpg) was not organized correctly"
  echo "Expected to be in output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/ based on file timestamp"
  exit 1
fi

# PNG image - would be organized with current date from file timestamp
if [[ ! -f "output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/image.png" ]]; then
  echo "FAIL: PNG image (image.png) was not organized correctly"
  echo "Expected to be in output/$CURRENT_YEAR/$CURRENT_MONTH_PADDED/ based on file timestamp"
  exit 1
fi

# Check that DateTimeOriginal was added to partial_exif images
mkdir -p "exif_check"

# Copy files to check EXIF data
cp "output/2021/03/create_date_only.jpg" "exif_check/"
cp "output/2021/04/modify_date_only.jpg" "exif_check/"
cp "output/2021/05/camera_only.jpg" "exif_check/"

# Check DateTimeOriginal on create_date_only.jpg
if ! exiftool -s3 -DateTimeOriginal "exif_check/create_date_only.jpg" | grep -q "2021:03:10"; then
  echo "FAIL: DateTimeOriginal was not added to create_date_only.jpg"
  exit 1
fi

# Check DateTimeOriginal on modify_date_only.jpg
if ! exiftool -s3 -DateTimeOriginal "exif_check/modify_date_only.jpg" | grep -q "2021:04:18"; then
  echo "FAIL: DateTimeOriginal was not added to modify_date_only.jpg"
  exit 1
fi

# Check DateTimeOriginal on camera_only.jpg
if ! exiftool -s3 -DateTimeOriginal "exif_check/camera_only.jpg" | grep -q "2021:05:01"; then
  echo "FAIL: DateTimeOriginal was not added to camera_only.jpg"
  exit 1
fi

# Clean up
rm -rf "exif_check"

echo "SUCCESS: All images were correctly organized based on available dates"