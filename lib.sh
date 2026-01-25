#!/usr/bin/env bash

# lib.sh - Unified loader for RalphLoop modular library
# This file sources all lib modules in dependency order
#
# Usage: source lib.sh

# Get the directory where this script is located
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# Core Module (no dependencies)
# =============================================================================
source "${LIB_DIR}/lib/core.sh"

# =============================================================================
# Arguments Module (no dependencies)
# =============================================================================
if [ -f "${LIB_DIR}/lib/args.sh" ]; then
  source "${LIB_DIR}/lib/args.sh"
fi

# =============================================================================
# Sessions Module (depends on core.sh)
# =============================================================================
if [ -f "${LIB_DIR}/lib/sessions.sh" ]; then
  source "${LIB_DIR}/lib/sessions.sh"
fi

# =============================================================================
# Templates Module (no dependencies)
# =============================================================================
if [ -f "${LIB_DIR}/lib/templates.sh" ]; then
  source "${LIB_DIR}/lib/templates.sh"
fi

# =============================================================================
# AI Module (no dependencies)
# =============================================================================
if [ -f "${LIB_DIR}/lib/ai.sh" ]; then
  source "${LIB_DIR}/lib/ai.sh"
fi

# =============================================================================
# Prompt Module (depends on sessions.sh, templates.sh, ai.sh)
# =============================================================================
if [ -f "${LIB_DIR}/lib/prompt.sh" ]; then
  source "${LIB_DIR}/lib/prompt.sh"
fi

# =============================================================================
# Execution Module (depends on core.sh, sessions.sh, prompt.sh)
# =============================================================================
if [ -f "${LIB_DIR}/lib/exec.sh" ]; then
  source "${LIB_DIR}/lib/exec.sh"
fi

# =============================================================================
# Pipeline Module (depends on core.sh, sessions.sh)
# =============================================================================
if [ -f "${LIB_DIR}/lib/pipeline.sh" ]; then
  source "${LIB_DIR}/lib/pipeline.sh"
fi
