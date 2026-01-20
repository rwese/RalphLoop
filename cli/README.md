# RalphLoop CLI

Run the RalphLoop autonomous development system via container with a simple command.

## Installation

### Method 1: Clone and Run (Works Now)

```bash
# Clone the repository
git clone https://github.com/rwese/RalphLoop.git
cd RalphLoop

# Run CLI directly
node cli/bin/ralphloop --help
node cli/bin/ralphloop 5
```

### Method 2: Publish to npm (For Global Access)

```bash
# From the cli/ directory
cd cli
npm publish

# Then use from anywhere
npx ralphloop --help
npx ralphloop 5
```

### Method 3: Install Globally (After Publishing)

```bash
# After publishing to npm
npm install -g ralphloop

# Run from anywhere
ralphloop --help
ralphloop 5
```

## Usage

```bash
# Run with default settings (1 iteration)
npx ralphloop

# Run 10 iterations
npx ralphloop 10

# Force Docker instead of auto-detected Podman
npx ralphloop --docker 5

# Use a specific image tag
npx ralphloop --image ghcr.io/rwese/ralphloop:v1.0.0

# Always pull latest image before running
npx ralphloop --pull

# Show help
npx ralphloop --help
```

## Options

| Option          | Description                                                     |
| --------------- | --------------------------------------------------------------- |
| `--runtime, -r` | Container runtime: `podman` or `docker` (auto-detected)         |
| `--image, -i`   | Docker image to use (default: `ghcr.io/rwese/ralphloop:latest`) |
| `--pull`        | Always pull the latest image before running                     |
| `--no-pull`     | Skip pulling the image                                          |
| `--help, -h`    | Show help message                                               |
| `--version, -V` | Show version information                                        |

## Environment Variables

| Variable           | Description                                            |
| ------------------ | ------------------------------------------------------ |
| `GITHUB_TOKEN`     | GitHub token for API access (needed for private repos) |
| `CONTEXT7_API_KEY` | Context7 documentation lookup key                      |
| `OPENCODE_AUTH`    | OpenCode authentication data                           |

## Features

- **Auto-detection**: Automatically detects Podman or Docker
- **Volume mounting**: Mounts current directory to `/workspace` in container
- **UID mapping**: Uses `--userns=keep-id` for proper file permissions
- **Git integration**: Passes through git user configuration for commits
- **Environment passthrough**: Forwards GitHub token and other credentials

## Examples

### Basic usage

```bash
# Navigate to your project
cd /path/to/your/project

# Run RalphLoop for 5 iterations
npx ralphloop 5
```

### With custom image

```bash
# Use a specific version
npx ralphloop --image ghcr.io/rwese/ralphloop:v2.0.0

# Use locally built image
npx ralphloop --image localhost/ralphloop:latest
```

### With GitHub integration

```bash
# Set GitHub token (needed for private repos)
export GITHUB_TOKEN=ghp_xxxxx

# Run RalphLoop
npx ralphloop 3
```

## Development

To test locally:

```bash
# Clone the repository
git clone https://github.com/rwese/RalphLoop.git
cd RalphLoop/cli

# Link locally
npm link

# Test the CLI
ralphloop --help

# Or run directly
node bin/ralphloop.js --help
```

## Requirements

- Node.js 18+
- Podman or Docker
- Linux or macOS

## License

MIT
