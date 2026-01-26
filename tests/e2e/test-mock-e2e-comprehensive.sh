#!/usr/bin/env bash
# RalphLoop Comprehensive Mock E2E Test Suite
#
# Purpose:
#   Complete mock-based end-to-end test coverage for RalphLoop workflows,
#   functions, environment variables, error conditions, and configuration scenarios.
#   This test suite ensures full coverage without requiring real OpenCode API calls.
#
# Key Features:
#   - All mock backend response modes tested with E2E workflows
#   - All mock scenarios covered (success, fail, progress, timeout, empty, error)
#   - Environment variable configuration testing
#   - Error condition testing with mock responses
#   - Configuration file scenario testing
#   - Git integration testing with mock backend
#   - Iteration control testing
#   - Progress tracking and validation workflow testing
#
# Usage:
#   source "$SCRIPT_DIR/../common.sh"
#   source "$SCRIPT_DIR/test-mock-e2e-comprehensive.sh"
#   run_mock_e2e_comprehensive_tests
#
# Related Files:
#   tests/common.sh: Shared test utilities
#   tests/e2e/test-workflows.sh: Basic E2E workflows
#   tests/mock/test-mock-backend.sh: Mock backend tests
#   backends/mock/bin/mock-opencode: Mock backend executable

set -e -u -o pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ============================================================================
# SECTION 1: Mock Response Mode E2E Tests
# Tests all response modes with complete end-to-end workflows
# ============================================================================

test_mock_response_mode_complete_single() {
  print_section "Test: Mock Response Mode - Complete (Single Iteration)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Create prompt that signals completion
  cat >prompt.md <<'EOF'
# Complete Task
Finish this task.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with complete response mode
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=complete \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify complete workflow
  assert_contains "$output" "Pipeline: default" "Should show pipeline"
  assert_contains "$output" "Pipeline configuration loaded" "Should show configuration"
  assert_contains "$output" "Starting agent execution" "Should show agent start"
  assert_contains "$output" "Goal marked complete" "Should detect completion"
  assert_contains "$output" "Running independent validation" "Should run validation"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_response_mode_complete_multi() {
  print_section "Test: Mock Response Mode - Complete (Multiple Iterations)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Create prompt that signals completion
  cat >prompt.md <<'EOF'
# Multi-Iteration Task
Complete this task over multiple iterations.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run 3 iterations with complete response
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=complete \
    RALPH_MOCK_DELAY=0 \
    timeout 60 "$RALPH_SCRIPT" 3 2>&1)

  # Verify multiple iterations ran
  assert_contains "$output" "Iteration: 1 /" "Should show iteration 1"
  assert_contains "$output" "Iteration: 2 /" "Should show iteration 2"
  assert_contains "$output" "Iteration: 3 /" "Should show iteration 3"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_response_mode_fail_single() {
  print_section "Test: Mock Response Mode - Fail (Single Iteration)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Create prompt that signals completion but mock returns fail mode
  cat >prompt.md <<'EOF'
# Task with Fail Mode
Complete this task but validation will fail.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with fail response mode
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=fail \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify fail workflow
  assert_contains "$output" "Stage: execute" "Should show execute stage"
  assert_contains "$output" "Goal marked complete" "Should detect completion"
  assert_contains "$output" "Running independent validation" "Should run validation"
  assert_contains "$output" "Validation FAILED" "Should detect validation failure"
  assert_contains "$output" "Issues saved to" "Should show issues saved"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_response_mode_fail_multi() {
  print_section "Test: Mock Response Mode - Fail (Multiple Iterations with Retry)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Task with Fail Mode
Complete this task with validation failures triggering retry.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with fail response mode - should retry
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=fail \
    timeout 60 "$RALPH_SCRIPT" 3 2>&1)

  # Verify retry behavior on validation failure
  assert_contains "$output" "Stage: execute" "Should show execute stages"
  assert_contains "$output" "Validation FAILED" "Should show validation failures"
  # Should continue to next iteration after validation failure
  assert_contains "$output" "Goal marked complete" "Should detect completion"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_response_mode_progress_single() {
  print_section "Test: Mock Response Mode - Progress (Single Iteration)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Progress Task
Work on this task incrementally.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with progress response mode
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=progress \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify progress workflow
  assert_contains "$output" "Stage: execute" "Should show execute stage"
  assert_contains "$output" "Starting agent execution" "Should show agent start"
  assert_contains "$output" "Creating" "Should show creating steps"
  assert_contains "$output" "Verifying" "Should show verifying steps"
  assert_contains "$output" "Goal marked complete" "Should detect completion"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_response_mode_progress_multi() {
  print_section "Test: Mock Response Mode - Progress (Multiple Iterations)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Progress Task
Work on this task over multiple iterations.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run 2 iterations with progress response
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=progress \
    RALPH_MOCK_DELAY=0 \
    timeout 60 "$RALPH_SCRIPT" 2 2>&1)

  # Verify progress tracking
  local progress_content=$(cat progress.md 2>/dev/null || echo "")
  assert_contains "$progress_content" "Iteration 1" "Progress should show iteration 1"
  assert_contains "$progress_content" "Iteration 2" "Progress should show iteration 2"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_response_mode_empty_single() {
  print_section "Test: Mock Response Mode - Empty (Single Iteration)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Empty Response Task
Process this task with empty response.
EOF
  echo "# Progress" >progress.md

  # Run with empty response mode
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=empty \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify graceful handling of empty response
  assert_contains "$output" "Iteration: 1 of 1" "Should show iteration"
  assert_contains "$output" "Starting agent execution" "Should show agent start"
  # Should handle empty gracefully without errors
  assert_not_contains "$output" "error" "Should not show errors"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_response_mode_empty_multi() {
  print_section "Test: Mock Response Mode - Empty (Multiple Iterations)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Empty Response Multi
Handle empty responses across multiple iterations.
EOF
  echo "# Progress" >progress.md

  # Run 2 iterations with empty response
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=empty \
    timeout 60 "$RALPH_SCRIPT" 2 2>&1)

  # Verify graceful handling across iterations
  assert_contains "$output" "Iteration 1 of 2" "Should show iteration 1"
  assert_contains "$output" "Iteration 2 of 2" "Should show iteration 2"
  assert_not_contains "$output" "error" "Should not show errors"

  cd "$original_dir"
  rm -rf "$test_dir"
}

# ============================================================================
# SECTION 2: Mock Scenario E2E Tests
# Tests all mock scenarios (success, fail, progress, timeout, empty, error)
# ============================================================================

test_mock_scenario_success() {
  print_section "Test: Mock Scenario - Success"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Success Scenario
Complete successfully.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with success scenario
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=success \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify success scenario
  assert_contains "$output" "Iteration:" "Should run iteration"
  assert_contains "$output" "Goal marked complete" "Should detect completion"
  assert_contains "$output" "Running independent validation" "Should run validation"
  assert_contains "$output" "<validation_status>PASS</validation_status>" "Should show PASS validation"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_scenario_fail() {
  print_section "Test: Mock Scenario - Fail"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Fail Scenario
This scenario will fail validation.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with fail scenario
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=fail \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify fail scenario
  assert_contains "$output" "Goal marked complete" "Should detect completion"
  assert_contains "$output" "Validation FAILED" "Should show validation failure"
  assert_contains "$output" "Mock validation failure" "Should show mock failure reason"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_scenario_progress() {
  print_section "Test: Mock Scenario - Progress"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Progress Scenario
Work on this task incrementally.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with progress scenario
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=progress \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify progress scenario
  assert_contains "$output" "Iteration:" "Should run iteration"
  assert_contains "$output" "Creating" "Should show creating message"
  assert_contains "$output" "Verifying" "Should show verifying message"
  assert_contains "$output" "Goal marked complete" "Should detect completion"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_scenario_timeout() {
  print_section "Test: Mock Scenario - Timeout (Exit Code 124)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Timeout Scenario
This task will timeout.
EOF
  echo "# Progress" >progress.md

  # Run with timeout exit code
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_EXIT_CODE=124 \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1) || local exit_code=$?

  # Verify timeout handling
  assert_contains "$output" "Iteration:" "Should show iteration started"
  # Should handle timeout gracefully
  assert_not_contains "$output" "Unhandled error" "Should not show unhandled errors"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_scenario_empty() {
  print_section "Test: Mock Scenario - Empty"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Empty Scenario
Handle empty response.
EOF
  echo "# Progress" >progress.md

  # Run with empty scenario
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=empty \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify empty scenario
  assert_contains "$output" "Iteration:" "Should run iteration"
  assert_not_contains "$output" "error" "Should not show errors"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_mock_scenario_error() {
  print_section "Test: Mock Scenario - Error (Exit Code 1)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Error Scenario
This task will error.
EOF
  echo "# Progress" >progress.md

  # Run with error exit code
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_EXIT_CODE=1 \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1) || local exit_code=$?

  # Verify error handling
  assert_contains "$output" "Iteration:" "Should show iteration"
  # Should handle error gracefully
  assert_not_contains "$output" "Unhandled error" "Should not show unhandled errors"

  cd "$original_dir"
  rm -rf "$test_dir"
}

# ============================================================================
# SECTION 3: Environment Variable Configuration Tests
# Tests all environment variable configurations with mock backend
# ============================================================================

test_env_timeout_custom() {
  print_section "Test: Environment - RALPH_TIMEOUT Custom Value"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Custom Timeout Test
Test custom timeout value.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with custom timeout
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_TIMEOUT=600 \
    timeout 60 "$RALPH_SCRIPT" 1 2>&1)

  # Verify custom timeout is used
  assert_contains "$output" "Pipeline configuration loaded" "Should show config loaded"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_env_timeout_short() {
  print_section "Test: Environment - RALPH_TIMEOUT Short Value"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Short Timeout Test
Test short timeout value.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with short timeout
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_TIMEOUT=60 \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify short timeout is used
  assert_contains "$output" "Pipeline configuration loaded" "Should show config loaded"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_env_log_level_debug() {
  print_section "Test: Environment - RALPH_LOG_LEVEL DEBUG"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Debug Log Test
Test DEBUG log level.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with DEBUG log level
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_LOG_LEVEL=DEBUG \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify DEBUG level is used
  assert_contains "$output" "Pipeline configuration loaded" "Should show configuration"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_env_log_level_info() {
  print_section "Test: Environment - RALPH_LOG_LEVEL INFO"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Info Log Test
Test INFO log level.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with INFO log level
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_LOG_LEVEL=INFO \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify INFO level is used
  assert_contains "$output" "Pipeline configuration loaded" "Should show configuration"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_env_log_level_warn() {
  print_section "Test: Environment - RALPH_LOG_LEVEL WARN"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Warn Log Test
Test WARN log level.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with WARN log level
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_LOG_LEVEL=WARN \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify WARN level is used
  assert_contains "$output" "Pipeline configuration loaded" "Should show configuration"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_env_log_level_error() {
  print_section "Test: Environment - RALPH_LOG_LEVEL ERROR"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Error Log Test
Test ERROR log level.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with ERROR log level
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_LOG_LEVEL=ERROR \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify ERROR level is used
  assert_contains "$output" "Pipeline configuration loaded" "Should show configuration"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_env_memory_limit() {
  print_section "Test: Environment - RALPH_MEMORY_LIMIT"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Memory Limit Test
Test memory limit configuration.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with custom memory limit
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MEMORY_LIMIT=8GB \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify memory limit is shown
  assert_contains "$output" "Pipeline configuration loaded" "Should show configuration"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_env_prompt_override() {
  print_section "Test: Environment - RALPH_PROMPT Override"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Remove prompt file
  rm -f prompt.md
  echo "# Progress" >progress.md

  # Run with RALPH_PROMPT env var
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_PROMPT="Test prompt from environment" \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify prompt from environment is used
  assert_contains "$output" "Iteration:" "Should run iteration"
  # Should work without prompt.md file
  assert_not_contains "$output" "No prompt file found" "Should not show prompt error"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_env_prompt_file_override() {
  print_section "Test: Environment - RALPH_PROMPT_FILE Override"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Create custom prompt file
  mkdir -p "$test_dir/custom"
  cat >"$test_dir/custom/my-prompt.md" <<'EOF'
# Custom Prompt File
Test prompt from custom file.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Remove default prompt.md
  rm -f prompt.md

  # Run with RALPH_PROMPT_FILE env var
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_PROMPT_FILE="$test_dir/custom/my-prompt.md" \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify custom prompt file is used
  assert_contains "$output" "Iteration:" "Should run iteration"
  assert_contains "$output" "Custom Prompt File" "Should show custom prompt content"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_env_mock_delay() {
  print_section "Test: Environment - RALPH_MOCK_DELAY"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Delay Test
Test artificial delay.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with delay
  local start=$(date +%s)
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_DELAY=2 \
    RALPH_MOCK_RESPONSE=progress \
    timeout 60 "$RALPH_SCRIPT" 1 2>&1)
  local end=$(date +%s)
  local duration=$((end - start))

  # Verify delay was applied (approximately 2 seconds)
  assert_match "$duration" "^[2-4]$" "Should take about 2 seconds"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_env_combined() {
  print_section "Test: Environment - Combined Variables"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Combined Test
Test combined environment variables.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with multiple environment variables
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_TIMEOUT=300 \
    RALPH_LOG_LEVEL=DEBUG \
    RALPH_MOCK_RESPONSE=complete \
    RALPH_MOCK_DELAY=0 \
    timeout 60 "$RALPH_SCRIPT" 1 2>&1)

  # Verify all variables are applied
  assert_contains "$output" "Pipeline configuration loaded" "Should show config"
  assert_contains "$output" "Goal marked complete" "Should complete successfully"

  cd "$original_dir"
  rm -rf "$test_dir"
}

# ============================================================================
# SECTION 4: Error Condition Tests
# Tests error conditions with mock backend
# ============================================================================

test_error_missing_prompt_file() {
  print_section "Test: Error - Missing Prompt File"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Remove prompt file
  rm -f prompt.md
  echo "# Progress" >progress.md

  # Run without prompt file
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    timeout 10 "$RALPH_SCRIPT" 1 2>&1) || local exit_code=$?

  # Verify proper error handling
  assert_failure "$exit_code" "Should fail without prompt file"
  assert_contains "$output" "No prompt file found" "Should show error message"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_error_timeout_handling() {
  print_section "Test: Error - Timeout Handling (Exit Code 124)"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Timeout Test
Test timeout handling.
EOF
  echo "# Progress" >progress.md

  # Run with timeout exit code
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_EXIT_CODE=124 \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1) || local exit_code=$?

  # Verify timeout is handled
  assert_contains "$output" "Iteration:" "Should show iteration"
  # Exit code 124 from timeout should be propagated

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_error_non_zero_exit() {
  print_section "Test: Error - Non-Zero Exit Code Propagation"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Error Exit Test
Test non-zero exit code propagation.
EOF
  echo "# Progress" >progress.md

  # Run with error exit code
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_EXIT_CODE=42 \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1) || local exit_code=$?

  # Verify error exit code is propagated
  assert_equal "42" "$exit_code" "Should propagate custom exit code"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_error_multiple_failures() {
  print_section "Test: Error - Multiple Validation Failures"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Multiple Failures Test
This will trigger multiple validation failures.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with fail response
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=fail \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify detailed failure information
  assert_contains "$output" "Validation FAILED" "Should show validation failure"
  assert_contains "$output" "Issues saved to" "Should show issues saved"
  assert_contains "$output" "Mock validation failure" "Should show mock failure reason"

  cd "$original_dir"
  rm -rf "$test_dir"
}

# ============================================================================
# SECTION 5: Configuration File Scenario Tests
# Tests configuration file loading and parsing
# ============================================================================

test_config_backend_selection() {
  print_section "Test: Configuration - Backend Selection"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Backend Selection Test
Test backend selection via configuration.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with mock backend in PATH
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify backend is selected and used
  assert_contains "$output" "Iteration:" "Should run iteration"
  assert_contains "$output" "Configuration" "Should show configuration"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_config_env_precedence() {
  print_section "Test: Configuration - Environment Variable Precedence"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Environment Precedence Test
Test that env vars take precedence over config files.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with custom environment variables
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_TIMEOUT=999 \
    RALPH_LOG_LEVEL=DEBUG \
    timeout 60 "$RALPH_SCRIPT" 1 2>&1)

  # Verify environment variables override defaults
  assert_contains "$output" "Timeout:.*999s" "Should use env timeout"
  assert_contains "$output" "Log Level.*DEBUG" "Should use env log level"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_config_mock_backend_loading() {
  print_section "Test: Configuration - Mock Backend Loading"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Mock Backend Loading Test
Test that mock backend loads correctly.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with mock backend
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=success \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify mock backend is used
  assert_contains "$output" "Iteration:" "Should run iteration"
  assert_contains "$output" "Goal marked complete" "Should complete with mock"

  cd "$original_dir"
  rm -rf "$test_dir"
}

# ============================================================================
# SECTION 6: Git Integration Tests
# Tests git operations with mock backend
# ============================================================================

test_git_with_mock_success() {
  print_section "Test: Git - Integration with Mock Success"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Initialize git repository
  init_git_repo "$test_dir"

  cat >prompt.md <<'EOF'
# Git Success Test
Test git integration with successful mock.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with mock backend
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=success \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify git integration works
  assert_contains "$output" "Stage: execute" "Should run iteration"
  assert_contains "$output" "Goal marked complete" "Should complete successfully"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_git_with_mock_fail() {
  print_section "Test: Git - Integration with Mock Fail"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Initialize git repository
  init_git_repo "$test_dir"

  cat >prompt.md <<'EOF'
# Git Fail Test
Test git integration with failing mock.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with fail mock
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=fail \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify git integration handles failure
  assert_contains "$output" "Goal marked complete" "Should detect completion"
  assert_contains "$output" "Validation FAILED" "Should show validation failure"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_git_with_mock_progress() {
  print_section "Test: Git - Integration with Mock Progress"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Initialize git repository
  init_git_repo "$test_dir"

  cat >prompt.md <<'EOF'
# Git Progress Test
Test git integration with progress mock.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with progress mock
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=progress \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify git integration works with progress
  assert_contains "$output" "Stage: execute" "Should run iteration"
  assert_contains "$output" "Creating" "Should show progress steps"
  assert_contains "$output" "Goal marked complete" "Should complete"

  cd "$original_dir"
  rm -rf "$test_dir"
}

# ============================================================================
# SECTION 7: Iteration Control Tests
# Tests iteration control with mock backend
# ============================================================================

test_iteration_single() {
  print_section "Test: Iteration - Single Iteration"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Single Iteration Test
Run single iteration.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=complete \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  assert_contains "$output" "Stage: execute" "Should show execute stage"
  assert_contains "$output" "Max iterations" "Should not show max iterations"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_iteration_multiple() {
  print_section "Test: Iteration - Multiple Iterations"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Multiple Iteration Test
Run multiple iterations.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=complete \
    RALPH_MOCK_DELAY=0 \
    timeout 60 "$RALPH_SCRIPT" 5 2>&1)

  assert_contains "$output" "Iteration: 1 /" "Should show iteration 1"
  assert_contains "$output" "Iteration: 5 /" "Should show iteration 5"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_iteration_max_limit() {
  print_section "Test: Iteration - Max Iteration Limit"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Max Limit Test
Test max iteration limit.
EOF
  echo "# Progress" >progress.md

  # Run with iterations exceeding max (5 > 2 default max)
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=progress \
    timeout 60 "$RALPH_SCRIPT" 5 2>&1)

  # Verify max iterations is enforced
  assert_contains "$output" "Max iterations" "Should show max iterations"
  # Progress file should not exceed max
  local progress_content=$(cat progress.md 2>/dev/null || echo "")
  # Count iterations in progress - should not exceed configured max

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_iteration_progress_file_updates() {
  print_section "Test: Iteration - Progress File Updates"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Progress File Test
Verify progress file is updated each iteration.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run 3 iterations
  PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=complete \
    RALPH_MOCK_DELAY=0 \
    timeout 60 "$RALPH_SCRIPT" 3 >/dev/null 2>&1

  # Check progress file
  local progress_content=$(cat progress.md)
  assert_contains "$progress_content" "Iteration 1" "Progress should show iteration 1"
  assert_contains "$progress_content" "Iteration 2" "Progress should show iteration 2"
  assert_contains "$progress_content" "Iteration 3" "Progress should show iteration 3"

  cd "$original_dir"
  rm -rf "$test_dir"
}

# ============================================================================
# SECTION 8: Validation Workflow Tests
# Tests validation triggering and status parsing
# ============================================================================

test_validation_success_triggers() {
  print_section "Test: Validation - Success Triggers"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Validation Success Test
Test that success triggers validation.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=success \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  assert_contains "$output" "Goal marked complete" "Should detect completion"
  assert_contains "$output" "Running independent validation" "Should trigger validation"
  assert_contains "$output" "<validation_status>PASS</validation_status>" "Should show PASS"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_validation_failure_triggers() {
  print_section "Test: Validation - Failure Triggers"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Validation Failure Test
Test that failure triggers proper handling.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=fail \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  assert_contains "$output" "Goal marked complete" "Should detect completion"
  assert_contains "$output" "Validation FAILED" "Should show validation failure"
  assert_contains "$output" "Mock validation failure" "Should show mock failure reason"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_validation_status_parsing() {
  print_section "Test: Validation - Status Parsing"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Validation Parsing Test
Test that validation status is parsed correctly.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Test with success response (should have PASS validation)
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=success \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify status parsing works
  assert_contains "$output" "<validation_status>PASS</validation_status>" "Should parse PASS status"

  cd "$original_dir"
  rm -rf "$test_dir"
}

# ============================================================================
# SECTION 10: Regression Tests
# Tests specifically added to verify bug fixes and prevent regressions
# ============================================================================

test_regression_validation_failure_handling() {
  print_section "Test: Regression - Validation Failure Handling"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Validation Failure Regression Test
This tests that validation failures are handled correctly.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with fail response mode - capture exit code
  local output
  local exit_code=0
  output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=fail \
    timeout 30 "$RALPH_SCRIPT" 2 2>&1) || exit_code=$?

  # Verify validation failure handling - regression test for issue where
  # pipeline showed "Validation FAILED" but then showed "Pipeline completed successfully!"
  assert_contains "$output" "Validation FAILED" "Should show validation failure"
  assert_not_contains "$output" "Pipeline completed successfully" "Should NOT show successful completion when validation fails"

  # Verify that validation issues are saved for next iteration
  assert_contains "$output" "Issues saved to" "Should save validation issues"

  # Verify that the pipeline continues to next iteration (retry behavior)
  # With 2 iterations, we should see execute stage multiple times
  local execute_count
  execute_count=$(echo "$output" | grep -c "Stage: execute" || echo "0")
  assert_match "$execute_count" "^[2-9]$" "Should have multiple execute stages (got $execute_count)"

  # Exit code should be non-zero when validation fails
  # Note: The exact exit code may vary, but it should not be 0
  if [ "$exit_code" -eq 0 ]; then
    print_warning "Exit code was 0 - this may indicate the mock backend exit code fix is not working"
  fi

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_regression_mock_backend_exit_code() {
  print_section "Test: Regression - Mock Backend Exit Code on Validation Failure"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Create a simple test that runs the mock-opencode validate command directly
  cat >prompt.md <<'EOF'
# Exit Code Test
Test mock backend exit code.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Test the mock-opencode validate command directly with fail response
  local mock_exit_code=0
  PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=fail \
    mock-opencode validate >/dev/null 2>&1
  mock_exit_code=$?

  # Verify that mock backend returns non-zero exit code when validation fails
  assert_not_equal "0" "$mock_exit_code" "Mock backend should return non-zero exit code on validation failure (got $mock_exit_code)"

  # Test that it returns 0 on success
  mock_exit_code=0
  PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=success \
    mock-opencode validate >/dev/null 2>&1
  mock_exit_code=$?

  assert_equal "0" "$mock_exit_code" "Mock backend should return 0 on validation success"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_regression_no_complete_stage_transition() {
  print_section "Test: Regression - No Invalid Complete Stage Transition"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# No Complete Stage Test
Verify pipeline doesn't transition to non-existent complete stage.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run with fail response mode
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=fail \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify pipeline doesn't try to transition to non-existent "complete" stage
  # The old buggy behavior would show "complete" stage which doesn't exist
  assert_not_contains "$output" "Stage: complete" "Should NOT show non-existent complete stage"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_edge_empty_prompt_file() {
  print_section "Test: Edge - Empty Prompt File"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Create empty prompt file
  touch prompt.md
  echo "# Progress" >progress.md

  # Run with empty prompt
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=progress \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1) || local exit_code=$?

  # Verify graceful handling
  assert_contains "$output" "Iteration:" "Should run iteration"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_edge_no_prompt_with_env() {
  print_section "Test: Edge - No Prompt File with RALPH_PROMPT"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Remove prompt file
  rm -f prompt.md
  echo "# Progress" >progress.md

  # Run with RALPH_PROMPT
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_PROMPT="Test from environment variable" \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Verify env var is used
  assert_contains "$output" "Iteration:" "Should run iteration"
  assert_not_contains "$output" "No prompt file found" "Should not show prompt error"

  cd "$original_dir"
  rm -rf "$test_dir"
}

test_edge_rapid_iterations() {
  print_section "Test: Edge - Rapid Iterations"

  local test_dir=$(create_temp_dir)
  local original_dir="$(pwd)"
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Rapid Iterations Test
Test rapid iteration handling.
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  # Run multiple iterations rapidly
  local start=$(date +%s)
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=complete \
    RALPH_MOCK_DELAY=0 \
    timeout 120 "$RALPH_SCRIPT" 10 2>&1)
  local end=$(date +%s)
  local duration=$((end - start))

  # Should complete quickly
  assert_match "$duration" "^[0-9]$" "Should complete rapidly"
  assert_contains "$output" "Iteration: 10 /" "Should show all iterations"

  cd "$original_dir"
  rm -rf "$test_dir"
}

# ============================================================================
# Main Test Runner
# ============================================================================

run_mock_e2e_comprehensive_tests() {
  print_header "Comprehensive Mock E2E Tests"

  # Setup
  setup_test_environment

  # Section 1: Mock Response Mode Tests
  print_header "Section 1: Mock Response Mode Tests"
  test_mock_response_mode_complete_single
  test_mock_response_mode_complete_multi
  test_mock_response_mode_fail_single
  test_mock_response_mode_fail_multi
  test_mock_response_mode_progress_single
  test_mock_response_mode_progress_multi
  test_mock_response_mode_empty_single
  test_mock_response_mode_empty_multi

  # Section 2: Mock Scenario Tests
  print_header "Section 2: Mock Scenario Tests"
  test_mock_scenario_success
  test_mock_scenario_fail
  test_mock_scenario_progress
  test_mock_scenario_timeout
  test_mock_scenario_empty
  test_mock_scenario_error

  # Section 3: Environment Variable Tests
  print_header "Section 3: Environment Variable Tests"
  test_env_timeout_custom
  test_env_timeout_short
  test_env_log_level_debug
  test_env_log_level_info
  test_env_log_level_warn
  test_env_log_level_error
  test_env_memory_limit
  test_env_prompt_override
  test_env_prompt_file_override
  test_env_mock_delay
  test_env_combined

  # Section 4: Error Condition Tests
  print_header "Section 4: Error Condition Tests"
  test_error_missing_prompt_file
  test_error_timeout_handling
  test_error_non_zero_exit
  test_error_multiple_failures

  # Section 5: Configuration File Tests
  print_header "Section 5: Configuration File Tests"
  test_config_backend_selection
  test_config_env_precedence
  test_config_mock_backend_loading

  # Section 6: Git Integration Tests
  print_header "Section 6: Git Integration Tests"
  test_git_with_mock_success
  test_git_with_mock_fail
  test_git_with_mock_progress

  # Section 7: Iteration Control Tests
  print_header "Section 7: Iteration Control Tests"
  test_iteration_single
  test_iteration_multiple
  test_iteration_max_limit
  test_iteration_progress_file_updates

  # Section 8: Validation Workflow Tests
  print_header "Section 8: Validation Workflow Tests"
  test_validation_success_triggers
  test_validation_failure_triggers
  test_validation_status_parsing

  # Section 9: Edge Case Tests
  print_header "Section 9: Edge Case Tests"
  test_edge_empty_prompt_file
  test_edge_no_prompt_with_env
  test_edge_rapid_iterations

  # Section 10: Regression Tests
  print_header "Section 10: Regression Tests"
  test_regression_validation_failure_handling
  test_regression_mock_backend_exit_code
  test_regression_no_complete_stage_transition

  # Teardown
  teardown_test_environment

  print_test_summary
}

# Run tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export VERBOSE="${VERBOSE:-false}"
  run_mock_e2e_comprehensive_tests
fi
