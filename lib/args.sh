#!/usr/bin/env bash

# lib/args.sh - CLI argument parsing for RalphLoop
# Depends on: core.sh
#
# Purpose:
#   Provides command-line argument parsing and help text generation
#   for RalphLoop's CLI interface.
#
# Key Responsibilities:
#   - Parsing CLI arguments (--sessions, --resume, --cleanup, pipeline commands)
#   - Session management command handling
#   - Pipeline management command handling
#   - Help text generation and display
#
# Usage:
#   Sourced by lib.sh after core.sh. Functions are called from bin/ralph.
#
# Related Files:
#   - bin/ralph: Calls parse_cli_args() and handle_session_commands()
#   - lib/sessions.sh: Uses list_sessions() and cleanup_sessions() from here
#   - lib/pipeline.sh: Pipeline commands are dispatched here

# =============================================================================
# CLI Argument Parsing
# =============================================================================

# Parse command-line arguments and set global variables
# Sets: RALPH_RESUME, RALPH_SESSIONS, RALPH_CLEANUP, RALPH_CLEANUP_DAYS, RALPH_PIPELINE_CMD
#
# Purpose:
#   Parses all CLI arguments and populates global variables for later use.
#   Handles both standard RalphLoop options and pipeline subcommands.
#
# Arguments:
#   $@ - All command-line arguments passed to the script
#
# Sets Global Variables:
#   RALPH_RESUME - Session ID to resume (if --resume used)
#   RALPH_SESSIONS - true if --sessions flag used
#   RALPH_CLEANUP - Cleanup mode: days, "all", or empty
#   RALPH_CLEANUP_DAYS - Default cleanup age in days (7)
#   RALPH_PIPELINE_CMD - Pipeline subcommand (run, resume, validate, status, reset, stop)
#   RALPH_PIPELINE_ARGS - Remaining arguments after pipeline subcommand
#   RALPH_SESSIONS_FILTER_DIR - Directory filter for session listing
#   RALPH_FORCE_RESUME - true if --force-resume flag used
#
# Usage:
#   parse_cli_args "$@"
#   shift $#
parse_cli_args() {
  RALPH_RESUME=""
  RALPH_SESSIONS=false
  RALPH_CLEANUP=""
  RALPH_CLEANUP_DAYS=7
  RALPH_PIPELINE_CMD=""
  RALPH_PIPELINE_ARGS=""
  RALPH_SESSIONS_FILTER_DIR=""
  RALPH_FORCE_RESUME=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --sessions)
      RALPH_SESSIONS=true
      # Check for --dir filter
      local next_arg=""
      if [[ $# -gt 1 ]]; then
        next_arg="$2"
      fi
      if [[ -n "$next_arg" && "$next_arg" != --* ]]; then
        RALPH_SESSIONS_FILTER_DIR="$2"
        shift
      fi
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
    --dir)
      if [[ -z "$2" || "$2" == --* ]]; then
        echo "Error: --dir requires a directory argument"
        exit 1
      fi
      RALPH_SESSIONS_FILTER_DIR="$2"
      shift 2
      ;;
    --force-resume)
      RALPH_FORCE_RESUME=true
      shift
      ;;
    pipeline)
      # Pipeline management command
      local next_arg=""
      if [[ $# -gt 1 ]]; then
        next_arg="$2"
      fi
      if [[ -z "$next_arg" || "$next_arg" == --* ]]; then
        echo "Error: 'pipeline' command requires a subcommand"
        echo "Usage: ./ralph pipeline [run|resume|validate|status|reset|stop]"
        exit 1
      fi
      RALPH_PIPELINE_CMD="$2"
      shift 2
      # Collect remaining args as pipeline args
      RALPH_PIPELINE_ARGS="$@"
      break
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
# Displays comprehensive help text for RalphLoop's CLI interface.
#
# Purpose:
#   Provides users with documentation on available commands, options,
#   and usage examples for RalphLoop.
#
# Output:
#   Help text to stdout, then exits with status 0
#
# Example:
#   show_help
show_help() {
  cat <<EOF
RalphLoop - Autonomous Development Agent

Usage: ./ralph [options] [iterations]
       ./ralph pipeline <command> [options]

Options:
  --sessions [--dir <path>]  List sessions (optionally filter by directory)
  --resume <id>              Resume a specific session
  --cleanup [days]           Clean up incomplete sessions older than N days (default: 7)
  --cleanup-all              Clean up ALL incomplete sessions
  --dir <path>               Filter sessions by directory
  --force-resume             Force resume without prompting (for pipeline)
  -h, --help                 Show this help message

Pipeline Commands:
  pipeline run         Run the configured pipeline
  pipeline resume      Resume interrupted pipeline
  pipeline validate    Validate pipeline configuration
  pipeline status      Show current pipeline status
  pipeline reset       Reset pipeline state
  pipeline stop        Emergency stop (if running)

Pipeline Options:
  RALPH_PIPELINE_CONFIG=path/to/config.yaml  Use custom config file
  RALPH_PIPELINE_AI_ENABLED=true             Enable AI validation
  RALPH_PIPELINE_MAX_ITERATIONS=50           Override max iterations

Session Management:
  Sessions are automatically saved and can be resumed after interruption.
  Session files are stored in ~/.cache/ralph/sessions/

Examples:
  ./ralph 10                                  Run 10 iterations
  ./ralph --sessions                          List all sessions
  ./ralph --sessions --dir /path/to/project   List sessions for specific project
  ./ralph --resume myproject_20240123-143000
  ./ralph --cleanup 3                         Clean up incomplete sessions older than 3 days
  ./ralph pipeline run                        Run pipeline
  ./ralph pipeline resume                     Resume interrupted pipeline
  ./ralph pipeline validate                   Validate pipeline config
  RALPH_PIPELINE_AI_ENABLED=true ./ralph pipeline run
EOF
}

# Handle session management commands
# Processes session-related commands (--sessions, --cleanup, --resume)
# and exits after handling.
#
# Purpose:
#   Dispatches session management commands to appropriate functions
#   and handles program exit after command completion.
#
# Global Variables Used:
#   RALPH_SESSIONS - If true, lists sessions
#   RALPH_CLEANUP - If set, triggers cleanup
#   RALPH_RESUME - If set, triggers resume
#   RALPH_SESSIONS_FILTER_DIR - Directory filter for listing
#
# Side Effects:
#   May call list_sessions(), cleanup_sessions(), or resume_session()
#   Exits with appropriate status code
#
# Example:
#   handle_session_commands
handle_session_commands() {
  if [ "$RALPH_SESSIONS" = "true" ]; then
    list_sessions "$RALPH_SESSIONS_FILTER_DIR"
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

# Handle pipeline management commands
# Dispatches pipeline subcommands to appropriate functions.
#
# Purpose:
#   Routes pipeline management commands (run, resume, validate, etc.)
#   to their respective handler functions.
#
# Global Variables Used:
#   RALPH_PIPELINE_CMD - The pipeline subcommand to execute
#   RALPH_FORCE_RESUME - Force resume without prompting
#
# Side Effects:
#   Calls appropriate pipeline function and exits with result code
#
# Example:
#   handle_pipeline_commands
handle_pipeline_commands() {
  if [ -z "$RALPH_PIPELINE_CMD" ]; then
    return 0
  fi

  # Export force resume flag for pipeline functions
  export RALPH_FORCE_RESUME

  case "$RALPH_PIPELINE_CMD" in
  run)
    echo "🚀 Starting pipeline..."
    run_pipeline
    exit $?
    ;;
  resume)
    resume_pipeline_command "${RALPH_FORCE_RESUME:-false}"
    exit $?
    ;;
  validate | validate-config)
    validate_pipeline_config_command
    exit $?
    ;;
  status | show-status)
    show_pipeline_status
    exit 0
    ;;
  reset)
    reset_pipeline_state
    exit 0
    ;;
  stop | emergency-stop)
    emergency_stop_pipeline
    exit 0
    ;;
  *)
    echo "Error: Unknown pipeline command: $RALPH_PIPELINE_CMD"
    echo "Usage: ./ralph pipeline [run|resume|validate|status|reset|stop]"
    exit 1
    ;;
  esac
}
