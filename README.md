# RalphLoop

Autonomous development system that runs itself.

## Quick Start

```bash
# Run the autonomous loop
./ralph.sh 1

# Build and run Docker image
docker build -t ralphloop .
docker run -it --rm -v "$(pwd):/workspace" ralphloop bash ./ralph.sh 1
```

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
  ghcr.io/rwese/ralphloop:latest ./ralph.sh 1

# Podman (with UID preservation)
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  -e RALPH_PROMPT="Your task here" \
  ghcr.io/rwese/ralphloop:latest ./ralph.sh 1
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

### Environment Variables

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
  ghcr.io/rwese/ralphloop:latest ./ralph.sh 10
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
  ghcr.io/rwese/ralphloop:latest ./ralph.sh 1
```

### Volume Mounts for Persistence

The container creates data in `/root/.local/` and `/root/.config/`. Mount these directories to preserve state:

```bash
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v "$(pwd)/.local:/root/.local" \
  -v "$(pwd)/.config:/root/.config" \
  -w "/workspace" \
  ghcr.io/rwese/ralphloop:latest ./ralph.sh 5
```

## License

MIT
