#!/bin/bash
#
# Script to create dummy test images with various EXIF metadata configurations
#

set -e

# Create the test directories
mkdir -p complete_exif
mkdir -p partial_exif
mkdir -p no_exif

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Generate a 100x100 color block image
generate_color_image() {
  local output_file="$1"
  local color="$2"
  
  convert -size 100x100 "xc:$color" "$output_file"
  log "Created image: $output_file"
}

# 1. Images with complete EXIF data (different dates and camera models)
log "Creating images with complete EXIF data..."

# Image 1: From 2018, Canon camera
generate_color_image "complete_exif/canon_2018.jpg" "red"
exiftool -overwrite_original \
  "-Make=Canon" \
  "-Model=EOS 5D Mark IV" \
  "-DateTimeOriginal=2018:05:15 10:30:00" \
  "-CreateDate=2018:05:15 10:30:00" \
  "-ModifyDate=2018:05:15 10:30:00" \
  "-Software=PhotoOrganizer Test" \
  "complete_exif/canon_2018.jpg"

# Image 2: From 2019, Nikon camera
generate_color_image "complete_exif/nikon_2019.jpg" "green"
exiftool -overwrite_original \
  "-Make=Nikon" \
  "-Model=D850" \
  "-DateTimeOriginal=2019:07:22 15:45:20" \
  "-CreateDate=2019:07:22 15:45:20" \
  "-ModifyDate=2019:07:22 15:45:20" \
  "-Software=PhotoOrganizer Test" \
  "complete_exif/nikon_2019.jpg"

# Image 3: From 2020, Sony camera
generate_color_image "complete_exif/sony_2020.jpg" "blue"
exiftool -overwrite_original \
  "-Make=Sony" \
  "-Model=Alpha A7 III" \
  "-DateTimeOriginal=2020:12:25 08:15:30" \
  "-CreateDate=2020:12:25 08:15:30" \
  "-ModifyDate=2020:12:25 08:15:30" \
  "-Software=PhotoOrganizer Test" \
  "complete_exif/sony_2020.jpg"

# 2. Images with partial EXIF data (missing DateTimeOriginal)
log "Creating images with partial EXIF data..."

# Image 1: Missing DateTimeOriginal, has CreateDate
generate_color_image "partial_exif/create_date_only.jpg" "yellow"
exiftool -overwrite_original \
  "-Make=Canon" \
  "-Model=EOS 6D" \
  "-CreateDate=2021:03:10 14:22:35" \
  "-ModifyDate=2021:03:10 14:22:35" \
  "-Software=PhotoOrganizer Test" \
  "partial_exif/create_date_only.jpg"

# Image 2: Missing DateTimeOriginal and CreateDate, has ModifyDate
generate_color_image "partial_exif/modify_date_only.jpg" "purple"
exiftool -overwrite_original \
  "-Make=Nikon" \
  "-Model=D750" \
  "-ModifyDate=2021:04:18 09:12:45" \
  "-Software=PhotoOrganizer Test" \
  "partial_exif/modify_date_only.jpg"

# Image 3: Has camera info but no dates in EXIF
generate_color_image "partial_exif/camera_only.jpg" "orange"
exiftool -overwrite_original \
  "-Make=Sony" \
  "-Model=Alpha A7R IV" \
  "-Software=PhotoOrganizer Test" \
  "partial_exif/camera_only.jpg"

# Set the file modification time to simulate an older file
touch -t 202105010900 "partial_exif/camera_only.jpg"

# 3. Images with no EXIF data
log "Creating images with no EXIF data..."

# Image 1: Plain JPEG with no EXIF, old modification time
generate_color_image "no_exif/old_jpeg.jpg" "cyan"
# Remove all metadata
exiftool -all= -overwrite_original "no_exif/old_jpeg.jpg"
# Set a specific modification time
touch -t 201901010800 "no_exif/old_jpeg.jpg"

# Image 2: Plain JPEG with no EXIF, recent modification time
generate_color_image "no_exif/recent_jpeg.jpg" "magenta"
# Remove all metadata
exiftool -all= -overwrite_original "no_exif/recent_jpeg.jpg"
# Set a specific modification time
touch -t 202212252000 "no_exif/recent_jpeg.jpg"

# Image 3: PNG image (typically has no standard EXIF)
convert -size 100x100 xc:white "no_exif/image.png"
touch -t 202006152200 "no_exif/image.png"
log "Created image: no_exif/image.png"

log "All test images created successfully!"