#!/usr/bin/env bash

# lib/args.sh - CLI argument parsing for RalphLoop
# Depends on: core.sh

# =============================================================================
# CLI Argument Parsing
# =============================================================================

# Parse command-line arguments and set global variables
# Sets: RALPH_RESUME, RALPH_SESSIONS, RALPH_CLEANUP, RALPH_CLEANUP_DAYS
parse_cli_args() {
    RALPH_RESUME=""
    RALPH_SESSIONS=false
    RALPH_CLEANUP=""
    RALPH_CLEANUP_DAYS=7

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --sessions)
            RALPH_SESSIONS=true
            shift
            ;;
        --resume)
            if [[ -z "$2" || "$2" == --* ]]; then
                echo "Error: --resume requires a session ID argument"
                exit 1
            fi
            RALPH_RESUME="$2"
            shift 2
            ;;
        --cleanup)
            if [[ -n "$2" && "$2" != --* ]]; then
                if [[ "$2" =~ ^[0-9]+$ ]]; then
                    RALPH_CLEANUP_DAYS="$2"
                else
                    echo "Warning: Invalid argument for --cleanup, using default of 7 days"
                fi
                shift
            else
                RALPH_CLEANUP="$RALPH_CLEANUP_DAYS"
            fi
            ;;
        --cleanup-all)
            RALPH_CLEANUP="all"
            shift
            ;;
        -h | --help)
            show_help
            exit 0
            ;;
        *)
            # Not a known option, stop parsing
            break
            ;;
        esac
    done
}

# Show help message
show_help() {
    cat <<EOF
RalphLoop - Autonomous Development Agent

Usage: ./ralph [options] [iterations]

Options:
  --sessions           List all sessions
  --resume <id>        Resume a specific session
  --cleanup [days]     Clean up incomplete sessions older than N days (default: 7)
  --cleanup-all        Clean up ALL incomplete sessions
  -h, --help           Show this help message

Session Management:
  Sessions are automatically saved and can be resumed after interruption.
  Session files are stored in ~/.cache/ralph/sessions/

Examples:
  ./ralph 10                  Run 10 iterations
  ./ralph --sessions          List all sessions
  ./ralph --resume myproject_20240123-143000
  ./ralph --cleanup 3         Clean up incomplete sessions older than 3 days
EOF
}

# Handle session management commands
handle_session_commands() {
    if [ "$RALPH_SESSIONS" = "true" ]; then
        list_sessions
        exit 0
    fi

    if [ -n "$RALPH_CLEANUP" ]; then
        cleanup_sessions "$RALPH_CLEANUP"
        exit 0
    fi

    if [ -n "$RALPH_RESUME" ]; then
        RESUME_ITERATION=$(resume_session "$RALPH_RESUME")
        if [ $? -eq 0 ] && [ -n "$RESUME_ITERATION" ]; then
            # Use the existing session ID for the resumed session
            SESSION_ID="$RALPH_RESUME"

            # Mark prompt as accepted for resumed sessions (session already exists on disk)
            PROMPT_ACCEPTED=true

            # Update MAX_ROUNDS to continue from where we left off
            # Ensure MAX_ROUNDS is numeric first (re-initialize from default if needed)
            if [[ -z "$MAX_ROUNDS" || ! "$MAX_ROUNDS" =~ ^[0-9]+$ ]]; then
                MAX_ROUNDS=100
            fi
            MAX_ROUNDS=$((MAX_ROUNDS + RESUME_ITERATION - 1))
            echo "   Continuing from iteration $RESUME_ITERATION (total: $MAX_ROUNDS)"
        else
            exit 1
        fi
        echo ""
    fi
}
