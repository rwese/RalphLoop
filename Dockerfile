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

# Add useful aliases and settings for development
RUN echo 'export PATH=/root/.local/bin:/root/.opencode/bin:$PATH' >> ~/.bashrc && \
    echo 'alias gs="git status"' >> ~/.bashrc && \
    echo 'export EDITOR=nano' >> ~/.bashrc

# Copy ralph.sh script to /usr/local/bin/ralph and make it executable
COPY ralph.sh /usr/local/bin/ralph
RUN chmod +x /usr/local/bin/ralph

# Default command
CMD ["/bin/bash"]

# For UID mapping, use one of these podman run options:
# 1. --userns=keep-id (maps your host UID to container UID)
# 2. --uidmap=501:1000:1 (maps host UID 501 to container UID 1000)
# 3. Rebuild with specific UID: useradd -u 501 -m root
