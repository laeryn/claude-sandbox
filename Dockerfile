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
    procps \
    locales \
    bc \
    jq \
    gawk \
    fontconfig \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

# Install Nerd Font (required by Tokyo Night tmux theme)
RUN mkdir -p /usr/local/share/fonts/nerd-fonts && \
    curl -fsSL -o /tmp/nerd-font.zip \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip && \
    unzip -o /tmp/nerd-font.zip -d /usr/local/share/fonts/nerd-fonts && \
    rm /tmp/nerd-font.zip && \
    fc-cache -fv

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create non-root user with matching UID/GID from host
ARG USER_ID=501
ARG GROUP_ID=20
RUN groupadd -g $GROUP_ID -o coder || true && \
    useradd -m -u $USER_ID -g $GROUP_ID -o -s /bin/zsh coder && \
    mkdir -p /Users && chown coder:$GROUP_ID /Users

# Install oh-my-zsh, TPM + Tokyo Night tmux theme, and bun for the coder user
USER coder
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && \
    git clone https://github.com/janoamaral/tokyo-night-tmux ~/.tmux/plugins/tokyo-night-tmux
RUN curl -fsSL https://bun.sh/install | bash
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/coder/.bun/bin:/home/coder/.local/bin:$PATH"

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
