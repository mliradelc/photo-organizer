#!/bin/bash
#
# Run individual test cases for EXIF tests
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

# Run each test case
for test in "${TEST_SCRIPTS[@]}"; do
  log "Running test: $test"
  
  # Create a temporary file to capture output
  TEST_OUTPUT_FILE="$(mktemp)"
  
  # Run the test directly with more verbosity
  log "Executing: $SCRIPT_DIR/individual_tests/$test.sh"
  
  # Use 'set -x' to show commands as they execute and capture all output
  if bash -x "$SCRIPT_DIR/individual_tests/$test.sh" > "$TEST_OUTPUT_FILE" 2>&1; then
    log "✅ Test passed: $test"
    ((PASSED++))
  else
    TEST_EXIT_CODE=$?
    log "❌ Test failed: $test (exit code: $TEST_EXIT_CODE)"
    log "=== Full test output: ==="
    cat "$TEST_OUTPUT_FILE"
    log "=== End of test output ==="
    ((FAILED++))
    FAILED_TESTS+=("$test")
  fi
  
  # Clean up the temporary file
  rm -f "$TEST_OUTPUT_FILE"
  
  echo "-----------------------------------"
done

# Print summary
log "Test summary:"
log "  Total: ${#TEST_SCRIPTS[@]}"
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