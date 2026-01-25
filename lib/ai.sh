#!/usr/bin/env bash

# lib/ai.sh - AI enhanced prompt generation for RalphLoop
# Depends on: core.sh, templates.sh
#
# Purpose:
#   Provides AI-enhanced prompt generation capabilities for RalphLoop.
#   Allows users to describe project ideas briefly and have AI expand
#   them into complete project specifications.
#
# Key Responsibilities:
#   - AI-powered prompt specification generation
#   - Interactive prompt review and editing workflow
#   - Fallback to standard templates on failure or cancellation
#
# Workflow:
#   1. User describes project idea in editor
#   2. AI generates complete specification from idea
#   3. User reviews, edits, retries, or accepts the generated prompt
#   4. Accepted prompt is used for execution
#
# Usage:
#   Sourced by lib.sh. Functions called from prompt.sh module.
#
# Related Files:
#   - lib/prompt.sh: Uses generate_ai_enhanced_prompt()
#   - lib/templates.sh: Uses get_ai_idea_template(), get_standard_template()
#   - lib/core.sh: Uses get_editor(), get_ralph_cache_dir()

# =============================================================================
# AI Enhanced Prompt Generation
# =============================================================================

# Call AI to generate enhanced prompt from user idea
# Sends user's project idea to AI and receives a complete specification.
#
# Purpose:
#   Transforms brief user descriptions into comprehensive project specifications
#   using AI language models.
#
# Arguments:
#   $1 - user_idea: Brief description of the project or feature to build
#
# Returns:
#   AI-generated markdown specification to stdout
#   Error message to stderr if generation fails (function still returns 0)
#
# Note:
#   This is an internal function prefixed with _ to indicate private use.
#   Uses OPENCODE_OPTS environment variable for AI configuration.
#
# Example:
#   spec=$(_ai_generate_spec "Build a task management API with user authentication")
_ai_generate_spec() {
  local user_idea="$1"
  local meta_prompt
  meta_prompt=$(
    cat <<METAPROMPT
You are a project specification generator. Based on the user's idea below, generate a complete project specification in markdown format.

### User's Idea

${user_idea}

### Generate a specification with

1. A clear project title
2. A detailed goal description
3. Specific, measurable acceptance criteria (use checkboxes)
4. Technical context and constraints
5. Any assumptions or prerequisites

Output ONLY the markdown specification, no explanations.
METAPROMPT
  )

  local generated error_output
  # Run opencode and capture both stdout and stderr to diagnose failures
  error_output=$(mktemp)
  if generated=$(timeout 600 opencode run "${OPENCODE_OPTS[@]}" <<<"$meta_prompt" 2>"$error_output"); then
    rm -f "$error_output"
    echo "$generated"
  else
    local error_msg
    error_msg=$(cat "$error_output" 2>/dev/null || echo "Unknown error")
    rm -f "$error_output"

    echo "⚠️  AI generation failed: $error_msg" >&2
  fi
}

# Show AI prompt review menu
# Displays options for reviewing the generated AI prompt.
#
# Purpose:
#   Provides user interface for deciding what to do with the AI-generated prompt.
#
# Returns:
#   User choice: "accept", "edit", "retry", or "cancel"
#
# Note:
#   This is an internal function prefixed with _ to indicate private use.
#
# Example:
#   choice=$(_ai_show_review_menu)
_ai_show_review_menu() {
  echo "" >&2
  echo "========================================" >&2
  echo " Review Generated Prompt" >&2
  echo "========================================" >&2
  echo "" >&2
  echo "  a) Accept - Use this prompt as-is" >&2
  echo "  e) Edit   - Open in editor to customize" >&2
  echo "  r) Retry  - Describe your idea again" >&2
  echo "  c) Cancel - Abort and use standard template" >&2
  echo "" >&2

  local choice
  while true; do
    printf "Enter choice [a/e/r/c]: " >&2
    read -r choice </dev/tty
    case "$choice" in
    a | A)
      echo "accept"
      return
      ;;
    e | E)
      echo "edit"
      return
      ;;
    r | R)
      echo "retry"
      return
      ;;
    c | C)
      echo "cancel"
      return
      ;;
    *) echo "Invalid choice. Please enter a, e, r, or c." >&2 ;;
    esac
  done
}

# Generate an AI-enhanced prompt from user's idea
# Complete workflow for AI-enhanced prompt creation with review loop.
#
# Purpose:
#   Main entry point for AI-enhanced prompt generation. Handles the complete
#   workflow: idea input, AI generation, review/editing, and final output.
#
# Environment Variables:
#   RALPH_PROMPT_FOR_AI: If set, uses this as idea instead of opening editor
#   EDITOR: Editor to use for idea input and prompt editing
#   OPENCODE_OPTS: Options passed to OpenCode for AI generation
#
# Returns:
#   Final prompt content to stdout (accepted, edited, or standard template)
#
# Workflow:
#   1. Open editor for user to describe their idea
#   2. Send idea to AI for specification generation
#   3. Show generated prompt and offer review options:
#      - Accept: Use generated prompt as-is
#      - Edit: Open in editor for customization
#      - Retry: Describe idea again
#      - Cancel: Fall back to standard template
#
# Example:
#   prompt=$(generate_ai_enhanced_prompt)
generate_ai_enhanced_prompt() {
  local cache_dir idea_file edit_file editor template_content user_idea generated choice
  cache_dir=$(get_ralph_cache_dir)
  idea_file="${TEMP_FILE_PREFIX}_ai_idea_temp.md"
  edit_file="${TEMP_FILE_PREFIX}_ai_edit_temp.md"
  editor=$(get_editor)

  # Track the previous idea for re-prompting
  local previous_idea=""

  echo "" >&2
  echo "========================================" >&2
  echo " AI Enhanced Prompt Generator" >&2
  echo "========================================" >&2

  while true; do
    echo "" >&2
    echo "Opening editor for you to describe your idea..." >&2

    # Write idea template (with previous idea if re-prompting)
    get_ai_idea_template "$previous_idea" >"$idea_file"
    template_content=$(get_ai_idea_template "")

    # Check if RALPH_PROMPT_FOR_AI is set for non-interactive mode
    if [ -n "${RALPH_PROMPT_FOR_AI:-}" ]; then
      echo "$RALPH_PROMPT_FOR_AI" >"$idea_file"
    else
      # Open editor for user to write their idea
      "$editor" "$idea_file" </dev/tty >/dev/tty
    fi

    # Read the user's idea
    user_idea=$(cat "$idea_file")
    rm -f "$idea_file"

    # Check if content was modified (only for first attempt)
    if [ -z "$previous_idea" ] && [ "$user_idea" = "$template_content" ]; then
      echo "Error: Idea was not modified. Using standard template." >&2
      get_standard_template
      return 0
    fi

    # Check if empty
    if [ -z "$user_idea" ] || ! echo "$user_idea" | grep -q '[^[:space:]]'; then
      echo "Error: No idea provided. Using standard template." >&2
      get_standard_template
      return 0
    fi

    # Save for potential re-prompt
    previous_idea="$user_idea"

    echo "" >&2
    echo "Generating enhanced prompt from your idea..." >&2
    echo "" >&2

    # Generate the AI-enhanced prompt
    generated=$(_ai_generate_spec "$user_idea")

    # Display the generated prompt
    echo "========================================" >&2
    echo " Generated Prompt Preview" >&2
    echo "========================================" >&2
    echo "" >&2
    echo "$generated" >&2
    echo "" >&2
    echo "========================================" >&2

    # Show review menu
    choice=$(_ai_show_review_menu)

    case "$choice" in
    accept)
      echo "$generated"
      return 0
      ;;
    edit)
      # Open editor for final customization
      echo "$generated" >"$edit_file"
      "$editor" "$edit_file" </dev/tty >/dev/tty
      local edited
      edited=$(cat "$edit_file")
      rm -f "$edit_file"
      echo "$edited"
      return 0
      ;;
    retry)
      # Loop back with previous idea prefilled
      echo "" >&2
      echo "Let's try again..." >&2
      continue
      ;;
    cancel)
      echo "" >&2
      echo "Cancelled. Using standard template." >&2
      get_standard_template
      return 0
      ;;
    esac
  done
}
