# Claude Code Backend Integration

This document describes how to integrate RalphLoop with Claude Code CLI for autonomous development workflows.

## Overview

Claude Code is Anthropic's CLI tool for autonomous development. This backend integration allows you to trigger RalphLoop evaluation loops directly from Claude Code commands, enabling seamless integration between the two systems.

## Installation

### Prerequisites

- Claude Code CLI installed and configured
- Node.js v18+
- npm or yarn package manager

### Install Claude Code CLI

```bash
# Using npm
npm install -g @anthropic-ai/claude-code-cli

# Verify installation
claude --version
```

### Configure RalphLoop Integration

```bash
# Enable Claude Code backend
ralph-config --enable claude-code

# Set API key (if required)
export CLAUDE_API_KEY="your_anthropic_api_key_here"

# Verify configuration
ralph-config --get backends.claude-code.enabled
```

## Usage

### Basic Commands

#### Trigger Evaluation Loop

```bash
# Run autonomous development for 5 iterations
claude ralph-trigger --iterations 5 --mode autonomous

# Run with specific prompt file
claude ralph-trigger --prompt ./custom-prompt.md --iterations 10

# Run in validation mode
claude ralph-trigger --mode validation

# Run in interactive mode
claude ralph-trigger --mode interactive
```

#### Check Status

```bash
# Show current state summary
claude ralph-status --state

# Show detailed progress information
claude ralph-status --progress

# Show backend status
claude ralf-status --backends

# Show all information
claude ralph-status --verbose
```

#### Configure Settings

```bash
# Get configuration value
claude ralph-config --get evaluation.maxIterations

# Set configuration value
claude ralph-config --set evaluation.maxIterations=50

# List all configuration
claude ralph-config --list

# Enable/disable backends
claude ralph-config --enable codex
claude ralph-config --disable kilo
```

### Custom Commands

The integration supports the following custom commands:

- `claude evaluate [iterations]` - Start evaluation loop
- `claude status` - Check current status
- `claude validate` - Validate current state

### Environment Variables

Configure the integration using environment variables:

```bash
# Set evaluation mode
export RALPH_MODE=autonomous

# Set backend to use
export RALPH_BACKEND=claude-code

# Set number of iterations
export RALPH_ITERATIONS=5

# Direct prompt
export RALPH_PROMPT="Build a REST API for user management"

# Prompt file path
export RALPH_PROMPT_FILE=/path/to/prompt.md
```

## Configuration

### Main Configuration File

The main configuration is stored in `backends/index.json`:

```json
{
  "backends": {
    "claude-code": {
      "enabled": true,
      "name": "Claude Code CLI",
      "description": "Anthropic's Claude Code CLI integration"
    }
  },
  "evaluation": {
    "modes": ["autonomous", "interactive", "validation"],
    "defaultMode": "autonomous",
    "maxIterations": 100
  }
}
```

### Backend-Specific Configuration

Individual backend settings are in `backends/claude-code/config.json`:

```json
{
  "enabled": true,
  "cli": {
    "name": "claude",
    "installUrl": "https://github.com/anthropics/claude-code-cli"
  },
  "integration": {
    "evaluationTrigger": {
      "command": "ralph-trigger",
      "arguments": ["--iterations", "--prompt", "--mode"]
    }
  },
  "hooks": {
    "preEvaluation": [],
    "postEvaluation": [],
    "onError": ["logError", "notifyUser"]
  }
}
```

## Examples

### Example 1: Autonomous Development Session

```bash
# Start a 10-iteration autonomous development session
claude ralph-trigger --iterations 10 --mode autonomous --prompt ./project-prompt.md
```

### Example 2: Validation Check

```bash
# Run validation to check current project state
claude ralph-trigger --mode validation
```

### Example 3: Interactive Development

```bash
# Start interactive development with user feedback
claude ralph-trigger --mode interactive --iterations 5
```

### Example 4: Configure and Run

```bash
# Configure settings
claude ralph-config --set evaluation.maxIterations=25
claude ralph-config --set evaluation.defaultMode=autonomous

# Start evaluation
claude ralph-trigger --iterations 25
```

## Integration Hooks

The integration supports the following hooks:

### Pre-Evaluation Hooks

Runs before the evaluation loop starts:

```json
"preEvaluation": [
  "validateEnvironment",
  "checkDependencies"
]
```

### Post-Evaluation Hooks

Runs after the evaluation loop completes:

```json
"postEvaluation": [
  "generateReport",
  "notifyCompletion"
]
```

### Error Handling Hooks

Runs when an error occurs:

```json
"onError": [
  "logError",
  "notifyUser",
  "cleanupResources"
]
```

## Troubleshooting

### Installation Issues

**Problem**: Claude Code CLI not found

```bash
# Check if claude command is available
which claude

# If not found, add to PATH
export PATH="$PATH:$(npm global bin)"

# Or reinstall
npm install -g @anthropic-ai/claude-code-cli
```

**Problem**: Authentication failed

```bash
# Set API key
export CLAUDE_API_KEY="your_api_key"

# Login to Claude Code
claude login
```

### Configuration Issues

**Problem**: Backend not enabled

```bash
# Enable the backend
ralph-config --enable claude-code

# Verify status
ralph-status --backends
```

**Problem**: Invalid configuration

```bash
# Reset to defaults
ralph-config --reset

# Reconfigure
ralph-config --enable claude-code
```

### Runtime Issues

**Problem**: Evaluation loop fails to start

```bash
# Check RalphLoop script
ls -la ralph

# Make executable
chmod +x ralph

# Test manually
./ralph 1
```

**Problem**: Permission denied errors

```bash
# Check file permissions
ls -la bin/

# Fix permissions
chmod +x bin/*
```

## Advanced Usage

### Script Integration

Integrate RalphLoop into your build scripts:

```bash
#!/bin/bash
# build.sh

# Run autonomous development
claude ralph-trigger --iterations 20 --mode autonomous

# Check results
if [ $? -eq 0 ]; then
    echo "✅ Development completed successfully"
else
    echo "❌ Development failed"
    exit 1
fi
```

### CI/CD Pipeline Integration

```yaml
# .github/workflows/ralphloop.yml
name: RalphLoop Development

on:
  schedule:
    - cron: '0 0 * * 0' # Weekly development cycle
  workflow_dispatch:
    inputs:
      iterations:
        description: 'Number of iterations'
        required: true
        default: '10'

jobs:
  develop:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install Dependencies
        run: |
          npm install -g @anthropic-ai/claude-code-cli
          chmod +x ralph bin/*

      - name: Run RalphLoop
        env:
          CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
          RALPH_MODE: autonomous
        run: |
          claude ralph-trigger --iterations ${{ github.event.inputs.iterations || 10 }}
```

## Best Practices

1. **Start Small**: Begin with 1-2 iterations to validate the setup
2. **Monitor Progress**: Use `ralph-status --progress` to track iterations
3. **Backup Configuration**: Keep backups of working configurations
4. **Use Version Control**: Commit configuration changes to git
5. **Test in Staging**: Validate new configurations in a test environment first

## Additional Resources

- [RalphLoop Documentation](../README.md)
- [Claude Code CLI Documentation](https://github.com/anthropics/claude-code-cli)
- [OpenCode Documentation](https://opencode.ai/docs)
- [GitHub Issues](https://github.com/rwese/RalphLoop/issues)

## Support

For issues and questions:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review [GitHub Issues](https://github.com/rwese/RalphLoop/issues)
3. Create a new issue if your problem isn't listed
