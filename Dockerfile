FROM ubuntu:latest

USER root

ENV HOME=/root
ENV USER=root
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/root/.local/bin:/root/.opencode/bin:/usr/local/lib/node_modules/npm/bin/node-gyp-bin:$PATH

# Set working directory
WORKDIR /workspace

RUN mkdir -p /root/.local/state && \
    mkdir -p /root/.local/share && \
    mkdir -p /root/.config && \
    mkdir -p /workspace

RUN set -ex && \
    apt-get update && apt-get install -y --no-install-recommends curl ca-certificates sudo git libnss3 unzip ripgrep fd-find 7zip && \
    curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get update && apt-get install -y --no-install-recommends \
      nodejs \
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
      libxshmfence1 \
      libgtk-3-0 \
      libnotify4 \
      libx11-xcb1 \
      libxtst6 && \
    curl -fsSL https://opencode.ai/install | bash && \
    curl -fsSL https://claude.ai/install.sh | bash && \
    curl -fsSL https://bun.com/install | bash && \
    npm install -g @kilocode/cli && \
    npm install -g @openai/codex && \
    npm install -g playwright && \
    npx playwright install-deps chromium && \
    npx playwright install chromium && \
    npx playwright --version && \
    npm config set save-exact true && \
    npx --version && echo "npx installation verified" && \
    echo 'export PATH=/root/.local/bin:/root/.opencode/bin:/usr/local/lib/node_modules/npm/bin/node-gyp-bin:$PATH' >> ~/.bashrc && \
    echo 'alias npx="npx --yes"' >> ~/.bashrc && \
    rm -rf /var/lib/apt/lists/*

COPY backend/opencode /root/.opencode
COPY examples /usr/share/ralphloop/examples

COPY ralph /usr/local/bin/ralph
RUN chmod +x /usr/local/bin/ralph

COPY entrance.sh /usr/local/bin/entrance.sh
RUN chmod +x /usr/local/bin/entrance.sh

RUN RESULT=$(opencode --print-logs debug agent AGENT_RALPH 2>&1) || echo 'Opencode install failed:' "$RESULT"

ENTRYPOINT ["/usr/local/bin/entrance.sh"]

CMD ["/bin/bash"]
