FROM node:22-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    ca-certificates \
    vim \
    neovim \
    tmux \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with matching UID/GID from host
ARG USER_ID=501
ARG GROUP_ID=20
RUN groupadd -g $GROUP_ID -o coder || true && \
    useradd -m -u $USER_ID -g $GROUP_ID -o -s /bin/zsh coder

# Install bun for the coder user (needed by some MCP servers)
USER coder
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/home/coder/.bun/bin:$PATH"

# Switch back to root to install global npm packages
USER root
RUN npm install -g @anthropic-ai/claude-code

# Set up workspace
WORKDIR /workspace
RUN chown coder:$GROUP_ID /workspace

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Run as non-root user
USER coder

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
