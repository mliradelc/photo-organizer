#!/bin/bash
#
# Run all individual tests for Photo Organizer
#

# Find the repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Setup test images if they don't exist
if [[ ! -f "test_cases/exif_test/input/canon_2018.jpg" ]]; then
  log "Setting up test images..."
  bash "$SCRIPT_DIR/setup_test_images.sh"
fi

# Define the test categories
TEST_CATEGORIES=(
  "camera_test/individual_tests/canon_camera_test.sh"
  "camera_test/individual_tests/nikon_camera_test.sh"
  "camera_test/individual_tests/sony_camera_test.sh"
  "camera_test/individual_tests/unknown_camera_test.sh"
  "date_organization/individual_tests/date_directory_creation_test.sh"
  "date_organization/individual_tests/date_file_organization_test.sh"
  "exif_test/individual_tests/complete_exif_test.sh"
  "exif_test/individual_tests/partial_exif_test.sh"
  "exif_test/individual_tests/no_exif_test.sh"
  "exif_test/individual_tests/exif_enhancement_test.sh"
  "combined_test/individual_tests/canon_combined_test.sh"
  "combined_test/individual_tests/nikon_combined_test.sh"
  "combined_test/individual_tests/sony_combined_test.sh"
  "combined_test/individual_tests/unknown_combined_test.sh"
)

log "Found ${#TEST_CATEGORIES[@]} individual tests to run"

# Track test results
PASSED=0
FAILED=0
FAILED_TESTS=()

# Run each test individually
for test_path in "${TEST_CATEGORIES[@]}"; do
  test_name=$(basename "$test_path" .sh)
  test_group=$(dirname "$(dirname "$test_path")")
  
  log "Running test: $test_name (group: $test_group)"
  
  # Create a clean test environment
  TEST_TMP_DIR="$(mktemp -d)"
  
  # Copy test data to temporary directory
  if [[ -d "$SCRIPT_DIR/test_cases/$test_group/input" ]]; then
    cp -r "$SCRIPT_DIR/test_cases/$test_group/input" "$TEST_TMP_DIR/"
    # Ensure that test images exist
    if [[ ! -f "$TEST_TMP_DIR/input/canon_2018.jpg" && -f "$SCRIPT_DIR/test_cases/exif_test/input/canon_2018.jpg" ]]; then
      log "Copying test images from exif_test/input..."
      cp -r "$SCRIPT_DIR/test_cases/exif_test/input/"* "$TEST_TMP_DIR/input/"
    fi
  else
    log "Error: No input directory found for test group: $test_group"
    exit 1
  fi
  
  # Run the test
  cd "$TEST_TMP_DIR" || exit 1
  
  log "Executing: $SCRIPT_DIR/test_cases/$test_path"
  
  if bash "$SCRIPT_DIR/test_cases/$test_path" > test_output.log 2>&1; then
    log "✅ Test passed: $test_name"
    ((PASSED++))
  else
    TEST_EXIT_CODE=$?
    log "❌ Test failed: $test_name (exit code: $TEST_EXIT_CODE)"
    log "Test output:"
    cat test_output.log
    ((FAILED++))
    FAILED_TESTS+=("$test_name")
  fi
  
  # Go back to script directory and clean up
  cd "$SCRIPT_DIR" || exit 1
  rm -rf "$TEST_TMP_DIR"
  
  echo "-----------------------------------"
done

# Print summary
log "==== Test Summary ===="
log "  Total: ${#TEST_CATEGORIES[@]}"
log "  Passed: $PASSED"
log "  Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
  log "Failed tests:"
  for failed in "${FAILED_TESTS[@]}"; do
    log "  - $failed"
  done
  exit 1
fi

log "All individual tests passed!"