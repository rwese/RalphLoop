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
# Also install Playwright dependencies for browser automation
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    sudo \
    git \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libasound2t64 \
    libatspi2.0-0 \
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

RUN curl -fsSL https://opencode.ai/install | bash

# Install Playwright and browsers for browser automation
RUN npm install -g playwright && \
    npx playwright install chromium --with-deps 2>/dev/null || \
    npx playwright install chromium
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

COPY .opencode /root/.config/opencode

# Copy examples directory to standard Linux share location
COPY example /usr/share/ralphloop/examples

# Copy ralph script to /usr/local/bin/ralph and make it executable
COPY ralph /usr/local/bin/ralph
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
