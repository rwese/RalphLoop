# RalphLoop Agent Documentation

This document captures project-specific knowledge, patterns, and best practices for autonomous development on RalphLoop. Use this as a reference when working on this project.

## Project Overview

RalphLoop is an autonomous development system that runs itself to achieve goals while continuously improving. It demonstrates a self-sustaining development process using OpenCode as the agent runtime.

**Key Technologies:**

- OpenCode CLI for autonomous agent operation
- OpenCode PTY plugin for interactive terminal management
- Docker/Podman for containerized environments
- Node.js v23.x with npx for package management
- Bash scripting for automation

## Core Patterns

### Autonomous Loop Pattern

The project uses a self-contained autonomous loop that:

1. **Reads State** - Reads `progress.md` and prompt source (file, env var, or `prompt.md`)
2. **Analyzes** - Decides highest priority next step using OpenCode agent
3. **Executes** - Implements the task with OpenCode AGENT_RALPH agent
4. **Commits** - Creates git commits for all changes
5. **Tracks** - Updates `progress.md` with accomplishments
6. **Iterates** - Continues until goal complete or max iterations reached

**Loop Command:**

```bash
./ralph <iterations>  # Default: 100 iterations
```

### Configuration Cascade

Settings flow from most specific to least specific:

1. **RALPH_PROMPT** - Direct prompt text (highest priority)
2. **RALPH_PROMPT_FILE** - Path to prompt file
3. **prompt.md** - Default prompt file in project root
4. **progress.md** - Progress tracking file (auto-created if missing)

## Environment Variables

### Prompt Configuration

```bash
# Method 1: Direct prompt
RALPH_PROMPT="Build a REST API for user management" ./ralph 50

# Method 2: Prompt from file
RALPH_PROMPT_FILE="/path/to/custom-prompt.md" ./ralph 50

# Method 3: Default prompt.md
./ralph 50
```

### API Keys

```bash
# Context7 MCP Server (documentation lookup)
export CONTEXT7_API_KEY=your_api_key_here

# OpenCode API (if using cloud features)
export OPENCODE_API_KEY=your_api_key_here
```

### Timeout and Memory Configuration

```bash
# Timeout for opencode commands in seconds (default: 600 = 10 minutes)
export RALPH_TIMEOUT=1200  # 20 minutes

# Memory limit in KB (default: 2097152 = 2GB)
export RALPH_MEMORY_LIMIT=3145728  # 3GB

# Progress refactoring threshold in lines (default: 1000)
export RALPH_PROGRESS_MAX_SIZE=2000

# Number of recent iterations to keep during refactoring (default: 5)
export RALPH_PROGRESS_KEEP=10

# Directory for archived progress entries (default: .progress-archive)
export RALPH_PROGRESS_ARCHIVE_DIR=".progress-archive"

# Example: Run with longer timeout for complex tasks
RALPH_TIMEOUT=1800 ./ralph 10  # 30 minute timeout
```

**Why configure these?**

- **RALPH_TIMEOUT**: If opencode commands are timing out (especially for complex tasks), increase this value
- **RALPH_MEMORY_LIMIT**: If you're getting exit code 137 (OOM kill), increase this value
- **RALPH_PROGRESS_MAX_SIZE**: To control when progress.md gets refactored/archived (default: 1000 lines)
- **RALPH_PROGRESS_KEEP**: Number of recent iterations to keep in main progress.md after refactoring (default: 5)
- **RALPH_PROGRESS_ARCHIVE_DIR**: Directory where archived progress entries are stored (default: .progress-archive)

**Common configurations:**

```bash
# Quick iterations (testing)
RALPH_TIMEOUT=300 RALPH_MEMORY_LIMIT=1048576 ./ralph 5

# Complex development
RALPH_TIMEOUT=1800 RALPH_MEMORY_LIMIT=4194304 ./ralph 50  # 30 min timeout, 4GB memory

# Heavy validation
RALPH_TIMEOUT=3600 RALPH_MEMORY_LIMIT=6291456 ./ralph 100  # 1 hour timeout, 6GB memory
```

### OpenCode Logging Configuration

```bash
# Log level: DEBUG, INFO, WARN, ERROR (default: WARN)
export RALPH_LOG_LEVEL=INFO

# Print logs to stderr: true/false (default: false)
export RALPH_PRINT_LOGS=true
```

**Why configure these?**

- **RALPH_LOG_LEVEL**: Control verbosity of OpenCode logs
  - `WARN` (default): Only warnings and errors - minimal output
  - `INFO`: Informational messages - good for debugging
  - `DEBUG`: Full debug output - verbose but helpful for troubleshooting
  - `ERROR`: Only errors - even quieter than WARN

- **RALPH_PRINT_LOGS**: Print logs to stderr in addition to capturing them
  - `false` (default): Logs are captured in temp files
  - `true`: Logs are printed to stderr in real-time

**Examples:**

```bash
# Debug mode with real-time logs (verbose but helpful for troubleshooting)
RALPH_LOG_LEVEL=DEBUG RALPH_PRINT_LOGS=true ./ralph 1

# Info level logging without printing (balanced)
RALPH_LOG_LEVEL=INFO ./ralph 10

# Quiet mode (default behavior)
RALPH_LOG_LEVEL=WARN ./ralph 10

# Minimal logging, show everything to stderr
RALPH_LOG_LEVEL=ERROR RALPH_PRINT_LOGS=true ./ralph 10
```

### Docker Runtime

```bash
# Podman (default on this system)
podman build -t ralphloop .
podman run -it --rm -v "$(pwd):/workspace" ralphloop bash ./ralph 1

# Docker (alternative)
docker build -t ralphloop .
docker run -it --rm -v "$(pwd):/workspace" ralphloop bash ./ralph 1
```

## Project Structure

```
RalphLoop/
├── ralph                  # Autonomous loop script (entry point)
├── prompt.md             # Default project objectives
├── progress.md           # Iteration tracking and progress
├── Dockerfile            # Container definition
├── entrance.sh           # Container entrypoint (auth handling)
├── .env.dist             # Environment variables template
├── backends/              # Backend configurations (claude-code, codex, kilo, opencode)
│   ├── opencode/          # OpenCode configuration
│   │   ├── prompts/agent/AGENT_RALPH.md  # Agent configuration
│   │   └── opencode.jsonc        # OpenCode CLI configuration
│   ├── claude-code/       # Claude Code backend configuration
│   ├── codex/             # OpenAI Codex backend configuration
│   └── kilo/              # Kilo CLI backend configuration
├── share/opencode-pty/       # OpenCode PTY plugin (git submodule)
│   ├── src/                  # Plugin source code
│   ├── index.ts              # Plugin entry point
│   └── README.md             # Plugin documentation
├── docs/                 # Documentation
│   ├── DOCKER.md         # Docker/Podman run commands
│   ├── DOCKER_HUB.md     # Docker Hub publishing guide
│   └── SECURITY.md       # Security policy
├── examples/             # Ready-to-use project examples
│   ├── todo-app/         # Task management web app
│   ├── book-collection/  # Personal library manager
│   ├── finance-dashboard/# Personal finance tracker
│   ├── weather-cli/      # CLI weather tool
│   └── youtube-cli/      # YouTube download tool
└── docs/                 # Documentation
```

## Best Practices

### For Autonomous Operation

1. **Always commit changes** - The loop should create meaningful git history
2. **Update progress.md** - Track what was accomplished each iteration
3. **One goal per iteration** - Focus on single, achievable objectives
4. **Use environment variables** - Prefer `RALPH_PROMPT` over modifying files for quick changes
5. **Validate before commit** - Ensure code builds and tests pass

### For Docker Development

1. **Use `--userns=keep-id`** - Preserves host UID/GID for volume mounts
2. **Mount current directory** - `-v "$(pwd):/workspace"` for live development
3. **Set working directory** - `-w "/workspace"` in container runs
4. **Pass environment variables** - `-e VAR=value` for configuration
5. **Examples are pre-installed** - Use `/usr/share/ralphloop/examples/` for quick start

### Running Examples

```bash
# Run todo-app example with npx (auto-pulls latest image)
RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/todo-app/prompt.md npx ralphloop 10

# Or build locally and run with npm script
npm run container:build
RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/todo-app/prompt.md npm run container:run 10
```

### For npm/node Usage

1. **Use npx for one-off commands** - `npx <package>` without global install
2. **npm config set save-exact=true** - Lock dependency versions
3. **Node.js v23.x** - Latest features, but test for compatibility

## Common Issues and Solutions

### Issue: npm init author options deprecated

**Problem:**

```
npm error The `init.author.name` option is deprecated
```

**Solution:**

- Remove deprecated options from Dockerfile
- Use command-line flags during `npm init` instead:

  ```bash
  npm init --init-author-name="Name" --init-author-email="email@example.com"
  ```

- Only `save-exact` can be set via `npm config set`

### Issue: Prompt file not found

**Problem:**

```
Error: prompt.md file must exist
```

**Solutions:**

1. Create `prompt.md` in project root
2. Set `RALPH_PROMPT_FILE=/path/to/prompt.md`
3. Set `RALPH_PROMPT="direct prompt text"`

### Issue: Docker build fails on NodeSource

**Problem:**

```
curl: (7) Failed to connect to deb.nodesource.com
```

**Solutions:**

1. Check network connectivity
2. Ensure curl is installed before NodeSource script
3. Try alternative Node.js installation method:

   ```dockerfile
   RUN apt-get install -y nodejs
   ```

### Issue: OpenCode authentication

**Problem:**

```
Authentication required for OpenCode
```

**Solutions:**

1. Set `OPENCODE_AUTH` environment variable with auth data
2. Mount auth file: `-e "OPENCODE_AUTH=$(cat ~/.local/share/opencode/auth.json)"`
3. Use interactive login: `podman run -it ralphloop bash` then `opencode login`

### Issue: Permission denied on scripts

**Problem:**

```
bash: ./ralph: Permission denied
```

**Solution:**

```bash
chmod +x ralph
```

## OpenCode PTY Plugin

RalphLoop includes the [opencode-pty](https://github.com/shekohex/opencode-pty) plugin for interactive terminal management. This enables agents to:

- Run background processes (dev servers, watch modes)
- Manage multiple terminal sessions
- Send interactive input (Ctrl+C, arrow keys, etc.)
- Read output with pagination and regex filtering
- Receive exit notifications for long-running processes

### Available Tools

| Tool        | Description              |
| ----------- | ------------------------ |
| `pty_spawn` | Create a new PTY session |
| `pty_write` | Send input to a PTY      |
| `pty_read`  | Read output buffer       |
| `pty_list`  | List all PTY sessions    |
| `pty_kill`  | Terminate a PTY          |

### Example Usage

```json
// Start a dev server
pty_spawn: command="npm", args=["run", "dev"], title="Dev Server"

// Read output
pty_read: id="pty_xxxxxxxx", limit=50

// Send Ctrl+C
pty_write: id="pty_xxxxxxxx", data="\x03"

// Kill session
pty_kill: id="pty_xxxxxxxx", cleanup=true
```

The plugin is located at `share/opencode-pty` and is pre-installed in the container at `/usr/share/ralphloop/opencode-pty`.

## Development Workflow

### Local Development

```bash
# 1. Edit files as needed
nano prompt.md

# 2. Test with single iteration
./ralph 1

# 3. Check git status
git status

# 4. Review changes
git diff
```

### Containerized Development

```bash
# Build image
podman build -t ralphloop .

# Run single iteration in container
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  ralphloop bash ./ralph 1

# Interactive development
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  ralphloop bash
```

### Quick Iteration Cycle

```bash
# Make change
echo "New objective" > prompt.md

# Run one iteration
RALPH_PROMPT="Complete the feature" ./ralph 1

# Check progress
cat progress.md
```

## Configuration Files

### opencode.jsonc

OpenCode CLI configuration. Key settings:

- Agent profiles and defaults
- Output formatting options
- MCP server configurations (Context7, etc.)

### AGENT_RALPH.md

Custom agent instructions for RalphLoop:

- YOLO agent profile (fast execution, minimal safety)
- Workflow patterns and constraints
- Reporting format requirements

### entrance.sh

Container entrypoint script:

- Handles authentication setup
- Prepares environment for OpenCode
- Falls back to interactive bash

### .env.dist

Environment variable template for:

- `CONTEXT7_API_KEY` - Context7 MCP documentation lookup
- `OPENCODE_API_KEY` - OpenCode API access
- `GITHUB_TOKEN` - GitHub CLI integration
- Docker registry credentials (optional)

## Lessons Learned

### What Works Well

1. **Environment variable prompts** - Provides flexibility without file changes
2. **Container-based development** - Consistent environment across systems
3. **Progress tracking** - Clear visibility into iteration accomplishments
4. **Small, focused iterations** - One goal per iteration produces better results
5. **Automated commits** - Maintains clean git history automatically

### What to Avoid

1. **Large prompts** - Break into smaller, achievable objectives
2. **Skipping validation** - Always verify build works before committing
3. **Ignoring errors** - Handle failures gracefully and log issues
4. **Overly complex goals** - Start simple, iterate to complexity

### Patterns to Continue

1. **Clear commit messages** - Descriptive, task-focused commits
2. **Progress documentation** - Update progress.md every iteration
3. **Environment templates** - `.env.dist` for reproducible setups
4. **Modular configuration** - Separate config files for different concerns

### Patterns to Improve

1. **Testing automation** - Add test suite and CI/CD pipeline
2. **Error recovery** - Implement better retry and recovery mechanisms
3. **Multi-agent coordination** - Support parallel task execution
4. **State persistence** - Better handling of interrupted loops

## Agent Instructions

When running as OpenCode agent for RalphLoop:

### Primary Directive

Complete the current objective while maintaining project resilience and producing useful output.

### Priorities (in order)

1. Understand current state from `progress.md` and prompt
2. Execute one clear, achievable goal
3. Update `progress.md` with accomplishments
4. Create meaningful git commit
5. Identify next improvements

### Constraints

- Work on ONE goal per iteration
- Always validate changes (build, test, lint)
- Commit frequently with clear messages
- Update progress tracking

### Success Criteria

- ✅ Git history shows regular commits
- ✅ Progress tracking is current
- ✅ Code builds without errors
- ✅ Made measurable progress toward goal

### Completion Signal

Output `<promise>COMPLETE</promise>` when:

- Original objective is fully achieved
- All sub-tasks are complete
- Code is committed and tested
- Progress is documented

### Validation Workflow

RalphLoop implements an independent validation system to ensure quality:

1. **Completion Signal**: When agent outputs `<promise>COMPLETE</promise>`, the loop triggers independent validation
2. **Independent Verification**: A separate agent instance verifies all acceptance criteria:
   - Runs build commands (`npm run build`)
   - Runs tests (`npm test`)
   - Runs linter (`npm run lint`)
   - Validates all acceptance criteria from prompt.md
   - Checks for regressions
3. **XML Output Format**: Validation results in structured XML:

```xml
<validation_status>PASS</validation_status> or <validation_status>FAIL</validation_status>

<validation_issues>
- Failing criterion 1
- Failing criterion 2
</validation_issues>

<validation_recommendations>
- Fix action 1
- Fix action 2
</validation_recommendations>
```

4. **Feedback Loop**: If validation FAILS:
   - Issues are saved to `.ralph_validation_issues.txt`
   - Next iteration receives pending issues in context
   - Agent focuses on fixing specific issues
   - Re-validation occurs after fix attempt

5. **Completion**: Validation PASS → Mission complete!

This ensures agents cannot prematurely exit without meeting all requirements.

## Backend Integration

RalphLoop supports integration with various CLI tools for custom command execution and evaluation loops.

### Supported Backends

RalphLoop includes backend configurations for the following CLI tools:

- **Claude Code**: Anthropic's CLI for autonomous development
- **OpenAI Codex**: OpenAI's code generation and analysis CLI
- **Kilo CLI**: Autonomous development workflow CLI

### Backend Configuration

Backend configurations are stored in the `backends/` directory:

```
backends/
├── index.json              # Main backend configuration
├── claude-code/
│   ├── config.json         # Claude Code specific settings
│   └── README.md           # Claude Code integration guide
├── codex/
│   ├── config.json         # Codex specific settings
│   └── README.md           # Codex integration guide
└── kilo/
    ├── config.json         # Kilo specific settings
    └── README.md           # Kilo integration guide
```

### Custom Command Triggers

The `@ralph` tool supports custom command calls to trigger evaluation loops:

```bash
# Trigger evaluation with custom settings
ralph-trigger --iterations 5 --mode autonomous --backend claude-code

# Check RalphLoop status
ralph-status --progress --state --backends

# Configure RalphLoop settings
ralph-config --get evaluation.maxIterations
ralph-config --set evaluation.maxIterations=50
ralph-config --enable claude-code
```

### Environment Variables

Custom command configuration via environment variables:

```bash
# Set evaluation mode
export RALPH_MODE=autonomous  # autonomous, interactive, validation

# Set backend to use
export RALPH_BACKEND=claude-code  # claude-code, codex, kilo

# Set custom command
export RALPH_COMMAND=evaluate  # Custom command to execute

# Direct prompt
export RALPH_PROMPT="Build a REST API for user management"

# Prompt file path
export RALPH_PROMPT_FILE=/path/to/prompt.md
```

### Backend Integration Features

1. **Configuration Management**: Each backend has its own configuration file with settings for:
   - CLI commands and paths
   - Environment variables
   - Custom command definitions
   - Integration hooks

2. **Custom Commands**: Define custom commands that trigger RalphLoop:

   ```json
   {
     "customCommands": [
       {
         "name": "evaluate",
         "command": "ralph",
         "arguments": ["$ITERATIONS"],
         "description": "Start evaluation loop",
         "mode": "autonomous"
       }
     ]
   }
   ```

3. **Evaluation Modes**:
   - **autonomous**: Full autonomous development loop
   - **interactive**: Loop with interactive prompts
   - **validation**: Run validation checks only

### Using Backends

1. **Enable a Backend**:

   ```bash
   ralf-config --enable claude-code
   ```

2. **Trigger Evaluation via Backend**:

   ```bash
   claude ralf-trigger --iterations 5 --mode autonomous
   codex ralf-trigger --iterations 10 --prompt ./prompt.md
   kilo ralf-trigger --mode validation
   ```

3. **Check Status via Backend**:

   ```bash
   claude ralf-status --progress
   codex ralf-status --backends
   kilo ralf-status --state
   ```

4. **Configure via Backend**:
   ```bash
   claude ralf-config --get evaluation.maxIterations
   codex ralf-config --set evaluation.maxIterations=50
   kilo ralf-config --list
   ```

### Backend-Specific Setup

#### Claude Code

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code-cli

# Configure RalphLoop integration
ralph-config --backend claude-code --set enabled=true
export CLAUDE_API_KEY=your_api_key
```

#### OpenAI Codex

```bash
# Install Codex CLI
npm install -g openai-codex

# Configure RalphLoop integration
ralph-config --backend codex --set enabled=true
export OPENAI_API_KEY=your_api_key
```

#### Kilo CLI

```bash
# Install Kilo CLI
npm install -g kilo-cli

# Configure RalphLoop integration
ralph-config --backend kilo --set enabled=true
export KILO_API_KEY=your_api_key
```

## Quick Reference

### Essential Commands

```bash
# Run loop
./ralph <iterations>

# With custom prompt
RALPH_PROMPT="goal" ./ralph 1

# Docker build
podman build -t ralphloop .

# Docker run
podman run -it --rm -v "$(pwd):/workspace" ralphloop bash

# Check progress
cat progress.md

# View git log
git log --oneline -10
```

### File Locations

- **Prompt**: `prompt.md` or `RALPH_PROMPT` env var
- **Progress**: `progress.md`
- **Agent config**: `/root/.config/opencode/` (in container)
- **Scripts**: `/usr/local/bin/` (ralph, entrance.sh in container)

### Support

- **Context7 docs**: Set `CONTEXT7_API_KEY` for MCP documentation lookup
- **OpenCode docs**: <https://opencode.ai/docs>
- **Project progress**: See `progress.md` for experiment status
