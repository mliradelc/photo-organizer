# Test Images for Photo Organizer

This directory contains scripts to create test images with various EXIF metadata configurations for testing the Photo Organizer.

## Creating Test Images

Run the script to create the test images:

```bash
./create_test_images.sh
```

This will generate test images in three categories:

## Image Categories

### Complete EXIF Data (`complete_exif/`)

Images with complete EXIF metadata including dates and camera information:

- `canon_2018.jpg` - Canon EOS 5D Mark IV, May 2018
- `nikon_2019.jpg` - Nikon D850, July 2019
- `sony_2020.jpg` - Sony Alpha A7 III, December 2020

All have DateTimeOriginal, CreateDate, and ModifyDate fields.

### Partial EXIF Data (`partial_exif/`)

Images with incomplete EXIF metadata:

- `create_date_only.jpg` - Has CreateDate but no DateTimeOriginal
- `modify_date_only.jpg` - Has ModifyDate only
- `camera_only.jpg` - Has camera information but no EXIF dates

These test the fallback mechanisms and date extraction logic.

### No EXIF Data (`no_exif/`)

Images with no EXIF metadata:

- `old_jpeg.jpg` - JPEG with no EXIF, file date from January 2019
- `recent_jpeg.jpg` - JPEG with no EXIF, file date from December 2022
- `image.png` - PNG image (typically has no standard EXIF), file date from June 2020

These test the script's handling of files with no metadata, relying on file timestamps.

## Using with Tests

The test images are used by the test scripts in `../test_scripts/`. They are automatically copied to the appropriate test case input directories when you run:

```bash
cd ../test_scripts
./setup_test_images.sh
```

## Requirements

- ImageMagick (`convert` command)
- ExifTool (`exiftool` command)

These tools are used to create and manipulate the test images.