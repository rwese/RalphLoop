# RalphLoop Agent Documentation

Autonomous development system documentation. Use as reference when working on RalphLoop.

## Quick Start

```bash
# Run autonomous loop
./ralph 10

# With custom prompt
RALPH_PROMPT="Build a REST API" ./ralph 5

# Using npx CLI
npx ralphloop 5
```

## Project Overview

RalphLoop runs itself to achieve goals using OpenCode as the agent runtime.

**Key Technologies:** OpenCode CLI, Docker/Podman, Node.js 18+, Bash, comprehensive testing

## Core Patterns

### Autonomous Loop

1. **Read State** - Reads `progress.md` and prompt source
2. **Analyze** - Decide next step via OpenCode agent
3. **Execute** - Implement with AGENT_RALPH agent
4. **Commit** - Create git commits for all changes
5. **Track** - Update `progress.md` with accomplishments
6. **Iterate** - Continue until goal complete or max iterations reached

### Configuration Cascade

| Priority | Source              | Description            |
| -------- | ------------------- | ---------------------- |
| 1        | `RALPH_PROMPT`      | Direct prompt text     |
| 2        | `RALPH_PROMPT_FILE` | Path to prompt file    |
| 3        | `prompt.md`         | Default prompt file    |
| 4        | `progress.md`       | Progress tracking file |

## Environment Variables

### Core Configuration

| Variable             | Default                 | Description              |
| -------------------- | ----------------------- | ------------------------ |
| `RALPH_TIMEOUT`      | 1800s                   | OpenCode command timeout |
| `RALPH_MEMORY_LIMIT` | 4GB                     | Memory limit in KB       |
| `RALPH_LOG_LEVEL`    | WARN                    | DEBUG, INFO, WARN, ERROR |
| `RALPH_PRINT_LOGS`   | false                   | Print logs to stderr     |
| `RALPH_IMAGE`        | ghcr.io/rwese/ralphloop | Container image          |
| `RALPH_IMAGE_TAG`    | latest                  | Image tag                |

### Evaluation Configuration

| Variable            | Default    | Description                              |
| ------------------- | ---------- | ---------------------------------------- |
| `RALPH_MODE`        | autonomous | autonomous, interactive, validation      |
| `RALPH_BACKEND`     | opencode   | opencode, claude-code, codex, kilo, mock |
| `RALPH_COMMAND`     | -          | Custom command to execute                |
| `RALPH_PROMPT`      | -          | Direct prompt text                       |
| `RALPH_PROMPT_FILE` | prompt.md  | Path to prompt file                      |

### Testing Configuration

| Variable               | Default | Description               |
| ---------------------- | ------- | ------------------------- |
| `RALPH_MOCK_RESPONSE`  | success | success, fail             |
| `RALPH_MOCK_DELAY`     | 0       | Response delay in seconds |
| `RALPH_MOCK_EXIT_CODE` | 0       | Simulated exit code       |

### API Keys

| Variable                  | Description                                                                  |
| ------------------------- | ---------------------------------------------------------------------------- |
| `CONTEXT7_API_KEY`        | Context7 MCP documentation lookup                                            |
| `OPENCODE_API_KEY`        | OpenCode API access                                                          |
| `GITHUB_TOKEN`            | GitHub CLI integration                                                       |
| `OPENCODE_CONFIG_CONTENT` | OpenCode inline config (JSONC content from backends/opencode/opencode.jsonc) |

## Project Structure

```
RalphLoop/
├── ralph                    # Autonomous loop script (entry point)
├── bin/
│   ├── ralphloop.js         # npx CLI tool entry point
│   └── doctor.js            # System diagnostic tool
├── prompt.md                # Default project objectives
├── progress.md              # Iteration tracking
├── Dockerfile               # Container definition
├── entrance.sh              # Container entrypoint
├── backends/                # Backend configurations
│   ├── opencode/            # Primary backend
│   ├── claude-code/         # Claude Code backend
│   ├── codex/               # Codex backend
│   ├── kilo/                # Kilo CLI backend
│   └── mock/                # Mock backend for testing
├── share/opencode-pty/      # OpenCode PTY plugin
├── examples/                # Example projects (7 examples)
├── tests/                   # Test suite
│   ├── run-tests.sh         # Main test runner
│   ├── unit/                # Unit tests
│   ├── integration/         # Integration tests
│   ├── e2e/                 # End-to-end tests
│   └── mock/                # Mock backend tests
└── lefthook.yml             # Git hooks configuration
```

## Testing Framework

### Test Runner

```bash
# Run all tests
./tests/run-tests.sh --all

# Specific categories
./tests/run-tests.sh --unit --integration --e2e --mock

# Quick smoke tests
./tests/run-tests.sh --quick

# CI mode
./tests/run-tests.sh --ci
```

### Mock Backend

Simulates OpenCode without API calls:

```bash
# Success scenario
RALPH_MOCK_RESPONSE=success ./ralph 1

# Failure scenario
RALPH_MOCK_RESPONSE=fail ./ralph 1

# With delay
RALPH_MOCK_DELAY=3 ./ralph 1
```

### Quality Gates

**Pre-commit hooks:**

- Secret scanning (gitleaks)
- Shell linting (shellcheck)
- Markdown linting (markdownlint)
- Code formatting (prettier)

**Pre-push hooks:**

- Quick tests (--quick) - rejects push if tests fail
- Shell linting with shellcheck

## Docker Commands

```bash
# Build and run locally
podman build -t ralphloop .
podman run -it --rm -v "$(pwd):/workspace" ralphloop bash ./ralph 1

# Pull and run published image
podman pull ghcr.io/rwese/ralphloop:latest
podman run -it --rm -v "$(pwd):/workspace" \
  -e RALPH_PROMPT="Your task" \
  ghcr.io/rwese/ralphloop:latest ./ralph 1
```

## Best Practices

### Autonomous Operation

- Always commit changes with clear messages
- Update `progress.md` each iteration
- One goal per iteration
- Use environment variables for quick changes
- Validate before commit

### Docker Development

- Use `--userns=keep-id` for UID preservation
- Mount current directory: `-v "$(pwd):/workspace"`
- Set working directory: `-w "/workspace"`
- Examples pre-installed at `/usr/share/ralphloop/examples/`

### npm/node Usage

- Use npx for one-off commands
- Node.js 18+ required

## Common Issues

| Issue                  | Solution                                   |
| ---------------------- | ------------------------------------------ |
| Permission denied      | `chmod +x ralph`                           |
| Prompt file not found  | Set `RALPH_PROMPT` or `RALPH_PROMPT_FILE`  |
| Docker build fails     | Check network, ensure curl installed       |
| OpenCode auth required | Set `OPENCODE_AUTH` environment variable   |
| Test failures          | Run `./tests/run-tests.sh --quick` locally |
| OOM errors             | Increase `RALPH_MEMORY_LIMIT`              |
| Timeout errors         | Increase `RALPH_TIMEOUT`                   |

## PTY Plugin Tools

| Tool        | Description            |
| ----------- | ---------------------- |
| `pty_spawn` | Create new PTY session |
| `pty_write` | Send input to PTY      |
| `pty_read`  | Read output buffer     |
| `pty_list`  | List all PTY sessions  |
| `pty_kill`  | Terminate PTY          |

## Agent Instructions

### Primary Directive

Complete objectives with quality-focused development practices.

### Workflow Phases

1. **UNDERSTAND & ANALYZE**
   - Parse prompt.md for goals and requirements
   - Identify acceptance criteria
   - Plan verification strategy

2. **PLAN & VALIDATE**
   - Create TODO list with checkpoints
   - Define "done" for each task
   - Validate plan against requirements

3. **EXECUTE & VERIFY**
   - Implement one task at a time
   - Run verification checks after each change
   - Ensure code compiles and tests pass

4. **VALIDATE & COMMIT**
   - Verify all acceptance criteria met
   - Update progress.md
   - Create meaningful git commit

### Verification Checklist

- [ ] Build: Code compiles without errors
- [ ] Test: Unit tests pass
- [ ] Lint: Code passes linting
- [ ] Requirements: Feature meets acceptance criteria
- [ ] Integration: Works with existing code
- [ ] Documentation: Comments updated if needed
- [ ] No Regressions: Existing functionality works

### Completion Signal

Output `<promise>COMPLETE</promise>` when:

- Original objective fully achieved
- All sub-tasks complete
- Code committed and tested
- Progress documented

### Validation Workflow

1. Agent outputs `<promise>COMPLETE</promise>`
2. Independent verification runs:
   - Build verification
   - Test execution
   - Linter checks
   - Acceptance criteria validation
3. XML output format:
   ```xml
   <validation_status>PASS|FAIL</validation_status>
   <validation_issues>...</validation_issues>
   <validation_recommendations>...</validation_recommendations>
   ```
4. If FAIL: issues saved, next iteration focuses on fixes
5. If PASS: mission complete

## Backend Integration

### Supported Backends

| Backend  | Type    | Description                |
| -------- | ------- | -------------------------- |
| OpenCode | Primary | Autonomous agent operation |
| Mock     | Testing | API-free testing           |

### Evaluation Modes

- **autonomous**: Full autonomous loop
- **interactive**: Loop with interactive prompts
- **validation**: Run validation checks only

## CLI Commands

### npx ralphloop

| Command                           | Description                      |
| --------------------------------- | -------------------------------- |
| `npx ralphloop`                   | Run with default (1 iteration)   |
| `npx ralphloop 10`                | Run 10 iterations                |
| `npx ralphloop doctor`            | Diagnose system requirements     |
| `npx ralphloop examples`          | List available examples          |
| `npx ralphloop quick todo`        | Quick-start todo-app             |
| `npx ralphloop quick prompt`      | Interactive prompt builder       |
| `npx ralphloop -p ./prompt.md`    | Read prompt from file            |
| `npx ralphloop --env "VAR=value"` | Set environment variable         |
| `npx ralphloop --docker`          | Force Docker instead of Podman   |
| `npx ralphloop --pull`            | Pull latest image before running |

### npm Scripts

| Script                  | Description               |
| ----------------------- | ------------------------- |
| `npm run format`        | Format code with Prettier |
| `npm run lint:markdown` | Lint markdown files       |

## Examples

| Example           | Description              | Iterations |
| ----------------- | ------------------------ | ---------- |
| todo-app          | Task management PWA      | 10-15      |
| simple-todo-cli   | CLI todo application     | 5-10       |
| book-collection   | Library management       | 15-20      |
| finance-dashboard | Personal finance tracker | 15-20      |
| weather-cli       | CLI weather tool         | 5-10       |
| youtube-cli       | YouTube download tool    | 10-15      |
| prompt-builder    | Interactive prompt tool  | 5-10       |

### Running Examples

```bash
# Using npx
npx ralphloop -p examples/todo-app/prompt.md 10

# Using ralph script
RALPH_PROMPT_FILE=/workspace/examples/todo-app/prompt.md ./ralph 10
```

## Lessons Learned

### What Works Well

- Environment variable prompts (flexibility without file changes)
- Container-based development (consistent environment)
- Progress tracking (clear iteration visibility)
- Small, focused iterations (better results)
- Automated commits (clean git history)
- Mock backend testing (no API costs)
- Comprehensive test suite (prevents regressions)

### What to Avoid

- Large prompts (break into smaller objectives)
- Skipping validation (always verify builds)
- Ignoring errors (handle failures gracefully)
- Bypassing hooks (pre-commit/pre-push critical)

### Patterns to Continue

- Clear commit messages
- Progress documentation
- Environment templates
- Modular configuration
- Automated quality gates

### Patterns to Improve

- Error recovery mechanisms
- Multi-agent coordination
- State persistence
- Documentation coverage

## File Locations

| Item         | Location                              |
| ------------ | ------------------------------------- |
| Prompt       | `prompt.md` or `RALPH_PROMPT`         |
| Progress     | `progress.md`                         |
| Agent config | `/root/.config/opencode/` (container) |
| Tests        | `./tests/run-tests.sh`                |
| Mock backend | `backends/mock/bin/mock-opencode`     |

## Support

- **Context7 docs**: Set `CONTEXT7_API_KEY`
- **OpenCode docs**: <https://opencode.ai/docs>
- **Testing docs**: `tests/README.md`
- **Examples**: `examples/README.md`
