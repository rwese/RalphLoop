#!/usr/bin/env bash

# lib/prompt.sh - Prompt handling functions for RalphLoop
# Depends on: core.sh, sessions.sh, templates.sh, ai.sh
#
# Purpose:
#   Provides comprehensive prompt management including creation, loading,
#   and source resolution with priority cascade for RalphLoop execution.
#
# Key Responsibilities:
#   - Interactive prompt creation via editor
#   - Prompt source resolution (environment, file, session, default)
#   - Template selection and AI-enhanced prompting
#   - Session integration for prompt persistence
#
# Prompt Priority (get_prompt):
#   1. RALPH_PROMPT environment variable
#   2. RALPH_PROMPT_FILE environment variable
#   3. Session prompt marker (from current/previous interactive session)
#   4. PROMPT_FILE (from resume or default location)
#   5. Interactive creation if no prompt found
#
# Usage:
#   Sourced by lib.sh. Functions called from pipeline and exec modules.
#
# Related Files:
#   - lib/pipeline.sh: Uses get_prompt() to load prompts
#   - lib/exec.sh: Uses get_prompt() for validation context
#   - lib/templates.sh: Template functions used here

# =============================================================================
# Prompt Functions
# =============================================================================

# Launch user's editor to create a prompt interactively
# Complete workflow for interactive prompt creation with template selection.
#
# Purpose:
#   Main entry point for interactive prompt creation. Guides user through
#   template selection, content creation, and editor customization.
#
# Process:
#   1. Show template selection menu (standard, quickfix, ai, example, blank)
#   2. Generate template content based on selection
#   3. Open editor for user customization
#   4. Validate prompt was saved and modified
#   5. Save session if SESSION_ID is set
#   6. Ask for execution confirmation (unless RALPH_PROMPT is set)
#
# Environment Variables:
#   RALPH_PROMPT: If set, skips interactive confirmation
#   EDITOR: Editor to use (falls back to vi)
#   RALPH_TEMPLATE_TYPE: If set, bypasses template menu
#
# Side Effects:
#   - Creates prompt file in cache directory
#   - Updates session marker with prompt file path
#   - Saves session if SESSION_ID is set
#
# Returns:
#   Prompt content to stdout
#   Exits with error if prompt validation fails
#
# Example:
#   prompt=$(launch_editor_for_prompt)
launch_editor_for_prompt() {
  local cache_dir ts dir_name prompt_file editor original_mtime original_content new_mtime new_content
  local template_type template_content session_marker skip_editor_marker
  cache_dir=$(get_ralph_cache_dir)
  ts=$(date +%Y-%m-%d-%H%M%S)
  dir_name=$(get_sanitized_dirname)
  prompt_file="${cache_dir}/${ts}_${dir_name}.md"
  session_marker=$(get_session_prompt_marker)
  skip_editor_marker="${cache_dir}/.ai_skip_editor_$$"

  # Show template selection menu
  template_type=$(show_template_menu)

  # Get content based on selection
  case "$template_type" in
  standard)
    template_content=$(get_standard_template)
    ;;
  quickfix)
    template_content=$(get_quickfix_template)
    ;;
  ai)
    template_content=$(generate_ai_enhanced_prompt)
    ;;
  example)
    local example_path
    example_path=$(show_example_menu)
    if [ -n "$example_path" ]; then
      template_content=$(load_example_prompt "$example_path")
    else
      template_content=$(get_standard_template)
    fi
    ;;
  blank)
    template_content=$(get_blank_template)
    ;;
  *)
    template_content=$(get_standard_template)
    ;;
  esac

  # Write content to prompt file
  echo "$template_content" >"$prompt_file"

  # Capture original state for modification check
  original_content=$(cat "$prompt_file")
  # stat -f %m for macOS, stat -c %Y for Linux
  original_mtime=$(stat -f %m "$prompt_file" 2>/dev/null || stat -c %Y "$prompt_file" 2>/dev/null)

  editor=$(get_editor)
  echo "" >&2
  echo "Opening editor to customize your prompt..." >&2
  echo "Prompt will be saved to: $prompt_file" >&2

  "$editor" "$prompt_file" </dev/tty >/dev/tty

  # Check if file was modified
  new_mtime=$(stat -f %m "$prompt_file" 2>/dev/null || stat -c %Y "$prompt_file" 2>/dev/null)
  new_content=$(cat "$prompt_file")

  # Fail if file wasn't saved (mtime unchanged)
  if [ "$original_mtime" = "$new_mtime" ]; then
    echo "Error: Prompt file was not saved. Aborting." >&2
    rm -f "$prompt_file"
    exit 1
  fi

  # Fail if content is unchanged from template
  if [ "$new_content" = "$original_content" ] && [ ! "$template_type" = "ai" ]; then
    echo "Error: Prompt file was not modified from template. Aborting." >&2
    rm -f "$prompt_file"
    exit 1
  fi

  # Fail if file is empty or only whitespace
  if [ ! -s "$prompt_file" ] || ! grep -q '[^[:space:]]' "$prompt_file"; then
    echo "Error: Prompt file is empty. Aborting." >&2
    rm -f "$prompt_file"
    exit 1
  fi

  # Store the prompt file path in session marker for reuse across iterations
  echo "$prompt_file" >"$session_marker"
  echo "Prompt saved to: $prompt_file" >&2

  cat "$prompt_file"

  # Mark prompt as accepted and save session
  # This ensures sessions are only saved after user has accepted the prompt
  if [ -n "$SESSION_ID" ]; then
    echo "" >&2
    echo "💾 Saving session..." >&2
    PROMPT_ACCEPTED=true
    # Get user's original prompt file path
    user_prompt_file=$(cat "$session_marker")
    # Save session with separated files
    save_session "$SESSION_ID" 0 "$MAX_ROUNDS" "$user_prompt_file"
    echo "✅ Session saved successfully" >&2
  fi

  # Show confirmation prompt unless RALPH_PROMPT is set (non-interactive mode)
  if [ -z "${RALPH_PROMPT:-}" ]; then
    echo "" >&2
    echo "========================================" >&2
    echo "Prompt accepted. Ready to execute?" >&2
    echo "========================================" >&2
    echo "" >&2
    cat "$prompt_file"
    echo "" >&2
    echo -n "   Proceed with execution? (y/n) " >&2
    read -n 1 -r reply </dev/tty >/dev/tty
    echo "" >&2
    if [[ ! $reply =~ ^[Yy]$ ]]; then
      echo "Aborting. Run './ralph' again to restart." >&2
      exit 0
    fi
  fi

  return 0
}

# Determine prompt source and return content
# Implements priority cascade for prompt source resolution.
#
# Purpose:
#   Resolves the prompt to use for execution based on available sources
#   with clear priority ordering and appropriate user feedback.
#
# Prompt Priority:
#   1. RALPH_PROMPT environment variable (highest priority)
#   2. RALPH_PROMPT_FILE environment variable
#   3. Session prompt marker (from interactive session)
#   4. PROMPT_FILE (from resume or temp location)
#   5. Interactive creation (lowest priority)
#
# Behavior:
#   - For priorities 1-3: Returns prompt directly
#   - For priority 4 (resume): Offers to review/modify prompt
#   - For priority 5: Launches interactive prompt creation
#
# Returns:
#   Prompt content to stdout
#   Exits with error if no prompt source available
#
# Example:
#   prompt=$(get_prompt)
get_prompt() {
  local session_marker session_prompt_file response

  # Priority 1: RALPH_PROMPT environment variable
  if [ -n "${RALPH_PROMPT:-}" ]; then
    echo "Using RALPH_PROMPT" >&2
    echo "$RALPH_PROMPT"
    return
  fi

  # Priority 2: RALPH_PROMPT_FILE environment variable
  if [ -n "${RALPH_PROMPT_FILE:-}" ]; then
    if [ ! -f "$RALPH_PROMPT_FILE" ]; then
      echo "Error: RALPH_PROMPT_FILE points to a missing file: '$RALPH_PROMPT_FILE'" >&2
      exit 1
    fi
    echo "Using RALPH_PROMPT_FILE" >&2
    cat "$RALPH_PROMPT_FILE"
    return
  fi

  # Priority 3: Session prompt file (created via interactive editor this session)
  session_marker=$(get_session_prompt_marker)
  if [ -f "$session_marker" ]; then
    session_prompt_file=$(cat "$session_marker")
    if [ -f "$session_prompt_file" ]; then
      echo "Using SESSION PROMPT MARKER" >&2
      cat "$session_prompt_file"
      return
    fi
  fi

  # Priority 4: Default prompt.md file (or temp file from resume)
  if [ -f "$PROMPT_FILE" ]; then
    # When resuming, offer to review/modify the prompt
    if [ -n "$RALPH_RESUME" ]; then
      if [ -t 0 ]; then
        echo "📝 Found prompt from previous session:" >&2
        echo "" >&2
        echo "----------------------------------------" >&2
        head -20 "$PROMPT_FILE" >&2
        if [ $(wc -l <"$PROMPT_FILE") -gt 20 ]; then
          echo "   ... (more lines)" >&2
        fi
        echo "----------------------------------------" >&2
        echo "" >&2
        echo "Would you like to review and modify it before continuing?" >&2
        echo "(y/n, default: y)" >&2
        echo -n "   > " >&2
        read -r response </dev/tty >/dev/tty
        echo "" >&2
        if [[ "$response" =~ ^[Yy] ]] || [ -z "$response" ]; then
          echo "Opening editor with your prompt..." >&2
          echo "Press :wq to save and exit." >&2
          echo "" >&2
          launch_editor_for_prompt_with_file "$PROMPT_FILE"
          echo "" >&2
        fi
        echo "📝 Using modified prompt." >&2
        cat "$PROMPT_FILE"
        return
      else
        echo "Using PROMPT_FILE from resume" >&2
        cat "$PROMPT_FILE"
        return
      fi
    fi
    echo "Using PROMPT_FILE" >&2
    cat "$PROMPT_FILE"
    return
  fi

  # Priority 5: No prompt found - guide through creation
  echo "" >&2
  echo "📝 No prompt found for this session." >&2
  echo "" >&2

  # Check if we have TTY for interactive input
  if [ -t 0 ]; then
    echo "Would you like to create a new prompt?" >&2
    echo "(y/n, default: y)" >&2
    echo -n "   > " >&2
    read -r response </dev/tty >/dev/tty
    echo "" >&2
    if [[ "$response" =~ ^[Nn] ]]; then
      echo "Aborting: No prompt to work with." >&2
      exit 1
    fi
  else
    # Non-interactive: try to find prompt.md in the original directory
    if [ -n "$RESUME_ORIGINAL_DIR" ] && [ -f "${RESUME_ORIGINAL_DIR}/prompt.md" ]; then
      cp "${RESUME_ORIGINAL_DIR}/prompt.md" "$PROMPT_FILE"
      echo "Using prompt.md from session directory" >&2
      cat "$PROMPT_FILE"
      return
    fi
    echo "Error: No prompt found and running non-interactive. Aborting." >&2
    exit 1
  fi

  # Launch interactive editor with template selection
  launch_editor_for_prompt
}

# Launch editor to modify an existing prompt file
# Opens an existing prompt in the editor for review or modification.
#
# Purpose:
#   Provides capability to review and modify prompts that were
#   previously created or loaded from file.
#
# Arguments:
#   $1 - prompt_file: Path to the prompt file to modify
#
# Returns:
#   0 on success, 1 if prompt file is empty
#   Updated prompt content is saved to the file
#
# Validation:
#   - Checks if file was actually saved (mtime changed)
#   - Reverts to original content if file is empty
#
# Example:
#   launch_editor_for_prompt_with_file "/path/to/prompt.md"
launch_editor_for_prompt_with_file() {
  local prompt_file="$1"
  local session_marker editor original_mtime original_content new_mtime new_content

  if [ ! -f "$prompt_file" ]; then
    echo "Error: Prompt file not found: $prompt_file" >&2
    return 1
  fi

  session_marker=$(get_session_prompt_marker)
  editor=$(get_editor)

  # Capture original state for modification check
  original_content=$(cat "$prompt_file")
  # stat -f %m for macOS, stat -c %Y for Linux
  original_mtime=$(stat -f %m "$prompt_file" 2>/dev/null || stat -c %Y "$prompt_file" 2>/dev/null)

  echo "" >&2
  echo "Opening editor to modify your prompt..." >&2
  echo "Press :wq to save and exit." >&2

  # Only try TTY if we have one
  if [ -t 0 ]; then
    "$editor" "$prompt_file" </dev/tty >/dev/tty
  else
    "$editor" "$prompt_file"
  fi

  # Check if file was modified
  new_mtime=$(stat -f %m "$prompt_file" 2>/dev/null || stat -c %Y "$prompt_file" 2>/dev/null)
  new_content=$(cat "$prompt_file")

  # If not modified, keep original content
  if [ "$original_mtime" = "$new_mtime" ]; then
    echo "Note: Prompt was not saved. Using original content." >&2
    return 0
  fi

  # Fail if file is empty or only whitespace
  if [ ! -s "$prompt_file" ] || ! grep -q '[^[:space:]]' "$prompt_file"; then
    echo "Error: Prompt file is empty. Keeping original content." >&2
    echo "$original_content" >"$prompt_file"
    return 1
  fi

  # Store the prompt file path in session marker for reuse
  echo "$prompt_file" >"$session_marker"
  echo "Prompt updated." >&2
}

# Get prompt without interactive fallback (for validation)
# Non-interactive prompt resolution for validation context.
#
# Purpose:
#   Provides prompt resolution without launching interactive prompts.
#   Used for validation where interactive creation is not appropriate.
#
# Prompt Priority:
#   1. RALPH_PROMPT environment variable
#   2. RALPH_PROMPT_FILE environment variable
#   3. Session prompt marker
#   4. PROMPT_FILE (from resume)
#   5. Default placeholder (lowest priority)
#
# Difference from get_prompt():
#   - Never launches interactive prompt creation
#   - Returns default placeholder instead of exiting
#
# Returns:
#   Prompt content to stdout, or default placeholder if none found
#
# Example:
#   prompt=$(get_prompt_nointeractive)
get_prompt_nointeractive() {
  local session_marker session_prompt_file

  # Priority 1: RALPH_PROMPT environment variable
  if [ -n "${RALPH_PROMPT:-}" ]; then
    echo "$RALPH_PROMPT"
    return 0
  fi

  # Priority 2: RALPH_PROMPT_FILE environment variable
  if [ -n "${RALPH_PROMPT_FILE:-}" ] && [ -f "$RALPH_PROMPT_FILE" ]; then
    cat "$RALPH_PROMPT_FILE"
    return 0
  fi

  # Priority 3: Session prompt file (created via interactive editor this session)
  session_marker=$(get_session_prompt_marker)
  if [ -f "$session_marker" ]; then
    session_prompt_file=$(cat "$session_marker")
    if [ -f "$session_prompt_file" ]; then
      cat "$session_prompt_file"
      return 0
    fi
  fi

  # Priority 4: Default prompt.md file
  if [ -f "$PROMPT_FILE" ]; then
    cat "$PROMPT_FILE"
    return 0
  fi

  # Return default for validation context (no interactive fallback)
  echo "[No original prompt available - validate based on current state]"
  return 0
}
