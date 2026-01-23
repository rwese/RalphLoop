#!/usr/bin/env bash
# RalphLoop Test Common Utilities
# Shared functions and utilities for all test scripts

set -e -u -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Test counters (global)
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RALPH_SCRIPT="$PROJECT_ROOT/bin/ralph"
RALPH_LIB="$PROJECT_ROOT/lib.sh"
MOCK_OPENCODE="$PROJECT_ROOT/backends/mock/bin/mock-opencode"

# Print functions
print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
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

print_debug() {
    if [ "${VERBOSE:-false}" = true ]; then
        echo -e "${MAGENTA}[DEBUG]${NC} $1"
    fi
}

# ============================================================================
# Assertion Functions
# ============================================================================

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

assert_empty() {
    local value="$1"
    local description="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -z "$value" ]; then
        print_pass "$description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_fail "$description (expected empty, got: $value)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local description="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -n "$value" ]; then
        print_pass "$description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_fail "$description (expected non-empty value)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_equal() {
    local expected="$1"
    local actual="$2"
    local description="$3"
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$expected" = "$actual" ]; then
        print_pass "$description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_fail "$description (expected: $expected, got: $actual)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# ============================================================================
# Test Environment Setup
# ============================================================================

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
    cat > "$TEST_PROJECT_ROOT/prompt.md" << 'EOF'
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
    echo "# RalphLoop Test Progress" > "$TEST_PROJECT_ROOT/progress.md"

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

# ============================================================================
# Mock Backend Helpers
# ============================================================================

run_with_mock_backend() {
    local iterations="${1:-1}"
    local response="${2:-complete}"
    local delay="${3:-0}"
    local exit_code="${4:-0}"

    RALPH_MOCK_RESPONSE="$response" \
    RALPH_MOCK_DELAY="$delay" \
    RALPH_MOCK_EXIT_CODE="$exit_code" \
    PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    "$RALPH_SCRIPT" "$iterations" 2>&1
}

run_mock_command() {
    local command="$1"
    shift
    RALPH_MOCK_RESPONSE="$MOCK_RESPONSE" \
    RALPH_MOCK_DELAY="$MOCK_DELAY" \
    RALPH_MOCK_EXIT_CODE="$MOCK_EXIT_CODE" \
    "$MOCK_OPENCODE" "$command" "$@"
}

# ============================================================================
# Output Capture Helpers
# ============================================================================

capture_output() {
    local cmd="$1"
    local output
    output=$(eval "$cmd" 2>&1) || true
    echo "$output"
}

capture_exit_code() {
    local cmd="$1"
    eval "$cmd" > /dev/null 2>&1
    echo $?
}

# ============================================================================
# File Helpers
# ============================================================================

create_temp_file() {
    local content="${1:-}"
    local tmp_file=$(mktemp)
    if [ -n "$content" ]; then
        echo "$content" > "$tmp_file"
    fi
    echo "$tmp_file"
}

create_temp_dir() {
    mktemp -d
}

read_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cat "$file"
    fi
}

write_file() {
    local file="$1"
    local content="$2"
    mkdir -p "$(dirname "$file")"
    echo "$content" > "$file"
}

# ============================================================================
# Git Helpers
# ============================================================================

init_git_repo() {
    local dir="$1"
    mkdir -p "$dir"
    cd "$dir"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
}

commit_file() {
    local file="$1"
    local message="${2:-Update}"
    git add "$file"
    git commit --quiet -m "$message"
}

# ============================================================================
# Validation Helpers
# ============================================================================

extract_validation_status() {
    local output="$1"
    echo "$output" | grep -o '<validation_status>[^<]*</validation_status>' | sed 's/<[^>]*>//g' | tr -d ' '
}

extract_promise() {
    local output="$1"
    if echo "$output" | grep -q '<promise>COMPLETE</promise>'; then
        echo "complete"
    else
        echo "incomplete"
    fi
}

# ============================================================================
# Test Summary
# ============================================================================

print_test_summary() {
    print_header "Test Summary"
    echo ""
    echo -e "  Tests Run:    ${BLUE}$TESTS_RUN${NC}"
    echo -e "  Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "  Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo -e "  Tests Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
    echo ""

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}❌ Some tests failed!${NC}"
        return 1
    else
        echo -e "${GREEN}✅ All tests passed!${NC}"
        return 0
    fi
}
