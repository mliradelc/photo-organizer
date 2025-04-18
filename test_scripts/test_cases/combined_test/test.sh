#!/bin/bash
#
# Test photo organization with combined camera and date structure
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

# Run the photo organizer script with combined organization
"$ORGANIZER_SCRIPT" -o "output" -b "both" -v "input"

# Check if the output directory was created
if [[ ! -d "output" ]]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# Verify that images were organized in combined structure (camera/year/month)
# Canon images
if [[ ! -f "output/Canon_EOS_5D_Mark_IV/2018/05/canon_2018.jpg" ]]; then
  echo "FAIL: Canon image (canon_2018.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Canon_EOS_6D/2021/03/create_date_only.jpg" ]]; then
  echo "FAIL: Canon image (create_date_only.jpg) was not organized correctly"
  exit 1
fi

# Nikon images
if [[ ! -f "output/Nikon_D850/2019/07/nikon_2019.jpg" ]]; then
  echo "FAIL: Nikon image (nikon_2019.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Nikon_D750/2021/04/modify_date_only.jpg" ]]; then
  echo "FAIL: Nikon image (modify_date_only.jpg) was not organized correctly"
  exit 1
fi

# Sony images
if [[ ! -f "output/Sony_Alpha_A7_III/2020/12/sony_2020.jpg" ]]; then
  echo "FAIL: Sony image (sony_2020.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Sony_Alpha_A7R_IV/2021/05/camera_only.jpg" ]]; then
  echo "FAIL: Sony image (camera_only.jpg) was not organized correctly"
  exit 1
fi

# Verify that images with no camera data were organized into Unknown folder
if [[ ! -f "output/Unknown_Camera/2019/01/old_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (old_jpeg.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Unknown_Camera/2022/12/recent_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (recent_jpeg.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Unknown_Camera/2020/06/image.png" ]]; then
  echo "FAIL: PNG image (image.png) was not organized correctly"
  exit 1
fi

echo "SUCCESS: All images were correctly organized by camera and date"