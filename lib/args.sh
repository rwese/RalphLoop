#!/usr/bin/env bash

# lib/args.sh - CLI argument parsing for RalphLoop
# Depends on: core.sh

# =============================================================================
# CLI Argument Parsing
# =============================================================================

# Parse command-line arguments and set global variables
# Sets: RALPH_RESUME, RALPH_SESSIONS, RALPH_CLEANUP, RALPH_CLEANUP_DAYS, RALPH_PIPELINE_CMD
parse_cli_args() {
  RALPH_RESUME=""
  RALPH_SESSIONS=false
  RALPH_CLEANUP=""
  RALPH_CLEANUP_DAYS=7
  RALPH_PIPELINE_CMD=""
  RALPH_PIPELINE_ARGS=""

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
    pipeline)
      # Pipeline management command
      if [[ -z "$2" ]]; then
        echo "Error: 'pipeline' command requires a subcommand"
        echo "Usage: ./ralph pipeline [run|validate-config|show-status|reset|stop]"
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
show_help() {
  cat <<EOF
RalphLoop - Autonomous Development Agent

Usage: ./ralph [options] [iterations]
       ./ralph pipeline <command> [options]

Options:
  --sessions           List all sessions
  --resume <id>        Resume a specific session
  --cleanup [days]     Clean up incomplete sessions older than N days (default: 7)
  --cleanup-all        Clean up ALL incomplete sessions
  -h, --help           Show this help message

Pipeline Commands:
  pipeline run         Run the configured pipeline
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
  ./ralph --resume myproject_20240123-143000
  ./ralph --cleanup 3                         Clean up incomplete sessions older than 3 days
  ./ralph pipeline run                        Run pipeline
  ./ralph pipeline validate                   Validate pipeline config
  RALPH_PIPELINE_AI_ENABLED=true ./ralph pipeline run
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

# Handle pipeline management commands
handle_pipeline_commands() {
  if [ -z "$RALPH_PIPELINE_CMD" ]; then
    return 0
  fi

  case "$RALPH_PIPELINE_CMD" in
  run)
    echo "🚀 Starting pipeline..."
    run_pipeline
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
    echo "Usage: ./ralph pipeline [run|validate|status|reset|stop]"
    exit 1
    ;;
  esac
}
