# --- Build Stage ---
FROM node:20-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# --- Final Stage ---
FROM node:20-slim

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    git \
    bash \
    ca-certificates \
    sudo \
    unzip \
    python3 \
    mpg123 && \
    # Download ttyd binary directly
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then TTYD_ARCH="x86_64"; else TTYD_ARCH="aarch64"; fi && \
    curl -L "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${TTYD_ARCH}" -o /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Claude Code globally (Running as ROOT to avoid permission issues)
RUN npm install -g @anthropic-ai/claude-code

# Create user 'pai'
RUN useradd -m -s /bin/bash pai && \
    echo "pai ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy Bun from builder and set ownership
COPY --from=builder --chown=pai:pai /root/.bun /home/pai/.bun
ENV PATH="/home/pai/.bun/bin:${PATH}"

# Create app directory
RUN mkdir -p /usr/local/pai && chown pai:pai /usr/local/pai

USER pai
WORKDIR /home/pai

# Copy PAI release files to /usr/local/pai
COPY --chown=pai:pai Releases/v4.0.3/.claude /usr/local/pai

# Copy the startup script
COPY --chown=pai:pai Docker/startup.sh /home/pai/startup.sh
RUN chmod +x /home/pai/startup.sh

# Expose ports
EXPOSE 8080 8888

# Persistence
VOLUME [ "/home/pai/.claude/MEMORY", "/home/pai/.claude/USER", "/home/pai/.config/PAI" ]

# Entrypoint
ENTRYPOINT ["/home/pai/startup.sh"]
