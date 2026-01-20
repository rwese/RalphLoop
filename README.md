# RalphLoop

Autonomous development system that runs itself.

## Quick Start

```bash
# Run the autonomous loop
./ralph 1

# Build and run Docker image
docker build -t ralphloop .
docker run -it --rm -v "$(pwd):/workspace" ralphloop bash ./ralph 1
```

## CLI Tool (Recommended)

RalphLoop includes an npx CLI tool for easy containerized execution:

### Option 1: Clone and Run

```bash
git clone https://github.com/rwese/RalphLoop.git
cd RalphLoop
node bin/ralphloop --help
node bin/ralphloop 5          # Run 5 iterations
```

### Option 2: Direct npx from GitHub (Quickest)

```bash
npx https://github.com/rwese/RalphLoop.git --help
npx https://github.com/rwese/RalphLoop.git 5
```

### Option 3: Publish to npm (Best for Regular Use)

```bash
# From the project root

npm publish

# Then use from anywhere
npx ralphloop --help
npx ralphloop 5
```

### CLI Options

| Option                                                 | Description                      |
| ------------------------------------------------------ | -------------------------------- |
| `npx ralphloop`                                        | Run with default (1 iteration)   |
| `npx ralphloop 10`                                     | Run 10 iterations                |
| `npx https://github.com/rwese/RalphLoop.git 10`        | Run directly from GitHub         |
| `npx ralphloop --docker 5`                             | Force Docker instead of Podman   |
| `npx ralphloop --image ghcr.io/rwese/ralphloop:v1.0.0` | Use specific image tag           |
| `npx ralphloop --pull`                                 | Pull latest image before running |
| `npx ralphloop --help`                                 | Show help                        |

### Environment Variables

| Variable           | Description                       |
| ------------------ | --------------------------------- |
| `GITHUB_TOKEN`     | GitHub token for API access       |
| `CONTEXT7_API_KEY` | Context7 documentation lookup key |
| `OPENCODE_AUTH`    | OpenCode authentication data      |

## Published Image

RalphLoop is published to GitHub Container Registry:

```
ghcr.io/rwese/ralphloop:latest
```

### Pull the Image

```bash
# Using Docker
docker pull ghcr.io/rwese/ralphloop:latest

# Using Podman
podman pull ghcr.io/rwese/ralphloop:latest
```

### Run with Your Project

The container expects your project files to be mounted at `/workspace`. Create a `prompt.md` file in your project directory, then run:

```bash
# Docker
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e RALPH_PROMPT="Your task here" \
  ghcr.io/rwese/ralphloop:latest ./ralph 1

# Podman (with UID preservation)
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e RALPH_PROMPT="Your task here" \
  ghcr.io/rwese/ralphloop:latest ./ralph 1
```

### Interactive Development

```bash
# Docker
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  ghcr.io/rwese/ralphloop:latest bash

# Podman
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  ghcr.io/rwese/ralphloop:latest bash
```

### Container Environment Variables

Pass environment variables to configure the container:

| Variable            | Description                                   |
| ------------------- | --------------------------------------------- |
| `RALPH_PROMPT`      | Direct prompt text for the autonomous loop    |
| `RALPH_PROMPT_FILE` | Path to a prompt file (mounted in container)  |
| `CONTEXT7_API_KEY`  | API key for Context7 MCP documentation lookup |
| `OPENCODE_API_KEY`  | API key for OpenCode cloud features           |
| `OPENCODE_AUTH`     | Auth data for OpenCode (JSON format)          |

```bash
# Example with multiple environment variables
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e RALPH_PROMPT="Add dark mode to the app" \
  -e CONTEXT7_API_KEY="your-key" \
  ghcr.io/rwese/ralphloop:latest ./ralph 10
```

### Using with GitHub Authentication

To enable GitHub operations inside the container, mount your GitHub token:

```bash
# Using GitHub CLI auth
export GH_TOKEN=$(gh auth token)

docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e GH_TOKEN \
  ghcr.io/rwese/ralphloop:latest ./ralph 1
```

### Volume Mounts for Persistence

The container creates data in `/root/.local/` and `/root/.config/`. Mount these directories to preserve state:

```bash
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v "$(pwd)/.local:/root/.local" \
  -v "$(pwd)/.config:/root/.config" \
  -w "/workspace" \
  ghcr.io/rwese/ralphloop:latest ./ralph 5
```

## Examples

RalphLoop includes ready-to-use project prompts in the `example/` directory. Each example is a complete project specification that RalphLoop can build for you.

### Available Examples

| Example                                           | Description                                     | Iterations |
| ------------------------------------------------- | ----------------------------------------------- | ---------- |
| [todo-app](./example/todo-app/)                   | Modern task management web app with PWA support | 10-15      |
| [book-collection](./example/book-collection/)     | Personal library management system              | 15-20      |
| [finance-dashboard](./example/finance-dashboard/) | Personal finance tracking and budgeting         | 15-20      |
| [weather-cli](./example/weather-cli/)             | Professional CLI weather tool                   | 5-10       |
| [youtube-cli](./example/youtube-cli/)             | YouTube download and media management           | 10-15      |

See the [Examples README](./example/README.md) for detailed usage instructions.

### Running an Example

```bash
# Run the todo app example with 10 iterations
RALPH_PROMPT_FILE=example/todo-app/prompt.md npm run container:run 10

# Or use the container script directly
RALPH_PROMPT_FILE=example/todo-app/prompt.md ./bin/container.sh run 10

# Copy the prompt to your project and run there
cp example/todo-app/prompt.md my-project/
cd my-project
RALPH_PROMPT="$(cat prompt.md)" npm run container:run 10
```

### Creating Your Own

1. Create a new folder in `example/`
2. Add your project prompt as `prompt.md`
3. See [example/README.md](./example/README.md) for full instructions

## License

MIT
