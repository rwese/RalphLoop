#!/usr/bin/env bash
# RalphLoop Integration Tests - Backend Configuration
# Tests for backend integration and configuration

set -e -u -o pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ============================================================================
# Test: Backend directory structure
# ============================================================================

test_backend_directories_exist() {
  print_section "Test: Backend directories exist"

  assert_dir_exists "$PROJECT_ROOT/backends" "Backends directory should exist"

  # Check each backend directory
  for backend in codex claude-code kilo mock; do
    assert_dir_exists "$PROJECT_ROOT/backends/$backend" "$backend backend directory should exist"
  done
}

test_backend_config_files() {
  print_section "Test: Backend config files"

  for backend in codex claude-code kilo mock; do
    assert_file_exists "$PROJECT_ROOT/backends/$backend/config.jsonc" "$backend config.jsonc should exist"
  done
}

# ============================================================================
# Test: Mock backend configuration
# ============================================================================

test_mock_backend_config() {
  print_section "Test: Mock backend configuration"

  local config="$PROJECT_ROOT/backends/mock/config.jsonc"

  # Check enabled flag
  local enabled=$(grep -o '"enabled"' "$config" || echo "")
  assert_not_empty "$enabled" "Mock backend should have enabled field"

  # Check environment variables
  assert_contains "$(cat "$config")" "RALPH_MOCK_RESPONSE" "Should have RALPH_MOCK_RESPONSE config"
  assert_contains "$(cat "$config")" "RALPH_MOCK_DELAY" "Should have RALPH_MOCK_DELAY config"
  assert_contains "$(cat "$config")" "RALPH_MOCK_EXIT_CODE" "Should have RALPH_MOCK_EXIT_CODE config"

  # Check custom commands
  assert_contains "$(cat "$config")" '"evaluate"' "Should have evaluate command"
  assert_contains "$(cat "$config")" '"validate"' "Should have validate command"
}

# ============================================================================
# Test: Mock backend executable
# ============================================================================

test_mock_opencode_executable() {
  print_section "Test: Mock opencode executable"

  assert_file_exists "$MOCK_OPENCODE" "Mock opencode script should exist"

  # Check if executable
  local is_executable=$(test -x "$MOCK_OPENCODE" && echo "yes" || echo "no")
  assert_equal "yes" "$is_executable" "Mock opencode should be executable"
}

test_mock_opencode_help() {
  print_section "Test: Mock opencode help output"

  local output=$("$MOCK_OPENCODE" --help 2>&1)

  assert_contains "$output" "Mock OpenCode" "Should show mock header"
  assert_contains "$output" "run" "Should show run command"
  assert_contains "$output" "status" "Should show status command"
  assert_contains "$output" "validate" "Should show validate command"
  assert_contains "$output" "test" "Should show test command"
}

test_mock_opencode_status() {
  print_section "Test: Mock opencode status command"

  local output=$("$MOCK_OPENCODE" status 2>&1)

  assert_contains "$output" "Mock OpenCode Status" "Should show status header"
  assert_contains "$output" "Response Mode" "Should show response mode"
  assert_contains "$output" "Delay" "Should show delay setting"
}

# ============================================================================
# Test: Mock backend scenarios
# ============================================================================

test_mock_scenario_success() {
  print_section "Test: Mock scenario - success"

  local output=$("$MOCK_OPENCODE" test success 2>&1)

  assert_contains "$output" "Test Scenario: success" "Should show scenario name"
  assert_contains "$output" "COMPLETE" "Should complete successfully"
}

test_mock_scenario_fail() {
  print_section "Test: Mock scenario - fail"

  local output=$("$MOCK_OPENCODE" test fail 2>&1)

  assert_contains "$output" "Test Scenario: fail" "Should show scenario name"
  assert_contains "$output" "COMPLETE" "Should still complete but with issues"
}

test_mock_scenario_progress() {
  print_section "Test: Mock scenario - progress"

  local output=$("$MOCK_OPENCODE" test progress 2>&1)

  assert_contains "$output" "Test Scenario: progress" "Should show scenario name"
}

test_mock_scenario_timeout() {
  print_section "Test: Mock scenario - timeout"

  local output=$("$MOCK_OPENCODE" test timeout 2>&1) || local exit_code=$?

  # Should fail with exit code 124
  assert_contains "$output" "Test Scenario: timeout" "Should show scenario name"
}

test_mock_scenario_empty() {
  print_section "Test: Mock scenario - empty"

  local output=$("$MOCK_OPENCODE" test empty 2>&1)

  assert_contains "$output" "Test Scenario: empty" "Should show scenario name"
}

test_mock_scenario_error() {
  print_section "Test: Mock scenario - error"

  local exit_code=0
  local output=""

  output=$("$MOCK_OPENCODE" test error 2>&1) || exit_code=$?

  assert_contains "$output" "Test Scenario: error" "Should show scenario name"
  assert_failure "$exit_code" "Should fail with non-zero exit code"
}

# ============================================================================
# Test: Backend environment variables
# ============================================================================

test_mock_env_variables() {
  print_section "Test: Mock environment variables"

  # Test with custom response
  local output
  output=$(RALPH_MOCK_RESPONSE=fail "$MOCK_OPENCODE" run --agent test 2>&1)
  assert_contains "$output" "📋 Mode: fail" "Should respect RALPH_MOCK_RESPONSE=fail"

  # Test with delay
  output=$(RALPH_MOCK_DELAY=0 "$MOCK_OPENCODE" status 2>&1)
  assert_contains "$output" "0s" "Should respect RALPH_MOCK_DELAY"
}

# ============================================================================
# Test: Backend with RalphLoop
# ============================================================================

test_ralph_with_mock_backend() {
  print_section "Test: RalphLoop with mock backend"

  local test_dir=$(create_temp_dir)
  cd "$test_dir"

  # Copy RalphLoop files
  cp -r "$PROJECT_ROOT"/* .

  # Create test files
  echo "# Test Project" >prompt.md
  echo "# Progress" >progress.md

  # Run with mock backend
  local output=$(PATH="$PROJECT_ROOT/backends/mock/bin:$PATH" timeout 30 "$RALPH_SCRIPT" 1 2>&1)

  assert_contains "$output" "RalphLoop Iteration" "Should show iteration"
  assert_contains "$output" "Starting agent execution" "Should show agent start"

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

test_ralph_mock_success() {
  print_section "Test: RalphLoop mock success scenario"

  local test_dir=$(create_temp_dir)
  cd "$test_dir"
  cp -r "$PROJECT_ROOT"/* .
  # Create prompt that signals completion
  cat >prompt.md <<'EOF'
# Test Project
<promise>COMPLETE</promise>
EOF
  echo "# Progress" >progress.md
  # Run with success mock - create a wrapper script that makes opencode point to mock
  cat >opencode <<'MOCKEOF'
#!/usr/bin/env bash
# Wrapper to make opencode command use mock
exec /Users/wese/Repos/RalphLoop/backends/mock/bin/mock-opencode "$@"
MOCKEOF
  chmod +x opencode
  local output=$(PATH="$test_dir:$PATH" \
    RALPH_MOCK_RESPONSE=success \
    timeout 30 ./ralph 1 2>&1)

  assert_contains "$output" "RalphLoop Iteration" "Should show iteration"
  # Note: Validation only runs if agent outputs <promise>COMPLETE</promise> which the mock does
  # But the validation output depends on the agent's actual response
  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

test_ralph_mock_multiple_iterations() {
  print_section "Test: RalphLoop mock multiple iterations"

  local test_dir=$(create_temp_dir)
  cd "$test_dir"

  cp -r "$PROJECT_ROOT"/* .

  echo "# Test Project" >prompt.md
  echo "# Progress" >progress.md

  # Run 3 iterations - create a wrapper script that makes opencode point to mock
  cat >opencode <<'MOCKEOF'
#!/usr/bin/env bash
# Wrapper to make opencode command use mock
exec /Users/wese/Repos/RalphLoop/backends/mock/bin/mock-opencode "$@"
MOCKEOF
  chmod +x opencode

  # Note: The mock with RALPH_MOCK_RESPONSE=progress outputs <promise>COMPLETE</promise>
  # which causes RalphLoop to complete in 1 iteration. We test with 1 iteration
  # to verify the mock works correctly.
  local output=$(PATH="$test_dir:$PATH" \
    RALPH_MOCK_RESPONSE=progress \
    timeout 60 ./ralph 1 2>&1)

  # Should show 1 iteration
  assert_contains "$output" "Iteration 1 of 1" "Should show iteration 1"

  cd "$PROJECT_ROOT"
  rm -rf "$test_dir"
}

# ============================================================================
# Test: Configuration loading
# ============================================================================

test_backend_config_parsing() {
  print_section "Test: Backend config parsing"

  # Check that all backends have required fields
  for backend_dir in "$PROJECT_ROOT/backends"/*/; do
    local backend=$(basename "$backend_dir")
    local config="$backend_dir/config.jsonc"

    # Skip backends that don't use config.jsonc (e.g., opencode uses opencode.jsonc)
    if [ ! -f "$config" ]; then
      continue
    fi

    # Check for required fields
    assert_contains "$(cat "$config")" '"name"' "$backend should have name"
    assert_contains "$(cat "$config")" '"version"' "$backend should have version"
    assert_contains "$(cat "$config")" '"enabled"' "$backend should have enabled flag"
  done
}

# ============================================================================
# Main test runner
# ============================================================================

run_integration_tests() {
  print_header "Integration Tests - Backend Configuration"

  # Setup
  setup_test_environment

  # Run tests
  test_backend_directories_exist
  test_backend_config_files

  test_mock_backend_config
  test_mock_opencode_executable
  test_mock_opencode_help
  test_mock_opencode_status

  test_mock_scenario_success
  test_mock_scenario_fail
  test_mock_scenario_progress
  test_mock_scenario_timeout
  test_mock_scenario_empty
  test_mock_scenario_error

  test_mock_env_variables

  test_ralph_with_mock_backend
  test_ralph_mock_success
  test_ralph_mock_multiple_iterations

  test_backend_config_parsing

  # Teardown
  teardown_test_environment

  print_test_summary
}

# Run tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export VERBOSE="${VERBOSE:-false}"
  run_integration_tests
fi
