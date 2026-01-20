# OpenAI Codex Backend Integration

This document describes how to integrate RalphLoop with OpenAI Codex CLI for code generation and analysis workflows.

## Overview

OpenAI Codex is OpenAI's CLI tool for code generation and analysis. This backend integration allows you to trigger RalphLoop evaluation loops directly from Codex commands, enabling AI-powered autonomous development.

## Installation

### Prerequisites

- OpenAI Codex CLI installed and configured
- Node.js v18+
- npm or yarn package manager
- OpenAI API key

### Install Codex CLI

```bash
# Using npm
npm install -g openai-codex

# Verify installation
codex --version
```

### Configure RalphLoop Integration

```bash
# Enable Codex backend
ralph-config --enable codex

# Set API key
export OPENAI_API_KEY="your_openai_api_key_here"

# Verify configuration
ralph-config --get backends.codex.enabled
```

## Usage

### Basic Commands

#### Trigger Evaluation Loop

```bash
# Run autonomous development for 5 iterations
codex ralph-trigger --iterations 5 --mode autonomous

# Run with specific prompt file
codex ralph-trigger --prompt ./custom-prompt.md --iterations 10

# Run in validation mode
codex ralph-trigger --mode validation

# Run in interactive mode
codex ralph-trigger --mode interactive
```

#### Check Status

```bash
# Show current state summary
codex ralph-status --state

# Show detailed progress information
codex ralph-status --progress

# Show backend status
codex ralf-status --backends

# Show all information
codex ralph-status --verbose
```

#### Configure Settings

```bash
# Get configuration value
codex ralph-config --get evaluation.maxIterations

# Set configuration value
codex ralph-config --set evaluation.maxIterations=50

# List all configuration
codex ralph-config --list

# Enable/disable backends
codex ralph-config --enable claude-code
codex ralph-config --disable kilo
```

### Custom Commands

The integration supports the following custom commands:

- `codex evaluate [iterations]` - Start evaluation loop
- `codex status` - Check current status
- `codex validate` - Validate current state

### Environment Variables

Configure the integration using environment variables:

```bash
# Set evaluation mode
export RALPH_MODE=autonomous

# Set backend to use
export RALPH_BACKEND=codex

# Set number of iterations
export RALPH_ITERATIONS=5

# Direct prompt
export RALPH_PROMPT="Build a REST API for user management"

# Prompt file path
export RALPH_PROMPT_FILE=/path/to/prompt.md

# OpenAI API key
export OPENAI_API_KEY="your_api_key"
```

## Configuration

### Main Configuration File

The main configuration is stored in `backends/index.json`:

```json
{
  "backends": {
    "codex": {
      "enabled": true,
      "name": "OpenAI Codex",
      "description": "OpenAI Codex CLI integration for code generation"
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

Individual backend settings are in `backends/codex/config.json`:

```json
{
  "enabled": true,
  "cli": {
    "name": "codex",
    "installUrl": "https://github.com/openai/codex"
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
    "OPENAI_API_KEY": {
      "required": true,
      "description": "OpenAI API key for Codex services"
    }
  }
}
```

## Features

### Code Generation Integration

The Codex backend leverages OpenAI's code generation capabilities:

- **Smart Code Suggestions**: Get AI-powered code recommendations
- **Code Analysis**: Analyze existing codebases for improvements
- **Automated Refactoring**: Identify and fix code quality issues
- **Documentation Generation**: Auto-generate code documentation

### Evaluation Modes

#### Autonomous Mode

In autonomous mode, Codex and RalphLoop work together:

1. Codex analyzes the current codebase
2. Generates improvement suggestions
3. RalphLoop implements changes
4. Codex reviews and validates implementations
5. Loop continues until goals are met

#### Interactive Mode

In interactive mode, you maintain control:

1. Codex suggests improvements
2. You approve or modify suggestions
3. RalphLoop implements approved changes
4. Continuous feedback loop

#### Validation Mode

In validation mode, Codex reviews the current state:

1. Analyze current codebase
2. Identify issues and improvements
3. Generate validation report
4. Provide recommendations

## Examples

### Example 1: Autonomous Code Improvement

```bash
# Start autonomous code improvement session
codex ralph-trigger --iterations 15 --mode autonomous --prompt ./code-quality.md
```

### Example 2: Interactive Refactoring

```bash
# Start interactive refactoring session
codex ralph-trigger --mode interactive --iterations 5
```

### Example 3: Code Analysis

```bash
# Run comprehensive code analysis
codex ralph-trigger --mode validation --prompt ./analysis-prompt.md
```

### Example 4: Configure for Code Generation

```bash
# Configure for code generation tasks
codex ralph-config --set evaluation.maxIterations=20
codex ralph-config --set evaluation.defaultMode=autonomous

# Start generation session
codex ralph-trigger --iterations 20 --prompt ./generate-api.md
```

## Integration Hooks

The integration supports the following hooks:

### Pre-Evaluation Hooks

Runs before the evaluation loop starts:

```json
"preEvaluation": [
  "validateApiKey",
  "checkCodebase",
  "analyzeDependencies"
]
```

### Post-Evaluation Hooks

Runs after the evaluation loop completes:

```json
"postEvaluation": [
  "generateCodeReport",
  "updateDocumentation",
  "notifyCompletion"
]
```

### Error Handling Hooks

Runs when an error occurs:

```json
"onError": [
  "logApiError",
  "handleRateLimit",
  "cleanupResources"
]
```

## Advanced Usage

### Custom Code Generation Prompts

Create specialized prompts for different code generation tasks:

```markdown
# code-generation-prompt.md

## Goal

Generate a REST API for user management with the following features:

## Requirements

1. User CRUD operations
2. Authentication with JWT
3. Input validation
4. Error handling
5. Unit tests

## Technology Stack

- Node.js with Express
- PostgreSQL database
- Jest for testing
```

### Script Integration

Integrate Codex-powered development into your workflow:

```bash
#!/bin/bash
# smart-build.sh

echo "🤖 Starting AI-powered development session..."

# Run Codex-powered development
codex ralph-trigger --iterations 20 --mode autonomous

# Check results
if [ $? -eq 0 ]; then
    echo "✅ AI development completed successfully"
    echo "📊 Check progress.md for details"
else
    echo "❌ Development encountered issues"
    codex ralph-trigger --mode validation
    exit 1
fi
```

### CI/CD Pipeline Integration

```yaml
# .github/workflows/codex-ralphloop.yml
name: Codex-Powered Development

on:
  schedule:
    - cron: '0 2 * * 1' # Weekly AI development cycle
  workflow_dispatch:
    inputs:
      iterations:
        description: 'Number of iterations'
        required: true
        default: '15'
      mode:
        description: 'Evaluation mode'
        required: true
        default: 'autonomous'
        options:
          - autonomous
          - interactive
          - validation

jobs:
  ai-develop:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install Dependencies
        run: |
          npm install -g openai-codex
          chmod +x ralph bin/*

      - name: Run Codex-Powered Development
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          RALPH_MODE: ${{ github.event.inputs.mode || 'autonomous' }}
        run: |
          codex ralph-trigger --iterations ${{ github.event.inputs.iterations || 15 }}
```

## Troubleshooting

### Installation Issues

**Problem**: Codex CLI not found

```bash
# Check if codex command is available
which codex

# If not found, add to PATH
export PATH="$PATH:$(npm global bin)"

# Or reinstall
npm install -g openai-codex
```

**Problem**: API key not working

```bash
# Verify API key
echo $OPENAI_API_KEY | head -c 10

# If using environment file
source .env

# Check API key validity
codex --test
```

### Configuration Issues

**Problem**: Backend not enabled

```bash
# Enable the backend
ralph-config --enable codex

# Verify status
ralph-status --backends
```

**Problem**: API rate limiting

```json
// Add to config.json
{
  "hooks": {
    "onError": ["handleRateLimit", "retryRequest"]
  },
  "settings": {
    "rateLimitRetries": 3,
    "rateLimitDelay": 1000
  }
}
```

### Runtime Issues

**Problem**: Evaluation loop fails

```bash
# Check RalphLoop script
./ralph 1

# Test Codex integration
codex ralph-trigger --mode validation

# Check logs
cat progress.md
```

**Problem**: Poor code generation quality

```bash
# Improve prompts
# More specific requirements
# Better context description
# Clear success criteria

# Adjust configuration
ralph-config --set codex.temperature=0.7
ralph-config --set codex.maxTokens=2000
```

## Best Practices

1. **Specific Prompts**: Provide clear, detailed requirements
2. **Incremental Changes**: Start with small iterations
3. **Review Generated Code**: Always review AI-generated code
4. **Version Control**: Commit AI-generated changes separately
5. **Test Thoroughly**: Run comprehensive tests after changes
6. **Monitor Costs**: Track API usage and costs
7. **Backup Regularly**: Keep backups of working code

## Limitations

1. **API Costs**: Usage incurs OpenAI API costs
2. **Rate Limits**: Subject to OpenAI rate limits
3. **Context Window**: Limited context for large codebases
4. **Human Review**: AI-generated code requires human review
5. **Edge Cases**: May miss complex edge cases

## Security Considerations

1. **API Key Protection**: Never commit API keys
2. **Code Privacy**: Be careful with proprietary code
3. **Dependency Security**: Review generated dependencies
4. **Access Control**: Limit API key permissions

## Additional Resources

- [RalphLoop Documentation](../README.md)
- [OpenAI Codex Documentation](https://platform.openai.com/docs/codex)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [GitHub Issues](https://github.com/rwese/RalphLoop/issues)

## Support

For issues and questions:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review [OpenAI Codex Documentation](https://platform.openai.com/docs/codex)
3. Review [GitHub Issues](https://github.com/rwese/RalphLoop/issues)
4. Create a new issue if your problem isn't listed
