#!/usr/bin/env bash

# lib/pipeline.sh - Configurable Multi-Stage Pipeline Framework for RalphLoop
# Depends on: core.sh, sessions.sh
#
# This module provides a configuration-driven pipeline orchestration system
# that replaces the hardcoded execute -> validate -> finalize flow.

# =============================================================================
# Pipeline Configuration Variables
# =============================================================================

# Pipeline configuration file paths (checked in order)
PIPELINE_CONFIG_FILES=("pipeline.yaml" "pipeline.yml" "pipeline.json")

# Pipeline state file
PIPELINE_STATE_FILE="${TEMP_FILE_PREFIX}_pipeline_state.txt"

# Pipeline log file
PIPELINE_LOG_FILE="${TEMP_FILE_PREFIX}_pipeline.log"

# Default pipeline configuration (used when no config file found)
PIPELINE_NAME="${PIPELINE_NAME:-default}"
PIPELINE_MAX_ITERATIONS="${PIPELINE_MAX_ITERATIONS:-100}"
PIPELINE_INITIAL_STAGE="${PIPELINE_INITIAL_STAGE:-execute}"

# Pipeline state variables
PIPELINE_CURRENT_STAGE=""
PIPELINE_CURRENT_ITERATION=0
PIPELINE_CURRENT_ROUND=0
PIPELINE_START_TIME=""
PIPELINE_STATUS="idle" # idle, running, completed, failed, stopped
PIPELINE_ERROR=""

# Stage definitions (populated by config parser)
declare -A STAGE_ENTRY_COMMANDS
declare -A STAGE_VALIDATION_COMMANDS
declare -A STAGE_ON_SUCCESS
declare -A STAGE_ON_FAILURE
declare -A STAGE_TIMEOUTS
declare -A STAGE_AI_VALIDATION
declare -A STAGE_DESCRIPTIONS

# Transition rules (populated by config parser)
declare -A TRANSITION_CONDITIONS

# Available stages (populated by config parser)
PIPELINE_STAGES=()

# AI validation enabled (global flag)
RALPH_PIPELINE_AI_ENABLED="${RALPH_PIPELINE_AI_ENABLED:-false}"

# Emergency stop flag
PIPELINE_EMERGENCY_STOP=false

# =============================================================================
# Configuration File Discovery and Parsing
# =============================================================================

# Find and load pipeline configuration
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
    echo "   Using default pipeline configuration (execute -> validate -> finalize)"
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

# Load default pipeline configuration (execute -> validate -> finalize)
load_default_pipeline_config() {
  PIPELINE_NAME="default"
  PIPELINE_MAX_ITERATIONS="${MAX_ROUNDS:-100}"
  PIPELINE_INITIAL_STAGE="execute"

  # Clear existing stage definitions
  unset STAGE_ENTRY_COMMANDS STAGE_VALIDATION_COMMANDS STAGE_ON_SUCCESS
  unset STAGE_ON_FAILURE STAGE_TIMEOUTS STAGE_AI_VALIDATION STAGE_DESCRIPTIONS
  unset TRANSITION_CONDITIONS
  declare -gA STAGE_ENTRY_COMMANDS STAGE_VALIDATION_COMMANDS STAGE_ON_SUCCESS
  declare -gA STAGE_ON_FAILURE STAGE_TIMEOUTS STAGE_AI_VALIDATION STAGE_DESCRIPTIONS
  declare -gA TRANSITION_CONDITIONS

  # Define execute stage
  STAGE_DESCRIPTIONS["execute"]="Execute the main workload"
  STAGE_ENTRY_COMMANDS["execute"]="run_agent_execution"
  STAGE_VALIDATION_COMMANDS["execute"]="check_execution_complete"
  STAGE_ON_SUCCESS["execute"]="validate"
  STAGE_ON_FAILURE["execute"]="finalize"
  STAGE_TIMEOUTS["execute"]="${RALPH_TIMEOUT:-1800}"
  STAGE_AI_VALIDATION["execute"]="false"

  # Define validate stage
  STAGE_DESCRIPTIONS["validate"]="Validate execution results"
  STAGE_ENTRY_COMMANDS["validate"]="run_validation"
  STAGE_VALIDATION_COMMANDS["validate"]="check_validation_passed"
  STAGE_ON_SUCCESS["validate"]="finalize"
  STAGE_ON_FAILURE["validate"]="execute" # Loop back to execute on failure
  STAGE_TIMEOUTS["validate"]="300"
  STAGE_AI_VALIDATION["validate"]="${RALPH_PIPELINE_AI_ENABLED:-false}"

  # Define finalize stage
  STAGE_DESCRIPTIONS["finalize"]="Finalize and complete the pipeline"
  STAGE_ENTRY_COMMANDS["finalize"]="run_finalization"
  STAGE_VALIDATION_COMMANDS["finalize"]=""
  STAGE_ON_SUCCESS["finalize"]=""
  STAGE_ON_FAILURE["finalize"]=""
  STAGE_TIMEOUTS["finalize"]="120"
  STAGE_AI_VALIDATION["finalize"]="false"

  # Define transitions
  PIPELINE_STAGES=("execute" "validate" "finalize")
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

  # Find terminal stages (no transitions defined)
  local terminal_stages=()
  for stage in "${PIPELINE_STAGES[@]}"; do
    local success="${STAGE_ON_SUCCESS[$stage]:-}"
    local failure="${STAGE_ON_FAILURE[$stage]:-}"
    if [[ -z "$success" && -z "$failure" ]]; then
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

  if [[ "$RALPH_PIPELINE_LOG_VERBOSE" == "true" ]]; then
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

    # Run with timeout if specified
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

  # Execute validation command
  local validation_passed=true
  if [[ -n "$validation_command" ]]; then
    log_pipeline_event "STAGE_VALIDATION" "Validating: $validation_command"

    if ! bash -c "$validation_command" 2>&1; then
      validation_passed=false
      stage_exit_code=1
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
    if [[ -z "${STAGE_ON_SUCCESS[$current_stage]}" && -z "${STAGE_ON_FAILURE[$current_stage]}" ]]; then
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
  echo "🚀 Starting pipeline execution"
  echo "========================================"
  echo "   Pipeline: $PIPELINE_NAME"
  echo "   Initial Stage: $PIPELINE_INITIAL_STAGE"
  echo "   Max Iterations: $PIPELINE_MAX_ITERATIONS"
  echo "========================================"
  echo ""

  # Load configuration
  if ! load_pipeline_config; then
    echo "❌ Failed to load pipeline configuration"
    return 1
  fi

  # Initialize state
  init_pipeline_state

  # Check for saved state (resume capability)
  if [[ -f "$PIPELINE_STATE_FILE" ]]; then
    echo "📂 Found saved pipeline state. Loading..."
    load_pipeline_state

    if [[ "$PIPELINE_STATUS" == "running" ]]; then
      echo "▶️  Resuming pipeline from stage: $PIPELINE_CURRENT_STAGE"
    fi
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
# Default Stage Commands (called by pipeline)
# =============================================================================

# Default execution stage command
run_agent_execution() {
  # This calls the main agent execution logic
  # In a full implementation, this would integrate with the existing run_main_loop
  echo "🚀 Running agent execution..."

  # For now, just return success to test the pipeline flow
  return 0
}

# Default validation stage command
run_validation() {
  echo "🛡️ Running validation..."

  # This would run the validation logic from the existing system
  # For now, just return success to test the pipeline flow
  return 0
}

# Default finalization stage command
run_finalization() {
  echo "🎉 Running finalization..."

  # This would run the completion logic
  # For now, just return success to test the pipeline flow
  return 0
}

# Check if execution is complete (for execute stage validation)
check_execution_complete() {
  # This checks if the main workload is complete
  # In a real implementation, this would check for <promise>COMPLETE</promise>
  return 1 # Return failure to continue pipeline (testing)
}

# Check if validation passed
check_validation_passed() {
  # This checks if validation criteria are met
  # In a real implementation, this would check validation results
  return 0 # Return success to move to finalize
}
