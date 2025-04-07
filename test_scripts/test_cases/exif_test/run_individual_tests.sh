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
  
  # Create a clean test environment
  TEST_TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TEST_TMP_DIR"' EXIT
  
  # Copy test data to temporary directory
  cp -r "$SCRIPT_DIR/input" "$TEST_TMP_DIR/"
  
  # Run the test
  cd "$TEST_TMP_DIR"
  # shellcheck disable=SC1090
  if source "$SCRIPT_DIR/individual_tests/$test.sh"; then
    log "✅ Test passed: $test"
    ((PASSED++))
  else
    log "❌ Test failed: $test"
    ((FAILED++))
    FAILED_TESTS+=("$test")
  fi
  
  # Go back to original directory and cleanup
  cd "$SCRIPT_DIR"
  rm -rf "$TEST_TMP_DIR"
  trap - EXIT
  
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