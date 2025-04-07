#!/bin/bash
#
# Run individual test cases for camera tests
#

set -e

# Find the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Get all individual test scripts
TEST_SCRIPTS=()
for test_script in individual_tests/*.sh; do
  # Extract just the name of the test
  test_name=$(basename "$test_script" .sh)
  TEST_SCRIPTS+=("$test_name")
done

log "Found ${#TEST_SCRIPTS[@]} individual test scripts to run"

# Track test results
PASSED=0
FAILED=0
FAILED_TESTS=()

# Check if a test directory has been provided by the parent script
if [[ -z "$TEST_TMP_DIR" ]]; then
  # Create a clean test environment if not provided
  TEST_TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TEST_TMP_DIR"' EXIT
  
  # Copy test data to temporary directory
  cp -r "$SCRIPT_DIR/input" "$TEST_TMP_DIR/"
fi

# Run each test case
for test in "${TEST_SCRIPTS[@]}"; do
  log "Running test: $test"
  
  # Make a separate subdirectory for each test to avoid file conflicts
  TEST_SUBDIR="$TEST_TMP_DIR/$test"
  mkdir -p "$TEST_SUBDIR"
  
  # Copy test data to the test-specific subdirectory
  cp -r "$TEST_TMP_DIR/input" "$TEST_SUBDIR/"
  
  # Run the test
  cd "$TEST_SUBDIR"
  log "Running test script: $SCRIPT_DIR/individual_tests/$test.sh"
  
  # Create a temporary file to capture output
  TEST_OUTPUT_FILE="$(mktemp)"
  
  # shellcheck disable=SC1090
  if source "$SCRIPT_DIR/individual_tests/$test.sh" > "$TEST_OUTPUT_FILE" 2>&1; then
    log "✅ Test passed: $test"
    ((PASSED++))
  else
    TEST_EXIT_CODE=$?
    log "❌ Test failed: $test (exit code: $TEST_EXIT_CODE)"
    log "Test output:"
    cat "$TEST_OUTPUT_FILE"
    ((FAILED++))
    FAILED_TESTS+=("$test")
  fi
  
  # Clean up the temporary file
  rm -f "$TEST_OUTPUT_FILE"
  
  # Go back to original directory 
  cd "$SCRIPT_DIR"
  
  # We'll clean up the entire test directory at the end, not after each test
  
  echo "-----------------------------------"
done

# Print summary
log "==== Test Summary ===="
log "  Total: ${#TEST_SCRIPTS[@]}"
log "  Passed: $PASSED"
log "  Failed: $FAILED"

# Only clean up if we created the test directory ourselves
if [[ -z "$TEST_TMP_DIR_EXPORTED" ]]; then
  log "Cleaning up test directory: $TEST_TMP_DIR"
  rm -rf "$TEST_TMP_DIR"
  trap - EXIT
fi

if [[ $FAILED -gt 0 ]]; then
  log "Failed tests:"
  for failed in "${FAILED_TESTS[@]}"; do
    log "  - $failed"
  done
  # Write to a log file as well
  LOG_FILE="$SCRIPT_DIR/test_failures.log"
  {
    echo "==== Test Failures ===="
    echo "Date: $(date)"
    echo "Failed tests: ${FAILED_TESTS[*]}"
    echo ""
  } > "$LOG_FILE"
  log "Detailed failure information has been written to $LOG_FILE"
  exit 1
fi

log "All individual tests passed!"