# Photo Organizer Test Suite

This directory contains test scripts and test cases for the Photo Organizer tool.

## Test Structure

The test suite is organized into several test case groups, each testing a specific aspect of the photo organizer:

- **date_organization**: Tests for organizing photos by date
- **camera_test**: Tests for organizing photos by camera make/model
- **combined_test**: Tests for organizing photos by both camera and date
- **exif_test**: Tests for handling EXIF data in various scenarios

Each test case group contains:
- `input/`: Directory with test images
- `test.sh`: The original monolithic test script
- `individual_tests/`: Directory with individual test files for each specific test case
- `run_individual_tests.sh`: Script to run all individual tests in the group

## Running Tests

### Setup Test Images

Before running tests, you need to create the test images and set them up:

```bash
# Create the test images with various EXIF configurations
cd ../test_images && ./create_test_images.sh

# Set up the test images in the test case directories
cd ../test_scripts && ./setup_test_images.sh
```

### Run All Tests

To run all test cases:

```bash
./run_all_tests.sh
```

### Run a Single Test Group

To run all tests in a specific test group:

```bash
./test_cases/[test_group]/run_individual_tests.sh
```

For example:
```bash
./test_cases/exif_test/run_individual_tests.sh
```

### Run a Single Test

To run a single test (original method):

```bash
./test_single.sh TEST_NAME
```

Where `TEST_NAME` is the name of a test case directory in `test_cases/`.

To run a specific individual test:

```bash
# Navigate to the test directory first
cd test_cases/[test_group]/individual_tests
bash [test_file].sh
```

For example:
```bash
cd test_cases/exif_test/individual_tests
bash complete_exif_test.sh
```

## Available Test Cases

### Date Organization Tests
- `date_directory_creation_test` - Tests creation of date-based directory structure
- `date_file_organization_test` - Tests files are organized into correct date directories

### EXIF Data Tests
- `complete_exif_test` - Tests organization of images with complete EXIF data
- `partial_exif_test` - Tests organization of images with partial EXIF data
- `no_exif_test` - Tests organization of images with no EXIF data
- `exif_enhancement_test` - Tests EXIF data enhancement functionality

### Camera Tests
- `canon_camera_test` - Tests organization of Canon camera images
- `nikon_camera_test` - Tests organization of Nikon camera images
- `sony_camera_test` - Tests organization of Sony camera images
- `unknown_camera_test` - Tests organization of images with no camera data

### Combined Organization Tests
- `canon_combined_test` - Tests combined organization of Canon camera images
- `nikon_combined_test` - Tests combined organization of Nikon camera images
- `sony_combined_test` - Tests combined organization of Sony camera images
- `unknown_combined_test` - Tests combined organization of images with no camera data

## Adding New Tests

To add a new test case:

1. Create a new script in the appropriate `individual_tests/` directory
2. Make sure your script:
   - Creates a clean test environment
   - Runs the photo organizer with appropriate options
   - Verifies the expected output
   - Returns a non-zero exit code on failure
   - Outputs clear error messages

3. Make the script executable:
   ```bash
   chmod +x your_new_test.sh
   ```

4. Run your test using the instructions above

## Test Images

Test images are automatically generated with the following characteristics:

### Complete EXIF Data
- Canon (2018), Nikon (2019), and Sony (2020) images
- All have DateTimeOriginal, CreateDate, and ModifyDate fields

### Partial EXIF Data
- Images with only CreateDate (no DateTimeOriginal)
- Images with only ModifyDate (no DateTimeOriginal or CreateDate)
- Images with camera information but no date information

### No EXIF Data
- JPG images with no EXIF metadata, relying on file timestamps
- PNG image (which typically has no standard EXIF data)

## GitHub Actions Integration

The test suite is integrated with GitHub Actions for continuous integration:
- Tests run automatically on push and pull requests
- Includes shellcheck validation of all scripts
- Creates test images and verifies all test cases