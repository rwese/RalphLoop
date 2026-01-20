# RalphLoop Examples

Ready-to-use project prompts for RalphLoop autonomous development system. These examples are pre-installed in the container at `/usr/share/ralphloop/examples/`.

## Quick Start (Recommended)

All examples are pre-installed in the container. Run any example with a single command:

```bash
# Build the container first
podman build -t ralphloop .

# Run the todo app example (10 iterations)
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/todo-app/prompt.md" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop ./ralph 10
```

Or using npm scripts:

```bash
# Build image
npm run container:build

# Run with example prompt (path is inside the container)
RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/todo-app/prompt.md npm run container:run 10
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
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/todo-app/prompt.md" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop ./ralph 10
```

### Book Collection

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/book-collection/prompt.md" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop ./ralph 15
```

### Finance Dashboard

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/finance-dashboard/prompt.md" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop ./ralph 15
```

### Weather CLI

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/weather-cli/prompt.md" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop ./ralph 5
```

### YouTube CLI

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/youtube-cli/prompt.md" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop ./ralph 10
```

### PromptBuilder

Build an interactive tool that helps users transform raw ideas into quality prompts:

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/prompt-builder/prompt.md" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop ./ralph 5
```

Or using the quick command:

```bash
npx ralphloop quick prompt
```

Or using npm scripts:

```bash
# Run with example prompt (path is inside the container)
RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/prompt-builder/prompt.md npm run container:run 5
```

## Interactive Mode

Get a shell inside the container to experiment:

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop bash
```

Inside the container:

```bash
# List all examples (pre-installed in container)
ls -la /usr/share/ralphloop/examples/

# Run an example
RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/todo-app/prompt.md ./ralph 10
```

## Using Your Own Prompts

You can also use prompts from your local project:

```bash
# Using a local prompt file (path relative to mounted workspace at /workspace)
RALPH_PROMPT_FILE=/workspace/examples/my-custom-prompt/prompt.md npm run container:run 10

# Or set the prompt directly
RALPH_PROMPT="Build a new feature X for my app" npm run container:run 5
```

## Environment Variables

| Variable            | Description                                                                      |
| ------------------- | -------------------------------------------------------------------------------- |
| `RALPH_PROMPT`      | Direct prompt text for the autonomous loop                                       |
| `RALPH_PROMPT_FILE` | Path to a prompt file (e.g., `/usr/share/ralphloop/examples/todo-app/prompt.md`) |
| `OPENCODE_AUTH`     | OpenCode authentication data (JSON format, required)                             |

### Setting Up OPENCODE_AUTH

1. **Install OpenCode CLI and log in:**

   ```bash
   npm install -g @opencode/ai
   opencode auth login
   ```

2. **The auth file is at:** `~/.local/share/opencode/auth.json`

3. **Pass to container:**

   ```bash
   # Using shell substitution
   OPENCODE_AUTH=$(cat ~/.local/share/opencode/auth.json) npx ralphloop 10

   # Or using --env flag
   npx ralphloop --env "OPENCODE_AUTH=$(cat ~/.local/share/opencode/auth.json)" 10
   ```

## Tips

- Start with fewer iterations (5-10) to test
- Review `progress.md` after each run
- RalphLoop commits after each iteration
- Check git log to see progress: `git log --oneline`
- Examples are pre-installed - no source checkout needed
- Your changes persist in your project directory (mounted volume)

## Creating Your Own

1. Create a new folder in `examples/`
2. Add your project prompt as `prompt.md`
3. Add a `README.md` with overview and instructions
4. Run with:

```bash
RALPH_PROMPT_FILE=/workspace/examples/your-project/prompt.md npm run container:run
```
