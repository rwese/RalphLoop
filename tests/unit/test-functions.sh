#!/usr/bin/env bash
# RalphLoop Unit Tests - Script Functions
# Tests for individual functions in the ralph script

set -e -u -o pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ============================================================================
# Test: sanitize_for_heredoc function
# ============================================================================

test_sanitize_heredoc() {
  print_section "Test: sanitize_for_heredoc"

  local content="Test content with EOF marker"
  local sanitized=$(RALPH_SOURCED_FOR_TEST=1 bash -c "source '$RALPH_LIB' 2>/dev/null; sanitize_for_heredoc" 2>/dev/null)

  assert_not_contains "$sanitized" "EOF" "Should replace EOF marker"
}

test_sanitize_multiple_eof() {
  print_section "Test: sanitize_for_heredoc with multiple EOF"

  local content="EOF some content EOF more content EOF"
  local sanitized=$(RALPH_SOURCED_FOR_TEST=1 bash -c "source '$RALPH_LIB' 2>/dev/null; sanitize_for_heredoc" 2>/dev/null)

  assert_not_contains "$sanitized" "EOF" "All EOF markers should be replaced"
}

# ============================================================================
# Test: get_validation_status function
# ============================================================================

test_get_validation_status_pass() {
  print_section "Test: get_validation_status - PASS"

  local result="<validation_status>PASS</validation_status>"
  local status=$(RALPH_SOURCED_FOR_TEST=1 bash -c "source '$RALPH_LIB' 2>/dev/null; get_validation_status '$result'" 2>/dev/null)

  assert_equal "PASS" "$status" "Should extract PASS status"
}

test_get_validation_status_fail() {
  print_section "Test: get_validation_status - FAIL"

  local result="<validation_status>FAIL</validation_status>"
  local status=$(RALPH_SOURCED_FOR_TEST=1 bash -c "source '$RALPH_LIB' 2>/dev/null; get_validation_status '$result'" 2>/dev/null)

  assert_equal "FAIL" "$status" "Should extract FAIL status"
}

test_get_validation_status_empty() {
  print_section "Test: get_validation_status - empty"

  local result=""
  local status=$(echo "$result" | RALPH_SOURCED_FOR_TEST=1 bash -c "source '$RALPH_LIB' 2>/dev/null; get_validation_status" 2>/dev/null)

  assert_empty "$status" "Should return empty for no status"
}

# ============================================================================
# Test: validate_max_rounds function
# ============================================================================

test_validate_max_rounds_valid() {
  print_section "Test: validate_max_rounds - valid input"

  local result=$(RALPH_SOURCED_FOR_TEST=1 MAX_ROUNDS=10 bash -c "source '$RALPH_LIB' 2>/dev/null; validate_max_rounds" 2>&1)
  assert_success $? "Should accept valid number"
}

test_validate_max_rounds_zero() {
  print_section "Test: validate_max_rounds - zero"

  local result=$(RALPH_SOURCED_FOR_TEST=1 MAX_ROUNDS=0 bash -c "source '$RALPH_LIB' 2>/dev/null; validate_max_rounds" 2>&1) || true
  assert_contains "$result" "at least 1" "Should reject zero"
}

test_validate_max_rounds_negative() {
  print_section "Test: validate_max_rounds - negative"

  local result=$(RALPH_SOURCED_FOR_TEST=1 MAX_ROUNDS=-5 bash -c "source '$RALPH_LIB' 2>/dev/null; validate_max_rounds" 2>&1) || true
  assert_contains "$result" "positive integer" "Should reject negative"
}

test_validate_max_rounds_string() {
  print_section "Test: validate_max_rounds - string"

  local result=$(RALPH_SOURCED_FOR_TEST=1 MAX_ROUNDS="abc" bash -c "source '$RALPH_LIB' 2>/dev/null; validate_max_rounds" 2>&1) || true
  assert_contains "$result" "positive integer" "Should reject string"
}

# ============================================================================
# Test: Configuration display
# ============================================================================

test_display_config() {
  print_section "Test: display_config output"

  local output=$(RALPH_SOURCED_FOR_TEST=1 bash -c "source '$RALPH_LIB' 2>/dev/null; display_config" 2>/dev/null)

  assert_contains "$output" "RalphLoop Configuration" "Should show configuration header"
  assert_contains "$output" "Timeout" "Should show timeout setting"
  assert_contains "$output" "Max Iterations" "Should show max iterations"
}

# ============================================================================
# Test: Template functions
# ============================================================================

test_get_standard_template() {
  print_section "Test: get_standard_template"

  local template=$(RALPH_SOURCED_FOR_TEST=1 bash -c "source '$RALPH_LIB' 2>/dev/null; get_standard_template" 2>/dev/null)

  assert_contains "$template" "Project Goal" "Should contain Project Goal header"
  assert_contains "$template" "Acceptance Criteria" "Should contain Acceptance Criteria section"
  assert_contains "$template" "Context" "Should contain Context section"
}

test_get_quickfix_template() {
  print_section "Test: get_quickfix_template"

  local template=$(RALPH_SOURCED_FOR_TEST=1 bash -c "source '$RALPH_LIB' 2>/dev/null; get_quickfix_template" 2>/dev/null)

  assert_contains "$template" "QuickFix" "Should contain QuickFix header"
  assert_contains "$template" "Issue" "Should contain Issue section"
  assert_contains "$template" "Expected Behavior" "Should contain Expected Behavior section"
  assert_contains "$template" "Files Affected" "Should contain Files Affected section"
}

test_get_blank_template() {
  print_section "Test: get_blank_template"

  local template=$(RALPH_SOURCED_FOR_TEST=1 bash -c "source '$RALPH_LIB' 2>/dev/null; get_blank_template" 2>/dev/null)

  assert_contains "$template" "# Project" "Should contain minimal Project header"
}

# ============================================================================
# Test: get_prompt_nointeractive function
# ============================================================================

test_get_prompt_nointeractive_with_env_var() {
  print_section "Test: get_prompt_nointeractive - with RALPH_PROMPT"

  local result=$(RALPH_SOURCED_FOR_TEST=1 RALPH_PROMPT="Test prompt content" bash -c "source '$RALPH_LIB' 2>/dev/null; get_prompt_nointeractive" 2>/dev/null)

  assert_equal "Test prompt content" "$result" "Should return RALPH_PROMPT value"
}

test_get_prompt_nointeractive_fallback() {
  print_section "Test: get_prompt_nointeractive - fallback message"

  local result=$(RALPH_SOURCED_FOR_TEST=1 PROMPT_FILE="/nonexistent/file" bash -c "source '$RALPH_LIB' 2>/dev/null; get_prompt_nointeractive" 2>/dev/null)

  assert_contains "$result" "No original prompt available" "Should return fallback message"
}

# ============================================================================
# Test: show_template_menu with environment variable
# ============================================================================

test_show_template_menu_env_standard() {
  print_section "Test: show_template_menu - RALPH_TEMPLATE_TYPE=standard"

  local result=$(RALPH_SOURCED_FOR_TEST=1 RALPH_TEMPLATE_TYPE=standard bash -c "source '$RALPH_LIB' 2>/dev/null; show_template_menu" 2>/dev/null)

  assert_equal "standard" "$result" "Should return standard when env var is set"
}

test_show_template_menu_env_quickfix() {
  print_section "Test: show_template_menu - RALPH_TEMPLATE_TYPE=quickfix"

  local result=$(RALPH_SOURCED_FOR_TEST=1 RALPH_TEMPLATE_TYPE=quickfix bash -c "source '$RALPH_LIB' 2>/dev/null; show_template_menu" 2>/dev/null)

  assert_equal "quickfix" "$result" "Should return quickfix when env var is set"
}

test_show_template_menu_env_blank() {
  print_section "Test: show_template_menu - RALPH_TEMPLATE_TYPE=blank"

  local result=$(RALPH_SOURCED_FOR_TEST=1 RALPH_TEMPLATE_TYPE=blank bash -c "source '$RALPH_LIB' 2>/dev/null; show_template_menu" 2>/dev/null)

  assert_equal "blank" "$result" "Should return blank when env var is set"
}

test_show_template_menu_env_ai() {
  print_section "Test: show_template_menu - RALPH_TEMPLATE_TYPE=ai"

  local result=$(RALPH_SOURCED_FOR_TEST=1 RALPH_TEMPLATE_TYPE=ai bash -c "source '$RALPH_LIB' 2>/dev/null; show_template_menu" 2>/dev/null)

  assert_equal "ai" "$result" "Should return ai when env var is set"
}

test_show_template_menu_env_example() {
  print_section "Test: show_template_menu - RALPH_TEMPLATE_TYPE=example"

  local result=$(RALPH_SOURCED_FOR_TEST=1 RALPH_TEMPLATE_TYPE=example bash -c "source '$RALPH_LIB' 2>/dev/null; show_template_menu" 2>/dev/null)

  assert_equal "example" "$result" "Should return example when env var is set"
}

# ============================================================================
# Main test runner
# ============================================================================

run_unit_tests() {
  print_header "Unit Tests - Script Functions"

  # Setup
  setup_test_environment

  # Run tests
  test_sanitize_heredoc
  test_sanitize_multiple_eof

  test_get_validation_status_pass
  test_get_validation_status_fail
  test_get_validation_status_empty

  test_validate_max_rounds_valid
  test_validate_max_rounds_zero
  test_validate_max_rounds_negative
  test_validate_max_rounds_string

  test_display_config

  # Template tests
  test_get_standard_template
  test_get_quickfix_template
  test_get_blank_template

  # get_prompt_nointeractive tests
  test_get_prompt_nointeractive_with_env_var
  test_get_prompt_nointeractive_fallback

  # Template menu tests
  test_show_template_menu_env_standard
  test_show_template_menu_env_quickfix
  test_show_template_menu_env_blank
  test_show_template_menu_env_ai
  test_show_template_menu_env_example

  # Teardown
  teardown_test_environment

  print_test_summary
}

# Run tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  export VERBOSE="${VERBOSE:-false}"
  run_unit_tests
fi
