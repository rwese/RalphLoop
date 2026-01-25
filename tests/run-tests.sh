#!/usr/bin/env bash

# tests/run-tests.sh - RalphLoop Test Runner
#
# Purpose:
#   Comprehensive test suite runner for RalphLoop autonomous development system.
#   Executes unit, integration, end-to-end, and mock backend tests with
#   flexible filtering and output options.
#
# Key Features:
#   - Run all tests or specific test categories
#   - Unit tests for individual modules
#   - Integration tests for module interactions
#   - End-to-end tests for complete workflows
#   - Mock backend tests for testing without API calls
#   - Verbose and CI modes for different use cases
#   - Color-coded output for easy reading
#
# Usage:
#   ./tests/run-tests.sh [options]
#
# Options:
#   --unit         Run unit tests only
#   --integration  Run integration tests only
#   --e2e          Run end-to-end tests only
#   --mock         Run mock backend tests only
#   --all          Run all tests (default)
#   --verbose      Show detailed output
#   --quick        Run quick smoke tests only
#   --ci           Run tests in CI mode (no colors, exit on failure)
#   --help         Show this help message
#
# Test Categories:
#   unit       Tests for individual functions and modules
#   integration Tests for module interactions and workflows
#   e2e        Tests for complete end-to-end workflows
#   mock       Tests using mock backend without real API calls
#
# Examples:
#   # Run all tests
#   ./tests/run-tests.sh --all
#
#   # Run only unit tests
#   ./tests/run-tests.sh --unit
#
#   # Run tests with verbose output
#   ./tests/run-tests.sh --verbose
#
#   # Run in CI mode (no colors, exit on first failure)
#   ./tests/run-tests.sh --ci
#
#   # Quick smoke tests
#   ./tests/run-tests.sh --quick
#
# Exit Codes:
#   0   All tests passed
#   1   One or more tests failed
#   2   Invalid arguments or missing dependencies
#
# Related Files:
#   tests/common.sh: Shared test utilities and functions
#   tests/unit/: Unit test scripts
#   tests/integration/: Integration test scripts
#   tests/e2e/: End-to-end test scripts
#   tests/mock/: Mock backend tests
#   backends/mock/bin/mock-opencode: Mock backend for testing

set -e -u -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Options
VERBOSE=false
CI_MODE=false
TEST_TYPE="all"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RALPH_SCRIPT="$PROJECT_ROOT/ralph"
MOCK_OPENCODE="$PROJECT_ROOT/backends/mock/bin/mock-opencode"

# Source common utilities
source "$SCRIPT_DIR/common.sh"

# Print functions
print_header() {
  echo ""
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}========================================${NC}"
}

print_test() {
  echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
}

print_fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
}

print_skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
}

print_info() {
  echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Test assertion functions
assert_file_exists() {
  local file="$1"
  local description="$2"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ -f "$file" ]; then
    print_pass "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    print_fail "$description (file not found: $file)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  local description="$2"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ -d "$dir" ]; then
    print_pass "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    print_fail "$description (directory not found: $dir)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_contains() {
  local content="$1"
  local pattern="$2"
  local description="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$content" | grep -q "$pattern"; then
    print_pass "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    print_fail "$description (pattern not found: $pattern)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_not_contains() {
  local content="$1"
  local pattern="$2"
  local description="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if ! echo "$content" | grep -q "$pattern"; then
    print_pass "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    print_fail "$description (pattern found: $pattern)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local description="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$expected" = "$actual" ]; then
    print_pass "$description (exit code: $actual)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    print_fail "$description (expected: $expected, got: $actual)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_success() {
  local exit_code="$1"
  local description="$2"
  assert_exit_code "0" "$exit_code" "$description"
}

assert_failure() {
  local exit_code="$1"
  local description="$2"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$exit_code" != "0" ]; then
    print_pass "$description (exit code: $exit_code)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    print_fail "$description (expected non-zero exit code, got: $exit_code)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_match() {
  local value="$1"
  local pattern="$2"
  local description="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$value" =~ $pattern ]]; then
    print_pass "$description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    print_fail "$description (value: $value, pattern: $pattern)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Setup and teardown
setup_test_environment() {
  print_info "Setting up test environment..."

  # Create temporary test directory
  export TEST_TMP_DIR=$(mktemp -d)
  export TEST_PROJECT_ROOT="$TEST_TMP_DIR/test-project"

  # Copy RalphLoop files
  mkdir -p "$TEST_PROJECT_ROOT"
  cp -r "$PROJECT_ROOT"/* "$TEST_PROJECT_ROOT/" 2>/dev/null || true

  # Setup mock backend
  chmod +x "$TEST_PROJECT_ROOT/backends/mock/bin/mock-opencode" 2>/dev/null || true

  # Create test prompt
  cat >"$TEST_PROJECT_ROOT/prompt.md" <<'EOF'
# Test Project Goal

Create a simple test project to verify RalphLoop functionality.

## Acceptance Criteria

1. Create a README.md file
2. Initialize git repository
3. Create a simple example file

## Tasks

Complete the above requirements.
EOF

  # Create empty progress file
  echo "# RalphLoop Test Progress" >"$TEST_PROJECT_ROOT/progress.md"

  print_info "Test environment created at: $TEST_TMP_DIR"
}

teardown_test_environment() {
  print_info "Cleaning up test environment..."

  # Remove temporary directory
  if [ -n "$TEST_TMP_DIR" ] && [ -d "$TEST_TMP_DIR" ]; then
    rm -rf "$TEST_TMP_DIR"
    print_info "Test environment cleaned up"
  fi
}

# Cleanup on exit
trap 'teardown_test_environment' EXIT

# Show usage
show_help() {
  head -20 "$0" | tail -15
  echo ""
  echo "Test Categories:"
  echo "  --unit       Test individual functions and utilities"
  echo "  --integration Test backend integrations and configurations"
  echo "  --e2e        Test complete end-to-end workflows"
  echo "  --mock       Test mock backend functionality"
  echo "  --all        Run all tests (default)"
  echo "  --quick      Run smoke tests only"
  echo "  --ci         Run in CI mode (non-interactive)"
}

# Parse command line arguments
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    --unit)
      TEST_TYPE="unit"
      shift
      ;;
    --integration)
      TEST_TYPE="integration"
      shift
      ;;
    --e2e)
      TEST_TYPE="e2e"
      shift
      ;;
    --mock)
      TEST_TYPE="mock"
      shift
      ;;
    --all)
      TEST_TYPE="all"
      shift
      ;;
    --quick)
      TEST_TYPE="quick"
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --ci)
      CI_MODE=true
      shift
      ;;
    --help | -h)
      show_help
      exit 0
      ;;
    *)
      print_error "Unknown option: $1"
      show_help
      exit 1
      ;;
    esac
  done
}

# Print summary
print_summary() {
  print_header "Test Summary"
  echo ""
  echo -e "  Tests Run:    ${BLUE}$TESTS_RUN${NC}"
  echo -e "  Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "  Tests Failed: ${RED}$TESTS_FAILED${NC}"
  echo -e "  Tests Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
  echo ""

  if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}❌ Some tests failed!${NC}"
    if [ "$CI_MODE" = true ]; then
      exit 1
    fi
  else
    echo -e "${GREEN}✅ All tests passed!${NC}"
  fi
}

# Quick test runner
run_quick_tests() {
  print_header "Quick Tests"

  # Source test files
  source "$SCRIPT_DIR/unit/test-validation.sh"
  source "$SCRIPT_DIR/mock/test-mock-backend.sh"

  # Run quick validation tests
  test_validation_status_extraction_complete
  test_promise_extraction_complete
  test_acceptance_criteria_parsing
  test_iteration_output

  # Run quick mock tests
  test_mock_basic_run
  test_scenario_comprehensive
}

# All tests runner
run_all_tests() {
  print_header "All Tests"

  # Unit tests
  source "$SCRIPT_DIR/unit/test-functions.sh"
  source "$SCRIPT_DIR/unit/test-validation.sh"
  run_unit_tests

  # Reset counters for integration tests
  TESTS_RUN=0
  TESTS_PASSED=0
  TESTS_FAILED=0

  # Integration tests
  source "$SCRIPT_DIR/integration/test-backends.sh"
  run_integration_tests

  # Reset counters for E2E tests
  TESTS_RUN=0
  TESTS_PASSED=0
  TESTS_FAILED=0

  # E2E tests
  source "$SCRIPT_DIR/e2e/test-workflows.sh"
  run_e2e_tests

  # Reset counters for mock tests
  TESTS_RUN=0
  TESTS_PASSED=0
  TESTS_FAILED=0

  # Mock tests
  source "$SCRIPT_DIR/mock/test-mock-backend.sh"
  run_mock_tests
}

# Main function
main() {
  parse_args "$@"

  print_header "RalphLoop Test Suite"
  echo "  Test Type:    $TEST_TYPE"
  echo "  CI Mode:      $CI_MODE"
  echo "  Project Root: $PROJECT_ROOT"
  echo "  Ralph Script: $RALPH_SCRIPT"

  # Setup test environment
  setup_test_environment

  # Run tests based on type
  case "$TEST_TYPE" in
  unit)
    source "$SCRIPT_DIR/unit/test-functions.sh"
    source "$SCRIPT_DIR/unit/test-validation.sh"
    run_unit_tests
    ;;
  integration)
    source "$SCRIPT_DIR/integration/test-backends.sh"
    run_integration_tests
    ;;
  e2e)
    source "$SCRIPT_DIR/e2e/test-workflows.sh"
    run_e2e_tests
    ;;
  mock)
    source "$SCRIPT_DIR/mock/test-mock-backend.sh"
    run_mock_tests
    ;;
  quick)
    source "$SCRIPT_DIR/unit/test-functions.sh"
    source "$SCRIPT_DIR/mock/test-mock-backend.sh"
    run_quick_tests
    ;;
  all)
    source "$SCRIPT_DIR/unit/test-functions.sh"
    source "$SCRIPT_DIR/unit/test-validation.sh"
    source "$SCRIPT_DIR/integration/test-backends.sh"
    source "$SCRIPT_DIR/e2e/test-workflows.sh"
    source "$SCRIPT_DIR/mock/test-mock-backend.sh"
    run_all_tests
    ;;
  esac

  # Print summary
  print_summary

  # Exit with appropriate code
  if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
  fi
  exit 0
}

# Run main
main "$@"
