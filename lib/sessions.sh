#!/usr/bin/env bash

# lib/sessions.sh - Session management functions
# Depends on: core.sh

# =============================================================================
# Session Directory Functions
# =============================================================================

# Get session directory for a specific session ID
get_session_dir() {
  local session_id="$1"
  local sessions_dir
  sessions_dir=$(get_ralph_sessions_dir)
  echo "${sessions_dir}/${session_id}"
}

# Get the session prompt file path (stores path to current session's prompt)
get_session_prompt_marker() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ralph"
  mkdir -p "$cache_dir"
  echo "${cache_dir}/.session_prompt_$$"
}

# =============================================================================
# Session State Management
# =============================================================================

# Save current session state with optional pipeline metadata
save_session() {
  local session_id="$1"
  local iteration="$2"
  local max_iterations="$3"
  local user_prompt_file="${4:-}" # Optional: path to user's original prompt
  local pipeline_name="${5:-${PIPELINE_NAME:-default}}"
  local pipeline_stage="${6:-${PIPELINE_CURRENT_STAGE:-}}"
  local pipeline_iteration="${7:-${PIPELINE_CURRENT_ITERATION:-0}}"
  local pipeline_config="${8:-${RALPH_PIPELINE_CONFIG:-pipeline.yaml}}"
  local session_dir created_at

  session_dir=$(get_session_dir "$session_id")
  mkdir -p "$session_dir"

  # Preserve original creation time if session already exists
  if [ -f "${session_dir}/session.json" ]; then
    created_at=$(grep '"created_at"' "${session_dir}/session.json" | sed 's/.*"\([^"]*\)".*/\1/')
  else
    created_at=$(date -Iseconds)
  fi

  # Save session metadata with extended schema for pipeline support
  cat >"${session_dir}/session.json" <<EOF
{
  "session_id": "${session_id}",
  "directory": "${PWD}",
  "created_at": "${created_at}",
  "iteration": ${iteration},
  "max_iterations": ${max_iterations},
  "status": "incomplete",
  "pipeline_name": "${pipeline_name}",
  "pipeline_stage": "${pipeline_stage}",
  "pipeline_iteration": ${pipeline_iteration},
  "pipeline_config": "${pipeline_config}",
  "has_pipeline_state": $([ -f "${session_dir}/pipeline_state.txt" ] && echo "true" || echo "false")
}
EOF

  # Save user's original prompt (pure, unmodified)
  if [ -n "$user_prompt_file" ] && [ -f "$user_prompt_file" ]; then
    cp "$user_prompt_file" "${session_dir}/prompt.md"
  fi

  # Save Ralph's prompts separately (for transparency and resuming)
  if [ -n "${RALPH_PROMPTS:-}" ]; then
    echo "$RALPH_PROMPTS" >"${session_dir}/ralph-prompts.md"
  fi

  # Save progress file
  if [ -f "$PROGRESS_FILE" ]; then
    cp "$PROGRESS_FILE" "${session_dir}/progress.md"
  fi

  # Save validation issues separately
  if [ -f "$VALIDATION_ISSUES_FILE" ]; then
    cp "$VALIDATION_ISSUES_FILE" "${session_dir}/issues.md"
  fi

  # Save pipeline state to session directory
  save_pipeline_to_session "$session_dir"

  # Create incomplete marker
  touch "${session_dir}/.incomplete"

  echo "💾 Session saved: $session_id"
}

# Mark session as complete
complete_session() {
  local session_id="$1"
  local session_dir
  session_dir=$(get_session_dir "$session_id")

  if [ -d "$session_dir" ]; then
    rm -f "${session_dir}/.incomplete"
    # Update status metadata
    if [ -f "${session_dir}/session.json" ]; then
      sed -i 's/"status": "incomplete"/"status": "complete"/' "${session_dir}/session.json" 2>/dev/null ||
        sed -i '' 's/"status": "incomplete"/"status": "complete"/' "${session_dir}/session.json"
    fi
    echo "✅ Session completed: $session_id"
  fi
}

# Mark session as failed
fail_session() {
  local session_id="$1"
  local session_dir
  session_dir=$(get_session_dir "$session_id")

  if [ -d "$session_dir" ]; then
    # Update status in metadata
    if [ -f "${session_dir}/session.json" ]; then
      sed -i 's/"status": "incomplete"/"status": "failed"/' "${session_dir}/session.json" 2>/dev/null ||
        sed -i '' 's/"status": "incomplete"/"status": "failed"/' "${session_dir}/session.json"
    fi
    echo "❌ Session failed: $session_id"
  fi
}

# =============================================================================
# Session Listing and Management
# =============================================================================

# List all sessions with optional directory filter
list_sessions() {
  local filter_dir="${1:-}"
  local sessions_dir
  sessions_dir=$(get_ralph_sessions_dir)

  if [ ! -d "$sessions_dir" ] || [ -z "$(ls -A "$sessions_dir" 2>/dev/null)" ]; then
    echo "No sessions found."
    return 0
  fi

  echo "========================================"
  echo "📂 RalphLoop Sessions"
  echo "========================================"
  if [ -n "$filter_dir" ]; then
    echo "   Filter: $filter_dir"
  fi
  echo ""

  local count=0
  while IFS= read -r session_dir; do
    local session_id
    session_id=$(basename "$session_dir")

    # Read session metadata
    local status="unknown"
    local iteration="?"
    local directory="?"
    local created="?"
    local pipeline_stage="?"
    local has_pipeline_state="false"

    if [ -f "${session_dir}/session.json" ]; then
      status=$(grep '"status"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
      iteration=$(grep '"iteration"' "${session_dir}/session.json" | sed 's/.*: *\([0-9]*\).*/\1/')
      directory=$(grep '"directory"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
      created=$(grep '"created_at"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/' | cut -d'T' -f1)
      pipeline_stage=$(grep '"pipeline_stage"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
      has_pipeline_state=$(grep '"has_pipeline_state"' "${session_dir}/session.json" | sed 's/.*: *\(true\|false\).*/\1/')
    fi

    # Apply directory filter
    if [ -n "$filter_dir" ] && [ "$directory" != "$filter_dir" ]; then
      continue
    fi

    # Check for incomplete marker
    local incomplete_marker=""
    if [ -f "${session_dir}/.incomplete" ]; then
      incomplete_marker=" [INCOMPLETE]"
    fi

    # Status icon
    local icon="📄"
    case "$status" in
    complete) icon="✅" ;;
    failed) icon="❌" ;;
    incomplete) icon="⏳" ;;
    esac

    # Pipeline state indicator
    local pipeline_info=""
    if [ "$has_pipeline_state" = "true" ] && [ -n "$pipeline_stage" ]; then
      pipeline_info=" (stage: $pipeline_stage)"
    fi

    printf "%s %s%s\n" "$icon" "$session_id" "$incomplete_marker"
    printf "   📁 %s\n" "$directory"
    printf "   📊 Iteration: %s | Created: %s%s\n" "$iteration" "$created" "$pipeline_info"
    echo ""

    count=$((count + 1))
  done < <(find "$sessions_dir" -mindepth 1 -maxdepth 1 -type d | sort -r)

  echo "-----------------------------------"
  echo "Total sessions: $count"
  echo ""
  echo "Resume a session: ./ralph --resume <session_id>"
  echo "Clean up sessions: ./ralph --cleanup"
}

# List sessions filtered by directory (convenience function)
list_sessions_filtered() {
  local filter_dir="${1:-$(pwd)}"
  list_sessions "$filter_dir"
}

# Cleanup old sessions (remove incomplete ones older than specified days)
cleanup_sessions() {
  local days="${1:-7}"
  local sessions_dir
  sessions_dir=$(get_ralph_sessions_dir)

  if [ ! -d "$sessions_dir" ]; then
    echo "No sessions to clean up."
    return 0
  fi

  local count=0
  local deleted=0

  while IFS= read -r session_dir; do
    local session_id
    session_id=$(basename "$session_dir")

    # Only remove incomplete sessions
    if [ -f "${session_dir}/.incomplete" ]; then
      # Check age
      local age
      age=$(find "$session_dir" -type f -mtime +${days} 2>/dev/null | wc -l)

      if [ "$age" -gt 0 ]; then
        rm -rf "$session_dir"
        echo "🗑️  Deleted incomplete session: $session_id (older than ${days} days)"
        deleted=$((deleted + 1))
      fi
    fi

    count=$((count + 1))
  done < <(find "$sessions_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

  echo ""
  echo "Cleaned up $deleted incomplete sessions."
}

# =============================================================================
# Session Resumption
# =============================================================================

# Resume a specific session
resume_session() {
  local session_id="$1"
  local session_dir
  session_dir=$(get_session_dir "$session_id")

  if [ ! -d "$session_dir" ]; then
    echo "❌ Session not found: $session_id"
    return 1
  fi

  if [ ! -f "${session_dir}/session.json" ]; then
    echo "❌ Session metadata not found: $session_id"
    return 1
  fi

  # Read session metadata
  local iteration max_iterations directory
  iteration=$(grep '"iteration"' "${session_dir}/session.json" | sed 's/.*: *\([0-9]*\).*/\1/')
  max_iterations=$(grep '"max_iterations"' "${session_dir}/session.json" | sed 's/.*: *\([0-9]*\).*/\1/')
  directory=$(grep '"directory"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/')

  # Save original directory globally for later use
  RESUME_ORIGINAL_DIR="$directory"

  # Check if we're in the right directory
  if [ "$directory" != "$(pwd)" ]; then
    echo "⚠️  Warning: Session was created in different directory:" >&2
    echo "   Session: $directory" >&2
    echo "   Current: $(pwd)" >&2
    echo "" >&2
    echo "You may need to cd to the correct directory first." >&2
    echo "" >&2
  fi

  # Restore files to temp locations
  # Copy prompt file if it exists in session dir
  if [ -f "${session_dir}/prompt.md" ]; then
    cp "${session_dir}/prompt.md" "${TEMP_FILE_PREFIX}_prompt.md"
  elif [ -f "${directory}/prompt.md" ]; then
    # Fallback: copy from original session directory
    cp "${directory}/prompt.md" "${TEMP_FILE_PREFIX}_prompt.md"
  fi

  if [ -f "${session_dir}/progress.md" ]; then
    cp "${session_dir}/progress.md" "$PROGRESS_FILE"
  fi

  if [ -f "${session_dir}/issues.md" ]; then
    cp "${session_dir}/issues.md" "$VALIDATION_ISSUES_FILE"
  fi

  echo "🔄 Resuming session: $session_id" >&2
  echo "   Directory: $directory" >&2
  echo "   Starting from iteration: $iteration" >&2
  echo "   Max iterations: $max_iterations" >&2
  echo "" >&2

  # Return the iteration to resume from
  echo "$iteration"
}

# =============================================================================
# Pipeline State Management
# =============================================================================

# Save pipeline state and config to session directory
save_pipeline_to_session() {
  local session_id="$1"
  local session_dir
  session_dir=$(get_session_dir "$session_id")

  # Save pipeline state file
  if [ -f "$PIPELINE_STATE_FILE" ]; then
    cp "$PIPELINE_STATE_FILE" "${session_dir}/pipeline_state.txt"
  fi

  # Copy pipeline config file to session directory (always, if exists)
  local config_file="${RALPH_PIPELINE_CONFIG:-pipeline.yaml}"
  if [ -f "$config_file" ]; then
    cp "$config_file" "${session_dir}/pipeline_config.yaml"
  fi

  # Update session.json with current pipeline state
  if [ -f "${session_dir}/session.json" ]; then
    local current_stage="${PIPELINE_CURRENT_STAGE:-}"
    local current_iteration="${PIPELINE_CURRENT_ITERATION:-0}"

    # Update pipeline fields in session.json using sed
    sed -i "s/\"pipeline_stage\": *\"[^\"]*\"/\"pipeline_stage\": \"${current_stage}\"/" "${session_dir}/session.json" 2>/dev/null ||
      sed -i '' "s/\"pipeline_stage\": *\"[^\"]*\"/\"pipeline_stage\": \"${current_stage}\"/" "${session_dir}/session.json"
    sed -i "s/\"pipeline_iteration\": *[0-9]*/\"pipeline_iteration\": ${current_iteration}/" "${session_dir}/session.json" 2>/dev/null ||
      sed -i '' "s/\"pipeline_iteration\": *[0-9]*/\"pipeline_iteration\": ${current_iteration}/" "${session_dir}/session.json"

    # Mark as having pipeline state
    sed -i 's/"has_pipeline_state": *false/"has_pipeline_state": true/' "${session_dir}/session.json" 2>/dev/null ||
      sed -i '' 's/"has_pipeline_state": *false/"has_pipeline_state": true/' "${session_dir}/session.json"
  fi
}

# Load pipeline state and config from session directory
load_pipeline_from_session() {
  local session_id="$1"
  local session_dir
  session_dir=$(get_session_dir "$session_id")

  if [ ! -d "$session_dir" ]; then
    echo "❌ Session directory not found: $session_dir"
    return 1
  fi

  # Restore pipeline state file
  if [ -f "${session_dir}/pipeline_state.txt" ]; then
    cp "${session_dir}/pipeline_state.txt" "$PIPELINE_STATE_FILE"
    echo "📂 Restored pipeline state from session: $session_id"
  fi

  # Restore pipeline config file (to temp location for pipeline to load)
  if [ -f "${session_dir}/pipeline_config.yaml" ]; then
    local temp_config="${TEMP_FILE_PREFIX}_session_pipeline.yaml"
    cp "${session_dir}/pipeline_config.yaml" "$temp_config"
    export RALPH_PIPELINE_CONFIG="$temp_config"
    echo "📂 Restored pipeline config from session: $session_id"
  fi

  # Return pipeline stage info if available
  if [ -f "${session_dir}/session.json" ]; then
    grep '"pipeline_stage"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/'
  fi
}

# Resume a specific session with optional pipeline state loading
resume_session() {
  local session_id="$1"
  local load_pipeline="${2:-false}"
  local session_dir
  session_dir=$(get_session_dir "$session_id")

  if [ ! -d "$session_dir" ]; then
    echo "❌ Session not found: $session_id"
    return 1
  fi

  if [ ! -f "${session_dir}/session.json" ]; then
    echo "❌ Session metadata not found: $session_id"
    return 1
  fi

  # Read session metadata
  local iteration max_iterations directory pipeline_stage
  iteration=$(grep '"iteration"' "${session_dir}/session.json" | sed 's/.*: *\([0-9]*\).*/\1/')
  max_iterations=$(grep '"max_iterations"' "${session_dir}/session.json" | sed 's/.*: *\([0-9]*\).*/\1/')
  directory=$(grep '"directory"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
  pipeline_stage=$(grep '"pipeline_stage"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/')

  # Save original directory globally for later use
  RESUME_ORIGINAL_DIR="$directory"

  # Check if we're in the right directory
  if [ "$directory" != "$(pwd)" ]; then
    echo "⚠️  Warning: Session was created in different directory:" >&2
    echo "   Session: $directory" >&2
    echo "   Current: $(pwd)" >&2
    echo "" >&2
    echo "You may need to cd to the correct directory first." >&2
    echo "" >&2
  fi

  # Restore files to temp locations
  # Copy prompt file if it exists in session dir
  if [ -f "${session_dir}/prompt.md" ]; then
    cp "${session_dir}/prompt.md" "${TEMP_FILE_PREFIX}_prompt.md"
  elif [ -f "${directory}/prompt.md" ]; then
    # Fallback: copy from original session directory
    cp "${directory}/prompt.md" "${TEMP_FILE_PREFIX}_prompt.md"
  fi

  if [ -f "${session_dir}/progress.md" ]; then
    cp "${session_dir}/progress.md" "$PROGRESS_FILE"
  fi

  if [ -f "${session_dir}/issues.md" ]; then
    cp "${session_dir}/issues.md" "$VALIDATION_ISSUES_FILE"
  fi

  # Load pipeline state if requested
  if [ "$load_pipeline" = "true" ]; then
    load_pipeline_from_session "$session_id"
  fi

  echo "🔄 Resuming session: $session_id" >&2
  echo "   Directory: $directory" >&2
  echo "   Starting from iteration: $iteration" >&2
  echo "   Max iterations: $max_iterations" >&2
  if [ -n "$pipeline_stage" ]; then
    echo "   Pipeline stage: $pipeline_stage" >&2
  fi
  echo "" >&2

  # Return the iteration to resume from
  echo "$iteration"
}

# Check for incomplete sessions in current directory with pipeline state
check_incomplete_sessions() {
  local sessions_dir
  sessions_dir=$(get_ralph_sessions_dir)
  local current_dir
  current_dir=$(pwd)
  local found=0

  if [ ! -d "$sessions_dir" ]; then
    return 1
  fi

  while IFS= read -r session_dir; do
    local session_id
    session_id=$(basename "$session_dir")

    # Check if this session is for the current directory and is incomplete
    if [ -f "${session_dir}/.incomplete" ] && grep -q "\"directory\": *\"${current_dir}\"" "${session_dir}/session.json" 2>/dev/null; then
      # Check if session has pipeline state
      local has_pipeline_state
      has_pipeline_state=$(grep '"has_pipeline_state"' "${session_dir}/session.json" 2>/dev/null | sed 's/.*: *\(true\|false\).*/\1/')

      if [ "$has_pipeline_state" != "true" ]; then
        continue
      fi

      if [ "$found" -eq 0 ]; then
        echo "========================================"
        echo "⚠️  Incomplete pipeline session(s) found!"
        echo "========================================"
        echo ""
        found=1
      fi

      local iteration pipeline_stage
      iteration=$(grep '"iteration"' "${session_dir}/session.json" | sed 's/.*: *\([0-9]*\).*/\1/')
      pipeline_stage=$(grep '"pipeline_stage"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/')

      printf "  🔄 %s (iteration %s, stage: %s)\n" "$session_id" "$iteration" "$pipeline_stage"
    fi
  done < <(find "$sessions_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

  if [ "$found" -eq 1 ]; then
    echo ""
    echo "Resume with: ./ralph pipeline resume"
    echo "Or list all: ./ralph --sessions"
    return 0
  fi

  return 1
}

# Find the most recent incomplete session with pipeline state in current directory
find_latest_pipeline_session() {
  local sessions_dir
  sessions_dir=$(get_ralph_sessions_dir)
  local current_dir
  current_dir=$(pwd)
  local latest_session=""

  if [ ! -d "$sessions_dir" ]; then
    return 1
  fi

  while IFS= read -r session_dir; do
    local session_id
    session_id=$(basename "$session_dir")

    # Check if this session is for the current directory, is incomplete, and has pipeline state
    if [ -f "${session_dir}/.incomplete" ] && grep -q "\"directory\": *\"${current_dir}\"" "${session_dir}/session.json" 2>/dev/null; then
      local has_pipeline_state
      has_pipeline_state=$(grep '"has_pipeline_state"' "${session_dir}/session.json" 2>/dev/null | sed 's/.*: *\(true\|false\).*/\1/')

      if [ "$has_pipeline_state" = "true" ]; then
        # Use the most recent one (files are already sorted by modification time via find -sort)
        if [ -z "$latest_session" ]; then
          latest_session="$session_id"
        fi
      fi
    fi
  done < <(find "$sessions_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -r)

  if [ -n "$latest_session" ]; then
    echo "$latest_session"
    return 0
  fi

  return 1
}
