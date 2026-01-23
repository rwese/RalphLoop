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

# Save current session state
save_session() {
  local session_id="$1"
  local iteration="$2"
  local max_iterations="$3"
  local user_prompt_file="${4:-}" # Optional: path to user's original prompt
  local session_dir created_at

  session_dir=$(get_session_dir "$session_id")
  mkdir -p "$session_dir"

  # Preserve original creation time if session already exists
  if [ -f "${session_dir}/session.json" ]; then
    created_at=$(grep '"created_at"' "${session_dir}/session.json" | sed 's/.*"\([^"]*\)".*/\1/')
  else
    created_at=$(date -Iseconds)
  fi

  # Save session metadata
  cat >"${session_dir}/session.json" <<EOF
{
  "session_id": "${session_id}",
  "directory": "${PWD}",
  "created_at": "${created_at}",
  "iteration": ${iteration},
  "max_iterations": ${max_iterations},
  "status": "incomplete"
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

# List all sessions
list_sessions() {
  local sessions_dir
  sessions_dir=$(get_ralph_sessions_dir)

  if [ ! -d "$sessions_dir" ] || [ -z "$(ls -A "$sessions_dir" 2>/dev/null)" ]; then
    echo "No sessions found."
    return 0
  fi

  echo "========================================"
  echo "📂 RalphLoop Sessions"
  echo "========================================"
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

    if [ -f "${session_dir}/session.json" ]; then
      status=$(grep '"status"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
      iteration=$(grep '"iteration"' "${session_dir}/session.json" | sed 's/.*: *\([0-9]*\).*/\1/')
      directory=$(grep '"directory"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
      created=$(grep '"created_at"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/' | cut -d'T' -f1)
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

    printf "%s %s%s\n" "$icon" "$session_id" "$incomplete_marker"
    printf "   📁 %s\n" "$directory"
    printf "   📊 Iteration: %s | Created: %s\n" "$iteration" "$created"
    echo ""

    count=$((count + 1))
  done < <(find "$sessions_dir" -mindepth 1 -maxdepth 1 -type d | sort -r)

  echo "-----------------------------------"
  echo "Total sessions: $count"
  echo ""
  echo "Resume a session: ./ralph --resume <session_id>"
  echo "Clean up sessions: ./ralph --cleanup"
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

# Check for incomplete sessions in current directory
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
      if [ "$found" -eq 0 ]; then
        echo "========================================"
        echo "⚠️  Incomplete session(s) found!"
        echo "========================================"
        echo ""
        found=1
      fi

      local iteration
      iteration=$(grep '"iteration"' "${session_dir}/session.json" | sed 's/.*: *\([0-9]*\).*/\1/')
      printf "  🔄 %s (iteration %s)\n" "$session_id" "$iteration"
    fi
  done < <(find "$sessions_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

  if [ "$found" -eq 1 ]; then
    echo ""
    echo "Resume with: ./ralph --resume <session_id>"
    echo "Or list all: ./ralph --sessions"
    return 0
  fi

  return 1
}
