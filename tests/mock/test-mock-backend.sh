#!/usr/bin/env bash
# RalphLoop Mock Backend Tests
# Comprehensive tests for the mock backend functionality

set -e -u -o pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ============================================================================
# Test: Basic mock functionality
# ============================================================================

test_mock_basic_run() {
  print_section "Test: Mock basic run command"

  local output=$("$MOCK_OPENCODE" run --agent default 2>&1)

  assert_contains "$output" "mock agent" "Should show mock agent message"
  assert_contains "$output" "Mode:" "Should show mode"
}

test_mock_run_with_custom_agent() {
  print_section "Test: Mock run with custom agent"

  local output=$("$MOCK_OPENCODE" run --agent custom-agent 2>&1)

  assert_contains "$output" "custom-agent" "Should use custom agent name"
}

# ============================================================================
# Test: Response modes
# ============================================================================

test_response_mode_complete() {
  print_section "Test: Response mode - complete"

  local output=$(RALPH_MOCK_RESPONSE=complete "$MOCK_OPENCODE" run --agent test 2>&1)

  assert_contains "$output" "COMPLETE" "Should show COMPLETE marker"
  assert_contains "$output" "completed successfully" "Should show success message"
}

test_response_mode_fail() {
  print_section "Test: Response mode - fail"

  local output=$(RALPH_MOCK_RESPONSE=fail "$MOCK_OPENCODE" run --agent test 2>&1)

  assert_contains "$output" "COMPLETE" "Should still complete"
}

test_response_mode_progress() {
  print_section "Test: Response mode - progress"

  local output=$(RALPH_MOCK_RESPONSE=progress "$MOCK_OPENCODE" run --agent test 2>&1)

  assert_contains "$output" "COMPLETE" "Should show COMPLETE"
}

test_response_mode_empty() {
  print_section "Test: Response mode - empty"

  local output=$(RALPH_MOCK_RESPONSE=empty "$MOCK_OPENCODE" run --agent test 2>&1)

  assert_empty "$output" "Should return empty output"
}

# ============================================================================
# Test: Delay functionality
# ============================================================================

test_delay_zero() {
  print_section "Test: Delay - zero"

  local start=$(date +%s)
  local output=$(RALPH_MOCK_DELAY=0 "$MOCK_OPENCODE" run --agent test 2>&1)
  local end=$(date +%s)
  local duration=$((end - start))

  assert_equal "0" "$duration" "Should complete instantly with zero delay"
}

test_delay_short() {
  print_section "Test: Delay - short"

  local start=$(date +%s)
  local output=$(RALPH_MOCK_DELAY=1 "$MOCK_OPENCODE" run --agent test 2>&1)
  local end=$(date +%s)
  local duration=$((end - start))

  # Should take approximately 1 second
  assert_match "$duration" "^[1-2]$" "Should take about 1 second"
}

test_delay_message() {
  print_section "Test: Delay - message display"

  local output=$(RALPH_MOCK_DELAY=1 "$MOCK_OPENCODE" run --agent test 2>&1)

  assert_contains "$output" "Simulating processing time" "Should show delay message"
}

# ============================================================================
# Test: Exit codes
# ============================================================================

test_exit_code_success() {
  print_section "Test: Exit code - success"

  local output
  local exit_code
  output=$("$MOCK_OPENCODE" run --agent test 2>&1)
  exit_code=$?

  assert_success "$exit_code" "Should exit with code 0"
}

test_exit_code_timeout() {
  print_section "Test: Exit code - timeout simulation"

  local output
  local exit_code=0
  output=$(RALPH_MOCK_EXIT_CODE=124 "$MOCK_OPENCODE" run --agent test 2>&1) || exit_code=$?

  assert_equal "124" "$exit_code" "Should exit with code 124 for timeout"
}

test_exit_code_error() {
  print_section "Test: Exit code - error simulation"

  local output
  local exit_code=0
  output=$(RALPH_MOCK_EXIT_CODE=1 "$MOCK_OPENCODE" run --agent test 2>&1) || exit_code=$?

  assert_failure "$exit_code" "Should exit with non-zero code for error"
}

# ============================================================================
# Test: Validation mode
# ============================================================================

test_validation_pass() {
  print_section "Test: Validation - PASS"

  local output=$(RALPH_MOCK_RESPONSE=success "$MOCK_OPENCODE" validate 2>&1)

  assert_contains "$output" "<validation_status>PASS</validation_status>" "Should show PASS status"
  assert_contains "$output" "<validation_issues>" "Should show issues section"
}

test_validation_fail() {
  print_section "Test: Validation - FAIL"

  local output=$(RALPH_MOCK_RESPONSE=fail "$MOCK_OPENCODE" validate 2>&1)

  assert_contains "$output" "<validation_status>FAIL</validation_status>" "Should show FAIL status"
  assert_contains "$output" "Mock validation failure" "Should show mock failure reason"
}

test_validation_empty() {
  print_section "Test: Validation - empty"

  local output=$(RALPH_MOCK_RESPONSE=empty "$MOCK_OPENCODE" validate 2>&1)

  # Should handle empty response gracefully
  assert_not_contains "$output" "error" "Should not show errors"
}

# ============================================================================
# Test: Test scenarios
# ============================================================================

test_scenario_comprehensive() {
  print_section "Test: Scenario - comprehensive"

  # Test all available scenarios
  local scenarios=("success" "fail" "progress" "timeout" "empty" "error")

  for scenario in "${scenarios[@]}"; do
    local output=$("$MOCK_OPENCODE" test "$scenario" 2>&1)
    assert_contains "$output" "Test Scenario: $scenario" "Scenario $scenario should work"
  done
}

# ============================================================================
# Test: Help and usage
# ============================================================================

test_help_output() {
  print_section "Test: Help output"

  local output=$("$MOCK_OPENCODE" --help 2>&1)

  # Should contain all sections
  assert_contains "$output" "Usage:" "Should show usage"
  assert_contains "$output" "Commands:" "Should show commands"
  assert_contains "$output" "Options for 'run':" "Should show options"
  assert_contains "$output" "Environment Variables:" "Should show env vars"
  assert_contains "$output" "Test Scenarios:" "Should show scenarios"
}

# ============================================================================
# Test: Output streaming simulation
# ============================================================================

test_output_streaming() {
  print_section "Test: Output streaming simulation"

  # With progress mode and delay, output should be streamed
  local output=$(RALPH_MOCK_DELAY=0 RALPH_MOCK_RESPONSE=progress "$MOCK_OPENCODE" run --agent test 2>&1)

  # Should contain progress indicators
  assert_contains "$output" "I'm working on the task" "Should show progress message"
  assert_contains "$output" "First, I'll create" "Should show creating steps"
  assert_contains "$output" "Then I'll verify" "Should show verifying steps"
}

# ============================================================================
# Test: Error handling
# ============================================================================

test_error_handling_invalid_command() {
  print_section "Test: Error handling - invalid command"

  local output
  local exit_code=0
  output=$("$MOCK_OPENCODE" invalid-command 2>&1) || exit_code=$?

  assert_failure "$exit_code" "Should fail with invalid command"
  assert_contains "$output" "Unknown argument" "Should show error message"
}

test_error_handling_missing_args() {
  print_section "Test: Error handling - missing args for test"

  local output
  local exit_code=0
  output=$("$MOCK_OPENCODE" test 2>&1) || exit_code=$?

  assert_failure "$exit_code" "Should fail with missing args"
}

# ============================================================================
# Test: Color output
# ============================================================================

test_color_output() {
  print_section "Test: Color output"

  local output=$("$MOCK_OPENCODE" status 2>&1)

  # Check for ANSI color codes
  assert_contains "$output" "Mock OpenCode Status" "Should show status header"
  assert_contains "$output" "Response Mode:" "Should show response mode"
}

# ============================================================================
# Test: Integration with RalphLoop
# ============================================================================

test_integration_single_iteration() {
  print_section "Test: Integration - single iteration"

  local test_dir=$(create_temp_dir)
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  echo "# Test" >prompt.md
  echo "# Progress" >progress.md

  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=success \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  assert_contains "$output" "Stage:" "Should show single iteration"
  assert_contains "$output" "Starting agent execution" "Should show agent start"

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

test_integration_validation_flow() {
  print_section "Test: Integration - validation flow"

  local test_dir=$(create_temp_dir)
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  # Create prompt that will be marked complete
  cat >prompt.md <<'EOF'
# Test Project

Work on this task.

<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=success \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Should trigger validation
  assert_contains "$output" "Agent indicated completion" "Should detect completion"
  assert_contains "$output" "Validation" "Should run validation"

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

test_integration_failed_validation() {
  print_section "Test: Integration - failed validation"

  local test_dir=$(create_temp_dir)
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  cat >prompt.md <<'EOF'
# Test Project

<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md

  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" \
    RALPH_MOCK_RESPONSE=fail \
    timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  # Should show validation failure
  assert_contains "$output" "Validation FAILED" "Should detect validation failure"
  assert_contains "$output" "issues" "Should show issues"

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

# ============================================================================
# Main test runner
# ============================================================================

run_mock_tests() {
  print_header "Mock Backend Tests"

  # Setup
  setup_test_environment

  # Run tests
  test_mock_basic_run
  test_mock_run_with_custom_agent

  test_response_mode_complete
  test_response_mode_fail
  test_response_mode_progress
  test_response_mode_empty

  test_delay_zero
  test_delay_short
  test_delay_message

  test_exit_code_success
  test_exit_code_timeout
  test_exit_code_error

  test_validation_pass
  test_validation_fail
  test_validation_empty

  test_scenario_comprehensive

  test_help_output
  test_output_streaming

  test_error_handling_invalid_command
  test_error_handling_missing_args

  test_color_output

  test_integration_single_iteration
  test_integration_validation_flow
  test_integration_failed_validation

  # Teardown
  teardown_test_environment

  print_test_summary
}

# Run tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export VERBOSE="${VERBOSE:-false}"
  run_mock_tests
fi
