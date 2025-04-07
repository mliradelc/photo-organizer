#!/bin/bash
#
# Test script for Photo Organizer
#

set -e

TEST_NAME="$1"
if [[ -z "$TEST_NAME" ]]; then
  echo "Error: Test name is required"
  echo "Usage: $(basename "$0") TEST_NAME"
  exit 1
fi

TEST_DIR="$(dirname "$0")/test_cases/$TEST_NAME"
if [[ ! -d "$TEST_DIR" ]]; then
  echo "Error: Test case not found: $TEST_NAME"
  exit 1
fi

TEST_SCRIPT="$(dirname "$0")/test_cases/$TEST_NAME/test.sh"
if [[ ! -f "$TEST_SCRIPT" ]]; then
  echo "Error: Test script not found: $TEST_SCRIPT"
  exit 1
fi

echo "Running test: $TEST_NAME"
echo "==============================="

# Create a clean test environment
TEST_TMP_DIR="$(mktemp -d)"
trap "rm -rf $TEST_TMP_DIR" EXIT

# Copy test data to temporary directory
cp -r "$TEST_DIR/input" "$TEST_TMP_DIR/"

# Run the test
cd "$TEST_TMP_DIR"
source "$TEST_SCRIPT"

echo "Test completed: $TEST_NAME"
