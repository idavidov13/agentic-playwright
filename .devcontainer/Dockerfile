# ============================================================
# PW Scaffold Dev Container
# Base: Playwright with pre-installed browsers (Ubuntu Noble)
# Adds: Python 3, Claude Code CLI, pre-warmed npm & CLI caches
# ============================================================

ARG PLAYWRIGHT_VERSION=1.60.0
FROM mcr.microsoft.com/playwright:v${PLAYWRIGHT_VERSION}-noble

LABEL maintainer="Ivan Davidov"
LABEL description="Playwright + Python + Claude Code development container"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Python 3, venv, and useful development utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-pip \
    sudo \
    curl \
    jq \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (used by Claude Code status line for PR status)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Give pwuser sudo access (needed for some devcontainer operations)
RUN echo "pwuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/pwuser

# Create workspace directory
RUN mkdir -p /workspace && chown pwuser:pwuser /workspace

# Create persistent directories
RUN mkdir -p /commandhistory && chown pwuser:pwuser /commandhistory
RUN mkdir -p /home/pwuser/.claude && chown pwuser:pwuser /home/pwuser/.claude
# Named volume mount point for @playwright/cli browsers (see devcontainer.json)
RUN mkdir -p /ms-playwright-cli && chown pwuser:pwuser /ms-playwright-cli
RUN mkdir -p /home/pwuser/.npm && chown pwuser:pwuser /home/pwuser/.npm

# Install Claude Code CLI natively (no npm dependency)
USER pwuser
RUN curl -fsSL https://claude.ai/install.sh | bash
USER root

# Persist bash history across container rebuilds
ENV HISTFILE=/commandhistory/.bash_history

# Tell Playwright to use pre-installed browsers
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Add Claude Code to PATH
ENV PATH="/home/pwuser/.local/bin:${PATH}"

# Pre-warm npm cache and install playwright-cli browsers.
# Build context must be the workspace root (set "context": ".." in devcontainer.json).
# Named volumes inherit image contents on first create, so the caches seeded here
# carry over into /home/pwuser/.npm and /ms-playwright-cli volumes automatically.
COPY --chown=pwuser:pwuser package.json package-lock.json /tmp/staging/

USER pwuser
WORKDIR /tmp/staging

RUN npm ci \
    && CLI_PW_VERSION=$(node -p "require('./node_modules/@playwright/cli/node_modules/playwright/package.json').version") \
    && PLAYWRIGHT_BROWSERS_PATH=/ms-playwright-cli \
       node ./node_modules/@playwright/cli/node_modules/playwright/cli.js install chromium \
    && touch "/ms-playwright-cli/.pw-cli-browsers.${CLI_PW_VERSION}" \
    && rm -rf /tmp/staging

USER root

# Switch to non-root user
USER pwuser
WORKDIR /workspace
