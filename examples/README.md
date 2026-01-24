# RalphLoop Examples

Ready-to-use project prompts for RalphLoop autonomous development system.

## Quick Start (Recommended)

Run any example with the ralph script:

```bash
# Run the todo app example (10 iterations)
RALPH_PROMPT_FILE=examples/todo-app/prompt.md ./ralph 10

# Or use the npx CLI
npx ralphloop -p examples/todo-app/prompt.md 10

# Or set the prompt directly
RALPH_PROMPT="$(cat examples/todo-app/prompt.md)" ./ralph 10
```

## Available Examples

| Example                                   | Description                                     | Iterations |
| ----------------------------------------- | ----------------------------------------------- | ---------- |
| [todo-app](./todo-app/)                   | Modern task management web app with PWA support | 10-15      |
| [book-collection](./book-collection/)     | Personal library management system              | 15-20      |
| [finance-dashboard](./finance-dashboard/) | Personal finance tracking and budgeting         | 15-20      |
| [weather-cli](./weather-cli/)             | Professional CLI weather tool                   | 5-10       |
| [youtube-cli](./youtube-cli/)             | YouTube download and media management           | 10-15      |
| [prompt-builder](./prompt-builder/)       | Interactive tool to craft quality prompts       | 5-10       |

## Example Structure

Each example folder contains:

- `prompt.md` - Complete project specification for RalphLoop
- `README.md` - Example overview and usage instructions
- `index.html` - Built application (when complete)

## Running Examples

### Todo App (Quickest to Complete)

```bash
RALPH_PROMPT_FILE=examples/todo-app/prompt.md ./ralph 10
```

### Book Collection

```bash
RALPH_PROMPT_FILE=examples/book-collection/prompt.md ./ralph 15
```

### Finance Dashboard

```bash
RALPH_PROMPT_FILE=examples/finance-dashboard/prompt.md ./ralph 15
```

### Weather CLI

```bash
RALPH_PROMPT_FILE=examples/weather-cli/prompt.md ./ralph 5
```

### YouTube CLI

```bash
RALPH_PROMPT_FILE=examples/youtube-cli/prompt.md ./ralph 10
```

### PromptBuilder

Build an interactive tool that helps users transform raw ideas into quality prompts:

```bash
RALPH_PROMPT_FILE=examples/prompt-builder/prompt.md ./ralph 5
```

Or using the quick command:

```bash
npx ralphloop quick prompt
```

## Using Your Own Prompts

You can also use prompts from your local project:

```bash
# Using a local prompt file (path relative to current directory)
RALPH_PROMPT_FILE=examples/my-custom-prompt/prompt.md ./ralph 10

# Or set the prompt directly
RALPH_PROMPT="Build a new feature X for my app" ./ralph 5
```

## Environment Variables

| Variable            | Description                                                 |
| ------------------- | ----------------------------------------------------------- |
| `RALPH_PROMPT`      | Direct prompt text for the autonomous loop                  |
| `RALPH_PROMPT_FILE` | Path to a prompt file (e.g., `examples/todo-app/prompt.md`) |
| `OPENCODE_AUTH`     | OpenCode authentication data (JSON format, required)        |

### Setting Up OPENCODE_AUTH

1. **Install OpenCode CLI and log in:**

   ```bash
   npm install -g @opencode/ai
   opencode auth login
   ```

2. **The auth file is at:** `~/.local/share/opencode/auth.json`

3. **Pass to script:**

   ```bash
   # Using shell substitution
   OPENCODE_AUTH=$(cat ~/.local/share/opencode/auth.json) ./ralph 10

   # Or using --env flag
   npx ralphloop --env "OPENCODE_AUTH=$(cat ~/.local/share/opencode/auth.json)" 10
   ```

## Tips

- Start with fewer iterations (5-10) to test
- Review `progress.md` after each run
- RalphLoop commits after each iteration
- Check git log to see progress: `git log --oneline`
- Your changes persist in your project directory

## Creating Your Own

1. Create a new folder in `examples/`
2. Add your project prompt as `prompt.md`
3. Add a `README.md` with overview and instructions
4. Run with:

```bash
RALPH_PROMPT_FILE=examples/your-project/prompt.md ./ralph
```
