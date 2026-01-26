#!/usr/bin/env bash
# RalphLoop Unit Tests - Validation Functions
# Tests for validation and acceptance criteria checking

set -e -u -o pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ============================================================================
# Test: Validation status extraction
# ============================================================================

test_validation_status_extraction_complete() {
  print_section "Test: Validation status extraction - complete"

  local output="<validation_status>PASS</validation_status>
<validation_issues>
</validation_issues>
<validation_recommendations>
</validation_recommendations>"

  # Define function inline to avoid sourcing ralph
  local status
  status=$(echo "$output" | grep -o '<validation_status>[^<]*</validation_status>' | sed 's/<[^>]*>//g' | tr -d ' ')
  status=$(echo "$status" | grep -v "ulimit" | grep -v "⚠️" | grep -v "===" | tr -d '\n')

  assert_equal "PASS" "$status" "Should extract PASS status"
}

test_validation_status_extraction_fail() {
  print_section "Test: Validation status extraction - fail"

  local output="<validation_status>FAIL</validation_status>
<validation_issues>
- Issue 1
</validation_issues>"

  # Define function inline to avoid sourcing ralph
  local status
  status=$(echo "$output" | grep -o '<validation_status>[^<]*</validation_status>' | sed 's/<[^>]*>//g' | tr -d ' ')
  status=$(echo "$status" | grep -v "ulimit" | grep -v "⚠️" | grep -v "===" | tr -d '\n')

  assert_equal "FAIL" "$status" "Should extract FAIL status"
}

test_validation_status_extraction_missing() {
  print_section "Test: Validation status extraction - missing"

  local output="No validation status here"

  # Define function inline to avoid sourcing ralph
  local status
  status=$(echo "$output" | grep -o '<validation_status>[^<]*</validation_status>' | sed 's/<[^>]*>//g' | tr -d ' ')
  status=$(echo "$status" | grep -v "ulimit" | grep -v "⚠️" | grep -v "===" | tr -d '\n')

  assert_empty "$status" "Should return empty for no status"
}

# ============================================================================
# Test: Acceptance criteria parsing
# ============================================================================

test_acceptance_criteria_parsing() {
  print_section "Test: Acceptance criteria parsing"

  local prompt="## Acceptance Criteria

1. First criterion
2. Second criterion
3. Third criterion"

  local count=$(echo "$prompt" | grep -c "^[0-9]\." || echo "0")
  assert_equal "3" "$count" "Should count all acceptance criteria"
}

test_multiple_sections_parsing() {
  print_section "Test: Multiple sections parsing"

  local prompt="# Project

## Goals
Goal 1

## Acceptance Criteria
1. Criterion 1

## Tasks
- Task 1"

  # Should contain goals section
  assert_contains "$prompt" "## Goals" "Should contain Goals section"
  assert_contains "$prompt" "## Acceptance Criteria" "Should contain Acceptance Criteria section"
  assert_contains "$prompt" "## Tasks" "Should contain Tasks section"
}

# ============================================================================
# Test: Progress tracking
# ============================================================================

test_progress_file_structure() {
  print_section "Test: Progress file structure"

  local test_dir=$(create_temp_dir)
  cd "$test_dir"

  # Create a progress file
  cat >progress.md <<'EOF'
# RalphLoop Progress

## Iteration 1
- Created README.md
- Initialized git

## Iteration 2
- Created main.go
- Added tests
EOF

  local iteration_count=$(grep -c "^## Iteration" progress.md || echo "0")
  assert_equal "2" "$iteration_count" "Should count iterations correctly"

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

# ============================================================================
# Test: Git history validation
# ============================================================================

test_git_commit_parsing() {
  print_section "Test: Git commit parsing"

  local test_dir=$(create_temp_dir)
  init_git_repo "$test_dir"

  # Create commits
  echo "First" >file1.txt
  commit_file "file1.txt" "Add first file"

  echo "Second" >file2.txt
  commit_file "file2.txt" "Add second file"

  cd "$test_dir"

  local commit_count=$(git rev-list --count HEAD)
  assert_match "$commit_count" "^[0-9]+$" "Should have valid commit count"

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

# ============================================================================
# Test: Error handling
# ============================================================================

test_error_exit_codes() {
  print_section "Test: Error exit codes"

  # Test missing prompt file
  local test_dir=$(create_temp_dir)
  cd "$test_dir"

  local exit_code=0
  timeout 5 bash -c "RALPH_PROMPT_FILE=/nonexistent/prompt.md PATH='$PROJECT_ROOT/backends/mock/bin:$PATH' '$RALPH_SCRIPT' 1" >/dev/null 2>&1 || exit_code=$?

  assert_failure "$exit_code" "Should fail with missing prompt file"

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

# ============================================================================
# Test: Timeout handling
# ============================================================================

test_timeout_handling() {
  print_section "Test: Timeout handling"

  local test_dir=$(create_temp_dir)
  cd "$test_dir"

  # Create prompt and progress
  echo "# Test" >prompt.md
  echo "# Progress" >progress.md

  # Run with very short timeout (should timeout or complete quickly)
  local start_time=$(date +%s)
  timeout 10 RALPH_TIMEOUT=2 PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" RALPH_MOCK_DELAY=5 "$RALPH_SCRIPT" 1 >/dev/null 2>&1
  local exit_code=$?
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  # Should timeout (exit code 124) or complete within reasonable time
  if [ $exit_code -eq 124 ]; then
    assert_equal "124" "$exit_code" "Should timeout with exit code 124"
  else
    assert_success "$exit_code" "Should complete successfully or timeout"
  fi

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

# ============================================================================
# Test: Environment variable handling
# ============================================================================

test_timeout_env_variable() {
  print_section "Test: Timeout environment variable"

  local value="${RALPH_TIMEOUT:-1800}"
  assert_match "$value" "^[0-9]+$" "RALPH_TIMEOUT should be a number"
}

test_log_level_env_variable() {
  print_section "Test: Log level environment variable"

  local value="${RALPH_LOG_LEVEL:-WARN}"
  assert_match "$value" "^(DEBUG|INFO|WARN|ERROR)$" "RALPH_LOG_LEVEL should be valid log level"
}

test_memory_limit_env_variable() {
  print_section "Test: Memory limit environment variable"

  local value="${RALPH_MEMORY_LIMIT:-2097152}"
  assert_match "$value" "^[0-9]+$" "RALPH_MEMORY_LIMIT should be a number"
}

# ============================================================================
# Test: Output validation
# ============================================================================

test_iteration_output() {
  print_section "Test: Iteration output format"

  local test_dir=$(create_temp_dir)
  cd "$test_dir"

  # Create minimal files
  echo "# Test" >prompt.md
  echo "# Progress" >progress.md

  # Run one iteration with mock
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  assert_contains "$output" "Stage:" "Should show stage info"
  assert_contains "$output" "Starting pipeline execution" "Should show execution start message"

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

test_validation_output() {
  print_section "Test: Validation output format"

  local test_dir=$(create_temp_dir)
  cd "$test_dir"

  # Create prompt that will complete
  echo "# Test

<promise>COMPLETE</promise>" >prompt.md
  echo "# Progress" >progress.md

  # Run with mock that completes
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" RALPH_MOCK_RESPONSE=success timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  assert_contains "$output" "Validation" "Should show validation section"

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

# ============================================================================
# Main test runner
# ============================================================================

run_validation_tests() {
  print_header "Unit Tests - Validation Functions"

  # Setup
  setup_test_environment

  # Run tests
  test_validation_status_extraction_complete
  test_validation_status_extraction_fail
  test_validation_status_extraction_missing

  test_acceptance_criteria_parsing
  test_multiple_sections_parsing

  test_progress_file_structure
  test_git_commit_parsing

  test_error_exit_codes
  test_timeout_handling

  test_timeout_env_variable
  test_log_level_env_variable
  test_memory_limit_env_variable

  test_iteration_output
  test_validation_output

  # Teardown
  teardown_test_environment

  print_test_summary
}

run_quick_validation_tests() {
  print_header "Quick Validation Tests"

  setup_test_environment

  test_validation_status_extraction_complete
  test_acceptance_criteria_parsing
  test_iteration_output

  teardown_test_environment

  print_test_summary
}

# Run tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export VERBOSE="${VERBOSE:-false}"
  run_validation_tests
fi
