# Kilo CLI Backend Integration

This document describes how to integrate RalphLoop with Kilo CLI for autonomous development workflows.

## Overview

Kilo CLI is a specialized tool for autonomous development workflows. This backend integration allows you to trigger RalphLoop evaluation loops directly from Kilo commands, providing a streamlined development experience.

## Installation

### Prerequisites

- Kilo CLI installed and configured
- Node.js v18+
- npm or yarn package manager
- Kilo API key (if required)

### Install Kilo CLI

```bash
# Using npm
npm install -g kilo-cli

# Verify installation
kilo --version
```

### Configure RalphLoop Integration

```bash
# Enable Kilo backend
ralph-config --enable kilo

# Set API key (if required)
export KILO_API_KEY="your_kilo_api_key_here"

# Verify configuration
ralph-config --get backends.kilo.enabled
```

## Usage

### Basic Commands

#### Trigger Evaluation Loop

```bash
# Run autonomous development for 5 iterations
kilo ralph-trigger --iterations 5 --mode autonomous

# Run with specific prompt file
kilo ralph-trigger --prompt ./custom-prompt.md --iterations 10

# Run in validation mode
kilo ralph-trigger --mode validation

# Run in interactive mode
kilo ralph-trigger --mode interactive
```

#### Check Status

```bash
# Show current state summary
kilo ralph-status --state

# Show detailed progress information
kilo ralph-status --progress

# Show backend status
kilo ralf-status --backends

# Show all information
kilo ralph-status --verbose
```

#### Configure Settings

```bash
# Get configuration value
kilo ralph-config --get evaluation.maxIterations

# Set configuration value
kilo ralph-config --set evaluation.maxIterations=50

# List all configuration
kilo ralph-config --list

# Enable/disable backends
kilo ralph-config --enable claude-code
kilo ralph-config --disable codex
```

### Custom Commands

The integration supports the following custom commands:

- `kilo evaluate [iterations]` - Start evaluation loop
- `kilo status` - Check current status
- `kilo validate` - Validate current state

### Environment Variables

Configure the integration using environment variables:

```bash
# Set evaluation mode
export RALPH_MODE=autonomous

# Set backend to use
export RALPH_BACKEND=kilo

# Set number of iterations
export RALPH_ITERATIONS=5

# Direct prompt
export RALPH_PROMPT="Build a REST API for user management"

# Prompt file path
export RALPH_PROMPT_FILE=/path/to/prompt.md

# Kilo API key
export KILO_API_KEY="your_api_key"
```

## Configuration

### Main Configuration File

The main configuration is stored in `backends/index.json`:

```json
{
  "backends": {
    "kilo": {
      "enabled": true,
      "name": "Kilo CLI",
      "description": "Kilo CLI integration for autonomous development"
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

Individual backend settings are in `backends/kilo/config.json`:

```json
{
  "enabled": true,
  "cli": {
    "name": "kilo",
    "installUrl": "https://github.com/kilo-cli/kilo"
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
  },
  "environment": {
    "KILO_API_KEY": {
      "required": false,
      "description": "Kilo API key for services"
    }
  }
}
```

## Features

### Workflow Automation

The Kilo backend provides advanced workflow automation:

- **Task Orchestration**: Coordinate complex development tasks
- **State Management**: Track and restore development state
- **Progress Tracking**: Detailed progress monitoring
- **Error Recovery**: Automatic error detection and recovery

### Development Modes

#### Autonomous Mode

In autonomous mode, Kilo and RalphLoop work together:

1. Kilo orchestrates the development workflow
2. RalphLoop implements changes
3. Kilo validates results
4. Loop continues until goals are met

#### Interactive Mode

In interactive mode, you maintain control:

1. Kilo presents options and progress
2. You approve or modify actions
3. RalphLoop implements approved changes
4. Continuous feedback loop

#### Validation Mode

In validation mode, Kilo reviews the current state:

1. Analyze current development state
2. Identify issues and improvements
3. Generate validation report
4. Provide recommendations

## Examples

### Example 1: Autonomous Project Setup

```bash
# Start autonomous project setup
kilo ralph-trigger --iterations 10 --mode autonomous --prompt ./project-setup.md
```

### Example 2: Interactive Development

```bash
# Start interactive development session
kilo ralph-trigger --mode interactive --iterations 5
```

### Example 3: Validation and Testing

```bash
# Run comprehensive validation
kilo ralph-trigger --mode validation --prompt ./test-prompt.md
```

### Example 4: Configure for Complex Workflows

```bash
# Configure for complex workflow automation
kilo ralph-config --set evaluation.maxIterations=30
kilo ralph-config --set evaluation.defaultMode=autonomous

# Start advanced workflow
kilo ralph-trigger --iterations 30 --prompt ./workflow.md
```

## Integration Hooks

The integration supports the following hooks:

### Pre-Evaluation Hooks

Runs before the evaluation loop starts:

```json
"preEvaluation": [
  "validateWorkflow",
  "checkPrerequisites",
  "setupEnvironment"
]
```

### Post-Evaluation Hooks

Runs after the evaluation loop completes:

```json
"postEvaluation": [
  "generateWorkflowReport",
  "archiveArtifacts",
  "notifyCompletion"
]
```

### Error Handling Hooks

Runs when an error occurs:

```json
"onError": [
  "logWorkflowError",
  "attemptRecovery",
  "cleanupResources"
]
```

## Advanced Usage

### Custom Workflow Prompts

Create specialized prompts for different workflow types:

```markdown
# workflow-prompt.md

## Goal

Set up a complete CI/CD pipeline for the project

## Requirements

1. GitHub Actions workflow
2. Automated testing
3. Deployment automation
4. Monitoring setup
5. Documentation

## Current State

- Basic Node.js project
- Existing unit tests
- Git repository initialized
```

### Script Integration

Integrate Kilo-powered development into your workflow:

```bash
#!/bin/bash
# workflow-automate.sh

echo "🔄 Starting Kilo-powered development session..."

# Run Kilo-powered development
kilo ralph-trigger --iterations 25 --mode autonomous

# Check results
if [ $? -eq 0 ]; then
    echo "✅ Workflow completed successfully"
    echo "📊 Check progress.md for detailed results"

    # Generate summary report
    kilo ralph-trigger --mode validation
else
    echo "❌ Workflow encountered issues"
    kilo ralph-trigger --mode validation
    exit 1
fi
```

### CI/CD Pipeline Integration

```yaml
# .github/workflows/kilo-ralphloop.yml
name: Kilo-Powered Development

on:
  schedule:
    - cron: '0 4 * * 0' # Weekly workflow automation
  workflow_dispatch:
    inputs:
      iterations:
        description: 'Number of iterations'
        required: true
        default: '20'
      mode:
        description: 'Evaluation mode'
        required: true
        default: 'autonomous'
        options:
          - autonomous
          - interactive
          - validation

jobs:
  workflow:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install Dependencies
        run: |
          npm install -g kilo-cli
          chmod +x ralph bin/*

      - name: Run Kilo-Powered Development
        env:
          KILO_API_KEY: ${{ secrets.KILO_API_KEY }}
          RALPH_MODE: ${{ github.event.inputs.mode || 'autonomous' }}
        run: |
          kilo ralph-trigger --iterations ${{ github.event.inputs.iterations || 20 }}
```

## Workflow Templates

### Template 1: New Feature Development

```yaml
# Template for new feature development
name: New Feature
stages:
  - analysis
  - implementation
  - testing
  - documentation
  - review

triggers:
  on_merge: true
  on_tag: false

actions:
  analysis:
    - analyzeRequirements
    - designArchitecture
    - planImplementation

  implementation:
    - createFeatureBranch
    - implementCode
    - writeUnitTests

  testing:
    - runUnitTests
    - runIntegrationTests
    - runE2ETests

  documentation:
    - updateReadme
    - generateApiDocs
    - updateChangelog

  review:
    - createPullRequest
    - requestReview
    - mergeBranch
```

### Template 2: Bug Fix Workflow

```yaml
# Template for bug fixes
name: Bug Fix
stages:
  - diagnosis
  - fix
  - verification
  - deployment

actions:
  diagnosis:
    - reproduceIssue
    - analyzeRootCause
    - identifyAffectedCode

  fix:
    - createFixBranch
    - implementFix
    - addRegressionTests

  verification:
    - runTests
    - verifyFix
    - checkPerformance

  deployment:
    - mergeToMain
    - deployToStaging
    - monitorProduction
```

## Troubleshooting

### Installation Issues

**Problem**: Kilo CLI not found

```bash
# Check if kilo command is available
which kilo

# If not found, add to PATH
export PATH="$PATH:$(npm global bin)"

# Or reinstall
npm install -g kilo-cli
```

**Problem**: Authentication failed

```bash
# Set API key
export KILO_API_KEY="your_api_key"

# Login to Kilo
kilo login
```

### Configuration Issues

**Problem**: Backend not enabled

```bash
# Enable the backend
ralph-config --enable kilo

# Verify status
ralph-status --backends
```

**Problem**: Invalid workflow configuration

```bash
# Reset to defaults
ralph-config --reset

# Reconfigure
ralph-config --enable kilo
```

### Runtime Issues

**Problem**: Workflow fails to start

```bash
# Check RalphLoop script
./ralph 1

# Test Kilo integration
kilo ralph-trigger --mode validation

# Check workflow logs
cat progress.md | tail -50
```

**Problem**: Workflow hangs

```bash
# Check running processes
ps aux | grep ralph

# Kill stuck processes
pkill -f ralph

# Restart with timeout
kilo ralph-trigger --iterations 5 --timeout 300
```

## Best Practices

1. **Start Simple**: Begin with basic workflows
2. **Monitor Progress**: Use `ralph-status --progress` regularly
3. **Version Control**: Commit workflow configurations
4. **Test Workflows**: Validate workflows in staging first
5. **Incremental Development**: Build complex workflows gradually
6. **Document Workflows**: Maintain workflow documentation
7. **Backup State**: Regular backups of development state

## Integration with Other Backends

Kilo can work alongside other backends for enhanced capabilities:

### Claude Code + Kilo

```bash
# Use Claude Code for AI suggestions, Kilo for orchestration
export RALPH_BACKEND=kilo
export CLAUDE_API_KEY="your_key"

kilo ralph-trigger --iterations 15 --mode autonomous
```

### Codex + Kilo

```bash
# Use Codex for code generation, Kilo for workflow management
export RALPH_BACKEND=kilo
export OPENAI_API_KEY="your_key"

kilo ralph-trigger --iterations 20 --mode autonomous
```

### Multi-Backend Setup

```json
{
  "backends": {
    "claude-code": { "enabled": true },
    "codex": { "enabled": true },
    "kilo": { "enabled": true }
  },
  "defaultBackend": "kilo",
  "workflow": {
    "useBestBackend": true,
    "fallbackOrder": ["claude-code", "codex", "kilo"]
  }
}
```

## Additional Resources

- [RalphLoop Documentation](../README.md)
- [Kilo CLI Documentation](https://github.com/kilo-cli/kilo)
- [Workflow Examples](examples/)
- [GitHub Issues](https://github.com/rwese/RalphLoop/issues)

## Support

For issues and questions:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review [Kilo CLI Documentation](https://github.com/kilo-cli/kilo)
3. Review [GitHub Issues](https://github.com/rwese/RalphLoop/issues)
4. Create a new issue if your problem isn't listed
