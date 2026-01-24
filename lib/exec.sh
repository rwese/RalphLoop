#!/usr/bin/env bash

# lib/exec.sh - Execution and validation loop for RalphLoop
# Depends on: core.sh, sessions.sh, prompt.sh

# =============================================================================
# Configuration and Setup
# =============================================================================

# Load opencode.jsonc and export as OPENCODE_CONFIG_CONTENT for inline override
load_opencode_config() {
  local opencode_config="${BACKENDS_DIR:-.}/opencode/opencode.jsonc"
  if [[ -f "$opencode_config" ]]; then
    echo "📄 Loading OpenCode config: $opencode_config"
    export OPENCODE_CONFIG_CONTENT=$(cat "$opencode_config")
    echo "✅ OpenCode config loaded (${#OPENCODE_CONFIG_CONTENT} bytes)"
  else
    echo "⚠️ OpenCode config not found: $opencode_config"
  fi
}

# Build opencode command with logging options
build_opencode_opts() {
  OPENCODE_OPTS=()
  if [ -n "$RALPH_LOG_LEVEL" ]; then
    OPENCODE_OPTS+=("--log-level" "$RALPH_LOG_LEVEL")
  fi
  if [ "$RALPH_PRINT_LOGS" = "true" ]; then
    OPENCODE_OPTS+=("--print-logs")
  fi
  OPENCODE_OPTS+=("--agent" "${RALPH_AGENT:-AGENT_RALPH}")
}

# Build opencode command options for validation with RALPH_AGENT_VALIDATION support
build_validation_opencode_opts() {
  VALIDATION_OPENCODE_OPTS=()
  if [ -n "$RALPH_LOG_LEVEL" ]; then
    VALIDATION_OPENCODE_OPTS+=("--log-level" "$RALPH_LOG_LEVEL")
  fi
  if [ "$RALPH_PRINT_LOGS" = "true" ]; then
    VALIDATION_OPENCODE_OPTS+=("--print-logs")
  fi
  # Use validation agent (RALPH_AGENT_VALIDATION > RALPH_AGENT > AGENT_RALPH)
  local validation_agent
  validation_agent=$(get_validation_agent)
  VALIDATION_OPENCODE_OPTS+=("--agent" "$validation_agent")

  # Log which agent is being used for validation
  if [ -n "${RALPH_AGENT_VALIDATION:-}" ]; then
    echo "🛡️ Using validation agent: $validation_agent (from RALPH_AGENT_VALIDATION)"
  else
    echo "🛡️ Using validation agent: $validation_agent (fallback from RALPH_AGENT)"
  fi
}

# Load backend configuration if available
load_backend_config() {
  if [[ -n "$RALPH_BACKEND" ]]; then
    local backend_config="${BACKENDS_DIR}/${RALPH_BACKEND}/config.jsonc"
    if [[ -f "$backend_config" ]]; then
      echo "📦 Loading backend configuration: $RALPH_BACKEND"

      # Load backend-specific settings if jq is available
      if command -v jq &>/dev/null; then
        local backend_enabled
        backend_enabled=$(jq -r '.enabled // false' "$backend_config" 2>/dev/null || echo "false")

        if [[ "$backend_enabled" == "true" ]]; then
          echo "✅ Backend '$RALPH_BACKEND' enabled and configured"
        else
          echo "⚠️ Backend '$RALPH_BACKEND' is disabled in configuration"
        fi
      fi
    else
      echo "⚠️ Backend configuration not found: $backend_config"
    fi
  fi
}

# Display configuration info
display_config() {
  echo "========================================"
  echo "⚙️  RalphLoop Configuration"
  echo "========================================"
  echo "  Timeout:        ${RALPH_TIMEOUT}s ($((RALPH_TIMEOUT / 60)) minutes)"
  echo "  Memory Limit:   ${RALPH_MEMORY_LIMIT}KB ($((RALPH_MEMORY_LIMIT / 1024 / 1024))GB)"
  echo "  Log Level:      $RALPH_LOG_LEVEL"
  echo "  Print Logs:     $RALPH_PRINT_LOGS"
  echo "  Max Iterations: $MAX_ROUNDS"
  if [ -n "$RALPH_BACKEND" ]; then
    echo "  Backend:        $RALPH_BACKEND"
    echo "  Mode:           $RALPH_MODE"
  fi
  echo "========================================"
}

# Get validation status from result
get_validation_status() {
  local result="$1"
  echo "$result" | grep -o '<validation_status>[^<]*</validation_status>' | sed 's/<[^>]*>//g' | tr -d ' '
}

# =============================================================================
# Main Execution Loop
# =============================================================================

# Run the main execution loop
run_main_loop() {
  # Set up signal handlers
  trap 'cleanup; exit 130' INT TERM

  # Load OpenCode configuration
  load_opencode_config

  # Build opencode options
  build_opencode_opts

  # Load backend configuration
  load_backend_config

  # Display configuration
  display_config

  # Validate MAX_ROUNDS
  if ! validate_max_rounds; then
    echo "❌ Invalid MAX_ROUNDS configuration"
    exit 1
  fi

  # Generate session ID for tracking (skip if already set by resume)
  if [ -z "$SESSION_ID" ]; then
    SESSION_ID=$(generate_session_id)
  fi

  # Check for existing incomplete sessions in this directory (skip when resuming)
  if [ -z "$RALPH_RESUME" ]; then
    check_incomplete_sessions || true
  fi

  echo "📁 Session ID: $SESSION_ID"
  echo ""

  # For non-interactive mode (RALPH_PROMPT set), save session immediately
  # For interactive mode, session will be saved after prompt acceptance
  if [ -n "${RALPH_PROMPT:-}" ]; then
    echo "💾 Non-interactive mode detected. Saving session..." >&2

    # Save RALPH_PROMPT to a temp file for session storage
    temp_user_prompt="${TEMP_FILE_PREFIX}_user_prompt.md"
    echo "$RALPH_PROMPT" >"$temp_user_prompt"

    save_session "$SESSION_ID" 0 "$MAX_ROUNDS" "$temp_user_prompt"
    PROMPT_ACCEPTED=true
    rm -f "$temp_user_prompt" # Clean up temp file

    echo "✅ Session saved successfully" >&2
    echo "" >&2
  fi

  # Session directory will be created when prompt is accepted
  # This ensures sessions are only saved after user confirmation

  PROMPT_CONTENT=""
  for ((i = 1; i <= MAX_ROUNDS; i++)); do
    echo "========================================"
    echo "🔄 RalphLoop Iteration $i of $MAX_ROUNDS"
    echo "========================================"

    if [ -z "$PROMPT_CONTENT" ]; then
      # Read current progress and prompt
      PROGRESS_CONTENT=$(cat "$PROGRESS_FILE")
      PROMPT_CONTENT=$(get_prompt)

      # Sanitize content to prevent heredoc injection
      SANITIZED_PROGRESS=$(sanitize_for_heredoc "$PROGRESS_CONTENT")
      SANITIZED_PROMPT=$(sanitize_for_heredoc "$PROMPT_CONTENT")
    fi

    # Check for pending validation issues from previous incomplete validation
    PENDING_ISSUES=""
    if [ -f "$VALIDATION_ISSUES_FILE" ]; then
      PENDING_ISSUES=$(cat "$VALIDATION_ISSUES_FILE")
    fi

    # Build context section with pending issues if any
    CONTEXT_SECTION=""
    if [ -n "$PENDING_ISSUES" ]; then
      CONTEXT_SECTION=$(
        cat <<CONTEXT_SECTION
## 🚨 PENDING VALIDATION ISSUES FROM PREVIOUS ITERATION
The previous completion attempt failed validation. You MUST fix these issues:

\`\`\`markdown
${PENDING_ISSUES}
\`\`\`

## Your Priority

Focus ONLY on resolving these validation issues. Do NOT work on new features.
After fixing, mark complete with <promise>COMPLETE</promise> for re-validation.
CONTEXT_SECTION
      )
    fi

    # Show progress indicator while command runs
    echo "🚀 Starting agent execution..."
    echo "   (This may take a moment. Progress will be shown below.)"
    echo ""

    # Use tee to both save to file AND display output in real-time
    # This provides feedback while ensuring output is captured for later analysis
    # Use set +e to allow opencode to fail without exiting the script
    # Signal handling via trap (see cleanup function above) provides graceful termination
    set +e
    tmp_prompt_file="${TEMP_FILE_PREFIX}_prompt.txt"
    cat >"$tmp_prompt_file" <<EOF
# Goals and Resources

## Project plan

${SANITIZED_PROMPT}

## Current Progress

${SANITIZED_PROGRESS}
${CONTEXT_SECTION}
${RALPH_PROMPTS}
EOF

    set +e # Don't exit on non-zero exit from wait
    # Run opencode in background with trap-based signal handling
    # This replaces the timeout command for better control over signals
    OPENCODE_PID=""
    opencode run "${OPENCODE_OPTS[@]}" <"$tmp_prompt_file" 2>&1 | tee "$OUTPUT_FILE" &
    OPENCODE_PID=$!

    # Wait for opencode process with proper signal handling
    # Using a loop to detect edge cases where wait returns early
    # Fixed: Ensure we always wait for the process and capture exit code correctly
    wait "$OPENCODE_PID" 2>/dev/null
    EXIT_CODE=$?
    set -e # Re-enable exit on error

    if [ $EXIT_CODE -ne 0 ]; then
      echo "⚠️  Main process exited with code: $EXIT_CODE" >&2
    fi

    # Read output from file (trap may delete the file if interrupted)
    result=$(cat "$OUTPUT_FILE" 2>/dev/null | tr -d '\0' || echo "")

    signal_name=$(check_signal_termination "$EXIT_CODE")
    if [ -n "$signal_name" ]; then
      echo ""
      echo "🛑 Process terminated by $signal_name"
      echo "   Stopping RalphLoop iterations."
      echo "========================================"
      rm -f "$OUTPUT_FILE"
      fail_session "$SESSION_ID"
      exit 130
    fi

    # Check for non-zero exit code from opencode
    if [ "$EXIT_CODE" -ne 0 ]; then
      echo "❌ ERROR: opencode command failed with exit code $EXIT_CODE" >>"$OUTPUT_FILE"
    fi

    # Check if result is empty or indicates an error
    if [ -z "$result" ]; then
      echo "⚠️ WARNING: Empty output from opencode agent - may indicate memory or execution issue"
      rm -f "$OUTPUT_FILE"
      echo "Continuing to next iteration..."
      echo ""
      continue
    fi

    # Output has already been streamed via tee, just show separator
    echo ""
    echo "--- Output complete ---"
    rm -f "$OUTPUT_FILE"

    # Check for completion
    if echo "$result" | grep -q "<promise>COMPLETE</promise>"; then
      echo ""
      echo "🛡️ Goal marked complete. Running independent validation..."
      echo "========================================"

      # Run validation prompt to verify completion criteria are truly met - stream output for real-time feedback
      # Using trap-based signal handling instead of timeout command for full control
      VALIDATION_OUTPUT_FILE="${TEMP_FILE_PREFIX}_validation.txt"

      echo "🛡️ Running independent validation..."
      echo ""

      # Build validation-specific opencode options with RALPH_AGENT_VALIDATION support
      build_validation_opencode_opts
      echo ""

      VALIDATION_PROMPT=$(
        cat <<RALPH_VALIDATE_EOF
# Validation Task

The agent previously indicated completion with <promise>COMPLETE</promise>.

You must INDEPENDENTLY VERIFY that all acceptance criteria are actually met.

## Original Project Goal (from prompt.md):
$(get_prompt_nointeractive)

## Your Validation Task:

1. READ the current state
2. CHECK each acceptance criterion is actually satisfied:
    - For each requirement, verify it exists and works
    - Run tests, build commands, and manual checks
3. RUN comprehensive verification:
    - [ ] Code compiles/builds without errors (run: npm run build or equivalent)
    - [ ] Tests pass (run: npm test or equivalent)
    - [ ] No linting errors (run: npm run lint or equivalent)
    - [ ] All acceptance criteria from prompt.md are met
    - [ ] No regressions in existing functionality
4. OUTPUT your findings in this exact XML format:

no issues found: <validation_status>PASS</validation_status>
issues fund: <validation_status>FAIL</validation_status>

<validation_issues>
- [List each failing criterion with specific details]
- Leave empty if PASS
</validation_issues>

<validation_recommendations>
- [Specific actions needed to fix each issue]
- Leave empty if PASS
</validation_recommendations>

IMPORTANT:
- If ALL checks pass, use <validation_status>PASS</validation_status>
- If ANY check fails, use <validation_status>FAIL</validation_status> and list all issues
- Do NOT trust the previous agent's assessment. Verify independently.
RALPH_VALIDATE_EOF
      )

      # Use timeout command for validation with proper signal handling
      set +e # Don't exit on error
      OPENCODE_PID=""
      opencode run "${VALIDATION_OPENCODE_OPTS[@]}" "$VALIDATION_PROMPT" 2>&1 | tee "$VALIDATION_OUTPUT_FILE" &
      OPENCODE_PID=$!

      # Wait for validation process
      wait "$OPENCODE_PID" 2>/dev/null
      VALIDATION_EXIT_CODE=$?
      set -e # Re-enable exit on error

      if [ $VALIDATION_EXIT_CODE -ne 0 ]; then
        echo "⚠️  Validation process exited with code: $VALIDATION_EXIT_CODE" >&2
      fi

      signal_name=$(check_signal_termination "$VALIDATION_EXIT_CODE")
      if [ -n "$signal_name" ]; then
        echo ""
        echo "🛑 Validation terminated by $signal_name"
        echo "   Stopping RalphLoop iterations."
        echo "========================================"
        rm -f "$VALIDATION_OUTPUT_FILE"
        fail_session "$SESSION_ID"
        exit 130
      fi

      validation_result=$(cat "$VALIDATION_OUTPUT_FILE" 2>/dev/null | tr -d '\0' || echo "")
      rm -f "$VALIDATION_OUTPUT_FILE"

      # Output has already been streamed via tee, just show completion message
      echo ""
      echo "--- Validation complete ---"

      # Extract and check validation status
      VALIDATION_STATUS=$(get_validation_status "$validation_result")

      if [ "$VALIDATION_STATUS" = "PASS" ]; then
        echo ""
        echo "🎉 Validation PASSED! RalphLoop mission complete!"
        echo "========================================"
        # Mark session as complete
        complete_session "$SESSION_ID"
        # Progress file management is delegated to the AI agent
        rm -f "$VALIDATION_ISSUES_FILE"
        exit 0
      else
        echo "⚠️ Validation FAILED. Saving issues for next iteration..."

        echo ""
        echo "📋 Validation Results:"
        echo "-----------------------------------"
        echo "$validation_result"
        echo "-----------------------------------"

        # Extract issues and recommendations for next iteration
        local issues_section
        local recommendations_section
        issues_section=$(echo "$validation_result" | grep -A 100 '<validation_issues>' | grep -B 100 '</validation_issues>' | sed 's/<[^>]*>//g' | sed 's/^-/  -/g')
        recommendations_section=$(echo "$validation_result" | grep -A 100 '<validation_recommendations>' | grep -B 100 '</validation_recommendations>' | sed 's/<[^>]*>//g' | sed 's/^-/  -/g')

        # Save issues for next iteration
        if [ -n "$issues_section" ]; then
          echo "Issues from validation:" >"$VALIDATION_ISSUES_FILE"
          echo "$issues_section" >>"$VALIDATION_ISSUES_FILE"
        fi

        echo ""
        echo "Issues saved to ${VALIDATION_ISSUES_FILE}"
        echo "Agent will prioritize fixing these in next iteration."
        echo ""
      fi
    fi

    # Save session after each iteration
    save_session "$SESSION_ID" "$i" "$MAX_ROUNDS"
    echo ""
    echo "✅ Iteration $i complete."
    echo ""
  done

  echo "========================================"
  echo "🏁 Max iterations ($MAX_ROUNDS) reached."
  echo "   RalphLoop will rest for now."
  echo "========================================"
}
