# Photo Organizer Test Suite

This directory contains test scripts and test cases for the Photo Organizer tool.

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

### Run a Single Test

To run a single test:

```bash
./test_single.sh TEST_NAME
```

Where `TEST_NAME` is the name of a test case directory in `test_cases/`.

## Test Case Structure

Each test case has the following structure:

```
test_cases/
└── test_name/
    ├── input/
    │   └── (sample photos to organize)
    └── test.sh
```

The `test.sh` script should:

1. Run the photo organizer with appropriate parameters
2. Verify the output is as expected
3. Return exit code 0 for success, non-zero for failure

## Available Test Cases

- `date_organization` - Tests basic date-based organization functionality
- `exif_test` - Tests organization with various EXIF data scenarios (complete, partial, none)
- `camera_test` - Tests organization by camera make and model
- `combined_test` - Tests combined organization (camera/date structure)

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