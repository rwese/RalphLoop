#!/usr/bin/env bash

# lib/templates.sh - Prompt template functions for RalphLoop
# Depends on: none

# =============================================================================
# Template Functions
# =============================================================================

# Get the standard prompt template
get_standard_template() {
    cat <<'TEMPLATE'
# Project Goal

[Describe what you want to accomplish]

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Context

[Any additional context, constraints, or preferences]
TEMPLATE
}

# Get the quickfix template for small changes
get_quickfix_template() {
    cat <<'TEMPLATE'
# QuickFix

## Issue

[Describe the bug or small change needed]

## Expected Behavior

[What should happen after the fix]

## Files Affected

- [ ] File 1

## Acceptance Criteria

- [ ] The fix is implemented
- [ ] No regressions introduced
TEMPLATE
}

# Get blank template
get_blank_template() {
    cat <<'TEMPLATE'
# Project

TEMPLATE
}

# Get the AI idea template (with optional prefilled content)
get_ai_idea_template() {
    local prefill="${1:-}"
    if [ -n "$prefill" ]; then
        echo "$prefill"
    else
        cat <<'TEMPLATE'
# Describe Your Project Idea

Write a brief description of what you want to build or accomplish.
The AI will expand this into a full project specification.

## Your Idea

[Replace this with your project idea - be as detailed or brief as you like]

## Optional: Additional Context

[Any constraints, preferences, or technical requirements]
TEMPLATE
    fi
}

# =============================================================================
# Template Selection Menu
# =============================================================================

# Show template selection menu and return the selected type
show_template_menu() {
    # Check for environment variable override
    if [ -n "${RALPH_TEMPLATE_TYPE:-}" ]; then
        case "${RALPH_TEMPLATE_TYPE}" in
        standard | quickfix | ai | example | blank)
            echo "${RALPH_TEMPLATE_TYPE}"
            return 0
            ;;
        *)
            echo "Warning: Invalid RALPH_TEMPLATE_TYPE '${RALPH_TEMPLATE_TYPE}', showing menu" >&2
            ;;
        esac
    fi

    cat >&2 <<'MENU'
=======================================
 RalphLoop - Template Selection
=======================================

Choose a template to start with:

  1) Standard Prompt
     Full project specification with goals and acceptance criteria

  2) QuickFix
     Quick bug fix or small change with minimal structure

  3) AI Enhanced Prompt
     Describe your idea and let AI generate a complete plan

  4) Load Example
     Choose from pre-built example projects

  5) Blank
     Start with an empty file

MENU

    local selection
    while true; do
        printf "Enter selection [1-5]: " >&2
        read -r selection </dev/tty
        case "$selection" in
        1)
            echo "standard"
            return 0
            ;;
        2)
            echo "quickfix"
            return 0
            ;;
        3)
            echo "ai"
            return 0
            ;;
        4)
            echo "example"
            return 0
            ;;
        5)
            echo "blank"
            return 0
            ;;
        *) echo "Invalid selection. Please enter 1-5." >&2 ;;
        esac
    done
}

# Show example selection menu and return the selected example path
show_example_menu() {
    local examples_dir="${SCRIPT_DIR:-$(dirname "${BASH_SOURCE[0]}")}/examples"
    local -a examples=()
    local i=0

    # Find all example directories with prompt.md files
    while IFS= read -r -d '' dir; do
        examples+=("$dir")
    done < <(find "$examples_dir" -maxdepth 2 -name "prompt.md" -print0 2>/dev/null | sort -z)

    if [ ${#examples[@]} -eq 0 ]; then
        echo "No examples found in $examples_dir" >&2
        echo ""
        return 1
    fi

    echo "" >&2
    echo "========================================" >&2
    echo " Available Examples" >&2
    echo "========================================" >&2
    echo "" >&2

    for ((i = 0; i < ${#examples[@]}; i++)); do
        local example_name
        example_name=$(dirname "${examples[$i]}" | xargs basename)
        printf "  %d) %s\n" "$((i + 1))" "$example_name" >&2
    done

    echo "" >&2

    local selection
    while true; do
        printf "Enter selection [1-%d]: " "${#examples[@]}" >&2
        read -r selection </dev/tty
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#examples[@]} ]; then
            echo "${examples[$((selection - 1))]}"
            return 0
        fi
        echo "Invalid selection. Please enter 1-${#examples[@]}." >&2
    done
}

# Load an example prompt file
load_example_prompt() {
    local example_path="$1"
    if [ -f "$example_path" ]; then
        cat "$example_path"
    else
        echo "Error: Example file not found: $example_path" >&2
        return 1
    fi
}
