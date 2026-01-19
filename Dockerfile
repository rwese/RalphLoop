FROM ubuntu:latest

USER root

# Set environment variables for rootless operation
ENV HOME=/root
ENV USER=root
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/root/.local/bin:/root/.opencode/bin:$PATH

# Set working directory
WORKDIR /workspace

# Install curl, git, and other useful tools for the container
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    sudo \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (v23.x - latest) for npx support
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Add npm global bin to PATH for npx access
ENV PATH=/root/.local/bin:/root/.opencode/bin:/usr/local/lib/node_modules/npm/bin/node-gyp-bin:$PATH

# Create workspace directory with proper ownership (must be done as root)
RUN mkdir -p /workspace

# Pre-create user directories with proper ownership for volume mounts
# root user has UID 1000 by default - matches most host systems
RUN mkdir -p /root/.local/state && \
    mkdir -p /root/.local/share && \
    mkdir -p /root/.config

# Switch to unprivileged user for all subsequent operations
ENV HOME=/root
ENV PATH=/root/.local/bin:/root/.opencode/bin:$PATH

# Install OpenCode in user context
# YOLO: Fast execution mode with minimal safety checks
RUN curl -fsSL https://opencode.ai/install | bash

# Create OpenCode config directory and copy configuration files
RUN mkdir -p /root/.config/opencode
COPY opencode.jsonc /root/.config/opencode/opencode.jsonc
COPY AGENT_RALPH.md /root/.config/opencode/AGENT_RALPH.md

# Configure npm for better user experience
# Note: init.author.name/email/license are deprecated in npm and cannot be set via config
# They can only be set during `npm init` with --init-author-name/email/license flags
RUN npm config set save-exact true

# Verify npx is available
RUN npx --version && echo "npx installation verified"

# Add useful aliases and settings for development
RUN echo 'export PATH=/root/.local/bin:/root/.opencode/bin:/usr/local/lib/node_modules/npm/bin/node-gyp-bin:$PATH' >> ~/.bashrc && \
    echo 'alias gs="git status"' >> ~/.bashrc && \
    echo 'export EDITOR=nano' >> ~/.bashrc && \
    echo 'alias npx="npx --yes"' >> ~/.bashrc

# Copy ralph.sh script to /usr/local/bin/ralph and make it executable
COPY ralph.sh /usr/local/bin/ralph
RUN chmod +x /usr/local/bin/ralph

# Copy and setup entrypoint script for auth handling
COPY entrance.sh /usr/local/bin/entrance.sh
RUN chmod +x /usr/local/bin/entrance.sh
ENTRYPOINT ["/usr/local/bin/entrance.sh"]

# Default command
CMD ["/bin/bash"]

# For UID mapping, use one of these podman run options:
# 1. --userns=keep-id (maps your host UID to container UID)
# 2. --uidmap=501:1000:1 (maps host UID 501 to container UID 1000)
# 3. Rebuild with specific UID: useradd -u 501 -m root
