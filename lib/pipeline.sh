#!/usr/bin/env bash

# lib/pipeline.sh - Configurable Multi-Stage Pipeline Framework for RalphLoop
# Depends on: core.sh, sessions.sh
#
# Purpose:
#   Provides a configuration-driven pipeline orchestration system that replaces
#   the hardcoded execute -> validate -> finalize flow with a flexible,
#   YAML/JSON-configurable multi-stage pipeline.
#
# Key Concepts:
#   - Stages: Named execution phases (plan, execute, validate, etc.)
#   - Transitions: Rules for moving between stages based on results
#   - State Persistence: Pipeline state saved for interruption recovery
#   - AI Validation: Optional AI-enhanced validation at stage boundaries
#
# Default Pipeline Structure:
#   plan -> execute -> validate
#   (with retry loop: validate failure -> execute)
#
# Configuration Files:
#   - pipeline.yaml (primary)
#   - pipeline.yml
#   - pipeline.json
#   - Or custom path via RALPH_PIPELINE_CONFIG
#
# Usage:
#   Sourced by lib.sh. Main entry point is run_pipeline().
#
# Related Files:
#   - pipeline.yaml: Default pipeline configuration
#   - lib/exec.sh: Uses pipeline functions for execution
#   - bin/ralph: Calls run_pipeline() as main entry point

# =============================================================================
# Pipeline Configuration Variables
# =============================================================================

# Pipeline configuration file paths (checked in order)
# Looks for configuration files in current directory before using default.
PIPELINE_CONFIG_FILES=("pipeline.yaml" "pipeline.yml" "pipeline.json")

# Pipeline state file - stores current state for resume support
PIPELINE_STATE_FILE="${TEMP_FILE_PREFIX}_pipeline_state.txt"

# Pipeline log file - detailed execution log
PIPELINE_LOG_FILE="${TEMP_FILE_PREFIX}_pipeline.log"

# Default pipeline configuration (used when no config file found)
PIPELINE_NAME="${PIPELINE_NAME:-default}"
PIPELINE_MAX_ITERATIONS="${PIPELINE_MAX_ITERATIONS:-100}"
PIPELINE_INITIAL_STAGE="${PIPELINE_INITIAL_STAGE:-execute}"

# Pipeline state variables - track execution progress
PIPELINE_CURRENT_STAGE=""    # Current stage name
PIPELINE_CURRENT_ITERATION=0 # Current iteration within stage
PIPELINE_CURRENT_ROUND=0     # Current execution round
PIPELINE_START_TIME=""       # When pipeline started
PIPELINE_STATUS="idle"       # idle, running, completed, failed, stopped
PIPELINE_ERROR=""            # Error message if failed

# Validation status tracking (set by run_validate_stage, checked by check_validation_passed)
VALIDATION_PASSED=false

# Execution completion tracking (set by run_execute_stage, checked by check_execution_complete)
EXECUTION_COMPLETE=false

# Stage definitions (populated by config parser)
declare -A STAGE_ENTRY_COMMANDS      # Command to run when entering stage
declare -A STAGE_VALIDATION_COMMANDS # Command to validate stage completion
declare -A STAGE_ON_SUCCESS          # Next stage on success
declare -A STAGE_ON_FAILURE          # Next stage on failure
declare -A STAGE_TIMEOUTS            # Timeout for each stage
declare -A STAGE_AI_VALIDATION       # Whether to use AI validation
declare -A STAGE_DESCRIPTIONS        # Human-readable description

# Transition rules (populated by config parser)
declare -A TRANSITION_CONDITIONS # Conditional transition expressions

# Available stages (populated by config parser)
PIPELINE_STAGES=()

# AI validation enabled (global flag)
RALPH_PIPELINE_AI_ENABLED="${RALPH_PIPELINE_AI_ENABLED:-false}"

# Emergency stop flag - set to true to stop pipeline gracefully
PIPELINE_EMERGENCY_STOP=false

# =============================================================================
# Configuration File Discovery and Parsing
# =============================================================================

# Find and load pipeline configuration
# Searches for configuration file in standard locations and loads it.
#
# Purpose:
#   Locates and parses the pipeline configuration file based on:
#   1. Explicit path via RALPH_PIPELINE_CONFIG
#   2. Standard files in current directory (pipeline.yaml, pipeline.yml, pipeline.json)
#   3. Falls back to default configuration
#
# Environment Variables:
#   RALPH_PIPELINE_CONFIG: Explicit path to config file
#
# Returns:
#   0 always (falls back to default config if file not found)
#
# Example:
#   load_pipeline_config
load_pipeline_config() {
  local config_file=""

  # Look for config file in current directory
  for file in "${PIPELINE_CONFIG_FILES[@]}"; do
    if [[ -f "$file" ]]; then
      config_file="$file"
      break
    fi
  done

  # Use explicit config file if provided
  if [[ -n "${RALPH_PIPELINE_CONFIG:-}" && -f "$RALPH_PIPELINE_CONFIG" ]]; then
    config_file="$RALPH_PIPELINE_CONFIG"
  fi

  if [[ -z "$config_file" ]]; then
    echo "⚠️  No pipeline configuration file found"
    echo "   Using default pipeline configuration (plan -> execute -> validate)"
    load_default_pipeline_config
    return 0
  fi

  echo "📄 Loading pipeline configuration: $config_file"

  # Parse based on file extension
  case "$config_file" in
  *.yaml | *.yml)
    parse_yaml_pipeline_config "$config_file"
    ;;
  *.json)
    parse_json_pipeline_config "$config_file"
    ;;
  *)
    # Try to detect format
    if command -v yq &>/dev/null; then
      parse_yaml_pipeline_config "$config_file"
    elif command -v jq &>/dev/null; then
      parse_json_pipeline_config "$config_file"
    else
      echo "❌ Error: Cannot parse $config_file - no YAML/JSON parser available"
      echo "   Install yq (for YAML) or jq (for JSON)"
      return 1
    fi
    ;;
  esac

  # Validate the configuration
  if ! validate_pipeline_config; then
    return 1
  fi

  echo "✅ Pipeline configuration loaded successfully"
  echo "   Pipeline: $PIPELINE_NAME"
  echo "   Stages: ${PIPELINE_STAGES[*]}"
  echo "   Max Iterations: $PIPELINE_MAX_ITERATIONS"
  echo "   Initial Stage: $PIPELINE_INITIAL_STAGE"
}

# Load default pipeline configuration (plan -> execute -> validate)
load_default_pipeline_config() {
  PIPELINE_NAME="default"
  PIPELINE_MAX_ITERATIONS="${MAX_ROUNDS:-100}"
  PIPELINE_INITIAL_STAGE="plan"

  # Clear existing stage definitions
  unset STAGE_ENTRY_COMMANDS STAGE_VALIDATION_COMMANDS STAGE_ON_SUCCESS
  unset STAGE_ON_FAILURE STAGE_TIMEOUTS STAGE_AI_VALIDATION STAGE_DESCRIPTIONS
  unset TRANSITION_CONDITIONS
  declare -gA STAGE_ENTRY_COMMANDS STAGE_VALIDATION_COMMANDS STAGE_ON_SUCCESS
  declare -gA STAGE_ON_FAILURE STAGE_TIMEOUTS STAGE_AI_VALIDATION STAGE_DESCRIPTIONS
  declare -gA TRANSITION_CONDITIONS

  # Define plan stage
  STAGE_DESCRIPTIONS["plan"]="Analyze task and create implementation plan"
  STAGE_ENTRY_COMMANDS["plan"]="run_plan_stage"
  STAGE_VALIDATION_COMMANDS["plan"]="check_plan_complete"
  STAGE_ON_SUCCESS["plan"]="execute"
  STAGE_ON_FAILURE["plan"]=""
  STAGE_TIMEOUTS["plan"]="${RALPH_TIMEOUT:-1800}"
  STAGE_AI_VALIDATION["plan"]="false"

  # Define execute stage
  STAGE_DESCRIPTIONS["execute"]="Execute the planned implementation"
  STAGE_ENTRY_COMMANDS["execute"]="run_execute_stage"
  STAGE_VALIDATION_COMMANDS["execute"]="check_execution_complete"
  STAGE_ON_SUCCESS["execute"]="validate"
  STAGE_ON_FAILURE["execute"]="plan" # Loop back to plan on failure
  STAGE_TIMEOUTS["execute"]="${RALPH_TIMEOUT:-1800}"
  STAGE_AI_VALIDATION["execute"]="false"

  # Define validate stage
  STAGE_DESCRIPTIONS["validate"]="Validate execution results and quality"
  STAGE_ENTRY_COMMANDS["validate"]="run_validate_stage"
  STAGE_VALIDATION_COMMANDS["validate"]="check_validation_passed"
  STAGE_ON_SUCCESS["validate"]=""        # Terminal stage - pipeline complete
  STAGE_ON_FAILURE["validate"]="execute" # Loop back to execute on failure
  STAGE_TIMEOUTS["validate"]="300"
  STAGE_AI_VALIDATION["validate"]="${RALPH_PIPELINE_AI_ENABLED:-false}"

  # Define transitions
  PIPELINE_STAGES=("plan" "execute" "validate")
}

# Parse YAML pipeline configuration (using yq if available, fallback to pure bash)
parse_yaml_pipeline_config() {
  local config_file="$1"

  if command -v yq &>/dev/null; then
    parse_yaml_pipeline_config_yq "$config_file"
  else
    parse_yaml_pipeline_config_bash "$config_file"
  fi
}

# Parse YAML using yq
parse_yaml_pipeline_config_yq() {
  local config_file="$1"

  # Parse pipeline metadata
  PIPELINE_NAME=$(yq e '.pipeline.name // "custom"' "$config_file")
  PIPELINE_MAX_ITERATIONS=$(yq e '.pipeline.max_iterations // 100' "$config_file")
  PIPELINE_INITIAL_STAGE=$(yq e '.pipeline.initial_stage // "execute"' "$config_file")

  # Parse stages
  local stage_count
  stage_count=$(yq e '.stages | length' "$config_file")

  PIPELINE_STAGES=()
  for ((i = 0; i < stage_count; i++)); do
    local stage_name
    stage_name=$(yq e ".stages[$i].name // \"stage_$i\"" "$config_file")

    PIPELINE_STAGES+=("$stage_name")
    STAGE_DESCRIPTIONS["$stage_name"]=$(yq e ".stages[$i].description // \"\"" "$config_file")
    STAGE_ENTRY_COMMANDS["$stage_name"]=$(yq e ".stages[$i].entry_command // \"\"" "$config_file")
    STAGE_VALIDATION_COMMANDS["$stage_name"]=$(yq e ".stages[$i].validation_command // \"\"" "$config_file")
    STAGE_ON_SUCCESS["$stage_name"]=$(yq e ".stages[$i].on_success // \"\"" "$config_file")
    STAGE_ON_FAILURE["$stage_name"]=$(yq e ".stages[$i].on_failure // \"\"" "$config_file")
    STAGE_TIMEOUTS["$stage_name"]=$(yq e ".stages[$i].timeout // 0" "$config_file")
    STAGE_AI_VALIDATION["$stage_name"]=$(yq e ".stages[$i].ai_validation // false" "$config_file")
  done

  # Parse transitions
  local transition_count
  transition_count=$(yq e '.transitions | length' "$config_file")

  for ((i = 0; i < transition_count; i++)); do
    local from to condition
    from=$(yq e ".transitions[$i].from" "$config_file")
    to=$(yq e ".transitions[$i].to" "$config_file")
    condition=$(yq e ".transitions[$i].condition // \"\"" "$config_file")

    local key="${from}->${to}"
    TRANSITION_CONDITIONS["$key"]="$condition"
  done
}

# Parse YAML using pure bash (fallback)
parse_yaml_pipeline_config_bash() {
  local config_file="$1"
  local in_pipeline=false
  local in_stages=false
  local current_stage=""
  local line

  # Clear existing definitions
  unset STAGE_ENTRY_COMMANDS STAGE_VALIDATION_COMMANDS STAGE_ON_SUCCESS
  unset STAGE_ON_FAILURE STAGE_TIMEOUTS STAGE_AI_VALIDATION STAGE_DESCRIPTIONS
  unset TRANSITION_CONDITIONS
  declare -gA STAGE_ENTRY_COMMANDS STAGE_VALIDATION_COMMANDS STAGE_ON_SUCCESS
  declare -gA STAGE_ON_FAILURE STAGE_TIMEOUTS STAGE_AI_VALIDATION STAGE_DESCRIPTIONS
  declare -gA TRANSITION_CONDITIONS

  PIPELINE_STAGES=()

  while IFS= read -r line; do
    # Remove leading/trailing whitespace
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Detect section headers
    if [[ "$line" =~ ^pipeline:[[:space:]]*$ ]]; then
      in_pipeline=true
      in_stages=false
      continue
    fi

    if [[ "$line" =~ ^stages:[[:space:]]*$ ]]; then
      in_pipeline=false
      in_stages=true
      continue
    fi

    if [[ "$line" =~ ^transitions:[[:space:]]*$ ]]; then
      in_stages=false
      continue
    fi

    # Parse pipeline settings
    if $in_pipeline; then
      if [[ "$line" =~ ^name:[[:space:]]*(.*)$ ]]; then
        PIPELINE_NAME="${BASH_REMATCH[1]}"
        PIPELINE_NAME=$(echo "$PIPELINE_NAME" | xargs)
      elif [[ "$line" =~ ^max_iterations:[[:space:]]*(.*)$ ]]; then
        PIPELINE_MAX_ITERATIONS=$(echo "${BASH_REMATCH[1]}" | xargs)
      elif [[ "$line" =~ ^initial_stage:[[:space:]]*(.*)$ ]]; then
        PIPELINE_INITIAL_STAGE=$(echo "${BASH_REMATCH[1]}" | xargs)
      fi
    fi

    # Parse stage definitions
    if $in_stages; then
      # Check for stage name (key with colon)
      if [[ "$line" =~ ^([^:]+):[[:space:]]*$ ]]; then
        current_stage=$(echo "${BASH_REMATCH[1]}" | xargs)
        PIPELINE_STAGES+=("$current_stage")
      elif [[ -n "$current_stage" ]]; then
        # Parse stage properties
        if [[ "$line" =~ ^entry_command:[[:space:]]*(.*)$ ]]; then
          STAGE_ENTRY_COMMANDS["$current_stage"]=$(echo "${BASH_REMATCH[1]}" | xargs)
        elif [[ "$line" =~ ^validation_command:[[:space:]]*(.*)$ ]]; then
          STAGE_VALIDATION_COMMANDS["$current_stage"]=$(echo "${BASH_REMATCH[1]}" | xargs)
        elif [[ "$line" =~ ^on_success:[[:space:]]*(.*)$ ]]; then
          STAGE_ON_SUCCESS["$current_stage"]=$(echo "${BASH_REMATCH[1]}" | xargs)
        elif [[ "$line" =~ ^on_failure:[[:space:]]*(.*)$ ]]; then
          STAGE_ON_FAILURE["$current_stage"]=$(echo "${BASH_REMATCH[1]}" | xargs)
        elif [[ "$line" =~ ^timeout:[[:space:]]*(.*)$ ]]; then
          STAGE_TIMEOUTS["$current_stage"]=$(echo "${BASH_REMATCH[1]}" | xargs)
        elif [[ "$line" =~ ^ai_validation:[[:space:]]*(.*)$ ]]; then
          STAGE_AI_VALIDATION["$current_stage"]=$(echo "${BASH_REMATCH[1]}" | xargs)
        elif [[ "$line" =~ ^description:[[:space:]]*(.*)$ ]]; then
          STAGE_DESCRIPTIONS["$current_stage"]=$(echo "${BASH_REMATCH[1]}" | xargs)
        fi
      fi
    fi
  done <"$config_file"
}

# Parse JSON pipeline configuration
parse_json_pipeline_config() {
  local config_file="$1"

  if ! command -v jq &>/dev/null; then
    echo "❌ Error: jq is required for JSON parsing"
    return 1
  fi

  # Parse pipeline metadata
  PIPELINE_NAME=$(jq -r '.pipeline.name // "custom"' "$config_file")
  PIPELINE_MAX_ITERATIONS=$(jq -r '.pipeline.max_iterations // 100' "$config_file")
  PIPELINE_INITIAL_STAGE=$(jq -r '.pipeline.initial_stage // "execute"' "$config_file")

  # Parse stages
  PIPELINE_STAGES=()
  local stages_json
  stages_json=$(jq '.stages' "$config_file")

  local stage_count
  stage_count=$(echo "$stages_json" | jq 'length')

  for ((i = 0; i < stage_count; i++)); do
    local stage_name entry validation on_success on_failure timeout ai desc
    stage_name=$(echo "$stages_json" | jq -r ".[$i].name // \"stage_$i\"")
    entry=$(echo "$stages_json" | jq -r ".[$i].entry_command // \"\"")
    validation=$(echo "$stages_json" | jq -r ".[$i].validation_command // \"\"")
    on_success=$(echo "$stages_json" | jq -r ".[$i].on_success // \"\"")
    on_failure=$(echo "$stages_json" | jq -r ".[$i].on_failure // \"\"")
    timeout=$(echo "$stages_json" | jq -r ".[$i].timeout // 0")
    ai=$(echo "$stages_json" | jq -r ".[$i].ai_validation // \"false\"")
    desc=$(echo "$stages_json" | jq -r ".[$i].description // \"\"")

    PIPELINE_STAGES+=("$stage_name")
    STAGE_ENTRY_COMMANDS["$stage_name"]="$entry"
    STAGE_VALIDATION_COMMANDS["$stage_name"]="$validation"
    STAGE_ON_SUCCESS["$stage_name"]="$on_success"
    STAGE_ON_FAILURE["$stage_name"]="$on_failure"
    STAGE_TIMEOUTS["$stage_name"]="$timeout"
    STAGE_AI_VALIDATION["$stage_name"]="$ai"
    STAGE_DESCRIPTIONS["$stage_name"]="$desc"
  done

  # Parse transitions
  local transitions_json
  transitions_json=$(jq '.transitions // []' "$config_file")

  local transition_count
  transition_count=$(echo "$transitions_json" | jq 'length')

  for ((i = 0; i < transition_count; i++)); do
    local from to condition
    from=$(echo "$transitions_json" | jq -r ".[$i].from")
    to=$(echo "$transitions_json" | jq -r ".[$i].to")
    condition=$(echo "$transitions_json" | jq -r ".[$i].condition // \"\"")

    local key="${from}->${to}"
    TRANSITION_CONDITIONS["$key"]="$condition"
  done
}

# Validate pipeline configuration
validate_pipeline_config() {
  # Check required fields
  if [[ -z "$PIPELINE_NAME" ]]; then
    echo "❌ Error: Pipeline name is required"
    return 1
  fi

  if [[ ${#PIPELINE_STAGES[@]} -eq 0 ]]; then
    echo "❌ Error: At least one stage is required"
    return 1
  fi

  # Check that initial stage exists
  local initial_found=false
  for stage in "${PIPELINE_STAGES[@]}"; do
    if [[ "$stage" == "$PIPELINE_INITIAL_STAGE" ]]; then
      initial_found=true
      break
    fi
  done

  if ! $initial_found; then
    echo "❌ Error: Initial stage '$PIPELINE_INITIAL_STAGE' not found in stages"
    return 1
  fi

  # Check for invalid circular dependencies
  # Allow: validate -> execute (retry loop is intentional)
  # Detect: true cycles that would cause infinite loops
  if ! check_circular_dependencies; then
    echo "❌ Error: Circular dependency detected in pipeline"
    return 1
  fi

  # Validate stage references
  for stage in "${PIPELINE_STAGES[@]}"; do
    # Check on_success reference
    local success_target="${STAGE_ON_SUCCESS[$stage]}"
    if [[ -n "$success_target" ]]; then
      local target_found=false
      for s in "${PIPELINE_STAGES[@]}"; do
        if [[ "$s" == "$success_target" ]]; then
          target_found=true
          break
        fi
      done
      if ! $target_found; then
        echo "❌ Warning: on_success target '$success_target' for stage '$stage' not found"
      fi
    fi

    # Check on_failure reference
    local failure_target="${STAGE_ON_FAILURE[$stage]}"
    if [[ -n "$failure_target" ]]; then
      local target_found=false
      for s in "${PIPELINE_STAGES[@]}"; do
        if [[ "$s" == "$failure_target" ]]; then
          target_found=true
          break
        fi
      done
      if ! $target_found; then
        echo "❌ Warning: on_failure target '$failure_target' for stage '$stage' not found"
      fi
    fi
  done

  return 0
}

# Check for circular dependencies in pipeline
check_circular_dependencies() {
  local visited=()
  local recursion_stack=()

  for stage in "${PIPELINE_STAGES[@]}"; do
    if ! contains_element "$stage" "${visited[@]}"; then
      if ! dfs_check_cycle "$stage" visited recursion_stack; then
        return 1
      fi
    fi
  done

  return 0
}

# Check for circular dependencies in pipeline
# Only detects infinite cycles, allows retry loops like execute->validate->execute
check_circular_dependencies() {
  # For RalphLoop, retry loops are intentional
  # e.g., validate failure -> execute is expected behavior
  # We only want to detect truly infinite cycles that never terminate
  # A cycle is only problematic if it has NO exit path to a terminal stage

  # Find terminal stages
  # A stage is terminal if on_success is empty (doesn't continue on success)
  # on_failure can point to retry, but if on_success is empty, the pipeline will complete
  local terminal_stages=()
  for stage in "${PIPELINE_STAGES[@]}"; do
    local success="${STAGE_ON_SUCCESS[$stage]:-}"
    # A stage is terminal if it doesn't continue on success
    if [[ -z "$success" ]]; then
      terminal_stages+=("$stage")
    fi
  done

  # If no terminal stages, it's an infinite loop
  if [[ ${#terminal_stages[@]} -eq 0 ]]; then
    echo "❌ Error: No terminal stages found - pipeline would loop forever"
    return 1
  fi

  # For now, skip the detailed cycle check for the default pipeline
  # The max_iterations guardrail will prevent infinite loops
  return 0
}

# Internal DFS cycle check (uses global CHECK_VISITED and CHECK_STACK)
_dfs_check_cycle() {
  local current="$1"

  # Check if current is in current DFS stack
  for item in "${CHECK_STACK[@]}"; do
    if [[ "$item" == "$current" ]]; then
      return 1 # Cycle detected
    fi
  done

  # Add to stack
  CHECK_STACK+=("$current")

  local success_target="${STAGE_ON_SUCCESS[$current]}"
  local failure_target="${STAGE_ON_FAILURE[$current]}"

  # Check success transition
  if [[ -n "$success_target" ]]; then
    if ! _dfs_check_cycle "$success_target"; then
      return 1
    fi
  fi

  # Check failure transition
  if [[ -n "$failure_target" ]]; then
    if ! _dfs_check_cycle "$failure_target"; then
      return 1
    fi
  fi

  # Remove from stack, add to visited
  CHECK_STACK=("${CHECK_STACK[@]/$current/}")
  CHECK_VISITED+=("$current")

  return 0
}

# Helper to check if element exists in array
contains_element() {
  local needle="$1"
  shift
  for element; do
    if [[ "$element" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

# =============================================================================
# Pipeline State Management
# =============================================================================

# Initialize pipeline state
init_pipeline_state() {
  PIPELINE_CURRENT_STAGE="$PIPELINE_INITIAL_STAGE"
  PIPELINE_CURRENT_ITERATION=0
  PIPELINE_CURRENT_ROUND=0
  PIPELINE_STATUS="running"
  PIPELINE_START_TIME=$(date +%s)
  PIPELINE_EMERGENCY_STOP=false

  # Save initial state
  save_pipeline_state

  # Initialize log
  log_pipeline_event "PIPELINE_START" "Pipeline '$PIPELINE_NAME' started"
}

# Save pipeline state to file
save_pipeline_state() {
  cat >"$PIPELINE_STATE_FILE" <<EOF
PIPELINE_NAME=$PIPELINE_NAME
PIPELINE_CURRENT_STAGE=$PIPELINE_CURRENT_STAGE
PIPELINE_CURRENT_ITERATION=$PIPELINE_CURRENT_ITERATION
PIPELINE_CURRENT_ROUND=$PIPELINE_CURRENT_ROUND
PIPELINE_STATUS=$PIPELINE_STATUS
PIPELINE_START_TIME=$PIPELINE_START_TIME
PIPELINE_ERROR=$PIPELINE_ERROR
EOF
}

# Load pipeline state from file
load_pipeline_state() {
  if [[ ! -f "$PIPELINE_STATE_FILE" ]]; then
    echo "⚠️  No saved pipeline state found"
    return 1
  fi

  source "$PIPELINE_STATE_FILE"
  echo "📂 Loaded pipeline state: $PIPELINE_STATUS (stage: $PIPELINE_CURRENT_STAGE)"
  return 0
}

# Update pipeline status
update_pipeline_status() {
  PIPELINE_STATUS="$1"
  save_pipeline_state
  log_pipeline_event "STATUS_CHANGE" "Pipeline status changed to: $1"
}

# =============================================================================
# Logging
# =============================================================================

# Log pipeline event with timestamp
log_pipeline_event() {
  local event_type="$1"
  local message="$2"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  echo "[$timestamp] [$event_type] $message" >>"$PIPELINE_LOG_FILE"

  if [[ "${RALPH_PIPELINE_LOG_VERBOSE:-false}" == "true" ]]; then
    echo "📝 [$event_type] $message"
  fi
}

# Get pipeline log
get_pipeline_log() {
  if [[ -f "$PIPELINE_LOG_FILE" ]]; then
    cat "$PIPELINE_LOG_FILE"
  else
    echo "No pipeline log found"
  fi
}

# =============================================================================
# Stage Execution
# =============================================================================

# Execute a single stage
execute_stage() {
  local stage_name="$1"
  local stage_exit_code=0

  PIPELINE_CURRENT_STAGE="$stage_name"
  PIPELINE_CURRENT_ITERATION=$((PIPELINE_CURRENT_ITERATION + 1))

  log_pipeline_event "STAGE_START" "Executing stage: $stage_name (iteration: $PIPELINE_CURRENT_ITERATION)"

  # Save state BEFORE executing stage (enables resume on interruption)
  save_pipeline_state

  # Check iteration limit
  if [[ $PIPELINE_CURRENT_ITERATION -gt $PIPELINE_MAX_ITERATIONS ]]; then
    log_pipeline_event "ITERATION_LIMIT" "Max iterations ($PIPELINE_MAX_ITERATIONS) reached"
    PIPELINE_STATUS="failed"
    PIPELINE_ERROR="Iteration limit exceeded"
    save_pipeline_state
    return 1
  fi

  # Check emergency stop
  if $PIPELINE_EMERGENCY_STOP; then
    log_pipeline_event "EMERGENCY_STOP" "Pipeline stopped by emergency signal"
    PIPELINE_STATUS="stopped"
    save_pipeline_state
    return 1
  fi

  # Get stage configuration
  local entry_command="${STAGE_ENTRY_COMMANDS[$stage_name]}"
  local validation_command="${STAGE_VALIDATION_COMMANDS[$stage_name]}"
  local stage_timeout="${STAGE_TIMEOUTS[$stage_name]:-0}"
  local ai_enabled="${STAGE_AI_VALIDATION[$stage_name]:-false}"
  local stage_desc="${STAGE_DESCRIPTIONS[$stage_name]:-}"

  echo "========================================"
  echo "🔄 Stage: $stage_name"
  [[ -n "$stage_desc" ]] && echo "   $stage_desc"
  echo "   Iteration: $PIPELINE_CURRENT_ITERATION / $PIPELINE_MAX_ITERATIONS"
  echo "========================================"

  # Execute entry command
  if [[ -n "$entry_command" ]]; then
    log_pipeline_event "STAGE_COMMAND" "Running: $entry_command"

    # Check if it's a shell function (defined in this shell)
    if declare -f "$entry_command" >/dev/null 2>&1; then
      # It's a function, call it directly in the current shell
      log_pipeline_event "STAGE_FUNCTION" "Calling function: $entry_command"
      if ! "$entry_command" 2>&1; then
        stage_exit_code=$?
      fi
    else
      # It's a command/script, run it via bash -c
      log_pipeline_event "STAGE_COMMAND" "Executing: $entry_command"
      if [[ -n "$stage_timeout" && "$stage_timeout" -gt 0 ]]; then
        echo "⏱️  Stage timeout: ${stage_timeout}s"
        if ! timeout "$stage_timeout" bash -c "$entry_command" 2>&1; then
          stage_exit_code=$?
          log_pipeline_event "STAGE_TIMEOUT" "Stage '$stage_name' timed out after ${stage_timeout}s"
        fi
      else
        if ! bash -c "$entry_command" 2>&1; then
          stage_exit_code=$?
        fi
      fi
    fi
  fi

  # Execute validation command
  local validation_passed=true
  if [[ -n "$validation_command" ]]; then
    log_pipeline_event "STAGE_VALIDATION" "Validating: $validation_command"

    # Check if it's a shell function (defined in this shell)
    if declare -f "$validation_command" >/dev/null 2>&1; then
      # It's a function, call it directly in the current shell
      if ! "$validation_command" 2>&1; then
        validation_passed=false
        stage_exit_code=1
      fi
    else
      # It's a command/script, run it via bash -c
      if ! bash -c "$validation_command" 2>&1; then
        validation_passed=false
        stage_exit_code=1
      fi
    fi
  fi

  # AI validation (if enabled)
  if [[ "$ai_enabled" == "true" && "$ai_enabled" != "false" ]]; then
    log_pipeline_event "AI_VALIDATION" "Running AI validation for stage: $stage_name"

    if ! run_ai_validation "$stage_name"; then
      validation_passed=false
      stage_exit_code=1
    fi
  fi

  # Log stage completion
  if $validation_passed; then
    log_pipeline_event "STAGE_SUCCESS" "Stage '$stage_name' completed successfully"
    echo "✅ Stage '$stage_name' completed"
  else
    log_pipeline_event "STAGE_FAILURE" "Stage '$stage_name' validation failed"
    echo "❌ Stage '$stage_name' validation failed"
  fi

  # Save state AFTER stage completion
  save_pipeline_state

  return $stage_exit_code
}

# AI validation hook
run_ai_validation() {
  local stage_name="$1"

  # This is a placeholder for AI validation
  # In a full implementation, this would call an AI agent
  # to validate the stage results

  if [[ "$RALPH_PIPELINE_AI_ENABLED" != "true" ]]; then
    return 0
  fi

  echo "🧠 Running AI validation for stage: $stage_name"

  # Placeholder: In real implementation, this would:
  # 1. Capture stage output/state
  # 2. Send to AI agent for validation
  # 3. Return validation result

  return 0
}

# =============================================================================
# Transition Engine
# =============================================================================

# Determine next stage based on exit code and configuration
get_next_stage() {
  local current_stage="$1"
  local exit_code="$2"
  local next_stage=""

  log_pipeline_event "TRANSITION" "Determining next stage from '$current_stage' (exit code: $exit_code)"

  # Determine which transition to use based on exit code
  if [[ $exit_code -eq 0 ]]; then
    # Success path
    next_stage="${STAGE_ON_SUCCESS[$current_stage]}"
  else
    # Failure path
    next_stage="${STAGE_ON_FAILURE[$current_stage]}"
  fi

  # Check for conditional transitions
  if [[ -n "$next_stage" ]]; then
    local condition_key="${current_stage}->${next_stage}"
    local condition="${TRANSITION_CONDITIONS[$condition_key]:-}"

    if [[ -n "$condition" ]]; then
      log_pipeline_event "CONDITIONAL_TRANSITION" "Evaluating condition: $condition"

      # Evaluate condition
      if ! bash -c "$condition"; then
        # Condition failed, stay on current stage or use fallback
        log_pipeline_event "CONDITION_FAILED" "Transition condition failed, staying on current stage"
        next_stage=""
      fi
    fi
  fi

  # If no next stage defined, check if this is a terminal stage
  if [[ -z "$next_stage" ]]; then
    # A stage is terminal if on_success is empty
    # (on_failure only matters when stage fails, not for success path)
    if [[ -z "${STAGE_ON_SUCCESS[$current_stage]}" ]]; then
      log_pipeline_event "TERMINAL_STAGE" "Stage '$current_stage' is terminal"
      echo ""
    else
      # Stay on current stage for retry
      next_stage="$current_stage"
      log_pipeline_event "RETRY" "No valid transition, retrying current stage"
    fi
  fi

  echo "$next_stage"
}

# =============================================================================
# Main Pipeline Runner
# =============================================================================

# Run the complete pipeline
run_pipeline() {
  # Load configuration first (must happen before printing stage info)
  if ! load_pipeline_config; then
    echo "❌ Failed to load pipeline configuration"
    return 1
  fi

  echo "🚀 Starting pipeline execution"
  echo "========================================"
  echo "   Pipeline: $PIPELINE_NAME"
  echo "   Initial Stage: $PIPELINE_INITIAL_STAGE"
  echo "   Max Iterations: $PIPELINE_MAX_ITERATIONS"
  echo "========================================"
  echo ""

  # Check for existing pipeline state and handle resume
  if check_and_handle_pipeline_resume; then
    # Resume was successful, state already loaded
    echo "▶️  Resuming from saved state..."
  else
    # No resume, initialize fresh state
    init_pipeline_state
  fi

  # Main pipeline loop
  local current_stage="$PIPELINE_CURRENT_STAGE"
  local exit_code=0
  local loop_count=0
  local max_loops=$((PIPELINE_MAX_ITERATIONS * 10)) # Safety limit

  while [[ "$PIPELINE_STATUS" == "running" && $loop_count -lt $max_loops ]]; do
    loop_count=$((loop_count + 1))
    PIPELINE_CURRENT_ROUND=$loop_count

    # Execute current stage
    if ! execute_stage "$current_stage"; then
      exit_code=$?
      log_pipeline_event "STAGE_ERROR" "Stage '$current_stage' failed with exit code: $exit_code"
    fi

    # Determine next stage
    local next_stage
    next_stage=$(get_next_stage "$current_stage" "$exit_code")

    # Check if pipeline should continue
    if [[ -z "$next_stage" ]]; then
      # Terminal stage reached
      PIPELINE_STATUS="completed"
      log_pipeline_event "PIPELINE_COMPLETE" "Pipeline completed successfully"
      echo ""
      echo "🎉 Pipeline completed successfully!"
      echo "   Total iterations: $PIPELINE_CURRENT_ITERATION"
      echo "   Total rounds: $loop_count"
      break
    fi

    # Check for infinite loop prevention
    if [[ "$next_stage" == "$current_stage" && $loop_count -gt $PIPELINE_MAX_ITERATIONS ]]; then
      PIPELINE_STATUS="failed"
      PIPELINE_ERROR="Infinite loop detected: stage '$current_stage' keeps retrying"
      log_pipeline_event "INFINITE_LOOP" "$PIPELINE_ERROR"
      echo ""
      echo "❌ Pipeline failed: $PIPELINE_ERROR"
      break
    fi

    # Transition to next stage
    current_stage="$next_stage"
    PIPELINE_CURRENT_STAGE="$current_stage"

    echo ""
    echo "➡️  Transitioning to stage: $current_stage"
    echo ""
  done

  # Check for safety limit
  if [[ $loop_count -ge $max_loops ]]; then
    PIPELINE_STATUS="failed"
    PIPELINE_ERROR="Safety limit reached ($max_loops rounds)"
    log_pipeline_event "SAFETY_LIMIT" "$PIPELINE_ERROR"
  fi

  # Save final state
  save_pipeline_state

  # Print summary
  echo ""
  echo "========================================"
  echo "📊 Pipeline Summary"
  echo "========================================"
  echo "   Status: $PIPELINE_STATUS"
  echo "   Final Stage: $PIPELINE_CURRENT_STAGE"
  echo "   Total Iterations: $PIPELINE_CURRENT_ITERATION"
  echo "   Total Rounds: $loop_count"

  if [[ -n "$PIPELINE_ERROR" ]]; then
    echo "   Error: $PIPELINE_ERROR"
  fi

  echo "========================================"

  # Return appropriate exit code
  if [[ "$PIPELINE_STATUS" == "completed" ]]; then
    return 0
  else
    return 1
  fi
}

# =============================================================================
# Pipeline Management Commands
# =============================================================================

# Validate pipeline configuration without running
validate_pipeline_config_command() {
  echo "🔍 Validating pipeline configuration..."

  if ! load_pipeline_config; then
    echo "❌ Configuration validation failed"
    return 1
  fi

  echo "✅ Configuration is valid"
  echo ""
  echo "Pipeline Details:"
  echo "   Name: $PIPELINE_NAME"
  echo "   Initial Stage: $PIPELINE_INITIAL_STAGE"
  echo "   Max Iterations: $PIPELINE_MAX_ITERATIONS"
  echo ""
  echo "Stages:"
  for stage in "${PIPELINE_STAGES[@]}"; do
    local desc="${STAGE_DESCRIPTIONS[$stage]:-No description}"
    local entry="${STAGE_ENTRY_COMMANDS[$stage]:-No command}"
    local success="${STAGE_ON_SUCCESS[$stage]:-None}"
    local failure="${STAGE_ON_FAILURE[$stage]:-None}"
    local ai="${STAGE_AI_VALIDATION[$stage]:-false}"

    echo "   - $stage"
    echo "     Description: $desc"
    echo "     Entry: $entry"
    echo "     On Success: $success"
    echo "     On Failure: $failure"
    echo "     AI Validation: $ai"
    echo ""
  done

  return 0
}

# Show current pipeline status
show_pipeline_status() {
  echo "📊 Pipeline Status"
  echo "========================================"

  if [[ -f "$PIPELINE_STATE_FILE" ]]; then
    load_pipeline_state

    echo "   Pipeline: $PIPELINE_NAME"
    echo "   Status: $PIPELINE_STATUS"
    echo "   Current Stage: $PIPELINE_CURRENT_STAGE"
    echo "   Iteration: $PIPELINE_CURRENT_ITERATION / $PIPELINE_MAX_ITERATIONS"

    if [[ -n "$PIPELINE_ERROR" ]]; then
      echo "   Error: $PIPELINE_ERROR"
    fi

    if [[ "$PIPELINE_STATUS" == "running" ]]; then
      local elapsed
      elapsed=$(($(date +%s) - PIPELINE_START_TIME))
      echo "   Elapsed: ${elapsed}s"
    fi
  else
    echo "   No pipeline state found"
    echo "   Run './ralph pipeline run' to start a new pipeline"
  fi

  echo "========================================"
  echo ""
  echo "Pipeline Log:"
  echo "-----------------------------------"
  get_pipeline_log | tail -20
}

# Reset pipeline state
reset_pipeline_state() {
  echo "🔄 Resetting pipeline state..."

  if [[ -f "$PIPELINE_STATE_FILE" ]]; then
    rm -f "$PIPELINE_STATE_FILE"
    echo "✅ State file removed"
  else
    echo "⚠️  No state file to remove"
  fi

  if [[ -f "$PIPELINE_LOG_FILE" ]]; then
    rm -f "$PIPELINE_LOG_FILE"
    echo "✅ Log file removed"
  else
    echo "⚠️  No log file to remove"
  fi

  echo "✅ Pipeline state reset complete"
}

# Emergency stop
emergency_stop_pipeline() {
  echo "🛑 EMERGENCY STOP triggered"
  PIPELINE_EMERGENCY_STOP=true

  # Kill any running processes
  if [[ -n "$OPENCODE_PID" ]]; then
    kill -9 "$OPENCODE_PID" 2>/dev/null || true
  fi

  if [[ -f "$PIPELINE_STATE_FILE" ]]; then
    PIPELINE_STATUS="stopped"
    PIPELINE_ERROR="Emergency stop triggered"
    save_pipeline_state
  fi

  echo "✅ Pipeline stopped"
}

# =============================================================================
# Pipeline Resume Functions
# =============================================================================

# Prompt user about existing pipeline state
prompt_pipeline_resume() {
  local session_id="$1"
  local session_dir
  session_dir=$(get_session_dir "$session_id")

  # Read session details
  local iteration pipeline_stage max_iterations
  iteration=$(grep '"iteration"' "${session_dir}/session.json" | sed 's/.*: *\([0-9]*\).*/\1/')
  pipeline_stage=$(grep '"pipeline_stage"' "${session_dir}/session.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
  max_iterations=$(grep '"max_iterations"' "${session_dir}/session.json" | sed 's/.*: *\([0-9]*\).*/\1/')

  echo ""
  echo "========================================"
  echo "⚠️  Existing pipeline state found!"
  echo "========================================"
  echo ""
  echo "Session: $session_id"
  echo "Stage: ${pipeline_stage:-unknown}"
  echo "Iteration: $iteration / $max_iterations"
  echo "Status: incomplete"
  echo ""
  echo "Options:"
  echo "  [R] Resume from this state"
  echo "  [N] Start new pipeline (keeps old session)"
  echo "  [X] Cancel"
  echo ""
  echo -n "Choose: "

  local choice
  read -r choice

  case "${choice^^}" in
  R)
    echo ""
    echo "▶️  Resuming pipeline..."
    return 0
    ;;
  N)
    echo ""
    echo "🔄 Starting new pipeline..."
    return 1
    ;;
  X | *)
    echo ""
    echo "❌ Cancelled."
    exit 1
    ;;
  esac
}

# Prompt for iteration count when resuming
prompt_iteration_count() {
  local resume_iteration="$1"
  local current_max="$2"

  local remaining=$((current_max - resume_iteration))
  local new_total=$current_max

  echo ""
  echo "========================================"
  echo "📊 Iteration Count Configuration"
  echo "========================================"
  echo ""
  echo "Current max iterations: $current_max"
  echo "Resume from iteration: $resume_iteration"
  echo "Remaining iterations: $remaining"
  echo ""
  echo -n "Enter new total [$current_max]: "

  local input
  read -r input

  if [[ -n "$input" && "$input" =~ ^[0-9]+$ ]]; then
    new_total="$input"
  fi

  echo ""
  echo "📝 Will run $((new_total - resume_iteration)) more iterations (total: $new_total)"
  echo ""

  # Return the new max iterations
  echo "$new_total"
}

# Check for existing pipeline session and handle resume logic
check_and_handle_pipeline_resume() {
  local session_id
  session_id=$(find_latest_pipeline_session)

  if [ -z "$session_id" ]; then
    # No existing session found, start fresh
    return 1
  fi

  # Check for --force-resume flag
  if [[ "${RALPH_FORCE_RESUME:-false}" == "true" ]]; then
    echo "▶️  Force resuming from existing session: $session_id"
    resume_session "$session_id" true
    return 0
  fi

  # Prompt user
  if prompt_pipeline_resume "$session_id"; then
    # User chose to resume
    local resume_iteration
    resume_iteration=$(resume_session "$session_id" true | tail -1)

    # Prompt for iteration count
    local new_max
    new_max=$(prompt_iteration_count "$resume_iteration" "$PIPELINE_MAX_ITERATIONS")

    if [[ -n "$new_max" && "$new_max" =~ ^[0-9]+$ ]]; then
      PIPELINE_MAX_ITERATIONS="$new_max"
    fi

    # Load pipeline state from session
    load_pipeline_from_session "$session_id"
    return 0
  else
    # User chose to start new, keep old session
    echo "🔄 Starting fresh pipeline. Old session preserved: $session_id"
    return 1
  fi
}

# Resume pipeline from saved state (command entry point)
resume_pipeline_command() {
  local force="${1:-false}"

  echo "🔄 Checking for pipeline session to resume..."

  # Try to find latest pipeline session
  local session_id
  session_id=$(find_latest_pipeline_session)

  if [ -z "$session_id" ]; then
    echo "❌ No pipeline session found to resume"
    echo "   Run './ralph pipeline run' to start a new pipeline"
    return 1
  fi

  echo "📂 Found session: $session_id"

  # Load session
  local resume_iteration
  resume_iteration=$(resume_session "$session_id" true | tail -1)

  if [ -z "$resume_iteration" ]; then
    echo "❌ Failed to resume session"
    return 1
  fi

  # Load pipeline state
  load_pipeline_from_session "$session_id"

  echo "✅ Pipeline state loaded"
  echo ""
  echo "🚀 Starting pipeline from saved state..."

  # Run the pipeline (it will pick up from loaded state)
  run_pipeline
}

# =============================================================================
# Default Stage Commands (called by pipeline)
# =============================================================================

# Plan stage command - analyze task and create implementation plan
run_plan_stage() {
  echo "📋 Running planning stage..."

  # Check if prompt is already set via environment variable
  if [ -n "${RALPH_PROMPT:-}" ]; then
    echo "📄 Using RALPH_PROMPT environment variable"
    echo "$RALPH_PROMPT" >"$PROMPT_FILE"

  # Check if prompt file is provided via environment variable
  elif [ -n "${RALPH_PROMPT_FILE:-}" ]; then
    if [ -f "$RALPH_PROMPT_FILE" ]; then
      echo "📄 Using RALPH_PROMPT_FILE: $RALPH_PROMPT_FILE"
      cp "$RALPH_PROMPT_FILE" "$PROMPT_FILE"
    else
      echo "❌ Error: RALPH_PROMPT_FILE not found: $RALPH_PROMPT_FILE"
      return 1
    fi

  # Check if prompt.md exists in current directory
  elif [ -f "prompt.md" ]; then
    echo "📄 Using prompt.md from current directory"
    cp "prompt.md" "$PROMPT_FILE"

  # Check if PROMPT_FILE already exists (from resume or previous iteration)
  elif [ -f "$PROMPT_FILE" ]; then
    echo "📄 Using existing PROMPT_FILE"

  # No prompt provided - need to create one
  else
    echo "📝 No prompt found. Creating one..."

    # Check if we have a TTY for interactive mode
    if [ -t 0 ]; then
      # Interactive mode - use the full prompt creation flow
      local prompt_content
      prompt_content=$(get_prompt)

      if [ -z "$prompt_content" ]; then
        echo "❌ Error: No prompt was created. Aborting."
        return 1
      fi

      # Save the prompt content to PROMPT_FILE for the pipeline
      echo "$prompt_content" >"$PROMPT_FILE"
      echo "✅ Prompt created and saved"
    else
      # Non-interactive mode - create a default prompt
      echo "⚠️  No prompt found in non-interactive mode"
      echo "   Creating default prompt..."
      cat >"$PROMPT_FILE" <<'EOF'
# Default Task

## Goal
Complete the work required by the system.

## Acceptance Criteria
- [ ] Work is completed successfully
- [ ] All tests pass
- [ ] Code is clean and functional
EOF
      echo "✅ Default prompt created"
    fi
  fi

  # Read and display the prompt
  if [ -f "$PROMPT_FILE" ]; then
    echo ""
    echo "========================================"
    echo "📋 PROJECT PROMPT"
    echo "========================================"
    head -30 "$PROMPT_FILE"
    if [ $(wc -l <"$PROMPT_FILE") -gt 30 ]; then
      echo "   ... (truncated)"
    fi
    echo "========================================"
    echo ""
  else
    echo "❌ Error: PROMPT_FILE was not created"
    return 1
  fi

  return 0
}

# Check if plan is complete
check_plan_complete() {
  # This checks if the planning phase is complete
  # In a real implementation, this would verify a plan was created
  return 0
}

# Execute stage command - execute the planned implementation
run_execute_stage() {
  echo "🚀 Running execution stage..."

  # Ensure we have a prompt file
  if [ ! -f "$PROMPT_FILE" ]; then
    echo "❌ Error: No prompt file found. Cannot execute."
    return 1
  fi

  # Read progress if exists
  local progress_content=""
  if [ -f "$PROGRESS_FILE" ]; then
    progress_content=$(cat "$PROGRESS_FILE")
  fi

  # Read prompt
  local prompt_content
  prompt_content=$(cat "$PROMPT_FILE")

  # Sanitize content to prevent heredoc injection
  local sanitized_progress
  local sanitized_prompt
  sanitized_progress=$(sanitize_for_heredoc "$progress_content")
  sanitized_prompt=$(sanitize_for_heredoc "$prompt_content")

  # Build the prompt for OpenCode
  local tmp_prompt_file="${TEMP_FILE_PREFIX}_prompt.txt"

  # Check if we're resuming from a pipeline state
  local pipeline_context=""
  if [[ -n "$PIPELINE_CURRENT_STAGE" && "$PIPELINE_CURRENT_ITERATION" -gt 0 ]]; then
    pipeline_context="
## Pipeline State (Resumed)
- Current Stage: $PIPELINE_CURRENT_STAGE
- Iteration: $PIPELINE_CURRENT_ITERATION / $PIPELINE_MAX_ITERATIONS
- Previous work completed: See progress.md below
"
  fi

  cat >"$tmp_prompt_file" <<EOF
# Goals and Resources

## Project plan

${sanitized_prompt}

${pipeline_context}
## Current Progress

${sanitized_progress}
${RALPH_PROMPTS}
EOF

  echo "📦 Building OpenCode options..."
  build_opencode_opts

  echo "🚀 Starting agent execution..."
  echo "   (This may take a moment. Progress will be shown below.)"
  echo ""

  # Run opencode
  set +e
  local output_file="${TEMP_FILE_PREFIX}_output.txt"
  opencode run "${OPENCODE_OPTS[@]}" <"$tmp_prompt_file" 2>&1 | tee "$output_file"
  local exit_code=$?
  set -e

  rm -f "$tmp_prompt_file"

  if [ $exit_code -ne 0 ]; then
    echo "⚠️  Process exited with code: $exit_code"
  fi

  # Check for completion
  local result
  result=$(cat "$output_file" 2>/dev/null | tr -d '\0' || echo "")

  rm -f "$output_file"

  if echo "$result" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "✅ Agent indicated completion with <promise>COMPLETE</promise>"
    EXECUTION_COMPLETE=true
    return 0
  else
    echo ""
    echo "⏳ Agent did not complete yet. Will continue in next iteration."
    EXECUTION_COMPLETE=false
    return 1
  fi
}

# Check if execution is complete (for execute stage validation)
check_execution_complete() {
  # This checks if the main workload is complete
  # It reads the EXECUTION_COMPLETE variable set by run_execute_stage
  if $EXECUTION_COMPLETE; then
    return 0
  else
    return 1
  fi
}

# Validate stage command - validate execution results and quality
run_validate_stage() {
  echo "🛡️ Running validation stage..."

  # Check if we have a prompt to validate against
  local prompt_content
  prompt_content=$(get_prompt_nointeractive)

  if [ -z "$prompt_content" ] || echo "$prompt_content" | grep -q "No original prompt available"; then
    echo "⚠️  No prompt found to validate against. Skipping validation."
    return 0
  fi

  echo "📋 Validating against original project goals..."

  # Build validation prompt
  build_validation_opencode_opts

  local validation_prompt_file="${TEMP_FILE_PREFIX}_validation.txt"
  cat >"$validation_prompt_file" <<EOF
# Validation Task

The agent previously indicated completion with <promise>COMPLETE</promise>.

You must INDEPENDENTLY VERIFY that all acceptance criteria are actually met.

## Original Project Goal:
$(get_prompt_nointeractive)

## Your Validation Task:

1. READ the current state of the project
2. CHECK each acceptance criterion is actually satisfied:
   - For each requirement, verify it exists and works
   - Run tests, build commands, and manual checks
3. RUN comprehensive verification:
   - [ ] Code compiles/builds without errors
   - [ ] Tests pass (if applicable)
   - [ ] No linting errors
   - [ ] All acceptance criteria from prompt are met
   - [ ] No regressions in existing functionality
4. OUTPUT your findings in this exact XML format:

<validation_status>PASS</validation_status>  OR  <validation_status>FAIL</validation_status>

<validation_issues>
- List each failing criterion with specific details
- Leave empty if PASS
</validation_issues>

<validation_recommendations>
- Specific actions needed to fix each issue
- Leave empty if PASS
</validation_recommendations>

IMPORTANT:
- If ALL checks pass, use <validation_status>PASS</validation_status>
- If ANY check fails, use <validation_status>FAIL</validation_status> and list all issues
- Do NOT trust the previous agent's assessment. Verify independently.
EOF

  echo "🧠 Running independent validation..."

  # Run validation with validation agent
  set +e
  local validation_output="${TEMP_FILE_PREFIX}_validation_output.txt"
  opencode run "${VALIDATION_OPENCODE_OPTS[@]}" "$validation_prompt_file" 2>&1 | tee "$validation_output"
  local validation_exit_code=$?
  set -e

  rm -f "$validation_prompt_file"

  if [ $validation_exit_code -ne 0 ]; then
    echo "⚠️  Validation process exited with code: $validation_exit_code"
  fi

  # Extract validation status
  local validation_status
  validation_status=$(get_validation_status "$(cat "$validation_output" 2>/dev/null || echo "")")

  rm -f "$validation_output"

  if [ "$validation_status" = "PASS" ]; then
    echo ""
    echo "🎉 Validation PASSED!"
    VALIDATION_PASSED=true
    return 0
  else
    echo ""
    echo "⚠️  Validation FAILED"
    echo "   The agent will need to fix issues in the next iteration."
    VALIDATION_PASSED=false
    return 1
  fi
}

# Check if validation passed
check_validation_passed() {
  # This checks if validation criteria are met
  # It reads the VALIDATION_PASSED variable set by run_validate_stage
  if $VALIDATION_PASSED; then
    return 0
  else
    return 1
  fi
}
