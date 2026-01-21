#!/usr/bin/env bash
# RalphLoop Unit Tests - Script Functions
# Tests for individual functions in the ralph script

set -e -u -o pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ============================================================================
# Test: get_prompt function
# ============================================================================

test_get_prompt_from_env() {
    print_section "Test: get_prompt from environment variable"

    local test_dir=$(create_temp_dir)
    local test_prompt="Test prompt from env"

    # Test with RALPH_PROMPT set
    # Export variables so they're available in the subshell
    # Set MAX_ROUNDS=0 to prevent main loop from running
    export RALPH_PROMPT="$test_prompt"
    export RALPH_PROMPT_FILE=""
    export PROMPT_FILE="$test_dir/prompt.md"
    export MAX_ROUNDS=0

    local result
    result=$(bash -c "source '$RALPH_SCRIPT'; get_prompt" 2>/dev/null)

    unset RALPH_PROMPT RALPH_PROMPT_FILE PROMPT_FILE MAX_ROUNDS

    assert_contains "$result" "$test_prompt" "Should return prompt from environment variable"

    rm -rf "$test_dir"
}

test_get_prompt_from_file() {
    print_section "Test: get_prompt from file"

    local test_dir=$(create_temp_dir)
    local test_prompt="Test prompt from file"
    echo "$test_prompt" > "$test_dir/custom-prompt.md"

    # Test with RALPH_PROMPT_FILE set
    # Export variables so they're available in the subshell
    # Set MAX_ROUNDS=0 to prevent main loop from running
    export RALPH_PROMPT=""
    export RALPH_PROMPT_FILE="$test_dir/custom-prompt.md"
    export PROMPT_FILE="$test_dir/prompt.md"
    export MAX_ROUNDS=0

    local result
    result=$(bash -c "source '$RALPH_SCRIPT'; get_prompt" 2>/dev/null)

    unset RALPH_PROMPT RALPH_PROMPT_FILE PROMPT_FILE MAX_ROUNDS

    assert_contains "$result" "$test_prompt" "Should return prompt from file"

    rm -rf "$test_dir"
}

test_get_prompt_default() {
    print_section "Test: get_prompt from default file"

    local test_dir=$(create_temp_dir)
    local test_prompt="Test prompt default"
    echo "$test_prompt" > "$test_dir/prompt.md"

    # Test with default prompt file
    # Export variables so they're available in the subshell
    # Set MAX_ROUNDS=0 to prevent main loop from running
    export RALPH_PROMPT=""
    export RALPH_PROMPT_FILE=""
    export PROMPT_FILE="$test_dir/prompt.md"
    export MAX_ROUNDS=0

    local result
    result=$(bash -c "source '$RALPH_SCRIPT'; get_prompt" 2>/dev/null)

    unset RALPH_PROMPT RALPH_PROMPT_FILE PROMPT_FILE MAX_ROUNDS

    assert_contains "$result" "$test_prompt" "Should return prompt from default file"

    rm -rf "$test_dir"
}

# ============================================================================
# Test: sanitize_for_heredoc function
# ============================================================================

test_sanitize_heredoc() {
    print_section "Test: sanitize_for_heredoc"

    local content="Test content with EOF marker"
    local sanitized=$(echo "$content" | bash -c "source '$RALPH_SCRIPT' 2>/dev/null; sanitize_for_heredoc" 2>/dev/null)

    assert_not_contains "$sanitized" "EOF" "Should replace EOF marker"
}

test_sanitize_multiple_eof() {
    print_section "Test: sanitize_for_heredoc with multiple EOF"

    local content="EOF some content EOF more content EOF"
    local sanitized=$(echo "$content" | bash -c "source '$RALPH_SCRIPT' 2>/dev/null; sanitize_for_heredoc" 2>/dev/null)

    local eof_count=$(echo "$sanitized" | grep -c "EOF" || echo "0")
    assert_equal "0" "$eof_count" "All EOF markers should be replaced"
}

# ============================================================================
# Test: get_validation_status function
# ============================================================================

test_get_validation_status_pass() {
    print_section "Test: get_validation_status - PASS"

    local result="<validation_status>PASS</validation_status>"
    local status=$(echo "$result" | bash -c "source '$RALPH_SCRIPT' 2>/dev/null; get_validation_status" 2>/dev/null)

    assert_equal "PASS" "$status" "Should extract PASS status"
}

test_get_validation_status_fail() {
    print_section "Test: get_validation_status - FAIL"

    local result="<validation_status>FAIL</validation_status>"
    local status=$(echo "$result" | bash -c "source '$RALPH_SCRIPT' 2>/dev/null; get_validation_status" 2>/dev/null)

    assert_equal "FAIL" "$status" "Should extract FAIL status"
}

test_get_validation_status_empty() {
    print_section "Test: get_validation_status - empty"

    local result=""
    local status=$(echo "$result" | bash -c "source '$RALPH_SCRIPT' 2>/dev/null; get_validation_status" 2>/dev/null)

    assert_empty "$status" "Should return empty for no status"
}

# ============================================================================
# Test: get_validation_issues function
# ============================================================================

test_get_validation_issues() {
    print_section "Test: get_validation_issues"

    local result="<validation_issues>\n- Issue 1\n- Issue 2\n</validation_issues>"
    local issues=$(echo -e "$result" | bash -c "source '$RALPH_SCRIPT' 2>/dev/null; get_validation_issues" 2>/dev/null)

    assert_contains "$issues" "Issue 1" "Should extract issue 1"
    assert_contains "$issues" "Issue 2" "Should extract issue 2"
}

# ============================================================================
# Test: get_validation_recommendations function
# ============================================================================

test_get_validation_recommendations() {
    print_section "Test: get_validation_recommendations"

    local result="<validation_recommendations>\n- Fix 1\n- Fix 2\n</validation_recommendations>"
    local recs=$(echo -e "$result" | bash -c "source '$RALPH_SCRIPT' 2>/dev/null; get_validation_recommendations" 2>/dev/null)

    assert_contains "$recs" "Fix 1" "Should extract recommendation 1"
    assert_contains "$recs" "Fix 2" "Should extract recommendation 2"
}

# ============================================================================
# Test: validate_max_rounds function
# ============================================================================

test_validate_max_rounds_valid() {
    print_section "Test: validate_max_rounds - valid input"

    local result=$(MAX_ROUNDS=10 bash -c "source '$RALPH_SCRIPT' 2>/dev/null; validate_max_rounds" 2>&1)
    assert_success $? "Should accept valid number"
}

test_validate_max_rounds_zero() {
    print_section "Test: validate_max_rounds - zero"

    local result=$(MAX_ROUNDS=0 bash -c "source '$RALPH_SCRIPT' 2>/dev/null; validate_max_rounds" 2>&1) || true
    assert_contains "$result" "greater than 0" "Should reject zero"
}

test_validate_max_rounds_negative() {
    print_section "Test: validate_max_rounds - negative"

    local result=$(MAX_ROUNDS=-5 bash -c "source '$RALPH_SCRIPT' 2>/dev/null; validate_max_rounds" 2>&1) || true
    assert_contains "$result" "positive integer" "Should reject negative"
}

test_validate_max_rounds_string() {
    print_section "Test: validate_max_rounds - string"

    local result=$(MAX_ROUNDS="abc" bash -c "source '$RALPH_SCRIPT' 2>/dev/null; validate_max_rounds" 2>&1) || true
    assert_contains "$result" "positive integer" "Should reject string"
}

# ============================================================================
# Test: refactor_progress function
# ============================================================================

test_refactor_progress_small_file() {
    print_section "Test: refactor_progress - small file"

    local test_dir=$(create_temp_dir)
    cd "$test_dir"

    echo "# Progress" > progress.md
    echo "## Iteration 1" >> progress.md
    echo "Done" >> progress.md

    # Mock grep to return small line count
    local result
    result=$(bash -c "source '$RALPH_SCRIPT' 2>/dev/null; refactor_progress" 2>/dev/null)

    assert_contains "$result" "within acceptable limits" "Should not refactor small file"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir"
}

# ============================================================================
# Test: Configuration display
# ============================================================================

test_display_config() {
    print_section "Test: display_config output"

    local output=$(bash -c "source '$RALPH_SCRIPT' 2>/dev/null; display_config" 2>/dev/null)

    assert_contains "$output" "RalphLoop Configuration" "Should show configuration header"
    assert_contains "$output" "Timeout" "Should show timeout setting"
    assert_contains "$output" "Max Iterations" "Should show max iterations"
}

# ============================================================================
# Main test runner
# ============================================================================

run_unit_tests() {
    print_header "Unit Tests - Script Functions"

    # Setup
    setup_test_environment

    # Run tests
    test_get_prompt_from_env
    test_get_prompt_from_file
    test_get_prompt_default

    test_sanitize_heredoc
    test_sanitize_multiple_eof

    test_get_validation_status_pass
    test_get_validation_status_fail
    test_get_validation_status_empty

    test_get_validation_issues
    test_get_validation_recommendations

    test_validate_max_rounds_valid
    test_validate_max_rounds_zero
    test_validate_max_rounds_negative
    test_validate_max_rounds_string

    test_refactor_progress_small_file
    test_display_config

    # Teardown
    teardown_test_environment

    print_test_summary
}

# Run tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    export VERBOSE="${VERBOSE:-false}"
    run_unit_tests
fi
