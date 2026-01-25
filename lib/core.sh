#!/usr/bin/env bash

# lib/core.sh - Core constants, configuration, and utilities
# Part of RalphLoop modular refactoring
#
# Purpose:
#   Provides foundational configuration, constants, and utility functions
#   used across all RalphLoop modules. This module has no dependencies.
#
# Key Responsibilities:
#   - Configuration variables (timeouts, memory limits, logging)
#   - Temporary file management
#   - Signal handling and cleanup
#   - Cache and session directory management
#   - Validation agent configuration
#
# Usage:
#   This module is sourced first by lib.sh before all other modules.
#   All variables and functions defined here are available globally.
#
# Related Files:
#   - lib.sh: Sources this module first in dependency order
#   - lib/sessions.sh: Uses get_ralph_sessions_dir() and generate_session_id()
#   - lib/exec.sh: Uses get_validation_agent() and cleanup()

# =============================================================================
# Configuration Variables
# =============================================================================

# Default iterations (from environment only - set from args in bin/ralph after parsing)
MAX_ROUNDS=${MAX_ROUNDS:-100}

# Temporary file management
TEMP_FILE="$(mktemp)"
TEMP_FILE_PREFIX="${TEMP_FILE}_ralph"
PROGRESS_FILE="${TEMP_FILE_PREFIX}_progress.md"
PROMPT_FILE="${TEMP_FILE_PREFIX}_prompt.md"
VALIDATION_ISSUES_FILE="${TEMP_FILE_PREFIX}_issues.md"
OUTPUT_FILE="${TEMP_FILE_PREFIX}_output.txt"

# Backends directory
BACKENDS_DIR="backends"

# Timeout and memory configuration (customizable via environment)
RALPH_TIMEOUT=${RALPH_TIMEOUT:-1800}              # Default: 30 minutes in seconds
RALPH_MEMORY_LIMIT=${RALPH_MEMORY_LIMIT:-4194304} # Default: 4GB in KB

# OpenCode logging configuration
RALPH_LOG_LEVEL=${RALPH_LOG_LEVEL:-WARN}    # Default: WARN to avoid too much output
RALPH_PRINT_LOGS=${RALPH_PRINT_LOGS:-false} # Default: false (logs to file instead)

# =============================================================================
# Session Tracking Variables (initialized before trap)
# =============================================================================

SESSION_ID=""
RESUME_ORIGINAL_DIR=""
OPENCODE_PID=""       # PID of background opencode process for signal handling
PROMPT_ACCEPTED=false # Flag to track if prompt has been accepted

# =============================================================================
# Ralph's Execution Context
# =============================================================================

# Ralph's execution context - added to user's prompt at runtime
RALPH_PROMPTS='
## Your Priorities

### Phase 1: ANALYZE

0. [ ] Validate initial existing issues and address them accordingly
1. [ ] Read and understand the project plan and acceptance criteria
2. [ ] Read progress.md to understand current state
3. [ ] Identify the highest priority next step that makes measurable progress

### Phase 2: PLAN & VALIDATE

4. [ ] Break down the goal into verifiable tasks
5. [ ] Define what "done" looks like for each task
6. [ ] Identify how you will verify completion (builds, tests, manual checks)

### Phase 3: EXECUTE & VERIFY

7. [ ] Implement the task
8. [ ] Run verification checks:
   - [ ] Code compiles/builds without errors
   - [ ] Tests pass (if applicable)
   - [ ] No linting errors
   - [ ] Changes meet acceptance criteria
9. [ ] Fix any issues found before proceeding

### Phase 4: DOCUMENT & COMMIT

10. [ ] Update progress.md with accomplishments
11. [ ] Create meaningful git commit
12. [ ] Identify next improvements

## Verification Requirements

BEFORE marking a task complete, you MUST verify:

- [ ] Build: Code compiles/runs successfully
- [ ] Tests: Unit tests pass (or state why not applicable)
- [ ] Linting: Code passes style checks
- [ ] Requirements: Feature meets acceptance criteria
- [ ] Integration: Works with existing code
- [ ] No Regressions: Existing functionality intact
- [ ] MUST ENSURE A CLEAN WORKSPACE, update gitignore and sort remaining files to their destination

## Constraints

- [ ] Only work on ONE goal per iteration
- [ ] NEVER skip verification steps
- [ ] Always run tests before committing

## Success Criteria

The loop succeeds when:

- [ ] Git history shows regular commits
- [ ] Progress tracking is current
- [ ] Verification checklist is completed
- [ ] Measurable progress made toward goal

If the current goal is complete, output <promise>COMPLETE</promise>
'

# =============================================================================
# Cleanup and Signal Handling
# =============================================================================

# Cleanup function for graceful termination
# Handles SIGINT (Ctrl+C) and SIGTERM signals to ensure clean shutdown.
# Terminates the OpenCode process, saves session state if applicable,
# and removes all temporary files created during execution.
#
# Purpose:
#   Provides graceful shutdown handling for interrupted pipeline runs.
#   Saves session state to enable later resumption of interrupted work.
#
# Behavior:
#   - Terminates OpenCode process with SIGTERM, then SIGKILL if needed
#   - Saves session state if prompt was accepted or session exists
#   - Removes all temporary files with TEMP_FILE_PREFIX pattern
#
# Usage:
#   Automatically called via trap when signals are received.
#   Can also be called directly for controlled shutdown.
cleanup() {
  echo "" >&2
  echo "🛑 Caught signal - initiating graceful shutdown..." >&2

  # Kill opencode process if running
  if [ -n "$OPENCODE_PID" ] && kill -0 "$OPENCODE_PID" 2>/dev/null; then
    echo "   Terminating opencode process (PID: $OPENCODE_PID)..." >&2
    kill -TERM "$OPENCODE_PID" 2>/dev/null || true

    # Wait briefly for graceful shutdown, then force kill if still running
    local count=0
    while kill -0 "$OPENCODE_PID" 2>/dev/null && [ $count -lt 5 ]; do
      sleep 1
      count=$((count + 1))
    done

    # Force kill if process is still running after 5 seconds
    if kill -0 "$OPENCODE_PID" 2>/dev/null; then
      echo "   Process still running - sending SIGKILL..." >&2
      kill -9 "$OPENCODE_PID" 2>/dev/null || true
    fi
  fi

  # Clean up temp files
  echo "   Cleaning up temporary files..." >&2
  rm -f "${TEMP_FILE_PREFIX}"* 2>/dev/null || true

  # Save session state if we have one AND prompt was accepted OR session already existed
  # These functions are defined in sessions.sh, which may not be loaded yet
  if [ -n "$SESSION_ID" ] && [ "$PROMPT_ACCEPTED" = true ]; then
    if command -v save_session &>/dev/null; then
      echo "   Saving session state..." >&2
      save_session "$SESSION_ID" 0 "$MAX_ROUNDS" 2>/dev/null || true
    fi
  elif [ -n "$SESSION_ID" ] && command -v get_session_dir &>/dev/null && [ -d "$(get_session_dir "$SESSION_ID")" ]; then
    # Also save if session directory already exists (resumed sessions)
    if command -v save_session &>/dev/null; then
      echo "   Saving existing session state..." >&2
      save_session "$SESSION_ID" 0 "$MAX_ROUNDS" 2>/dev/null || true
    fi
  fi

  echo "   Shutdown complete." >&2
}

# Check if exit code indicates signal termination
# Converts exit codes greater than 128 to their corresponding signal name.
#
# Purpose:
#   Identifies which signal caused process termination for better error reporting.
#
# Arguments:
#   $1 - Exit code to check
#
# Returns:
#   Signal name (SIGHUP, SIGINT, SIGQUIT, SIGTERM, or "Signal N") or empty if not signal
#
# Example:
#   signal=$(check_signal_termination $?)
check_signal_termination() {
  local exit_code=$1

  # Check for signal termination (128 + signal number)
  if [ $exit_code -gt 128 ]; then
    local signal_num=$((exit_code - 128))
    case $signal_num in
    1) echo "SIGHUP" ;;
    2) echo "SIGINT" ;;
    3) echo "SIGQUIT" ;;
    15) echo "SIGTERM" ;;
    *) echo "Signal $signal_num" ;;
    esac
  fi
}

# Sanitize content for heredoc to prevent variable expansion
# Escapes dollar signs and backticks to prevent shell expansion in heredocs.
#
# Purpose:
#   Allows safe embedding of content containing shell variables or commands
#   into heredoc blocks without unintended expansion.
#
# Arguments:
#   $1 - Content to sanitize
#
# Returns:
#   Sanitized content with $ and ` characters escaped
#
# Example:
#   safe_content=$(sanitize_for_heredoc "User: $HOME")
sanitize_for_heredoc() {
  local content="$1"
  # Escape $ and ` to prevent expansion in heredoc
  echo "$content" | sed 's/\$/\\$/g' | sed 's/`/\\`/g'
}

# =============================================================================
# Configuration Functions
# =============================================================================

# Get the user's preferred editor
# Checks VISUAL then EDITOR environment variables, falls back to vi.
#
# Purpose:
#   Provides a consistent way to determine the user's preferred text editor
#   for interactive prompt editing sessions.
#
# Returns:
#   Editor command to use (VISUAL > EDITOR > vi)
#
# Example:
#   editor=$(get_editor)
#   $editor prompt.md
get_editor() {
  if [ -n "${VISUAL:-}" ]; then
    echo "$VISUAL"
  elif [ -n "${EDITOR:-}" ]; then
    echo "$EDITOR"
  else
    echo "vi"
  fi
}

# Validate max rounds is a positive integer
# Ensures MAX_ROUNDS environment variable is a valid positive integer.
#
# Purpose:
#   Validates that the iteration count is valid before starting execution.
#
# Sets:
#   MAX_ROUNDS - Validated iteration count (from environment or default)
#
# Returns:
#   0 if valid, 1 otherwise with error message printed to stderr
#
# Example:
#   validate_max_rounds || exit 1
validate_max_rounds() {
  if [[ -z "$MAX_ROUNDS" || ! "$MAX_ROUNDS" =~ ^[0-9]+$ ]]; then
    echo "Error: MAX_ROUNDS must be a positive integer"
    return 1
  fi
  if [ "$MAX_ROUNDS" -lt 1 ]; then
    echo "Error: MAX_ROUNDS must be at least 1"
    return 1
  fi
  return 0
}

# =============================================================================
# Cache and Session Directory Functions
# =============================================================================

# Get the Ralph cache directory for storing prompts
# Creates the directory if it doesn't exist. Uses XDG_CACHE_HOME if set.
#
# Purpose:
#   Provides a consistent location for storing prompt cache files.
#
# Returns:
#   Path to the prompts cache directory
#
# Example:
#   cache_dir=$(get_ralph_cache_dir)
get_ralph_cache_dir() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ralph/prompts"
  mkdir -p "$cache_dir"
  echo "$cache_dir"
}

# Get the Ralph sessions directory
# Creates the directory if it doesn't exist. Uses XDG_CACHE_HOME if set.
#
# Purpose:
#   Provides a consistent location for storing session state files.
#
# Returns:
#   Path to the sessions directory
#
# Example:
#   sessions_dir=$(get_ralph_sessions_dir)
get_ralph_sessions_dir() {
  local sessions_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ralph/sessions"
  mkdir -p "$sessions_dir"
  echo "$sessions_dir"
}

# Get sanitized directory name for session filename
# Converts the current directory name to a safe filename by replacing
# special characters with underscores.
#
# Purpose:
#   Creates safe directory names for session filenames by sanitizing
#   the current working directory name.
#
# Returns:
#   Sanitized directory name suitable for filenames
#
# Example:
#   safe_name=$(get_sanitized_dirname)  # "My Project" -> "My_Project"
get_sanitized_dirname() {
  local dir_name
  dir_name=$(basename "$PWD")
  # Replace spaces and special chars with underscores
  echo "${dir_name//[^a-zA-Z0-9_-]/_}"
}

# Generate a unique session ID based on directory and timestamp
# Combines sanitized directory name with current timestamp.
#
# Purpose:
#   Creates globally unique identifiers for session tracking.
#
# Returns:
#   Unique session ID in format: "directory_YYYYMMDD-HHMMSS"
#
# Example:
#   session_id=$(generate_session_id)  # "myproject_20250125-143022"
generate_session_id() {
  local dir_name
  dir_name=$(get_sanitized_dirname)
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  echo "${dir_name}_${ts}"
}

# =============================================================================
# Validation Agent Configuration
# =============================================================================

# Get the validation agent to use for validation tasks
# Implements priority cascade: RALPH_AGENT_VALIDATION > RALPH_AGENT > AGENT_RALPH
#
# Purpose:
#   Determines which agent configuration to use for validation stage.
#   Allows separate validation agent from execution agent.
#
# Environment Variables:
#   RALPH_AGENT_VALIDATION - Primary validation agent (highest priority)
#   RALPH_AGENT - Fallback validation agent
#   AGENT_RALPH - Default validation agent (lowest priority)
#
# Returns:
#   Agent configuration string to use for validation
#
# Example:
#   validation_agent=$(get_validation_agent)
#   # Returns: "opencode:gpt-4" (or whatever is configured)
get_validation_agent() {
  if [ -n "${RALPH_AGENT_VALIDATION:-}" ]; then
    # RALPH_AGENT_VALIDATION is set, use it for validation
    echo "$RALPH_AGENT_VALIDATION"
  elif [ -n "${RALPH_AGENT:-}" ]; then
    # RALPH_AGENT_VALIDATION not set, fall back to RALPH_AGENT
    # Log the fallback behavior for transparency
    if [ -z "${RALPH_AGENT_VALIDATION:-}" ]; then
      echo "ℹ️  RALPH_AGENT_VALIDATION not set, falling back to RALPH_AGENT for validation" >&2
    fi
    echo "$RALPH_AGENT"
  else
    # Neither is set, use default
    echo "AGENT_RALPH"
  fi
}
