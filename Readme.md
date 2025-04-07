# Photo Organizer

A high-performance shell script tool to organize photos based on EXIF metadata, with automatic parallel processing for efficient handling of large photo collections.

## Features

- Organize photos by date, camera, or both
- Copy or move files to organized structure
- Preserve original metadata
- Handle duplicate files safely
- Extract EXIF data for organization
- Support for dry-run mode to preview changes
- Recursive directory processing option
- Detailed logging with verbose mode
- Parallel processing for improved performance
- Auto-detection of available CPU cores

## Requirements

- Linux/Unix environment
- Bash shell
- ExifTool (for metadata extraction)
- Standard Linux utilities

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/photo-organizer.git
   ```

2. Make the script executable:
   ```
   chmod +x photo_organizer.sh
   ```

3. Install ExifTool (if not already installed):
   - On Ubuntu/Debian: `sudo apt-get install libimage-exiftool-perl`
   - On Fedora: `sudo dnf install perl-Image-ExifTool`
   - On macOS with Homebrew: `brew install exiftool`
   - More installation options: https://exiftool.org/install.html

## Usage

```
./photo_organizer.sh [OPTIONS] SOURCE_DIRECTORY
```

### Options

- `-o, --output DIR`: Output directory (default: organized_photos)
- `-b, --organize-by TYPE`: Organize by: date, camera, both (default: date)
- `-m, --move`: Move files instead of copying
- `-d, --dry-run`: Show what would be done without making changes
- `-r, --recursive`: Process directories recursively
- `-v, --verbose`: Enable verbose output
- `-p, --parallel`: Enable parallel processing (default)
- `-s, --sequential`: Disable parallel processing and use sequential processing
- `-j, --jobs NUM`: Number of parallel jobs (default: auto-detected based on CPU cores)
- `-h, --help`: Display help message
- `--version`: Display version information

### Examples

```
# Organize photos by date with automatic parallel processing (default)
./photo_organizer.sh ~/Pictures

# Organize by camera model
./photo_organizer.sh -o ~/Sorted -b camera ~/Pictures

# Move files instead of copying, with recursive directory processing
./photo_organizer.sh -m -r ~/Pictures

# Use sequential processing (disable parallel processing)
./photo_organizer.sh -s ~/Pictures

# Specify number of parallel jobs
./photo_organizer.sh -j 8 ~/Pictures

# Preview changes without modifying files
./photo_organizer.sh -d -v ~/Pictures
```

## Organization Structure

### By Date
```
organized_photos/
├── 2023/
│   ├── 01/
│   │   ├── IMG_0001.jpg
│   │   └── IMG_0002.jpg
│   └── 02/
│       ├── IMG_0003.jpg
│       └── ...
└── 2022/
    └── ...
```

### By Camera
```
organized_photos/
├── Canon_EOS_R5/
│   ├── IMG_0001.jpg
│   └── IMG_0002.jpg
├── iPhone_13_Pro/
│   └── IMG_0003.jpg
└── Nikon_Z6/
    └── ...
```

### By Both
```
organized_photos/
├── Canon_EOS_R5/
│   ├── 2023/
│   │   ├── 01/
│   │   │   └── IMG_0001.jpg
│   │   └── ...
│   └── 2022/
│       └── ...
├── iPhone_13_Pro/
│   └── ...
└── Nikon_Z6/
    └── ...
```

## Development

- Run script: `bash photo_organizer.sh`
- Lint shell scripts: `shellcheck photo_organizer.sh`
- Test EXIF extraction: `exiftool -a -u -g1 test_image.jpg`
- Run single test: `bash test_scripts/test_single.sh TEST_NAME`

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.