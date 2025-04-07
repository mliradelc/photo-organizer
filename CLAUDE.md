# Photo Organizer Development Guide

## Commands
- Run script: `bash photo_organizer.sh`
- Lint shell scripts: `shellcheck photo_organizer.sh`
- Test EXIF extraction: `exiftool -a -u -g1 test_image.jpg`
- Run single test: `bash test_scripts/test_single.sh TEST_NAME`

## Code Style Guidelines
- **Shell Script**: Follow Google Shell Style Guide
- **Naming**: Use snake_case for variables/functions
- **Formatting**: 2-space indentation, 80 character line limit
- **Comments**: Add comments for complex operations
- **Error Handling**: Use `trap` for cleanup, provide clear error messages
- **Input Validation**: Always validate user inputs before processing
- **File Handling**: Check file existence before operations
- **Dependencies**: Check for required tools (exiftool) at startup
- **Logging**: Use echo with descriptive prefixes for different message types
- **Functions**: Create modular functions with clear purpose

## Tools Used
- exiftool: For EXIF metadata extraction and analysis
- Standard Linux utilities (find, stat, cp, etc.)