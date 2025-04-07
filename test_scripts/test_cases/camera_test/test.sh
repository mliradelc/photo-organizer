#!/bin/bash
#
# Test photo organization by camera make/model
#

# Make the output directory
mkdir -p "output"

# Run the photo organizer script with camera organization
../../../photo_organizer.sh -o "output" -b "camera" -v "input"

# Check if the output directory was created
if [[ ! -d "output" ]]; then
  echo "FAIL: Output directory was not created"
  exit 1
fi

# Verify that images with camera data were organized correctly
# Canon images
if [[ ! -f "output/Canon/EOS 5D Mark IV/canon_2018.jpg" ]]; then
  echo "FAIL: Canon image (canon_2018.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Canon/EOS 6D/create_date_only.jpg" ]]; then
  echo "FAIL: Canon image (create_date_only.jpg) was not organized correctly"
  exit 1
fi

# Nikon images
if [[ ! -f "output/Nikon/D850/nikon_2019.jpg" ]]; then
  echo "FAIL: Nikon image (nikon_2019.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Nikon/D750/modify_date_only.jpg" ]]; then
  echo "FAIL: Nikon image (modify_date_only.jpg) was not organized correctly"
  exit 1
fi

# Sony images
if [[ ! -f "output/Sony/Alpha A7 III/sony_2020.jpg" ]]; then
  echo "FAIL: Sony image (sony_2020.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Sony/Alpha A7R IV/camera_only.jpg" ]]; then
  echo "FAIL: Sony image (camera_only.jpg) was not organized correctly"
  exit 1
fi

# Verify that images with no camera data were organized into Unknown folder
if [[ ! -f "output/Unknown/old_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (old_jpeg.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Unknown/recent_jpeg.jpg" ]]; then
  echo "FAIL: No EXIF image (recent_jpeg.jpg) was not organized correctly"
  exit 1
fi

if [[ ! -f "output/Unknown/image.png" ]]; then
  echo "FAIL: PNG image (image.png) was not organized correctly"
  exit 1
fi

echo "SUCCESS: All images were correctly organized by camera make and model"