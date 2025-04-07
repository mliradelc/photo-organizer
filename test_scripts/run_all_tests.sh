#!/bin/bash
#
# Run all test cases for Photo Organizer
#

set -e

# Find the repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Setup test images if they don't exist
if [[ ! -f "test_cases/exif_test/input/canon_2018.jpg" ]]; then
  log "Setting up test images..."
  bash "$SCRIPT_DIR/setup_test_images.sh"
fi

# Get all test case directories
TEST_CASES=()
for test_dir in test_cases/*/; do
  # Extract just the name of the test
  test_name=$(basename "$test_dir")
  TEST_CASES+=("$test_name")
done

log "Found ${#TEST_CASES[@]} test cases to run"

# Track test results
PASSED=0
FAILED=0
FAILED_TESTS=()

# Run each test case
for test in "${TEST_CASES[@]}"; do
  log "Running test: $test"
  
  if bash "$SCRIPT_DIR/test_single.sh" "$test"; then
    log "✅ Test passed: $test"
    ((PASSED++))
  else
    log "❌ Test failed: $test"
    ((FAILED++))
    FAILED_TESTS+=("$test")
  fi
  
  echo "-----------------------------------"
done

# Print summary
log "Test summary:"
log "  Total: ${#TEST_CASES[@]}"
log "  Passed: $PASSED"
log "  Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
  log "Failed tests:"
  for failed in "${FAILED_TESTS[@]}"; do
    log "  - $failed"
  done
  exit 1
fi

log "All tests passed!"