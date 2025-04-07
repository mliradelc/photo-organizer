#!/bin/bash
#
# Debug test script to identify issues
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Set up test environment
TEST_TMP_DIR="$(mktemp -d)"
echo "Created test directory: $TEST_TMP_DIR"

# Copy test data
cp -r "$SCRIPT_DIR/input" "$TEST_TMP_DIR/"
echo "Copied input data to test directory"

# Run each test individually
for test_file in individual_tests/*.sh; do
  test_name=$(basename "$test_file" .sh)
  echo "==== Running test: $test_name ===="
  
  # Change to test directory
  cd "$TEST_TMP_DIR"
  
  # Run the test with detailed output
  bash -x "$SCRIPT_DIR/$test_file" 2>&1 || echo "Test $test_name failed with exit code $?"
  
  echo "==== Completed test: $test_name ===="
  echo ""
  
  # Return to script directory
  cd "$SCRIPT_DIR"
done

# Clean up
echo "Cleaning up test directory..."
rm -rf "$TEST_TMP_DIR"
echo "Done."