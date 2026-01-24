#!/usr/bin/env bash

# lib/ai.sh - AI enhanced prompt generation for RalphLoop
# Depends on: core.sh, templates.sh

# =============================================================================
# AI Enhanced Prompt Generation
# =============================================================================

# Call AI to generate enhanced prompt from user idea
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

  local generated
  if generated=$(timeout 600 opencode run "${OPENCODE_OPTS[@]}" <<<"$meta_prompt" 2>/dev/null); then
    echo "$generated"
  else
    echo "ai generation failed, using default template." >&2
    # Fallback if AI fails
    cat <<FALLBACK
# Goal

${user_idea}

## Approach

- [ ] Extract Acceptance criteria
- [ ] Break down work into chunks
- [ ] Tests passing

FALLBACK
  fi
}

# Show AI prompt review menu
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
# Returns: final prompt content (accepted, edited, or fallback to standard)
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

    # Open editor for user to write their idea
    "$editor" "$idea_file" </dev/tty >/dev/tty

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
      # User accepts as-is, signal to skip editor via marker file
      touch "${cache_dir}/.ai_skip_editor_$$"
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
      # Signal to skip editor via marker file
      touch "${cache_dir}/.ai_skip_editor_$$"
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
