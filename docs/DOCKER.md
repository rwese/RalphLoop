# Docker/Podman Quickstart

Run RalphLoop autonomous development system in a container with pre-built examples.

## Quick Start with Examples

RalphLoop includes ready-to-use examples pre-installed in the container at `/usr/share/ralphloop/examples/`:

### Todo App (Recommended First Example)

```bash
# Build the container image first
podman build -t ralphloop .

# Run the todo app example with 10 iterations
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/todo-app/prompt.md" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop ./ralph 10
```

### Book Collection App

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

### Weather CLI Tool

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/weather-cli/prompt.md" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop ./ralph 5
```

### YouTube CLI Tool

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/youtube-cli/prompt.md" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop ./ralph 10
```

## Available Examples

| Example                                             | Description                                     | Iterations |
| --------------------------------------------------- | ----------------------------------------------- | ---------- |
| [todo-app](../examples/todo-app/)                   | Modern task management web app with PWA support | 10-15      |
| [book-collection](../examples/book-collection/)     | Personal library management system              | 15-20      |
| [finance-dashboard](../examples/finance-dashboard/) | Personal finance tracking and budgeting         | 15-20      |
| [weather-cli](../examples/weather-cli/)             | Professional CLI weather tool                   | 5-10       |
| [youtube-cli](../examples/youtube-cli/)             | YouTube download and media management           | 10-15      |

## Interactive Shell

Get an interactive shell in the container to explore:

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e "OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)" \
  ralphloop bash
```

Then run examples from inside the container:

```bash
# List available examples
ls -la /usr/share/ralphloop/examples/

# Run todo app example
RALPH_PROMPT_FILE=/usr/share/ralphloop/examples/todo-app/prompt.md ./ralph 10
```

## Authentication

The container requires OpenCode authentication. If you don't have an auth file, you can:

1. Log in interactively:

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  ralphloop bash
```

Then run `opencode login` inside the container.

2. Or set up authentication before running:

```bash
# Create auth file if needed
mkdir -p ~/.local/share/opencode
# ... complete login setup
export OPENCODE_AUTH=$(< ~/.local/share/opencode/auth.json)
```

## Notes

- Examples are installed at `/usr/share/ralphloop/examples/` (standard Linux share location)
- Your project is mounted from the host at `/workspace`
- Changes to your project directory persist on the host
- The container is based on Ubuntu with Node.js v23.x
- Playwright is installed for browser automation tasks
- Examples work even without mounting your source code
