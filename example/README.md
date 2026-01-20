# RalphLoop Examples

Ready-to-use project prompts for RalphLoop autonomous development system.

## Quick Start

```bash
# Run any example with RalphLoop
RALPH_PROMPT_FILE=example/<example-name>/prompt.md npm run container:run <iterations>
```

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
# Run with 10 iterations
RALPH_PROMPT_FILE=example/todo-app/prompt.md npm run container:run 10

# Or cd into the example and run
cd example/todo-app
RALPH_PROMPT="$(cat prompt.md)" npm run container:run 10
```

### Finance Dashboard Example

```bash
RALPH_PROMPT_FILE=example/finance-dashboard/prompt.md npm run container:run 15
```

## Creating Your Own

1. Create a new folder in `example/`
2. Add your project prompt as `prompt.md`
3. Add a `README.md` with overview and instructions
4. Run with: `RALPH_PROMPT_FILE=example/your-project/prompt.md npm run container:run`

## Tips

- Start with fewer iterations (5-10) to test
- Review progress.md after each run
- RalphLoop commits after each iteration
- Check git log to see progress: `git log --oneline`
