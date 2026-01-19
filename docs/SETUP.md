# Gastown Setup Guide

## Overview

This document provides comprehensive setup instructions for Gastown, a development environment management tool. It covers both native installation options and Docker container deployment strategies, helping you choose the best approach for your workflow.

## Prerequisites

### Core Dependencies

| Dependency     | Minimum Version | Purpose                                 | Installation                                                       |
| -------------- | --------------- | --------------------------------------- | ------------------------------------------------------------------ |
| **Go**         | 1.23+           | Running Gastown and Go-based tools      | [go.dev/dl](https://go.dev/dl)                                     |
| **Git**        | 2.25+           | Worktree support for project management | Usually pre-installed                                              |
| **beads (bd)** | 0.44.0+         | Custom type support and project tooling | [github.com/steveyegge/beads](https://github.com/steveyegge/beads) |
| **sqlite3**    | 3.0+            | Convoy database queries                 | Pre-installed on macOS/Linux                                       |
| **tmux**       | 3.0+            | Session management (recommended)        | `brew install tmux` / `apt install tmux`                           |

### Optional Runtimes

| Runtime             | Purpose                      | Installation                                                               |
| ------------------- | ---------------------------- | -------------------------------------------------------------------------- |
| **Claude Code CLI** | Default AI agent runtime     | [claude.ai/code](https://claude.ai/code)                                   |
| **Codex CLI**       | Alternative AI agent runtime | [developers.openai.com/codex/cli](https://developers.openai.com/codex/cli) |
| **OpenCode**        | Development environment      | [opencode.ai](https://opencode.ai)                                         |

### Platform-Specific Notes

**macOS:**

```bash
brew install go git tmux sqlite3
```

**Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install -y golang-go git tmux sqlite3
```

**Windows (WSL2 recommended):**

```bash
# Install WSL2 and Ubuntu, then use Ubuntu instructions above
```

## Native Installation

### Step 1: Install Gastown

```bash
# Install the latest version of Gastown
go install github.com/steveyegge/gastown/cmd/gt@latest

# Add Go binaries to your PATH (add to ~/.zshrc or ~/.bashrc)
export PATH="$PATH:$HOME/go/bin"

# Verify installation
gt --version
```

### Step 2: Initialize Workspace

```bash
# Create workspace with git initialization
gt install ~/gt --git
cd ~/gt

# Add your first project from a Git repository
gt rig add myproject https://github.com/you/repo.git

# Create your crew workspace
gt crew add yourname --rig myproject
cd myproject/crew/yourname

# Start the Mayor session (your main interface)
gt mayor attach
```

### Step 3: Configure Environment

Add the following to your shell configuration (`~/.zshrc` or `~/.bashrc`):

```bash
# Go binaries
export PATH="$PATH:$HOME/go/bin"

# Git configuration for worktree support
export GIT_TERMINAL_PROMPT=0

# Optional: Default editor
export EDITOR="${EDITOR:-nano}"

# Optional: Configure your preferred AI runtime
export CODE_RUNTIME="${CODE_RUNTIME:-claude}"
```

## Docker Installation Options

### Option A: Minimal Ubuntu Base (Recommended)

This Dockerfile provides a balance between size and functionality, perfect for most development workflows.

**File:** `Dockerfile.minimal`

```dockerfile
FROM ubuntu:24.04

USER root

ENV HOME=/root
ENV USER=root
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/root/.local/bin:/root/.go/bin:/root/.cargo/bin:$PATH

WORKDIR /workspace

# Install essential tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Create workspace directory
RUN mkdir -p /workspace

# Pre-create user directories
RUN mkdir -p /root/.local/state && \
    mkdir -p /root/.local/share && \
    mkdir -p /root/.config && \
    mkdir -p /root/.go && \
    mkdir -p /root/.cargo

# Install Go
ARG GO_VERSION=1.23.4
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | \
    tar -C /root -xzf - && \
    mv /root/go /root/.go && \
    rm -rf /root/go

# Install Gastown
RUN go install github.com/steveyegge/gastown/cmd/gt@latest

# Install beads for custom type support
RUN go install github.com/steveyegge/beads/cmd/bd@latest

# Configure shell
RUN echo 'export PATH=/root/.local/bin:/root/.go/bin:/root/.cargo/bin:$PATH' >> ~/.bashrc && \
    echo 'alias gs="git status"' >> ~/.bashrc && \
    echo 'alias ll="ls -la"' >> ~/.bashrc

# Switch to unprivileged user
USER 1000:1000

CMD ["/bin/bash"]
```

**Build and Run:**

```bash
docker build -f Dockerfile.minimal -t gastown:minimal .
docker run -it --rm -v $(pwd):/workspace gastown:minimal
```

### Option B: Full Development Environment

This option includes all development tools, IDE support, and complete environment setup.

**File:** `Dockerfile.full`

```dockerfile
FROM ubuntu:24.04

USER root

ENV HOME=/root
ENV USER=root
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

ENV PATH=/root/.local/bin:/root/.go/bin:/root/.cargo/bin:/root/.pyenv/bin:$PATH
ENV PYENV_ROOT=/root/.pyenv
ENV PYTHON_CONFIGURE_OPTS="--enable-shared"

WORKDIR /workspace

# Base system and development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    vim \
    nano \
    htop \
    tree \
    ripgrep \
    fd-find \
    jq \
    yq \
    make \
    gcc \
    g++ \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /workspace /root/.local /root/.config /root/.cache && \
    mkdir -p /root/.go /root/.cargo /root/.pyenv

# Install Go
ARG GO_VERSION=1.23.4
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | \
    tar -C /root -xzf - && \
    mv /root/go /root/.go && \
    rm -rf /root/go

# Install Gastown and beads
RUN go install github.com/steveyegge/gastown/cmd/gt@latest && \
    go install github.com/steveyegge/beads/cmd/bd@latest

# Install Python with pyenv
RUN export PYENV_VERSION=3.12.1 && \
    curl -fsSL "https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer" | bash && \
    export PYENV_ROOT="/root/.pyenv" && \
    eval "$(pyenv init -)" && \
    pyenv install $PYENV_VERSION && \
    pyenv global $PYENV_VERSION && \
    pip install --upgrade pip setuptools wheel

# Install uv for fast Python package management
RUN curl -fsSL https://astral.sh/uv/install.sh | sh

# Install Node.js with nvm
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install --lts && \
    nvm use --lts && \
    npm install -g npm@latest

# Install Docker CLI (for container management)
COPY --from=docker.io/docker:cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker.io/docker:cli /usr/local/bin/docker-compose /usr/local/bin/docker-compose

# Configure shell
RUN echo 'export PATH=/root/.local/bin:/root/.go/bin:/root/.cargo/bin:/root/.pyenv/bin:$PATH' >> ~/.bashrc && \
    echo 'export PYENV_ROOT=/root/.pyenv' >> ~/.bashrc && \
    echo 'export NVM_DIR=/root/.nvm' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc && \
    echo 'alias gs="git status"' >> ~/.bashrc && \
    echo 'alias ll="ls -la"' >> ~/.bashrc && \
    echo 'alias docker=docker' >> ~/.bashrc && \
    echo 'set -o vi' >> ~/.inputrc

# Create non-root user
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID developer && \
    useradd -u $UID -g $GID -m -s /bin/bash developer

# Switch to non-root user
USER developer
WORKDIR /home/developer

CMD ["/bin/bash"]
```

**Build and Run:**

```bash
docker build -f Dockerfile.full -t gastown:full .
docker run -it --rm -v $(pwd):/workspace gastown:full
```

### Option C: Lightweight Alpine Base

For minimal image size and faster builds when you don't need full Ubuntu compatibility.

**File:** `Dockerfile.alpine`

```dockerfile
FROM alpine:3.19

USER root

ENV HOME=/root
ENV USER=root
ENV PATH=/root/.go/bin:/root/.local/bin:$PATH

WORKDIR /workspace

# Install essential tools and Go dependencies
RUN apk add --no-cache \
    curl \
    git \
    vim \
    bash \
    ca-certificates \
    openssh-client \
    && rm -rf /var/cache/apk/*

# Install Go
ARG GO_VERSION=1.23.4
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | \
    tar -C /root -xzf - && \
    mv /root/go /root/.go && \
    rm -rf /root/go

# Install Gastown and beads
RUN go install github.com/steveyegge/gastown/cmd/gt@latest && \
    go install github.com/steveyegge/beads/cmd/bd@latest

# Configure shell
RUN echo 'export PATH=/root/.go/bin:$PATH' >> ~/.bashrc && \
    echo 'alias gs="git status"' >> ~/.bashrc

# Create non-root user
ARG UID=1000
ARG GID=1000
RUN addgroup -g $GID developer && \
    adduser -u $UID -G developer -s /bin/bash -D developer

# Switch to non-root user
USER developer

CMD ["/bin/bash"]
```

**Build and Run:**

```bash
docker build -f Dockerfile.alpine -t gastown:alpine .
docker run -it --rm -v $(pwd):/workspace gastown:alpine
```

### Option D: Multi-Stage Build (Production Optimized)

For CI/CD pipelines and deployment scenarios where image size matters.

**File:** `Dockerfile.production`

```dockerfile
# Stage 1: Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Install Git for go install
RUN apk add --no-cache git

# Install dependencies
RUN go install github.com/steveyegge/gastown/cmd/gt@latest && \
    go install github.com/steveyegge/beads/cmd/bd@latest

# Stage 2: Runtime stage
FROM alpine:3.19

# Copy binaries from builder
COPY --from=builder /root/go/bin/ /usr/local/bin/
COPY --from=builder /root/go/pkg/mod/ /root/go/pkg/mod/

ENV PATH=/usr/local/bin:$PATH

# Install runtime dependencies
RUN apk add --no-cache \
    git \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Create non-root user
ARG UID=1000
ARG GID=1000
RUN addgroup -g $GID developer && \
    adduser -u $UID -G developer -s /bin/bash -D developer

USER developer

WORKDIR /home/developer

CMD ["gt"]
```

**Build:**

```bash
docker build -f Dockerfile.production -t gastown:production .
```

## Container Configuration Options

### User Namespace Mapping

For permission consistency between host and container:

```bash
# Option 1: Keep ID mapping (recommended for podman)
podman run -it --rm --userns=keep-id \
  -v "$(pwd):/workspace" \
  gastown:minimal

# Option 2: UID mapping for Docker
docker run -it --rm \
  --user $(id -u):$(id -g) \
  -v "$(pwd):/workspace" \
  gastown:minimal

# Option 3: Explicit UID mapping
docker run -it --rm \
  --uidmap=1000:1000:1 \
  -v "$(pwd):/workspace" \
  gastown:minimal
```

### Volume Mounts

Recommended volume mounts for development:

```bash
# For OpenCode integration
podman run -it --rm \
  --userns=keep-id \
  -v "$HOME/.config/opencode:/root/.config/opencode:ro" \
  -v "$HOME/.local/share/opencode:/root/.local/share/opencode" \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  gastown:minimal

# For full integration with all tools
podman run -it --rm \
  --userns=keep-id \
  -v "$HOME/.config:/root/.config:ro" \
  -v "$HOME/.local:/root/.local" \
  -v "$HOME/.cache:/root/.cache" \
  -v "$(pwd):/workspace" \
  -w "/workspace" \
  gastown:full
```

### Environment Variables

Configure runtime behavior with environment variables:

```bash
# Set default runtime
export CODE_RUNTIME="claude"

# Configure Git
export GIT_TERMINAL_PROMPT=0
export GIT_EDITOR="vim"

# Configure Go
export GOPATH="$HOME/go"
export GO111MODULE="on"

# Configure Docker/Podman
export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"
```

## Docker Image Size Comparison

| Image          | Base Size | Total Size | Use Case                      |
| -------------- | --------- | ---------- | ----------------------------- |
| **Minimal**    | 77 MB     | ~200 MB    | Standard development          |
| **Full**       | 77 MB     | ~1.5 GB    | Full-featured IDE replacement |
| **Alpine**     | 5 MB      | ~100 MB    | Minimal footprint             |
| **Production** | 5 MB      | ~150 MB    | CI/CD and deployment          |

## Choosing the Right Dockerfile

### Use Minimal When:

- You need standard Go development tools
- Build times are important
- You don't need multiple language runtimes
- You're running in resource-constrained environments

### Use Full When:

- You need Python, Node.js, and Go support
- You want IDE-like functionality in container
- You need Docker-in-Docker capability
- This is your primary development environment

### Use Alpine When:

- Image size is critical
- You're doing CI/CD builds
- You need minimal attack surface
- You only need Go and Git

### Use Production When:

- You're deploying to production
- You need minimal image size
- You only need the `gt` binary
- Security is the highest priority

## Integration with Existing Docker Setup

If you already have a `Dockerfile` in your project, you can extend it:

```dockerfile
# Add to your existing Dockerfile
COPY --from=gastown:minimal /usr/local/bin/gt /usr/local/bin/gt
COPY --from=gastown:minimal /root/.go /root/.go

ENV PATH=/root/.go/bin:$PATH
```

Or use gastown as a base:

```dockerfile
FROM gastown:minimal as gastown-base

# Your customizations here
RUN go install github.com/your/package@latest
```

## Troubleshooting

### Permission Issues

```bash
# Fix ownership of mounted directories
sudo chown -R $(id -u):$(id -g) .

# Or use user namespace mapping
podman run --userns=keep-id ...
```

### Go Module Issues

```bash
# Enable Go modules
export GO111MODULE=on

# Set GOPRIVATE for private repositories
export GOPRIVATE="github.com/yourorg/*"
```

### Git Credential Issues

```bash
# Use SSH instead of HTTPS
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Or configure git credential helper
git config --global credential.helper 'cache --timeout=3600'
```

## Next Steps

1. **Initialize your workspace**: Follow the [Native Installation](#native-installation) steps
2. **Choose your Dockerfile**: Select the option that best fits your workflow
3. **Configure volumes**: Set up appropriate volume mounts for persistence
4. **Set up aliases**: Add convenient shell aliases for common operations
5. **Configure your runtime**: Set up Claude Code or Codex CLI preferences

For more information about Gastown commands and features, run:

```bash
gt --help
gt install --help
gt rig --help
gt crew --help
gt mayor --help
```
