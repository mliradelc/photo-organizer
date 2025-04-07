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

log "Found ${#TEST_CASES[@]} test case groups to run"

# Track test results
PASSED=0
FAILED=0
FAILED_TESTS=()

# Run each test case group
for test in "${TEST_CASES[@]}"; do
  log "Running test group: $test"
  
  # Check if individual test runner exists
  INDIVIDUAL_RUNNER="$SCRIPT_DIR/test_cases/$test/run_individual_tests.sh"
  if [[ -f "$INDIVIDUAL_RUNNER" ]]; then
    log "Using individual test runner for $test"
    
    # Create a log file to capture output
    RUNNER_LOG="$SCRIPT_DIR/test_cases/$test/runner.log"
    
    # Create a clean test environment for each test group
    TEST_TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEST_TMP_DIR"' EXIT
    
    # Copy test data to temporary directory
    cp -r "$SCRIPT_DIR/test_cases/$test/input" "$TEST_TMP_DIR/"
    
    # Run the individual tests with the clean environment
    # Export the TEST_TMP_DIR so it can be used by the runner script
    export TEST_TMP_DIR
    export TEST_TMP_DIR_EXPORTED=1
    
    if bash "$INDIVIDUAL_RUNNER" > "$RUNNER_LOG" 2>&1; then
      log "✅ All tests in group passed: $test"
      ((PASSED++))
    else
      RUNNER_EXIT_CODE=$?
      log "❌ Some tests in group failed: $test (exit code: $RUNNER_EXIT_CODE)"
      log "Last 20 lines of log output:"
      tail -n 20 "$RUNNER_LOG" || echo "Could not read log file"
      ((FAILED++))
      FAILED_TESTS+=("$test")
    fi
    
    # Clean up the test directory
    rm -rf "$TEST_TMP_DIR"
    trap - EXIT
    
    log "Full logs available at: $RUNNER_LOG"
  else
    # Fallback to the original single test runner
    log "Using single test runner for $test"
    
    if bash "$SCRIPT_DIR/test_single.sh" "$test"; then
      log "✅ Test passed: $test"
      ((PASSED++))
    else
      log "❌ Test failed: $test"
      ((FAILED++))
      FAILED_TESTS+=("$test")
    fi
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