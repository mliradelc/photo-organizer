# Photo Organizer Test Suite

This directory contains test scripts and test cases for the Photo Organizer tool.

## Running Tests

To run a single test:

```bash
bash test_single.sh TEST_NAME
```

Where `TEST_NAME` is the name of a test case directory in `test_cases/`.

## Test Case Structure

Each test case should have the following structure:

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