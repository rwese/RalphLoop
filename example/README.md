# RalphLoop Examples

Ready-to-use project prompts for RalphLoop autonomous development system.

## Quick Start

```bash
# Run any example with RalphLoop
RALPH_PROMPT_FILE=/workspace/example/<example-name>/prompt.md npm run container:run <iterations>
```

> **Note:** `RALPH_PROMPT_FILE` paths are relative to `/workspace` inside the container (where your project is mounted).

## Available Examples

| Example                                   | Description                                     | Iterations |
| ----------------------------------------- | ----------------------------------------------- | ---------- |
| [todo-app](./todo-app/)                   | Modern task management web app with PWA support | 10-15      |
| [book-collection](./book-collection/)     | Personal library management system              | 15-20      |
| [finance-dashboard](./finance-dashboard/) | Personal finance tracking and budgeting         | 15-20      |
| [weather-cli](./weather-cli/)             | Professional CLI weather tool                   | 5-10       |
| [youtube-cli](./youtube-cli/)             | YouTube download and media management           | 10-15      |

## Example Structure

Each example folder contains:

- `prompt.md` - Complete project specification
- `README.md` - Example overview and usage
- `index.html` - Built application (when complete)

## Running Examples

### Todo App Example

```bash
# Run with 10 iterations (path is relative to /workspace inside container)
RALPH_PROMPT_FILE=/workspace/example/todo-app/prompt.md npm run container:run 10

# Or set RALPH_PROMPT directly from the file
RALPH_PROMPT="$(cat example/todo-app/prompt.md)" npm run container:run 10
```

### Finance Dashboard Example

```bash
RALPH_PROMPT_FILE=/workspace/example/finance-dashboard/prompt.md npm run container:run 15
```

### Using Environment Variables

```bash
# Set prompt directly
RALPH_PROMPT="Build a task manager app" npm run container:run 5

# Or use a prompt file (path relative to container's /workspace)
RALPH_PROMPT_FILE=/workspace/example/book-collection/prompt.md npm run container:run 20
```

## Creating Your Own

1. Create a new folder in `example/`
2. Add your project prompt as `prompt.md`
3. Add a `README.md` with overview and instructions
4. Run with: `RALPH_PROMPT_FILE=/workspace/example/your-project/prompt.md npm run container:run`

## Environment Variables

| Variable            | Description                                                   |
| ------------------- | ------------------------------------------------------------- |
| `RALPH_PROMPT`      | Direct prompt text for the autonomous loop                    |
| `RALPH_PROMPT_FILE` | Path to a prompt file (relative to `/workspace` in container) |

## Tips

- Start with fewer iterations (5-10) to test
- Review `progress.md` after each run
- RalphLoop commits after each iteration
- Check git log to see progress: `git log --oneline`
